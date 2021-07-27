const IndexProtocol = artifacts.require("IndexProtocol.sol");

module.exports = function(deployer) {
    deployer.deploy(IndexProtocol);
};