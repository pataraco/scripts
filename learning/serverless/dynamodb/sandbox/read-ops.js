const AWS = require('aws-sdk');
AWS.config.update({region: 'us-west-2'});

const documentClient = new AWS.DynamoDB.DocumentClient();

var params = {
    Item: {
        user_id: '10',
        timestamp: 2,
        cat: 'general',
        content: 'more content',
        title: 'additional title',
        username: 'raco'
    },
    TableName: 'raco_test_notes'
};
documentClient.put(params, (err, data) => {
    if (err) {
        console.log(err);
    } else {
        console.log(data);
    }
});

var params = {
    Key: {
        user_id: '10',
        timestamp: 2,
    },
    TableName: 'raco_test_notes'
};
documentClient.get(params, (err, data) => {
    if (err) {
        console.log(err);
    } else {
        console.log(data);
    }
});

var params = {
    TableName: 'raco_test_notes',
    KeyConditionExpression: 'user_id = :uid',
    ExpressionAttributeValues: {
        ':uid': '2'
    }
};
documentClient.query(params, (err, data) => {
    if (err) {
        console.log(err);
    } else {
        console.log(data);
    }
});

documentClient.scan({TableName: 'raco_test_notes'}, (err, data) => {
    if (err) {
        console.log(err);
    } else {
        console.log(data);
    }
});

var params = {
    TableName: 'raco_test_notes',
    FilterExpression: 'cat = :cat',
    ExpressionAttributeValues: {
        ':cat': 'general'
    }
};
documentClient.scan(params, (err, data) => {
    if (err) {
        console.log(err);
    } else {
        console.log(data);
    }
});