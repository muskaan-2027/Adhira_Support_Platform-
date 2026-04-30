const mongoose = require("mongoose");

const helpRequestSchema = new mongoose.Schema(
    {
        requesterId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
        volunteerId: { type: mongoose.Schema.Types.ObjectId, ref: "User", default: null },
        sosId: { type: mongoose.Schema.Types.ObjectId, ref: "SOS", default: null },
        message: { type: String, required: true, trim: true },
        assistanceNote: { type: String, default: "", trim: true },
        hoursSpent: { type: Number, default: 0 },
        peopleHelped: { type: Number, default: 0 },
        rating: { type: Number, default: 0, min: 0, max: 5 },
        ratingReview: { type: String, default: "", trim: true },
        status: {
            type: String,
            enum: ["pending", "accepted", "rejected", "completed"],
            default: "pending"
        },
        followUps: [
            {
                senderId: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
                message: { type: String, required: true, trim: true },
                createdAt: { type: Date, default: Date.now }
            }
        ]
    },
    { timestamps: true }
);

module.exports = mongoose.model("HelpRequest", helpRequestSchema);
