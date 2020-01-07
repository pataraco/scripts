const AWS = require('aws-sdk');
AWS.config.update({region: 'us-west-2'});

const documentClient = new AWS.DynamoDB.DocumentClient();

const processImageMetadata = async (images) => {
    // console.log('images:', images);
    let orig, thumb;
    let filesProcessed = images.map(async (image) => {
        for (let key in image) {
            // console.log('key:', key);
            switch (key) {
                case 'copyToDest':
                    orig = image.copyToDest.from;
                    break;
                case 'resize':
                    thumb = image.resize.to;
                    break;
                default:
            }
        }
    });
    await Promise.all(filesProcessed);
    
    return {
        orig: orig,
        thumb: thumb
    }
}    
    
exports.handler = async (event) => {
    // console.log('event:', event);
    let images = await processImageMetadata(event.results.images);
    // console.log('images:', images);
    var params = {
        Item: {
            orig: images.orig,
            thumb: images.thumb,
            timestamp: new Date().getTime()
        },
        TableName: process.env.DB_TABLE
    };
    // console.log('params:', params);
    await documentClient.put(params).promise();
    return true;
};
