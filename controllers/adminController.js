const pool = require('../config/db');

exports.updateSetting = async (req, res) => {
  try {
    const { key, value } = req.body;

    await pool.query(
      `UPDATE system_settings
       SET setting_value = jsonb_set(setting_value, '{limit}', $1::jsonb),
           updated_at = NOW()
       WHERE setting_key = $2`,
      [JSON.stringify(value), key]
    );

    res.json({ message: "Setting updated" });

  } catch (err) {
    console.error("ERROR:", err);
    res.status(500).json({ error: err.message });
  }
};
