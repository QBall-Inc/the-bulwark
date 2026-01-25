#!/usr/bin/env node

const args = process.argv.slice(2);
const operation = args[0];
const numbers = args.slice(1).map(Number).filter(n => !isNaN(n));

if (!operation || numbers.length === 0) {
  console.error('Usage: calc <operation> <numbers...>');
  console.error('Operations: add, sub, mul, div, avg, max, min');
  process.exit(1);
}

let result;

switch (operation) {
  case 'add':
    result = numbers.reduce((a, b) => a + b, 0);
    break;
  case 'sub':
    result = numbers.reduce((a, b) => a - b);
    break;
  case 'mul':
    result = numbers.reduce((a, b) => a * b, 1);
    break;
  case 'div':
    if (numbers.slice(1).includes(0)) {
      console.error('Error: Division by zero');
      process.exit(1);
    }
    result = numbers.reduce((a, b) => a / b);
    break;
  case 'avg':
    result = numbers.reduce((a, b) => a + b, 0) / numbers.length;
    break;
  case 'max':
    result = Math.max(...numbers);
    break;
  case 'min':
    result = Math.min(...numbers);
    break;
  default:
    console.error(`Unknown operation: ${operation}`);
    process.exit(1);
}

console.log(result);
