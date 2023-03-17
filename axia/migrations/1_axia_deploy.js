const TestToken = artifacts.require('./TestToken.sol');

module.exports = async (deployer) =>
{
    /**
     * Deploy the Tokeniza Token Contract
     */
    await deployer.deploy(
        TestToken,
        "0xD8f3234C711Dd16ee0d881659d6502161999806d"
    );
};