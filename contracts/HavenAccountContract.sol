pragma solidity ^0.5.12;

import "openzeppelin-solidity/ownership/Ownable.sol";

contract UserContract is Ownable {

    // The address of the Natural Rights Server Testing
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

    mapping (address => privUserStruct) userPriv; // private account backup
    mapping (address => pubUserStruct) userPub; // naturalRightsID to public identifiers
    address[] public userList; // user index
    mapping (uint256 => address) userNameOwner; // maps userName to Loom address
    mapping (address => userNameTransfer) userNameTransferQueue; // Queues userName transfer from initiator (value) to comfirmer (key)
    address[] public userNameTransferList; // List of username confirmers
    mapping (uint256 => address) naturalRightsOwner; // maps NR ID to Loom address
    
    // Only contract owner may change Natural Rights Server
    function setNaturalRightsServer(address _newNaturalRights) public onlyOwner returns(bool success) {
        require(_newNaturalRights != address(0));
        naturalRightsAddress = _newNaturalRights;
        return true;
    }
    
    // Only Natural Rights server may add users
    function addUser(string memory _naturalRightsId, address _loomAddr) public onlyNR returns(bool success) {
        uint256 naturalRightsIdHash = uint256(keccak256(bytes(_naturalRightsId)));
        naturalRightsOwner[naturalRightsIdHash] = _loomAddr;
    }
    
    // Is user active
    function isLoomUser(address _loomAddr) public view returns(bool isIndeed) {
        if(userList.length == 0) return false;
        return (userList[userPub[_loomAddr].listPointer] == _loomAddr);
    }
    
    // Is user added by NR
    function isHavenUser(string memory _naturalRightsId) public view returns(bool isIndeed) {
        uint256 naturalRightsIdHash = uint256(keccak256(bytes(_naturalRightsId)));
        return (naturalRightsOwner[naturalRightsIdHash] != address(0));
    }

    // Number of active users
    function getUserCount() public view returns(uint userCount) {
        return userList.length;
    }
    
    function setUserName(string memory _userName) private {
        uint256 userNameHash = uint256(keccak256(_userName));
        userNameOwner[userNameHash] = msg.sender;
        userPub[msg.sender].userName = _userName;
    }

    // user initializes the public and private users structs to become active
    function initUser(string memory _naturalRightsId, string memory _userName, string memory _cryptPubKey, string memory _encCryptPrivKey, string memory _encSignPrivKey) public returns(bool success) {
        if(isHavenUser(_naturalRightsId)) {
            if(isLoomUser(msg.sender)) {
                revert ("User is already registered");
            } else {
                uint256 userNameHash = uint256(keccak256(_userName));
                if(userNameOwner[userNameHash]) {
                    revert ("Username already taken");
                } else {
                userPriv[msg.sender].cryptPubKey = _cryptPubKey;
                userPriv[msg.sender].encCryptPrivKey = _encCryptPrivKey;
                userPriv[msg.sender].encSignPrivKey = _encSignPrivKey;
                userPub[msg.sender].naturalRightsId = _naturalRightsId;
                userPub[msg.sender].listPointer = userList.push(msg.sender) - 1;
                setUserName(_userName);
                }
            }
        } else {
            revert("Natural Rights account does not exist");
        }
        return true;
    }

    function updateUserPriv(string memory _cryptPubKey, string memory _encCryptPrivKey, string memory _encSignPrivKey) public returns(bool success) {
        if(!isLoomUser(msg.sender)) {
            revert('User does not exist');
        }
        userPriv[msg.sender].cryptPubKey = _cryptPubKey;
        userPriv[msg.sender].encCryptPrivKey = _encCryptPrivKey;
        userPriv[msg.sender].encSignPrivKey = _encSignPrivKey;
        return true;
    }

    function updateUserName(string memory _newUserName) public returns(bool success) {
        if(!isLoomUser(msg.sender)) {
            revert('User does not exist');
        }
        uint256 userNameHash = uint256(keccak256(_newUserName));
        if(userNameOwner[userNameHash]) {
            revert ("Username already taken");
        } else {
        uint256 oldUserNameHash = uint256(keccak256(userPub[msg.sender].userName));
        delete userNameOwner[oldUserNameHash];
        setUserName(_newUserName);
        return true;
        }
    }

    function initTransferUsername(address confirmAddr, string memory expectedUserName) public returns(bool success) {
        if(!isLoomUser(msg.sender)) {
            revert('Initiating User does not exist');
        }
        if(!isLoomUser(confirmAddr)) {
            revert('Confirming User does not exist');
        }
        if(userPub[confirmAddr].userName == expectedUserName) {
            userNameTransferQueue[confirmAddr].initiator = msg.sender;
            userNameTransferQueue[confirmAddr].listPointer = userNameTransferList.push(confirmAddr) - 1;
        }
        return true;
    }

    function confirmTransferUsername(string memory expectedUserName) public returns(bool success) {
        address initiator = userNameTransferQueue[msg.sender].initiator;
        if(!isLoomUser(initiator)) {
            revert('Initiating User does not exist');
        }
        if(!isLoomUser(msg.sender)) {
            revert('Confirming User does not exist');
        }
        if(userPub[initiator].userName == expectedUserName) {
            if(userNameTransferQueue[msg.sender].initExpectedUserName == userPub[msg.sender].userName) {
                uint256 expectedUserNameHash = uint256(keccak256(expectedUserName));
                uint256 confirmUserNameHash = uint256(keccak256(userPub[msg.sender].userName));
                userNameOwner[expectedUserNameHash] = initiator;
                userNameOwner[confirmUserNameHash] = msg.sender;
                userPub[initiator].userName = userPub[msg.sender].userName;
                userPub[msg.sender].userName = expectedUserName;
                // Remove the userName transfer queue and row in list
                delete userNameTransferQueue[msg.sender];
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
        uint rowToDelete = userPub[msg.sender].listPointer;
        address keyToMove = userList[userList.length-1];
        userList[rowToDelete] = keyToMove;
        userPub[keyToMove].listPointer = rowToDelete;
        userList.length--;
        uint256 userNameHash = uint256(keccak256(userPub[msg.sender].userName));
        delete userNameOwner[userNameHash];
        delete userPub[msg.sender].userName; 
        return true;
    }

    // Used to recover the natural rights encrypted private keys
    function recoverUserPriv() public returns(string memory, string memory, string memory) {
        if(!isLoomUser(msg.sender)) {
            revert('User does not exist');
        }
        return (userPriv[msg.sender].cryptPubKey, userPriv[msg.sender].encCryptPrivKey, userPriv[msg.sender].encSignPrivKey);
    }

    // Used to recover the user public identifiers
    function recoverUserPub() public returns(string memory, string memory, string memory) {
        if(!isLoomUser(msg.sender)) {
            revert('User does not exist');
        }
        return (userPub[msg.sender].naturalRightsId, userPub[msg.sender].userName, userPub[msg.sender].listPointer);
    }
    
    // Reactivate previously deleted user
    function restoreUser(string memory userName) public returns(bool success) {
        if(isLoomUser(msg.sender)) {
            revert('User exists');
        }
        setUserName(userName);
        userPub[msg.sender].listPointer = userList.push(msg.sender) - 1;
    }
}
