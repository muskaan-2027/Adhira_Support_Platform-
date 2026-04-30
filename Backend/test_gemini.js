const https = require('https');
require('dotenv').config();
const GEMINI_API_KEY = process.env.GEMINI_API_KEY || 'AIzaSyD5QwUhjz_b1Wm65O9qPDdU-vYuCW0lS-4';
const GEMINI_API_URL = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=' + GEMINI_API_KEY;

const query = 'Harassment';
const prompt = `Generate exactly 5 short blog article summaries related to "${query}" for a women safety app.
Return ONLY a valid JSON array. Each object in the array must have these exact keys:
"type" (string, must be either "blog" or "article"), "title" (string), "description" (string, max 100 characters), "category" (string), "date" (string, format like "21 Apr 2026"), "url" (string, a valid working URL to a real article related to the topic).
Do not include any markdown formatting like \`\`\`json or \`\`\`. Just return the raw JSON array.`;

const requestBody = JSON.stringify({
    contents: [{
        parts: [{ text: prompt }]
    }]
});

const req = https.request(GEMINI_API_URL, {
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(requestBody)
    }
}, (res) => {
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', () => {
        console.log('Status:', res.statusCode);
        console.log('Response:', data);
    });
});
req.write(requestBody);
req.end();
