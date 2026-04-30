const mongoose = require("mongoose");

const privateMessageSchema = new mongoose.Schema(
    {
        sessionId: { type: mongoose.Schema.Types.ObjectId, ref: "PrivateChatSession", required: true },
        senderId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
        content: { type: String, required: true, trim: true },
        urgencyColor: { type: String, enum: ["green", "yellow", "red"], default: "green" },
        toxicityLevel: { type: String, enum: ["low", "medium", "high"], default: "low" },
        isDeleted: { type: Boolean, default: false },
        deletedReason: { type: String, default: "" }
    },
    { timestamps: true }
);

module.exports = mongoose.model("PrivateMessage", privateMessageSchema);
