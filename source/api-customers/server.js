const express = require('express');
const { Pool } = require('pg'); // Importa el cliente de PostgreSQL

const app = express();
const PORT = 3000;

app.use(express.json());

// Configuración de la conexión a la base de datos
// Lee las variables de entorno inyectadas por Kubernetes
const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_DATABASE,
  password: process.env.DB_PASSWORD,
  port: 5432,
});

// Lee la clave de cifrado desde las variables de entorno
const encryptionKey = process.env.ENCRYPTION_KEY;

// --- Rutas de la API ---

// Ruta de salud obligatoria
app.get('/api/customers/healthz', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// Obtener todos los clientes (con número de identidad descifrado)
app.get('/api/customers', async (req, res) => {
  try {
    const query = `
      SELECT id, full_name, email, pgp_sym_decrypt(identity_number, $1) as identity_number
      FROM customers;
    `;
    const result = await pool.query(query, [encryptionKey]);
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// Crear un nuevo cliente (cifrando el número de identidad)
app.post('/api/customers', async (req, res) => {
  const { full_name, email, identity_number } = req.body;

  if (!full_name || !email || !identity_number) {
    return res.status(400).json({ error: 'Faltan datos requeridos' });
  }

  try {
    const query = `
      INSERT INTO customers (full_name, email, identity_number)
      VALUES ($1, $2, pgp_sym_encrypt($3, $4))
      RETURNING id;
    `;
    const result = await pool.query(query, [full_name, email, identity_number, encryptionKey]);
    res.status(201).json({ message: 'Cliente creado', customerId: result.rows[0].id });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});


app.listen(PORT, () => {
  console.log(`Customers API corriendo en el puerto ${PORT}`);
});
