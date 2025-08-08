// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Laterally Integrated Network Enterprise (L.I.N.E.)
 * @dev A Decentralized Cooperative Enterprise with:
 * - Dynamic ownership based on continuous participation
 * - Value decay for inactive members
 * - Automatic profit redistribution
 */
contract LINEProtocol {
    // Struct to track member activity and ownership
    struct Member {
        uint256 contributionScore; // Dynamic ownership units
        uint256 lastActivity;      // Timestamp of last participation
        uint256 claimedRewards;    // Lifetime rewards claimed
        bool exists;
    }

    // Protocol Parameters
    uint256 public constant BASE_GROWTH = 4;    // 4% annual baseline growth
    uint256 public constant DECAY_RATE = 10;    // 10% annual decay if inactive
    uint256 public constant ACTIVITY_WINDOW = 90 days; // Must participate quarterly
    
    // State
    mapping(address => Member) public members;
    address[] public memberList;
    uint256 public totalValueUnits; // Total ownership units in circulation
    
    // Events
    event Participation(address indexed member, uint256 valueAdded);
    event OwnershipAdjusted(address indexed member, uint256 newScore);
    event RewardDistributed(address indexed member, uint256 amount);

    // Core Participation Function
    function participate(uint256 valueContributed) external payable {
        // Initialize new members
        if (!members[msg.sender].exists) {
            members[msg.sender] = Member(0, block.timestamp, 0, true);
            memberList.push(msg.sender);
        }
        
        Member storage m = members[msg.sender];
        
        // Apply decay if inactive
        if (block.timestamp > m.lastActivity + ACTIVITY_WINDOW) {
            uint256 decayPeriods = (block.timestamp - m.lastActivity) / ACTIVITY_WINDOW;
            uint256 decayFactor = 10**18;
            
            for (uint i = 0; i < decayPeriods; i++) {
                decayFactor = decayFactor * (100 - DECAY_RATE) / 100;
            }
            
            m.contributionScore = m.contributionScore * decayFactor / 10**18;
        }
        
        // Add new contribution (1:1 minting for active participants)
        uint256 addedUnits = valueContributed + msg.value;
        m.contributionScore += addedUnits;
        totalValueUnits += addedUnits;
        
        // Update activity tracker
        m.lastActivity = block.timestamp;
        
        emit Participation(msg.sender, addedUnits);
    }

    // Automatic Reward Distribution
    function distributeRewards() external {
        uint256 rewardPool = address(this).balance;
        require(rewardPool > 0, "No rewards to distribute");
        
        // Apply baseline growth (4% annualized)
        uint256 growthUnits = totalValueUnits * BASE_GROWTH / 100 / (365 days / ACTIVITY_WINDOW);
        totalValueUnits += growthUnits;
        
        // Distribute rewards proportionally
        for (uint i = 0; i < memberList.length; i++) {
            address member = memberList[i];
            Member storage m = members[member];
            
            if (m.contributionScore > 0) {
                uint256 share = (m.contributionScore * rewardPool) / totalValueUnits;
                
                if (share > 0) {
                    payable(member).transfer(share);
                    m.claimedRewards += share;
                    emit RewardDistributed(member, share);
                }
            }
        }
    }

    // Value Decay Mechanism (Callable by anyone for inactive members)
    function applyDecay(address member) external {
        Member storage m = members[member];
        require(block.timestamp > m.lastActivity + ACTIVITY_WINDOW, "Member still active");
        
        uint256 decayedUnits = m.contributionScore * DECAY_RATE / 100;
        m.contributionScore -= decayedUnits;
        totalValueUnits -= decayedUnits;
        
        emit OwnershipAdjusted(member, m.contributionScore);
    }
}
