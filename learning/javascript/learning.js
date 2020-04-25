'use strict'  // forces strict type setting

console.log('Hello World!');

var x = 'Hello';
var y = 'World!';
console.log(x + ' ' + y);

var msg = `${x} ${y}`;
console.log(msg);

console.log('Multiline\nmessage!');
console.log(`Multiline
message!`);

// Boolean Coercion
let userInput = '';
const isValidInput = !!userInput;  // false
let userInput = 'Foo Bar';
const isValidInput = !!userInput;  // true

// Default settings or set if true
let userInput = '';
name = userInput || 'No Input Given';  // 'No Input Given'
name = userInput && 'Input Given';     // ''
let userInput = 'Foo Bar';
name = userInput || 'No Input Given';  // 'Foo Bar'
name = userInput && 'Input Given';     // 'Input Given'


// Ternary
let isValidInput = userInput ? true : false


var z;
console.log(z);  // undefined

var a = 'String';
console.log(a);  // value/type can be changed dynamically
a = 10;
console.log(a);
a = true;
console.log(a);  // set to last value

const b = 'constant value';
// b = 'different value';  // TypeError: Assignment to contanct variable

var c = 'Foo';
var d = 'Bar!';
console.log("c = '" + c + "' and d = '" + d + "'");
console.log('c (length): ' + c.length + ' and d (length): ' + d.length);
console.log("c + d: '" + c + " " + d + "'");
