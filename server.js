require("dotenv").config();
const express = require('express');
const cors = require('cors');
const path = require('path');

const app = express();

app.use(require("cors")({ origin: "*", methods: ["GET","POST","PUT","DELETE"], credentials: true }));
app.use(express.json());

// ✅ FIX: serve uploaded images
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

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
const restaurantRoutes = require('./routes/restaurantRoutes_v2');
const userRoutes = require('./routes/userRoutes');
const authRoutes = require('./routes/authRoutes');

app.use('/api/orders', orderRoutes);
app.use('/api/order-status', statusRoutes);
app.use('/api/riders', riderRoutes);
app.use('/api/users', userRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/delivery', deliveryRoutes);
app.use('/api/rider/location', riderLocationRoutes);
app.use('/api/restaurants', restaurantRoutes);

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log('Server running on port ' + PORT);
});
// redeploy trigger
