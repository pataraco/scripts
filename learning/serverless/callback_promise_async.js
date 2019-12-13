'use strict'

// --- Node.js 6.10 ---
// exports.handler = (event, context, callback) => {
//     // do some stuff
//     callback(null, result);
// }

// --- Node.js 8.10/10.x/12.x ---
// exports.handler = async (event, context) => {
//     // do some stuff
//     return result;
// }

exports.handler = async (event, context) => {
    const data = event.data;
    let newImage = await resizeImage();
    return newImage;
}

const resizeImage = (data) => new Promise((resolve, reject) => {
    // resize the image
    if (data) {
        resolve(result);
    } else {
        reject(error);
    }
});
