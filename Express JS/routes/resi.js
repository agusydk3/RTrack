const router = require('express').Router();
const Resi = require('../models/Resi');
const jwt = require('jsonwebtoken');

// Middleware to verify token
const verifyToken = (req, res, next) => {
    const token = req.header('auth-token');
    if (!token) return res.status(401).json({ message: 'Access denied' });

    try {
        const verified = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key');
        req.user = verified;
        next();
    } catch (error) {
        res.status(400).json({ message: 'Invalid token' });
    }
};

// Create new receipt
router.post('/', verifyToken, async (req, res) => {
    try {
        const resi = new Resi({
            noResi: req.body.noResi,
            title: req.body.title,
            courier: req.body.courier,
            userId: req.user._id
        });

        const savedResi = await resi.save();
        res.status(201).json(savedResi);
    } catch (error) {
        // Handle duplicate key error
        if (error.code === 11000) {
            return res.status(400).json({ 
                message: 'Nomor resi ini sudah ada dalam daftar Anda' 
            });
        }
        res.status(500).json({ message: error.message });
    }
});

// Get all receipts for logged in user
router.get('/', verifyToken, async (req, res) => {
    try {
        const resis = await Resi.find({ userId: req.user._id })
            .sort({ createdAt: -1 }); // Sort by newest first
        res.json(resis);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Get specific receipt
router.get('/:id', verifyToken, async (req, res) => {
    try {
        const resi = await Resi.findOne({
            _id: req.params.id,
            userId: req.user._id
        });
        
        if (!resi) {
            return res.status(404).json({ message: 'Receipt not found' });
        }
        
        res.json(resi);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Update receipt
router.put('/:id', verifyToken, async (req, res) => {
    try {
        const resi = await Resi.findOneAndUpdate(
            {
                _id: req.params.id,
                userId: req.user._id
            },
            {
                noResi: req.body.noResi,
                title: req.body.title,
                courier: req.body.courier
            },
            { new: true }
        );

        if (!resi) {
            return res.status(404).json({ message: 'Receipt not found' });
        }

        res.json(resi);
    } catch (error) {
        // Handle duplicate key error
        if (error.code === 11000) {
            return res.status(400).json({ 
                message: 'Nomor resi ini sudah ada dalam daftar Anda' 
            });
        }
        res.status(500).json({ message: error.message });
    }
});

// Delete receipt
router.delete('/:id', verifyToken, async (req, res) => {
    try {
        const resi = await Resi.findOneAndDelete({
            _id: req.params.id,
            userId: req.user._id
        });

        if (!resi) {
            return res.status(404).json({ message: 'Receipt not found' });
        }

        res.json({ message: 'Receipt deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

module.exports = router;
