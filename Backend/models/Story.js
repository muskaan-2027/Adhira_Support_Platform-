const mongoose = require("mongoose");

const storySchema = new mongoose.Schema(
    {
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true
        },
        title: {
            type: String,
            required: true,
            trim: true
        },
        snippet: {
            type: String,
            required: true,
            trim: true
        },
        anonymous: {
            type: Boolean,
            default: false
        },
        likes: [{
            type: mongoose.Schema.Types.ObjectId,
            ref: "User"
        }]
    },
    { timestamps: true }
);

module.exports = mongoose.model("Story", storySchema);
