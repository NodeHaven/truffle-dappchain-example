pragma solidity ^0.5.12;

import "openzeppelin-solidity/ownership/Ownable.sol";

contract UserContract is Ownable {
    struct privUserStruct {
        string naturalRightsId;
        address ethAddr;
        string userName;
        string encCryptPubKey;
        string encCryptPrivKey;
        string encSignPrivKey;
    }
    struct pubUserStruct {
        address loomAddr;
        string userName;
        uint listPointer;
    }
    mapping (address => privUserStruct) userPrivate; // private account backup
    mapping (string => pubUserStruct) userPublic; // naturalRightsID to public identifiers
    address[] public userList;
    mapping (string => address) userNameOwner; // maps username to address
    
    function isLoomUser(address _loomAddr) public view returns(bool isIndeed) {
        if(userList.length == 0) return false;
        return (userList[privUserStructs[_loomAddr].listPointer] == _loomAddr);
    }
    
    function isHavenUser(address _naturalRightsId) public view returns(bool isIndeed) {
        return (pubUserStructs[_naturalRightsId].loomAddr > 0);
    }

    function getUserCount() public view returns(uint userCount) {
        return userList.length;
    }

    function newUser(string _naturalRightsId, address _ethAddr, string _userName, string _encCryptPubKey, string _encCryptPrivKey, string _encSignPrivKey) public returns(bool success) {
        if(isHavenUser(_naturalRightsId) {
            if(isLoomUser(msg.sender)) {
                revert ("User is already registered")
            } else {
                if(userNameOwner[_userName])) {
                    revert ("Username already taken")
                } else {
                userPrivate[msg.sender].naturalRightsId = _naturalRightsId;
                userPrivate[msg.sender].ethAddr = _ethAddr;
                userPrivate[msg.sender].userName = _userName;
                userPrivate[msg.sender].encCryptPubKey = _encCryptPubKey;
                userPrivate[msg.sender].encCryptPrivKey = _encCryptPrivKey;
                userPrivate[msg.sender].encSignPrivKey = _encSignPrivKey;
                userPublic[_naturalRightsId].userName = _userName;
                userPublic[msg.sender].listPointer = userList.push(msg.sender) - 1;
                userNameOwner[_userName] = msg.sender;
                
                }
            }
        entityStructs[entityAddress].listPointer = entityList.push(entityAddress) - 1;
        return true;
        } else {
            revert("Natural Rights account does not exist")
        }
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
