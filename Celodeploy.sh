const fs = require('fs');
const { execSync } = require('child_process');
const os = require('os');

function installNode() {
  console.log('Checking Node.js and npm installation...');

  try {
    // Check if Node.js is installed
    const nodeVersion = execSync('node -v').toString();
    const npmVersion = execSync('npm -v').toString();
    console.log(`Node.js version: ${nodeVersion}`);
    console.log(`npm version: ${npmVersion}`);
    return; // Exit if both are installed
  } catch (error) {
    console.log('Node.js or npm is not installed. Installing now...');
  }

  // Determine the OS
  const platform = os.platform();

  let installCommand;
  if (platform === 'win32') {
    installCommand = 'powershell -Command "Start-Process msiexec.exe -ArgumentList \'/i https://nodejs.org/dist/latest/node-v18.17.0-x64.msi /quiet /norestart\' -Verb RunAs"';
  } else if (platform === 'darwin') {
    installCommand = 'brew install node'; // Requires Homebrew
  } else if (platform === 'linux') {
    installCommand = 'curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - && sudo apt-get install -y nodejs';
  } else {
    throw new Error('Unsupported OS. Please install Node.js manually.');
  }

  // Install Node.js
  execSync(installCommand, { stdio: 'inherit' });
}

function setupHardhat() {
  try {
    // Install Hardhat
    console.log('Installing Hardhat...');
    execSync('npm install --save-dev hardhat', { stdio: 'inherit' });

    // Initialize Hardhat
    console.log('Initializing Hardhat...');
    execSync('npx hardhat', { stdio: 'inherit' });

    // Update hardhat.config.js
    const configContent = `
module.exports = {
  solidity: "0.8.4",
  networks: {
    alfajores: {
      url: "https://alfajores-forno.celo-testnet.org",
      accounts: { mnemonic: process.env.MNEMONIC },
      chainId: 44787
    },
    celo: {
      url: "https://forno.celo.org",
      accounts: { mnemonic: process.env.MNEMONIC },
      chainId: 42220
    }
  }
};
`;

    console.log('Updating hardhat.config.js...');
    fs.writeFileSync('./hardhat.config.js', configContent);
    
    // Run the sample script on the Alfajores network
    console.log('Running sample script on the Alfajores network...');
    execSync('npx hardhat run scripts/sample-script.js --network alfajores', { stdio: 'inherit' });

    console.log('Setup completed successfully!');
  } catch (error) {
    console.error('An error occurred:', error.message);
  }
}

// Main function to execute the setup
function main() {
  installNode();
  setupHardhat();
}

main();
