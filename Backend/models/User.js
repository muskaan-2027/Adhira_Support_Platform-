const mongoose = require("mongoose");

const userSchema = new mongoose.Schema(
    {
        name: { type: String, trim: true },
        email: { type: String, unique: true, sparse: true, lowercase: true, trim: true },
        password: { type: String },
        googleId: { type: String, unique: true, sparse: true },
        isAnonymous: { type: Boolean, default: false },
        role: {
            type: String,
            enum: ["user", "volunteer"],
            default: null
        },
        onboardingCompleted: { type: Boolean, default: false },
        voterIdVerified: { type: Boolean, default: false },
        volunteerAvailability: {
            type: String,
            enum: ["active", "inactive"],
            default: "inactive"
        },
        // Volunteer Profile Fields
        profilePhoto: { type: String },
        registrationId: { type: String, trim: true },
        dateOfBirth: { type: String },
        gender: { type: String },
        occupation: { type: String, trim: true },
        skills: { type: String },
        yearsOfExperience: { type: String },
        volunteerExperience: { type: String },
        areasOfHelp: { type: String },
        languagesKnown: { type: [String], default: [] },
        phone: { type: String, trim: true },
        address: { type: String, trim: true },
        city: { type: String, trim: true },
        state: { type: String, trim: true },
        pincode: { type: String, trim: true },
        connectedToNGO: { type: Boolean, default: false },
        ngoName: { type: String, trim: true },
        socialMediaLink: { type: String, trim: true },
        additionalInfo: { type: String },
        ratings: [
            {
                userId: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
                rating: { type: Number, min: 1, max: 5 },
                review: { type: String, trim: true },
                createdAt: { type: Date, default: Date.now }
            }
        ],
        averageRating: { type: Number, default: 0 },
        totalRatings: { type: Number, default: 0 },
        emergencyContacts: [
            {
                _id: { type: mongoose.Schema.Types.ObjectId, auto: true },
                name: { type: String, required: true },
                phone: { type: String, required: true }
            }
        ],
        followers: [{ type: mongoose.Schema.Types.ObjectId, ref: "User" }],
        following: [{ type: mongoose.Schema.Types.ObjectId, ref: "User" }],
        followRequests: [{ type: mongoose.Schema.Types.ObjectId, ref: "User" }],
        preferences: {
            notifications: { type: Boolean, default: true },
            language: { type: String, default: "English" },
            theme: { type: String, default: "Light" }
        }
    },
    { timestamps: true }
);

module.exports = mongoose.model("User", userSchema);
