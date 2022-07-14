const Sbitwise = artifacts.require("Sbitwise");

module.exports = function (deployer) {
  deployer.deploy(Sbitwise, "Chris");
};
