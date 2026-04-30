const router = require("express").Router();
const { chatbot } = require("../controllers/chatbotController");

router.post("/", chatbot);

module.exports = router;