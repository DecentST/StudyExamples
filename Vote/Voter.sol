// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.5.0/contracts/access/Ownable.sol';
/**
 * @title SVoting
 */
contract Voting is Ownable {

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }
    struct Proposal {
        string description;
        uint voteCount;
    }
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);

    address private _admin;
    uint public winningProposalId;
    mapping(address=> bool) private _whitelist;
    mapping(address => Voter) public voters;
    WorkflowStatus public currentStatus = WorkflowStatus.RegisteringVoters;
    Proposal[] public proposals;

    //old admin restricted modifier, commented in favor of Ownable OpenZeppelin lib
    //constructor () {      
        //_admin = msg.sender;      
    //}
    //modifier onlyAdmin() {
        //require(msg.sender == _admin);
        //_;
    //} 

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender), "User not whitelisted");
        _;
    }

    modifier withStatus(WorkflowStatus _status) {
        require(currentStatus == _status, "Wrong status");
        _;
    }

    function addProposal (string memory _description) public onlyWhitelisted withStatus(WorkflowStatus.ProposalsRegistrationStarted) {
        proposals.push(Proposal(_description, 0));
    }

    function startProposalRegistration() public onlyOwner withStatus(WorkflowStatus.RegisteringVoters) {
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
        currentStatus = WorkflowStatus.ProposalsRegistrationStarted;
    }

    function endProposalRegistration() public onlyOwner withStatus(WorkflowStatus.ProposalsRegistrationStarted) {
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
        currentStatus = WorkflowStatus.ProposalsRegistrationEnded;
    }

    function startVote() public onlyOwner withStatus(WorkflowStatus.ProposalsRegistrationEnded){
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
        currentStatus = WorkflowStatus.VotingSessionStarted;
    }

    function endVote() public onlyOwner withStatus(WorkflowStatus.VotingSessionStarted){
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
        currentStatus = WorkflowStatus.VotingSessionEnded;
    }
 
    function whitelist(address _address) public onlyOwner withStatus(WorkflowStatus.RegisteringVoters) {
      require(!_whitelist[_address], "Already whitelisted");
      _whitelist[_address] = true;
    }
 
    function isWhitelisted(address _address) public view returns (bool){
      return _whitelist[_address];
    }

    function vote(uint _proposalNum) external onlyWhitelisted withStatus(WorkflowStatus.VotingSessionStarted){
        Voter storage sender = voters[msg.sender];
        require(!sender.hasVoted, "Already voted");
        sender.hasVoted = true;
        sender.votedProposalId = _proposalNum;
        proposals[_proposalNum].voteCount += 1;
        emit Voted(msg.sender, _proposalNum);
    }

    function tallyVotes() public onlyOwner withStatus(WorkflowStatus.VotingSessionEnded){
        currentStatus = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);

        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposalId = p;
            }
        }
    }
    //Not sure if needed as `winningProposalId` is public
    function getWinner() public view withStatus(WorkflowStatus.VotesTallied) returns (uint) {
        return winningProposalId;
    }
}