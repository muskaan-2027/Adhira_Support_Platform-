const https = require("https");

const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const GEMINI_API_URL = `https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=${GEMINI_API_KEY}`;



function postJson(url, options) {
    return new Promise((resolve, reject) => {
        const req = https.request(url, options, (res) => {
            let data = "";
            res.on("data", (chunk) => { data += chunk; });
            res.on("end", () => {
                resolve({
                    ok: res.statusCode >= 200 && res.statusCode < 300,
                    status: res.statusCode,
                    body: data
                });
            });
        });
        req.on("error", reject);
        req.write(options.body);
        req.end();
    });
}

/**
 * Uses Gemini AI to analyze a post for urgency, toxicity, and field categorization
 * based on the zero-shot multimodal grievance classification framework.
 */
exports.analyzePostWithAI = async (content) => {
    try {
        // Safety net: Keyword-based urgency override based on user's new mapping
        const lowerContent = content.toLowerCase();
        
        let keywordUrgency = null;
        // User requested: "stalking from long time" -> red
        if (lowerContent.includes("stalking") || lowerContent.includes("staking") || lowerContent.includes("following me")) {
            keywordUrgency = "red";
        }
        // User requested: "beats me" -> yellow
        else if (lowerContent.includes("beats me") || lowerContent.includes("beating me")) {
            keywordUrgency = "yellow";
        }

        const prompt = `Analyze the following user post from a women safety and support community app. 
Evaluate it based on the following criteria:
1. Urgency: How urgent is this post? 
   - green: (DEFAULT) Normal post, general sharing, seeking general advice, venting, or raising awareness. No immediate physical danger.
   - yellow: Concerning, active emotional distress, or past abuse where the user is currently safe but needs help.
   - red: Extremely urgent and life-threatening ONLY. Active stalking, immediate physical violence, active crimes, or suicidal ideation.
2. Toxicity: Is this post highly toxic, abusive towards others, or promoting harm?
   - low: Normal, supportive, or venting.
   - medium: Heated emotion or swearing.
   - high: Promoting violence or hate speech towards others.
3. Field: You have full autonomy to categorize this post. Provide a precise, descriptive 1-3 word category (e.g., "Domestic Violence", "Cyber Harassment", "Mental Health", "Legal Advice", "Public Safety", etc.).

Respond ONLY with a valid JSON object matching this structure:
{
  "urgencyColor": "green" | "yellow" | "red",
  "toxicityLevel": "low" | "medium" | "high",
  "field": "Generated Category String"
}

Post Content: "${content.replace(/"/g, '\\"')}"`;

        const requestBody = JSON.stringify({
            contents: [{ parts: [{ text: prompt }] }],
            generationConfig: {
                temperature: 0.1,
            }
        });

        const options = {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "Content-Length": Buffer.byteLength(requestBody)
            },
            body: requestBody
        };

        const response = await postJson(GEMINI_API_URL, options);
        if (!response.ok) {
            console.error("Gemini AI Sentiment Error:", response.body);
            throw new Error("API failed");
        }

        const data = JSON.parse(response.body);
        const textResponse = data.candidates[0].content.parts[0].text;
        
        let jsonStr = textResponse.trim();
        if (jsonStr.startsWith("```json")) {
            jsonStr = jsonStr.substring(7, jsonStr.length - 3);
        } else if (jsonStr.startsWith("```")) {
            jsonStr = jsonStr.substring(3, jsonStr.length - 3);
        }

        const result = JSON.parse(jsonStr);

        // Apply keyword override if detected earlier
        if (keywordUrgency) {
            result.urgencyColor = keywordUrgency;
        }

        // --- Field Categorization ---
        // Let the AI model decide the field, only fallback to "General Safety" if completely missing.
        let finalField = result.field || "General Safety";

        // Map toxicity to deletion logic
        const isDeleted = result.toxicityLevel === "high";
        const deletedReason = isDeleted ? "Deleted due to unethical content" : "";
        const suggestSOS = result.urgencyColor === "red";

        return {
            urgencyColor: result.urgencyColor || "green",
            toxicityLevel: result.toxicityLevel || "low",
            field: finalField,
            isDeleted,
            deletedReason,
            suggestSOS
        };
    } catch (err) {
        console.error("Failed to analyze sentiment with AI, falling back to defaults", err);
        
        // Fallback with keyword check even in error case
        const lowerContent = content.toLowerCase();
        const criticalKeywords = ["beats me", "beating me", "killing me", "suicide", "active abuse", "rape", "attacked me"];
        const isRed = criticalKeywords.some(k => lowerContent.includes(k));
        
        let fallbackField = "General Safety";
        if (lowerContent.includes("beats") || lowerContent.includes("husband")) fallbackField = "Domestic Violence";
        else if (lowerContent.includes("stalking")) fallbackField = "Stalking";

        return {
            urgencyColor: isRed ? "red" : "green",
            toxicityLevel: "low",
            field: fallbackField,
            isDeleted: false,
            deletedReason: "",
            suggestSOS: isRed
        };
    }
};
/**
 * Synchronous keyword-based analysis for quick chatbot responses
 */
exports.analyze = (message) => {
    const msg = message.toLowerCase();
    
    // High urgency keywords
    const highUrgency = ["kill", "die", "suicide", "murder", "rape", "weapon", "gun", "knife", "attacked", "bleeding"];
    if (highUrgency.some(word => msg.includes(word))) {
        return "high";
    }

    // Medium urgency keywords
    const mediumUrgency = ["scared", "unsafe", "follow", "harass", "stalk", "help", "danger", "threat", "abuse"];
    if (mediumUrgency.some(word => msg.includes(word))) {
        return "medium";
    }

    return "normal";
};

/**
 * Suggests actions based on the detected urgency level
 */
exports.suggestActions = (level) => {
    switch (level) {
        case "high":
            return [
                "Call 112 immediately",
                "Use the SOS button in the app",
                "Women Helpline: 1091",
                "Find a safe, public place"
            ];
        case "medium":
            return [
                "Move to a crowded area",
                "Share live location with a trusted contact",
                "Call a friend or family member",
                "Talk to our volunteers in the Feed section"
            ];
        default:
            return [
                "Browse safety tips in the app",
                "Check out community stories",
                "Learn about your legal rights",
                "Stay connected with local volunteers"
            ];
    }
};
