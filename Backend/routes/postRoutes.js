const router = require("express").Router();
const Post = require("../models/Post");
const User = require("../models/User");
const Comment = require("../models/Comment");
const auth = require("../middleware/authMiddleware");
const { analyzePostWithAI } = require("../utils/sentiment");
const Notification = require("../models/Notification");

// Analyze endpoint (used by frontend for preview or internal use)
router.post("/analyze", auth, async (req, res) => {
    try {
        const { content } = req.body;
        if (!content || !content.trim()) {
            return res.status(400).json({ message: "content is required" });
        }

        const analysis = await analyzePostWithAI(content);
        return res.json(analysis);
    } catch (err) {
        return res.status(500).json({ message: "Failed to analyze post content" });
    }
});

// Create Post
router.post("/", auth, async (req, res) => {
    try {
        const { content, caption, mediaUrl, mediaType, isAnonymous = false, mode = "public", field = "" } = req.body;

        const textToAnalyze = content || caption || "";
        const safeMediaUrl = mediaUrl || "";
        if (!textToAnalyze.trim() && !safeMediaUrl) {
            return res.status(400).json({ message: "Content, caption, or media is required" });
        }

        // Run AI Sentiment Analysis on available text or image
        let analysis = { urgencyColor: "green", toxicityLevel: "low", isDeleted: false, deletedReason: "", field: "general" };
        if (textToAnalyze.trim() || safeMediaUrl.startsWith("data:image")) {
            try {
                const imgData = safeMediaUrl.startsWith("data:image") ? safeMediaUrl : null;
                analysis = await analyzePostWithAI(textToAnalyze, imgData);
            } catch (e) {
                console.error("AI Analysis failed, proceeding with default", e);
            }
        }

        const post = await Post.create({
            userId: req.user,
            content: content || "",
            caption: caption || "",
            mediaUrl: mediaUrl || "",
            mediaType: mediaType || "text",
            isAnonymous,
            mode,
            field: field || analysis.field || "", // user selected field or AI extracted
            urgencyColor: analysis.urgencyColor || "green",
            toxicityLevel: analysis.toxicityLevel || "low",
            isDeleted: analysis.isDeleted || false,
            deletedReason: analysis.deletedReason || "",
            likes: [],
            views: 0
        });

        return res.status(201).json({
            post,
            analysis
        });
    } catch (err) {
        console.error("Create post error:", err);
        return res.status(500).json({ message: "Failed to create post" });
    }
});

// Get Posts (Feed)
router.get("/", auth, async (req, res) => {
    try {
        const currentUser = await User.findById(req.user);
        if (!currentUser) return res.status(404).json({ message: "User not found" });

        let query = {};

        if (req.query.tab === 'following') {
            const followingIds = currentUser.following || [];
            query = { userId: { $in: followingIds } };
            query.$or = [{ mode: "public" }, { mode: "private", userId: req.user }];
        } else if (req.query.tab === 'urgent') {
            // Fetch posts with urgencyColor 'red' that the user hasn't read yet
            query = { 
                urgencyColor: 'red',
                readBy: { $ne: req.user },
                $or: [
                    { mode: "public" },
                    { mode: "private", userId: req.user }
                ]
            };
        } else {
            if (currentUser.role === "volunteer") {
                const areas = currentUser.areasOfHelp ? currentUser.areasOfHelp.split(',').map(s => s.trim().toLowerCase()) : [];
                query = {
                    $or: [
                        { mode: "public" },
                        { 
                            mode: "private", 
                            $expr: {
                                $in: [{ $toLower: "$field" }, areas]
                            }
                        }
                    ]
                };
            } else {
                query = {
                    $or: [
                        { mode: "public" },
                        { mode: "private", userId: req.user }
                    ]
                };
            }
        }

        const posts = await Post.find(query).sort({ updatedAt: -1 }).populate("userId", "name role profilePhoto");
        return res.json({ posts });
    } catch (err) {
        console.error("Get posts error:", err);
        return res.status(500).json({ message: "Failed to fetch posts" });
    }
});

// Like a post
router.post("/:id/like", auth, async (req, res) => {
    try {
        const post = await Post.findById(req.params.id);
        if (!post) return res.status(404).json({ message: "Post not found" });

        if (!post.likes.includes(req.user)) {
            post.likes.push(req.user);
            await post.save();
        }
        return res.json(post);
    } catch (err) {
        return res.status(500).json({ message: "Failed to like post" });
    }
});

// Unlike a post
router.post("/:id/unlike", auth, async (req, res) => {
    try {
        const post = await Post.findById(req.params.id);
        if (!post) return res.status(404).json({ message: "Post not found" });

        post.likes = post.likes.filter(id => id.toString() !== req.user.toString());
        await post.save();
        return res.json(post);
    } catch (err) {
        return res.status(500).json({ message: "Failed to unlike post" });
    }
});

// Increment views for a post
router.post("/:id/view", auth, async (req, res) => {
    try {
        const post = await Post.findById(req.params.id);
        if (!post) return res.status(404).json({ message: "Post not found" });

        post.views = (post.views || 0) + 1;
        await post.save();
        return res.json({ views: post.views });
    } catch (err) {
        return res.status(500).json({ message: "Failed to update views" });
    }
});

