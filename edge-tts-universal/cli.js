#!/usr/bin/env node

import { Communicate } from './dist/isomorphic.js';
import fs from 'fs';

const args = process.argv.slice(2);

const voice = args.includes('--voice') ? args[args.indexOf('--voice') + 1] || 'en-US-AndrewMultilingualNeural' : 'en-US-AndrewMultilingualNeural';
const rate = args.includes('--rate') ? args[args.indexOf('--rate') + 1] || '+0%' : '+0%';
const volume = args.includes('--volume') ? args[args.indexOf('--volume') + 1] || '+0%' : '+0%';
const pitch = args.includes('--pitch') ? args[args.indexOf('--pitch') + 1] || '+0Hz' : '+0Hz';
const output = args.includes('--output') ? args[args.indexOf('--output') + 1] : null;
const stdin = args.includes('--stdin');

let text = '';
if (stdin) {
  text = fs.readFileSync(0, 'utf8');
}

async function run() {
  try {
    const communicateOptions = {
      voice,
      rate,
      volume,
      pitch
    };

    const tts = new Communicate(text, communicateOptions);
    
    if (output) {
      const writeStream = fs.createWriteStream(output);
      for await (const chunk of tts.stream()) {
        if (chunk.type === 'audio' && chunk.data) {
          writeStream.write(chunk.data);
        }
      }
      writeStream.end();
    } else {
      for await (const chunk of tts.stream()) {
        if (chunk.type === 'audio' && chunk.data) {
          process.stdout.write(chunk.data);
        }
      }
    }
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

run();