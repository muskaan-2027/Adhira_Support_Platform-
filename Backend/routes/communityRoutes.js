const router = require("express").Router();
const auth = require("../middleware/authMiddleware");
const communityController = require("../controllers/communityController");

router.get("/blogs", auth, communityController.getBlogs);

router.post("/stories", auth, communityController.createStory);
router.get("/stories", auth, communityController.getStories);
router.post("/stories/:id/like", auth, communityController.toggleLike);

module.exports = router;
