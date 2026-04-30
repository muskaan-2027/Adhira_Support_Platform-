const router = require("express").Router();
const auth = require("../middleware/authMiddleware");
const { listVolunteers, updateAvailability, rateVolunteer, suggestVolunteers } = require("../controllers/volunteerController");

router.get("/", auth, listVolunteers);
router.get("/suggest", auth, suggestVolunteers);
router.patch("/availability", auth, updateAvailability);
router.post("/:id/rate", auth, rateVolunteer);

module.exports = router;
