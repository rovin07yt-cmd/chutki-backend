const pool = require('../config/db');

exports.assignOrder = async (order_id, rider_id) => {
  try {

    // 1. Get rider current distance
    const rider = await pool.query(
      `SELECT total_distance_today FROM riders WHERE id = $1`,
      [rider_id]
    );

    const start_distance = rider.rows[0].total_distance_today || 0;

    // 2. Insert assignment with start distance
    await pool.query(
      `INSERT INTO rider_assignments 
       (order_id, rider_id, status, assigned_at, start_distance)
       VALUES ($1, $2, 'pending', NOW(), $3)`,
      [order_id, rider_id, start_distance]
    );

    // 3. Update order
    await pool.query(
      `UPDATE orders 
       SET assigned_rider_id = $1, status = 'assigned'
       WHERE id = $2`,
      [rider_id, order_id]
    );

  } catch (err) {
    console.error("ASSIGN ERROR:", err);
  }
};
