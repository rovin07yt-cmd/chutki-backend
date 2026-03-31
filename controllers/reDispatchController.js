const pool = require('../config/db');

exports.reDispatchWaitingOrders = async (rider_id) => {
  try {

    while (true) {

      // 1. Get current active orders
      const active = await pool.query(
        `SELECT COUNT(*) FROM rider_assignments
         WHERE rider_id = $1
         AND status IN ('pending','accepted','picked')`,
        [rider_id]
      );

      const active_orders = parseInt(active.rows[0].count);

      // 2. Get max limit
      const setting = await pool.query(
        `SELECT setting_value FROM system_settings
         WHERE setting_key = 'max_orders_per_rider'`
      );

      const limit = setting.rows.length > 0
        ? setting.rows[0].setting_value.limit
        : 1;

      // 3. Stop if full
      if (active_orders >= limit) {
        console.log("Rider reached max capacity");
        break;
      }

      // 4. Get next waiting order
      const order = await pool.query(
        `SELECT id FROM orders
         WHERE status = 'waiting'
         ORDER BY queued_at ASC
         LIMIT 1`
      );

      if (order.rows.length === 0) {
        console.log("No more waiting orders");
        break;
      }

      const order_id = order.rows[0].id;

      // 5. Assign
      await pool.query(
        `INSERT INTO rider_assignments (order_id, rider_id, status, assigned_at)
         VALUES ($1, $2, 'pending', NOW())`,
        [order_id, rider_id]
      );

      await pool.query(
        `UPDATE orders 
         SET status = 'assigned', assigned_rider_id = $1
         WHERE id = $2`,
        [rider_id, order_id]
      );

      console.log("Assigned order:", order_id);
    }

  } catch (err) {
    console.error("REDISPATCH ERROR:", err);
  }
};
