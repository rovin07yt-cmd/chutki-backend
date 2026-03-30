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
module.exports = router;
