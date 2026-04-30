const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const User = require("../models/User");

let googleClient = null;

const getGoogleClient = () => {
    if (googleClient) {
        return googleClient;
    }

    const { OAuth2Client } = require("google-auth-library");
    googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);
    return googleClient;
};

const sanitizeUser = (userDoc) => {
    const user = userDoc.toObject ? userDoc.toObject() : userDoc;
    delete user.password;
    return user;
};

const signToken = (userId) => jwt.sign({ id: userId }, process.env.JWT_SECRET, { expiresIn: "7d" });

exports.register = async (req, res) => {
    try {
        const { name, email, password, role } = req.body;

        if (!name || !email || !password || !role) {
            return res.status(400).json({ message: "name, email, password and role are required" });
        }

        if (!["user", "volunteer"].includes(role)) {
            return res.status(400).json({ message: "role must be either 'user' or 'volunteer'" });
        }

        const existing = await User.findOne({ email: email.toLowerCase() });
        if (existing) {
            return res.status(409).json({ message: "User already exists" });
        }

        const hashed = await bcrypt.hash(password, 10);
        const user = await User.create({
            name,
            email: email.toLowerCase(),
            password: hashed,
            role,
            onboardingCompleted: Boolean(name && String(name).trim() && role)
        });

        return res.status(201).json({
            token: signToken(user._id),
            user: sanitizeUser(user)
        });
    } catch (err) {
        return res.status(500).json({ message: "Error registering user" });
    }
};

exports.login = async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({ message: "email and password are required" });
        }

        const user = await User.findOne({ email: email.toLowerCase() });
        if (!user || !user.password) {
            return res.status(400).json({ message: "Invalid credentials" });
        }

        const match = await bcrypt.compare(password, user.password);
        if (!match) {
            return res.status(400).json({ message: "Invalid credentials" });
        }

        return res.json({
            token: signToken(user._id),
            user: sanitizeUser(user)
        });
    } catch (err) {
        return res.status(500).json({ message: "Login failed" });
    }
};

exports.googleLogin = async (req, res) => {
    try {
        const { idToken } = req.body;

        if (!idToken) {
            return res.status(400).json({ message: "Google idToken is required" });
        }

        if (!process.env.GOOGLE_CLIENT_ID) {
            return res.status(500).json({ message: "GOOGLE_CLIENT_ID is not configured" });
        }

        const ticket = await getGoogleClient().verifyIdToken({
            idToken,
            audience: process.env.GOOGLE_CLIENT_ID
        });

        const payload = ticket.getPayload();
        const googleId = payload.sub;
        const email = payload.email?.toLowerCase();
        const name = payload.name || "Google User";

        if (!email) {
            return res.status(400).json({ message: "Google account email is required" });
        }

        let user = await User.findOne({ $or: [{ googleId }, { email }] });
        if (!user) {
            user = await User.create({
                name,
                email,
                googleId
            });
        } else if (!user.googleId) {
            user.googleId = googleId;
            await user.save();
        }

        return res.json({
            token: signToken(user._id),
            user: sanitizeUser(user)
        });
    } catch (err) {
        if (err && err.code === "MODULE_NOT_FOUND" && String(err.message).includes("google-auth-library")) {
            return res.status(500).json({ message: "google-auth-library is not installed on the backend" });
        }
        return res.status(401).json({ message: "Google authentication failed" });
    }
};
