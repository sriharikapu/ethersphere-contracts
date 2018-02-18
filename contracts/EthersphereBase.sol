pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "./EthersphereAccessControl.sol";

/// @dev Defines base data structures for Ethersphere.
/// @dev Defines base data structures for DWorld.
contract EthersphereBase is EthersphereAccessControl {
    using SafeMath for uint256;

    mapping (uint256 => string) public dataName;
    mapping (uint256 => string) public dataDescription;
    mapping (uint256 => string) public dataImageUrl;

    /// @dev All minted cubes (array of cube identifiers). There are
    /// 2^16 * 2^16 possible cubes (covering the entire world), thus
    /// 32 bits are required. This fits in a uint32. Storing
    /// the identifiers as uint32 instead of uint256 makes storage
    /// cheaper. (The impact of this in mappings is less noticeable,
    /// and using uint32 in the mappings below actually *increases*
    /// gas cost for minting).
    uint256[] public cubes;

    mapping (uint256 => address) identifierToOwner;
    mapping (uint256 => address) identifierToApproved;
    mapping (address => uint256) ownershipCubeCount;

    // Boolean indicating whether the cube was bought before the migration.
    mapping (uint256 => bool) public identifierIsOriginal;

    /// @dev Event fired when a cube's data are changed. The cube
    /// data are not stored in the contract directly, instead the
    /// data are logged to the block. This gives significant
    /// reductions in gas requirements (~75k for minting with data
    /// instead of ~180k). However, it also means cube data are
    /// not available from *within* other contracts.
    event SetData(uint256 indexed cubeId, string name, string description, string imageUrl, string infoUrl);

    /// @notice Get all minted cubes.
    function getAllCubes() external view returns(uint256[]) {
        return cubes;
    }

    /// @dev Represent a 2D coordinate as a single uint.
    /// @param x The x-coordinate.
    /// @param y The y-coordinate.
    function coordinateToIdentifier(uint256 x, uint256 y) public pure returns(uint256) {
        require(validCoordinate(x, y));

        return (y << 64) + x;
    }

    /// @dev Turn a single uint representation of a coordinate into its x and y parts.
    /// @param identifier The uint representation of a coordinate.
    function identifierToCoordinate(uint256 identifier) public pure returns(uint256 x, uint256 y) {
        require(validIdentifier(identifier));

        y = identifier >> 64;
        x = identifier - (y << 64);
    }

    /// @dev Test whether the coordinate is valid.
    /// @param x The x-part of the coordinate to test.
    /// @param y The y-part of the coordinate to test.
    function validCoordinate(uint256 x, uint256 y) public pure returns(bool) {
        return x < 18446744073709551616 && y < 18446744073709551616; // 2^64
    }

    /// @dev Test whether an identifier is valid.
    /// @param identifier The identifier to test.
    function validIdentifier(uint256 identifier) public pure returns(bool) {
        return identifier < 340282366920938463463374607431768211456; // 2^64 * 2^64
    }

    /// @dev Set a cube's data.
    /// @param identifier The identifier of the cube to set data for.
    function _setCubeData(uint256 identifier, string name, string description, string imageUrl, string infoUrl) internal {
        SetData(identifier, name, description, imageUrl, infoUrl);
    }
}