/* eslint-disable no-undef */
/* eslint-disable arrow-body-style */
/* eslint-disable no-await-in-loop */
// import { time } from "@openzeppelin/test-helpers";
import { ethers } from "hardhat";
// @ts-ignore
import { JsonFragment } from "@ethersproject/abi";
import fs from "fs";
import path from "path";

const getSuperInterface = () => {
  let mergedArray: JsonFragment[] = [];
  function readDirectory(directory: string) {
    const files = fs.readdirSync(directory);

    files.forEach((file) => {
      const fullPath = path.join(directory, file);
      if (fs.statSync(fullPath).isDirectory()) {
        readDirectory(fullPath); // Recurse into subdirectories
      } else if (path.extname(file) === ".json") {
        const fileContents = require("../" + fullPath); // Load the JSON file
        if (Array.isArray(fileContents)) {
          mergedArray = mergedArray.concat(fileContents); // Merge the array from the JSON file
        }
      }
    });
  }
  const originalConsoleLog = console.log;
  readDirectory("./abi");
  console.log = () => {}; // avoid noisy output
  const result = new ethers.utils.Interface(mergedArray);
  console.log = originalConsoleLog;
  return result;
};

export default {
  getSuperInterface,
};
