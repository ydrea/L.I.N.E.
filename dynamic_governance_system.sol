// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract DynamicLINE {
    // Current parameters
    uint256 public legacyPreservation = 20; // Default 20%
    uint256 public decayRate = 15;          // Default 15% per window
    uint256 public activityWindow = 90 days;

    // Governance state
    struct Proposal {
        uint256 id;
        string description;
        uint256 newLegacy;
        uint256 newDecay;
        uint256 newWindow;
        uint256 voteEnd;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
    }
    
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public delegatedVotingPower;
    uint256 public proposalCount;
    
    // Events
    event ProposalCreated(uint256 id, string description);
    event Voted(uint256 proposalId, address voter, bool support, uint256 power);
    event ParametersChanged(uint256 newLegacy, uint256 newDecay, uint256 newWindow);

    // Governance functions
    function createProposal(
        string memory description,
        uint256 newLegacy,
        uint256 newDecay,
        uint256 newWindowDays,
        uint256 votingDays
    ) external {
        require(newLegacy <= 50, "Legacy too high");
        require(newDecay <= 30, "Decay too aggressive");
        
        proposalCount++;
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            description: description,
            newLegacy: newLegacy,
            newDecay: newDecay,
            newWindow: newWindowDays * 1 days,
            voteEnd: block.timestamp + votingDays * 1 days,
            forVotes: 0,
            againstVotes: 0,
            executed: false
        });
        
        emit ProposalCreated(proposalCount, description);
    }

    function vote(uint256 proposalId, bool support) external {
        Proposal storage p = proposals[proposalId];
        require(block.timestamp < p.voteEnd, "Voting ended");
        
        uint256 power = _getVotingPower(msg.sender);
        if (support) {
            p.forVotes += power;
        } else {
            p.againstVotes += power;
        }
        
        emit Voted(proposalId, msg.sender, support, power);
    }

    function executeProposal(uint256 proposalId) external {
        Proposal storage p = proposals[proposalId];
        require(block.timestamp >= p.voteEnd, "Voting ongoing");
        require(!p.executed, "Already executed");
        require(p.forVotes > p.againstVotes, "Proposal failed");
        
        legacyPreservation = p.newLegacy;
        decayRate = p.newDecay;
        activityWindow = p.newWindow;
        p.executed = true;
        
        emit ParametersChanged(p.newLegacy, p.newDecay, p.newWindow);
    }

    // Voting power based on current contribution score
    function _getVotingPower(address user) internal view returns (uint256) {
        return userBalance[user]; // Or use sqrt(userBalance) for quadratic voting
    }

    // Delegation system
    function delegateVotingPower(address to) external {
        delegatedVotingPower[msg.sender] = _getVotingPower(msg.sender);
    }
}
