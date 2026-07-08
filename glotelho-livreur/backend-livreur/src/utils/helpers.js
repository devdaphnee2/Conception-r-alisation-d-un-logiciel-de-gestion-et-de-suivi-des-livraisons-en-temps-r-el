/**
 * Flutter/Dio envoie les disponibilités sous ce format multipart indexé :
 *   disponibilites[0][jour]       = "Lundi"
 *   disponibilites[0][heureDebut] = "08:00"
 *   disponibilites[0][heureFin]   = "18:00"
 *   disponibilites[1][jour]       = "Mardi"
 *   ...
 *
 * Cette fonction reconstruit le tableau d'objets depuis req.body.
 */
function parseDisponibilites(body) {
  const result = {};
  const regex  = /^disponibilites\[(\d+)\]\[(\w+)\]$/;

  for (const key of Object.keys(body)) {
    const match = key.match(regex);
    if (!match) continue;
    const index = parseInt(match[1], 10);
    const field = match[2];
    if (!result[index]) result[index] = {};
    result[index][field] = body[key];
  }

  return Object.values(result);
}

/**
 * Construit l'URL publique d'un fichier uploadé.
 * Retourne null si aucun fichier.
 */
function fileUrl(req, file) {
  if (!file) return null;
  return `${process.env.APP_URL}/uploads/${file.filename}`;
}

module.exports = { parseDisponibilites, fileUrl };