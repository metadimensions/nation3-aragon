const hre = require('hardhat');

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  console.log('Deploying contracts with the account:', deployer.address);
  console.log('Account balance:', (await deployer.getBalance()).toString());

  // Deploy NationDao contract
  const NationDao = await hre.ethers.getContractFactory('NationDao');
  const nationDao = await NationDao.deploy();
  await nationDao.deployed();
  console.log('NationDao address:', nationDao.address);

  // Deploy NationDaoSetup contract
  const NationDaoSetup = await hre.ethers.getContractFactory('NationDaoSetup');
  const nationDaoSetup = await NationDaoSetup.deploy(nationDao.address);
  await nationDaoSetup.deployed();
  console.log('NationDaoSetup address:', nationDaoSetup.address);

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
