// index.js
const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');           // ⬅️ Importa mongoose
const app = express();

// ——————————————
// 1) Conexión a MongoDB
// ——————————————
mongoose.connect('mongodb://localhost:27017/rutvans', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => console.log('🟢 Conectado a MongoDB'))
.catch(err => {
  console.error('🔴 Error al conectar a MongoDB:', err.message);
  process.exit(1);
});

app.use(cors());
app.use(express.json());

// ——————————————
// 2) Rutas
// ——————————————
const ventasRoutes   = require('./routes/ventas.routes');
const finanzasRoutes = require('./routes/finanzas.routes');

app.use('/api/ventas',   ventasRoutes);
app.use('/api/finanzas', finanzasRoutes);

// ——————————————
// 3) Levantar servidor
// ——————————————
const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Servidor activo en http://localhost:${PORT}`);
});
