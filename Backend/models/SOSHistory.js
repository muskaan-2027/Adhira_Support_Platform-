const mongoose = require('mongoose');

const sosHistorySchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    location: {
        latitude: { type: Number },
        longitude: { type: Number },
        address: { type: String }
    },
    contactsNotified: [{
        name: { type: String },
        phone: { type: String }
    }],
    status: { type: String, enum: ['active', 'resolved'], default: 'active' },
    createdAt: { type: Date, default: Date.now },
    resolvedAt: { type: Date }
});

module.exports = mongoose.model('SOSHistory', sosHistorySchema);
