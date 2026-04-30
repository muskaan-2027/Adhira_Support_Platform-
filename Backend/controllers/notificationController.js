const Notification = require("../models/Notification");

exports.getNotifications = async (req, res) => {
    try {
        const notifications = await Notification.find({ userId: req.user })
            .sort({ createdAt: -1 })
            .limit(50);
        return res.json({ notifications });
    } catch (err) {
        return res.status(500).json({ message: "Failed to fetch notifications" });
    }
};

exports.markAsRead = async (req, res) => {
    try {
        await Notification.updateMany(
            { userId: req.user, isRead: false },
            { $set: { isRead: true } }
        );
        return res.json({ message: "Notifications marked as read" });
    } catch (err) {
        return res.status(500).json({ message: "Failed to mark notifications as read" });
    }
};
