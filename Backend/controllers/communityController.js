const https = require("https");
const Story = require("../models/Story");

function postJson(url, options) {
    return new Promise((resolve, reject) => {
        const { headers, body } = options;
        const request = https.request(
            url,
            {
                method: "POST",
                headers: {
                    ...headers,
                    "Content-Length": Buffer.byteLength(body)
                }
            },
            (response) => {
                let rawBody = "";
                response.setEncoding("utf8");
                response.on("data", (chunk) => {
                    rawBody += chunk;
                });
                response.on("end", () => {
                    let parsed = null;
                    try {
                        parsed = rawBody ? JSON.parse(rawBody) : null;
                    } catch (error) {
                        parsed = null;
                    }
                    resolve({
                        ok: response.statusCode >= 200 && response.statusCode < 300,
                        status: response.statusCode || 500,
                        rawBody,
                        json: parsed
                    });
                });
            }
        );

        request.on("error", reject);
        request.write(body);
        request.end();
    });
}

exports.getBlogs = async (req, res) => {
    try {
        const query = req.query.query || "latest women safety news";
        console.log(`[CommunityController] Fetching blogs for query: "${query}"`);
        
        const GEMINI_API_KEY = process.env.GEMINI_API_KEY_COMMUNITY;
        if (!GEMINI_API_KEY) throw new Error("Missing Gemini API Key for Community");

        const prompt = `You are a professional content curator. 
Generate a JSON array of exactly 3 HIGH-QUALITY articles or blog posts specifically for the topic: "${query}".

Requirements for each item:
1. "type": "blog" or "article".
2. "title": Compelling headline.
3. "description": Catchy summary (max 100 characters).
4. "category": Relevant category (e.g. Safety, Tech, Legal).
5. "date": Current date or very recent (e.g. "Apr 2026").
6. "url": A REAL, WORKING link. 
   - Prefer reputable sites like UN Women, Amnesty, BBC, or Reuters.
   - If you are not 100% sure a specific article URL exists, provide a direct Google Search link for that topic instead (e.g., https://www.google.com/search?q=women+safety+tips+2025). This ensures the user always gets a working results page.

Return ONLY the raw JSON array. No markdown, no extra text.`;

        const requestBody = JSON.stringify({
            contents: [{ parts: [{ text: prompt }] }]
        });

        const GEMINI_URL = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${GEMINI_API_KEY}`;

        const response = await postJson(GEMINI_URL, {
            headers: { "Content-Type": "application/json" },
            body: requestBody
        });

        if (!response.ok) {
            console.error(`[Gemini Error] Status: ${response.status}, Body: ${response.rawBody}`);
            throw new Error("Gemini API Request Failed");
        }

        const candidateText = response.json?.candidates?.[0]?.content?.parts?.[0]?.text;
        let blogs = [];

        if (candidateText) {
            try {
                const startIndex = candidateText.indexOf('[');
                const endIndex = candidateText.lastIndexOf(']');
                if (startIndex !== -1 && endIndex !== -1) {
                    blogs = JSON.parse(candidateText.substring(startIndex, endIndex + 1));
                }
            } catch (err) {
                console.error("[Parse Error] Failed to parse Gemini response:", candidateText);
            }
        }

        if (!Array.isArray(blogs) || blogs.length === 0) {
            console.log("[Fallback] Using dynamic search links as fallback.");
            const encodedQuery = encodeURIComponent(query);
            blogs = [
                {
                    type: "article",
                    title: `Latest Updates: ${query}`,
                    description: `Find real-time articles and news about ${query}.`,
                    category: "Search",
                    date: "Apr 2026",
                    url: `https://www.google.com/search?q=${encodedQuery}+women+safety+articles+2025`
                },
                {
                    type: "article",
                    title: "UN Women Safety Portal",
                    description: "Global resources and articles on ending violence against women.",
                    category: "Global",
                    date: "Apr 2026",
                    url: "https://www.unwomen.org/en/what-we-do/ending-violence-against-women"
                }
            ];
        }

        return res.json({ blogs });
    } catch (err) {
        console.error("[Controller Error]", err.message);
        return res.json({
            blogs: [
                {
                    type: "article",
                    title: "Safety Resource Center",
                    description: "Access essential resources for your safety.",
                    category: "General",
                    date: "Apr 2026",
                    url: "https://www.google.com/search?q=women+safety+resources"
                }
            ]
        });
    }
};

exports.createStory = async (req, res) => {
    try {
        const { title, snippet, anonymous } = req.body;
        if (!title || !snippet) return res.status(400).json({ message: "Required fields missing." });

        const story = await Story.create({
            userId: req.user,
            title,
            snippet,
            anonymous: anonymous || false
        });

        return res.status(201).json({ story });
    } catch (err) {
        return res.status(500).json({ message: "Failed to share story." });
    }
};

exports.getStories = async (req, res) => {
    try {
        const stories = await Story.find().populate("userId", "name").sort({ createdAt: -1 }).limit(50);
        return res.json({ stories });
    } catch (err) {
        return res.status(500).json({ message: "Failed to fetch stories." });
    }
};

exports.toggleLike = async (req, res) => {
    try {
        const { id } = req.params;
        const story = await Story.findById(id);
        if (!story) return res.status(404).json({ message: "Story not found." });

        const userIdStr = req.user.toString();
        const likeIndex = story.likes.findIndex(likeId => likeId.toString() === userIdStr);

        if (likeIndex === -1) story.likes.push(req.user);
        else story.likes.splice(likeIndex, 1);

        await story.save();
        return res.json({ likes: story.likes.length, isLiked: likeIndex === -1 });
    } catch (err) {
        return res.status(500).json({ message: "Failed to update like." });
    }
};
