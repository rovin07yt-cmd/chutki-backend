const db = require("../config/db");
const express = require('express');
const router = express.Router();
const pool = require('../config/db');
const multer = require('multer');
const path = require('path');
const { assignNearestRider } = require('../controllers/dispatchController');

// ================= FILE STORAGE =================
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, 'uploads/'),
  filename: (req, file, cb) => cb(null, Date.now() + path.extname(file.originalname))
});
const upload = multer({ storage });

// ================= OTP =================
router.post('/auth/send-otp', async (req, res) => {
  const { email } = req.body;
  const otp = Math.floor(100000 + Math.random() * 900000).toString();

  await pool.query(
    `INSERT INTO email_otps(email, otp, expires_at)
     VALUES ($1,$2,NOW() + INTERVAL '5 minutes')`,
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
     ORDER BY created_at DESC LIMIT 1`,
    [email, otp]
  );

  res.json({ success: result.rows.length > 0 });
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

// ================= ADD ITEM =================
router.post('/add-item-with-images', upload.array('images', 5), async (req, res) => {
  try {
    const { restaurant_id, name, description, veg_type, subcategory, mrp, price, preparation_time } = req.body;

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

// ================= UPDATE ITEM WITH IMAGES =================
router.post('/update-item-with-images', upload.array('images', 5), async (req, res) => {
if(req.body.keep_old_images){ req.files = null; }
  try {
    const { item_id, name, description, veg_type, subcategory, mrp, price, preparation_time } = req.body;

    // update item
    await pool.query(`
      UPDATE food_items SET
      name=$1, description=$2, veg_type=$3, subcategory=$4,
      mrp=$5, price=$6, preparation_time_minutes=$7
      WHERE id=$8
    `,[name, description, veg_type, subcategory, mrp, price, preparation_time, item_id]);

    // delete old images
    await pool.query(`DELETE FROM food_item_images WHERE food_item_id=$1`,[item_id]);

    // insert new images
    for (let file of req.files) {
      await pool.query(
        `INSERT INTO food_item_images (food_item_id, image_url)
         VALUES ($1,$2)`,
        [item_id, file.filename]
      );
    }

    res.json({ success:true });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ================= MENU ENHANCED =================
router.get('/items-with-images', async (req, res) => {
  const { restaurant_id } = req.query;

  const result = await pool.query(`
    SELECT fi.*, 
    (SELECT image_url FROM food_item_images WHERE food_item_id = fi.id LIMIT 1) AS image
    FROM food_items fi
    WHERE restaurant_id=$1
    ORDER BY id DESC
  `,[restaurant_id]);

  res.json(result.rows);
});

router.get('/item', async (req, res) => {
  const { item_id } = req.query;

  const item = await pool.query(`SELECT * FROM food_items WHERE id=$1`,[item_id]);
  const images = await pool.query(`SELECT image_url FROM food_item_images WHERE food_item_id=$1`,[item_id]);

  res.json({ ...item.rows[0], images: images.rows });
});

// ================= OLD ROUTES =================

// EXPORT LAST

// DELETE ITEM
router.post('/delete-item', async (req, res) => {
console.log("DELETE HIT:", req.body);
console.log("DELETE HIT:", req.body);
  const { item_id } = req.body;

  try {
    if (!item_id) {
      return res.json({ success: false, message: "item_id required" });
    }

    // delete images first
    await pool.query(
      "DELETE FROM food_item_images WHERE food_item_id = $1",
      [item_id]
    );

    // delete item
    await pool.query(
      "DELETE FROM food_items WHERE id = $1",
      [item_id]
    );

    res.json({ success: true });

  } catch (err) {
    console.log("DELETE ERROR:", err);
    res.json({ success: false });
  }
});


// TOGGLE RESTAURANT STATUS


// TOGGLE ITEM AVAILABILITY
router.post('/toggle-item-availability', async (req, res) => {
  const { item_id, is_available } = req.body;

  try {
    await pool.query(
      "UPDATE food_items SET is_available=$1 WHERE id=$2",
      [is_available, item_id]
    );

    res.json({ success: true });

  } catch (err) {
    console.log("ITEM STATUS ERROR:", err);
    res.json({ success: false });
  }
});


// TOGGLE RESTAURANT STATUS + AUTO ITEMS
router.post('/toggle-restaurant-status', async (req, res) => {
  const { restaurant_id, is_open } = req.body;

  try {
    await pool.query(
      "UPDATE restaurants SET is_open=$1 WHERE id=$2",
      [is_open, restaurant_id]
    );

    // AUTO UPDATE ALL ITEMS
    await pool.query(
      "UPDATE food_items SET is_available=$1 WHERE restaurant_id=$2",
      [is_open, restaurant_id]
    );

    res.json({ success: true });

  } catch (err) {
    console.log(err);
    res.json({ success: false });
  }
});


// GET RESTAURANT STATUS
router.get('/status', async (req, res) => {
  const { restaurant_id } = req.query;

  const r = await pool.query(
    "SELECT is_open FROM restaurants WHERE id=$1",
    [restaurant_id]
  );

  res.json(r.rows[0]);
});

// UPDATE ORDER STATUS
router.post("/update-order-status", async (req, res) => {
  const { order_id, status } = req.body;
  try {
    await pool.query("UPDATE orders SET status=$1 WHERE id=$2",[status, order_id]);
    res.json({ success:true });
  } catch(err){
    console.log("ORDER UPDATE ERROR:", err);
    res.json({ success:false });
  }
});



// AUTO DISPATCH WHEN READY
router.post("/mark-ready", async (req, res) => {
  const { order_id } = req.body;

  try {
    await pool.query(
      "UPDATE orders SET status='ready' WHERE id=$1",
      [order_id]
    );

    await assignNearestRider(order_id);

    res.json({ success: true });

  } catch (err) {
    console.log("MARK READY ERROR:", err);
    res.json({ success: false });
  }
});


// ================= PROFILE =================

// GET PROFILE (UPDATED)
router.get('/profile', async (req, res) => {
  try {
    const { restaurant_id } = req.query;

    const result = await pool.query(
      `SELECT name, owner_name, phone_number, email, address, profile_image
       FROM restaurants WHERE id=$1`,
      [restaurant_id]
    );

    res.json(result.rows[0]);
  } catch (err) {
    console.log("PROFILE GET ERROR:", err);
    res.json({});
  }
});


// UPDATE PROFILE
router.post('/profile', async (req, res) => {
  try {
    const { restaurant_id, name, email, owner, mobile } = req.body;

    await pool.query(
      `UPDATE restaurants SET
        name=$1,
        email=$2,
        owner_name=$3,
        phone_number=$4
      WHERE id=$5`,
      [name, email, owner, mobile, restaurant_id]
    );

    res.json({ success: true });
  } catch (err) {
    console.log("PROFILE UPDATE ERROR:", err);
    res.json({ success: false });
  }
});


// UPLOAD PROFILE IMAGE
router.post('/upload-profile-image', upload.single('image'), async (req, res) => {
  try {
    const { restaurant_id } = req.body;

    if (!req.file) {
      return res.json({ success: false });
    }

    const filename = req.file.filename;

    await pool.query(
      `UPDATE restaurants SET profile_image=$1 WHERE id=$2`,
      [filename, restaurant_id]
    );

    res.json({ success: true, image: filename });
  } catch (err) {
    console.log("UPLOAD ERROR:", err);
    res.json({ success: false });
  }
});


// CHANGE PASSWORD
router.post('/change-password', async (req, res) => {
  try {
    const { restaurant_id, old_password, new_password } = req.body;

    const check = await pool.query(
      `SELECT password FROM restaurants WHERE id=$1`,
      [restaurant_id]
    );

    if (!check.rows.length || check.rows[0].password !== old_password) {
      return res.json({ success: false, message: "Wrong password" });
    }

    await pool.query(
      `UPDATE restaurants SET password=$1 WHERE id=$2`,
      [new_password, restaurant_id]
    );

    res.json({ success: true });
  } catch (err) {
    console.log("PASSWORD ERROR:", err);
    res.json({ success: false });
  }
});


// FINAL EXPORT
module.exports = router;

