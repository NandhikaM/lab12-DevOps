const test = require('node:test');
const assert = require('node:assert');
const app = require('../app');

test('GET /health returns UP', async () => {
  const server = app.listen(0);
  const { port } = server.address();
  const res = await fetch(`http://localhost:${port}/health`);
  const body = await res.json();
  server.close();
  assert.strictEqual(res.status, 200);
  assert.strictEqual(body.status, 'UP');
});

test('GET / returns the page', async () => {
  const server = app.listen(0);
  const { port } = server.address();
  const res = await fetch(`http://localhost:${port}/`);
  const text = await res.text();
  server.close();
  assert.strictEqual(res.status, 200);
  assert.match(text, /environment/);
});
