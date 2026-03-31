const express = require('express');
const router = express.Router();
const pool = require('../config/db');
const { assignNearestRider } = require('../controllers/dispatchController');


// ================= OTP SYSTEM =================

// SEND OTP
router.post('/auth/send-otp', async (req, res) => {
  try {
    const { email } = req.body;

    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    await pool.query(
      `INSERT INTO email_otps(email, otp, expires_at)
       VALUES ($1,$2, NOW() + INTERVAL '5 minutes')`,
      [email, otp]
    );

    console.log("RESTAURANT OTP:", otp);

    res.json({ success: true });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


// VERIFY OTP
router.post('/auth/verify-otp', async (req, res) => {
  try {
    const { email, otp } = req.body;

    const result = await pool.query(
      `SELECT * FROM email_otps
       WHERE email=$1 AND otp=$2 AND expires_at > NOW()
       ORDER BY expires_at DESC LIMIT 1`,
      [email, otp]
    );

    if (result.rows.length === 0) {
      return res.json({ success: false });
    }

    res.json({ success: true });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


// ================= AUTH =================

// REGISTER (UNCHANGED)
router.post('/register', async (req, res) => {
  try {
    const { name, owner_name, phone, email, password, address } = req.body;

    const result = await pool.query(
      `INSERT INTO restaurants (name, owner_name, phone_number, email, password, address)
       VALUES ($1,$2,$3,$4,$5,$6)
       RETURNING id`,
      [name, owner_name, phone, email, password, address]
    );

    res.json({ success: true, restaurant_id: result.rows[0].id });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


// LOGIN (UNCHANGED)
router.post('/login', async (req, res) => {
  try {
    const { identifier, password } = req.body;

    const result = await pool.query(
      `SELECT * FROM restaurants 
       WHERE (email=$1 OR phone_number=$1) AND password=$2`,
      [identifier, password]
    );

    if (result.rows.length === 0) return res.json({ success: false });

    res.json({ success: true, restaurant: result.rows[0] });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


// ================= KEEP EVERYTHING SAME =================

// We import original routes to avoid breaking anything
const originalRoutes = require('./restaurantRoutes_backup_before_otp');
router.use('/', originalRoutes);

module.exports = router;
