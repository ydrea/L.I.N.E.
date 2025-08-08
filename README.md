# a capitalism hack – Laterally Integrated Network Enterprise (L.I.N.E.)

The issue you need to solve is – inadequate accumulation of wealth. This issue is caused by a bug in capitalism, that enables the wealthy (‘capitalists’) to become increasingly wealthier, while everyone else goes poorer. 
Obviously, the imbalance of wealth is causing the imbalance of power - in capitalism, if you are not the owner, the only power you posses is your working time, so when you sell that to a corporation, what are you left with? 

Luckily, there is a virus that can neutralise this bug – and this virus is a publicly traded company! 

Now, you are probably wondering how can another company be a virus designed to hack the capitalism?

The response is simple – it belongs to You and I! Really, it belongs to everyone who chooses to either generate income for this company (by purchasing its goods, or paying for its services), or create added value to it (by offering goods or services through this company). The value traded is automatically converted into a percentage of ownership, so no one gets wealthy, but everyone who decides to partake gets richer. 

The mechanism for assigning/claiming the value is an open-source blockchain algorithm, describing a Decentralized Cooperative Enterprise that uses blockchain-based value accounting to assign ownership dynamically to contributors and consumers — ie. a kind of “anti-capitalist capitalist” Decentralised Autonomous Organisation (DAO) — a mechanism that rewards value-creation and participation directly, rather than hoarding ownership, as presented in the table below:


## DAO comparison table 

|                     | Typical Crypto DAO                       | L.I.N.E. DAO                                  |
|---------------------|------------------------------------------|-----------------------------------------------|
| Ownership           | Often based on capital (buy tokens)      | Based on contribution (value created)         |
| Power Accumulation  | Wealthy participants can dominate        | Power decays without continued contribution   |
| Profit Distribution | Optional                                 | Central to the model — shared by contributors |
| Accessibility       | High barrier (capital or network needed) | Low — anyone can join by participating        |
| Ideology            | Market-driven                            | Value-driven, anti-hoarding                   |


## blockchain algorithm

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CooperativeOwnership {
    // Struct to track contributor information
    struct Contributor {
        uint256 totalContributed;  // Total ETH contributed by this address
        uint256 lastUpdated;      // Timestamp of last contribution/growth application
        bool exists;              // Flag indicating if this contributor exists
    }

    // Storage mappings
   mapping(address => Contributor) public contributors;  // Contributor data by address
   address[] public contributorList;                    // List of all contributor addresses

    // Growth parameters (replaces decay parameters)
   uint256 public totalContributions = 0;       // Total ETH contributed system-wide
   uint256 public growthRate = 4;               // 4% annual growth (fixed-point)
   uint256 public growthInterval = 365 days;    // Time between growth applications
   uint256 public lastGrowthTimestamp;          // Last time growth was applied globally

    // Events
   event ContributionReceived(address indexed user, uint256 amount);
   event ProfitsDistributed(uint256 totalAmount);
   event GrowthApplied(uint256 newTotal);

    // Modifier to check if contributor exists
   modifier onlyExisting(address user) {
        require(contributors[user].exists, "Contributor not found");
        _;
    }

    // Initialize last growth timestamp to contract creation
   constructor() {
     lastGrowthTimestamp = block.timestamp;
    }

    // ========================
    // Core Growth Functionality
    // ========================

    // Applies compound growth to the total contributions
  function _applyGrowth() internal {
        uint256 elapsed = block.timestamp - lastGrowthTimestamp;
        
        // Only proceed if full growth interval has passed
   if (elapsed >= growthInterval) {
            uint256 periods = elapsed / growthInterval;
            
            // Calculate growth factor (1.04^periods)
   uint256 growthFactor = 10**18; // 1.0 in fixed-point
            for (uint256 i = 0; i < periods; i++) {
                growthFactor = growthFactor * (100 + growthRate) / 100;
            }
            
            // Apply growth to total contributions
   uint256 newTotal = (totalContributions * growthFactor) / 10**18;
            uint256 growthAmount = newTotal - totalContributions;
            
   totalContributions = newTotal;
   lastGrowthTimestamp += periods * growthInterval;
            
   emit GrowthApplied(totalContributions);
        }
    }

    // Applies growth to an individual contributor's balance
   function _applyIndividualGrowth(address user) internal onlyExisting(user) {
        Contributor storage c = contributors[user];
        uint256 elapsed = block.timestamp - c.lastUpdated;
        
   if (elapsed >= growthInterval) {
            uint256 periods = elapsed / growthInterval;
            uint256 growthFactor = 10**18;
            
   for (uint256 i = 0; i < periods; i++) {
                growthFactor = growthFactor * (100 + growthRate) / 100;
            }
            
   uint256 newBalance = (c.totalContributed * growthFactor) / 10**18;
   uint256 growthAmount = newBalance - c.totalContributed;
            
   c.totalContributed = newBalance;
    c.lastUpdated += periods * growthInterval;
        }
    }

    // ===================
    // User-Facing Functions
    // ===================

    // Record a new contribution
  function contribute() external payable {
        require(msg.value > 0, "Contribution must be positive");
        
        // Initialize new contributor if needed
  if (!contributors[msg.sender].exists) {
            contributors[msg.sender] = Contributor(0, block.timestamp, true);
            contributorList.push(msg.sender);
        }
        
        // Apply growth before updating balances
   _applyGrowth();
   _applyIndividualGrowth(msg.sender);
       
        // Update balances
   contributors[msg.sender].totalContributed += msg.value;
   contributors[msg.sender].lastUpdated = block.timestamp;
   totalContributions += msg.value;
        
   emit ContributionReceived(msg.sender, msg.value);
    }

    // View ownership percentage (in 1e18 fixed-point)
   function getShare(address user) public view returns (uint256) {
        if (totalContributions == 0) return 0;
        return (contributors[user].totalContributed * 1e18) / totalContributions;
    }

    // Distribute contract balance as profits
   function distributeProfits() external {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to distribute");
        
        // Apply growth to all before distribution
   _applyGrowth();
   for (uint256 i = 0; i < contributorList.length; i++) {
            _applyIndividualGrowth(contributorList[i]);
        }
        
        // Distribute according to shares
   for (uint256 i = 0; i < contributorList.length; i++) {
            address user = contributorList[i];
            uint256 share = getShare(user);
            uint256 payout = (share * balance) / 1e18;
            
   if (payout > 0) {
                payable(user).transfer(payout);
            }
        }
        
   emit ProfitsDistributed(balance);
    }

    // Manual trigger for growth application
   function applyGrowth() external {
        _applyGrowth();
        for (uint256 i = 0; i < contributorList.length; i++) {
            _applyIndividualGrowth(contributorList[i]);
        }
    }

    // Fallback function to accept ETH
   receive() external payable {
        contribute();
    }
}
