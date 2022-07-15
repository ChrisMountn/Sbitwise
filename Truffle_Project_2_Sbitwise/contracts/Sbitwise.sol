// SPDX-License-Identifier: GPL-3.0
// No need to use SafeMath, as lowest allowed version is 0.8.0
pragma solidity ^0.8.0;

contract Sbitwise {
    //initiate group member structure
    struct groupMember {
        string name;
        int amountPaid;
        bool confirmedSplit;
        int owes;
    }

    //the person who initiates the contract is the group admin
    address public groupAdmin;

    // events
    event AdminSet(address indexed oldAdmin, address indexed newAdmin);
    event newSplit(string indexed name, string exchangeType, int indexed amount);
    event memberRemoved(address indexed memberAddress, string indexed name);
    
    // modifier to check if caller is admin
    modifier isAdmin() {
        require(msg.sender == groupAdmin, "Caller is not Admin");
        _;
    }
    
    // modifier to check if caller is group member
    modifier isGroupMember() {
        bool isMember = false;
        for(uint i = 0; i < memberAddresses.length; i++ ){
            if(msg.sender == memberAddresses[i]){
                isMember = true;
            }
        }
        require(isMember == true, "Caller is not a group member");
        _;
    }

    //modifier to check if everyone agrees to split
    modifier everyoneAgreesToSplit() {
        bool everyoneAgrees = true;
        for(uint i = 0; i < memberAddresses.length; i++ ){
            if(groupMembers[memberAddresses[i]].confirmedSplit == false){
                everyoneAgrees = false;
            }
        }
        require(everyoneAgrees == true, "Not everyone agrees to split");
        _;
    }

    //modifier to check if everyone has paid
    modifier allPaid() {
        bool everyonePaid = true;
        for(uint i = 0; i < memberAddresses.length; i++ ){
            if(groupMembers[memberAddresses[i]].owes != balances[memberAddresses[i]] && groupMembers[memberAddresses[i]].owes > 0){
                everyonePaid = false;
            }
        }
        require(everyonePaid == true, "Not everyone has paid");
        _;
    }

    //make a mapping from address to group member and a list of member addresses.
    mapping(address => groupMember) public groupMembers;
    address[] public memberAddresses;

    //Set the contract initiator to group admin. 
    constructor(string memory _adminName){
        groupAdmin = msg.sender;
        groupMembers[groupAdmin].name = _adminName;
        groupMembers[groupAdmin].amountPaid = 0;
        groupMembers[groupAdmin].confirmedSplit = false;
        memberAddresses.push(groupAdmin);
    }

    //Absolute value utility function
    function abs(int x) private pure returns (int) {
        return x >= 0 ? x : -x;
    }

    //Admin adds members to group.
    //SHOULD CHECK THAT USER NOT ALREADY IN GROUP
    function addToGroup(address _groupMember, string memory _name) external isAdmin {
        groupMembers[_groupMember].name = _name;
        groupMembers[_groupMember].amountPaid = 0;
        groupMembers[_groupMember].confirmedSplit = false;
        memberAddresses.push( _groupMember);
    }

    //Admin removes member from the group -- this leaves the array unordered (which shouldn't matter, as array was unordered to begin with)
    function removeFromGroup(address _groupMember) public isAdmin {
        for(uint i = 0; i < memberAddresses.length; i++){
            if(memberAddresses[i] == _groupMember){
                memberAddresses[i] = memberAddresses[memberAddresses.length - 1];
                memberAddresses.pop();
                emit memberRemoved(_groupMember, groupMembers[_groupMember].name);
                break;
            }
        }
    }

    //A user claims that they have paid this much. The split is updated. Everyone's confirmed split parameters are set to false. 
    //Add a value onto the currently saved paid amount (IE you bought an additional item for the group). Amount starts at 0 for everyone
    function addToPaid(int _valuePaid) external isGroupMember {
        groupMembers[msg.sender].amountPaid += _valuePaid;
        for(uint i = 0; i < memberAddresses.length; i++ ){
            groupMembers[memberAddresses[i]].confirmedSplit = false;
        }
        updateSplitCalculation();
    }

    //calculate how much each member owes or is owed.
    function updateSplitCalculation() internal {
        int averagePaid;
        for(uint i = 0; i < memberAddresses.length; i++ ){
            averagePaid += groupMembers[memberAddresses[i]].amountPaid;
        }
        averagePaid = averagePaid / int(memberAddresses.length);
        for(uint i = 0; i < memberAddresses.length; i++ ){
            groupMembers[memberAddresses[i]].owes = averagePaid - groupMembers[memberAddresses[i]].amountPaid;
        }
    }

    //emit events that say how much everyone owes or is owed.
    function printSplit() public {
        string memory exchangeType;
        for(uint i = 0; i < memberAddresses.length; i++ ){
            if(groupMembers[memberAddresses[i]].owes >= 0){
                exchangeType = "will pay";
            }
            else{
                exchangeType = "will receive";
            }
            emit newSplit(groupMembers[memberAddresses[i]].name, exchangeType, abs(groupMembers[memberAddresses[i]].owes));
        }
    }

    //each user confirms that they agree to the current split.
    function agreeToSplit() external isGroupMember{
        //Everyone must agree to the split before you can settle up.
        groupMembers[msg.sender].confirmedSplit = true;
    }

    mapping(address => int) public balances;

    //Members are able to put money into the contract
    function putMoneyInContract() external payable isGroupMember everyoneAgreesToSplit{
        if(msg.value != uint(abs(groupMembers[msg.sender].owes)) || groupMembers[msg.sender].owes <= 0){
            revert();
        }
        balances[msg.sender] += int(msg.value);
    }

    //If everyone agrees to split and everyone who owes has paid, funds are sent to those who are owed. 
    //Just trust that this works for now as this is untested on a testnet hahahha
    function settleUp() external everyoneAgreesToSplit allPaid{
        address payable payableAddr;
        for(uint i = 0; i < memberAddresses.length; i++){
            if(groupMembers[memberAddresses[i]].owes < 0){
                payableAddr = payable(memberAddresses[i]);
                payableAddr.transfer(uint(abs(groupMembers[memberAddresses[i]].owes))); //Transfer what they are owed to their account.
            }
        }
        //reset all balances to 0
        for(uint i = 0; i< memberAddresses.length; i++){
            balances[memberAddresses[i]] = 0;
            groupMembers[memberAddresses[i]].confirmedSplit = false;
            groupMembers[memberAddresses[i]].amountPaid = 0;
            groupMembers[memberAddresses[i]].owes = 0;
        }
    }

    //Return all funds that have been paid to original recipients (used after money is put in but before settle up).
    function sendAllMoneyBack() external isAdmin{
        for(uint i = 0; i < memberAddresses.length; i++ ){
            address payable payableAddr;
            if(balances[memberAddresses[i]] > 0){
                payableAddr = payable(memberAddresses[i]);
                payableAddr.transfer(uint(balances[memberAddresses[i]]));
                balances[memberAddresses[i]] = 0;
            }
            groupMembers[memberAddresses[i]].confirmedSplit = false;
        }
    }

    //Changes the admin
    function changeAdmin(address _newAdmin) public isAdmin {
        emit AdminSet(groupAdmin, _newAdmin);
        groupAdmin = _newAdmin;
    }
}
