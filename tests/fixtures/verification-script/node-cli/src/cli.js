#!/usr/bin/env node

const args = process.argv.slice(2);

if (args.includes('--help') || args.includes('-h')) {
  console.log('Usage: greet [options] [name]');
  console.log('');
  console.log('Options:');
  console.log('  -h, --help     Show this help message');
  console.log('  -v, --version  Show version');
  console.log('  --shout        Output in uppercase');
  process.exit(0);
}

if (args.includes('--version') || args.includes('-v')) {
  console.log('1.0.0');
  process.exit(0);
}

const shout = args.includes('--shout');
const name = args.filter(a => !a.startsWith('-'))[0] || 'World';

let message = `Hello, ${name}!`;
if (shout) {
  message = message.toUpperCase();
}

console.log(message);
