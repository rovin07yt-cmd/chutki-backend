const express = require('express');
const router = express.Router();
const pool = require('../config/db');
const { assignNearestRider } = require('../controllers/dispatchController');


// ✅ Get Orders
router.get('/orders', async (req, res) => {
  try {
    const { restaurant_id } = req.query;

    const result = await pool.query(`
      SELECT 
        o.id,
        o.status,
        o.total_amount,
        o.created_at,

        (ROUND(o.total_amount * (settings.value / 100), 2)) AS admin_commission,
        (o.total_amount - (ROUND(o.total_amount * (settings.value / 100), 2))) AS restaurant_earning,

        json_agg(
          json_build_object(
            'name', fi.name,
            'quantity', oi.quantity,
            'price', oi.price
          )
        ) AS items

      FROM orders o
      JOIN order_restaurants r ON o.id = r.order_id
      LEFT JOIN order_items oi ON o.id = oi.order_id
      LEFT JOIN food_items fi ON oi.food_item_id = fi.id

      JOIN (
        SELECT (setting_value::json->>'value')::numeric AS value
        FROM system_settings
        WHERE setting_key = 'admin_commission_percent'
      ) settings ON true

      WHERE r.restaurant_id = $1
      GROUP BY o.id, settings.value
      ORDER BY o.created_at DESC
    `, [restaurant_id]);

    result.rows.forEach(order => {
      if (typeof order.items === "string") {
        order.items = JSON.parse(order.items);
      }
    });

    res.json(result.rows);

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});


// ✅ Add Item
router.post('/add-item', async (req, res) => {
  try {
    const { restaurant_id, name, price, preparation_time } = req.body;

    const result = await pool.query(
      `INSERT INTO food_items 
       (restaurant_id, name, price, preparation_time_minutes, available)
       VALUES ($1,$2,$3,$4,true)
       RETURNING *`,
      [restaurant_id, name, price, preparation_time]
    );

    res.json(result.rows[0]);

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


// ✅ Toggle Item
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


// ✅ Accept / Reject Order
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


// ✅ Start Preparing
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


// ✅ Mark Ready + Auto Assign Rider
router.post('/mark-ready', async (req, res) => {
  try {
    const { order_id } = req.body;

    await pool.query(
      `UPDATE orders SET status='ready' WHERE id=$1`,
      [order_id]
    );

    await assignNearestRider(order_id);

    res.json({ success: true, message: "Order ready + rider assigned" });

  } catch (err) {
    console.error("ASSIGN ERROR:", err);
    res.status(500).json({ error: err.message });
  }
});


module.exports = router;
