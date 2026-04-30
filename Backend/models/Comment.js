const mongoose = require("mongoose");

const commentSchema = new mongoose.Schema(
    {
        postId: { type: mongoose.Schema.Types.ObjectId, ref: "Post", required: true },
        userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
        content: { type: String, required: true, trim: true },
        toxicityLevel: { type: String, enum: ["low", "medium", "high"], default: "low" },
        isDeleted: { type: Boolean, default: false },
        deletedReason: { type: String, default: "" }
    },
    { timestamps: true }
);

module.exports = mongoose.model("Comment", commentSchema);
