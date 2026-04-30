const https = require('https');
const GEMINI_API_KEY = 'AIzaSyD5QwUhjz_b1Wm65O9qPDdU-vYuCW0lS-4';
const url = `https://generativelanguage.googleapis.com/v1beta/models?key=${GEMINI_API_KEY}`;

const req = https.request(url, {
    method: 'GET',
    headers: { 'Content-Type': 'application/json' }
}, (res) => {
    let data = '';
    res.on('data', d => data += d);
    res.on('end', () => {
        console.log('RAW RESP:', data);
    });
});
req.end();
