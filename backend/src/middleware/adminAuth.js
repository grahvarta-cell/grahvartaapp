const jwt = require('jsonwebtoken');
const db = require('../config/database');

const authenticateAdmin = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ success: false, message: 'No token provided' });
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    if (decoded.type === 'subadmin') {
      const result = await db.query(
        "SELECT id, email, name, permissions, is_active FROM sub_admins WHERE id = $1 AND is_active = TRUE",
        [decoded.subAdminId]
      );
      if (!result.rows.length) {
        return res.status(403).json({ success: false, message: 'Admin access required' });
      }
      req.admin = { ...result.rows[0], isSuperAdmin: false };
      next();
    } else {
      const result = await db.query(
        "SELECT id, email, name, role FROM users WHERE id = $1 AND role = 'admin'",
        [decoded.userId]
      );
      if (!result.rows.length) {
        return res.status(403).json({ success: false, message: 'Admin access required' });
      }
      req.admin = { ...result.rows[0], isSuperAdmin: true };
      next();
    }
  } catch (err) {
    return res.status(401).json({ success: false, message: 'Invalid token' });
  }
};

const requirePermission = (requiredPermission) => {
  return (req, res, next) => {
    if (req.admin.isSuperAdmin) {
      return next();
    }
    if (req.admin.permissions && req.admin.permissions.includes(requiredPermission)) {
      return next();
    }
    return res.status(403).json({ success: false, message: 'Access denied' });
  };
};

module.exports = { authenticateAdmin, requirePermission };
