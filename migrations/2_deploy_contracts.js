const IndexProtocol = artifacts.require("IndexProtocol.sol");
const Oracle = artifacts.require("Oracle.sol");
const IndexProtocol89 = artifacts.require("IndexProtocol89.sol");
const Rebase = artifacts.require("Rebase.sol");
module.exports = function(deployer) {
    deployer.deploy(IndexProtocol);
    deployer.deploy(Oracle);
    //deployer.deploy(Rebase);
    //deployer.deploy(IndexProtocol89);

};