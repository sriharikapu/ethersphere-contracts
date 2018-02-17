pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/token/ERC721/ERC721Token.sol';

contract Ethersphere {

    // Structs
    struct Location {
        address owner;
        string hash;
    }

    // Mappings
    mapping (string => unit256) public locationID;

    // Event
    event LocationIdentified(string location, uint256 id);

    function Ethersphere(){

    }
}
