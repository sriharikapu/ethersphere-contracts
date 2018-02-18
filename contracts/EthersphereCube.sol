pragma solidity ^0.4.18;

import "./ERC721.sol";
import "./ERC721Metadata.sol";
import "./EthersphereBase.sol";

/// @dev Holds cube functionality such as approving and transferring. Implements ERC721.
contract EthersphereCube is EthersphereBase, ERC721, ERC721Metadata {

    /// @notice Name of the collection of cubes (non-fungible token), as defined in ERC721Metadata.
    function name() public pure returns (string _cubeName) {
        _cubeName = "Ethersphere Cubes";
    }

    /// @notice Symbol of the collection of cubes (non-fungible token), as defined in ERC721Metadata.
    function symbol() public pure returns (string _cubeSymbol) {
        _cubeSymbol = "ESP";
    }

    /// @dev ERC-165 (draft) interface signature for itself
    bytes4 internal constant INTERFACE_SIGNATURE_ERC165 = // 0x01ffc9a7
    bytes4(keccak256('supportsInterface(bytes4)'));

    /// @dev ERC-165 (draft) interface signature for ERC721
    bytes4 internal constant INTERFACE_SIGNATURE_ERC721 = // 0xda671b9b
    bytes4(keccak256('ownerOf(uint256)')) ^
    bytes4(keccak256('countOfCubes()')) ^
    bytes4(keccak256('countOfCubesByOwner(address)')) ^
    bytes4(keccak256('cubeOfOwnerByIndex(address,uint256)')) ^
    bytes4(keccak256('approve(address,uint256)')) ^
    bytes4(keccak256('takeOwnership(uint256)'));

    /// @dev ERC-165 (draft) interface signature for ERC721
    bytes4 internal constant INTERFACE_SIGNATURE_ERC721Metadata = // 0x2a786f11
    bytes4(keccak256('name()')) ^
    bytes4(keccak256('symbol()'));

    /// @notice Introspection interface as per ERC-165 (https://github.com/ethereum/EIPs/issues/165).
    /// Returns true for any standardized interfaces implemented by this contract.
    /// (ERC-165 and ERC-721.)
    function supportsInterface(bytes4 _interfaceID) external pure returns (bool) {
        return (
        (_interfaceID == INTERFACE_SIGNATURE_ERC165)
        || (_interfaceID == INTERFACE_SIGNATURE_ERC721)
        || (_interfaceID == INTERFACE_SIGNATURE_ERC721Metadata)
        );
    }

    /// @dev Checks if a given address owns a particular cube.
    /// @param _owner The address of the owner to check for.
    /// @param _cubeId The cube identifier to check for.
    function _owns(address _owner, uint256 _cubeId) internal view returns (bool) {
        return identifierToOwner[_cubeId] == _owner;
    }

    /// @dev Approve a given address to take ownership of a cube.
    /// @param _from The address approving taking ownership.
    /// @param _to The address to approve taking ownership.
    /// @param _cubeId The identifier of the cube to give approval for.
    function _approve(address _from, address _to, uint256 _cubeId) internal {
        identifierToApproved[_cubeId] = _to;

        // Emit event.
        Approval(_from, _to, _cubeId);
    }

    /// @dev Checks if a given address has approval to take ownership of a cube.
    /// @param _claimant The address of the claimant to check for.
    /// @param _cubeId The identifier of the cube to check for.
    function _approvedFor(address _claimant, uint256 _cubeId) internal view returns (bool) {
        return identifierToApproved[_cubeId] == _claimant;
    }

    /// @dev Assigns ownership of a specific cube to an address.
    /// @param _from The address to transfer the cube from.
    /// @param _to The address to transfer the cube to.
    /// @param _cubeId The identifier of the cube to transfer.
    function _transfer(address _from, address _to, uint256 _cubeId) internal {
        // The number of cubes is capped at 2^16 * 2^16, so this cannot
        // be overflowed.
        ownershipCubeCount[_to]++;

        // Transfer ownership.
        identifierToOwner[_cubeId] = _to;

        // When a new cube is minted, the _from address is 0x0, but we
        // do not track cube ownership of 0x0.
        if (_from != address(0)) {
            ownershipCubeCount[_from]--;

            // Clear taking ownership approval.
            delete identifierToApproved[_cubeId];
        }

        // Emit the transfer event.
        Transfer(_from, _to, _cubeId);
    }

    // ERC 721 implementation
    /// @notice Returns the total number of cubes currently in existence.
    /// @dev Required for ERC-721 compliance.
    function countOfCubes() public view returns (uint256) {
        return cubes.length;
    }

    /// @notice Returns the number of cubes owned by a specific address.
    /// @param _owner The owner address to check.
    /// @dev Required for ERC-721 compliance
    function countOfCubesByOwner(address _owner) public view returns (uint256) {
        return ownershipCubeCount[_owner];
    }

    /// @notice Returns the address currently assigned ownership of a given cube.
    /// @dev Required for ERC-721 compliance.
    function ownerOf(uint256 _cubeId) external view returns (address _owner) {
        _owner = identifierToOwner[_cubeId];

        require(_owner != address(0));
    }

    /// @notice Approve a given address to take ownership of a cube.
    /// @param _to The address to approve taking owernship.
    /// @param _cubeId The identifier of the cube to give approval for.
    /// @dev Required for ERC-721 compliance.
    function approve(address _to, uint256 _cubeId) external whenNotPaused {
        uint256[] memory _cubeIds = new uint256[](1);
        _cubeIds[0] = _cubeId;

        approveMultiple(_to, _cubeIds);
    }

    /// @notice Approve a given address to take ownership of multiple cubes.
    /// @param _to The address to approve taking ownership.
    /// @param _cubeIds The identifiers of the cubes to give approval for.
    function approveMultiple(address _to, uint256[] _cubeIds) public whenNotPaused {
        // Ensure the sender is not approving themselves.
        require(msg.sender != _to);

        for (uint256 i = 0; i < _cubeIds.length; i++) {
            uint256 _cubeId = _cubeIds[i];

            // Require the sender is the owner of the cube.
            require(_owns(msg.sender, _cubeId));

            // Perform the approval.
            _approve(msg.sender, _to, _cubeId);
        }
    }

    /// @notice Transfer a cube to another address. If transferring to a smart
    /// contract be VERY CAREFUL to ensure that it is aware of ERC-721, or your
    /// cube may be lost forever.
    /// @param _to The address of the recipient, can be a user or contract.
    /// @param _cubeId The identifier of the cube to transfer.
    /// @dev Required for ERC-721 compliance.
    function transfer(address _to, uint256 _cubeId) external whenNotPaused {
        uint256[] memory _cubeIds = new uint256[](1);
        _cubeIds[0] = _cubeId;

        transferMultiple(_to, _cubeIds);
    }

    /// @notice Transfers multiple cubes to another address. If transferring to
    /// a smart contract be VERY CAREFUL to ensure that it is aware of ERC-721,
    /// or your cubes may be lost forever.
    /// @param _to The address of the recipient, can be a user or contract.
    /// @param _cubeIds The identifiers of the cubes to transfer.
    function transferMultiple(address _to, uint256[] _cubeIds) public whenNotPaused {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));

        // Disallow transfers to this contract to prevent accidental misuse.
        require(_to != address(this));

        for (uint256 i = 0; i < _cubeIds.length; i++) {
            uint256 _cubeId = _cubeIds[i];

            // One can only transfer their own cubes.
            require(_owns(msg.sender, _cubeId));

            // Transfer ownership
            _transfer(msg.sender, _to, _cubeId);
        }
    }

    /// @notice Transfer a cube owned by another address, for which the calling
    /// address has previously been granted transfer approval by the owner.
    /// @param _cubeId The identifier of the cube to be transferred.
    /// @dev Required for ERC-721 compliance.
    function takeOwnership(uint256 _cubeId) external whenNotPaused {
        uint256[] memory _cubeIds = new uint256[](1);
        _cubeIds[0] = _cubeId;

        takeOwnershipMultiple(_cubeIds);
    }

    /// @notice Transfer multiple cubes owned by another address, for which the
    /// calling address has previously been granted transfer approval by the owner.
    /// @param _cubeIds The identifier of the cube to be transferred.
    function takeOwnershipMultiple(uint256[] _cubeIds) public whenNotPaused {
        for (uint256 i = 0; i < _cubeIds.length; i++) {
            uint256 _cubeId = _cubeIds[i];
            address _from = identifierToOwner[_cubeId];

            // Check for transfer approval
            require(_approvedFor(msg.sender, _cubeId));

            // Reassign ownership (also clears pending approvals and emits Transfer event).
            _transfer(_from, msg.sender, _cubeId);
        }
    }

    /// @notice Returns a list of all cube identifiers assigned to an address.
    /// @param _owner The owner whose cubes we are interested in.
    /// @dev This method MUST NEVER be called by smart contract code. It's very
    /// expensive and is not supported in contract-to-contract calls as it returns
    /// a dynamic array (only supported for web3 calls).
    function cubesOfOwner(address _owner) external view returns(uint256[]) {
        uint256 cubeCount = countOfCubesByOwner(_owner);

        if (cubeCount == 0) {
            // Return an empty array.
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](cubeCount);
            uint256 totalCubes = countOfCubes();
            uint256 resultIndex = 0;

            for (uint256 cubeNumber = 0; cubeNumber < totalCubes; cubeNumber++) {
                uint256 identifier = cubes[cubeNumber];
                if (identifierToOwner[identifier] == _owner) {
                    result[resultIndex] = identifier;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    /// @notice Returns a cube identifier of the owner at the given index.
    /// @param _owner The address of the owner we want to get a cube for.
    /// @param _index The index of the cube we want.
    function cubeOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
        // The index should be valid.
        require(_index < countOfCubesByOwner(_owner));

        // Loop through all cubes, accounting the number of cubes of the owner we've seen.
        uint256 seen = 0;
        uint256 totalCubes = countOfCubes();

        for (uint256 cubeNumber = 0; cubeNumber < totalCubes; cubeNumber++) {
            uint256 identifier = cubes[cubeNumber];
            if (identifierToOwner[identifier] == _owner) {
                if (seen == _index) {
                    return identifier;
                }

                seen++;
            }
        }
    }
}