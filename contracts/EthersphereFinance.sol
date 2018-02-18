pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "./EthersphereCube.sol";

/// @dev Holds functionality for finance related to cubes.
/// @dev Holds functionality for finance related to cubes.
contract EthersphereFinance is EthersphereAccessControl, EthersphereCube {
    using SafeMath for uint256;

    /// Total amount of Ether yet to be paid to auction beneficiaries.
    uint256 public outstandingEther = 0 ether;

    /// Amount of Ether yet to be paid per beneficiary.
    mapping (address => uint256) public addressToEtherOwed;

    /// Base price for unclaimed cubes.
    uint256 public unclaimedCubePrice = 0.01 ether;

    /// Buyout fee in 1/1000th of a percentage.
    uint256 public buyoutFeePercentage = 3500;

    /// Number of free claims per address.
    mapping (address => uint256) freeClaimAllowance;

    /// Initial price paid for a cube.
    mapping (uint256 => uint256) public initialPricePaid;

    /// Current cube price.
    mapping (uint256 => uint256) public identifierToBuyoutPrice;

    /// Boolean indicating whether the cube has been bought out at least once.
    mapping (uint256 => bool) identifierToBoughtOutOnce;

    /// @dev Event fired when a buyout is performed.
    event Buyout(address indexed buyer, address indexed seller, uint256 indexed cubeId, uint256 winnings, uint256 totalCost, uint256 newPrice);

    /// @dev Event fired when the buyout price is manually changed for a cube.
    event SetBuyoutPrice(uint256 indexed cubeId, uint256 newPrice);

    /// @notice Sets the new price for unclaimed cubes.
    /// @param _unclaimedCubePrice The new price for unclaimed cubes.
    function setUnclaimedCubePrice(uint256 _unclaimedCubePrice)
    external
    onlyCFO
    {
        unclaimedCubePrice = _unclaimedCubePrice;
    }

    /// @notice Sets the new fee percentage for buyouts.
    /// @param _buyoutFeePercentage The new fee percentage for buyouts.
    function setBuyoutFeePercentage(uint256 _buyoutFeePercentage)
    external
    onlyCFO
    {
        // Buyout fee may be 5% at the most.
        require(0 <= _buyoutFeePercentage && _buyoutFeePercentage <= 5000);

        buyoutFeePercentage = _buyoutFeePercentage;
    }

    /// @notice Set the free claim allowance for an address.
    /// @param addr The address to set the free claim allowance for.
    /// @param allowance The free claim allowance to set.
    function setFreeClaimAllowance(address addr, uint256 allowance)
    external
    onlyCFO
    {
        freeClaimAllowance[addr] = allowance;
    }

    /// @notice Get the free claim allowance of an address.
    /// @param addr The address to get the free claim allowance of.
    function freeClaimAllowanceOf(address addr)
    external
    view
    returns (uint256)
    {
        return freeClaimAllowance[addr];
    }


    /// @dev Assign balance to an account.
    /// @param addr The address to assign balance to.
    /// @param amount The amount to assign.
    function _assignBalance(address addr, uint256 amount)
    internal
    {
        addressToEtherOwed[addr] = addressToEtherOwed[addr].add(amount);
        outstandingEther = outstandingEther.add(amount);
    }

    /// @dev Calculate the next buyout price given the current total buyout cost.
    /// @param totalCost The current total buyout cost.
    function nextBuyoutPrice(uint256 totalCost) public pure returns (uint256) {
        if (totalCost < 0.05 ether) {
            return totalCost * 2;
        } else if (totalCost < 0.2 ether) {
            return totalCost * 170 / 100; // * 1.7
        } else if (totalCost < 0.5 ether) {
            return totalCost * 150 / 100; // * 1.5
        } else {
            return totalCost.mul(125).div(100); // * 1.25
        }
    }

    /// @notice Get the buyout cost for a given cube.
    /// @param _cubeId The identifier of the cube to get the buyout cost for.
    function buyoutCost(uint256 _cubeId)
    external
    view
    returns (uint256)
    {
        // The current buyout price.
        uint256 price = identifierToBuyoutPrice[_cubeId];
        return price;
    }

    /// @dev Assign the proceeds of the buyout.
    /// @param _cubeId The identifier of the cube that is being bought out.
    function _assignBuyoutProceeds(
        address currentOwner,
        uint256 _cubeId,
        uint256 currentOwnerWinnings,
        uint256 totalCost
    )
    internal
    {
        // Calculate and assign the current owner's winnings.
        Buyout(msg.sender, currentOwner, _cubeId, currentOwnerWinnings, totalCost, nextBuyoutPrice(totalCost));
        _assignBalance(currentOwner, currentOwnerWinnings);
    }

    /// @dev Calculate and assign the proceeds from the buyout.
    /// @param currentOwner The current owner of the cube that is being bought out.
    /// @param _cubeId The identifier of the cube that is being bought out.
    function _calculateAndAssignBuyoutProceeds(address currentOwner, uint256 _cubeId)
        internal
        returns (uint256 totalCost)
    {
        // The current price.
        uint256 price = identifierToBuyoutPrice[_cubeId];
        totalCost = price;

        // Calculate fees.
        uint256 fee = price.mul(buyoutFeePercentage).div(100000);

        // Calculate and assign buyout proceeds.
        uint256 currentOwnerWinnings = price.sub(fee);

        _assignBuyoutProceeds(
            currentOwner,
            _cubeId,
            currentOwnerWinnings,
            totalCost
        );
    }

    /// @notice Buy the current owner out of the cube.
    function buyout(uint256 _cubeId)
        external
        payable
        whenNotPaused
    {
        buyoutWithData(_cubeId, "", "", "", "");
    }

    /// @dev Send ether to the fund collection wallet. If the user is msg.sender, send and log. If not, just log.
    function forwardFunds()
        internal
    {
        cfoAddress.transfer(msg.value);
    }

    /// @dev Send ether to the fund collection wallet. If the user is msg.sender, send and log. If not, just log.
    function forwardFundsBuyout()
        internal
    {
        uint256 cfoAmount = msg.value.div(98);
        uint256 payout = msg.value.sub(cfoAmount);
        msg.sender.transfer(payout);
        cfoAddress.transfer(cfoAmount);
    }

    /// @notice Buy the current owner out of the cube.
    function buyoutWithData(uint256 _cubeId, string name, string description, string imageUrl, string infoUrl)
        public
        payable
        whenNotPaused
    {
        address currentOwner = identifierToOwner[_cubeId];

        // The cube must be owned before it can be bought out.
        require(currentOwner != 0x0);

        // Assign the buyout proceeds and retrieve the total cost.
        uint256 totalCost = _calculateAndAssignBuyoutProceeds(currentOwner, _cubeId);

        // Ensure the message has enough value.
        require(msg.value >= totalCost);

        // Transfer the cube.
        _transfer(currentOwner, msg.sender, _cubeId);

        // Set the cube data
        SetData(_cubeId, name, description, imageUrl, infoUrl);

        // Calculate and set the new cube price.
        identifierToBuyoutPrice[_cubeId] = nextBuyoutPrice(totalCost);

        // Indicate the cube has been bought out at least once
        if (!identifierToBoughtOutOnce[_cubeId]) {
            identifierToBoughtOutOnce[_cubeId] = true;
        }

        forwardFundsBuyout();
    }

    /// @notice Calculate the maximum initial buyout price for a cube.
    /// @param _cubeId The identifier of the cube to get the maximum initial buyout price for.
    function maximumInitialBuyoutPrice(uint256 _cubeId)
    public
    view
    returns (uint256)
    {
        // The initial buyout price can be set to 4x the initial cube price
        uint256 mul = 4;
        return initialPricePaid[_cubeId].mul(mul);
    }

    /// @notice Test whether a buyout price is valid.
    /// @param _cubeId The identifier of the cube to test the buyout price for.
    /// @param price The buyout price to test.
    function validInitialBuyoutPrice(uint256 _cubeId, uint256 price)
    public
    view
    returns (bool)
    {
        return (price >= unclaimedCubePrice && price <= maximumInitialBuyoutPrice(_cubeId));
    }

    /// @notice Manually set the initial buyout price of a cube.
    /// @param _cubeId The identifier of the cube to set the buyout price for.
    /// @param price The value to set the buyout price to.
    function setInitialBuyoutPrice(uint256 _cubeId, uint256 price)
    public
    whenNotPaused
    {
        // Set the buyout price.
        identifierToBuyoutPrice[_cubeId] = price;

        // Trigger the buyout price event.
        SetBuyoutPrice(_cubeId, price);
    }

}