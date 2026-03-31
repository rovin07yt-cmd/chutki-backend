const express = require('express');
const router = express.Router();
const controller = require('../controllers/riderLocationController');

router.post('/update', controller.updateLocation);

module.exports = router;
