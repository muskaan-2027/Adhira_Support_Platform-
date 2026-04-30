const router = require("express").Router();
const PrivateChatSession = require("../models/PrivateChatSession");
const PrivateMessage = require("../models/PrivateMessage");
const Post = require("../models/Post");
const User = require("../models/User");
const auth = require("../middleware/authMiddleware");
const { analyzePostWithAI } = require("../utils/sentiment");

// Accept a Private Request (Create Session)
router.post("/accept/:postId", auth, async (req, res) => {
    try {
        const post = await Post.findById(req.params.postId);
        if (!post) return res.status(404).json({ message: "Post not found" });
        if (post.mode !== "private") return res.status(400).json({ message: "Can only accept private posts" });

        const currentUser = await User.findById(req.user);
        if (currentUser.role !== "volunteer") return res.status(403).json({ message: "Only volunteers can accept requests" });

        // Check if session already exists
        let session = await PrivateChatSession.findOne({
            helpSeekerId: post.userId,
            volunteerId: req.user,
            originalPostId: post._id
        });

        if (!session) {
            session = await PrivateChatSession.create({
                helpSeekerId: post.userId,
                volunteerId: req.user,
                originalPostId: post._id,
                status: "active"
            });
        }

        return res.status(201).json(session);
    } catch (err) {
        console.error("Accept request error:", err);
        return res.status(500).json({ message: "Failed to accept request" });
    }
});

// Get all sessions for current user
router.get("/sessions", auth, async (req, res) => {
    try {
        const currentUser = await User.findById(req.user);
        const query = currentUser.role === "volunteer" 
            ? { volunteerId: req.user } 
            : { helpSeekerId: req.user };
            
        const sessions = await PrivateChatSession.find(query)
            .populate("helpSeekerId", "name profilePhoto")
            .populate("volunteerId", "name profilePhoto")
            .sort({ updatedAt: -1 });

        return res.json({ sessions });
    } catch (err) {
        return res.status(500).json({ message: "Failed to fetch sessions" });
    }
});

// Send a message in a session
router.post("/:sessionId/messages", auth, async (req, res) => {
    try {
        const { content } = req.body;
        if (!content || !content.trim()) return res.status(400).json({ message: "Content is required" });

        const session = await PrivateChatSession.findById(req.params.sessionId);
        if (!session) return res.status(404).json({ message: "Session not found" });

        // Ensure user is part of the session
        if (session.helpSeekerId.toString() !== req.user.toString() && 
            session.volunteerId.toString() !== req.user.toString()) {
            return res.status(403).json({ message: "Not authorized for this session" });
        }

        const analysis = await analyzePostWithAI(content);

        const message = await PrivateMessage.create({
            sessionId: session._id,
            senderId: req.user,
            content,
            urgencyColor: analysis.urgencyColor,
            toxicityLevel: analysis.toxicityLevel,
            isDeleted: analysis.isDeleted,
            deletedReason: analysis.deletedReason
        });

        // Update session timestamp
        session.updatedAt = new Date();
        await session.save();

        await message.populate("senderId", "name role profilePhoto");

        return res.status(201).json({
            message,
            analysis
        });
    } catch (err) {
        console.error("Send message error:", err);
        return res.status(500).json({ message: "Failed to send message" });
    }
});

// Get messages for a session
router.get("/:sessionId/messages", auth, async (req, res) => {
    try {
        const session = await PrivateChatSession.findById(req.params.sessionId);
        if (!session) return res.status(404).json({ message: "Session not found" });

        if (session.helpSeekerId.toString() !== req.user.toString() && 
            session.volunteerId.toString() !== req.user.toString()) {
            return res.status(403).json({ message: "Not authorized for this session" });
        }

        const messages = await PrivateMessage.find({ sessionId: session._id })
            .sort({ createdAt: 1 })
            .populate("senderId", "name role profilePhoto");

        return res.json({ messages });
    } catch (err) {
        return res.status(500).json({ message: "Failed to fetch messages" });
    }
});

module.exports = router;
