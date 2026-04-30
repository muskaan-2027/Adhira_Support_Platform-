const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");
require("dotenv").config();

const User = require("../models/User");

async function seedAdmin() {
    const adminEmail = (process.env.ADMIN_EMAIL || "admin").toLowerCase();
    const adminPassword = process.env.ADMIN_PASSWORD || "admin";

    if (!process.env.MONGO_URI) {
        throw new Error("MONGO_URI is missing in environment");
    }

    await mongoose.connect(process.env.MONGO_URI);

    const hashed = await bcrypt.hash(adminPassword, 10);
    const adminUser = await User.findOneAndUpdate(
        { email: adminEmail.toLowerCase() },
        {
            name: "admin",
            email: adminEmail.toLowerCase(),
            password: hashed,
            role: "user",
            onboardingCompleted: true,
            voterIdVerified: false,
            isAnonymous: false
        },
        { new: true, upsert: true, setDefaultsOnInsert: true }
    );

    console.log("Admin user is ready.");
    console.log(`login email: ${adminUser.email}`);
    console.log(`password: ${adminPassword}`);
}

seedAdmin()
    .catch((err) => {
        console.error("Failed to seed admin user:", err.message);
        process.exitCode = 1;
    })
    .finally(async () => {
        await mongoose.disconnect();
    });
