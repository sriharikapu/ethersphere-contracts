pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "./EthersphereFinance.sol";
import "./EthersphereBase.sol";

/// @dev Holds functionality for minting new cube cubes.
contract EthersphereMinting is Pausable, EthersphereFinance {

    /// @notice Buy unclaimed cubes.
    /// @param _cubeIds The unclaimed cubes to buy.
    /// @param _buyoutPrice The initial buyout price to set on the cube.
    function claimCubeMultiple(uint256[] _cubeIds, uint256 _buyoutPrice)
    external
    payable
    whenNotPaused
    {
        claimCubeMultipleWithData(_cubeIds, _buyoutPrice, "", "", "", "");
    }

    /// @dev Send ether to the fund collection wallet. If the user is msg.sender, send and log. If not, just log.
    function forwardFunds()
    internal
    {
        cfoAddress.transfer(msg.value);
    }

    /// @notice Buy unclaimed cubes.
    /// @param _cubeIds The unclaimed cubes to buy.
    /// @param _buyoutPrice The initial buyout price to set on the cube.
    /// @param name The name to give the cubes.
    /// @param description The description to add to the cubes.
    /// @param imageUrl The image url for the cubes.
    /// @param infoUrl The info url for the cubes.
    function claimCubeMultipleWithData(uint256[] _cubeIds, uint256 _buyoutPrice, string name, string description, string imageUrl, string infoUrl)
    public
    payable
    whenNotPaused
    {
        uint256 buyAmount = _cubeIds.length;
        uint256 etherRequired;
        if (freeClaimAllowance[msg.sender] > 0) {
            // The sender has a free claim allowance.
            if (freeClaimAllowance[msg.sender] > buyAmount) {
                // Subtract from allowance.
                freeClaimAllowance[msg.sender] -= buyAmount;

                // No ether is required.
                etherRequired = 0;
            } else {
                uint256 freeAmount = freeClaimAllowance[msg.sender];

                // The full allowance has been used.
                delete freeClaimAllowance[msg.sender];

                // The subtraction cannot underflow, as freeAmount <= buyAmount.
                etherRequired = unclaimedCubePrice.mul(buyAmount - freeAmount);
            }
        } else {
            // The sender does not have a free claim allowance.
            etherRequired = unclaimedCubePrice.mul(buyAmount);
        }

        uint256 offset = cubes.length;

        // Allocate additional memory for the cubes array
        // (this is more efficient than .push-ing each individual
        // cube, as that requires multiple dynamic allocations).
        cubes.length = cubes.length.add(_cubeIds.length);

        for (uint256 i = 0; i < _cubeIds.length; i++) {
            uint256 _cubeId = _cubeIds[i];
            require(validIdentifier(_cubeId));

            // The cube must be unowned (a cube cube cannot be transferred to
            // 0x0, so once a cube is claimed it will always be owned by a
            // non-zero address).
            require(identifierToOwner[_cubeId] == address(0));

            // Create the cube
            cubes[offset + i] = uint256(_cubeId);
            saveData(_cubeId, name, description, imageUrl);

            // Transfer the new cube to the sender.
            _transfer(address(0), msg.sender, _cubeId);

            // Set the cube data.
            _setCubeData(_cubeId, name, description, imageUrl, infoUrl);

            // Set the initial price paid for the cube.
            initialPricePaid[_cubeId] = unclaimedCubePrice;

            // Set the initial buyout price. Throws if it does not succeed.
            setInitialBuyoutPrice(_cubeId, _buyoutPrice);

        }

        forwardFunds();

    }

    function saveData(uint _cubeId, string _name, string _description, string _imageUrl)
    internal
    {
        dataName[_cubeId] = _name;
        dataDescription[_cubeId] = _description;
        dataImageUrl[_cubeId] = _imageUrl;
    }
}