const pool = require('../config/db');

// LOGIN (ALL ROLES)
exports.login = async (req, res) => {
  try {
    const { identifier, password } = req.body;

    // USER
    let result = await pool.query(
      `SELECT id, name, email, phone_number, 'user' AS role
       FROM users
       WHERE (email=$1 OR phone_number=$1) AND password=$2`,
      [identifier, password]
    );

    if (result.rows.length > 0) {
      return res.json({ success: true, user: result.rows[0] });
    }

    // RESTAURANT
    result = await pool.query(
      `SELECT id, name, email, phone_number, 'restaurant' AS role
       FROM restaurants
       WHERE (email=$1 OR phone_number=$1) AND password=$2`,
      [identifier, password]
    );

    if (result.rows.length > 0) {
      return res.json({ success: true, user: result.rows[0] });
    }

    // RIDER
    result = await pool.query(
      `SELECT id, name, email, phone_number, 'rider' AS role
       FROM riders
       WHERE (email=$1 OR phone_number=$1) AND password=$2`,
      [identifier, password]
    );

    if (result.rows.length > 0) {
      return res.json({ success: true, user: result.rows[0] });
    }

    return res.json({ success: false, message: "Invalid credentials" });

  } catch (err) {
    console.error("LOGIN ERROR:", err);
    res.status(500).json({ success: false });
  }
};
