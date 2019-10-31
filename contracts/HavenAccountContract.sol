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
        string cryptPubKey;
        string encCryptPrivKey;
        string encSignPrivKey;
    }
    struct pubUserStruct {
        string naturalRightsId;
        string userName;
        uint listPointer;
    }
    struct userNameTransfer {
        address initiator;
        string initExpectedUserName;
        uint listPointer;
        // bool paymentMade
    }

    mapping (address => privUserStruct) userPrivate; // private account backup
    mapping (address => pubUserStruct) userPublic; // naturalRightsID to public identifiers
    address[] public userList; // user index
    mapping (uint256 => address) userNameOwner; // maps userName to Loom address
    mapping (address => userNameTransfer) userNameTransferQueue; // Queues userName transfer from initiator (value) to comfirmer (key)
    address[] public userNameTransferList; // List of username confirmers
    mapping (uint256 => address) naturalRightsOwner; // maps NR ID to Loom address
    
    // Only contract owner may change Natural Rights Server
    function setNaturalRightsServer(address _newNaturalRights) public onlyOwner returns(bool success) {
        require(_naturalRights != address(0));
        naturalRightsAddress = _newNaturalRights;
        return true;
    }
    
    // Only Natural Rights server may add users
    function addUser(string _naturalRightsId, address _loomAddr) public onlyNR returns(bool success) {
        naturalRightsIdHash = uint256(keccak256(_naturalRightsId));
        naturalRightsOwner[naturalRightsIdHash] = _loomAddr;
    }
    
    // Is user active
    function isLoomUser(address _loomAddr) public view returns(bool isIndeed) {
        if(userList.length == 0) return false;
        return (userList[userPublic[_loomAddr].listPointer] == _loomAddr);
    }
    
    // Is user added by NR
    function isHavenUser(address _naturalRightsId) public view returns(bool isIndeed) {
        naturalRightsIdHash = uint256(keccak256(_naturalRightsId));
        return (naturalRightsOwner[naturalRightsIdHash] > 0);
    }

    // Number of active users
    function getUserCount() public view returns(uint userCount) {
        return userList.length;
    }
    
    function setUserName(string _userName) private {
        userNameHash = uint256(keccak256(_userName));
        userNameOwner[newUserNameHash] = msg.sender;
        userPublic[msg.sender].userName = _userName;
    }

    // user initializes the public and private users structs to become active
    function initUser(string _naturalRightsId, string _userName, string _cryptPubKey, string _encCryptPrivKey, string _encSignPrivKey) public returns(bool success) {
        if(isHavenUser(_naturalRightsId) {
            if(isLoomUser(msg.sender)) {
                revert ("User is already registered")
            } else {
                if(userNameOwner[_userName])) {
                    revert ("Username already taken")
                } else {
                userPrivate[msg.sender].cryptPubKey = _cryptPubKey;
                userPrivate[msg.sender].encCryptPrivKey = _encCryptPrivKey;
                userPrivate[msg.sender].encSignPrivKey = _encSignPrivKey;
                userPublic[msg.sender].naturalRightsId = _naturalRightsId
                userPublic[msg.sender].listPointer = userList.push(msg.sender) - 1;
                setUserName(_userName);
                }
            }
        } else {
            revert("Natural Rights account does not exist")
        }
        return true;
    }

    function updateUserPriv(string _cryptPubKey, string _encCryptPrivKey, string _encSignPrivKey) public returns(bool success) {
        if(!isLoomUser(msg.sender)) {
            revert('User does not exist');
        }
        userPrivate[msg.sender].cryptPubKey = _cryptPubKey;
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
        setUserName(newUserName);
        return true
    }

    function initTransferUsername(address confirmAddr, string expectedUserName) public returns (bool success) {
        if(!isLoomUser(msg.sender)) {
            revert('Initiating User does not exist');
        }
        if(!isLoomUser(confirmAddr)) {
            revert('Confirming User does not exist');
        }
        if(userPublic[confirmAddr].userName == expectedUserName) {
            userNameTransferQueue[confirmAddr].initiator = msg.sender;
            userNameTransferQueue[confirmAddr].listPointer = userNameTransferList.push(confirmAddr) - 1;
        }
        return true;
    }

    function confirmTransferUsername(string expectedUserName) public returns(bool success) {
        address initiator = userNameTransferQueue[msg.sender].initiator;
        if(!isLoomUser(initiator)) {
            revert('Initiating User does not exist');
        }
        if(!isLoomUser(msg.sender)) {
            revert('Confirming User does not exist');
        }
        if(userPublic[initiator].userName == expectedUserName) {
            if(userNameTransferQueue[msg.sender].initExpectedUserName == userPublic[msg.sender].userName) {
                expectedUserNameHash = uint256(keccak256(expectedUserName));
                confirmUserNameHash = uint256(keccak256(userPublic[msg.sender].userName));
                userNameOwner[expectedUserNameHash] = initiator;
                userNameOwner[confirmUserNameHash] = msg.sender;
                userPublic[initiator].userName = userPublic.[msg.sender].userName;
                userPublic[msg.sender].userName = expectedUserName;
                // Remove the userName transfer queue and row in list
                delete naturalRightsTransferQueue[msg.sender];
                uint rowToDelete = userNameTransferList[msg.sender].listPointer;
                address keyToMove = userNameTransferList[userNameTransferList.length-1];
                userNameTransferList[rowToDelete] = keyToMove;
                userNameTransferQueue[keyToMove].listPointer = rowToDelete;
                userNameTransferList.length--;
            }
        }
    }

    // deletes the user from the userList and also deletes the userName. userPriv and NR account mapping left for recovery
    function deleteUser() public returns(bool success) {
        if(!isLoomUser(msg.sender)) {
            revert('User does not exist');
        }
        uint rowToDelete = userPublic[msg.sender].listPointer;
        address keyToMove = userList[userList.length-1];
        userList[rowToDelete] = keyToMove;
        userPublic[keyToMove].listPointer = rowToDelete;
        userList.length--;
        uint256 userNameHash = uint256(keccak256(userPublic[msg.sender].userName))
        delete userNameOwner[userNameHash]
        delete userPublic[msg.sender].userName 
        return true;
    }

    // Used to recover the natural rights encrypted private keys
    function recoverUserPriv() public returns(userPriv) {
        if(!isLoomUser(msg.sender)) {
            revert('User does not exist')
        }
        return userPriv[msg.sender]
    }

    // Used to recover the user public identifiers
    function recoverUserPub() public returns(userPub) {
        if(!isLoomUser(msg.sender)) {
            revert('User does not exist')
        }
        return userPub[msg.sender]
    }
    
    // Reactivate previously deleted user
    function restoreUser(string userName) return(bool success) {
        if(isLoomUser(msg.sender)) {
            revert('User exists')
        }
        setUserName(userName);
        userPublic[msg.sender].listPointer = userList.push(msg.sender) - 1;
    }
}
