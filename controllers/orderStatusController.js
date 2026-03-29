const pool = require('../config/db');
const { assignOrder } = require('./assignController');

exports.updateStatus = async (req, res) => {
  try {
    const { order_id, status } = req.body;

    console.log("STATUS UPDATE CALLED:", order_id, status);

    await pool.query(
      `UPDATE orders SET status = $1, updated_at = NOW() WHERE id = $2`,
      [status, order_id]
    );

    if (status === 'ready') {
      console.log("READY TRIGGERED → ASSIGNING");

      const rider = await pool.query(
        `SELECT id FROM riders WHERE status = 'available' LIMIT 1`
      );

      console.log("RIDER FOUND:", rider.rows);

      if (rider.rows.length > 0) {
        const rider_id = rider.rows[0].id;

        console.log("ASSIGNING TO RIDER:", rider_id);

        await assignOrder(order_id, rider_id);
      } else {
        console.log("NO RIDER → WAITING");

        await pool.query(
          `UPDATE orders SET status = 'waiting', queued_at = NOW() WHERE id = $1`,
          [order_id]
        );
      }
    }

    const updated = await pool.query(
      `SELECT * FROM orders WHERE id = $1`,
      [order_id]
    );

    res.json(updated.rows[0]);

  } catch (err) {
    console.error("STATUS ERROR:", err);
    res.status(500).json({ error: err.message });
  }
};
