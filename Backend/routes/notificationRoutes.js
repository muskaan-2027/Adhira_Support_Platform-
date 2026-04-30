const router = require("express").Router();
const auth = require("../middleware/authMiddleware");
const notificationController = require("../controllers/notificationController");

router.get("/", auth, notificationController.getNotifications);
router.patch("/mark-read", auth, notificationController.markAsRead);

module.exports = router;
