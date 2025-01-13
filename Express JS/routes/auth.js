const router = require('express').Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const User = require('../models/User');
const auth = require('../middleware/auth');
const Resi = require('../models/Resi'); // Assuming Resi model is defined in this file

// Debug middleware to log all requests
router.use((req, res, next) => {
    next();
});

// Configure multer for image upload
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        const uploadDir = 'uploads/';
        if (!fs.existsSync(uploadDir)) {
            fs.mkdirSync(uploadDir, { recursive: true });
        }
        cb(null, uploadDir);
    },
    filename: function (req, file, cb) {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, uniqueSuffix + path.extname(file.originalname));
    }
});

const upload = multer({
    storage: storage,
    limits: {
        fileSize: 5 * 1024 * 1024 // 5MB limit
    },
    fileFilter: function (req, file, cb) {
        const filetypes = /jpeg|jpg|png/;
        const mimetype = filetypes.test(file.mimetype);
        const extname = filetypes.test(path.extname(file.originalname).toLowerCase());

        if (mimetype && extname) {
            return cb(null, true);
        }
        cb(new Error('Only .png, .jpg and .jpeg format allowed!'));
    }
});

// Register
router.post('/register', async (req, res) => {
    try {
        console.log('Register attempt:', { ...req.body, password: '[HIDDEN]' }); // Debug log

        // Check if user already exists
        const emailExists = await User.findOne({ email: req.body.email });
        if (emailExists) return res.status(400).json({ message: 'Email already exists' });

        const usernameExists = await User.findOne({ username: req.body.username });
        if (usernameExists) return res.status(400).json({ message: 'Username already exists' });

        // Hash the password
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(req.body.password, salt);

        // Create new user
        const user = new User({
            name: req.body.name,
            email: req.body.email,
            username: req.body.username,
            password: hashedPassword
        });

        const savedUser = await user.save();
        
        // Create token for the new user
        const token = jwt.sign({ _id: savedUser._id }, process.env.JWT_SECRET);

        // Log successful registration
        console.log('User registered successfully:', savedUser.username);

        res.status(201).json({
            token: token,
            user: {
                _id: savedUser._id,
                userID: savedUser.userID,
                name: savedUser.name,
                email: savedUser.email,
                username: savedUser.username,
                profileImage: savedUser.profileImage
            }
        });
    } catch (err) {
        console.error('Register error:', err); // Debug log
        res.status(400).json({ message: err.message });
    }
});

// Login
router.post('/login', async (req, res) => {
    try {
        console.log('Login attempt with body:', { ...req.body, password: '[HIDDEN]' }); // Debug log

        const { identifier, password } = req.body;
        
        // Check if user exists by username or email
        const user = await User.findOne({
            $or: [
                { username: identifier },
                { email: identifier }
            ]
        });
        
        console.log('Found user:', user ? 'Yes' : 'No'); // Debug log

        if (!user) {
            console.log('User not found:', identifier);
            return res.status(400).json({ message: 'Invalid email/username or password' });
        }

        // Check password
        const validPassword = await bcrypt.compare(password, user.password);
        console.log('Password valid:', validPassword); // Debug log

        if (!validPassword) {
            console.log('Invalid password for user:', identifier);
            return res.status(400).json({ message: 'Invalid email/username or password' });
        }

        // Create and assign token
        const token = jwt.sign({ _id: user._id }, process.env.JWT_SECRET);

        // Log successful login
        console.log('User logged in successfully:', user.username);

        // Send response
        res.status(200).json({
            token: token,
            user: {
                _id: user._id,
                userID: user.userID,
                name: user.name,
                email: user.email,
                username: user.username,
                profileImage: user.profileImage
            }
        });
    } catch (err) {
        console.error('Login error:', err); // Debug log
        res.status(400).json({ message: err.message });
    }
});

