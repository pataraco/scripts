const AWS = require('aws-sdk');
AWS.config.update({region: 'us-west-2'});

const documentClient = new AWS.DynamoDB.DocumentClient();

var params = {
    ConditionExpression: '#t <> :t',
    ExpressionAttributeNames: {
        '#t': 'timestamp'
    },
    ExpressionAttributeValues: {
        ':t': 1
    },
    Item: {
        user_id: '10',
        timestamp: 1,
        title: 'New Title',
        content: 'Initial Content'
    },
    TableName: 'raco_test_notes',
};
documentClient.put(params, (err, data) => {
    if (err) {
        console.log(err);
    } else {
        console.log(data);
    }
});