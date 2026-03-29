const pool = require('../config/db');

exports.login = async (req, res) => {
  const { identifier, password, role } = req.body;

  try {
    let result;

    // 🔹 USER LOGIN
    if (role === 'user') {
      result = await pool.query(
        `SELECT * FROM users 
         WHERE (email=$1 OR phone_number=$1) AND password=$2`,
        [identifier, password]
      );
    }

    // 🔹 RESTAURANT LOGIN
    else if (role === 'restaurant') {
      result = await pool.query(
        `SELECT * FROM restaurants 
         WHERE (email=$1 OR phone_number=$1) AND password=$2`,
        [identifier, password]
      );
    }

    // 🔹 RIDER LOGIN
    else if (role === 'rider') {
      result = await pool.query(
        `SELECT * FROM riders 
         WHERE (phone_number=$1 OR email=$1) AND password=$2`,
        [identifier, password]
      );
    }

    // 🔹 ADMIN LOGIN
    else if (role === 'admin') {
      result = await pool.query(
        `SELECT * FROM admins 
         WHERE (email=$1 OR phone_number=$1) AND password=$2`,
        [identifier, password]
      );
    }

    // ❌ INVALID ROLE
    else {
      return res.json({ success: false, message: "Invalid role" });
    }

    // ❌ NO USER FOUND
    if (!result || result.rows.length === 0) {
      return res.json({ success: false, message: "Invalid credentials" });
    }

    // ✅ SUCCESS
    res.json({
      success: true,
      role: role,
      data: result.rows[0]
    });

  } catch (err) {
    console.log("LOGIN ERROR:", err);
    res.status(500).json({ success: false });
  }
};
