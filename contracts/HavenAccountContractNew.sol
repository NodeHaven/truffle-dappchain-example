pragma solidity ^0.5.12;

import "openzeppelin-solidity/ownership/Ownable.sol";

contract UserContract is Ownable {
    
    // The address of the Natural Rights Server
    address public naturalRightsAddress;
    
    /// @dev Access modifier for NR-only functionality
    modifier onlyNR() {
        require(msg.sender == naturalRightsAddress);
        _;
    }
    
    struct privUserStruct {
        string encCryptPubKey;
        string encCryptPrivKey;
        string encSignPrivKey;
    }
    struct pubUserStruct {
        string naturalRightsId;
        string userName;
        uint listPointer;
    }
    mapping (address => privUserStruct) userPrivate; // private account backup
    mapping (address => pubUserStruct) userPublic; // naturalRightsID to public identifiers
    address[] public userList; // user index
    mapping (uint256 => address) userNameOwner; // maps username to Loom address
    mapping (uint256 => address) naturalRightsOwner; // maps NR ID to Loom address
    
    
    // Only contract owner can change Natural Rights Server
    function setNaturalRightsServer(address _newNaturalRights) public onlyOwner {
        require(_naturalRights != address(0));
        naturalRightsAddress = _newNaturalRights;
    }
    
    // Natural Rights server only adds users
    function addUser(string _naturalRightsId, address _loomAddr) public onlyNR returns(bool success) {
        naturalRightsIdHash = uint256(keccak256(_naturalRightsId));
        naturalRightsOwner[naturalRightsIdHash] = _loomAddr;
    }
    
    function isLoomUser(address _loomAddr) public view returns(bool isIndeed) {
        if(userList.length == 0) return false;
        return (userList[userPublic[_loomAddr].listPointer] == _loomAddr);
    }
    
    function isHavenUser(address _naturalRightsId) public view returns(bool isIndeed) {
        naturalRightsIdHash = uint256(keccak256(_naturalRightsId));
        return (naturalRightsOwner[naturalRightsIdHash] > 0);
    }

    function getUserCount() public view returns(uint userCount) {
        return userList.length;
    }
    
    function initUser(string _naturalRightsId, string _userName, string _encCryptPubKey, string _encCryptPrivKey, string _encSignPrivKey) public returns(bool success) {
        if(isHavenUser(_naturalRightsId) {
            if(isLoomUser(msg.sender)) {
                revert ("User is already registered")
            } else {
                if(userNameOwner[_userName])) {
                    revert ("Username already taken")
                } else {
                userPrivate[msg.sender].encCryptPubKey = _encCryptPubKey;
                userPrivate[msg.sender].encCryptPrivKey = _encCryptPrivKey;
                userPrivate[msg.sender].encSignPrivKey = _encSignPrivKey;
                userPublic[msg.sender].userName = _userName;
                userPublic[msg.sender].naturalRightsId = _naturalRightsId
                userPublic[msg.sender].listPointer = userList.push(msg.sender) - 1;
                userNameOwner[_userName] = msg.sender;
                
                }
            }
        userPublic[msg.sender].listPointer = userList.push(msg.sender) - 1;
        return true;
        } else {
            revert("Natural Rights account does not exist")
        }
    }

    function updateUserPriv(string _encCryptPubKey, string _encCryptPrivKey, string _encSignPrivKey) public returns(bool success) {
        if(!isLoomUser(msg.sender)) throw;
        userPrivate[msg.sender].encCryptPubKey = _encCryptPubKey;
        userPrivate[msg.sender].encCryptPrivKey = _encCryptPrivKey;
        userPrivate[msg.sender].encSignPrivKey = _encSignPrivKey;
        return true;
    }
    
    function updateUserName(string newUserName) public returns(bool success) {
        if(!isLoomUser(msg.sender)) {
            revert('User does not exist')
        }
        if(userNameOwner[_userName])) {
            revert ("Username already taken")
        } else {
        oldUserNameHash = uint256(keccak256(userPublic[msg.sender].userName));
        delete userNameOwner[oldUserNameHash];
        newUserNameHash = uint256(keccak256(newUserName));
        userNameOwner[newUserNameHash] = msg.sender;
        userPublic[msg.sender].userName = newUserName;
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
