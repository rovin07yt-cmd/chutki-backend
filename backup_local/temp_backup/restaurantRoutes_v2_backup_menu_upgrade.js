const express = require('express');
const router = express.Router();
const pool = require('../config/db');
const multer = require('multer');
const path = require('path');
const { assignNearestRider } = require('../controllers/dispatchController');

// ================= FILE STORAGE =================
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'uploads/');
  },
  filename: function (req, file, cb) {
    cb(null, Date.now() + path.extname(file.originalname));
  }
});

const upload = multer({ storage: storage });

// ================= OTP SYSTEM =================
router.post('/auth/send-otp', async (req, res) => {
  const { email } = req.body;
  const otp = Math.floor(100000 + Math.random() * 900000).toString();

  await pool.query(
    `INSERT INTO email_otps(email, otp, expires_at)
     VALUES ($1,$2, NOW() + INTERVAL '5 minutes')`,
    [email, otp]
  );

  console.log("RESTAURANT OTP:", otp);
  res.json({ success: true });
});

router.post('/auth/verify-otp', async (req, res) => {
  const { email, otp } = req.body;

  const result = await pool.query(
    `SELECT * FROM email_otps
     WHERE email=$1 AND otp=$2 AND expires_at > NOW()
     ORDER BY expires_at DESC LIMIT 1`,
    [email, otp]
  );

  if (result.rows.length === 0) return res.json({ success: false });

  res.json({ success: true });
});

// ================= AUTH =================
router.post('/register', async (req, res) => {
  const { name, owner_name, phone, email, password, address } = req.body;

  const result = await pool.query(
    `INSERT INTO restaurants (name, owner_name, phone_number, email, password, address)
     VALUES ($1,$2,$3,$4,$5,$6)
     RETURNING id`,
    [name, owner_name, phone, email, password, address]
  );

  res.json({ success: true, restaurant_id: result.rows[0].id });
});

router.post('/login', async (req, res) => {
  const { identifier, password } = req.body;

  const result = await pool.query(
    `SELECT * FROM restaurants 
     WHERE (email=$1 OR phone_number=$1) AND password=$2`,
    [identifier, password]
  );

  if (result.rows.length === 0) return res.json({ success: false });

  res.json({ success: true, restaurant: result.rows[0] });
});

// ================= NEW IMAGE UPLOAD API =================
router.post('/add-item-with-images', upload.array('images', 5), async (req, res) => {
  try {
    const {
      restaurant_id,
      name,
      description,
      veg_type,
      subcategory,
      mrp,
      price,
      preparation_time
    } = req.body;

    const item = await pool.query(
      `INSERT INTO food_items 
       (restaurant_id, name, description, veg_type, subcategory, mrp, price, preparation_time_minutes, available)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,true)
       RETURNING id`,
      [restaurant_id, name, description, veg_type, subcategory, mrp, price, preparation_time]
    );

    const item_id = item.rows[0].id;

    for (let file of req.files) {
      await pool.query(
        `INSERT INTO food_item_images (food_item_id, image_url)
         VALUES ($1,$2)`,
        [item_id, file.filename]
      );
    }

    res.json({ success: true });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ================= KEEP OLD SYSTEM =================
const oldRoutes = require('./restaurantRoutes_backup_before_otp');
router.use('/', oldRoutes);

module.exports = router;
