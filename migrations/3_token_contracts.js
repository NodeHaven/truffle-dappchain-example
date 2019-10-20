const MyToken = artifacts.require('./MyToken.sol')
const KudosToken = artifacts.require('./KudosToken.sol')

const gatewayAddress = '0xe754d9518bf4a9c63476891ef9AA7d91C8236A5D'

module.exports = function (deployer, network, accounts) {
  if (network === 'rinkeby') {
    return
  }

  deployer.then(async () => {
    await deployer.deploy(MyToken, gatewayAddress)
    const myTokenInstance = await MyToken.deployed()

    await deployer.deploy(KudosToken, gatewayAddress)
    const kudosTokenInstance = await KudosToken.deployed()
        
    console.log('\n*************************************************************************\n')
    console.log(`KudosToken Contract Address: ${myTokenInstance.address}`)
    console.log(`KudosCoin Contract Address: ${kudosTokenInstance.address}`)
    console.log('\n*************************************************************************\n')
  })
}
