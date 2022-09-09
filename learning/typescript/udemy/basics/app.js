// types
// - number - all
// - string
// - boolean
console.log("Raco WAS here...");
function add(n1, n2, showResult, phrase) {
    var result = n1 + n2;
    if (showResult) {
        console.log(phrase + result);
        console.log("again ".concat(phrase, " ").concat(n1 + n2));
    }
    else {
        return result;
    }
}
var number1 = 5;
var number2 = 2.8;
var printResult = false;
var resultPhrase = 'Result is ';
var result = add(number1, number2, printResult, resultPhrase);
console.log(result);
printResult = true;
var number3 = 8;
var number4 = 1.8;
add(number3, number4, printResult, resultPhrase);
