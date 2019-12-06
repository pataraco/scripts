'use strict'  // forces strict type setting

var a = 10;
var b = 20;
// c = 5;                 // ReferenceError (with 'use strict')
var c = 5;
console.log("a = '" + a + "' b = '" + b + "' c = '" + c + "'");
console.log('a + b: ' + (a + b));             // 30
console.log('a - b: ' + (a - b));             // -10
console.log('a * b: ' + (a * b));             // 200
console.log('a / b: ' + (a / b));             // 0.5
console.log('a % b: ' + (a % b));             // 10
console.log('a + b * c: ' + (a + b * c));     // 110
console.log('(a + b) * c: ' + ((a + b) * c)); // 150
console.log('a < b: ' + (a < b));             // true
console.log('a > b: ' + (a > b));             // false

var p = true;
var q = false;
console.log('p: ' + p);
console.log('q: ' + q);
console.log('p || q: ' + (p || q));   // true
console.log('p && q: ' + (p && q));   // false
console.log('q || q: ' + (q || q));   // false
console.log('p && p: ' + (p && p));   // true
console.log('!p: ' + !p);             // false
q = undefined;
console.log('q: ' + q);