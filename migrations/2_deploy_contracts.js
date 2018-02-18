const EthersphereAccessControl = artifacts.require("./EthersphereAccessControl.sol");
const EthersphereBase = artifacts.require("./EthersphereBase.sol");
const EthersphereCube = artifacts.require("./EthersphereCube.sol");
const EthersphereFinance = artifacts.require("./EthersphereFinance.sol");
const EthersphereMinting = artifacts.require("./EthersphereMinting.sol");

module.exports = function(deployer, network) {
    deployer.then(function() {

        deployer.deploy(EthersphereAccessControl).then(function() {
            return deployer.deploy(EthersphereBase).then(function() {
                return deployer.deploy(EthersphereCube).then(function() {
                    return deployer.deploy(EthersphereFinance).then(function() {
                        return deployer.deploy(EthersphereMinting)
                    });
                });
            });
        });
    });
};