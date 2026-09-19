const express = require('express');
const app = express();

const PORT = process.env.PORT || 3000;
const COLOR = process.env.APP_COLOR || 'local';      // blue | green
const VERSION = process.env.APP_VERSION || '1.0.0';  // set by Jenkins (build number)

app.get('/', (req, res) => {
  const bg = COLOR === 'blue' ? '#1e66f5' : COLOR === 'green' ? '#2e9e4f' : '#555';
  res.send(`<!doctype html>
<html><head><title>Blue-Green Demo</title></head>
<body style="margin:0;font-family:sans-serif;background:${bg};color:#fff;
             display:flex;align-items:center;justify-content:center;height:100vh">
  <div style="text-align:center">
    <h1>${COLOR.toUpperCase()} environment</h1>
    <h2>Version: ${VERSION}</h2>
    <p>Served by: ${require('os').hostname()}</p>
  </div>
</body></html>`);
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'UP', color: COLOR, version: VERSION });
});

if (require.main === module) {
  app.listen(PORT, () => console.log(`App (${COLOR}, v${VERSION}) listening on ${PORT}`));
}

module.exports = app;
