// models/venta.model.js

const mongoose = require('mongoose');

const ventaSchema = new mongoose.Schema({
  folio: String,
  id_user: Number,
  id_payment: Number,
  id_route_unit_schedule: Number,
  id_rate: Number,
  data: String, // puedes parsearlo como JSON si lo deseas
  status: String,
  amount: Number,
  created_at: Date,
  updated_at: Date
}, {
  collection: 'sales'
});

module.exports = mongoose.model('Venta', ventaSchema);
