const pool = require('../config/db');

exports.markDelivered = async (req, res) => {
  try {
    const { order_id } = req.body;

    // 1. Get rider assignment
    const assign = await pool.query(
      `SELECT rider_id, start_distance 
       FROM rider_assignments 
       WHERE order_id = $1`,
      [order_id]
    );

    if (assign.rows.length === 0) {
      return res.status(400).json({ error: "Assignment not found" });
    }

    const rider_id = assign.rows[0].rider_id;
    const start_distance = assign.rows[0].start_distance || 0;

    // 2. Get current rider distance
    const rider = await pool.query(
      `SELECT total_distance_today FROM riders WHERE id = $1`,
      [rider_id]
    );

    const end_distance = rider.rows[0].total_distance_today || 0;

    const distance = end_distance - start_distance;

    // 3. Update assignment
    await pool.query(
      `UPDATE rider_assignments
       SET status = 'delivered',
           delivered_at = NOW(),
           end_distance = $1
       WHERE order_id = $2`,
      [end_distance, order_id]
    );

    // 4. Update order
    await pool.query(
      `UPDATE orders 
       SET status = 'delivered'
       WHERE id = $1`,
      [order_id]
    );

    // 5. Get order amount
    const order = await pool.query(
      `SELECT total_amount FROM orders WHERE id = $1`,
      [order_id]
    );

    const total = parseFloat(order.rows[0].total_amount);

    // 💰 SETTINGS (you can later fetch from system_settings)
    const rider_per_order = 30;
    const admin_commission = 10;
    const fuel_per_km = 5;

    // 6. Calculate earnings
    const fuel_amount = distance * fuel_per_km;
    const rider_total = rider_per_order + fuel_amount;
    const admin_total = admin_commission;
    const restaurant_total = total - admin_commission;

    // 7. Insert Rider earning
    await pool.query(
      `INSERT INTO earnings (order_id, entity_type, entity_id, gross_amount, net_amount, currency)
       VALUES ($1, 'rider', $2, $3, $3, 'INR')
       ON CONFLICT (order_id, entity_type) DO NOTHING`,
      [order_id, rider_id, rider_total]
    );

    // 8. Insert Admin earning
    await pool.query(
      `INSERT INTO earnings (order_id, entity_type, entity_id, gross_amount, net_amount, currency)
       VALUES ($1, 'admin', 1, $2, $2, 'INR')
       ON CONFLICT (order_id, entity_type) DO NOTHING`,
      [order_id, admin_total]
    );

    // 9. Insert Restaurant earning
    await pool.query(
      `INSERT INTO earnings (order_id, entity_type, entity_id, gross_amount, net_amount, currency)
       VALUES ($1, 'restaurant', 1, $2, $2, 'INR')
       ON CONFLICT (order_id, entity_type) DO NOTHING`,
      [order_id, restaurant_total]
    );

    res.json({
      success: true,
      order_id,
      distance,
      rider_earning: rider_total,
      admin_earning: admin_total,
      restaurant_earning: restaurant_total
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
};
