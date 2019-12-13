const AWS = require('aws-sdk');
AWS.config.update({region: 'us-west-2'});

const stepFunctions = new AWS.StepFunctions();

exports.handler = async (event) => {
    console.log(JSON.stringify(event));
    let filesProcessed = event.Records.map(async (record) => {
        let params = {
            stateMachineArn: process.env.STATE_MACHINE_ARN,
            input: JSON.stringify(record)
        }
        let data = await stepFunctions.startExecution(params).promise();
        console.log('step function data:', data);
        return data;
    })
    let results = await Promise.all(filesProcessed);
    return results;
};
