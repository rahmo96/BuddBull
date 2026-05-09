/**
 * Serialize a Mongoose document (or plain object) for Socket.io / JSON responses.
 */
function toPlainDoc(doc) {
  if (doc == null) return doc;
  if (typeof doc.toObject === 'function') {
    return doc.toObject({ virtuals: true });
  }
  return doc;
}

module.exports = { toPlainDoc };
