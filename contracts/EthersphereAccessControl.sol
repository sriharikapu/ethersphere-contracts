pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/ownership/Claimable.sol";
import "zeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "zeppelin-solidity/contracts/ownership/CanReclaimToken.sol";

/// @dev Implements access control to the Ethersphere contract.
contract EthersphereAccessControl is Claimable, Pausable, CanReclaimToken {
    address public cfoAddress;

    function EthersphereAccessControl()
        public
    {
        // The creator of the contract is the initial CFO.
        cfoAddress = msg.sender;
    }

    /// @dev Access modifier for CFO-only functionality.
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    /// @dev Assigns a new address to act as the CFO. Only available to the current contract owner.
    /// @param _newCFO The address of the new CFO.
    function setCFO(address _newCFO)
        external
        onlyOwner
    {
        require(_newCFO != address(0));
        cfoAddress = _newCFO;
    }
}