const express = require('express');
const router = express.Router();

const { login } = require('../controllers/authController');

// 🔐 LOGIN
router.post('/login', login);


// ================= OTP SYSTEM =================

let otpStore = {}; // TEMP
// AUTO CLEANUP EVERY 1 MIN
setInterval(() => {
  const now = Date.now();
  for (let key in otpStore) {
    if (otpStore[key].expires < now) {
      delete otpStore[key];
    }
  }
}, 60000);


router.post('/send-otp', (req, res) => {
  const { email, mobile } = req.body;

  if (!email && !mobile) {
    return res.json({ success: false, message: "Email or Mobile required" });
  }

  const key = email || mobile;
  const otp = Math.floor(100000 + Math.random() * 900000);

  otpStore[key] = {
    otp,
    expires: Date.now() + 5 * 60 * 1000 // 5 min
  };

  console.log("OTP for", key, "=", otp);

  res.json({ success: true });
});

router.post('/verify-otp', (req, res) => {
  const { email, mobile, otp } = req.body;

  const key = email || mobile;
  const record = otpStore[key];

  if (!record) {
    return res.json({ success: false, message: "No OTP found" });
  }

  if (Date.now() > record.expires) {
    delete otpStore[key];
    return res.json({ success: false, message: "OTP expired" });
  }

  if (record.otp == otp) {
    delete otpStore[key];
    return res.json({ success: true });
  }

  res.json({ success: false, message: "Invalid OTP" });
});


// ================= REGISTER =================
const pool = require('../config/db');

router.post('/register', async (req, res) => {
  const { name, email, phone, password, role } = req.body;

  try {
    if (!email) {
      return res.json({ success: false, message: "Email required" });
    }

    let result;

    // USER REGISTER
    if (role === "user") {
      result = await pool.query(
        `INSERT INTO users(name, email, phone_number, password)
         VALUES ($1,$2,$3,$4)
         RETURNING id`,
        [name, email, phone, password]
      );
    }

    // RESTAURANT REGISTER
    else if (role === "restaurant") {
      result = await pool.query(
        `INSERT INTO restaurants(name, owner_name, phone_number, email, password)
         VALUES ($1,$2,$3,$4,$5)
         RETURNING id`,
        [req.body.restaurant_name, req.body.owner_name, phone, email, password]
      );
    }

    // RIDER REGISTER
    else if (role === "rider") {
      result = await pool.query(
        `INSERT INTO riders(name, phone_number, email, password)
         VALUES ($1,$2,$3,$4)
         RETURNING id`,
        [name, phone, email, password]
      );
    }

    else {
      return res.json({ success: false, message: "Invalid role" });
    }

    res.json({ success: true, user: { id: result.rows[0].id, name, email, phone, role } });

  } catch (err) {
    console.log("REGISTER ERROR:", err);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

module.exports = router;
