const express = require('express');
const router = express.Router();
const pool = require('../config/db');
const { assignNearestRider } = require('../controllers/dispatchController');

// ✅ Update Order Status
router.post('/update', async (req, res) => {
  try {
    const { order_id, status } = req.body;

    // 1. Update status
    await pool.query(
      `UPDATE orders SET status=$1 WHERE id=$2`,
      [status, order_id]
    );

    // 2. If ready → assign rider
    if (status === 'ready') {
      await assignNearestRider(order_id);
    }

    res.json({ success: true });

  } catch (err) {
    console.error("STATUS ERROR:", err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
