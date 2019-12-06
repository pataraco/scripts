'use strict'  // forces strict type setting

function square(data) {
    return new Promise((resolve, reject) => {
        setTimeout(() => {
            if (typeof data == 'number') {
                resolve(data * data);
            } else {
                reject('error: data is not a number: ' + data)
            }
        }, 500);
    });
}

// --- promises ---
square(2).then(result => {
    console.log('square(2)[resolve] result: ' + result);
    return square(result);
}).then(result => {
    console.log('square[resolve] result: ' + result);
    return square(result);
}).then(result => {
    console.log('square[resolve] result: ' + result);
    return square('result');
}).catch(errmsg => {
    console.log('square[catch] errmsg: ' + errmsg);
});

async function chainSquare(x) {  // async functions always return a promise
    // --- return => resolve ---
    // let result = await square(x);
    // return result;

    // --- errors => reject ---
    // return await square('a'); // error: data is not a number
    // return await square(a);   // ReferenceError: a is not defined

    // --- one-liner ---
    // return await square(data);

    // --- chain --- (any errors => reject)
    console.log('in chainSquare: x=' + x);
    let a = await square(x);
    console.log('in chainSquare: a=' + a);
    let b = await square(a);
    console.log('in chainSquare: b=' + b);
    let c = await square(b);
    console.log('in chainSquare: c=' + c);
    return c;
}

var x = 2;
chainSquare(x).then(result => {
    console.log('chainSquare(x)[resolve] result: ' + result);
}).catch(errmsg => {
    console.log('chainSquare(x)[catch] errmsg: ' + errmsg);
});