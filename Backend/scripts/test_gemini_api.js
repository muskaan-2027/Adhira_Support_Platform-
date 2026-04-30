const https = require("https");
require("dotenv").config();

const apiKey = process.env.GEMINI_API_KEY;
const url = `https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent?key=${apiKey}`;



const body = JSON.stringify({
    contents: [{ parts: [{ text: "Hello, are you working?" }] }]
});

const options = {
    method: "POST",
    headers: {
        "Content-Type": "application/json",
        "Content-Length": Buffer.byteLength(body)
    }
};

const req = https.request(url, options, (res) => {
    let data = "";
    res.on("data", (chunk) => { data += chunk; });
    res.on("end", () => {
        console.log("Status:", res.statusCode);
        console.log("Response:", data);
    });
});

req.on("error", (e) => {
    console.error("Error:", e);
});

req.write(body);
req.end();
