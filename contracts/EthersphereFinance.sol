pragma solidity ^0.4.18;

import "./EthersphereDeed.sol";

/// @dev Holds functionality for finance related to plots.
contract EtherspherFinance is EthersphereDeed {
    /// Total amount of Ether yet to be paid to auction beneficiaries.
    uint256 public outstandingEther = 0 ether;

    /// Amount of Ether yet to be paid per beneficiary.
    mapping (address => uint256) public addressToEtherOwed;

    /// Base price for unclaimed plots.
    uint256 public unclaimedPlotPrice = 0.01 ether;

    /// Buyout fee in 1/1000th of a percentage.
    uint256 public buyoutFeePercentage = 3500;

    /// Number of free claims per address.
    mapping (address => uint256) freeClaimAllowance;

    /// Initial price paid for a plot.
    mapping (uint256 => uint256) public initialPricePaid;

    /// Current plot price.
    mapping (uint256 => uint256) public identifierToBuyoutPrice;

    /// Boolean indicating whether the plot has been bought out at least once.
    mapping (uint256 => bool) identifierToBoughtOutOnce;

    /// @dev Event fired when a buyout is performed.
    event Buyout(address indexed buyer, address indexed seller, uint256 indexed deedId, uint256 winnings, uint256 totalCost, uint256 newPrice);

    /// @dev Event fired when the buyout price is manually changed for a plot.
    event SetBuyoutPrice(uint256 indexed deedId, uint256 newPrice);

    /// @notice Sets the new price for unclaimed plots.
    /// @param _unclaimedPlotPrice The new price for unclaimed plots.
    function setUnclaimedPlotPrice(uint256 _unclaimedPlotPrice)
        external
        onlyCFO
    {
        unclaimedPlotPrice = _unclaimedPlotPrice;
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

    /// @notice Get the buyout cost for a given plot.
    /// @param _deedId The identifier of the plot to get the buyout cost for.
    function buyoutCost(uint256 _deedId)
        external
        view
        returns (uint256)
    {
        // The current buyout price.
        uint256 price = identifierToBuyoutPrice[_deedId];
        return price;
    }

    /// @dev Assign the proceeds of the buyout.
    /// @param _deedId The identifier of the plot that is being bought out.
    function _assignBuyoutProceeds(
        address currentOwner,
        uint256 _deedId,
        uint256 currentOwnerWinnings,
        uint256 totalCost
    )
        internal
    {
        // Calculate and assign the current owner's winnings.
        Buyout(msg.sender, currentOwner, _deedId, currentOwnerWinnings, totalCost, nextBuyoutPrice(totalCost));
        _assignBalance(currentOwner, currentOwnerWinnings);
    }

    /// @dev Calculate and assign the proceeds from the buyout.
    /// @param currentOwner The current owner of the plot that is being bought out.
    /// @param _deedId The identifier of the plot that is being bought out.
    function _calculateAndAssignBuyoutProceeds(address currentOwner, uint256 _deedId)
        internal
        returns (uint256 totalCost)
    {
        // The current price.
        uint256 price = identifierToBuyoutPrice[_deedId];
        totalCost = price;

        // Calculate fees.
        uint256 fee = price.mul(buyoutFeePercentage).div(100000);

        // Calculate and assign buyout proceeds.
        uint256 currentOwnerWinnings = price.sub(fee);

        _assignBuyoutProceeds(
            currentOwner,
            _deedId,
            currentOwnerWinnings,
            totalCost
        );
    }

    /// @notice Buy the current owner out of the plot.
    function buyout(uint256 _deedId)
        external
        payable
        whenNotPaused
    {
        buyoutWithData(_deedId, "", "", "", "");
    }

    /// @notice Buy the current owner out of the plot.
    function buyoutWithData(uint256 _deedId, string name, string description, string imageUrl, string infoUrl)
        public
        payable
        whenNotPaused
    {
        address currentOwner = identifierToOwner[_deedId];

        // The plot must be owned before it can be bought out.
        require(currentOwner != 0x0);

        // Assign the buyout proceeds and retrieve the total cost.
        uint256 totalCost = _calculateAndAssignBuyoutProceeds(currentOwner, _deedId);

        // Ensure the message has enough value.
        require(msg.value >= totalCost);

        // Transfer the plot.
        _transfer(currentOwner, msg.sender, _deedId);

        // Set the plot data
        SetData(_deedId, name, description, imageUrl, infoUrl);

        // Calculate and set the new plot price.
        identifierToBuyoutPrice[_deedId] = nextBuyoutPrice(totalCost);

        // Indicate the plot has been bought out at least once
        if (!identifierToBoughtOutOnce[_deedId]) {
            identifierToBoughtOutOnce[_deedId] = true;
        }

        // Calculate the excess Ether sent.
        // msg.value is greater than or equal to totalCost,
        // so this cannot underflow.
        uint256 excess = msg.value - totalCost;

        if (excess > 0) {
            // Refund any excess Ether (not susceptible to re-entry attack, as
            // the owner is assigned before the transfer takes place).
            msg.sender.transfer(excess);
        }
    }

    /// @notice Calculate the maximum initial buyout price for a plot.
    /// @param _deedId The identifier of the plot to get the maximum initial buyout price for.
    function maximumInitialBuyoutPrice(uint256 _deedId)
        public
        view
        returns (uint256)
    {
        // The initial buyout price can be set to 4x the initial plot price
        uint256 mul = 4;
        return initialPricePaid[_deedId].mul(mul);
    }

    /// @notice Test whether a buyout price is valid.
    /// @param _deedId The identifier of the plot to test the buyout price for.
    /// @param price The buyout price to test.
    function validInitialBuyoutPrice(uint256 _deedId, uint256 price)
        public
        view
        returns (bool)
    {
        return (price >= unclaimedPlotPrice && price <= maximumInitialBuyoutPrice(_deedId));
    }

    /// @notice Manually set the initial buyout price of a plot.
    /// @param _deedId The identifier of the plot to set the buyout price for.
    /// @param price The value to set the buyout price to.
    function setInitialBuyoutPrice(uint256 _deedId, uint256 price)
        public
        whenNotPaused
    {
        // One can only set the buyout price of their own plots.
        require(_owns(msg.sender, _deedId));

        // The initial buyout price can only be set if the plot has never been bought out before.
        require(!identifierToBoughtOutOnce[_deedId]);

        // The buyout price must be valid.
        require(validInitialBuyoutPrice(_deedId, price));

        // Set the buyout price.
        identifierToBuyoutPrice[_deedId] = price;

        // Trigger the buyout price event.
        SetBuyoutPrice(_deedId, price);
    }
}