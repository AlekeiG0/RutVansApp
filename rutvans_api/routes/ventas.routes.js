// routes/ventas.routes.js

const express = require('express');
const router = express.Router();
const Venta = require('../models/venta.model');

// 1. Obtener todas las ventas
router.get('/', async (req, res) => {
  try {
    const ventas = await Venta.find().limit(100);
    res.json(ventas);
  } catch (err) {
    res.status(500).json({ error: 'Error al obtener ventas' });
  }
});

// 2. Obtener una venta por ID
router.get('/:id', async (req, res) => {
  try {
    const venta = await Venta.findById(req.params.id);
    if (!venta) return res.status(404).json({ error: 'No encontrada' });
    res.json(venta);
  } catch (err) {
    res.status(500).json({ error: 'Error al obtener venta' });
  }
});

// 3. Crear una nueva venta
router.post('/', async (req, res) => {
  try {
    const nuevaVenta = new Venta(req.body);
    await nuevaVenta.save();
    res.status(201).json(nuevaVenta);
  } catch (err) {
    res.status(400).json({ error: 'Error al crear venta' });
  }
});

// 4. Actualizar una venta
router.put('/:id', async (req, res) => {
  try {
    const actualizada = await Venta.findByIdAndUpdate(req.params.id, req.body, { new: true });
    res.json(actualizada);
  } catch (err) {
    res.status(400).json({ error: 'Error al actualizar venta' });
  }
});

// 5. Eliminar una venta
router.delete('/:id', async (req, res) => {
  try {
    await Venta.findByIdAndDelete(req.params.id);
    res.json({ mensaje: 'Venta eliminada' });
  } catch (err) {
    res.status(400).json({ error: 'Error al eliminar venta' });
  }
});

module.exports = router;
