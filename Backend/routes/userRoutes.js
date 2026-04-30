const router = require("express").Router();
const auth = require("../middleware/authMiddleware");
const { 
    getMe, 
    updateProfile, 
    updateRole,
    addEmergencyContact,
    removeEmergencyContact,
    triggerSOS,
    getSOSHistory,
    followUser,
    getUserById,
    getFollowInfo,
    getFollowRequests,
    respondToFollowRequest,
    updatePreferences,
    searchUsers,
    changePassword
} = require("../controllers/userController");

router.get("/me", auth, getMe);
router.get("/search", auth, searchUsers);
router.patch("/preferences", auth, updatePreferences);
router.get("/follow/info/:targetId", auth, getFollowInfo);
router.get("/follow/requests", auth, getFollowRequests);
router.post("/follow/respond", auth, respondToFollowRequest);
router.get("/:userId", auth, getUserById);
router.patch("/profile", auth, updateProfile);
router.patch("/role", auth, updateRole);
router.patch("/password", auth, changePassword);

router.post("/contacts", auth, addEmergencyContact);
router.delete("/contacts/:contactId", auth, removeEmergencyContact);

router.post("/sos", auth, triggerSOS);
router.get("/sos/history", auth, getSOSHistory);
router.post("/follow/:targetId", auth, followUser);

module.exports = router;
