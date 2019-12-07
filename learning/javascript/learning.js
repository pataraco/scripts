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
