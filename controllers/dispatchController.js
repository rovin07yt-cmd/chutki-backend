const pool = require('../config/db');

exports.assignNearestRider = async (order_id) => {
  try {

    // 1. Get order location
    const orderRes = await pool.query(
      `SELECT delivery_location FROM orders WHERE id = $1`,
      [order_id]
    );

    if (orderRes.rows.length === 0) {
      console.log("❌ ORDER NOT FOUND");
      return;
    }

    const orderLocation = orderRes.rows[0].delivery_location;

    if (!orderLocation) {
      console.log("❌ ORDER LOCATION NULL");
      return;
    }

    // 2. Find nearest available rider with capacity
    const riders = await pool.query(
      `SELECT r.id,
              COUNT(ra.id) AS active_orders,
              ST_Distance(
                r.location_geo,
                o.delivery_location
              ) AS distance
       FROM riders r
       CROSS JOIN (SELECT delivery_location FROM orders WHERE id = $1) o
       LEFT JOIN rider_assignments ra 
         ON r.id = ra.rider_id 
         AND ra.status IN ('pending','accepted','picked')
       WHERE r.status = 'available'
         AND r.location_geo IS NOT NULL
       GROUP BY r.id, r.location_geo, o.delivery_location
       ORDER BY distance ASC`,
      [order_id]
    );

    if (riders.rows.length === 0) {
      console.log("❌ NO RIDERS AVAILABLE");
      return;
    }

    // 3. Get max orders setting
    const setting = await pool.query(
      `SELECT setting_value FROM system_settings 
       WHERE setting_key = 'max_orders_per_rider'`
    );

    const maxOrders = setting.rows.length > 0
      ? setting.rows[0].setting_value.limit
      : 1;

    // 4. Pick first rider with capacity
    let selectedRider = null;

    for (const r of riders.rows) {
      if (r.active_orders < maxOrders) {
        selectedRider = r;
        break;
      }
    }

    if (!selectedRider) {
      console.log("⚠️ ALL RIDERS FULL → WAITING");

      await pool.query(
        `UPDATE orders 
         SET status = 'waiting', queued_at = NOW()
         WHERE id = $1`,
        [order_id]
      );

      return;
    }

    const rider_id = selectedRider.id;

    console.log("✅ ASSIGNED RIDER:", rider_id);

    // 5. Get start distance
    const riderData = await pool.query(
      `SELECT total_distance_today FROM riders WHERE id = $1`,
      [rider_id]
    );

    const start_distance = riderData.rows[0].total_distance_today || 0;

    // 6. Insert assignment
    await pool.query(
      `INSERT INTO rider_assignments 
       (order_id, rider_id, status, assigned_at, start_distance)
       VALUES ($1, $2, 'pending', NOW(), $3)`,
      [order_id, rider_id, start_distance]
    );

    // 7. Update order
    await pool.query(
      `UPDATE orders 
       SET assigned_rider_id = $1, status = 'assigned'
       WHERE id = $2`,
      [rider_id, order_id]
    );

  } catch (err) {
    console.error("DISPATCH ERROR:", err);
  }
};
