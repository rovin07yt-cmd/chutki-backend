const pool = require('../config/db');

exports.calculateEarnings = async (order_id) => {
  try {

    // 1. Get order + rider
    const orderRes = await pool.query(
      `SELECT o.total_amount, o.assigned_rider_id, o.delivery_location,
              r.location_geo
       FROM orders o
       JOIN riders r ON o.assigned_rider_id = r.id
       WHERE o.id = $1`,
      [order_id]
    );

    const order = orderRes.rows[0];
    const total = parseFloat(order.total_amount);

    // 2. Get settings
    const settings = await pool.query(
      `SELECT setting_key, setting_value FROM system_settings`
    );

    let config = {};
    settings.rows.forEach(row => {
      config[row.setting_key] = row.setting_value.value;
    });

    const delivery_charge = config.delivery_charge || 40;
    const rider_per_order = config.rider_per_order || 30;
    const fuel_per_km = config.fuel_per_km || 5;
    const admin_percent = config.admin_commission_percent || 10;

    // 3. REAL DISTANCE (meters → km)
    const distRes = await pool.query(
      `SELECT ST_Distance($1::geography, $2::geography) AS distance`,
      [order.location_geo, order.delivery_location]
    );

    const distance_km = (distRes.rows[0].distance || 0) / 1000;

    // 4. Calculate
    const food_amount = total - delivery_charge;

    const fuel_cost = distance_km * fuel_per_km;
    const rider_earning = rider_per_order + fuel_cost;

    const admin_commission = (food_amount * admin_percent) / 100;

    const restaurant_amount = food_amount - admin_commission;

    const admin_delivery_profit = delivery_charge - rider_earning;

    // 5. Save earnings
    await pool.query(
      `INSERT INTO earnings (order_id, entity_type, entity_id, gross_amount, net_amount, currency)
       VALUES 
       ($1, 'rider', 1, $2, $2, 'INR'),
       ($1, 'admin', 1, $3, $3, 'INR'),
       ($1, 'restaurant', 1, $4, $4, 'INR')`,
      [
        order_id,
        rider_earning,
        admin_commission + admin_delivery_profit,
        restaurant_amount
      ]
    );

    console.log("Distance KM:", distance_km.toFixed(2));

  } catch (err) {
    console.error("EARNINGS ERROR:", err);
  }
};