// Get user profile
router.get('/profile', auth, async (req, res) => {
    try {
        console.log('Getting profile for user ID:', req.user._id); // Debug log
        
        const user = await User.findById(req.user._id).select('-password');
        
        if (!user) {
            console.log('User not found for ID:', req.user._id);
            return res.status(404).json({ message: 'User not found' });
        }

        console.log('Found user:', user); // Debug log

        res.json({
            _id: user._id,
            name: user.name,
            email: user.email,
            username: user.username,
            userID: user.userID,
            profileImage: user.profileImage
        });
    } catch (error) {
        console.error('Profile fetch error:', error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Upload profile image
router.post('/profile/image', auth, upload.single('image'), async (req, res) => {
    try {
        console.log('Request received for profile image upload');
        console.log('Request file:', req.file);
        console.log('Request body:', req.body);

        if (!req.file) {
            console.log('No file received');
            return res.status(400).json({ message: 'No image file provided' });
        }

        const user = await User.findById(req.user._id);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Delete old profile image if exists
        if (user.profileImage) {
            const oldImagePath = path.join(__dirname, '..', 'uploads', path.basename(user.profileImage));
            console.log('Attempting to delete old image at:', oldImagePath);
            if (fs.existsSync(oldImagePath)) {
                fs.unlinkSync(oldImagePath);
                console.log('Old image deleted successfully');
            }
        }

        // Update user profile with new image
        const imageUrl = `/uploads/${req.file.filename}`;
        console.log('New image URL:', imageUrl);
        
        user.profileImage = imageUrl;
        await user.save();
        console.log('User profile updated with new image');

        // Return full user data
        res.json({
            userId: user._id,
            username: user.username,
            userID: user.userID,
            profileImage: imageUrl,
            message: 'Profile image updated successfully'
        });
    } catch (error) {
        console.error('Error in profile image upload:', error);
        res.status(500).json({ message: error.message });
    }
});

// Update user profile
router.put('/me', auth, async (req, res) => {
    try {
        console.log('Profile update request:', req.body); // Debug log

        const { name, email, username } = req.body;

        // Check if username is taken (if username is being changed)
        if (username) {
            const existingUser = await User.findOne({ 
                username, 
                _id: { $ne: req.user._id } 
            });
            if (existingUser) {
                return res.status(400).json({ message: 'Username already taken' });
            }
        }

        // Check if email is taken (if email is being changed)
        if (email) {
            const existingUser = await User.findOne({ 
                email, 
                _id: { $ne: req.user._id } 
            });
            if (existingUser) {
                return res.status(400).json({ message: 'Email already taken' });
            }
        }

        const updatedUser = await User.findByIdAndUpdate(
            req.user._id,
            { 
                name: name || undefined,
                email: email || undefined,
                username: username || undefined
            },
            { new: true, runValidators: true }
        ).select('-password');

        if (!updatedUser) {
            return res.status(404).json({ message: 'User not found' });
        }

        console.log('Profile updated successfully:', updatedUser); // Debug log

        res.json({
            user: {
                _id: updatedUser._id,
                userID: updatedUser.userID,
                name: updatedUser.name,
                email: updatedUser.email,
                username: updatedUser.username,
                profileImage: updatedUser.profileImage
            }
        });
    } catch (error) {
        console.error('Profile update error:', error); // Debug log
        res.status(500).json({ message: error.message });
    }
});

// Change password
router.put('/change-password', auth, async (req, res) => {
    try {
        const { currentPassword, newPassword } = req.body;
        
        // Get user from database
        const user = await User.findById(req.user._id);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Verify current password
        const validPassword = await bcrypt.compare(currentPassword, user.password);
        if (!validPassword) {
            return res.status(400).json({ message: 'Current password is incorrect' });
        }

        // Hash new password
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(newPassword, salt);

        // Update password
        user.password = hashedPassword;
        await user.save();

        res.json({ message: 'Password updated successfully' });
    } catch (error) {
        console.error('Change password error:', error);
        res.status(500).json({ message: error.message });
    }
});

// Delete account
router.delete('/me', auth, async (req, res) => {
    try {
        // Get user from database
        const user = await User.findById(req.user._id);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Delete user's profile image if exists
        if (user.profileImage) {
            const imagePath = path.join(__dirname, '..', user.profileImage);
            if (fs.existsSync(imagePath)) {
                fs.unlinkSync(imagePath);
            }
        }

        // Delete all user's resis
        await Resi.deleteMany({ userId: user._id });

        // Delete user
        await User.findByIdAndDelete(req.user._id);

        res.status(200).json({ message: 'Account deleted successfully' });
    } catch (error) {
        console.error('Delete account error:', error);
        res.status(500).json({ message: 'Error deleting account' });
    }
});

module.exports = router;
