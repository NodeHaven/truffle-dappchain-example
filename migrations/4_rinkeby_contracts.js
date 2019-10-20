const MyRinkebyToken = artifacts.require('./MyRinkebyToken.sol')
const KudosRinkebyToken = artifacts.require('./KudosRinkebyToken.sol')

module.exports = function (deployer, network, accounts) {
  if (network !== 'rinkeby') {
    return
  }

  deployer.then(async () => {
    await deployer.deploy(MyRinkebyToken)
    const myTokenInstance = await MyRinkebyToken.deployed()

    await deployer.deploy(KudosRinkebyToken)
    const kudosTokenInstance = await KudosRinkebyToken.deployed()
        
    console.log('\n*************************************************************************\n')
    console.log(`MyRinkebyToken Contract Address: ${myTokenInstance.address}`)
    console.log(`KudosRinkebyToken Contract Address: ${kudosTokenInstance.address}`)
    console.log('\n*************************************************************************\n')
  })
}
