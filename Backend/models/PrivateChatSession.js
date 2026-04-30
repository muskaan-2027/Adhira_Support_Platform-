const mongoose = require("mongoose");

const privateChatSessionSchema = new mongoose.Schema(
    {
        helpSeekerId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
        volunteerId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
        originalPostId: { type: mongoose.Schema.Types.ObjectId, ref: "Post" },
        status: { type: String, enum: ["active", "closed"], default: "active" }
    },
    { timestamps: true }
);

module.exports = mongoose.model("PrivateChatSession", privateChatSessionSchema);
