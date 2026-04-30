const mongoose = require("mongoose");

const sosSchema = new mongoose.Schema(
    {
        userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
        location: {
            lat: { type: Number, required: true },
            lng: { type: Number, required: true }
        },
        notes: { type: String, default: "", trim: true }
    },
    { timestamps: true }
);

module.exports = mongoose.model("SOS", sosSchema);
