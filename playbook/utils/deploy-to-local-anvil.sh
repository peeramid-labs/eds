#! /bin/bash

# Uncomment playbook import in hardhat.config.ts
sed -i '' 's|// import '\''./playbook'\''|import '\''./playbook'\''|' ./hardhat.config.ts

rm -rf ./deployments/localhost
export NODE_ENV=TEST
pnpm hardhat deploy --tags ERC7744 --network localhost
