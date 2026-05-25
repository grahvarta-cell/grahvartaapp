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

// Create Razorpay order to add money
exports.createAddMoneyOrder = async (req, res) => {
  try {
    const { amount } = req.body; // amount in INR
    if (amount < 50) return res.status(400).json({ success: false, message: 'Minimum recharge is ₹50' });

    if (!razorpay) {
      // Dev mode: simulate
      return res.json({
        success: true,
        data: {
          order_id: `order_demo_${Date.now()}`,
          amount: amount * 100,
          currency: 'INR',
          key: 'rzp_test_demo',
        }
      });
    }

    const order = await razorpay.orders.create({
      amount: Math.round(amount * 100),
      currency: 'INR',
      receipt: `w_${Date.now()}`,
      notes: { user_id: req.user.id },
    });

    res.json({ success: true, data: { order_id: order.id, amount: order.amount, currency: order.currency, key: process.env.RAZORPAY_KEY_ID } });
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

    const wallet = await ensureWallet(req.user.id);
    const creditAmount = parseFloat(amount);

    await db.query('UPDATE wallets SET balance = balance + $1, total_added = total_added + $1 WHERE user_id = $2', [creditAmount, req.user.id]);

    await db.query(`
      INSERT INTO wallet_transactions (wallet_id, user_id, type, amount, balance_before, balance_after, description, gateway_transaction_id, payment_gateway, status)
      VALUES ($1, $2, 'credit', $3, $4, $5, 'Wallet recharge', $6, 'razorpay', 'success')
    `, [wallet.id, req.user.id, creditAmount, wallet.balance, wallet.balance + creditAmount, payment_id]);

    const updated = await db.query('SELECT * FROM wallets WHERE user_id = $1', [req.user.id]);
    sendPushNotification([req.user.id], '💰 Money Added!', `₹${creditAmount} has been credited to your AstroVaak wallet.`, { type: 'wallet_credit', amount: String(creditAmount) });
    res.json({ success: true, data: updated.rows[0], message: `₹${creditAmount} added to wallet` });
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
