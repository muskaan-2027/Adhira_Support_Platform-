const User = require("../models/User");
const SOSHistory = require("../models/SOSHistory");

const sanitizeUser = (userDoc) => {
    const user = userDoc.toObject ? userDoc.toObject() : userDoc;
    delete user.password;
    return user;
};

const computeOnboardingCompletion = (user) => {
    return Boolean(user.name && user.role);
};

exports.getMe = async (req, res) => {
    try {
        const user = await User.findById(req.user);
        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }

        return res.json({ user: sanitizeUser(user) });
    } catch (err) {
        return res.status(500).json({ message: "Failed to fetch profile" });
    }
};

exports.updateProfile = async (req, res) => {
    try {
        const { 
            name, voterIdVerified, isAnonymous,
            profilePhoto, registrationId, dateOfBirth, gender, occupation, skills,
            yearsOfExperience, volunteerExperience, areasOfHelp,
            languagesKnown, phone, address, city, state, pincode,
            connectedToNGO, ngoName, socialMediaLink, additionalInfo 
        } = req.body;
        
        const user = await User.findById(req.user);

        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }

        if (typeof name === "string") user.name = name.trim();
        if (typeof voterIdVerified === "boolean") user.voterIdVerified = voterIdVerified;
        if (typeof isAnonymous === "boolean") user.isAnonymous = isAnonymous;
        
        if (typeof profilePhoto === "string") user.profilePhoto = profilePhoto;
        if (typeof registrationId === "string") user.registrationId = registrationId.trim();
        if (typeof dateOfBirth === "string") user.dateOfBirth = dateOfBirth;
        if (typeof gender === "string") user.gender = gender;
        if (typeof occupation === "string") user.occupation = occupation.trim();
        if (typeof skills === "string") user.skills = skills;
        if (typeof yearsOfExperience === "string") user.yearsOfExperience = yearsOfExperience;
        if (typeof volunteerExperience === "string") user.volunteerExperience = volunteerExperience;
        if (typeof areasOfHelp === "string") user.areasOfHelp = areasOfHelp;
        if (Array.isArray(languagesKnown)) user.languagesKnown = languagesKnown;
        if (typeof phone === "string") user.phone = phone.trim();
        if (typeof address === "string") user.address = address.trim();
        if (typeof city === "string") user.city = city.trim();
        if (typeof state === "string") user.state = state.trim();
        if (typeof pincode === "string") user.pincode = pincode.trim();
        if (typeof connectedToNGO === "boolean") user.connectedToNGO = connectedToNGO;
        if (typeof ngoName === "string") user.ngoName = ngoName.trim();
        if (typeof socialMediaLink === "string") user.socialMediaLink = socialMediaLink.trim();
        if (typeof additionalInfo === "string") user.additionalInfo = additionalInfo;

        user.onboardingCompleted = computeOnboardingCompletion(user);
        await user.save();

        return res.json({ user: sanitizeUser(user) });
    } catch (err) {
        return res.status(500).json({ message: "Failed to update profile" });
    }
};

exports.updateRole = async (req, res) => {
    try {
        const { role } = req.body;

        if (!["user", "volunteer"].includes(role)) {
            return res.status(400).json({ message: "role must be either 'user' or 'volunteer'" });
        }

        const user = await User.findById(req.user);
        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }

        user.role = role;
        user.onboardingCompleted = computeOnboardingCompletion(user);
        await user.save();

        return res.json({ user: sanitizeUser(user) });
    } catch (err) {
        return res.status(500).json({ message: "Failed to update role" });
    }
};

exports.addEmergencyContact = async (req, res) => {
    try {
        const { name, phone } = req.body;
        if (!name || !phone) {
            return res.status(400).json({ message: "Name and phone are required" });
        }

        const user = await User.findById(req.user);
        if (!user) return res.status(404).json({ message: "User not found" });

        user.emergencyContacts.push({ name: name.trim(), phone: phone.trim() });
        await user.save();

        return res.json({ user: sanitizeUser(user) });
    } catch (err) {
        return res.status(500).json({ message: "Failed to add emergency contact" });
    }
};

