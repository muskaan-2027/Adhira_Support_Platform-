const { analyze, suggestActions } = require("../utils/sentiment");
const https = require("https");

const GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions";
const DEFAULT_GROQ_MODEL = process.env.GROQ_MODEL || "llama-3.1-8b-instant";

function getSystemPrompt(language) {
    return `You are Sophie, a highly supportive women’s safety and legal assistant.

IMPORTANT: You must reply ONLY in ${language}.
Your reply must be extremely easy to understand, using very simple, everyday words.

Tone:
- Humble, deeply supportive, and empowering.
- Speak like a caring, professional, and empowering guide.
- IMPORTANT: Do NOT use terms like "Beta", "(child)", or "Dear" in a patronizing way.
- Maintain a respectful, supportive, and serious tone.
- Never robotic.

Conversation Rules:
- If it's a greeting, respond warmly and ask how you can support them today.
- If the user is in distress, show deep empathy first, then provide simple, immediate safety steps.
- If it's a legal query, explain relevant Indian laws (IPC/BNS) simply and explain what the police are required to do.
- Keep responses concise (under 150 words) unless detailed legal explanation is needed.
- Use simple bullet points for advice.
- CRITICAL: You must NEVER repeat your exact previous reply. Always acknowledge the new information the user provided and continue the conversation based on the context.

Context:
- Always remember the previous conversation context to provide relevant replies.
- Do not repeat information already given unless asked.
`;
}

const FALLBACK_REPLIES = {
    normal: "I’m here with you. Tell me what’s happening.",
    medium: "I understand this feels difficult. Is there someone nearby you trust?",
    high: "This sounds serious. Please call 112 or 1091 and move to a safe place."
};


function detectIntent(message) {
    const msg = message.toLowerCase().trim();

    if (["hi", "hello", "hey"].includes(msg)) return "greeting";

    if (msg.includes("case") || msg.includes("complaint") || msg.includes("report")) {
        return "legal";
    }

    if (
        msg.includes("follow") ||
        msg.includes("unsafe") ||
        msg.includes("scared")
    ) {
        return "distress";
    }

    return "general";
}


function enforceSafety(reply, level) {
    if (!reply) return reply;

    if (level === "high") {
        if (!reply.includes("112")) {
            reply += "\n• Call 112 immediately";
        }
        if (!reply.includes("1091")) {
            reply += "\n• Women helpline: 1091";
        }
    }

    return reply;
}

// =========================
// 🧠 TONE CLEANUP
// =========================
function cleanTone(reply) {
    if (!reply) return reply;

    const badPhrases = [
        "are you sure",
        "big decision",
        "consider whether",
        "if you feel ready"
    ];

    let cleaned = reply;

    badPhrases.forEach(p => {
        const regex = new RegExp(p, "gi");
        cleaned = cleaned.replace(regex, "");
    });

    return cleaned;
}

// =========================
// 🌐 HTTP HELPER
// =========================
async function postJson(url, apiKey, body, isGemini = false) {
    const headers = { "Content-Type": "application/json" };
    if (isGemini) {
        // Gemini URL already has key
    } else {
        headers["Authorization"] = `Bearer ${apiKey}`;
    }

    const requestBody = JSON.stringify(body);

    return new Promise((resolve, reject) => {
        const options = {
            method: "POST",
            headers: {
                ...headers,
                "Content-Length": Buffer.byteLength(requestBody)
            }
        };

        const req = https.request(url, options, (res) => {
            let data = "";
            res.on("data", (chunk) => { data += chunk; });
            res.on("end", () => {
                let json = null;
                try { json = JSON.parse(data); } catch (e) {}
                resolve({ ok: res.statusCode >= 200 && res.statusCode < 300, json });
            });
        });

        req.on("error", (err) => reject(err));
        req.write(requestBody);
        req.end();
    });
}

// =========================
// 🤖 AI ENGINES
// =========================
async function generateGroqReply(message, level, intent, language, history = []) {
    const apiKey = process.env.GROQ_API_KEY;
    if (!apiKey) return null;

    const messages = [{ role: "system", content: getSystemPrompt(language || "English") }];
    if (Array.isArray(history)) {
        history.forEach(msg => {
            if (msg.sender && msg.text) {
                messages.push({ role: msg.sender === "bot" ? "assistant" : "user", content: msg.text });
            }
        });
    }
    messages.push({ role: "user", content: message });

    const body = { model: process.env.GROQ_MODEL || "llama-3.1-8b-instant", temperature: 0.6, messages };
    const response = await postJson(GROQ_API_URL, apiKey, body);
    if (!response.ok) throw new Error("Groq API failed");
    return response.json?.choices?.[0]?.message?.content?.trim() || null;
}

async function generateGeminiReply(message, level, intent, language, history = []) {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) return null;

    const systemPrompt = getSystemPrompt(language || "English");
    const contents = [{ role: "user", parts: [{ text: "SYSTEM INSTRUCTION: " + systemPrompt }] }];
    
    if (Array.isArray(history)) {
        history.forEach(msg => {
            if (msg.sender && msg.text) {
                const role = msg.sender === "bot" ? "model" : "user";
                // Only push if different from last role to keep alternating
                if (contents.length === 0 || contents[contents.length - 1].role !== role) {
                    contents.push({ role, parts: [{ text: msg.text }] });
                } else {
                    // Merge same-role consecutive messages
                    contents[contents.length - 1].parts[0].text += "\n" + msg.text;
                }
            }
        });
    }

    const lastRole = contents.length > 0 ? contents[contents.length - 1].role : null;
    if (lastRole === "user") {
        // If last was user, we must add a model message or merge
        contents[contents.length - 1].parts[0].text += "\n" + message;
    } else {
        contents.push({ role: "user", parts: [{ text: message }] });
    }

    const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=${apiKey}`;

    const body = { contents, generationConfig: { temperature: 0.7 } };
    
    const response = await postJson(url, null, body, true);
    if (!response.ok) throw new Error("Gemini API failed");
    return response.json?.candidates?.[0]?.content?.parts?.[0]?.text?.trim() || null;
}

// =========================
// 💬 CONTROLLER
// =========================
exports.chatbot = async (req, res) => {
    const message = req.body?.message?.toString().trim();
    const language = req.body?.language?.toString().trim() || "English";
    const history = req.body?.history || [];

    if (!message) {
        return res.status(400).json({ message: "Message is required" });
    }

    const level = analyze(message);
    const intent = detectIntent(message);
    const suggestedActions = suggestActions(level);

    // ✅ INTENT DETECTION is done but we let Groq handle everything now to respect language

    const fallbackReply = FALLBACK_REPLIES[level] || FALLBACK_REPLIES.normal;

    let aiReply = null;
    try {
        // Try Groq first
        aiReply = await generateGroqReply(message, level, intent, language, history);
    } catch (err) {
        console.error("Groq fallback, trying Gemini...", err.message);
        try {
            // Backup: Gemini
            aiReply = await generateGeminiReply(message, level, intent, language, history);
        } catch (err2) {
            console.error("Both AI engines failed:", err2.message);
        }
    }

    let finalReply = aiReply || fallbackReply;

    finalReply = cleanTone(finalReply);
    finalReply = enforceSafety(finalReply, level);

    res.json({
        reply: finalReply,
        level,
        suggestedActions,
        provider: aiReply ? "groq" : "fallback"
    });
};
// Force nodemon restart