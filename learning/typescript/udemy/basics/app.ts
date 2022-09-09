// types
// - number - all
// - string
// - boolean

console.log("Raco WAS here...");

function add(n1: number, n2: number, showResult: boolean, phrase: string) {
  const result = n1 + n2;
  if (showResult) {
    console.log(phrase + result)
    console.log(`again ${phrase} ${n1+n2}`)
  } else {
    return result;
  }
}

const number1 = 5;
const number2 = 2.8;
let printResult = false;
const resultPhrase = 'Result is ';

const result = add(number1, number2, printResult, resultPhrase);
console.log(result);

printResult = true;
const number3 = 8;
const number4 = 1.8;
add(number3, number4, printResult, resultPhrase);