const express = require('express');
const router = express.Router();
const Venta = require('../models/venta.model');

// Ruta: GET /api/finanzas/resumen
router.get('/resumen', async (req, res) => {
  try {
    const ventas = await Venta.find();

    const ingresos = ventas.reduce((sum, v) => sum + (v.amount || 0), 0);
    const egresos = 0;
    const balance = ingresos - egresos;

    const ventasPorDia = ventas.reduce((acc, venta) => {
      const fecha = new Date(venta.created_at).toISOString().substring(0, 10);
      acc[fecha] = (acc[fecha] || 0) + (venta.amount || 0);
      return acc;
    }, {});

    const formateadas = Object.entries(ventasPorDia).map(([fecha, total]) => ({
      fecha,
      total,
    }));

    res.json({
      ingresos,
      egresos,
      balance,
      ventasPorDia: formateadas,
      transacciones: ventas,
    });
  } catch (err) {
    res.status(500).json({ error: 'Error al obtener resumen financiero' });
  }
});

// ✅ RUTA CORREGIDA: GET /ventas-detalle?fecha=YYYY-MM-DD
router.get('/ventas-detalle', async (req, res) => {
  try {
    const { fecha } = req.query;
    if (!fecha) return res.status(400).json({ error: 'Fecha requerida' });

    const inicio = new Date(`${fecha}T00:00:00.000Z`);
    const fin = new Date(`${fecha}T23:59:59.999Z`);

    const ventas = await Venta.find({ created_at: { $gte: inicio, $lte: fin } });

    const detalle = ventas.map(v => ({
      folio: v.folio || '-', // asegúrate de que el modelo tenga este campo
      created_at: v.created_at,
      amount: v.amount || 0.0,
    }));

    res.json(detalle);
  } catch (err) {
    res.status(500).json({ error: 'Error al obtener ventas por fecha' });
  }
});

// 2. GET /ventas-periodo
router.get('/ventas-periodo', async (req, res) => {
  try {
    const { desde, hasta } = req.query;
    if (!desde || !hasta) return res.status(400).json({ error: 'Parámetros desde y hasta requeridos' });

    const inicio = new Date(`${desde}T00:00:00.000Z`);
    const fin = new Date(`${hasta}T23:59:59.999Z`);

    const ventas = await Venta.find({ created_at: { $gte: inicio, $lte: fin } });

    const total = ventas.reduce((sum, v) => sum + (v.amount || 0), 0);
    const transacciones = ventas.length;
    const promedio = transacciones > 0 ? total / transacciones : 0;

    res.json({ total, transacciones, promedio });
  } catch (err) {
    res.status(500).json({ error: 'Error al obtener resumen por periodo' });
  }
});

// 3. GET /top-rutas
router.get('/top-rutas', async (req, res) => {
  try {
    const { desde, hasta } = req.query;
    const inicio = new Date(`${desde}T00:00:00.000Z`);
    const fin = new Date(`${hasta}T23:59:59.999Z`);

    const ventas = await Venta.find({ created_at: { $gte: inicio, $lte: fin } });

    const rutas = {};
    for (const v of ventas) {
      const ruta = v.data || 'Desconocida';
      rutas[ruta] = (rutas[ruta] || 0) + (v.amount || 0);
    }

    const total = Object.values(rutas).reduce((a, b) => a + b, 0);
    const lista = Object.entries(rutas).map(([nombre, monto]) => ({
      nombre,
      monto: `$${monto.toFixed(2)}`,
      porcentaje: total > 0 ? monto / total : 0
    }));

    lista.sort((a, b) => b.porcentaje - a.porcentaje);

    res.json(lista);
  } catch (err) {
    res.status(500).json({ error: 'Error al obtener rutas más vendidas' });
  }
});

// 4. GET /balance-historico
router.get('/balance-historico', async (req, res) => {
  try {
    const { desde, hasta, periodo } = req.query;
    if (!desde || !hasta || !periodo) return res.status(400).json({ error: 'Parámetros requeridos' });

    const inicio = new Date(`${desde}T00:00:00.000Z`);
    const fin = new Date(`${hasta}T23:59:59.999Z`);

    const ventas = await Venta.find({ created_at: { $gte: inicio, $lte: fin } });

    const agrupado = {};
    for (const v of ventas) {
      let clave;
      const fecha = new Date(v.created_at);
      if (periodo === 'daily') {
        clave = fecha.toISOString().substring(0, 10);
      } else if (periodo === 'monthly') {
        clave = `${fecha.getFullYear()}-${String(fecha.getMonth() + 1).padStart(2, '0')}`;
      }
      agrupado[clave] = (agrupado[clave] || 0) + (v.amount || 0);
    }

    const resultado = Object.entries(agrupado).map(([fecha, balance]) => ({ fecha, balance }));
    resultado.sort((a, b) => new Date(a.fecha) - new Date(b.fecha));

    res.json(resultado);
  } catch (err) {
    res.status(500).json({ error: 'Error al obtener balance histórico' });
  }
});

// 5. GET /egresos-categorias
router.get('/egresos-categorias', async (req, res) => {
  try {
    return res.status(400).json({ error: 'Aún no hay egresos en el sistema' });
  } catch (err) {
    res.status(500).json({ error: 'Error al obtener egresos' });
  }
});

module.exports = router;
