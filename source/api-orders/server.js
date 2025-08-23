const express = require('express');
const { Pool } = require('pg');

const app = express();
const PORT = 3000;

app.use(express.json());

// Config DB
const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_DATABASE,
  password: process.env.DB_PASSWORD,
  port: 5432,
});

// --- Routes ---

// Healthz
app.get('/api/orders/healthz', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// Get all orders with items and total
app.get('/api/orders', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT o.id, o.customer_id, o.order_date, o.total,
             json_agg(json_build_object(
               'product_id', i.product_id,
               'quantity', i.quantity,
               'subtotal', i.subtotal
             )) AS items
      FROM orders o
      JOIN order_items i ON o.id = i.order_id
      GROUP BY o.id
      ORDER BY o.id;
    `);
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// Create a new order with items
app.post('/api/orders', async (req, res) => {
  const { customer_id, items } = req.body;
  if (!customer_id || !items || items.length === 0) {
    return res.status(400).json({ error: 'Missing customer_id or items' });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Insert order with total=0 first
    const orderRes = await client.query(
      'INSERT INTO orders (customer_id, total) VALUES ($1, 0) RETURNING id',
      [customer_id]
    );
    const orderId = orderRes.rows[0].id;

    let total = 0;

    for (const item of items) {
      const productRes = await client.query(
        'SELECT price FROM products WHERE id=$1',
        [item.product_id]
      );
      if (productRes.rows.length === 0) {
        throw new Error(`Product ${item.product_id} not found`);
      }
      const price = parseFloat(productRes.rows[0].price);
      const subtotal = price * item.quantity;
      total += subtotal;

      await client.query(
        'INSERT INTO order_items (order_id, product_id, quantity, subtotal) VALUES ($1, $2, $3, $4)',
        [orderId, item.product_id, item.quantity, subtotal]
      );
    }

    // Update total
    await client.query('UPDATE orders SET total=$1 WHERE id=$2', [total, orderId]);

    await client.query('COMMIT');
    res.status(201).json({ message: 'Order created', order_id: orderId, total });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  } finally {
    client.release();
  }
});

app.listen(PORT, () => {
  console.log(`Orders API corriendo en el puerto ${PORT}`);
});
