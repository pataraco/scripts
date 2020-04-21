let student = {
  firstName: 'Patrick',
  lastName: 'Raco',
  age: 35,
  hobbies: ['kids', 'movies', 'camping'],
  email: 'pataraco@gmail.com'
}

// object destructuring
let first_name = student.firstName;
let last_name = student.lastName;
console.log('first name:', first_name, '|', 'last name:', last_name);
let { firstName, lastName } = student;
console.log('firstName:', firstName, '|', 'lastName:', lastName);
let { firstName: fn, lastName: ln, nickName: nn = 'N/A' } = student;
console.log('fn:', fn, '|', 'ln:', ln, '|', 'nn:', nn);
let { firstName: f, lastName: l, nickName: n = 'N/A', ...rest } = student;
console.log('f:', f, '|', 'l:', l, '|', 'n:', n, '|', 'rest:', rest);

// array destructuring
let array = [0, 1, 2, 3, 4, 5];
let [n0, , n2, n3 = 'n/a', ...remaining] = array;
console.log('n0:', n0, '|', 'n2:', n2, '|', 'n3:', n3, '|', 'remaining:', remaining);