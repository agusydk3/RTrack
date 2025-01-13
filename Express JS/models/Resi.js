const mongoose = require('mongoose');

const resiSchema = new mongoose.Schema({
    noResi: {
        type: String,
        required: true
    },
    title: {
        type: String,
        required: true
    },
    courier: {
        type: String,
        required: true,
        enum: ['jne', 'jnt', 'pos', 'sicepat', 'anteraja', 'tiki']
    },
    createdAt: {
        type: Date,
        default: Date.now
    },
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    }
});

// Membuat compound index untuk noResi dan userId
// Ini akan memastikan kombinasi noResi dan userId unik
resiSchema.index({ noResi: 1, userId: 1 }, { unique: true });

module.exports = mongoose.model('Resi', resiSchema, 'cekresi');
