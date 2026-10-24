import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../Assets/UI');
const server = http.createServer((req, res) => {
  const name = decodeURIComponent(new URL(req.url, 'http://localhost').pathname).slice(1);
  if (!/^[a-z-]+\.png$/.test(name)) { res.writeHead(404).end(); return; }
  const file = path.join(root, name);
  if (!fs.existsSync(file)) { res.writeHead(404).end(); return; }
  res.writeHead(200, { 'Content-Type': 'image/png' });
  fs.createReadStream(file).pipe(res);
});
server.listen(34873, '127.0.0.1', () => console.log('Generated UI assets: http://localhost:34873'));
