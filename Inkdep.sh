#!/bin/bash

# Memasang Foundry
echo "Memasang Foundry..."
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Membuat proyek baru
echo "Masukkan nama proyek Anda (misalnya: my_project):"
read PROJECT_NAME
echo "Membuat proyek Foundry baru dengan nama: $PROJECT_NAME"
forge init $PROJECT_NAME
cd $PROJECT_NAME

# Menghapus kontrak default dan membuat kontrak baru
echo "Menghapus kontrak default dan membuat kontrak baru..."
rm -rf src/Counter.sol script/Counter.s.sol test/Counter.t.sol

cat > src/InkContract.sol <<EOL
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract InkContract {
    string public greeting = "Hello, Ink!";
    
    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }
}
EOL

# Menyiapkan pengujian untuk kontrak
cat > test/InkContract.t.sol <<EOL
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {InkContract} from "../src/InkContract.sol";

contract InkContractTest is Test {
    InkContract public ink;

    function setUp() public {
        ink = new InkContract();
    }

    function test_DefaultGreeting() public view {
        assertEq(ink.greeting(), "Hello, Ink!");
    }

    function test_SetGreeting() public {
        string memory newGreeting = "New greeting!";
        ink.setGreeting(newGreeting);
        assertEq(ink.greeting(), newGreeting);
    }

    function testFuzz_SetGreeting(string memory randomGreeting) public {
        ink.setGreeting(randomGreeting);
        assertEq(ink.greeting(), randomGreeting);
    }
}
EOL

# Membangun proyek
echo "Membangun proyek Foundry..."
forge build

# Menjalankan pengujian
echo "Menjalankan pengujian..."
forge test

# Menyiapkan file .env untuk penyebaran
echo "Masukkan private key Anda:"
read PRIVATE_KEY
echo "Masukkan RPC URL (misalnya: https://rpc-gel-sepolia.inkonchain.com/):"
read RPC_URL
echo "Masukkan API key BlockScout Anda:"
read BLOCKSCOUT_API_KEY

cat > .env <<EOL
PRIVATE_KEY=$PRIVATE_KEY
RPC_URL=$RPC_URL
BLOCKSCOUT_API_KEY=$BLOCKSCOUT_API_KEY
EOL

# Membuat skrip penyebaran
echo "Membuat skrip penyebaran..."
cat > script/Deploy.s.sol <<EOL
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "forge-std/Script.sol";
import "../src/InkContract.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        new InkContract();

        vm.stopBroadcast();
    }
}
EOL

# Menjalankan penyebaran
echo "Menjalankan penyebaran ke jaringan Sepolia..."
source .env
forge script script/Deploy.s.sol:DeployScript --rpc-url $RPC_URL --broadcast --verify

# Verifikasi kontrak
echo "Verifikasi kontrak di BlockScout..."
echo "Masukkan alamat kontrak yang telah dideploy:"
read DEPLOYED_CONTRACT_ADDRESS
forge verify-contract $DEPLOYED_CONTRACT_ADDRESS src/InkContract.sol:InkContract \
    --chain-id 763373 \
    --etherscan-api-key $BLOCKSCOUT_API_KEY

echo "Instalasi dan penyebaran kontrak selesai!"
