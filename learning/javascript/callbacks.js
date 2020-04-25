'use strict';  // forces strict type setting

// asynchronous
function async_add(a, b, callback) {
  callback(a + b);
}
function print(c) {
  console.log('async add: ' + c);
}
async_add(1, 2, print);
async_add(5, 6, function (c) {
  console.log('inline/anonomous async add: ' + c);
});
async_add(8, 9, (c) => {
  console.log('arrow/anony function async add: ' + c);
});
async_add(11, 12, (c) => console.log('one-liner anony function async add: ' + c));

function doIt(data, callback) {
  callback("done");
}
doIt(true, result => console.log(result));