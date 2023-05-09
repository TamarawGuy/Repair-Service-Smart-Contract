// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract HomeRepairService {
    struct RepairRequest {
        address repairOwner;
        string description;
        uint payment;
        bool exists;
        bool accepted;
        bool paid;
        bool confirmed;
        bool repaired;
        bool verified;
        uint verificationCount;
        uint lastVerifiedTime;
    }

    address public immutable admin;
    address public repairer = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2; // second account in remix
    mapping(address => bool) public auditors; // owner will add auditors manually 
    mapping(uint => RepairRequest) public repairRequests;

    modifier onlyAdmin(){
        require(msg.sender == admin, "Only Admin can use this function");
        _;
    }

    modifier onlyAuditor() {
        require(auditors[msg.sender] == true, "Only auditors can use this function");
        _;
    }

    modifier onlyRepairer() {
        require(msg.sender == repairer, "Only repairer can use this function");
        _;
    }

    modifier repairExists(uint _id) {
        require(repairRequests[_id].exists, "Repair request does not exist");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    // function, to repair a request by repairer (added by me)
    function repair(uint _id) external onlyRepairer{
        require(repairRequests[_id].exists == true, "Repair request does not exist");
        require(repairRequests[_id].accepted == true, "Repair request not accepted");
        require(repairRequests[_id].paid == true, "Repair request is not paid");
        repairRequests[_id].repaired = true;
    }

    // function when admin can add auditors to mapping (added by me)
    function addAuditor(address auditor) external onlyAdmin {
        auditors[auditor] = true;
    }


    function addRepair(uint _id, string memory _description) external {
        repairRequests[_id] = RepairRequest({
            repairOwner: msg.sender,
            description: _description,
            payment: 0,
            accepted: false,
            confirmed: false,
            paid: false,
            repaired: false,
            verified: false,
            exists: true,
            verificationCount: 0,
            lastVerifiedTime: 0
        });
    }

    function acceptRepairRequest(uint _id) external payable onlyAdmin repairExists(_id) {
        require(!repairRequests[_id].accepted, "Repair request has already been accepted");
        repairRequests[_id].accepted = true;
        repairRequests[_id].payment = msg.value;
    }

    function addPayment(uint _id) external payable repairExists(_id) {
        require(repairRequests[_id].repairOwner == msg.sender, "Not owner of repair request");
        require(repairRequests[_id].accepted, "Repair request not accepted");
        require(repairRequests[_id].payment == msg.value, "Incorrect payment amount");
        repairRequests[_id].paid = true;
    }

    function confirmRepairRequest(uint _id) external onlyAdmin repairExists(_id) {
        require(repairRequests[_id].paid, "Repair request is not paid");
        require(repairRequests[_id].repaired, "Repair request is not paid");
        repairRequests[_id].confirmed = true;
    }

    function verifyIfJobDone(uint _id) external onlyAuditor repairExists(_id) {
        require(repairRequests[_id].repaired, "Repair request is not paid");
        repairRequests[_id].verified = true;
        repairRequests[_id].verificationCount++;
    }

    function executeRepairRequest(uint _id, address payable _repairReceiver, uint amount) external onlyAuditor repairExists(_id) {
        require(repairRequests[_id].verificationCount >= 2, "Has to be audited by at least 2 auditors");
        require(address(this).balance >= amount, "Contract doesn't have enough balance to send Ether");
        _repairReceiver.transfer(amount);
    }

    function moneyBack(uint _id) external repairExists(_id) {
        require(block.timestamp >= repairRequests[_id].lastVerifiedTime + 30 days, "Less than 30 days have passed");
        payable(msg.sender).transfer(repairRequests[_id].payment);
    }
}