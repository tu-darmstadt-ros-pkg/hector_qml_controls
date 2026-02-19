.pragma library

// Sanitize the input to be a valid ROS topic part by replacing all non-valid namespace characters with '_' and ensuring it starts with a letter.
function sanitizeTopic(name) {
  if (!name) return ""
  let sanitized = name.replace(/[^a-zA-Z0-9_]/g, "_")
  if (sanitized.length > 0 && !sanitized[0].match(/[a-zA-Z]/)) {
      sanitized = "ns" + sanitized
  }
  return sanitized
}