// Mark urgent post as read
router.post("/:id/read", auth, async (req, res) => {
    try {
        const post = await Post.findById(req.params.id);
        if (!post) return res.status(404).json({ message: "Post not found" });

        if (!post.readBy.includes(req.user)) {
            post.readBy.push(req.user);
            await post.save();
        }
        return res.json(post);
    } catch (err) {
        return res.status(500).json({ message: "Failed to mark as read" });
    }
});

// Edit a post
router.put("/:id", auth, async (req, res) => {
    try {
        const post = await Post.findById(req.params.id);
        if (!post) return res.status(404).json({ message: "Post not found" });
        if (post.userId.toString() !== req.user.toString()) return res.status(403).json({ message: "Unauthorized" });

        post.content = req.body.content !== undefined ? req.body.content : post.content;
        post.caption = req.body.caption !== undefined ? req.body.caption : post.caption;
        post.mediaUrl = req.body.mediaUrl !== undefined ? req.body.mediaUrl : post.mediaUrl;
        post.mediaType = req.body.mediaType !== undefined ? req.body.mediaType : post.mediaType;

        await post.save();
        return res.json(post);
    } catch (err) {
        return res.status(500).json({ message: "Failed to update post" });
    }
});

// Delete a post
router.delete("/:id", auth, async (req, res) => {
    try {
        const post = await Post.findById(req.params.id);
        if (!post) return res.status(404).json({ message: "Post not found" });
        if (post.userId.toString() !== req.user.toString()) return res.status(403).json({ message: "Unauthorized" });

        await Post.findByIdAndDelete(req.params.id);
        await Comment.deleteMany({ postId: req.params.id });
        return res.json({ message: "Post deleted" });
    } catch (err) {
        return res.status(500).json({ message: "Failed to delete post" });
    }
});

// Increment views
router.post("/:id/view", auth, async (req, res) => {
    try {
        await Post.findByIdAndUpdate(req.params.id, { $inc: { views: 1 } });
        return res.json({ success: true });
    } catch (err) {
        return res.status(500).json({ message: "Failed to increment view" });
    }
});

// Repost
router.post("/:id/repost", auth, async (req, res) => {
    try {
        const originalPost = await Post.findById(req.params.id).populate("userId", "name");
        if (!originalPost) return res.status(404).json({ message: "Post not found" });

        const isOwnPost = originalPost.userId._id.toString() === req.user.toString();

        const newPost = await Post.create({
            userId: req.user,
            content: originalPost.content,
            caption: originalPost.caption,
            mediaUrl: originalPost.mediaUrl,
            mediaType: originalPost.mediaType,
            isAnonymous: originalPost.isAnonymous,
            mode: originalPost.mode,
            field: originalPost.field,
            urgencyColor: originalPost.urgencyColor,
            toxicityLevel: originalPost.toxicityLevel,
            isRepost: !isOwnPost,
            originalPostId: isOwnPost ? null : originalPost._id,
            originalAuthorName: isOwnPost ? "" : originalPost.userId.name
        });

        return res.status(201).json(newPost);
    } catch (err) {
        return res.status(500).json({ message: "Failed to repost" });
    }
});

// Comment model is imported at the top of the file

// Add a comment to a post
router.post("/:id/comments", auth, async (req, res) => {
    try {
        const { content } = req.body;
        if (!content || !content.trim()) return res.status(400).json({ message: "Content is required" });

        // Evaluate comment sentiment
        const analysis = await analyzePostWithAI(content);

        const comment = await Comment.create({
            postId: req.params.id,
            userId: req.user,
            content,
            toxicityLevel: analysis.toxicityLevel,
            isDeleted: analysis.isDeleted,
            deletedReason: analysis.deletedReason
        });

        // Update the post's updatedAt and comment count
        const post = await Post.findById(req.params.id);
        if (post) {
            post.commentCount = (post.commentCount || 0) + 1;
            post.updatedAt = new Date();
            await post.save();

            // Notify author if someone else commented
            if (post.userId.toString() !== req.user.toString()) {
                const commenter = await User.findById(req.user);
                await Notification.create({
                    userId: post.userId,
                    title: "New Comment",
                    message: `${commenter ? commenter.name : 'Someone'} commented on your post.`,
                    type: "community"
                });
            }
        }

        // Populate user for the response
        await comment.populate("userId", "name role profilePhoto");

        return res.status(201).json(comment);
    } catch (err) {
        console.error("Add comment error:", err);
        return res.status(500).json({ message: "Failed to add comment" });
    }
});

// Get comments for a post
router.get("/:id/comments", auth, async (req, res) => {
    try {
        const comments = await Comment.find({ postId: req.params.id })
            .sort({ createdAt: -1 })
            .populate("userId", "name role profilePhoto");
        return res.json({ comments });
    } catch (err) {
        return res.status(500).json({ message: "Failed to fetch comments" });
    }
});

module.exports = router;
