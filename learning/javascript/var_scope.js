'use strict'  // forces strict type setting

var a = 10;
if (true) {
    a = 20;
    console.log(a)  // 20
}
console.log(a)      // 20

var b = 30;
if (true) {
    let b = 40;
    console.log(b)  // 40
}
console.log(b)      // 30