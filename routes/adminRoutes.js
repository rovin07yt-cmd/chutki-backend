const express = require('express');
const router = express.Router();
const pool = require('../config/db');

// ================= SETTINGS =================
router.get('/settings', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT setting_key, setting_value 
      FROM system_settings
      WHERE setting_key IN ('rider_commission_per_order','fuel_per_km')
    `);

    const data = {};
    result.rows.forEach(r => {
      let val = r.setting_value;
      if (typeof val === "string") val = JSON.parse(val);
      data[r.setting_key] = Number(val.value) || 0;
    });

    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ================= RESTAURANT DETAILS =================
router.get('/restaurant-full-details', async (req, res) => {
  const { restaurant_id } = req.query;

  const info = await pool.query(
    `SELECT id, name, owner_name, phone_number, upi_id, account_no, ifsc 
     FROM restaurants WHERE id=$1`,
    [restaurant_id]
  );

  const stats = await pool.query(`
    SELECT COUNT(o.id) AS total_orders,
    COALESCE(SUM(o.total_amount),0) AS total
    FROM order_restaurants orr
    JOIN orders o ON o.id = orr.order_id
    WHERE orr.restaurant_id=$1
  `, [restaurant_id]);

  const total = Number(stats.rows[0].total);

  const setting = await pool.query(
    "SELECT setting_value FROM system_settings WHERE setting_key='admin_commission_percent'"
  );

  let raw = setting.rows[0].setting_value;
  if (typeof raw === "string") raw = JSON.parse(raw);

  const percent = Number(raw.value) || 0;
  const commission = total * (percent / 100);

  const paid = await pool.query(`
    SELECT COALESCE(SUM(amount),0) FROM finance_transactions
    WHERE entity_id=$1 AND type='restaurant_payment'
  `, [restaurant_id]);

  const already_paid = Number(paid.rows[0].coalesce);

  res.json({
    info: info.rows[0],
    total_orders: stats.rows[0].total_orders,
    total,
    admin_commission: commission,
    already_paid,
    payable: total - commission - already_paid
  });
});

// ================= PAY RESTAURANT (FIXED) =================
router.post('/pay-restaurant', async (req, res) => {
  try {
    const { restaurant_id, amount } = req.body;

    const bank = await pool.query(
      `SELECT upi_id, account_no, owner_name, ifsc 
       FROM restaurants WHERE id=$1`,
      [restaurant_id]
    );

    const b = bank.rows[0] || {};

    await pool.query(
      `INSERT INTO finance_transactions(type, entity_id, amount, description)
       VALUES ('restaurant_payment',$1,$2,'Paid to restaurant')`,
      [restaurant_id, amount]
    );

    await pool.query(
      `INSERT INTO restaurant_payments
       (restaurant_id, amount, upi_id, bank_account_number, account_holder_name, ifsc_code)
       VALUES ($1,$2,$3,$4,$5,$6)`,
      [
        restaurant_id,
        amount,
        b.upi_id || null,
        b.account_no || null,
        b.owner_name || null,
        b.ifsc || null
      ]
    );

    res.json({ success: true });

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
