const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const pty = require('node-pty');
const path = require('path');

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

const CLIENT_DIR = path.join(__dirname, 'client');
app.use(express.static(CLIENT_DIR));

wss.on('connection', ws => {
  // Spawn redis-cli in a PTY
  const shell = pty.spawn('redis-cli', ['-h', '127.0.0.1', '-p', '6379'], {
    name: 'xterm-color',
    cols: 80,
    rows: 24,
    cwd: process.env.HOME,
    env: process.env
  });

  shell.on('data', data => {
    ws.send(data);
  });

  shell.on('exit', (code, signal) => {
    console.log(`redis-cli exited with code ${code}, signal ${signal}`);
    if (ws.readyState === ws.OPEN) {
      ws.close();
    }
  });

  ws.on('message', msg => {
    shell.write(msg);
  });

  ws.on('close', () => {
    shell.kill();
  });
});

const PORT = 8080;
server.listen(PORT, () => {
  console.log(`Server listening on http://localhost:${PORT}`);
});
