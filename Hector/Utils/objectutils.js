.pragma library

function getElement(obj, path) {
  var paths = path.split('.')
  var current = obj
  for (var i = 0; i < paths.length; ++i) {
    if (current == null) return undefined
    if (current[paths[i]] == undefined) return undefined
    current = current[paths[i]]
  }
  return current
}

function isAncestor(ancestor, item) {
  var current = item
  while (current != null) {
    if (current == ancestor) return true
    current = current.parent
  }
  return false
}

function findAncestorOfType(item, type) {
  var current = item
  while (current != null) {
    if (current instanceof type) return current
    current = current.parent
  }
  return null
}

function deepEquals(a, b) {
  if (a == null || b == null) return a == b
  if (typeof a !== typeof b) return false
  if (Array.isArray(a)) {
    if (!Array.isArray(b) || a.length !== b.length) return false
    for (let i = 0; i < a.length; ++i) {
      if (typeof a[i] === "object") {
        if (!deepEquals(a[i], b[i])) return false
      } else if (a[i] !== b[i]) {
        return false
      }
    }
  }
  let props_a = Object.getOwnPropertyNames(a)
  let props_b = Object.getOwnPropertyNames(b)
  if (props_a.length != props_b.length) return false
  for (let key of props_a) {
    if (!props_b.find(val => val == key)) return false
    if (typeof a[key] === "object") {
      if (!deepEquals(a[key], b[key])) return false
    } else if (a[key] !== b[key]) {
      return false
    }
  }
  return true
}