exports.removeEmergencyContact = async (req, res) => {
    try {
        const { contactId } = req.params;

        const user = await User.findById(req.user);
        if (!user) return res.status(404).json({ message: "User not found" });

        const contact = user.emergencyContacts.id(contactId);
        if (!contact) {
            return res.status(404).json({ message: "Contact not found" });
        }

        contact.deleteOne();
        await user.save();

        return res.json({ user: sanitizeUser(user) });
    } catch (err) {
        console.error("Remove contact error:", err);
        return res.status(500).json({ message: "Failed to remove emergency contact" });
    }
};

exports.triggerSOS = async (req, res) => {
    try {
        const { latitude, longitude, address } = req.body;

        const user = await User.findById(req.user);
        if (!user) return res.status(404).json({ message: "User not found" });

        const contactsNotified = user.emergencyContacts.map(c => ({
            name: c.name,
            phone: c.phone
        }));

        const sos = new SOSHistory({
            userId: user._id,
            location: {
                latitude,
                longitude,
                address
            },
            contactsNotified
        });

        await sos.save();

        // In a real app, this is where SMS/Notifications would be sent
        console.log(`[SOS TRIGGERED] By ${user.name || user.email}. Location: ${latitude}, ${longitude}. Notified: ${contactsNotified.length} contacts.`);

        return res.json({ message: "SOS Alert sent successfully", sos });
    } catch (err) {
        console.error("SOS Trigger Error:", err);
        return res.status(500).json({ message: "Failed to trigger SOS" });
    }
};

exports.getSOSHistory = async (req, res) => {
    try {
        const history = await SOSHistory.find({ userId: req.user }).sort({ createdAt: -1 });
        return res.json({ history });
    } catch (err) {
        return res.status(500).json({ message: "Failed to fetch SOS history" });
    }
};

exports.followUser = async (req, res) => {
    try {
        const { targetId } = req.params;
        if (targetId === req.user.toString()) {
            return res.status(400).json({ message: "You cannot follow yourself" });
        }
        const [me, target] = await Promise.all([
            User.findById(req.user),
            User.findById(targetId),
        ]);
        if (!me || !target) return res.status(404).json({ message: "User not found" });

        const alreadyFollowing = me.following.map(id => id.toString()).includes(targetId);
        const alreadyRequested = target.followRequests.map(id => id.toString()).includes(req.user.toString());

        if (alreadyFollowing) {
            // Unfollow
            me.following = me.following.filter(id => id.toString() !== targetId);
            target.followers = target.followers.filter(id => id.toString() !== req.user.toString());
            await Promise.all([me.save(), target.save()]);
            return res.json({ 
                message: "Unfollowed", 
                isFollowing: false, 
                isRequested: false,
                followers: target.followers.length,
                following: target.following.length
            });
        } else if (alreadyRequested) {
            // Cancel request
            target.followRequests = target.followRequests.filter(id => id.toString() !== req.user.toString());
            await target.save();
            return res.json({ 
                message: "Follow request cancelled", 
                isFollowing: false, 
                isRequested: false,
                followers: target.followers.length,
                following: target.following.length
            });
        } else {
            // Send request
            target.followRequests.push(req.user);
            await target.save();

            // Notify target
            const Notification = require("../models/Notification");
            await Notification.create({
                userId: target._id,
                title: "New Follow Request",
                message: `${me.name} wants to connect with you.`,
                type: "follow_request"
            });

            return res.json({ 
                message: "Follow request sent", 
                isFollowing: false, 
                isRequested: true,
                followers: target.followers.length,
                following: target.following.length
            });
        }
    } catch (err) {
        console.error("Follow error:", err);
        return res.status(500).json({ message: "Failed to update follow status" });
    }
};

exports.getFollowRequests = async (req, res) => {
    try {
        const user = await User.findById(req.user).populate("followRequests", "name email profilePhoto occupation");
        if (!user) return res.status(404).json({ message: "User not found" });
        return res.json({ requests: user.followRequests });
    } catch (err) {
        return res.status(500).json({ message: "Failed to fetch follow requests" });
    }
};

