function parseDisponibilites(body) {
  // Format 1 : champ "disponibilites" = JSON string(s)
  if (body.disponibilites !== undefined) {
    const raw = body.disponibilites;
    const items = Array.isArray(raw) ? raw : [raw];
    const result = [];
    for (const item of items) {
      if (typeof item === 'string') {
        try {
          const parsed = JSON.parse(item);
          if (parsed && typeof parsed === 'object') result.push(parsed);
        } catch (_) {}
      } else if (typeof item === 'object') {
        result.push(item);
      }
    }
    if (result.length > 0) return result;
  }

  // Format 2 : champs indexés disponibilites[0][jour]
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

function fileUrl(req, file) {
  if (!file) return null;
  return `${process.env.APP_URL}/uploads/${file.filename}`;
}

module.exports = { parseDisponibilites, fileUrl };