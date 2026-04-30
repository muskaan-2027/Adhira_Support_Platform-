const router = require("express").Router();
const auth = require("../middleware/authMiddleware");
const helpRequestController = require("../controllers/helpRequestController");

router.post("/", auth, helpRequestController.createHelpRequest);
router.get("/", auth, helpRequestController.listHelpRequests);
router.patch("/:id/status", auth, helpRequestController.updateHelpRequestStatus);
router.post("/:id/rate", auth, helpRequestController.rateHelpRequest);
router.post("/:id/follow-up", auth, helpRequestController.addFollowUp);
router.get("/volunteer/:volunteerId", auth, helpRequestController.listVolunteerWork);

module.exports = router;
