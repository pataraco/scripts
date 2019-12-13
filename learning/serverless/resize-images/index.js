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
    let filesProcessed = event.Records.map(async (record) => {
        let bucket = record.s3.bucket.name;
        let key = record.s3.object.key;

        // get file from S3
        var s3Args = {
            Bucket: bucket,
            Key: key
        }
        // a) s3.getObject(s3Args);                  // without a callback
        // b) s3.getObject(s3Args, (err, data) => {  // with a callback
        //        ...
        //    });
        // c) s3.getObject(s3Args).promise().then()        // promise
        // d) await s3.getObject(s3Args).promise().then()  // async/await
        let inputData = await s3.getObject(s3Args).promise();

        // resize the file
        let tempFile = os.tmpdir() + '/' + uuidv4() + '.jpg';
        let resizeArgs = {
            srcData: inputData.Body,
            dstPath: tempFile,
            width: 150
        };
        await resizeAsync(resizeArgs);

        // read the resized file
        let resizedData = await readFileAsync(tempFile);

        // upload the resized file to S3
        let targetKey = `images/resized/${key.substring(
            (key.lastIndexOf('/')+1), key.lastIndexOf('.'))}-small.jpg`;
        var s3Args = {
            Bucket: bucket,
            Key: targetKey,
            Body: new Buffer(resizedData),
            ContentType: 'image/jpeg'
        }
        await s3.putObject(s3Args).promise();
        return await unlinkAsync(tempFile);
    });

    await Promise.all(filesProcessed);
    var processedMsg = `done (files processed: ${filesProcessed.length})`;
    console.log(processedMsg);
    return processedMsg;
}
