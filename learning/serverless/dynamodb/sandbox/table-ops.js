const AWS = require('aws-sdk');
AWS.config.update({region: 'us-west-2'});

const dynamodb = new AWS.DynamoDB();

dynamodb.listTables({}, (err, data) => {
    if (err) {
        // console.log(err, err.stack);
        console.log(err);
    } else {
        console.log(data);
    }
});

// dynamodb.describeTable({TableName: 'par_test_notes'}, (err, data) => {
//     if (err) {
//         console.log(err);
//     } else {
//         console.log(JSON.stringify(data, null, 2));
//     }
// });

var params = {
    AttributeDefinitions: [
        {
            AttributeName: 'timestamp',
            AttributeType: 'N'
        },
        {
            AttributeName: 'user_id',
            AttributeType: 'S'
        }
    ],
    KeySchema: [
        {
            AttributeName: 'user_id',
            KeyType: 'HASH'
        },
        {
            AttributeName: 'timestamp',
            KeyType: 'RANGE'
        }
    ],
    ProvisionedThroughput: {
        ReadCapacityUnits: 1,
        WriteCapacityUnits: 1
    },
    TableName: 'raco_test_notes'
};

dynamodb.createTable(params, (err, data) => {
    if (err) {
        console.log(err);
    } else {
        console.log(JSON.stringify(data, null, 2));
    }
});

var params = {
    ProvisionedThroughput: {
        ReadCapacityUnits: 2,
        WriteCapacityUnits: 1
    },
    TableName: 'raco_test_notes'
};
// dynamodb.updateTable(params, (err, data) => {
//     if (err) {
//         console.log(err);
//     } else {
//         console.log(JSON.stringify(data, null, 2));
//     }
// });

var params = {TableName: 'raco_test_notes'};
dynamodb.describeTable(params, (err, data) => {
    if (err) {
        console.log(err);
    } else {
        console.log(JSON.stringify(data, null, 2));
    }
});

// var params = {TableName: 'raco_test_notes'};
// dynamodb.deleteTable(params, (err, data) => {
//     if (err) {
//         console.log(err);
//     } else {
//         console.log(JSON.stringify(data, null, 2));
//     }
// });