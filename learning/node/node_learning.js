"use strict"  // forces strict type setting

// console.log("Hello World!");
// console.log('Hello World!');

// var x = "Hello ";
// var y = "World!";
// console.log(x + y);

// console.log('Multiline\nmessage!');
// console.log(`Multiline
// message!`);

// var z;
// console.log(z);  // undefined

// var a = "String";
// console.log(a);  // value/type can be changed dynamically
// a = 10;
// console.log(a);
// a = true;
// console.log(a);  // set to last value

// const b = 'constant value';
// b = 'different value';  // TypeError: Assignment to contanct variable

// var c = "Foo";
// var d = "Bar!";
// console.log("c = '" + c + "' and d = '" + d + "'");
// console.log("c (length): " + c.length + " and d (length): " + d.length);
// console.log("c + d: '" + c + " " + d + "'");

// --- simple types ---
// var a = 10;
// var b = 20;
// // c = 5;                 // ReferenceError (with "use strict")
// var c = 5;
// console.log("a = '" + a + "' b = '" + b + "'" + "' c = '" + c + "'");
// console.log("a + b: " + (a + b));             // 30
// console.log("a - b: " + (a - b));             // -10
// console.log("a * b: " + (a * b));             // 200
// console.log("a / b: " + (a / b));             // 0.5
// console.log("a % b: " + (a % b));             // 10
// console.log("a + b * c: " + (a + b * c));     // 110
// console.log("(a + b) * c: " + ((a + b) * c)); // 150
// console.log("a < b: " + (a < b));             // true
// console.log("a > b: " + (a > b));             // false

// var p = true;
// var q = false;
// console.log("p: " + p);
// console.log("q: " + q);
// console.log("p || q: " + (p || q));   // true
// console.log("p && q: " + (p && q));   // false
// console.log("q || q: " + (q || q));   // false
// console.log("p && p: " + (p && p));   // true
// console.log("!p: " + !p);             // false
// q = undefined;
// console.log("q: " + q);

// --- complex types ---
// var emp = {};
// emp.first = "Patrick";
// emp.last = "Raco";
// emp.age = 35;
// console.log(emp);
// console.log("emp.first: " + emp.first);

// var emp2 = {
//     first: "John",
//     last: "Doe",
//     age: 40
// };
// console.log(emp2);
// console.log("emp2.age: " + emp2.age);

// var l1 = [10, 20, 30];
// var l2 = [10, "String", true, 40];
// console.log("l1: " + l1 + " length: " + l1.length);
// console.log("l2: " + l2 + " length: " + l2.length);
// console.log("l1[0]: " + l1[0]);
// console.log("setting l2[3] -> '50'");
// l2[3] = 50;
// console.log("l2: " + l2 + " length: " + l2.length);
// console.log("pushing 'false' on to l2");
// l2.push(false);
// console.log("l2: " + l2 + " length: " + l2.length);
// console.log("pushing '40', '50' and '60' on to l1");
// l1.push(40, 50, 60);
// console.log("l1: " + l1 + " length: " + l1.length);
// var v = l1.pop();
// console.log("popped value from l1: " + v);
// console.log("l1: " + l1 + " length: " + l1.length);

// --- conditionals ---
// var a = 20;
// var b = 10;
// if(a < b) {
//     console.log("a is less than b");
// } else if(a > b) {
//     console.log("a is greater than b");
// } else {
//     console.log("a is equal to b");
// }

// var i = 1;
// var limit = 10;
// while(i <= limit) {
//     console.log("i: " + i + " limit: " + limit);
//     i++;
//     limit = limit - 2;
// }

// --- loops ---
// var i = 0;
// var limit = 10;
// do {
//     console.log("i: " + i + " limit: " + limit);
//     i++;
//     limit = limit - 2;
// } while(i <= limit);

// var limit = 10;
// for(i=0; i <= limit; i++) {
//     console.log("i: " + i + " limit: " + limit);
//     limit = limit - 2;
// }

// var list = [10, 20, 30];
// list.forEach(function(item) {
//     console.log("item: " + item);
// })

// var list = [10, 20, 30];
// for(var item of list) {
//     console.log("item: " + item);
// }

// --- functions ---
// synchronous
// function sync_add(a, b) {
//     return(a + b);
// }
// console.log("sync add(10, 20): " + sync_add(10, 20));

// asynchronous
// function async_add(a, b, callback) {
//     callback(a + b);
// }
// function print(c) {
//     console.log("async add: " + c);
// }
// async_add(1, 2, print);
// async_add(5, 6, function(c) {
//     console.log("inline/anonomous async add: " + c);
// });
// async_add(8, 9, (c) => {
//     console.log("arrow/anony function async add: " + c);
// });
// async_add(11, 12, (c) => console.log("one-liner anony function async add: " + c));

// --- variable scope ---
var a = 10;
if(true) {
    var a = 20;
    console.log(a)  // 20
}
console.log(a)      // 20

var b = 10;
if(true) {
    let b = 20;
    console.log(b)  // 20
}
console.log(b)      // 10