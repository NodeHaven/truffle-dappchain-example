pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract UserContract is Ownable {
    struct UserStruct {
        string accountId;
        string username;
        string encCryptPrivKey;
        string encSigPrivKey;
    }
    mapping (address => UserStruct[])
    mapping (address => uint256) listOfUsers; //address-> username hash
    uint256[] listOfGunNicksIndex;
    mapping (uint256 => string) listOfSocialUsernamesHashTranslations;
    mapping (address => string) listOfSocialEncryptedKeys;


    event setHavenAccount(address user, string userGunNick);

    function setHavenAccount(string memory _gunNick, ) public {

        //check that the user doesnt exist since before
        //search by string hash
        //...
        if (listOfSocialUsernames[msg.sender] > 5)
        {
            //we found that the user already has over 5
            revert("the user already has a nick");
        }

        //check that any other user doesnt have the same nick since before
        bytes memory _gunNickInBytes = bytes(_gunNick);
        uint256 gunNickHash = uint256(keccak256(_gunNickInBytes));

        bytes memory tempEmptyStringTest = bytes(listOfGunNickHashTranslations[gunNickHash]);
        if (tempEmptyStringTest.length != 0){
            revert("the name already exists for another nick");
        }
        //if(keccak256(_gunNick) == keccak256(listOfGunNickHashTranslations[gunNickHash]) ){

        //}
        //add the user address and nick to the store
        //listOfGunNicksIndex = listOfGunNicksIndex.length + 1;
        listOfGunNicks[msg.sender] = gunNickHash;
        listOfGunNickHashTranslations[gunNickHash] = _gunNick;

        emit SetUserGunNick(msg.sender, _gunNick);
    }

    function getUserGunNick(address _user) public view returns (string memory) {

        return listOfGunNickHashTranslations[listOfGunNicks[_user]];
    }

    event SetGunKey(address user, string userGunNick);

    function setGunKey(string memory _gunKey) public {
        listOfGunEncryptedKeys[msg.sender] = _gunKey;

        emit SetGunKey(msg.sender, _gunKey);
    }

    function getGunKey(address _user) public view returns (string memory) {
        return listOfGunEncryptedKeys[_user];
    }


}