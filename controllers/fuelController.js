const pool = require('../config/db');

exports.addFuelEarning = async (order_id, rider_id) => {
  try {

    // 1. Get rider distance
    const rider = await pool.query(
      `SELECT total_distance_today FROM riders WHERE id = $1`,
      [rider_id]
    );

    const distance = rider.rows[0].total_distance_today || 0;

    // 2. Get fuel rate
    const setting = await pool.query(
      `SELECT setting_value FROM system_settings
       WHERE setting_key = 'fuel_rate_per_km'`
    );

    const rate = setting.rows.length > 0
      ? setting.rows[0].setting_value.value
      : 0;

    const fuel_amount = distance * rate;

    // 3. Insert earning
    await pool.query(
      `INSERT INTO earnings (order_id, entity_type, entity_id, gross_amount, net_amount, currency)
       VALUES ($1, 'rider', $2, $3, $3, 'INR')`,
      [order_id, rider_id, fuel_amount]
    );

    console.log("Fuel earning added:", fuel_amount);

  } catch (err) {
    console.error("FUEL ERROR:", err);
  }
};
