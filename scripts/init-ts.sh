#!/bin/bash

# 1. Initialize Project and Install Dependencies
npm init -y
npm install -D typescript tsx @types/node

# 2. Setup Directory Structure
mkdir -p src
echo 'const message: string = "Hello, TypeScript!";' >src/index.ts
echo 'console.log(message);' >>src/index.ts

# 3. Create tsconfig.json with specified compilerOptions
cat <<EOF >tsconfig.json
{
  "compilerOptions": {
    "outDir": "./dist",
    "rootDir": "./src",
    "target": "ESNext",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "esModuleInterop": true,
    "strict": true,
    "skipLibCheck": true
  }
}
EOF

# 4. Update package.json scripts
node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
pkg.scripts = {
  ...pkg.scripts,
  'dev': 'tsx watch src/index.ts',
  'build': 'tsc',
  'start': 'node dist/index.js'
};
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
"

echo "Project initialized. Use 'npm run build' followed by 'npm start' to execute."
