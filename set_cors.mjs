import { readFileSync } from 'fs';
import { homedir } from 'os';
import { join } from 'path';

const BUCKET = 'beathub-35769.firebasestorage.app';
const CORS = [{
  origin: ['*'],
  method: ['GET', 'HEAD', 'PUT', 'POST', 'DELETE', 'OPTIONS'],
  responseHeader: [
    'Content-Type', 'Content-Length', 'Authorization',
    'Accept', 'Range', 'Access-Control-Allow-Origin',
  ],
  maxAgeSeconds: 3600,
}];

// Read refresh token from firebase-tools credential store
const credPath = join(homedir(), '.config', 'configstore', 'firebase-tools.json');
const creds = JSON.parse(readFileSync(credPath, 'utf8'));
const refreshToken = creds.tokens?.refresh_token;

if (!refreshToken) {
  console.error('No refresh token. Run: firebase login');
  process.exit(1);
}

// Exchange refresh token for a fresh access token
const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
  method: 'POST',
  headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
  body: new URLSearchParams({
    client_id: '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com',
    client_secret: 'j9iVZfS8kkCEFUPaAeJV0sAi',
    refresh_token: refreshToken,
    grant_type: 'refresh_token',
  }),
});
const tokenData = await tokenRes.json();
const token = tokenData.access_token;
if (!token) {
  console.error('Token refresh failed:', JSON.stringify(tokenData));
  process.exit(1);
}
console.log('Token refreshed OK');

const url = `https://storage.googleapis.com/storage/v1/b/${encodeURIComponent(BUCKET)}?fields=cors`;
const res = await fetch(url, {
  method: 'PATCH',
  headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
  body: JSON.stringify({ cors: CORS }),
});

const data = await res.json();
if (res.ok) {
  console.log('✅ CORS applied successfully!');
  console.log(JSON.stringify(data, null, 2));
} else {
  console.error('❌ Failed:', JSON.stringify(data, null, 2));
  process.exit(1);
}

