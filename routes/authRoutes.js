const express = require('express');
const router = express.Router();

const { login } = require('../controllers/authController');

// 🔐 LOGIN
router.post('/login', login);

module.exports = router;

// ================= OTP SYSTEM =================

let otpStore = {}; // TEMP (later DB)

router.post('/send-otp', (req, res) => {
  const { email, mobile } = req.body;

  if (!email && !mobile) {
    return res.json({ success: false, message: "Email or Mobile required" });
  }

  const key = email || mobile;
  const otp = Math.floor(100000 + Math.random() * 900000);

  otpStore[key] = otp;

  console.log("OTP for", key, "=", otp); // DEBUG

  res.json({ success: true, message: "OTP sent" });
});

router.post('/verify-otp', (req, res) => {
  const { email, mobile, otp } = req.body;

  const key = email || mobile;

  if (otpStore[key] == otp) {
    delete otpStore[key];
    return res.json({ success: true });
  }

  res.json({ success: false, message: "Invalid OTP" });
});

