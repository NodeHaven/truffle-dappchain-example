const MyRinkebyToken = artifacts.require('./MyRinkebyToken.sol')
const KudosRinkebyToken = artifacts.require('./KudosRinkebyToken.sol')

module.exports = function (deployer, network, accounts) {
  if (network !== 'rinkeby') {
    return
  }

  deployer.then(async () => {
    await deployer.deploy(KudosRinkebyToken)
    const myTokenInstance = await KudosRinkebyToken.deployed()

    await deployer.deploy(KudosRinkebyToken)
    const KudosTokenInstance = await KudosRinkebyToken.deployed()
        
    console.log('\n*************************************************************************\n')
    console.log(`KudosRinkebyToken Contract Address: ${myTokenInstance.address}`)
    console.log(`KudosRinkebyToken Contract Address: ${KudosTokenInstance.address}`)
    console.log('\n*************************************************************************\n')
  })
}
