const User = require("../models/User");

exports.listVolunteers = async (req, res) => {
    try {
        const { onlyActive = "false" } = req.query;
        const filter = { role: "volunteer" };

        if (String(onlyActive).toLowerCase() === "true") {
            filter.volunteerAvailability = "active";
        }

        const volunteers = await User.find(filter)
            .select("name email profilePhoto volunteerAvailability voterIdVerified occupation gender yearsOfExperience areasOfHelp city state followers following averageRating totalRatings")
            .sort({ averageRating: -1, updatedAt: -1 });

        return res.json({ volunteers });
    } catch (err) {
        return res.status(500).json({ message: "Failed to fetch volunteer profiles" });
    }
};

exports.suggestVolunteers = async (req, res) => {
    try {
        const { issue } = req.query;
        if (!issue) {
            return res.json({ volunteers: [] });
        }

        // Extremely simple keyword match for simulation purposes
        // Split issue into words
        const keywords = issue.toLowerCase().split(/\s+/).filter(w => w.length > 2);
        
        // Find active volunteers
        const volunteers = await User.find({ 
            role: "volunteer", 
            volunteerAvailability: "active",
            areasOfHelp: { $exists: true, $ne: "" }
        }).select("name email profilePhoto volunteerAvailability voterIdVerified occupation gender yearsOfExperience areasOfHelp city state followers following averageRating totalRatings");

        // Filter volunteers whose areasOfHelp contains any of the keywords
        const suggested = volunteers.filter(v => {
            const areas = (v.areasOfHelp || "").toLowerCase();
            return keywords.some(kw => areas.includes(kw));
        });

        // Sort by highest rating
        suggested.sort((a, b) => (b.averageRating || 0) - (a.averageRating || 0));

        return res.json({ volunteers: suggested });
    } catch (err) {
        return res.status(500).json({ message: "Failed to suggest volunteers" });
    }
};

exports.updateAvailability = async (req, res) => {
    try {
        const { availability } = req.body;

        if (!["active", "inactive"].includes(availability)) {
            return res.status(400).json({ message: "availability must be 'active' or 'inactive'" });
        }

        const user = await User.findById(req.user);
        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }

        user.volunteerAvailability = availability;
        await user.save();

        return res.json({ availability: user.volunteerAvailability });
    } catch (err) {
        return res.status(500).json({ message: "Failed to update availability" });
    }
};

exports.rateVolunteer = async (req, res) => {
    try {
        const { rating, review = "" } = req.body;
        const numRating = Number(rating);

        if (isNaN(numRating) || numRating < 1 || numRating > 5) {
            return res.status(400).json({ message: "Rating must be a number between 1 and 5" });
        }

        const volunteer = await User.findById(req.params.id);
        if (!volunteer || volunteer.role !== "volunteer") {
            return res.status(404).json({ message: "Volunteer not found" });
        }

        volunteer.ratings = volunteer.ratings || [];
        volunteer.ratings.push({
            userId: req.user,
            rating: numRating,
            review: review.trim()
        });

        volunteer.totalRatings = volunteer.ratings.length;
        const sum = volunteer.ratings.reduce((acc, r) => acc + r.rating, 0);
        volunteer.averageRating = sum / volunteer.totalRatings;

        await volunteer.save();

        const Notification = require("../models/Notification");
        const rater = await User.findById(req.user);
        await Notification.create({
            userId: volunteer._id,
            title: "New Rating Received",
            message: `${rater ? rater.name : "A user"} gave you a ${numRating}-star rating!`
        });

        return res.json({ 
            message: "Rating submitted successfully",
            averageRating: volunteer.averageRating,
            totalRatings: volunteer.totalRatings
        });
    } catch (err) {
        return res.status(500).json({ message: "Failed to rate volunteer" });
    }
};
