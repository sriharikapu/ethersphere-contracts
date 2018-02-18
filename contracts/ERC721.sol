pragma solidity ^0.4.18;

/**
 * ERC721 Contracts
 */
/// @title Interface for contracts conforming to ERC-721: Cube Standard
/// @author William Entriken (https://phor.net), et al.
/// @dev Specification at https://github.com/ethereum/EIPs/pull/841 (DRAFT)
interface ERC721 {

    // COMPLIANCE WITH ERC-165 (DRAFT) /////////////////////////////////////////

    /// @dev ERC-165 (draft) interface signature for itself
    // bytes4 internal constant INTERFACE_SIGNATURE_ERC165 = // 0x01ffc9a7
    //     bytes4(keccak256('supportsInterface(bytes4)'));

    /// @dev ERC-165 (draft) interface signature for ERC721
    // bytes4 internal constant INTERFACE_SIGNATURE_ERC721 = // 0xda671b9b
    //     bytes4(keccak256('ownerOf(uint256)')) ^
    //     bytes4(keccak256('countOfCubes()')) ^
    //     bytes4(keccak256('countOfCubesByOwner(address)')) ^
    //     bytes4(keccak256('cubeOfOwnerByIndex(address,uint256)')) ^
    //     bytes4(keccak256('approve(address,uint256)')) ^
    //     bytes4(keccak256('takeOwnership(uint256)'));

    /// @notice Query a contract to see if it supports a certain interface
    /// @dev Returns `true` the interface is supported and `false` otherwise,
    ///  returns `true` for INTERFACE_SIGNATURE_ERC165 and
    ///  INTERFACE_SIGNATURE_ERC721, see ERC-165 for other interface signatures.
    function supportsInterface(bytes4 _interfaceID) external pure returns (bool);

    // PUBLIC QUERY FUNCTIONS //////////////////////////////////////////////////

    /// @notice Find the owner of a cube
    /// @param _cubeId The identifier for a cube we are inspecting
    /// @dev Cubes assigned to zero address are considered destroyed, and
    ///  queries about them do throw.
    /// @return The non-zero address of the owner of cube `_cubeId`, or `throw`
    ///  if cube `_cubeId` is not tracked by this contract
    function ownerOf(uint256 _cubeId) external view returns (address _owner);

    /// @notice Count cubes tracked by this contract
    /// @return A count of the cubes tracked by this contract, where each one of
    ///  them has an assigned and queryable owner
    function countOfCubes() public view returns (uint256 _count);

    /// @notice Count all cubes assigned to an owner
    /// @dev Throws if `_owner` is the zero address, representing destroyed cubes.
    /// @param _owner An address where we are interested in cubes owned by them
    /// @return The number of cubes owned by `_owner`, possibly zero
    function countOfCubesByOwner(address _owner) public view returns (uint256 _count);

    /// @notice Enumerate cubes assigned to an owner
    /// @dev Throws if `_index` >= `countOfCubesByOwner(_owner)` or if
    ///  `_owner` is the zero address, representing destroyed cubes.
    /// @param _owner An address where we are interested in cubes owned by them
    /// @param _index A counter between zero and `countOfCubesByOwner(_owner)`,
    ///  inclusive
    /// @return The identifier for the `_index`th cube assigned to `_owner`,
    ///   (sort order not specified)
    function cubeOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 _cubeId);

    // TRANSFER MECHANISM //////////////////////////////////////////////////////

    /// @dev This event emits when ownership of any cube changes by any
    ///  mechanism. This event emits when cubes are created (`from` == 0) and
    ///  destroyed (`to` == 0). Exception: during contract creation, any
    ///  transfers may occur without emitting `Transfer`.
    event Transfer(address indexed from, address indexed to, uint256 indexed cubeId);

    /// @dev This event emits on any successful call to
    ///  `approve(address _spender, uint256 _cubeId)`. Exception: does not emit
    ///  if an owner revokes approval (`_to` == 0x0) on a cube with no existing
    ///  approval.
    event Approval(address indexed owner, address indexed approved, uint256 indexed cubeId);

    /// @notice Approve a new owner to take your cube, or revoke approval by
    ///  setting the zero address. You may `approve` any number of times while
    ///  the cube is assigned to you, only the most recent approval matters.
    /// @dev Throws if `msg.sender` does not own cube `_cubeId` or if `_to` ==
    ///  `msg.sender`.
    /// @param _cubeId The cube you are granting ownership of
    function approve(address _to, uint256 _cubeId) external;

    /// @notice Become owner of a cube for which you are currently approved
    /// @dev Throws if `msg.sender` is not approved to become the owner of
    ///  `cubeId` or if `msg.sender` currently owns `_cubeId`.
    /// @param _cubeId The cube that is being transferred
    function takeOwnership(uint256 _cubeId) external;

    // SPEC EXTENSIONS /////////////////////////////////////////////////////////

    /// @notice Transfer a cube to a new owner.
    /// @dev Throws if `msg.sender` does not own cube `_cubeId` or if
    ///  `_to` == 0x0.
    /// @param _to The address of the new owner.
    /// @param _cubeId The cube you are transferring.
    function transfer(address _to, uint256 _cubeId) external;
}