const form = document.getElementById('form');
const msg = document.getElementById('msg');
const lista = document.getElementById('lista');

function mostrar(texto, ok) {
  msg.textContent = texto;
  msg.className = ok ? 'ok' : 'erro';
}

form.addEventListener('submit', async (e) => {
  e.preventDefault();
  const f = new FormData(form);
  const corpo = {
    nome: f.get('nome'),
    instrutor: f.get('instrutor'),
    preco: parseFloat(f.get('preco')),
    vagas: parseInt(f.get('vagas'), 10),
  };
  try {
    const r = await fetch(`${window.API_URL}/curso`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(corpo),
    });
    const dados = await r.json();
    if (!r.ok) throw new Error(dados.erro || 'Erro ao cadastrar');
    mostrar(`Curso cadastrado com sucesso (id ${dados.id}).`, true);
    form.reset();
  } catch (err) {
    mostrar(`Falha: ${err.message}`, false);
  }
});

document.getElementById('listar').addEventListener('click', async (e) => {
  e.preventDefault();
  try {
    const r = await fetch(`${window.API_URL}/cursos`);
    if (!r.ok) throw new Error('Erro ao consultar a API');
    const cursos = await r.json();

    lista.textContent = '';
    if (cursos.length === 0) {
      lista.textContent = 'Nenhum curso cadastrado.';
      return;
    }
    const tabela = document.createElement('table');
    const cab = tabela.createTHead().insertRow();
    ['ID', 'Curso', 'Instrutor', 'Preço', 'Vagas'].forEach((t) => {
      const th = document.createElement('th');
      th.textContent = t;
      cab.appendChild(th);
    });
    const corpo = tabela.createTBody();
    cursos.forEach((c) => {
      const tr = corpo.insertRow();
      [c.id, c.nome, c.instrutor,
        Number(c.preco).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' }),
        c.vagas].forEach((v) => (tr.insertCell().textContent = v));
    });
    lista.appendChild(tabela);
  } catch (err) {
    lista.textContent = `Falha: ${err.message}`;
  }
});
