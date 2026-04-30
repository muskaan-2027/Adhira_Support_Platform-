const HelpRequest = require("../models/HelpRequest");
const User = require("../models/User");
const Notification = require("../models/Notification");

exports.createHelpRequest = async (req, res) => {
    try {
        const { message, sosId = null, volunteerId = null } = req.body;

        if (!message) {
            return res.status(400).json({ message: "message is required" });
        }

        const requester = await User.findById(req.user);
        if (!requester) {
            return res.status(404).json({ message: "User not found" });
        }

        if (requester.role !== "user") {
            return res.status(403).json({ message: "Only normal users can create help requests" });
        }

        let assignedVolunteerId = null;
        if (volunteerId) {
            const volunteer = await User.findById(volunteerId);
            if (!volunteer || volunteer.role !== "volunteer") {
                return res.status(400).json({ message: "Selected volunteer profile is invalid" });
            }
            assignedVolunteerId = volunteer._id;
        }

        const helpRequest = await HelpRequest.create({
            requesterId: requester._id,
            volunteerId: assignedVolunteerId,
            sosId,
            message
        });

        if (assignedVolunteerId) {
            // Notify the specific volunteer
            await Notification.create({
                userId: assignedVolunteerId,
                title: "New Help Request",
                message: `${requester.name} has specifically requested your help.`
            });
        } else {
            // Notify all active volunteers
            const activeVolunteers = await User.find({ role: "volunteer", volunteerAvailability: "active" });
            if (activeVolunteers.length > 0) {
                const notifications = activeVolunteers.map(v => ({
                    userId: v._id,
                    title: "New Help Request",
                    message: `A new help request was created by ${requester.name}. Please check your dashboard.`
                }));
                await Notification.insertMany(notifications);
            }
        }

        return res.status(201).json({ helpRequest });
    } catch (err) {
        return res.status(500).json({ message: "Failed to create help request" });
    }
};

exports.listHelpRequests = async (req, res) => {
    try {
        const user = await User.findById(req.user);
        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }

        let filter = { requesterId: user._id };
        if (user.role === "volunteer") {
            filter = {
                $or: [
                    { status: "pending", volunteerId: null },
                    { status: "pending", volunteerId: user._id },
                    { volunteerId: user._id, status: { $in: ["accepted", "rejected", "completed"] } }
                ]
            };
        }

        const requests = await HelpRequest.find(filter)
            .populate("requesterId", "name")
            .populate("volunteerId", "name")
            .populate("followUps.senderId", "name")
            .sort({ createdAt: -1 });

        return res.json({ requests });
    } catch (err) {
        return res.status(500).json({ message: "Failed to fetch help requests" });
    }
};

