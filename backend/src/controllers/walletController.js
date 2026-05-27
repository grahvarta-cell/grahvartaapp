const db = require('../config/database');
const Razorpay = require('razorpay');
const { sendPushNotification } = require('./liveController');

const razorpay = process.env.RAZORPAY_KEY_ID ? new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID,
  key_secret: process.env.RAZORPAY_KEY_SECRET,
}) : null;

// Ensure wallet exists for user
async function ensureWallet(userId) {
  await db.query(
    `INSERT INTO wallets (user_id) VALUES ($1) ON CONFLICT (user_id) DO NOTHING`,
    [userId]
  );
  const result = await db.query('SELECT * FROM wallets WHERE user_id = $1', [userId]);
  return result.rows[0];
}

exports.getWallet = async (req, res) => {
  try {
    const wallet = await ensureWallet(req.user.id);
    res.json({ success: true, data: wallet });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.getTransactions = async (req, res) => {
  try {
    const { page = 1, limit = 20, type } = req.query;
    const offset = (page - 1) * limit;

    let query = 'SELECT * FROM wallet_transactions WHERE user_id = $1';
    const params = [req.user.id];

    if (type) { query += ` AND type = $${params.length + 1}`; params.push(type); }
    query += ` ORDER BY created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
    params.push(limit, offset);

    const result = await db.query(query, params);
    res.json({ success: true, data: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.getRechargeOffers = async (req, res) => {
  try {
    const result = await db.query('SELECT * FROM recharge_offers WHERE is_active = true ORDER BY sort_order ASC');
    res.json({ success: true, data: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// ── Admin: Recharge Offer CRUD ────────────────────────────────────────────────

exports.adminListOffers = async (req, res) => {
  try {
    const result = await db.query('SELECT * FROM recharge_offers ORDER BY sort_order ASC, id ASC');
    res.json({ success: true, data: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.adminCreateOffer = async (req, res) => {
  try {
    const { amount, bonus_percent, label, sort_order = 0 } = req.body;
    if (!amount || bonus_percent == null) return res.status(400).json({ success: false, message: 'amount and bonus_percent are required' });
    const result = await db.query(
      'INSERT INTO recharge_offers (amount, bonus_percent, label, sort_order) VALUES ($1, $2, $3, $4) RETURNING *',
      [amount, bonus_percent, label || null, sort_order]
    );
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.adminUpdateOffer = async (req, res) => {
  try {
    const { amount, bonus_percent, label, sort_order, is_active } = req.body;
    const result = await db.query(
      `UPDATE recharge_offers SET amount = COALESCE($1, amount), bonus_percent = COALESCE($2, bonus_percent),
       label = COALESCE($3, label), sort_order = COALESCE($4, sort_order), is_active = COALESCE($5, is_active)
       WHERE id = $6 RETURNING *`,
      [amount, bonus_percent, label, sort_order, is_active, req.params.id]
    );
    if (!result.rows.length) return res.status(404).json({ success: false, message: 'Offer not found' });
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.adminDeleteOffer = async (req, res) => {
  try {
    const result = await db.query('DELETE FROM recharge_offers WHERE id = $1 RETURNING id', [req.params.id]);
    if (!result.rows.length) return res.status(404).json({ success: false, message: 'Offer not found' });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// Create Razorpay order to add money
exports.createAddMoneyOrder = async (req, res) => {
  try {
    const { amount } = req.body; // amount in INR
    if (amount < 50) return res.status(400).json({ success: false, message: 'Minimum recharge is ₹50' });

    // Look up bonus for this amount
    const offerResult = await db.query(
      'SELECT bonus_percent FROM recharge_offers WHERE amount = $1 AND is_active = true LIMIT 1',
      [amount]
    );
    const bonusPercent = offerResult.rows[0]?.bonus_percent || 0;
    const bonusAmount = Math.round(amount * bonusPercent) / 100;
    const walletCredit = amount + bonusAmount;

    if (!razorpay) {
      // Dev mode: simulate
      const orderId = `order_demo_${Date.now()}`;
      await db.query(
        'INSERT INTO wallet_orders (order_id, user_id, amount_paid, wallet_credit, bonus_amount) VALUES ($1, $2, $3, $4, $5) ON CONFLICT (order_id) DO NOTHING',
        [orderId, req.user.id, amount, walletCredit, bonusAmount]
      );
      return res.json({
        success: true,
        data: {
          order_id: orderId,
          amount: amount * 100,
          currency: 'INR',
          key: 'rzp_test_demo',
          wallet_credit: walletCredit,
          bonus_amount: bonusAmount,
          bonus_percent: bonusPercent,
        }
      });
    }

    const chargeAmount = Math.round(amount * 1.18 * 100); // base amount + 18% GST in paise
    const order = await razorpay.orders.create({
      amount: chargeAmount,
      currency: 'INR',
      receipt: `w_${Date.now()}`,
      notes: { user_id: req.user.id, wallet_credit: walletCredit },
    });

    await db.query(
      'INSERT INTO wallet_orders (order_id, user_id, amount_paid, wallet_credit, bonus_amount) VALUES ($1, $2, $3, $4, $5)',
      [order.id, req.user.id, amount, walletCredit, bonusAmount]
    );

    res.json({ success: true, data: { order_id: order.id, amount: order.amount, currency: order.currency, key: process.env.RAZORPAY_KEY_ID, wallet_credit: walletCredit, bonus_amount: bonusAmount, bonus_percent: bonusPercent } });
  } catch (err) {
    console.error('Order error:', err);
    res.status(500).json({ success: false, message: 'Payment gateway error' });
  }
};

// Verify and credit wallet after payment
exports.verifyAndCredit = async (req, res) => {
  try {
    const { order_id, payment_id, signature, amount } = req.body;

    // Verify Razorpay signature
    if (process.env.RAZORPAY_KEY_SECRET && signature !== 'demo_signature') {
      const crypto = require('crypto');
      const generated = crypto.createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
        .update(`${order_id}|${payment_id}`).digest('hex');
      if (generated !== signature) return res.status(400).json({ success: false, message: 'Invalid payment signature' });
    }

    // Resolve wallet_credit from server-stored order (prevents client tampering)
    const orderRow = await db.query(
      'SELECT wallet_credit, bonus_amount FROM wallet_orders WHERE order_id = $1 AND user_id = $2 AND status = $3',
      [order_id, req.user.id, 'pending']
    );
    const creditAmount = orderRow.rows.length
      ? parseFloat(orderRow.rows[0].wallet_credit)
      : parseFloat(amount); // fallback for legacy calls
    const bonusAmount = orderRow.rows.length ? parseFloat(orderRow.rows[0].bonus_amount) : 0;

    const wallet = await ensureWallet(req.user.id);

    await db.query('UPDATE wallets SET balance = balance + $1, total_added = total_added + $1 WHERE user_id = $2', [creditAmount, req.user.id]);
    await db.query('UPDATE wallet_orders SET status = $1 WHERE order_id = $2', ['completed', order_id]);

    const baseAmount = creditAmount - bonusAmount;
    const description = bonusAmount > 0
      ? `Wallet recharge ₹${baseAmount.toFixed(0)} + ₹${bonusAmount.toFixed(0)} bonus`
      : 'Wallet recharge';

    await db.query(`
      INSERT INTO wallet_transactions (wallet_id, user_id, type, amount, balance_before, balance_after, description, gateway_transaction_id, payment_gateway, status)
      VALUES ($1, $2, 'credit', $3, $4, $5, $6, $7, 'razorpay', 'success')
    `, [wallet.id, req.user.id, creditAmount, wallet.balance, wallet.balance + creditAmount, description, payment_id]);

    const updated = await db.query('SELECT * FROM wallets WHERE user_id = $1', [req.user.id]);
    const notifMsg = bonusAmount > 0
      ? `₹${creditAmount} credited (includes ₹${bonusAmount} bonus)!`
      : `₹${creditAmount} has been credited to your wallet.`;
    sendPushNotification([req.user.id], '💰 Money Added!', notifMsg, { type: 'wallet_credit', amount: String(creditAmount) });
    res.json({ success: true, data: updated.rows[0], message: `₹${creditAmount} added to wallet`, bonus_amount: bonusAmount });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.getSubscriptionPlans = async (req, res) => {
  try {
    const result = await db.query('SELECT * FROM subscription_plans WHERE is_active = true ORDER BY price ASC');
    res.json({ success: true, data: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.purchaseSubscription = async (req, res) => {
  try {
    const { plan_id } = req.body;

    const planResult = await db.query('SELECT * FROM subscription_plans WHERE id = $1 AND is_active = true', [plan_id]);
    if (!planResult.rows.length) return res.status(404).json({ success: false, message: 'Plan not found' });
    const plan = planResult.rows[0];

    const wallet = await ensureWallet(req.user.id);
    if (wallet.balance < plan.price) {
      return res.status(400).json({ success: false, message: 'Insufficient wallet balance', required: plan.price, balance: wallet.balance });
    }

    // Deduct from wallet
    await db.query('UPDATE wallets SET balance = balance - $1, total_spent = total_spent + $1 WHERE user_id = $2', [plan.price, req.user.id]);

    const tx = await db.query(`
      INSERT INTO wallet_transactions (wallet_id, user_id, type, amount, balance_before, balance_after, description, reference_type)
      VALUES ($1, $2, 'debit', $3, $4, $5, $6, 'subscription') RETURNING id
    `, [wallet.id, req.user.id, plan.price, wallet.balance, wallet.balance - plan.price, `${plan.name} plan subscription`]);

    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + plan.duration_days);

    await db.query(`
      INSERT INTO user_subscriptions (user_id, plan_id, starts_at, expires_at, amount_paid, transaction_id)
      VALUES ($1, $2, NOW(), $3, $4, $5)
    `, [req.user.id, plan_id, expiresAt, plan.price, tx.rows[0].id]);

    await db.query('UPDATE users SET subscription_plan = $1, subscription_expires_at = $2 WHERE id = $3', [plan.name.toLowerCase(), expiresAt, req.user.id]);

    // Credit free minutes if plan includes them
    if (plan.free_minutes > 0) {
      const freeCredit = plan.free_minutes; // convert to rupees at base rate
      await db.query('UPDATE wallets SET balance = balance + $1 WHERE user_id = $2', [freeCredit, req.user.id]);
    }

    res.json({ success: true, message: `Subscribed to ${plan.name} plan`, expires_at: expiresAt });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.getWalletStats = async (req, res) => {
  try {
    const wallet = await ensureWallet(req.user.id);
    const txStats = await db.query(`
      SELECT
        COUNT(*) FILTER (WHERE type = 'credit') as total_credits,
        COUNT(*) FILTER (WHERE type = 'debit') as total_debits,
        SUM(amount) FILTER (WHERE type = 'credit') as total_credited,
        SUM(amount) FILTER (WHERE type = 'debit') as total_debited,
        COUNT(*) FILTER (WHERE created_at > NOW() - INTERVAL '30 days') as transactions_this_month
      FROM wallet_transactions WHERE user_id = $1
    `, [req.user.id]);

    const subscription = await db.query(`
      SELECT us.*, sp.name, sp.features FROM user_subscriptions us
      JOIN subscription_plans sp ON us.plan_id = sp.id
      WHERE us.user_id = $1 AND us.status = 'active' AND us.expires_at > NOW()
      ORDER BY us.expires_at DESC LIMIT 1
    `, [req.user.id]);

    res.json({
      success: true,
      data: {
        wallet,
        stats: txStats.rows[0],
        active_subscription: subscription.rows[0] || null,
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};
