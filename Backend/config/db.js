const mongoose = require("mongoose");

const connectDB = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log("MongoDB Connected");
    } catch (err) {
        console.log("MongoDB connection failed:", err.message);
        console.log("Expected local DB at:", process.env.MONGO_URI);
        console.log("If using Docker, run: npm run db:up");
        process.exit(1);
    }
};

module.exports = connectDB;