exports.updateHelpRequestStatus = async (req, res) => {
    try {
        const { status, assistanceNote = "", hoursSpent = 0, peopleHelped = 0 } = req.body;
        const user = await User.findById(req.user);

        if (!user || user.role !== "volunteer") {
            return res.status(403).json({ message: "Only volunteers can update help request status" });
        }

        if (!["accepted", "rejected", "completed"].includes(status)) {
            return res.status(400).json({ message: "Invalid status update" });
        }

        const request = await HelpRequest.findById(req.params.id);
        if (!request) {
            return res.status(404).json({ message: "Help request not found" });
        }

        if (status === "accepted") {
            if (request.status !== "pending") {
                return res.status(400).json({ message: "Only pending requests can be accepted" });
            }
            if (request.volunteerId && request.volunteerId.toString() !== user._id.toString()) {
                return res.status(403).json({ message: "This request is assigned to another volunteer" });
            }
            request.status = "accepted";
            request.volunteerId = user._id;
        }

        if (status === "rejected") {
            if (request.status !== "pending") {
                return res.status(400).json({ message: "Only pending requests can be rejected" });
            }
            if (request.volunteerId && request.volunteerId.toString() !== user._id.toString()) {
                return res.status(403).json({ message: "This request is assigned to another volunteer" });
            }
            request.status = "rejected";
            request.volunteerId = user._id;
        }

        if (status === "completed") {
            const ownsRequest = request.volunteerId && request.volunteerId.toString() === user._id.toString();
            if (!ownsRequest || request.status !== "accepted") {
                return res.status(400).json({ message: "Only accepted requests assigned to you can be completed" });
            }
            request.status = "completed";
            if (typeof assistanceNote === "string") {
                request.assistanceNote = assistanceNote.trim();
            }
            request.hoursSpent = Number(hoursSpent) || 0;
            request.peopleHelped = Number(peopleHelped) || 0;
        }

        await request.save();

        if (status === "accepted") {
            await Notification.create({
                userId: request.requesterId,
                title: "Request Accepted",
                message: "A volunteer has accepted your help request."
            });
        } else if (status === "rejected") {
            await Notification.create({
                userId: request.requesterId,
                title: "Request Rejected",
                message: "A volunteer has rejected your help request."
            });
        } else if (status === "completed") {
            await Notification.create({
                userId: request.requesterId,
                title: "Request Completed",
                message: "Your help request has been marked as completed."
            });
        }

        return res.json({ helpRequest: request });
    } catch (err) {
        return res.status(500).json({ message: "Failed to update help request" });
    }
};

exports.rateHelpRequest = async (req, res) => {
    try {
        const { rating, review = "" } = req.body;
        const user = await User.findById(req.user);

        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }

        const request = await HelpRequest.findById(req.params.id);
        if (!request) {
            return res.status(404).json({ message: "Help request not found" });
        }

        if (request.requesterId.toString() !== user._id.toString()) {
            return res.status(403).json({ message: "Only the requester can rate this help request" });
        }

        if (request.status !== "completed") {
            return res.status(400).json({ message: "Can only rate completed help requests" });
        }

        const numRating = Number(rating);
        if (isNaN(numRating) || numRating < 1 || numRating > 5) {
            return res.status(400).json({ message: "Rating must be a number between 1 and 5" });
        }

        request.rating = numRating;
        if (typeof review === "string") {
            request.ratingReview = review.trim();
        }

        await request.save();

        if (request.volunteerId) {
            await Notification.create({
                userId: request.volunteerId,
                title: "New Rating Received",
                message: `${user.name} gave you a ${numRating}-star rating for your assistance.`
            });
        }

        return res.json({ helpRequest: request });
    } catch (err) {
        return res.status(500).json({ message: "Failed to rate help request" });
    }
};

exports.addFollowUp = async (req, res) => {
    try {
        const { message } = req.body;
        if (!message) return res.status(400).json({ message: "Message is required" });

        const request = await HelpRequest.findById(req.params.id);
        if (!request) return res.status(404).json({ message: "Help request not found" });

        // Only requester or assigned volunteer can follow up
        const isRequester = request.requesterId.toString() === req.user.toString();
        const isVolunteer = request.volunteerId && request.volunteerId.toString() === req.user.toString();

        if (!isRequester && !isVolunteer) {
            return res.status(403).json({ message: "You are not authorized to follow up on this request" });
        }

        request.followUps.push({
            senderId: req.user,
            message: message.trim()
        });

        await request.save();

        // Notify the other party
        const recipientId = isRequester ? request.volunteerId : request.requesterId;
        if (recipientId) {
            await Notification.create({
                userId: recipientId,
                title: "New Follow-up Message",
                message: "You have a new message regarding a help request."
            });
        }

        return res.json({ helpRequest: request });
    } catch (err) {
        return res.status(500).json({ message: "Failed to add follow-up" });
    }
};

exports.listVolunteerWork = async (req, res) => {
    try {
        const { volunteerId } = req.params;
        const requests = await HelpRequest.find({ volunteerId, status: "completed" });
        return res.json({ requests });
    } catch (err) {
        return res.status(500).json({ message: "Failed to fetch volunteer work" });
    }
};
