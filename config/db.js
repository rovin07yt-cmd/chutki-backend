const { Pool } = require('pg');

const pool = new Pool({
  host: '34.196.24.162', // 🔥 working IP
  port: 5432,
  user: 'neondb_owner',
  password: 'npg_T2klMpXZtLD9',
  database: 'neondb',

  ssl: {
    rejectUnauthorized: false,
    servername: 'ep-tiny-waterfall-a4693veh.us-east-1.aws.neon.tech' // 🔥 SNI fix
  },

  connectionTimeoutMillis: 20000
});

module.exports = pool;
