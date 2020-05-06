'use strict';  // forces strict type setting

console.log('Hello World!');

var x = 'Hello';
var y = 'World!';
console.log(x + ' ' + y);

var msg = `${x} ${y}`;
console.log(msg);

console.log('Multiline\nmessage!');
console.log(`Multiline
message!`);

// See expanded object info about a function
function example() {
  console.log('Hello World!');
}
console.dir(example);

// can assign functions as values in objects
const person = {
  name: 'John',
  greet: function () {
    console.log('Hello there!');
  }
};
person.greet();

// anonymous functions
// (note: for debugging purposes, better to name them)
// as a variable/const
const greet = function () {
  console.log('Hello there!');
};
greet();

// as an argument
function someFunction(param1, param2) {
  console.log(`param1: ${param1}`);
  param2();
}
someFunction('Arg 1', function () {
  console.log('This is an example');
});

// arrow functions
const add1 = (a, b) => a + b;
const add2 = (a, b) => {
  return a + b;
};
const square = x => x * x;
console.log(add1(2, 3));
console.log(add2(4, 5));
console.log(square(6));

// default values function params
function anotherFunc(param1, param2 = 'two', param3 = param1 === 'one' ? 'three' : 'four') {
  console.log(`param1: ${param1}, param2: ${param2},  param3: ${param3}`);
}

// Boolean Coercion
let userInput;
let isValidInput;
userInput = '';
isValidInput = !!userInput;  // false
userInput = 'Foo Bar';
isValidInput = !!userInput;  // true

// Default settings or set if true
let name;
userInput = '';
name = userInput || 'No Input Given';  // 'No Input Given'
name = userInput && 'Input Given';     // ''
userInput = 'Foo Bar';
name = userInput || 'No Input Given';  // 'Foo Bar'
name = userInput && 'Input Given';     // 'Input Given'


// Ternary
isValidInput = userInput ? true : false;


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
