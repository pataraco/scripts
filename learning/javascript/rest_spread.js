'use strict'  // forces strict type setting

function square(x) {
    return new Promise((resolve, reject) => {
        setTimeout(() => {
            if (typeof x == 'number') {
                resolve(x * x);
            } else {
                reject('error: data is not a number: ' + data)
            }
        }, 500);
    });
}

function add(a, b) {
    console.log('add(); adding a:', a, 'and b:', b);
    return a + b;
}

function add_many(...a) {  // rest parameter: converts arguments into a list
    console.log('add_many(); adding a:', a);
    let sum = 0;
    a.forEach(num => sum += num);
    return sum;
}

function add_one_and_many(a, ...b) {
    console.log('add_one_and_many(); adding a:', a, 'and b:', b);
    let sum = a;
    b.forEach(num => sum += num);
    return sum;
}

console.log(add(7, 8));
console.log(add_many(1, 2, 3, 4, 5));
console.log(add_one_and_many(1, 2, 3, 4, 5));
let nums = [1, 2, 3, 4, 5];
console.log(add_many(...nums));  // spread operator: converts a list into individual arguments

let array0 = [1, 2, 3];
let array1 = array0;
let array2 = [...array0];
let array3 = [0, ...array0, 10];
console.log('array0:', array0, 'spread =>', ...array0);
console.log('array1:', array1, 'spread =>', ...array1);
console.log('array2:', array2, 'spread =>', ...array2);
console.log('array3:', array3, 'spread =>', ...array3);
