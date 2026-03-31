const express = require('express');
const router = express.Router();
const pool = require('../config/db');

router.post('/deliver', async (req, res) => {
  try {
    const { order_id, collected } = req.body;

    // 1. Get order amount
    const order = await pool.query(
      `SELECT total_amount FROM orders WHERE id=$1`,
      [order_id]
    );

    const amount = parseFloat(order.rows[0].total_amount);

    // 2. Mark delivered
    await pool.query(
      `UPDATE orders 
       SET status='delivered',
           cod_collected=$1,
           payment_collected_amount=$2
       WHERE id=$3`,
      [collected, collected ? amount : 0, order_id]
    );

    // 3. Get admin commission %
    const setting = await pool.query(
      `SELECT (setting_value->>'value')::numeric AS percent
       FROM system_settings
       WHERE setting_key = 'admin_commission_percent'`
    );

    const percent = setting.rows[0]?.percent || 10;

    const admin_commission = (amount * percent) / 100;
    const restaurant_earning = amount - admin_commission;

    // 4. Insert restaurant earning (safe)
    await pool.query(
      `INSERT INTO earnings (order_id, entity_type, entity_id, gross_amount, net_amount)
       SELECT o.id, 'restaurant', r.restaurant_id, $2, $3
       FROM order_restaurants r
       JOIN orders o ON o.id = r.order_id
       WHERE o.id = $1
       ON CONFLICT (order_id, entity_type) DO NOTHING`,
      [order_id, amount, restaurant_earning]
    );

    // 5. Insert admin earning (safe)
    await pool.query(
      `INSERT INTO earnings (order_id, entity_type, entity_id, gross_amount, net_amount)
       VALUES ($1, 'admin', 1, $2, $3)
       ON CONFLICT (order_id, entity_type) DO NOTHING`,
      [order_id, amount, admin_commission]
    );

    res.json({ success: true });

  } catch (err) {
    console.error("DELIVERY ERROR:", err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
