.pragma library

//! Inserts value into the sorted array array.
//! compareFn has to return true if a should be before b and false otherwise.
function insertSorted(array, value, compareFn=(a, b) => a < b) {
  // Could be made more efficient with binary search
  for (let i = 0; i < array.length; ++i) {
    if (compareFn(array[i], value)) continue
    array.splice(i, 0, value)
    return
  }
  array.push(value)
}
