const pool = require('../config/db');

exports.updateLocation = async (req, res) => {
  try {
    const { rider_id, lat, lng } = req.body;

    await pool.query(
      `UPDATE riders
       SET location_geo = ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography,
           last_location_update = NOW()
       WHERE id = $3`,
      [lng, lat, rider_id]
    );

    res.json({ message: "Location updated" });

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
};
