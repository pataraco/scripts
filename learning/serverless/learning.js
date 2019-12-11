'use strict'

// --- Node.js 6.10 ---
// exports.handler = (event, context, callback) => {
//     // do some stuff
//     callback(null, result);
// }

// --- Node.js 8.10/10.x/12.x ---
// exports.handler = async (event, context) => {
//     // do some stuff
//     return result;
// }

// =============================================================

// --- hondler example 1 (BEGIN) ---
// exports.handler = async (event, context) => {
//     const data = event.data;
//     let newImage = await resizeImage();
//     return newImage;
// }

// const newImage = (data) => new Promise((resolve, reject) => {
//     // resize the image
//     if (data) {
//         resolve(result);
//     } else {
//         reject(error);
//     }
// });
// --- hondler example 1 (END) ---

// =============================================================

// --- hondler example 2 (BEGIN) ---
// event: Amazon SNS Topic Notification

// console.log('Loading function');

// exports.handler = async (event, context) => {
//     console.log('Received event:                     ', JSON.stringify(event, null, 2));
//     console.log('Received context:                   ', JSON.stringify(context, null, 2));
//     console.log('event.Records                      =', event.Records);                     // SNS event
//     console.log('event.Records[0].EventSource       =', event.Records[0].EventSource);      // SNS event

//     console.log('context.getRemainingTimeInMillis() =', context.getRemainingTimeInMillis());
//     console.log('context.functionName               =', context.functionName);
//     console.log('context.functionVersion            =', context.functionVersion);
    
//     // console.log('environment variable: Creator      =', Creator);
    
//     // console.log('context.clientContext              =', context.clientContext);
//     // console.log('context.clientContext.env          =', context.clientContext.env);
//     // console.log('context.clientContext.env.Creator  =', context.clientContext.env.Creator);
    
//     // throw new Error('Something went wrong');

//     console.info('an informative message');
//     console.warn('a warning message');
//     console.error('an error message');


//     return event.Records[0].EventSource;                                                    // SNS event
// };
// --- hondler example 2 (END) ---

// =============================================================

// --- hondler example 3 (BEGIN) ---
// event: Amazon API Gateway AWS Proxy

console.log('Loading function');

const greetings = {
    'en': 'Hello',
    'fr': 'Bonjour',
    'hi': 'Namaste',
    'es': 'Hola',
    'it': 'Ciao'
}

exports.handler = async (event, context) => {
    // hondle API gateway: PATH/URI/Name?lang=val1&param2=val2

    let {functionName:fName, functionVersion:fVersion} = context;
    console.log('Handling function:', fName, '- version:', fVersion);

    let name = event.pathParameters.name;
    let {lang, ...remaining} = event.queryStringParameters;
    
    let message = `${greetings[lang] ? greetings[lang] : greetings['en']} ${name}`;
    let body = {
        timestamp: moment().unix(),
        message: message,
        remaining_params: remaining
    }
    let response = {
        'statusCode': 200,
        'body': JSON.stringify(body)
    }
    console.log('event.pathParameters.name =', name);
    console.log('message =', message);
    console.log('response =', response);

    return response;
};
// --- hondler example 3 (END) ---

// =============================================================

// --- hondler environment variables (BEGIN) ---
const AWS = require('aws-sdk');
AWS.config.update({ region: 'us-west-2' });

const encryptedDbPassword = process.env['DB_PASSWORD'];
let decryptedDbPassword;

async function processEvent(event, context) {
    let log = event;
    log.functionName = context.functionName;
    log.functionVersion = context.functionVersion;
    log.db_user = process.env.DB_USER;
    log.db_name = process.env.DB_NAME;
    log.db_password_encrypted = encryptedDbPassword;
    log.db_password_decrypted = decryptedDbPassword;
    return log;
}

exports.handler = async (event, context) => {
    if (decryptedDbPassword) {
        return processEvent(event, context);
    } else {
        // Decrypt code should run once and variables stored outside of the
        // function handler so that these are decrypted once per container
        const kms = new AWS.KMS();
        let data = await kms.decrypt({
            CiphertextBlob: new Buffer(encryptedDbPassword, 'base64')
        }).promise();
        decryptedDbPassword = data.Plaintext.toString('ascii');
        return processEvent(event, context);
    }
};
// --- hondler environment variables (END) ---