exports.respondToFollowRequest = async (req, res) => {
    try {
        const { requesterId, action } = req.body; // action: 'accept' or 'reject'
        const me = await User.findById(req.user);
        const requester = await User.findById(requesterId);

        if (!me || !requester) return res.status(404).json({ message: "User not found" });

        // Remove from requests
        me.followRequests = me.followRequests.filter(id => id.toString() !== requesterId);

        if (action === "accept") {
            // Add to followers
            if (!me.followers.includes(requesterId)) {
                me.followers.push(requesterId);
            }
            // Add to requester's following
            if (!requester.following.includes(req.user)) {
                requester.following.push(req.user);
            }
            await Promise.all([me.save(), requester.save()]);
            return res.json({ message: "Follow request accepted" });
        } else {
            await me.save();
            return res.json({ message: "Follow request rejected" });
        }
    } catch (err) {
        return res.status(500).json({ message: "Failed to respond to follow request" });
    }
};

exports.getUserById = async (req, res) => {
    try {
        const user = await User.findById(req.params.userId);
        if (!user) return res.status(404).json({ message: "User not found" });
        return res.json({ user: sanitizeUser(user) });
    } catch (err) {
        return res.status(500).json({ message: "Failed to fetch user" });
    }
};

exports.searchUsers = async (req, res) => {
    try {
        const { query } = req.query;
        if (!query) return res.json({ users: [] });

        const users = await User.find({
            $or: [
                { name: { $regex: query, $options: "i" } },
                { email: { $regex: query, $options: "i" } }
            ],
            _id: { $ne: req.user } // Don't include self
        }).limit(10).select("name email profilePhoto role occupation city state");

        return res.json({ users });
    } catch (err) {
        console.error("Search error:", err);
        return res.status(500).json({ message: "Failed to search users" });
    }
};

exports.getFollowInfo = async (req, res) => {
    try {
        const target = await User.findById(req.params.targetId);
        if (!target) return res.status(404).json({ message: "User not found" });
        
        const isFollowing = target.followers.map(id => id.toString()).includes(req.user.toString());
        const isRequested = target.followRequests.map(id => id.toString()).includes(req.user.toString());
        return res.json({
            followers: target.followers.length,
            following: target.following.length,
            isFollowing,
            isRequested
        });
    } catch (err) {
        return res.status(500).json({ message: "Failed to fetch follow info" });
    }
};

exports.updatePreferences = async (req, res) => {
    try {
        const { notifications, language, theme } = req.body;
        const user = await User.findById(req.user);
        if (!user) return res.status(404).json({ message: "User not found" });

        if (typeof notifications === "boolean") user.preferences.notifications = notifications;
        if (typeof language === "string") user.preferences.language = language;
        if (typeof theme === "string") user.preferences.theme = theme;

        await user.save();
        return res.json({ user: sanitizeUser(user) });
    } catch (err) {
        return res.status(500).json({ message: "Failed to update preferences" });
    }
};

exports.changePassword = async (req, res) => {
    try {
        const { oldPassword, newPassword } = req.body;
        if (!oldPassword || !newPassword) {
            return res.status(400).json({ message: "Old password and new password are required" });
        }

        const user = await User.findById(req.user);
        if (!user) return res.status(404).json({ message: "User not found" });
        
        if (!user.password) {
            return res.status(400).json({ message: "Cannot change password. Please login using your original method." });
        }

        const bcrypt = require("bcryptjs");
        const match = await bcrypt.compare(oldPassword, user.password);
        if (!match) {
            return res.status(400).json({ message: "Incorrect old password" });
        }

        user.password = await bcrypt.hash(newPassword, 10);
        await user.save();

        return res.json({ message: "Password updated successfully" });
    } catch (err) {
        console.error("Change password error:", err);
        return res.status(500).json({ message: "Failed to update password" });
    }
};
