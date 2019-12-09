console.log('Loading function');

const moment = require('moment');
const greetings = {
    'en': 'Hello',
    'fr': 'Bonjour',
    'hi': 'Namaste',
    'es': 'Hola',
    'it': 'Ciao'
}

exports.handler = async (event, context) => {
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