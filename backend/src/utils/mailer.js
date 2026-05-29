const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: 'mail.grahvarta.com',
  port: 465,
  secure: true,
  auth: {
    user: 'support@grahvarta.com',
    pass: 'Sis#1605007',
  },
});

exports.sendAstrologerWelcome = async ({ to, name, email, password, loginUrl }) => {
  await transporter.sendMail({
    from: '"Grahvarta" <support@grahvarta.com>',
    to,
    subject: '🎉 Welcome to Grahvarta — Your Astrologer Account is Ready',
    html: `
      <div style="font-family:Arial,sans-serif;max-width:560px;margin:0 auto;background:#0D0D0D;color:#fff;border-radius:12px;overflow:hidden;">
        <div style="background:#E8762A;padding:28px 32px;">
          <h1 style="margin:0;font-size:22px;">Welcome to Grahvarta, ${name}!</h1>
          <p style="margin:8px 0 0;opacity:0.85;font-size:14px;">Your astrologer account has been activated.</p>
        </div>
        <div style="padding:32px;">
          <p style="color:#aaa;font-size:14px;">Your application has been reviewed and approved. Here are your login credentials:</p>
          <div style="background:#1A1A1A;border:1px solid #2A2A2A;border-radius:10px;padding:20px;margin:20px 0;">
            <p style="margin:0 0 10px;color:#aaa;font-size:13px;">Login Email</p>
            <p style="margin:0 0 18px;font-size:16px;font-weight:bold;">${email}</p>
            <p style="margin:0 0 10px;color:#aaa;font-size:13px;">Temporary Password</p>
            <p style="margin:0;font-size:20px;font-weight:bold;color:#E8762A;letter-spacing:2px;">${password}</p>
          </div>
          <p style="color:#aaa;font-size:13px;">Please change your password after your first login.</p>
          <a href="${loginUrl || 'https://astrologer.grahvarta.com'}"
             style="display:inline-block;background:#E8762A;color:#fff;text-decoration:none;padding:14px 28px;border-radius:10px;font-weight:bold;margin-top:16px;">
            Login to Astrologer App
          </a>
          <p style="margin-top:28px;color:#666;font-size:12px;">If you have any questions, reply to this email.</p>
        </div>
      </div>
    `,
  });
};
