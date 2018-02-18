pragma solidity ^0.4.18;

/// @title Metadata extension to ERC-721 interface
/// @author William Entriken (https://phor.net)
/// @dev Specification at https://github.com/ethereum/EIPs/pull/841 (DRAFT)
interface ERC721Metadata {

    /// @dev ERC-165 (draft) interface signature for ERC721
    // bytes4 internal constant INTERFACE_SIGNATURE_ERC721Metadata = // 0x2a786f11
    //     bytes4(keccak256('name()')) ^
    //     bytes4(keccak256('symbol()')) ^

    /// @notice A descriptive name for a collection of cubes managed by this
    ///  contract
    /// @dev Wallets and exchanges MAY display this to the end user.
    function name() public pure returns (string _cubeName);

    /// @notice An abbreviated name for cubes managed by this contract
    /// @dev Wallets and exchanges MAY display this to the end user.
    function symbol() public pure returns (string _cubeSymbol);
}
