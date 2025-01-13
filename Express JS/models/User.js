const mongoose = require('mongoose');

function generateUserID() {
    return Math.floor(10000 + Math.random() * 90000).toString();
}

const resiSchema = new mongoose.Schema({
    title: {
        type: String,
        required: true
    },
    resiNumber: {
        type: String,
        required: true
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

const userSchema = new mongoose.Schema({
    userID: {
        type: String,
        required: true,
        unique: true,
        default: generateUserID
    },
    name: {
        type: String,
        required: true,
        min: 2,
        max: 255
    },
    email: {
        type: String,
        required: true,
        unique: true,
        min: 5,
        max: 255
    },
    username: {
        type: String,
        required: true,
        unique: true,
        min: 3,
        max: 255
    },
    password: {
        type: String,
        required: true,
        min: 6,
        max: 1024
    },
    profileImage: {
        type: String,
        default: null
    },
    resis: [resiSchema],
    createdAt: {
        type: Date,
        default: Date.now
    }
});

// Middleware to ensure unique userID
userSchema.pre('save', async function(next) {
    if (this.isNew) {
        const User = this.constructor;
        let isUnique = false;
        let attempts = 0;
        const maxAttempts = 10;

        while (!isUnique && attempts < maxAttempts) {
            const userID = generateUserID();
            const existingUser = await User.findOne({ userID });
            
            if (!existingUser) {
                this.userID = userID;
                isUnique = true;
            }
            attempts++;
        }

        if (!isUnique) {
            next(new Error('Could not generate unique userID'));
            return;
        }
    }
    next();
});

const User = mongoose.model('User', userSchema);

module.exports = User;
