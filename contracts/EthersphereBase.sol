pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "./EthersphereAccessControl.sol";

/// @dev Defines base data structures for Ethersphere.
contract EthersphereBase is EthersphereAccessControl {
    using SafeMath for uint256;


    uint32[] public plots;
    mapping (uint256 => address) identifierToOwner;
    mapping (uint256 => address) identifierToApproved;
    mapping (address => uint256) ownershipDeedCount;

    // Boolean indicating whether the plot was bought before the migration.
    mapping (uint256 => bool) public identifierIsOriginal;

    // Events
    event SetData(uint256 indexed deedId, string name, string description, string imageUrl, string infoUrl);

    /// @dev Get all minted plots.
    function getAllPlots()
        external
        view
        returns(uint256[])
    {
        return plots;
    }

    /// @dev Represent a 2D coordinate as a single uint.
    /// @param x The x-coordinate.
    /// @param y The y-coordinate.
    function coordinateToIdentifier(uint256 x, uint256 y)
        public
        pure
        returns(uint256)
    {
        require(validCoordinate(x, y));
        return (y << 32) + x;
    }

    /// @dev Turn a single uint representation of a coordinate into its x and y parts.
    /// @param identifier The uint representation of a coordinate.
    function identifierToCoordinate(uint256 identifier)
        public
        pure
        returns(uint256 x, uint256 y)
    {
        require(validIdentifier(identifier));

        y = identifier >> 32;
        x = identifier - (y << 32);
    }

    /// @dev Test whether the coordinate is valid.
    /// @param x The x-part of the coordinate to test.
    /// @param y The y-part of the coordinate to test.
    function validCoordinate(uint256 x, uint256 y)
        public
        pure
        returns(bool)
    {
        return x < 4294967296 && y < 4294967296; // 2^32
    }

    /// @dev Test whether an identifier is valid.
    /// @param identifier The identifier to test.
    function validIdentifier(uint256 identifier)
        public
        pure
        returns(bool)
    {
        uint256 sixteen = 4294967296;
        uint256 ans = sixteen.mul(sixteen);
        return identifier < ans;  // 2^32 * 2^32
    }

    /// @dev Set a plot's data.
    /// @param identifier The identifier of the plot to set data for.
    function _setPlotData(uint256 identifier, string name, string description, string imageUrl, string infoUrl)
        internal
    {
        SetData(identifier, name, description, imageUrl, infoUrl);
    }
}