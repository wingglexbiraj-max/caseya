const http = require('http');
const fs = require('fs');
const path = require('path');
const os = require('os');

const PORT = parseInt(process.env.PORT, 10) || 5050;
const BACKEND_PORT = parseInt(process.env.BACKEND_PORT, 10) || 8000;
const PUBLIC_DIR = path.join(__dirname, 'build', 'web');

const MIME_TYPES = {
  '.html': 'text/html; charset=UTF-8',
  '.js': 'application/javascript; charset=UTF-8',
  '.mjs': 'application/javascript; charset=UTF-8',
  '.json': 'application/json; charset=UTF-8',
  '.css': 'text/css; charset=UTF-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.wasm': 'application/wasm',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.map': 'application/json; charset=UTF-8',
  '.txt': 'text/plain; charset=UTF-8',
};

// Global error handlers so server never dies
process.on('uncaughtException', (err) => {
  console.error('[SERVER ERROR uncaughtException]:', err.message);
});

process.on('unhandledRejection', (reason) => {
  console.error('[SERVER ERROR unhandledRejection]:', reason);
});

function getLocalIpAddresses() {
  const interfaces = os.networkInterfaces();
  const addresses = [];
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name] || []) {
      if (iface.family === 'IPv4' && !iface.internal) {
        addresses.push(iface.address);
      }
    }
  }
  return addresses;
}

// Proxy API requests to FastAPI backend if available
function proxyToBackend(req, res) {
  const options = {
    hostname: '127.0.0.1',
    port: BACKEND_PORT,
    path: req.url,
    method: req.method,
    headers: { ...req.headers, host: `127.0.0.1:${BACKEND_PORT}` },
  };

  const proxyReq = http.request(options, (proxyRes) => {
    res.writeHead(proxyRes.statusCode || 200, proxyRes.headers);
    proxyRes.pipe(res);
  });

  proxyReq.on('error', () => {
    // If backend isn't running, return 503 so frontend gracefully falls back to LocalStorage
    res.writeHead(503, {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
    });
    res.end(JSON.stringify({
      error: 'Backend API offline',
      message: `FastAPI backend on port ${BACKEND_PORT} is not currently running. Offline local mode is active.`,
    }));
  });

  req.pipe(proxyReq);
}

const server = http.createServer((req, res) => {
  const startTime = Date.now();

  // Robust CORS & Modern Isolation Headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
  res.setHeader('Cross-Origin-Opener-Policy', 'same-origin');
  res.setHeader('Cross-Origin-Embedder-Policy', 'credentialless');
  res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  // Health check endpoint
  if (req.url === '/healthz' || req.url === '/ping') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok', uptime: process.uptime() }));
    return;
  }

  // Optional: Transparent backend proxying for /api/
  if (req.url.startsWith('/api/')) {
    proxyToBackend(req, res);
    return;
  }

  let cleanUrl = req.url.split('?')[0].split('#')[0];
  let safePath = path.normalize(decodeURIComponent(cleanUrl));
  if (safePath === '/' || safePath === '\\') {
    safePath = '/index.html';
  }

  let filePath = path.join(PUBLIC_DIR, safePath);

  // Security check to avoid directory traversal
  if (!filePath.startsWith(PUBLIC_DIR)) {
    res.writeHead(403);
    res.end('Access Denied');
    return;
  }

  fs.stat(filePath, (err, stats) => {
    let isSpaFallback = false;
    if (err || !stats.isFile()) {
      // Fallback to index.html for SPA routing
      filePath = path.join(PUBLIC_DIR, 'index.html');
      isSpaFallback = true;
    }

    const ext = path.extname(filePath).toLowerCase();
    const contentType = MIME_TYPES[ext] || 'application/octet-stream';

    fs.readFile(filePath, (readErr, content) => {
      const duration = Date.now() - startTime;
      if (readErr) {
        console.error(`[${new Date().toLocaleTimeString()}] ❌ 500 Error reading ${filePath}: ${readErr.message}`);
        res.writeHead(500, { 'Content-Type': 'text/plain' });
        res.end('Server Error: ' + readErr.message);
        return;
      }

      res.writeHead(200, {
        'Content-Type': contentType,
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0',
      });
      res.end(content);

      const statusTag = isSpaFallback ? `[200 SPA -> index.html]` : `[200 OK]`;
      const sizeKb = (content.length / 1024).toFixed(1);
      // Log static file requests compactly
      if (!req.url.includes('.wasm') && !req.url.includes('.png') && !req.url.includes('.ico')) {
        console.log(`[${new Date().toLocaleTimeString()}] ${req.method} ${cleanUrl} ${statusTag} ${sizeKb}KB (${duration}ms)`);
      }
    });
  });
});

server.on('error', (e) => {
  if (e.code === 'EADDRINUSE') {
    console.error(`\n⚠️  Port ${PORT} is already in use!`);
    console.error(`You can kill the existing process or run on another port, e.g.:`);
    console.error(`  PORT=5051 node web_server.js\n`);
  } else {
    console.error('Server error:', e);
  }
});

server.listen(PORT, '0.0.0.0', () => {
  const ips = getLocalIpAddresses();
  console.log('\n======================================================');
  console.log('🥛  CASEYA Dairy Operations Web System is LIVE & READY');
  console.log('======================================================');
  console.log(`➜ Local:      http://localhost:${PORT}`);
  console.log(`➜ Loopback:   http://127.0.0.1:${PORT}`);
  for (const ip of ips) {
    console.log(`➜ Network:    http://${ip}:${PORT}`);
  }
  console.log('------------------------------------------------------');
  console.log('⚡ Built for zero-crash debugging with instant SPA reload');
  console.log('⚡ Open the URL above in Chrome/Edge to test & debug.');
  console.log('======================================================\n');
});
