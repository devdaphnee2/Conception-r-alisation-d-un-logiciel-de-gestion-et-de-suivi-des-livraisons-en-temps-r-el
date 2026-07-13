const multer = require('multer');
const path   = require('path');
const fs     = require('fs');

const uploadDir = path.join(__dirname, '../../uploads/livreurs');
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

const storage = multer.diskStorage({
    destination: function(req, file, cb) { cb(null, uploadDir); },
    filename: function(req, file, cb) {
        cb(null, file.fieldname + '_' + Date.now() + path.extname(file.originalname));
    }
});

const upload = multer({
    storage: storage,
    limits: { fileSize: 10 * 1024 * 1024 },
    fileFilter: function(req, file, cb) {
        var allowed = ['.jpg', '.jpeg', '.png', '.pdf'];
        if (allowed.includes(path.extname(file.originalname).toLowerCase())) cb(null, true);
        else cb(new Error('Format non autorise.'));
    }
});

var uploadFields = upload.fields([
    { name: 'photoProfil',   maxCount: 1 },
    { name: 'cniRecto',      maxCount: 1 },
    { name: 'cniVerso',      maxCount: 1 },
    { name: 'permis',        maxCount: 1 },
    { name: 'photoVehicule', maxCount: 1 },
]);

function fileUrl(req, file) {
    if (!file) return null;
    var filename = file.filename || file;
    if (!filename) return null;
    var base = process.env.BACKEND_URL || ('http://' + (req.hostname || 'localhost') + ':' + (process.env.PORT || 5000));
    return base + '/uploads/livreurs/' + path.basename(filename);
}

module.exports = { upload, uploadFields, fileUrl };
