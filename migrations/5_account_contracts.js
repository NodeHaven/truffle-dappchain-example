const HavenAccountContract = artifacts.require('./HavenAccountContract.sol')

module.exports = function (deployer, network, accounts) {
  if (network === 'rinkeby') {
    return
  }

  deployer.then(async () => {
    await deployer.deploy(HavenAccountContract, gatewayAddress)
    const HavenAccountInstance = await HavenAccountContract.deployed()

        
    console.log('\n*************************************************************************\n')
    console.log(`Haven Account Contract Address: ${HavenAccountInstance.address}`)
    console.log('\n*************************************************************************\n')
  })
}