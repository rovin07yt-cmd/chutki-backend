const pool = require('../config/db');

exports.createOrder = async (req, res) => {
  try {
    const { 
      user_id, 
      total_amount, 
      address, 
      phone, 
      lat, 
      lng,
      restaurant_id,
      items 
    } = req.body;

    // 🔹 1. Create Order
    const orderResult = await pool.query(
      `INSERT INTO orders 
      (user_id, total_amount, delivery_address, delivery_phone, payment_type, status, delivery_location)
      VALUES (
        $1, $2, $3, $4, 'cod', 'new',
        ST_SetSRID(ST_MakePoint($6::double precision, $5::double precision), 4326)
      )
      RETURNING *`,
      [user_id, total_amount, address, phone, lat, lng]
    );

    const order = orderResult.rows[0];

    // 🔹 2. Link Restaurant
    await pool.query(
      `INSERT INTO order_restaurants (order_id, restaurant_id)
       VALUES ($1, $2)`,
      [order.id, restaurant_id]
    );

    // 🔹 3. Insert Items
    for (let item of items) {
      await pool.query(
        `INSERT INTO order_items 
         (order_id, food_item_id, quantity, portion, price)
         VALUES ($1, $2, $3, $4, $5)`,
        [
          order.id,
          item.food_item_id,
          item.quantity,
          item.portion,
          item.price
        ]
      );
    }

    res.json(order);

  } catch (err) {
    console.error("ORDER ERROR:", err);
    res.status(500).json({ error: err.message });
  }
};
