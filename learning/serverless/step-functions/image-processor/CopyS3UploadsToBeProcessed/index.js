const AWS = require('aws-sdk');
AWS.config.update({region: 'us-west-2'});

const s3 = new AWS.S3();

exports.handler = async (event) => {
    let bucket = event.s3.bucket.name;
    let key = event.s3.object.key;
    let index = key.lastIndexOf('/');
    let fileName = key.substring(index+1);
    let copySource = encodeURI('/' + bucket + '/' + key);
    let destBuckt = process.env.S3_DEST_BUCKET;
    let destKey = 'images/pending/' + fileName;
    let params = {
        Bucket: destBuckt,
        CopySource: copySource,
        Key: destKey
    }
    await s3.copyObject(params).promise();
    return {
        from: `${bucket}/${key}`,
        to: `${destBuckt}/${destKey}`
    }
};
