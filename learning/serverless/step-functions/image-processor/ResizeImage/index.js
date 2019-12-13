const im = require('imagemagick');
const fs = require('fs');
const os = require('os');
const uuidv4 = require('uuid/v4');
const {promisify} = require('util');
const AWS = require('aws-sdk');

const resizeAsync = promisify(im.resize);
const readFileAsync = promisify(fs.readFile);
const unlinkAsync = promisify(fs.unlink);

AWS.config.update({region: 'us-west-2'});
const s3 = new AWS.S3();

exports.handler = async (event) => {
    let bucket = event.s3.bucket.name;
    let key = event.s3.object.key;
    let fileName = key.substring((key.lastIndexOf('/')+1));
    let sourceKey = `images/pending/${fileName}`;
    // get file from S3
    var s3Args = {
        Bucket: bucket,
        Key: sourceKey
    }
    console.log('S3 get args:', s3Args);
    let inputData = await s3.getObject(s3Args).promise();
    // resize the file
    let tempFile = os.tmpdir() + '/' + uuidv4() + '.jpg';
    let resizeArgs = {
        srcData: inputData.Body,
        dstPath: tempFile,
        width: process.env.NEW_SIZE
    };
    await resizeAsync(resizeArgs);
    // read the resized file
    let resizedData = await readFileAsync(tempFile);
    // upload the resized file to S3
    let index = fileName.lastIndexOf('.');
    let targetKey = `images/resized/${fileName.substring(0,index)}-small.jpg`;
    var s3Args = {
        Bucket: bucket,
        Key: targetKey,
        Body: new Buffer(resizedData),
        ContentType: 'image/jpeg'
    };
    console.log('S3 put args:', s3Args);
    await s3.putObject(s3Args).promise();
    await unlinkAsync(tempFile);
    return {
        from: `${bucket}/${key}`,
        to: `${bucket}/${targetKey}`
    }
}
