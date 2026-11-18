const express = require('express');
const cors = require('cors');
const mysql = require('mysql2/promise');

const app = express();

// CORS: permite a origem da VM1 e os métodos GET, POST e OPTIONS
const origens = (process.env.CORS_ORIGIN || '*').split(',').map((s) => s.trim());
app.use(
  cors({
    origin: origens.includes('*') ? '*' : origens,
    methods: ['GET', 'POST', 'OPTIONS'],
    allowedHeaders: ['Content-Type'],
  })
);
app.use(express.json());

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'db',
  user: process.env.DB_USER || 'cursos',
  password: process.env.DB_PASSWORD || 'cursospass',
  database: process.env.DB_NAME || 'cursos_db',
  waitForConnections: true,
  connectionLimit: 10,
  decimalNumbers: true,
});

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function initDb() {
  for (let i = 1; i <= 30; i++) {
    try {
      await pool.query(`
        CREATE TABLE IF NOT EXISTS cursos (
          id INT AUTO_INCREMENT PRIMARY KEY,
          nome VARCHAR(150) NOT NULL,
          instrutor VARCHAR(150) NOT NULL,
          preco DECIMAL(10,2) NOT NULL,
          vagas INT NOT NULL
        )`);
      console.log('Banco pronto.');
      return;
    } catch (e) {
      console.log(`Aguardando MySQL (${i}/30): ${e.code || e.message}`);
      await sleep(2000);
    }
  }
  throw new Error('Não foi possível conectar ao MySQL');
}

app.post('/curso', async (req, res) => {
  const { nome, instrutor, preco, vagas } = req.body || {};
  const precoNum = Number(String(preco).replace(',', '.'));
  const vagasNum = Number(vagas);

  if (
    typeof nome !== 'string' || !nome.trim() ||
    typeof instrutor !== 'string' || !instrutor.trim() ||
    !Number.isFinite(precoNum) || precoNum < 0 ||
    !Number.isInteger(vagasNum) || vagasNum < 0
  ) {
    return res.status(400).json({ erro: 'Dados inválidos: informe nome, instrutor, preco (decimal) e vagas (inteiro).' });
  }

  try {
    const [r] = await pool.query(
      'INSERT INTO cursos (nome, instrutor, preco, vagas) VALUES (?, ?, ?, ?)',
      [nome.trim(), instrutor.trim(), precoNum, vagasNum]
    );
    res.status(201).json({ id: r.insertId, nome: nome.trim(), instrutor: instrutor.trim(), preco: precoNum, vagas: vagasNum });
  } catch (e) {
    console.error(e);
    res.status(500).json({ erro: 'Erro ao gravar no banco.' });
  }
});

app.get('/cursos', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT id, nome, instrutor, preco, vagas FROM cursos ORDER BY id');
    res.json(rows);
  } catch (e) {
    console.error(e);
    res.status(500).json({ erro: 'Erro ao consultar o banco.' });
  }
});

initDb()
  .then(() => app.listen(3000, () => console.log('API na porta 3000')))
  .catch((e) => {
    console.error(e);
    process.exit(1);
  });
