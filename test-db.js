require('dotenv').config({ path: __dirname + '/.env' });

const pool = require('./config/db');

(async () => {
  try {
    const res = await pool.query('SELECT NOW()');
    console.log("DB OK:", res.rows);
  } catch (err) {
    console.error("DB ERROR:", err);
  } finally {
    process.exit();
  }
})();
