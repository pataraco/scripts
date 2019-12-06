'use strict'  // forces strict type setting

var emp = {};
emp.first = 'Patrick';
emp.last = 'Raco';
emp.age = 35;
console.log(emp);
console.log('emp.first: ' + emp.first);

var emp2 = {
    first: 'John',
    last: 'Doe',
    age: 40
};
console.log(emp2);
console.log('emp2.age: ' + emp2.age);

var l1 = [10, 20, 30];
var l2 = [10, 'String', true, 40];
console.log('l1: ' + l1 + ' length: ' + l1.length);
console.log('l2: ' + l2 + ' length: ' + l2.length);
console.log('l1[0]: ' + l1[0]);
console.log("setting l2[3] -> '50'");
l2[3] = 50;
console.log('l2: ' + l2 + ' length: ' + l2.length);
console.log("pushing 'false' on to l2");
l2.push(false);
console.log('l2: ' + l2 + ' length: ' + l2.length);
console.log("pushing '40', '50' and '60' on to l1");
l1.push(40, 50, 60);
console.log('l1: ' + l1 + ' length: ' + l1.length);
var v = l1.pop();
console.log('popped value from l1: ' + v);
console.log('l1: ' + l1 + ' length: ' + l1.length);