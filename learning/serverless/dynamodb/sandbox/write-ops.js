const AWS = require('aws-sdk');
AWS.config.update({region: 'us-west-2'});

const documentClient = new AWS.DynamoDB.DocumentClient();

// var params = {
//     Item: {
//         user_id: '1',
//         timestamp: 1,
//         title: 'my title',
//         content: 'my content'
//     },
//     TableName: 'raco_test_notes'
// };
// documentClient.put(params, (err, data) => {
//     if (err) {
//         console.log(err);
//     } else {
//         console.log(data);
//     }
// });

var params = {
    Item: {
        user_id: '2',
        timestamp: 2,
        title: 'another title',
        content: 'another content'
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
    ExpressionAttributeNames: {
        '#t': 'title'
    },
    ExpressionAttributeValues: {
        ':t': 'Updated title'
    },
    Key: {
        user_id: '1',
        timestamp: 1,
    },
    TableName: 'raco_test_notes',
    UpdateExpression: 'set #t = :t'
};
documentClient.update(params, (err, data) => {
    if (err) {
        console.log(err);
    } else {
        console.log(data);
    }
});

// var params = {
//     Item: {
//         user_id: '2',
//         timestamp: 3,
//         title: 'third title',
//         content: 'third content'
//     },
//     TableName: 'raco_test_notes'
// };
// documentClient.put(params, (err, data) => {
//     if (err) {
//         console.log(err);
//     } else {
//         console.log(data);
//     }
// });
// var params = {
//     Key: {
//         user_id: '2',
//         timestamp: 3,
//     },
//     TableName: 'raco_test_notes'
// };
// documentClient.delete(params, (err, data) => {
//     if (err) {
//         console.log(err);
//     } else {
//         console.log(data);
//     }
// });

// var params = {
//     Item: {
//         user_id: '2',
//         timestamp: 10,
//         title: 'extra title (to be deleted)',
//         content: 'extra content (to be deleted)'
//     },
//     TableName: 'raco_test_notes'
// };
// documentClient.put(params, (err, data) => {
//     if (err) {
//         console.log(err);
//     } else {
//         console.log(data);
//     }
// });

var params = {
    RequestItems: {
        'raco_test_notes': [
            {
                DeleteRequest: {
                    Key: {
                        user_id: '2',
                        timestamp: 10
                    }
                }
            },
            {
                PutRequest: {
                    Item: {
                        user_id: '2',
                        timestamp: 4,
                        title: 'fourth title',
                        content: 'fourth content'
                    }
                }
            },
            {
                PutRequest: {
                    Item: {
                        user_id: '3',
                        timestamp: 5,
                        title: 'first title',
                        content: 'first content'
                    }
                }
            }
        ]
    }
}
documentClient.batchWrite(params, (err, data) => {
    if (err) {
        console.log(err);
    } else {
        console.log(data);
    }
});