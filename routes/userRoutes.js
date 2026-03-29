const express = require('express');
const router = express.Router();
const pool = require('../config/db');


// ================= AUTH =================

// SEND OTP
router.post('/auth/send-otp', async (req, res) => {
  const { email } = req.body;

  const otp = Math.floor(100000 + Math.random() * 900000).toString();

  await pool.query(
    `INSERT INTO email_otps(email, otp, expires_at)
     VALUES ($1,$2, NOW() + INTERVAL '5 minutes')`,
    [email, otp]
  );

  console.log("OTP:", otp); // dev only

  res.json({ success: true });
});


// VERIFY OTP
router.post('/auth/verify-otp', async (req, res) => {
  const { email, otp } = req.body;

  const result = await pool.query(
    `SELECT * FROM email_otps
     WHERE email=$1 AND otp=$2 AND expires_at > NOW()
     ORDER BY created_at DESC LIMIT 1`,
    [email, otp]
  );

  if (result.rows.length === 0) {
    return res.json({ error: "Invalid OTP" });
  }

  res.json({ success: true });
});


// REGISTER
router.post('/auth/register', async (req, res) => {
  const { name, email, phone, password, role } = req.body;

  try {
    const user = await pool.query(
      `INSERT INTO users(name, email, phone_number, password, role)
       VALUES ($1,$2,$3,$4,$5)
       RETURNING id`,
      [name, email, phone, password, role || 'user']
    );

    res.json({ success: true, user_id: user.rows[0].id });

  } catch (err) {
    res.json({ error: "User already exists" });
  }
});


// LOGIN
router.post('/auth/login', async (req, res) => {
  const { identifier, password } = req.body;

  const result = await pool.query(
    `SELECT * FROM users
     WHERE (email=$1 OR phone_number=$1) AND password=$2`,
    [identifier, password]
  );

  if (result.rows.length === 0) {
    return res.json({ error: "Invalid credentials" });
  }

  res.json({ success: true, user: result.rows[0] });
});


// ================= RESTAURANTS =================
router.get('/restaurants', async (req, res) => {
  const result = await pool.query(
    `SELECT id, name FROM restaurants WHERE is_open=true`
  );
  res.json(result.rows);
});


// ================= MENU =================
router.get('/menu', async (req, res) => {
  const { restaurant_id } = req.query;

  const result = await pool.query(
    `SELECT * FROM food_items WHERE restaurant_id=$1 AND available=true`,
    [restaurant_id]
  );

  res.json(result.rows);
});


// ================= SEARCH =================
router.get('/search', async (req, res) => {
  const { query } = req.query;

  const food = await pool.query(
    `SELECT name FROM food_items WHERE name ILIKE '%' || $1 || '%'`,
    [query]
  );

  const restaurants = await pool.query(
    `SELECT name FROM restaurants WHERE name ILIKE '%' || $1 || '%'`,
    [query]
  );

  res.json({
    food: food.rows,
    restaurants: restaurants.rows
  });
});


// ================= SUGGESTIONS =================
router.get('/suggestions', async (req, res) => {
  const { query } = req.query;

  const result = await pool.query(
    `SELECT name FROM food_items
     WHERE name ILIKE $1 || '%'
     LIMIT 5`,
    [query]
  );

  res.json(result.rows);
});


// ================= CATEGORIES =================
router.get('/categories', async (req, res) => {
  const result = await pool.query(
    `SELECT DISTINCT category FROM food_items WHERE category IS NOT NULL`
  );

  res.json(result.rows);
});


// ================= ORDER APIs (UNCHANGED) =================

// Place Order
router.post('/place-order', async (req, res) => {
  const { user_id, items, total_amount, address, phone, lat, lng, restaurant_id } = req.body;

  const order = await pool.query(
    `INSERT INTO orders 
     (user_id, total_amount, delivery_address, delivery_phone, payment_type, status, delivery_location)
     VALUES ($1,$2,$3,$4,'cod','new',
     ST_SetSRID(ST_MakePoint($5,$6),4326)::geography)
     RETURNING id`,
    [user_id, total_amount, address, phone, lng, lat]
  );

  const order_id = order.rows[0].id;

  for (let item of items) {
    await pool.query(
      `INSERT INTO order_items (order_id, food_item_id, quantity, price)
       VALUES ($1,$2,$3,$4)`,
      [order_id, item.id, item.qty, item.price]
    );
  }

  await pool.query(
    `INSERT INTO order_restaurants (order_id, restaurant_id, status)
     VALUES ($1,$2,'accepted')`,
    [order_id, restaurant_id]
  );

  res.json({ success: true, order_id });
});


// Order History
router.get('/orders', async (req, res) => {
  const { user_id } = req.query;

  const result = await pool.query(
    `SELECT * FROM orders WHERE user_id=$1 ORDER BY created_at DESC`,
    [user_id]
  );

  res.json(result.rows);
});


// Track Order
router.get('/track-order', async (req, res) => {
  const { order_id } = req.query;

  const result = await pool.query(
    `SELECT status FROM orders WHERE id=$1`,
    [order_id]
  );

  res.json(result.rows[0]);
});


// Cancel Order
router.post('/cancel-order', async (req, res) => {
  const { order_id } = req.body;

  const order = await pool.query(
    `SELECT status FROM orders WHERE id=$1`,
    [order_id]
  );

  if (order.rows[0].status !== 'new') {
    return res.json({ error: "Cannot cancel" });
  }

  await pool.query(
    `UPDATE orders SET status='cancelled' WHERE id=$1`,
    [order_id]
  );

  res.json({ success: true });
});


// ================= PROFILE =================
router.get('/profile', async (req, res) => { console.log('PROFILE API HIT', req.query);
  const { user_id } = req.query;

  const result = await pool.query(
    `SELECT id, name, email, phone_number FROM users WHERE id=$1`,
    [user_id]
  );

  res.json(result.rows[0]);
});
module.exports = router;
