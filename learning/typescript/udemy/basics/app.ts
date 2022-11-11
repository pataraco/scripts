// Core Types
//   - number  - all numbers: integer, float, etc.
//   - string  - 'Hi', "Hi", `Hi`
//   - boolean -  true, false
//   - object  - {key: value}
//   - array   - []
// Other Types
//   - tuple   - []  - fixed length and type
//   - enum    - { NEW, OLD } - human readable numbered list
//   - any                    - try not to use at all if possible
//   - union   number|string
//   - literal   VAR: 'LITERAL1' | 'ANOTHER_LITERAL'
//   - aliases   type NAME = WHAT EVER YOU WANT
//   - return (functions)  => function (): TYPE (explicit void's I/A)
//   - function   - let someFunc: Function;   someFunc = someOtherFunction;
//                - let someFunc: (PARAMS) => RETURN_TYPE ;   someFunc = someOtherFunction;
//   - unknown    - better than 'any'
//   - never      - functions that never return a value

// compilation tips/tricks
//   - watch mode  ;  tsc app.ts --watch | -w
//   - tsc --init  ;  one-time, then 'tsc [--watch]'
// tsconfig tips/tricks
//   - include, exclude, files ; set for tsc to compile whatnot
//   - sourceMap               ; 'true' for WUI inspection debugging and TS viewing
//   - rootDir, outDir         ; location of source and destination for tsc
//   - "removeComments": true  ; tsc will remove comments to reduce size of code
//   - "noEmitOnError": true   ; don't emit if errors found
// general tips/tricks
//   - use "let" not "var" for block {} scope

console.log("Raco WAS here...");

type Combinable = number|string                   // alias type
type ConversionDescriptor = 'as-num'|'as-txt'     // alias type

// unknown
let userInput: unknown;
let userName: string;
userInput = 5;
userInput = 'five';
// userName = userInput;  // error: Type 'unknown' is not assignable to type 'string'.
if (typeof userInput === 'string') {
  userName = userInput;
}

function generateError(msg: string, code: number): never {
  throw { message: msg, errorCode: code };
}

generateError('An error occureed!', 500);

function add(n1: number, n2: number, showResult: boolean, phrase: string) {
  console.log(`type of n1: ${typeof n1}`);
  const result = n1 + n2;
  if (showResult) {
    console.log(phrase + result)
    console.log(`again ${phrase} ${n1+n2}`)
    return result;
  } else {
    return result;
  }
  // throw new Error('Incorrect input!')
}

function combine(
  input1: number|string,
  input2: Combinable,
  showResult: boolean,
  phrase: string,
  resultConversion: 'as-num'|'as-txt',
  altResultConversion: ConversionDescriptor
  ) {
  console.log(`type of input1: ${typeof input1}`);
  let result;
  if (typeof input1 === 'number' && typeof input2 === 'number') {
    result = input1 + input2;
  } else {
    result = input1.toString() + input2.toString();
  }
  if (showResult) {
    console.log(phrase + result)
    console.log(`again ${phrase} ${result}`)
    return result;
  } else {
    return result;
  }
  // throw new Error('Incorrect input!')
  // +result or parseFloat(result) - convert to number
}

enum Role {
  ADMIN = 1,
  READ_ONLY = "RO",
  DEVELOPER = 200
}
const person = {
  name: 'Raco',
  age: 37,
  hobbies: ['Biking', 'Movies'],
  role: Role.ADMIN
}
const animal: object = {
  name: 'Fluffy',
  type: 'Cat'
}
// let myList1: string[];
// myList1 = ['hey', 'bee', 'sea']
const myList1 = ['hey', 'bee', 'sea']
// let myList2: any[];
// let myList2: (number|string|boolean)[];
// myList2 = ['one', 2, true]
const myList2 = ['one', 2, true]
let myTuple: [number, string] = [2, 'Foo']


const vehicle: {  // not needed - let TS infer it
  make: string;
  model: string;
  year: number
} = {
  make: 'Honda',
  model: 'Civic',
  year: 2001
}
const number1 = 5;
const number2 = 2.8;
// let printResult: string;   // not needed - inferred
let printResult = false;
const resultPhrase = 'Result is ';

const result = add(number1, number2, printResult, resultPhrase);
console.log(result);

printResult = true;
const number3 = 8;
const number4 = 1.8;
add(number3, number4, printResult, resultPhrase);


// bookmark
// 20. Working with Enums