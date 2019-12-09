'use strict'  // forces strict type setting

var i = 1;
var limit = 10;
while (i <= limit) {
    console.log('i: ' + i + ' limit: ' + limit);
    i++;
    limit = limit - 2;
}

var i = 0;
var limit = 10;
do {
    console.log('i: ' + i + ' limit: ' + limit);
    i++;
    limit = limit - 2;
} while (i <= limit);

var limit = 10;
for (i=0; i <= limit; i++) {
    console.log('i: ' + i + ' limit: ' + limit);
    limit = limit - 2;
}

var list = [10, 20, 30];
list.forEach(function(item) {
    console.log('item: ' + item);
})

var list = [10, 20, 30];
for (var item of list) {
    console.log('item: ' + item);
}
