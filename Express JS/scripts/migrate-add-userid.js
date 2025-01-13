require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../models/User');

function generateUserID() {
    return Math.floor(10000 + Math.random() * 90000).toString();
}

async function isUserIDUnique(User, userID) {
    const existingUser = await User.findOne({ userID });
    return !existingUser;
}

async function generateUniqueUserID(User) {
    let userID;
    let isUnique = false;
    let attempts = 0;
    const maxAttempts = 10;

    while (!isUnique && attempts < maxAttempts) {
        userID = generateUserID();
        isUnique = await isUserIDUnique(User, userID);
        attempts++;
    }

    if (!isUnique) {
        throw new Error('Could not generate unique userID');
    }

    return userID;
}

async function migrateUsers() {
    try {
        // Connect to MongoDB
        await mongoose.connect(process.env.MONGODB_URI, {
            useNewUrlParser: true,
            useUnifiedTopology: true
        });
        console.log('Connected to MongoDB');

        // Find all users without userID
        const users = await User.find({ userID: { $exists: false } });
        console.log(`Found ${users.length} users without userID`);

        // Update each user
        for (const user of users) {
            try {
                const userID = await generateUniqueUserID(User);
                await User.updateOne(
                    { _id: user._id },
                    { $set: { userID: userID } }
                );
                console.log(`Updated user ${user.username} with userID: ${userID}`);
            } catch (error) {
                console.error(`Error updating user ${user.username}:`, error.message);
            }
        }

        console.log('Migration completed');
    } catch (error) {
        console.error('Migration failed:', error.message);
    } finally {
        await mongoose.connection.close();
        console.log('Disconnected from MongoDB');
    }
}

// Run migration
migrateUsers();
