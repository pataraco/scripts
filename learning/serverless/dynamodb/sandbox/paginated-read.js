const async = require('async');
const _ = require('underscore');

const AWS = require('aws-sdk');
AWS.config.update({region: 'us-west-2'});

const documentClient = new AWS.DynamoDB.DocumentClient();

var startKey = {};
var results = [];
var pages = 0;

async.doWhilst(
    // iteratee
    (callback) => {
        let params = {
            TableName: 'raco_test_notes',
            Limit: 2
        };

        if (!_.isEmpty(startKey)) {
            params.ExclusiveStartKey = startKey;
        }

        documentClient.scan(params, (err, data) => {
            if (err) {
                console.log(err);
                callback(err, {});
            } else {
                if (typeof data.LastEvaluatedKey !== 'undefined') {
                    startKey = data.LastEvaluatedKey;
                } else {
                    startKey = [];
                }

                if (!_.isEmpty(data.Items)) {
                    results = _.union(results, data.Items);
                    pages++;
                }

                callback(null, results);
            }
        });
    },

    // test
    (results, callback) => {
        if (_.isEmpty(startKey)) { 
            return callback(null, false);
        } else {
            return callback(null, true);
        }
    },

    // callback
    (err, data) => {
        if (err) {
            console.log(err);
        } else {
            console.log(data);
            console.log("Item Count:", data.length);
            console.log("Pages:", pages);
        }
    }
);