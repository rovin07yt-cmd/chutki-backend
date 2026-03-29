const express = require('express');
const router = express.Router();

const { login } = require('../controllers/authController');

// 🔐 LOGIN
router.post('/login', login);

module.exports = router;
