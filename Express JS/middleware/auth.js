const jwt = require('jsonwebtoken');

module.exports = function(req, res, next) {
    // Check both auth-token and Authorization headers
    const token = req.header('auth-token') || req.header('Authorization');
    
    if (!token) {
        return res.status(401).json({ message: 'Access denied. No token provided.' });
    }

    try {
        // Remove 'Bearer ' prefix if present
        const tokenString = token.startsWith('Bearer ') ? token.slice(7) : token;
        const decoded = jwt.verify(tokenString, process.env.JWT_SECRET);
        req.user = decoded;
        next();
    } catch (err) {
        res.status(401).json({ message: 'Invalid token' });
    }
}
