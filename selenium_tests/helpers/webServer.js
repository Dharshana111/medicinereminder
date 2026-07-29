const http = require('http');
const fs = require('fs');
const path = require('path');

const BUILD_DIR = path.join(__dirname, '..', '..', 'build', 'web');

const MIME_TYPES = {
  '.html': 'text/html',
  '.js': 'application/javascript',
  '.json': 'application/json',
  '.css': 'text/css',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.ico': 'image/x-icon',
  '.wasm': 'application/wasm',
  '.otf': 'font/otf',
  '.ttf': 'font/ttf'
};

function startServer(port = 8080) {
  return new Promise((resolve, reject) => {
    const server = http.createServer((req, res) => {
      let reqPath = req.url.split('?')[0];
      if (reqPath === '/') reqPath = '/index.html';

      let filePath = path.join(BUILD_DIR, reqPath);

      if (!fs.existsSync(filePath) || fs.statSync(filePath).isDirectory()) {
        filePath = path.join(BUILD_DIR, 'index.html');
      }

      const ext = path.extname(filePath).toLowerCase();
      const contentType = MIME_TYPES[ext] || 'application/octet-stream';

      fs.readFile(filePath, (err, content) => {
        if (err) {
          res.writeHead(500);
          res.end(`Server Error: ${err.code}`);
        } else {
          res.writeHead(200, {
            'Content-Type': contentType,
            'Cache-Control': 'no-cache'
          });
          res.end(content, 'utf-8');
        }
      });
    });

    server.listen(port, () => {
      console.log(`🌐 Local MedCare+ Web Application Server running at http://localhost:${port}`);
      resolve(server);
    });

    server.on('error', (err) => {
      if (err.code === 'EADDRINUSE') {
        console.log(`⚠️ Port ${port} is already in use, assuming server is running.`);
        resolve(null);
      } else {
        reject(err);
      }
    });
  });
}

if (require.main === module) {
  startServer();
} else {
  module.exports = startServer;
}
