//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Crowd_funding {
    address public admin;
    mapping(address => uint) public contributors;
    uint public noOfContributors;
    uint public minContribution;
    uint public deadline;
    uint public goal;
    uint public raisedAmount;
    struct Request {
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfvoters;
        mapping(address => bool) voters;
    }
    mapping(uint => Request) public requests;
    uint numOfRequests;

    constructor(uint _goal, uint _deadline){
        goal = _goal;
        deadline = block.timestamp + _deadline;
        admin = msg.sender;
        minContribution = 100 wei;
    }


    event ContributeEvent(address _sender, uint _value);
    event createRequestEvent(string _description, address _recipient, uint _value);
    event makepaymentEvent(address _recipient, uint _value);


    function contribute() public payable {
        require(block.timestamp < deadline, "Deadline has passed");
        require(msg.value >= minContribution, "Amount less than the minimum requirement");

        if (contributors[msg.sender] == 0) {
            noOfContributors += 1;
        }

        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;

        emit ContributeEvent(msg.sender, msg.value);
    }

    receive() payable external {
        contribute();
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function getRefund() public {
        require(block.timestamp > deadline && raisedAmount < goal);
        require(contributors[msg.sender] > 0);
        payable(msg.sender).transfer(contributors[msg.sender]);
        contributors[msg.sender] = 0;
    }

    modifier OnlyAdmin() {
        require(msg.sender == admin,"Only admin can call this function");
        _;
    }

    function createRequest(string memory _description, address payable _recipient, uint _value) public OnlyAdmin {
        Request storage newRequest = requests[numOfRequests];
        numOfRequests++;
        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.noOfvoters = 0;

        emit createRequestEvent(_description, _recipient, _value);
    }

    function voteRequest(uint _RequestNo) public {
        require(contributors[msg.sender] > 0);
        Request storage thisRequest = requests[_RequestNo];
        require(thisRequest.voters[msg.sender] == false, "You have already voted");
        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfvoters++;
    }

    function makepayment(uint _requestNo) public OnlyAdmin{
        require(raisedAmount >= goal);
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.completed == false, "this request has been completed");
        require(thisRequest.noOfvoters > noOfContributors / 2); // to get 50% acceptance 
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;

        emit makepaymentEvent(thisRequest.recipient, thisRequest.value);
    }
}
