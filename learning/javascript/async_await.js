'use strict'  // forces strict type setting

// --- promises ---
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

square(8).then(
    (result) => {
        console.log('square(8)[resolve] result: ' + result); },
    (errmsg) => {
        console.log('square(8)[reject] error: ' + errmsg); }
)

square('eight').then(
    (result) => {
        console.log('square(\'eight\')[resolve] result: ' + result); },
    (errmsg) => {
        console.log('square(\'eight\')[reject] errmsg: ' + errmsg); }
)

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