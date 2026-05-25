/**
 * Per-minute billing engine for live consultations.
 * Deducts from user wallet every 60 seconds and credits astrologer.
 */
class BillingEngine {
  constructor(consultationId, ratePerMinute, db, io) {
    this.consultationId = consultationId;
    this.ratePerMinute = parseFloat(ratePerMinute);
    this.db = db;
    this.io = io;
    this.interval = null;
    this.secondsElapsed = 0;
    this.totalCharged = 0;
    this.PLATFORM_FEE_PERCENT = 20; // 20% platform commission
  }

  start(userId, astrologerId) {
    this.userId = userId;
    this.astrologerId = astrologerId;
    this.startTime = new Date();
    this.lastActivityAt = Date.now();
    this.INACTIVITY_TIMEOUT_MS = 5 * 60 * 1000; // 5 minutes
    this._ticking = false; // guard against concurrent async ticks

    this.interval = setInterval(() => {
      if (this._ticking) return; // skip if previous tick still running
      this._ticking = true;
      this._tick().finally(() => { this._ticking = false; });
    }, 1000);
    console.log(`Billing started: consultation ${this.consultationId} @ ₹${this.ratePerMinute}/min`);
  }

  resetActivity() {
    this.lastActivityAt = Date.now();
  }

  async _tick() {
    this.secondsElapsed++;

    // Check inactivity
    if (Date.now() - this.lastActivityAt > this.INACTIVITY_TIMEOUT_MS) {
      console.log(`Consultation ${this.consultationId} ended due to inactivity`);
      const duration = this.secondsElapsed;
      const total = this.totalCharged;
      await this.stop();
      // Force DB update in case stop() missed it
      await this.db.query(
        `UPDATE consultations SET status = 'completed', ended_at = NOW(), duration_seconds = $1, total_amount = $2 WHERE id = $3 AND status != 'completed'`,
        [duration, total, this.consultationId]
      );
      await this.db.query(
        `UPDATE consultation_queue SET status = 'cancelled' WHERE consultation_id = $1 AND status NOT IN ('cancelled', 'completed')`,
        [this.consultationId]
      );
      this.io.to(`consultation:${this.consultationId}`).emit('consultation_ended', {
        consultation_id: this.consultationId,
        reason: 'inactivity',
        duration,
        total_amount: total,
      });
      return;
    }

    // Emit live timer
    this.io.to(`consultation:${this.consultationId}`).emit('billing_tick', {
      seconds: this.secondsElapsed,
      amount_charged: this.totalCharged,
    });

    // Charge every 60 seconds
    if (this.secondsElapsed % 60 === 0) {
      await this._chargeMinute();
    }
  }

  async _chargeMinute() {
    try {
      const walletResult = await this.db.query(
        'SELECT id, balance FROM wallets WHERE user_id = $1 FOR UPDATE',
        [this.userId]
      );

      if (!walletResult.rows.length || walletResult.rows[0].balance < this.ratePerMinute) {
        // Insufficient balance — refund last partial minute and end session
        if (this.secondsElapsed % 60 !== 0 && this.totalCharged > 0) {
          const partialSeconds = this.secondsElapsed % 60;
          const partialCharge = parseFloat(((partialSeconds / 60) * this.ratePerMinute).toFixed(2));
          if (partialCharge > 0) {
            await this.db.query('UPDATE wallets SET balance = balance + $1 WHERE user_id = $2', [partialCharge, this.userId]);
          }
        }
        await this.stop();
        this.io.to(`consultation:${this.consultationId}`).emit('consultation_ended', {
          consultation_id: this.consultationId,
          reason: 'insufficient_balance',
          duration: this.secondsElapsed,
          total_amount: this.totalCharged,
        });
        return;
      }

      const wallet = walletResult.rows[0];
      const platformFee = this.ratePerMinute * (this.PLATFORM_FEE_PERCENT / 100);
      const astrologerEarning = this.ratePerMinute - platformFee;

      // Deduct from user wallet
      await this.db.query(
        'UPDATE wallets SET balance = balance - $1, total_spent = total_spent + $1 WHERE user_id = $2',
        [this.ratePerMinute, this.userId]
      );

      // Record transaction
      await this.db.query(
        `INSERT INTO wallet_transactions (wallet_id, user_id, type, amount, balance_before, balance_after, description, reference_id, reference_type)
         VALUES ($1, $2, 'debit', $3, $4, $5, $6, $7, 'consultation')`,
        [wallet.id, this.userId, this.ratePerMinute, wallet.balance, wallet.balance - this.ratePerMinute,
         `Consultation charge - 1 minute`, this.consultationId]
      );

      // Credit astrologer
      await this.db.query(
        'UPDATE astrologers SET wallet_balance = wallet_balance + $1 WHERE id = $2',
        [astrologerEarning, this.astrologerId]
      );

      this.totalCharged += this.ratePerMinute;

      // Update consultation totals
      await this.db.query(
        `UPDATE consultations SET
           duration_seconds = $1,
           total_amount = $2,
           user_wallet_deducted = $2,
           astrologer_earning = astrologer_earning + $3,
           platform_fee = platform_fee + $4
         WHERE id = $5`,
        [this.secondsElapsed, this.totalCharged, astrologerEarning, platformFee, this.consultationId]
      );

      this.io.to(`consultation:${this.consultationId}`).emit('billing_charged', {
        amount: this.ratePerMinute,
        total: this.totalCharged,
        balance_remaining: wallet.balance - this.ratePerMinute,
      });

    } catch (err) {
      console.error('Billing error:', err);
    }
  }

