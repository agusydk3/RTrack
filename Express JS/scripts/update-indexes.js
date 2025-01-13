require('dotenv').config();
const mongoose = require('mongoose');

async function updateIndexes() {
    try {
        // Connect to MongoDB
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('Connected to MongoDB');

        // Get the Resi collection
        const collection = mongoose.connection.collection('resis');

        // Drop all existing indexes except _id
        const indexes = await collection.listIndexes().toArray();
        for (const index of indexes) {
            if (index.name !== '_id_') {
                await collection.dropIndex(index.name);
                console.log(`Dropped index: ${index.name}`);
            }
        }

        // Create new compound index
        await collection.createIndex(
            { noResi: 1, userId: 1 },
            { unique: true }
        );
        console.log('Created new compound index on noResi and userId');

        console.log('Index update completed successfully');
    } catch (error) {
        console.error('Error:', error);
    } finally {
        await mongoose.disconnect();
        console.log('Disconnected from MongoDB');
    }
}

updateIndexes();
