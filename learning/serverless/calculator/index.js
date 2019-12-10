// test event
// {
//   "operation": "/",
//   "input": {
//     "operand1": 5,
//     "operand2": 4
//   }
// }
//
// API - Integration Request
// {
//    "operation": "$input.params('operation')",
//    "input": {
//      "operand1": $input.json('$.num1'),
//      "operand2": $input.json('$.num2')
//    }
// }
//
// API - Integration Response
// {
//    "result": $input.json('$.body')
// }

exports.handler = async (event) => {
    let {operand1, operand2} = event.input;
    let result;
    switch(event.operation) {
        case 'add':
        case '+':
            result = operand1 + operand2;
            break;
        case 'subtract':
        case '-':
            result = operand1 - operand2;
            break;
        case 'multiply':
        case '*':
            result = operand1 * operand2;
            break;
        case 'divide':
        case '/':
            result = operand1 / operand2;
            break;
        default:
            result = null;
    }        
    const response = {
        statusCode: 200,
        body: JSON.stringify(result),
    };
    return response;
};
