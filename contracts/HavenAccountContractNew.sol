pragma solidity ^0.5.12;

import "openzeppelin-solidity/ownership/Ownable.sol";

contract UserContract is Ownable {
    struct privUserStruct {
        string naturalRightsId;
        address ethereumAddr;
        string username;
        string encCryptPubKey;
        string encCryptPrivKey;
        string encSignPrivKey;
        uint listPointer;
    }
    struct pubUserStruct {
        string loomAddress;
        string userName;
        uint listPointer;
    }
    mapping (address => privUserStruct) userAccount; // private account backup
    mapping (string => pubUserStruct) usernameMap; // naturalRightsID to public identifiers
    address[] public userList
    
    function isLoomUser(address loomAddress) public constant returns(bool isIndeed) {
        if(userList.length == 0) return false;
        return (userList[pubUserStructs[naturalRightsId].listPointer] == entityAddress);
    }
    
    function isHavenUser(address accountId) public constant returns(bool isIndeed) {
        if(entityList.length == 0) return false;
        return (entityList[pubUserStructs[entityAddress].listPointer] == entityAddress);
    }

    function getEntityCount() public constant returns(uint entityCount) {
        return entityList.length;
    }

    function newEntity(address entityAddress, uint entityData) public returns(bool success) {
        if(isEntity(entityAddress)) throw;
        entityStructs[entityAddress].entityData = entityData;
        entityStructs[entityAddress].listPointer = entityList.push(entityAddress) - 1;
        return true;
    }

    function updateEntity(address entityAddress, uint entityData) public returns(bool success) {
        if(!isEntity(entityAddress)) throw;
        entityStructs[entityAddress].entityData = entityData;
        return true;
    }

    function deleteEntity(address entityAddress) public returns(bool success) {
        if(!isEntity(entityAddress)) throw;
        uint rowToDelete = entityStructs[entityAddress].listPointer;
        address keyToMove   = entityList[entityList.length-1];
        entityList[rowToDelete] = keyToMove;
        entityStructs[keyToMove].listPointer = rowToDelete;
        entityList.length--;
        return true;
    }
}
