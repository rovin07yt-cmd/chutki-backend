const express = require('express');
const router = express.Router();
const pool = require('../config/db');

// ✅ Rider Dashboard
router.get('/dashboard', async (req, res) => {
  try {
    const { rider_id } = req.query;

    // ✅ Active Orders
    const activeOrders = await pool.query(`
      SELECT id, status, created_at, total_amount
      FROM orders
      WHERE assigned_rider_id = $1
      AND status IN ('assigned','picked')
      ORDER BY created_at DESC
    `, [rider_id]);

    // ✅ Delivered Orders
    const deliveredOrders = await pool.query(`
      SELECT id, status, created_at, total_amount, delivery_address
      FROM orders
      WHERE assigned_rider_id = $1
      AND status = 'delivered'
      ORDER BY created_at DESC
    `, [rider_id]);

    // ✅ Cancelled Orders
    const cancelledOrders = await pool.query(`
      SELECT id, status, created_at, total_amount
      FROM orders
      WHERE assigned_rider_id = $1
      AND status = 'cancelled'
      ORDER BY created_at DESC
    `, [rider_id]);

    // ✅ Earnings (SAFE)
    const earnings = await pool.query(`
      SELECT 
        COALESCE(SUM(net_amount),0) AS total
      FROM earnings
      WHERE entity_type = 'rider'
      AND entity_id = $1
    `, [rider_id]);

    // ✅ COD collected
    const cod = await pool.query(`
      SELECT COALESCE(SUM(total_amount),0) AS total
      FROM orders
      WHERE assigned_rider_id = $1
      AND cod_collected = true
    `, [rider_id]);

    res.json({
      active_orders: activeOrders.rows,
      delivered_orders: deliveredOrders.rows,
      cancelled_orders: cancelledOrders.rows,
      earnings: {
        today_earnings: earnings.rows[0].total
      },
      cod_collected: cod.rows[0].total
    });

  } catch (err) {
    console.error("RIDER ERROR:", err);
    res.status(500).json({ error: err.message });
  }
});


// ✅ Pickup
router.post('/pickup', async (req, res) => {
  try {
    const { order_id } = req.body;

    await pool.query(`
      UPDATE orders SET status='picked'
      WHERE id=$1
    `, [order_id]);

    res.json({ success: true });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
