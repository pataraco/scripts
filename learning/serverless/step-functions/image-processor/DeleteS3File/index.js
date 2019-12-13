const AWS = require('aws-sdk');
AWS.config.update({region: 'us-west-2'});

const s3 = new AWS.S3();

exports.handler = async (event) => {
    let bucket = event.s3.bucket.name;
    let key = event.s3.object.key;
    let params = {
        Bucket: bucket,
        Key: key
    }
    console.log(params);
    await s3.deleteObject(params).promise();
    return {
        deleted: `${bucket}/${key}`
    }
};