const express = require('express');
const { Pool } = require('pg'); // Importa el cliente de PostgreSQL

const app = express();
const PORT = 3000;

app.use(express.json());

// Configuración de la conexión a la base de datos
const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_DATABASE,
  password: process.env.DB_PASSWORD,
  port: 5432,
});

// --- Rutas de la API ---

// Ruta de salud
app.get('/api/catalog/healthz', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// Obtener todos los productos DESDE LA BASE DE DATOS
app.get('/api/catalog/products', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM productos ORDER BY id;');
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

app.listen(PORT, () => {
  console.log(`Catalog API corriendo en el puerto ${PORT}`);
});