  async stop() {
    if (this._stopped) return;
    this._stopped = true;
    if (this.interval) {
      clearInterval(this.interval);
      this.interval = null;
    }

    const MINIMUM_CHARGE = 1;

    // Charge minimum ₹1 if call was connected but less than 1 minute elapsed
    if (this.secondsElapsed > 0 && this.totalCharged === 0) {
      try {
        const walletResult = await this.db.query(
          'SELECT id, balance FROM wallets WHERE user_id = $1', [this.userId]
        );
        if (walletResult.rows.length && walletResult.rows[0].balance >= MINIMUM_CHARGE) {
          const wallet = walletResult.rows[0];
          const platformFee = MINIMUM_CHARGE * (this.PLATFORM_FEE_PERCENT / 100);
          const astrologerEarning = MINIMUM_CHARGE - platformFee;

          await this.db.query(
            'UPDATE wallets SET balance = balance - $1, total_spent = total_spent + $1 WHERE user_id = $2',
            [MINIMUM_CHARGE, this.userId]
          );
          await this.db.query(
            'UPDATE astrologers SET wallet_balance = wallet_balance + $1 WHERE id = $2',
            [astrologerEarning, this.astrologerId]
          );
          await this.db.query(
            `INSERT INTO wallet_transactions (wallet_id, user_id, type, amount, balance_before, balance_after, description, reference_id, reference_type)
             VALUES ($1, $2, 'debit', $3, $4, $5, $6, $7, 'consultation')`,
            [wallet.id, this.userId, MINIMUM_CHARGE, wallet.balance, wallet.balance - MINIMUM_CHARGE,
             'Minimum consultation charge', this.consultationId]
          );

          this.totalCharged = MINIMUM_CHARGE;
          console.log(`Minimum charge ₹${MINIMUM_CHARGE} applied for short consultation ${this.consultationId}`);
        }
      } catch (err) {
        console.error('Minimum charge error:', err);
      }
    }

    const endTime = new Date();
    await this.db.query(
      `UPDATE consultations SET
         status = 'completed',
         ended_at = $1,
         duration_seconds = $2,
         total_amount = $3
       WHERE id = $4`,
      [endTime, this.secondsElapsed, this.totalCharged, this.consultationId]
    );

    // Update astrologer stats
    await this.db.query(
      `UPDATE astrologers SET
         total_consultations = total_consultations + 1,
         total_minutes = total_minutes + $1,
         queue_count = GREATEST(queue_count - 1, 0)
       WHERE id = $2`,
      [Math.floor(this.secondsElapsed / 60), this.astrologerId]
    );

    console.log(`Billing stopped: ${this.consultationId}, charged ₹${this.totalCharged}, ${this.secondsElapsed}s`);
  }
}

module.exports = { BillingEngine };
