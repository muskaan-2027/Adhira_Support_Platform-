const router = require("express").Router();
const SOS = require("../models/SOS");
const auth = require("../middleware/authMiddleware");

router.post("/", auth, async (req, res) => {
    try {
        const { lat, lng, notes = "" } = req.body;

        if (typeof lat !== "number" || typeof lng !== "number") {
            return res.status(400).json({ message: "lat and lng are required numeric values" });
        }

        const sos = await SOS.create({
            userId: req.user,
            location: { lat, lng },
            notes
        });

        const Notification = require("../models/Notification");
        const User = require("../models/User");

        await Notification.create({
            userId: req.user,
            title: "SOS Alert",
            message: "SOS sent successfully. Nearby help and emergency contacts have been notified."
        });

        // Notify active volunteers
        const activeVolunteers = await User.find({ role: "volunteer", volunteerAvailability: "active" });
        if (activeVolunteers.length > 0) {
            const volunteerNotifications = activeVolunteers.map(v => ({
                userId: v._id,
                title: "Emergency SOS Alert",
                message: "A user has triggered an SOS alert. Please check for details."
            }));
            await Notification.insertMany(volunteerNotifications);
        }

        return res.status(201).json({ message: "SOS sent", sos });
    } catch (err) {
        return res.status(500).json({ message: "Failed to send SOS" });
    }
});

router.get("/history", auth, async (req, res) => {
    try {
        const history = await SOS.find({ userId: req.user }).sort({ createdAt: -1 });
        return res.json({ history });
    } catch (err) {
        return res.status(500).json({ message: "Failed to fetch SOS history" });
    }
});

module.exports = router;
