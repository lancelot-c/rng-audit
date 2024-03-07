import { publicClient } from './client.js';
import { abi } from './abi.js';
import { unlinkSync, promises as fsPromises } from 'fs';
import 'dotenv/config'


let entropyNeededPerWinner = 8; // Retrieving 8 bytes (64 bits) of entropy for each winner is enough to have an infinitely small scaling bias
let bytesPerWord = 32; // Each random word from Chainlink VRF gives an entropy of 32 bytes
let wordsPerRequest = 110;
let nbWinnersPerRequest = (bytesPerWord / entropyNeededPerWinner) * wordsPerRequest; // = 440


let startAt = process.env.START_AT; // min value: 1
let howMany = process.env.HOW_MANY; // min value: 1
let outputPath = `./../../script-outputs/OnlyRaw-${startAt}-${howMany}.txt`;
let vrfRequestNb = Math.ceil(startAt / nbWinnersPerRequest);
let exported = 0;
let progress = 0;

async function run() {

    // Remove previous output file if any
    try {
        unlinkSync(outputPath);
    } catch (error) {
        // If error, the file doesn't exist, which is what we want
    }

    let ignoreFirst = (startAt - 1) % nbWinnersPerRequest; // If the first value we want isn't located at the beginning of the request, we need to ignore the values before it
    let isFirst = true;

    while (exported < howMany) {

        // console.log(`vrfRequestNb: ${vrfRequestNb}`);
        let rawEntropy = await collectedEntropy(vrfRequestNb);
        await writeToFile(rawEntropy, ignoreFirst, isFirst);

        if (isFirst) {
            ignoreFirst = 0;
            isFirst = false;
        }

        logProgress();
        vrfRequestNb++;
    }

    console.log(`Output file: ${outputPath}`);
}

async function collectedEntropy(vrfRequest) {
    const data = await publicClient.readContract({
        address: "0xBBCD0c8DBdC112dd29af8c57Ee8740bD9feE084B",
        abi: abi,
        functionName: 'collectedEntropy',
        args: [vrfRequest]
    });
    // console.log(data);
    return data;
}

// Log the progression of the script for every new percent
function logProgress() {

    let newProgress = Math.floor((exported * 100) / howMany);

    if (progress < newProgress) {
        progress = newProgress;
        console.log(`${progress}% (${exported}/${howMany} values)`);
    }
}

async function writeToFile(rawEntropy, ignoreFirst = 0, isFirst = false) {

    rawEntropy = rawEntropy.slice(2); // Removes "0x"

    // To get the 64 bits values from the rawEntropy string, we split it in an array of strings of length 16 because 64 bits are encoded in 16 hexadecimal values (i.e. 16^16 = 2^64)
    // See https://stackoverflow.com/questions/8359905/split-string-into-array-of-equal-length-strings
    let values64Bits = rawEntropy.match(/.{1,16}/g); // the result is an array of size nbWinnersPerRequest

    // Ignore previous values that are out of the range we want to export
    if (ignoreFirst > 0) {
        // console.log(`ignoreFirst: ${ignoreFirst}`);
        values64Bits = values64Bits.slice(ignoreFirst);
    }

    // Ignore next values that are out of the range we want to export
    let toExport = Math.min(values64Bits.length, howMany - exported);
    // console.log(`toExport: ${toExport}`);
    values64Bits = values64Bits.slice(0, toExport);

    // Convert to decimal
    values64Bits = values64Bits.map(v => hexToDec(v));

    // New line between each value
    let finalString = isFirst ? '' : '\n';
    finalString += values64Bits.join('\n');

    // Write to file
    fsPromises.appendFile(outputPath, finalString);
    exported += toExport;
}

// See https://stackoverflow.com/a/53751162
function hexToDec(hex) {

    if (hex.length % 2) {
        hex = '0' + hex;
    }

    let bn = BigInt('0x' + hex);
    let d = bn.toString(10);
    return d;
}

run();