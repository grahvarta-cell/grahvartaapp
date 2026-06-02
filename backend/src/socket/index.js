const jwt = require('jsonwebtoken');
const db = require('../config/database');
const { BillingEngine } = require('./billingEngine');
const { sendPushNotification } = require('../controllers/liveController');
const { saveMessage, insertSessionDivider } = require('../controllers/threadController');

const billingEngines = new Map(); // consultationId -> BillingEngine
const activeRooms = new Map();    // consultationId -> { userId, astrologerId, type }
const onlineAstrologers = new Map(); // astrologerId -> socketId
const onlineUsers = new Map();       // userId -> socketId

function initSocket(io) {
  // Auth middleware
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth.token;
      if (!token) return next(new Error('No token'));
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      const result = await db.query('SELECT id, name, sun_sign FROM users WHERE id = $1', [decoded.userId]);
      if (!result.rows.length) return next(new Error('User not found'));
      socket.user = result.rows[0];
      next();
    } catch {
      next(new Error('Authentication failed'));
    }
  });

  io.on('connection', (socket) => {
    const userId = socket.user.id;
    console.log(`User connected: ${socket.user.name} (${socket.id})`);

    // ─── PRESENCE ───────────────────────────────────────────────
    socket.on('set_role', async ({ role }) => {
      socket.role = role;
      console.log(`[set_role] user=${socket.user.name} (${userId}) role=${role} socket=${socket.id}`);
      if (role === 'astrologer') {
        const result = await db.query('SELECT id FROM astrologers WHERE user_id = $1', [userId]);
        console.log(`[set_role] astrologer DB lookup: found=${result.rows.length} rows`);
        if (result.rows.length) {
          socket.astrologerId = result.rows[0].id;
          onlineAstrologers.set(socket.astrologerId, socket.id);
          console.log(`Astrologer registered: ${socket.user.name} (astrologer_id=${socket.astrologerId}, socket=${socket.id})`);
          await db.query('UPDATE astrologers SET is_online = true WHERE id = $1', [socket.astrologerId]);
          io.emit('astrologer_online', { astrologer_id: socket.astrologerId });

          // Notify astrologer of any pending queued consultations
          const queued = await db.query(
            `SELECT c.*, u.name as user_name FROM consultations c
             JOIN users u ON c.user_id = u.id
             WHERE c.astrologer_id = $1 AND c.status = 'queued'`,
            [socket.astrologerId]
          );
          for (const c of queued.rows) {
            // Always notify astrologer — user may still be reconnecting
            socket.emit('new_consultation_request', {
              consultation_id: c.id,
              user: { id: c.user_id, name: c.user_name },
              type: c.type,
              rate: c.per_minute_rate,
            });
          }
        }
      } else {
        onlineUsers.set(userId, socket.id);
      }
    });

    // ─── CONSULTATION REQUEST ────────────────────────────────────
    socket.on('request_consultation', async ({ astrologer_id, type }) => {
      try {
        console.log(`[request_consultation] user=${userId} astrologer_id=${astrologer_id} type=${type}`);
        console.log(`[onlineAstrologers] map size=${onlineAstrologers.size}`, [...onlineAstrologers.entries()]);

        // Reuse existing active/queued consultation if one exists
        const existing = await db.query(
          `SELECT * FROM consultations
           WHERE user_id = $1 AND status IN ('queued', 'active')
           ORDER BY created_at DESC LIMIT 1`,
          [userId]
        );
        if (existing.rows.length) {
          const c = existing.rows[0];

          console.log(`[existing consultation] id=${c.id} status=${c.status} astrologer_id=${c.astrologer_id} requested=${astrologer_id}`);

          // If stale queued consultation is for a DIFFERENT astrologer, cancel it and proceed fresh
          if (c.status === 'queued' && c.astrologer_id !== astrologer_id) {
            await db.query(`UPDATE consultations SET status='cancelled', ended_at=NOW() WHERE id=$1`, [c.id]);
            await db.query(`UPDATE consultation_queue SET status='cancelled' WHERE consultation_id=$1`, [c.id]);
            await db.query(`UPDATE astrologers SET queue_count=GREATEST(queue_count-1,0) WHERE id=$1`, [c.astrologer_id]);
            console.log(`[existing consultation] cancelled stale queued consultation ${c.id} for different astrologer`);
            // fall through to create new consultation below
          } else {
          socket.consultationId = c.id;
          socket.join(`consultation:${c.id}`);

          if (c.status === 'active') {
            // Emit started first so Flutter sets isConnected = true
            socket.emit('consultation_started', { consultation_id: c.id, type: c.type });

            // Sync current billing state so timer and amount are correct
            const engine = billingEngines.get(c.id);
            if (engine) {
              socket.emit('billing_tick', {
                seconds: engine.secondsElapsed,
                amount_charged: engine.totalCharged,
              });
            }
          } else {
            socket.emit('consultation_queued', { consultation_id: c.id, position: 1, estimated_wait: 5 });

            // Re-notify astrologer in case they missed the original request
            const astroSocketId = onlineAstrologers.get(c.astrologer_id);
            console.log(`[re-notify] astrologer_id=${c.astrologer_id} socketId=${astroSocketId || 'NOT FOUND'}`);
            if (astroSocketId) {
              io.to(astroSocketId).emit('new_consultation_request', {
                consultation_id: c.id,
                user: socket.user,
                type: c.type,
                rate: c.per_minute_rate,
              });
              console.log(`Re-notified astrologer ${c.astrologer_id} of existing queued consultation ${c.id}`);
            }
          }
          return;
          } // end else (same astrologer)
        }

        // Check wallet balance — create wallet row if it doesn't exist yet
        await db.query(
          `INSERT INTO wallets (user_id) VALUES ($1) ON CONFLICT (user_id) DO NOTHING`,
          [userId]
        );
        const walletResult = await db.query('SELECT balance FROM wallets WHERE user_id = $1', [userId]);
        const balance = parseFloat(walletResult.rows[0]?.balance ?? 0);

        const rateCol = type === 'chat' ? 'per_minute_rate_chat' : type === 'voice' ? 'per_minute_rate_call' : 'per_minute_rate_video';
        const astroResult = await db.query(`SELECT id, display_name, ${rateCol} as rate, is_online, is_available, queue_count FROM astrologers WHERE id = $1`, [astrologer_id]);

        if (!astroResult.rows.length) return socket.emit('error', { message: 'Astrologer not found' });
        const astro = astroResult.rows[0];
        const rate = parseFloat(astro.rate);

        if (balance < rate) {
          return socket.emit('insufficient_balance', { required: rate, balance });
        }

        // Create consultation record
        const consultation = await db.query(
          `INSERT INTO consultations (user_id, astrologer_id, type, status, per_minute_rate, session_token)
           VALUES ($1, $2, $3, 'queued', $4, $5) RETURNING *`,
          [userId, astrologer_id, type, astro.rate, require('uuid').v4()]
        );
        const consultationId = consultation.rows[0].id;

        // Add to queue
        const queuePos = await db.query(
          `INSERT INTO consultation_queue (astrologer_id, user_id, consultation_id, consultation_type, position, status)
           VALUES ($1, $2, $3, $4, (SELECT COALESCE(MAX(position),0)+1 FROM consultation_queue WHERE astrologer_id=$1 AND status='waiting'), $5)
           RETURNING position`,
          [astrologer_id, userId, consultationId, type, 'waiting']
        );

        socket.consultationId = consultationId;
        socket.join(`consultation:${consultationId}`);

        socket.emit('consultation_queued', {
          consultation_id: consultationId,
          position: queuePos.rows[0].position,
          estimated_wait: queuePos.rows[0].position * 5,
          astrologer: astro,
        });

        // Notify astrologer via socket (if online) — retry once after 2s in case set_role is still resolving
        const notifyAstrologer = async (attempt = 1) => {
          const astroSocketId = onlineAstrologers.get(astrologer_id);
          console.log(`[notify attempt ${attempt}] astrologer_id=${astrologer_id} socketId=${astroSocketId || 'NOT FOUND'}`);
          if (astroSocketId) {
            io.to(astroSocketId).emit('new_consultation_request', {
              consultation_id: consultationId,
              user: socket.user,
              type,
              rate: astro.rate,
            });
            return true;
          }
          return false;
        };

        const notified = await notifyAstrologer(1);
        if (!notified) {
          // Retry after 2s (astrologer may still be completing set_role)
          setTimeout(() => notifyAstrologer(2), 2000);
        }

        // Always send push notification so astrologer is notified even if app is closed
        const astroUserResult = await db.query('SELECT user_id FROM astrologers WHERE id = $1', [astrologer_id]);
        if (astroUserResult.rows.length) {
          const typeLabel = type === 'chat' ? 'Chat' : type === 'voice' ? 'Voice Call' : 'Video Call';
          await sendPushNotification(
            [astroUserResult.rows[0].user_id],
            `New ${typeLabel} Request 🔔`,
            `${socket.user.name} is requesting a ${typeLabel.toLowerCase()} consultation. Open the app to accept.`,
            { type: 'consultation_request', consultation_id: consultationId }
          );
        }

        await db.query('UPDATE astrologers SET queue_count = queue_count + 1 WHERE id = $1', [astrologer_id]);
      } catch (err) {
        console.error('Consultation request error:', err);
        socket.emit('error', { message: 'Failed to create consultation' });
      }
    });

    // ─── ASTROLOGER ACCEPTS ──────────────────────────────────────
    socket.on('accept_consultation', async ({ consultation_id }) => {
      try {
        const consult = await db.query('SELECT * FROM consultations WHERE id = $1', [consultation_id]);
        if (!consult.rows.length) return;

        const now = new Date();
        await db.query(
          `UPDATE consultations SET status='active', started_at=$1 WHERE id=$2`,
          [now, consultation_id]
        );

        await db.query(`UPDATE consultation_queue SET status='called' WHERE consultation_id=$1`, [consultation_id]);

        activeRooms.set(consultation_id, {
          userId: consult.rows[0].user_id,
          astrologerId: consult.rows[0].astrologer_id,
          type: consult.rows[0].type,
          rate: consult.rows[0].per_minute_rate,
        });

        // Start billing engine
        const billing = new BillingEngine(consultation_id, consult.rows[0].per_minute_rate, db, io, sendPushNotification);
        billing.start(consult.rows[0].user_id, consult.rows[0].astrologer_id);
        billingEngines.set(consultation_id, billing);

        socket.join(`consultation:${consultation_id}`);
        // Insert a session-start divider into the persistent thread
        const sessionLabel = `── Session started ${now.toLocaleDateString('en-IN', { day:'numeric', month:'short', year:'numeric', hour:'2-digit', minute:'2-digit' })} ──`;
        await insertSessionDivider({
          userId: consult.rows[0].user_id,
          astrologerId: consult.rows[0].astrologer_id,
          consultationId: consultation_id,
          label: sessionLabel,
        });

        io.to(`consultation:${consultation_id}`).emit('consultation_started', {
          consultation_id,
          started_at: now,
          type: consult.rows[0].type,
          webrtc_room: consultation_id,
        });
      } catch (err) {
        console.error('Accept error:', err);
      }
    });

    // ─── JOIN EXISTING CONSULTATION ROOM (astrologer portal chat) ──
    socket.on('join_consultation', async ({ consultation_id }) => {
      const consult = await db.query(
        'SELECT * FROM consultations WHERE id = $1',
        [consultation_id]
      );
      if (consult.rows.length) socket.join(`consultation:${consultation_id}`);
    });

    // ─── REJECT / DECLINE ────────────────────────────────────────
    socket.on('reject_consultation', async ({ consultation_id }) => {
      await db.query(`UPDATE consultations SET status='cancelled' WHERE id=$1`, [consultation_id]);
      io.to(`consultation:${consultation_id}`).emit('consultation_rejected', { consultation_id });
    });

    // ─── CHAT MESSAGES ───────────────────────────────────────────
    socket.on('send_message', async ({ consultation_id, content, message_type = 'text', media_url }) => {
      try {
        // Reset inactivity timer
        const engine = billingEngines.get(consultation_id);
        if (engine) engine.resetActivity();

        const senderRole = socket.role === 'astrologer' ? 'astrologer' : 'user';
        const room = activeRooms.get(consultation_id);

        // Save to old per-session table (backward compat)
        const msg = await db.query(
          `INSERT INTO consultation_messages (consultation_id, sender_id, sender_type, message_type, content, media_url)
           VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
          [consultation_id, userId, senderRole, message_type, content, media_url]
        );

        // Save to persistent astrologer-wise thread
        if (room) {
          await saveMessage({
            userId: room.userId,
            astrologerId: room.astrologerId,
            consultationId: consultation_id,
            senderId: userId,
            senderRole,
            message: content,
            messageType: message_type,
          });
        }

        io.to(`consultation:${consultation_id}`).emit('new_message', msg.rows[0]);
      } catch (err) {
        console.error('Message error:', err);
      }
    });

    // ─── TYPING INDICATORS ──────────────────────────────────────
    socket.on('typing_start', ({ consultation_id }) => {
      socket.to(`consultation:${consultation_id}`).emit('peer_typing', { is_typing: true });
    });
    socket.on('typing_stop', ({ consultation_id }) => {
      socket.to(`consultation:${consultation_id}`).emit('peer_typing', { is_typing: false });
    });

    // ─── WEBRTC SIGNALING ────────────────────────────────────────
    socket.on('webrtc_offer', ({ consultation_id, sdp }) => {
      billingEngines.get(consultation_id)?.resetActivity();
      socket.to(`consultation:${consultation_id}`).emit('webrtc_offer', { sdp, from: userId });
    });
    socket.on('webrtc_answer', ({ consultation_id, sdp }) => {
      billingEngines.get(consultation_id)?.resetActivity();
      socket.to(`consultation:${consultation_id}`).emit('webrtc_answer', { sdp, from: userId });
    });
    socket.on('webrtc_ice_candidate', ({ consultation_id, candidate }) => {
      billingEngines.get(consultation_id)?.resetActivity();
      socket.to(`consultation:${consultation_id}`).emit('webrtc_ice_candidate', { candidate, from: userId });
    });

    // ─── END CONSULTATION ────────────────────────────────────────
    socket.on('end_consultation', async ({ consultation_id }) => {
      const engine = billingEngines.get(consultation_id);
      if (engine) {
        await engine.stop();
        billingEngines.delete(consultation_id);
      } else {
        // No billing engine — update DB directly so session doesn't stay active
        await db.query(
          `UPDATE consultations SET status='completed', ended_at=NOW()
           WHERE id=$1 AND status NOT IN ('completed','cancelled')`,
          [consultation_id]
        );
      }
      activeRooms.delete(consultation_id);

      const result = await db.query('SELECT * FROM consultations WHERE id = $1', [consultation_id]);
      if (result.rows.length) {
        const consult = result.rows[0];
        const durationMin = Math.ceil((consult.duration_seconds || 0) / 60);
        const amount = parseFloat(consult.total_amount || 0).toFixed(2);

        io.to(`consultation:${consultation_id}`).emit('consultation_ended', {
          consultation_id,
          duration: consult.duration_seconds,
          total_amount: consult.total_amount,
        });

        if (consult.user_id) {
          await sendPushNotification(
            [consult.user_id],
            'Consultation Ended',
            `Your consultation has ended. Duration: ${durationMin} min | ₹${amount} charged.`,
            { type: 'call_ended', consultation_id }
          );
        }

        // Notify astrologer
        if (consult.astrologer_id) {
          const astroUser = await db.query('SELECT user_id FROM astrologers WHERE id = $1', [consult.astrologer_id]);
          if (astroUser.rows.length) {
            const earned = (parseFloat(consult.total_amount || 0) * 0.8).toFixed(2);
            await sendPushNotification(
              [astroUser.rows[0].user_id],
              'Session Completed',
              `Session ended. Duration: ${durationMin} min | ₹${earned} earned.`,
              { type: 'session_ended', consultation_id }
            );
          }
        }
      }
    });

    // ─── LIVE SESSION ────────────────────────────────────────────
    socket.on('join_live', async ({ session_id }) => {
      socket.join(`live:${session_id}`);
      socket.liveSessionId = session_id;
      const count = io.sockets.adapter.rooms.get(`live:${session_id}`)?.size || 0;
      io.to(`live:${session_id}`).emit('viewer_count', { count });
      await db.query('UPDATE live_sessions SET viewer_count = $1 WHERE id = $2', [count, session_id]).catch(() => {});
    });

    socket.on('leave_live', async ({ session_id }) => {
      socket.leave(`live:${session_id}`);
      socket.liveSessionId = null;
      const count = io.sockets.adapter.rooms.get(`live:${session_id}`)?.size || 0;
      io.to(`live:${session_id}`).emit('viewer_count', { count });
      await db.query('UPDATE live_sessions SET viewer_count = $1 WHERE id = $2', [count, session_id]).catch(() => {});
    });

    socket.on('send_tip', async ({ session_id, amount, message }) => {
      try {
        const walletResult = await db.query('SELECT balance FROM wallets WHERE user_id = $1', [userId]);
        const balance = walletResult.rows[0]?.balance || 0;
        if (balance < amount) return socket.emit('error', { message: 'Insufficient balance' });

        await db.query('UPDATE wallets SET balance = balance - $1 WHERE user_id = $2', [amount, userId]);
        await db.query('INSERT INTO live_tips (session_id, user_id, amount, message) VALUES ($1, $2, $3, $4)', [session_id, userId, amount, message]);
        await db.query('UPDATE live_sessions SET total_tips = total_tips + $1 WHERE id = $2', [amount, session_id]);

        io.to(`live:${session_id}`).emit('new_tip', {
          user: socket.user.name,
          amount,
          message,
        });
      } catch (err) {
        console.error('Tip error:', err);
      }
    });

    socket.on('live_chat', ({ session_id, message }) => {
      io.to(`live:${session_id}`).emit('live_chat_message', {
        user: socket.user.name,
        message,
        timestamp: new Date(),
      });
    });

    // ─── DISCONNECT ──────────────────────────────────────────────
    socket.on('disconnect', async () => {
      // Update live viewer count if socket was in a live room
      if (socket.liveSessionId) {
        // Socket is removed from rooms before disconnect fires, so size is already decremented
        const count = io.sockets.adapter.rooms.get(`live:${socket.liveSessionId}`)?.size || 0;
        io.to(`live:${socket.liveSessionId}`).emit('viewer_count', { count });
        await db.query('UPDATE live_sessions SET viewer_count = $1 WHERE id = $2', [count, socket.liveSessionId]).catch(() => {});
      }

      if (socket.astrologerId) {
        onlineAstrologers.delete(socket.astrologerId);
        await db.query('UPDATE astrologers SET is_online = false WHERE id = $1', [socket.astrologerId]);
        io.emit('astrologer_offline', { astrologer_id: socket.astrologerId });

        // If astrologer disconnects mid-session, refund user for unused partial minute
        if (socket.consultationId) {
          const engine = billingEngines.get(socket.consultationId);
          if (engine) {
            const partialSeconds = engine.secondsElapsed % 60;
            if (partialSeconds > 0) {
              const refund = parseFloat(((partialSeconds / 60) * engine.ratePerMinute).toFixed(2));
              if (refund > 0) {
                await db.query('UPDATE wallets SET balance = balance + $1 WHERE user_id = $2', [refund, engine.userId]);
              }
            }
            await engine.stop();
            billingEngines.delete(socket.consultationId);
            io.to(`consultation:${socket.consultationId}`).emit('consultation_ended', {
              consultation_id: socket.consultationId,
              reason: 'astrologer_disconnected',
              duration: engine.secondsElapsed,
              total_amount: engine.totalCharged,
            });
          }
        }
      }
      // If user disconnects mid-session, end the active consultation
      if (!socket.astrologerId && socket.consultationId) {
        const engine = billingEngines.get(socket.consultationId);
        if (engine) {
          await engine.stop();
          billingEngines.delete(socket.consultationId);
          io.to(`consultation:${socket.consultationId}`).emit('consultation_ended', {
            consultation_id: socket.consultationId,
            reason: 'user_disconnected',
            duration: engine.secondsElapsed,
            total_amount: engine.totalCharged,
          });
        } else {
          // Consultation may still be queued/active without a billing engine (e.g. chat not yet started)
          await db.query(
            `UPDATE consultations SET status = 'missed', ended_at = NOW() WHERE id = $1 AND status IN ('queued', 'active')`,
            [socket.consultationId]
          ).catch(() => {});
          io.to(`consultation:${socket.consultationId}`).emit('consultation_ended', {
            consultation_id: socket.consultationId,
            reason: 'user_disconnected',
          });
        }
        activeRooms.delete(socket.consultationId);
      }

      onlineUsers.delete(userId);
    });
  });
}

module.exports = { initSocket };
