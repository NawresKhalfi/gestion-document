// middleware/adminMiddleware.js
module.exports = function(req, res, next) {
  if (req.user && req.user.role === 'admin') {
    next();
  } else {
    res.status(403).send('Accès réservé à l\'administrateur');
  }
};