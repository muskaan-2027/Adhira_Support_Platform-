const mongoose = require("mongoose");

const postSchema = new mongoose.Schema(
    {
        userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
        content: { type: String, trim: true, default: "" },
        caption: { type: String, trim: true, default: "" },
        mediaUrl: { type: String, default: "" },
        mediaType: { type: String, enum: ["text", "image", "audio"], default: "text" },
        isAnonymous: { type: Boolean, default: false },
        mode: { type: String, default: "public" },
        field: { type: String, default: "" },
        distressLevel: { type: String, enum: ["normal", "medium", "high"], default: "normal" },
        urgencyColor: { type: String, default: "green" },
        toxicityLevel: { type: String, default: "low" },
        isDeleted: { type: Boolean, default: false },
        deletedReason: { type: String, default: "" },
        views: { type: Number, default: 0 },
        likes: [{ type: mongoose.Schema.Types.ObjectId, ref: "User" }],
        commentCount: { type: Number, default: 0 },
        readBy: [{ type: mongoose.Schema.Types.ObjectId, ref: "User" }],
        isRepost: { type: Boolean, default: false },
        originalPostId: { type: mongoose.Schema.Types.ObjectId, ref: "Post" },
        originalAuthorName: { type: String, default: "" }
    },
    { timestamps: true }
);

module.exports = mongoose.model("Post", postSchema);
