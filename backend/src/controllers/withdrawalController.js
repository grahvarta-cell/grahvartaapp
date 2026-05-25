const db = require('../config/database');
const axios = require('axios');

const RZP_KEY = process.env.RAZORPAY_KEY_ID;
const RZP_SECRET = process.env.RAZORPAY_KEY_SECRET;
const RZP_AUTH = Buffer.from(`${RZP_KEY}:${RZP_SECRET}`).toString('base64');

const MIN_WITHDRAWAL = 10;
const HOLD_HOURS = 48;

// ── Save / update payout details ─────────────────────────────────────────────
exports.savePayoutDetails = async (req, res) => {
  try {
    const { method, upi_id, paytm_number, bank_account_number, bank_ifsc, bank_account_name, bank_name } = req.body;

    const astroResult = await db.query('SELECT id FROM astrologers WHERE user_id = $1', [req.user.id]);
    if (!astroResult.rows.length) return res.status(403).json({ success: false, message: 'Not an astrologer' });
    const astrologerId = astroResult.rows[0].id;

    if (method === 'upi' && !upi_id) return res.status(400).json({ success: false, message: 'UPI ID required' });
    if (method === 'paytm' && !paytm_number) return res.status(400).json({ success: false, message: 'Paytm number required' });
    if (method === 'bank' && (!bank_account_number || !bank_ifsc || !bank_account_name)) {
      return res.status(400).json({ success: false, message: 'Bank details incomplete' });
    }

    // Create Razorpay contact if not exists
    let existing = await db.query('SELECT * FROM astrologer_payout_details WHERE astrologer_id = $1', [astrologerId]);
    let contactId = existing.rows[0]?.razorpay_contact_id;

    if (!contactId) {
      const userResult = await db.query('SELECT name, email FROM users WHERE id = $1', [req.user.id]);
      const user = userResult.rows[0];
      try {
        const contactRes = await axios.post('https://api.razorpay.com/v1/contacts', {
          name: user.name,
          email: user.email,
          type: 'vendor',
        }, { headers: { Authorization: `Basic ${RZP_AUTH}` } });
        contactId = contactRes.data.id;
      } catch (e) {
        console.error('Razorpay contact error:', e.response?.data);
      }
    }

    // Create fund account on Razorpay
    let fundAccountId = null;
    if (contactId) {
      try {
        let fundPayload = { contact_id: contactId, account_type: 'bank_account' };
        if (method === 'upi') {
          fundPayload.account_type = 'vpa';
          fundPayload.vpa = { address: upi_id };
        } else if (method === 'paytm') {
          fundPayload.account_type = 'vpa';
          fundPayload.vpa = { address: `${paytm_number}@paytm` };
        } else {
          fundPayload.bank_account = {
            name: bank_account_name,
            ifsc: bank_ifsc,
            account_number: bank_account_number,
          };
        }
        const fundRes = await axios.post('https://api.razorpay.com/v1/fund_accounts', fundPayload, {
          headers: { Authorization: `Basic ${RZP_AUTH}` },
        });
        fundAccountId = fundRes.data.id;
      } catch (e) {
        console.error('Razorpay fund account error:', e.response?.data);
      }
    }

    await db.query(`
      INSERT INTO astrologer_payout_details
        (astrologer_id, method, upi_id, paytm_number, bank_account_number, bank_ifsc, bank_account_name, bank_name, razorpay_contact_id, razorpay_fund_account_id)
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
      ON CONFLICT (astrologer_id) DO UPDATE SET
        method=$2, upi_id=$3, paytm_number=$4, bank_account_number=$5,
        bank_ifsc=$6, bank_account_name=$7, bank_name=$8,
        razorpay_contact_id=COALESCE($9, astrologer_payout_details.razorpay_contact_id),
        razorpay_fund_account_id=COALESCE($10, astrologer_payout_details.razorpay_fund_account_id),
        updated_at=NOW()
    `, [astrologerId, method, upi_id, paytm_number, bank_account_number, bank_ifsc, bank_account_name, bank_name, contactId, fundAccountId]);

    res.json({ success: true, message: 'Payout details saved' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// ── Get payout details ────────────────────────────────────────────────────────
exports.getPayoutDetails = async (req, res) => {
  try {
    const astroResult = await db.query('SELECT id FROM astrologers WHERE user_id = $1', [req.user.id]);
    if (!astroResult.rows.length) return res.status(403).json({ success: false, message: 'Not an astrologer' });
    const result = await db.query('SELECT * FROM astrologer_payout_details WHERE astrologer_id = $1', [astroResult.rows[0].id]);
    res.json({ success: true, data: result.rows[0] || null });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// ── Request withdrawal ────────────────────────────────────────────────────────
exports.requestWithdrawal = async (req, res) => {
  try {
    const { amount } = req.body;

    const astroResult = await db.query('SELECT * FROM astrologers WHERE user_id = $1', [req.user.id]);
    if (!astroResult.rows.length) return res.status(403).json({ success: false, message: 'Not an astrologer' });
    const astro = astroResult.rows[0];

    // Minimum amount check
    if (amount < MIN_WITHDRAWAL) {
      return res.status(400).json({ success: false, message: `Minimum withdrawal amount is ₹${MIN_WITHDRAWAL}` });
    }

    // Weekly once check
    if (astro.last_withdrawal_at) {
      const daysSince = (Date.now() - new Date(astro.last_withdrawal_at).getTime()) / (1000 * 60 * 60 * 24);
      if (daysSince < 7) {
        const nextDate = new Date(astro.last_withdrawal_at);
        nextDate.setDate(nextDate.getDate() + 7);
        return res.status(400).json({
          success: false,
          message: `You can withdraw once per week. Next withdrawal available on ${nextDate.toDateString()}`,
        });
      }
    }

    // Check available balance (excluding on_hold)
    const available = parseFloat(astro.wallet_balance || 0) - parseFloat(astro.on_hold_amount || 0);
    if (amount > available) {
      return res.status(400).json({ success: false, message: `Insufficient balance. Available: ₹${available.toFixed(2)}` });
    }

    // Check payout details exist
    const payoutDetails = await db.query('SELECT * FROM astrologer_payout_details WHERE astrologer_id = $1', [astro.id]);
    if (!payoutDetails.rows.length) {
      return res.status(400).json({ success: false, message: 'Please add payout details before withdrawing' });
    }
    const details = payoutDetails.rows[0];
    const processAfter = new Date(Date.now() + HOLD_HOURS * 60 * 60 * 1000);

    // Deduct from wallet and put on hold
    await db.query('UPDATE astrologers SET wallet_balance = wallet_balance - $1, on_hold_amount = on_hold_amount + $1, last_withdrawal_at = NOW() WHERE id = $2',
      [amount, astro.id]);

    const withdrawal = await db.query(`
      INSERT INTO withdrawal_requests (astrologer_id, amount, method, process_after)
      VALUES ($1, $2, $3, $4) RETURNING *
    `, [astro.id, amount, details.method, processAfter]);

    res.json({
      success: true,
      message: `Withdrawal of ₹${amount} requested. Will be processed after ${HOLD_HOURS} hours.`,
      data: withdrawal.rows[0],
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// ── Get withdrawal history ────────────────────────────────────────────────────
exports.getWithdrawalHistory = async (req, res) => {
  try {
    const astroResult = await db.query('SELECT id FROM astrologers WHERE user_id = $1', [req.user.id]);
    if (!astroResult.rows.length) return res.status(403).json({ success: false, message: 'Not an astrologer' });

    const result = await db.query(`
      SELECT * FROM withdrawal_requests WHERE astrologer_id = $1 ORDER BY requested_at DESC LIMIT 50
    `, [astroResult.rows[0].id]);

    res.json({ success: true, data: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// ── Process due withdrawals (called by cron) ──────────────────────────────────
exports.processDueWithdrawals = async () => {
  try {
    const due = await db.query(`
      SELECT wr.*, apd.razorpay_fund_account_id, apd.method
      FROM withdrawal_requests wr
      JOIN astrologer_payout_details apd ON apd.astrologer_id = wr.astrologer_id
      WHERE wr.status = 'pending' AND wr.process_after <= NOW()
    `);

    for (const req of due.rows) {
      try {
        await db.query(`UPDATE withdrawal_requests SET status = 'processing' WHERE id = $1`, [req.id]);

        if (!req.razorpay_fund_account_id) {
          await db.query(`UPDATE withdrawal_requests SET status = 'rejected', remarks = 'No fund account on Razorpay' WHERE id = $1`, [req.id]);
          // Refund to wallet
          await db.query(`UPDATE astrologers SET wallet_balance = wallet_balance + $1, on_hold_amount = GREATEST(on_hold_amount - $1, 0) WHERE id = $2`,
            [req.amount, req.astrologer_id]);
          continue;
        }

        const payoutRes = await axios.post('https://api.razorpay.com/v1/payouts', {
          account_number: process.env.RAZORPAY_ACCOUNT_NUMBER,
          fund_account_id: req.razorpay_fund_account_id,
          amount: Math.round(req.amount * 100), // paise
          currency: 'INR',
          mode: req.method === 'upi' || req.method === 'paytm' ? 'UPI' : 'NEFT',
          purpose: 'payout',
          queue_if_low_balance: true,
          reference_id: req.id,
          narration: 'AstroVaak Earnings',
        }, { headers: { Authorization: `Basic ${RZP_AUTH}`, 'X-Payout-Idempotency': req.id } });

        await db.query(`
          UPDATE withdrawal_requests SET status = 'completed', razorpay_payout_id = $1, processed_at = NOW() WHERE id = $2
        `, [payoutRes.data.id, req.id]);

        // Release from hold
        await db.query(`UPDATE astrologers SET on_hold_amount = GREATEST(on_hold_amount - $1, 0) WHERE id = $2`,
          [req.amount, req.astrologer_id]);

        console.log(`Payout processed: ₹${req.amount} to ${req.method} for astrologer ${req.astrologer_id}`);
      } catch (e) {
        console.error('Payout error:', e.response?.data || e.message);
        await db.query(`UPDATE withdrawal_requests SET status = 'rejected', remarks = $1 WHERE id = $2`,
          [e.response?.data?.error?.description || 'Payout failed', req.id]);
        // Refund to wallet on failure
        await db.query(`UPDATE astrologers SET wallet_balance = wallet_balance + $1, on_hold_amount = GREATEST(on_hold_amount - $1, 0) WHERE id = $2`,
          [req.amount, req.astrologer_id]);
      }
    }
  } catch (err) {
    console.error('processDueWithdrawals error:', err);
  }
};

// ── Submit complaint (user) ───────────────────────────────────────────────────
exports.submitComplaint = async (req, res) => {
  try {
    const { consultation_id, reason } = req.body;

    const consult = await db.query('SELECT * FROM consultations WHERE id = $1 AND user_id = $2', [consultation_id, req.user.id]);
    if (!consult.rows.length) return res.status(404).json({ success: false, message: 'Consultation not found' });

    await db.query(`INSERT INTO consultation_complaints (consultation_id, user_id, reason) VALUES ($1, $2, $3)`,
      [consultation_id, req.user.id, reason]);

    // Hold the astrologer's earning for this consultation
    const earning = parseFloat(consult.rows[0].astrologer_earning || 0);
    if (earning > 0) {
      await db.query(`UPDATE astrologers SET on_hold_amount = on_hold_amount + $1 WHERE id = $2`,
        [earning, consult.rows[0].astrologer_id]);
    }

    res.json({ success: true, message: 'Complaint submitted. We will review within 24 hours.' });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};
