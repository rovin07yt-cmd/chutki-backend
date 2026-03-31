console.log("🔥 USING restaurantRoutes.js");
const express = require('express');
const router = express.Router();
const pool = require('../config/db');
const { assignNearestRider } = require('../controllers/dispatchController');


// ================= AUTH =================

// REGISTER
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


// LOGIN
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


// ================= PROFILE =================

router.get('/profile', async (req, res) => {
  try {
    const { restaurant_id } = req.query;

    const result = await pool.query(
      `SELECT name, owner_name, phone_number, email, address 
       FROM restaurants WHERE id=$1`,
      [restaurant_id]
    );

    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


// ================= MENU =================

// ADD ITEM
router.post('/add-item', async (req, res) => {
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

    const result = await pool.query(
      `INSERT INTO food_items 
       (restaurant_id, name, description, veg_type, subcategory, mrp, price, preparation_time_minutes, available)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,true)
       RETURNING *`,
      [restaurant_id, name, description, veg_type, subcategory, mrp, price, preparation_time]
    );

    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


// GET ITEMS
router.get('/items', async (req, res) => {
  try {
    const { restaurant_id } = req.query;

    const result = await pool.query(
      `SELECT * FROM food_items WHERE restaurant_id=$1 ORDER BY id DESC`,
      [restaurant_id]
    );

    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


// TOGGLE ITEM
router.post('/toggle-item', async (req, res) => {
  try {
    const { item_id, available } = req.body;

    await pool.query(
      `UPDATE food_items SET available=$1 WHERE id=$2`,
      [available, item_id]
    );

    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


// ================= ORDERS =================

// GET ORDERS
router.get('/orders', async (req, res) => {
  try {
    const { restaurant_id, status } = req.query;

    let query = `
      SELECT 
        o.id,
        o.status,
        o.total_amount,
        o.created_at,
        o.assigned_rider_id,
        r.name AS rider_name,
        r.phone_number AS rider_phone,
        json_agg(
          json_build_object(
            'name', fi.name,
            'quantity', oi.quantity,
            'price', oi.price
          )
        ) AS items
      FROM orders o
      JOIN order_restaurants orr ON o.id = orr.order_id
      LEFT JOIN order_items oi ON o.id = oi.order_id
      LEFT JOIN food_items fi ON oi.food_item_id = fi.id
      LEFT JOIN riders r ON o.assigned_rider_id = r.id
      WHERE orr.restaurant_id = $1
    `;

    const values = [restaurant_id];

    if (status) {
      query += ` AND o.status = $2`;
      values.push(status);
    }

    query += ` GROUP BY o.id, r.name, r.phone_number ORDER BY o.created_at DESC`;

    const result = await pool.query(query, values);

    res.json(result.rows);

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


// ORDER ACTION
router.post('/order-action', async (req, res) => {
  try {
    const { order_id, action } = req.body;

    if (action === 'accept') {
      await pool.query(`UPDATE orders SET status='accepted' WHERE id=$1`, [order_id]);
    } else {
      await pool.query(
        `UPDATE orders 
         SET status='cancelled', cancelled_by='restaurant', cancel_reason='Rejected'
         WHERE id=$1`,
        [order_id]
      );
    }

    res.json({ success: true });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


// START PREPARING
router.post('/start-preparing', async (req, res) => {
  try {
    const { order_id, preparation_time } = req.body;

    await pool.query(
      `UPDATE orders 
       SET status='preparing', preparation_time_minutes=$2 
       WHERE id=$1`,
      [order_id, preparation_time]
    );

    res.json({ success: true });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


// MARK READY
router.post('/mark-ready', async (req, res) => {
  try {
    const { order_id } = req.body;

    await pool.query(`UPDATE orders SET status='ready' WHERE id=$1`, [order_id]);

    const check = await pool.query(
      `SELECT assigned_rider_id FROM orders WHERE id=$1`,
      [order_id]
    );

    if (!check.rows[0].assigned_rider_id) {
      await assignNearestRider(order_id);
    }

    await pool.query(
      `UPDATE orders SET status='assigned' WHERE id=$1 AND assigned_rider_id IS NOT NULL`,
      [order_id]
    );

    res.json({ success: true });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


// ================= PAYMENTS =================

// SUMMARY
router.get('/payments/summary', async (req, res) => {
  try {
    const { restaurant_id } = req.query;

    const earned = await pool.query(
      `SELECT COALESCE(SUM(net_amount),0) AS total
       FROM earnings
       WHERE entity_type='restaurant' AND entity_id=$1`,
      [restaurant_id]
    );

    const paid = await pool.query(
      `SELECT COALESCE(SUM(amount),0) AS total
       FROM restaurant_payments
       WHERE restaurant_id=$1`,
      [restaurant_id]
    );

    const yEarned = await pool.query(
      `SELECT COALESCE(SUM(net_amount),0) AS total
       FROM earnings
       WHERE entity_type='restaurant'
       AND entity_id=$1
       AND DATE(created_at)=CURRENT_DATE - INTERVAL '1 day'`,
      [restaurant_id]
    );

    const yPaid = await pool.query(
      `SELECT COALESCE(SUM(amount),0) AS total
       FROM restaurant_payments
       WHERE restaurant_id=$1
       AND DATE(paid_at)=CURRENT_DATE - INTERVAL '1 day'`,
      [restaurant_id]
    );

    res.json({
      total_earned: earned.rows[0].total,
      total_paid: paid.rows[0].total,
      total_pending: earned.rows[0].total - paid.rows[0].total,
      yesterday_earned: yEarned.rows[0].total,
      yesterday_paid: yPaid.rows[0].total,
      yesterday_pending: yEarned.rows[0].total - yPaid.rows[0].total
    });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


// HISTORY
router.get('/payments/history', async (req, res) => {
  try {
    const { restaurant_id } = req.query;

    const result = await pool.query(
      `SELECT amount, paid_at
       FROM restaurant_payments
       WHERE restaurant_id=$1
       ORDER BY paid_at DESC`,
      [restaurant_id]
    );

    res.json(result.rows);

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


module.exports = router;

// ================= BANK DETAILS =================

// GET BANK DETAILS
router.get('/bank-details', async (req, res) => {
  try {
    const { restaurant_id } = req.query;

    const result = await pool.query(
      `SELECT upi_id, account_no, owner_name, ifsc 
       FROM restaurants WHERE id=$1`,
      [restaurant_id]
    );

    res.json(result.rows[0]);

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// UPDATE BANK DETAILS
router.post('/bank-details', async (req, res) => {
  try {
    const { restaurant_id, upi_id, account_no, owner_name, ifsc } = req.body;

    await pool.query(
      `UPDATE restaurants
       SET upi_id=$1, account_no=$2, owner_name=$3, ifsc=$4
       WHERE id=$5`,
      [upi_id, account_no, owner_name, ifsc, restaurant_id]
    );

    res.json({ success: true });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

