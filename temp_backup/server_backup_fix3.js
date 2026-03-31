require("dotenv").config();
const express = require('express');
const cors = require('cors');

const app = express();

app.use(cors({ origin: "*" }));
app.use(express.json());

app.get('/', (req, res) => {
  res.send('API Running...');
});

// Routes
const orderRoutes = require('./routes/orderRoutes');
const statusRoutes = require('./routes/orderStatusRoutes');
const riderRoutes = require('./routes/riderRoutes');
const adminRoutes = require('./routes/adminRoutes');
const deliveryRoutes = require('./routes/deliveryRoutes');
const riderLocationRoutes = require('./routes/riderLocationRoutes');

// ✅ SWITCHED TO V2
const restaurantRoutes = require('./routes/restaurantRoutes_v2');

const userRoutes = require('./routes/userRoutes');

app.use('/api/orders', orderRoutes);
app.use('/api/order-status', statusRoutes);
app.use('/api/riders', riderRoutes);
app.use('/api/users', userRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/delivery', deliveryRoutes);
app.use('/api/rider/location', riderLocationRoutes);
app.use('/api/restaurants', restaurantRoutes);

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log('Server running on port ' + PORT);
});
