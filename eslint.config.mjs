import promise from "eslint-plugin-promise";
import globals from "globals";
import tsParser from "@typescript-eslint/parser";
import path from "node:path";
import { fileURLToPath } from "node:url";
import js from "@eslint/js";
import { FlatCompat } from "@eslint/eslintrc";
import prettier from "eslint-plugin-prettier";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const compat = new FlatCompat({
  baseDirectory: __dirname,
  recommendedConfig: js.configs.recommended,
  allConfig: js.configs.all,
});

export default [
  {
    ignores: ["deployments/", "coverage/**", "docs/templates/", "**/node_modules/"],
  },
  ...compat.extends(
    "eslint:recommended",
    "plugin:promise/recommended",
    "plugin:prettier/recommended", // Add Prettier recommended config
    "prettier",
  ),
  {
    plugins: {
      promise,
      prettier, // Add Prettier plugin
    },
    languageOptions: {
      globals: {
        ...globals.browser,
        ...globals.node,
        ...globals.mocha,
        artifacts: "readonly",
        contract: "readonly",
        assert: "readonly",
        web3: "readonly",
      },
      parser: tsParser,
    },
    rules: {
      "no-unused-vars": "warn",
      "prettier/prettier": "error", // Add Prettier as an ESLint rule
    },
    files: ["**/*.js", "**/*.jsx", "**/*.ts", "**/*.tsx"],
  },
];
