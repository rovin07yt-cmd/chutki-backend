const pool = require('../config/db');

exports.markDelivered = async (req, res) => {
  try {
    const { order_id } = req.body;

    await pool.query(
      `UPDATE orders SET status='delivered' WHERE id=$1`,
      [order_id]
    );

    res.json({ success: true });

  } catch (err) {
    console.error("DELIVERY ERROR:", err);
    res.status(500).json({ error: err.message });
  }
};
