'use strict'  // forces strict type setting

var a = 20;
var b = 10;
if (a < b) {
    console.log('a is less than b');
} else if (a > b) {
    console.log('a is greater than b');
} else {
    console.log('a is equal to b');
}

var a = 10;
var b = true;
var c = '10';
var f = (c) => c;
var s = 'true';
console.log("a='" + a + "' type:" + typeof(a));
console.log("b='" + b + "' type:" + typeof(b));
console.log("c='" + c + "' type:" + typeof(c));
console.log("f='" + f + "' type:" + typeof(f));
console.log("s='" + s + "' type:" + typeof(s));
if (a === 10) console.log('a === 10');
if (a == 10) console.log('a == 10');
if (b === true) console.log('b === true');
if (b == true) console.log('b == true');
if (a === c) {console.log('a === c')} else {console.log('a !=== c')};
if (a == c) console.log('a == c');
if (f(true) === true) console.log('f(true) === true');
if (f('true') === true) {console.log('f("true") === true')} else {console.log('f("true") !=== true')};
if (f('true') === 'true') console.log('f("true") === "true"');
if (b === "true") {console.log('b === "true"')} else {console.log('b !=== "true"')};
if (b == "true") {console.log('b == "true"')} else {console.log('b !== "true"')};
if (s === 'true') console.log('s === "true"');
if (s == 'true') console.log('s == "true"');
if (b === s) {console.log('b === s')} else {console.log('b !=== s')};
if (b == s) {console.log('b == s')} else {console.log('b !== s')};