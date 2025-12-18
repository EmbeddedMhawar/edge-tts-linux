
import { Communicate } from "./src/communicate";
import fs from "fs";
import { Readable } from "stream";

// Simple argument parser
const args: Record<string, string | boolean> = {};
let currentKey: string | null = null;

for (const arg of process.argv.slice(2)) {
  if (arg.startsWith("--")) {
    const key = arg.slice(2);
    if (key === "stdin") {
      args[key] = true;
      currentKey = null;
    } else {
      currentKey = key;
    }
  } else if (arg.startsWith("-")) {
      // Handle short flags if strictly necessary, but sticking to long flags for simplicity as per existing script usage
      const key = arg.slice(1);
      // Map short flags to long flags based on edge_tts_client.py
      if (key === 't') { currentKey = 'text'; }
      else if (key === 'v') { currentKey = 'voice'; }
      else if (key === 'r') { currentKey = 'rate'; }
      else if (key === 'p') { currentKey = 'pitch'; }
      else if (key === 'o') { currentKey = 'output'; }
      else { currentKey = key; }
  } else if (currentKey) {
    args[currentKey] = arg;
    currentKey = null;
  }
}

async function readStdin(): Promise<string> {
  const chunks: Buffer[] = [];
  for await (const chunk of process.stdin) {
    chunks.push(Buffer.from(chunk));
  }
  return Buffer.concat(chunks).toString("utf-8");
}

async function main() {
  let text = "";

  if (args.stdin) {
    text = await readStdin();
  } else if (typeof args.text === "string") {
    text = args.text;
  } else {
    console.error("Error: Either --text or --stdin is required");
    process.exit(1);
  }

  const voice = (args.voice as string) || "en-US-AndrewMultilingualNeural";
  const rate = (args.rate as string) || "+0%";
  const volume = (args.volume as string) || "+0%";
  const pitch = (args.pitch as string) || "+0Hz";
  const outputFile = (args.output as string) || null;

  const communicate = new Communicate(text, {
    voice,
    rate,
    volume,
    pitch,
  });

  const outputStream = outputFile
    ? fs.createWriteStream(outputFile)
    : process.stdout;

  try {
    for await (const chunk of communicate.stream()) {
      if (chunk.type === "audio" && chunk.data) {
        outputStream.write(chunk.data);
      }
    }
  } catch (error) {
    console.error("Error streaming TTS:", error);
    process.exit(1);
  } finally {
    if (outputFile) {
        // @ts-ignore
        outputStream.end();
    }
  }
}

main();
