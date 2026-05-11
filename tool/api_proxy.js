const http = require('http');
const https = require('https');

const PORT = Number(process.env.JEJUFLOW_API_PROXY_PORT || 8787);
const ALLOWED_HOSTS = new Set(['apis.data.go.kr']);

function send(res, status, body, type = 'text/plain; charset=utf-8') {
  res.writeHead(status, {
    'content-type': type,
    'access-control-allow-origin': '*',
    'access-control-allow-methods': 'GET,OPTIONS',
    'access-control-allow-headers': 'content-type,accept',
  });
  res.end(body);
}

http.createServer((req, res) => {
  if (req.method === 'OPTIONS') return send(res, 204, '');
  if (req.method !== 'GET') return send(res, 405, 'GET only');

  const base = `http://${req.headers.host || 'localhost'}`;
  const target = new URL(req.url || '/', base).searchParams.get('url');
  if (!target) return send(res, 400, 'Missing url');

  let parsed;
  try {
    parsed = new URL(target);
  } catch {
    return send(res, 400, 'Bad url');
  }

  if (parsed.protocol !== 'https:' || !ALLOWED_HOSTS.has(parsed.hostname)) {
    return send(res, 403, 'Host not allowed');
  }

  const upstream = https.get(parsed, {
    headers: {
      accept: req.headers.accept || 'application/json',
      'user-agent': 'JejuFlow local dev proxy',
    },
  }, (up) => {
    res.writeHead(up.statusCode || 502, {
      'content-type': up.headers['content-type'] || 'application/json; charset=utf-8',
      'access-control-allow-origin': '*',
      'cache-control': 'no-store',
    });
    up.pipe(res);
  });

  upstream.on('error', (err) => send(res, 502, err.message));
  upstream.setTimeout(15000, () => {
    upstream.destroy(new Error('Upstream timeout'));
  });
}).listen(PORT, '127.0.0.1', () => {
  console.log(`JejuFlow API proxy listening at http://127.0.0.1:${PORT}/`);
});
