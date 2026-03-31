const pool = require('../config/db');
const { reDispatchWaitingOrders } = require('./reDispatchController');

exports.updateRiderStatus = async (req, res) => {
  try {
    const { rider_id, status } = req.body;

    await pool.query(
      `UPDATE riders SET status = $1, updated_at = NOW()
       WHERE id = $2`,
      [status, rider_id]
    );

    // 🚀 If rider becomes available → trigger re-dispatch
    if (status === 'available') {
      await reDispatchWaitingOrders(rider_id);
    }

    res.json({ message: "Rider status updated" });

  } catch (err) {
    console.error("ERROR:", err);
    res.status(500).json({ error: err.message });
  }
};
