'use strict'  // forces strict type setting

function doIt(data) {
    return new Promise((resolve, reject) => {
        let successMsg = {
            status: 'pass',
            message: 'was able to do it'
        };
        let errorMsg = {
            status: 'fail',
            message: 'was NOT able to do it'
        };
        if (data == true) { 
            resolve(successMsg);
        } else {
            reject(errorMsg);
        };
    });
}

doIt(true).then(
    (msg) => { console.log('doIt(true)[resolve]'); console.log(msg); },
    (msg) => { console.log('doIt(true)[reject]'); console.log(msg); }
);

doIt(false).then(
    (msg) => { console.log('doIt(false)[resolve]'); console.log(msg); },
    (msg) => { console.log('doIt(false)[reject]'); console.log(msg); }
);

// --- chaining promises ---

doIt(true).then(
    (msg) => {
        console.log('1st: doIt(true)[resolve]');
        console.log(msg);
        return doIt(false);
    },
    (msg) => {
        console.log('1st: doIt(true)[reject]');
        console.log(msg);
        return doIt(false);
    }
).then(
    (msg) => {
        console.log('2nd: doIt(false)[resolve]');
        console.log(msg);
    },
    (msg) => {
        console.log('2nd: doIt(false)[reject]');
        console.log(msg);
    }
);

function getRandomInt(max) {
    return Math.floor(Math.random() * Math.floor(max));
}

var promise1 = new Promise(function(resolve, reject) {
    setTimeout(function() {
        resolve("resolved");
    }, 250);
});

promise1.then(
    function(value) {
        console.log('promise1: ' + value);
    }
);

var promise2 = new Promise(function(resolve, reject) {
    const a = 10;
    const b = 10;
    if (a === b) {
        resolve(true);
    } else {
        reject(false);
    }
});

promise2.then(
    function(result) { // on resolve()
        console.log('promise2: success: ' + result);
    },
    function(result) { // on reject()
        console.log('promise2: failure: ' + result);
    }
);

promise2
    .then( // on resolve()
        (result) => {
            console.log('promise2: resolve: ' + result);
        }
    )
    .catch( // on reject()
        (error) => {
            console.log('promise2: catch: ' + error);
        }
    )
    .finally( // always ran
        console.log('promise2: finally')
    )

var promiseA = new Promise(function(resolve, reject) {
    let timeout = getRandomInt(500);
    setTimeout(resolve, timeout, 'promiseA=' + timeout);
});

var promiseB = new Promise(function(resolve, reject) {
    let timeout = getRandomInt(500);
    setTimeout(resolve, timeout, 'promiseB=' + timeout);
});

var promiseC = new Promise(function(resolve, reject) {
    let timeout = getRandomInt(500);
    setTimeout(resolve, timeout, 'promiseC=' + timeout);
});

Promise.race([promiseA, promiseB, promiseC]) // it's a race!
    .then((val) => { console.log(val); }
)

Promise.all([promiseA, promiseB, promiseC]) // all are resolved...
    .then((val) => { console.log(val); }
)

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