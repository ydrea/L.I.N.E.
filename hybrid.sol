// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FairDecayDAO {
    struct Contribution {
        uint256 amount;
        uint256 timestamp;
        bool isActive;
    }
    
    // Configurable parameters
    uint256 public constant BASE_GROWTH = 4; // 4% annual growth
    uint256 public constant ACTIVITY_WINDOW = 90 days;
    uint256 public constant LEGACY_PRESERVATION = 20; // 20% preserved forever
    uint256 public constant DECAY_RATE = 15; // 15% per window for non-legacy
    
    mapping(address => Contribution[]) public contributions;
    uint256 public totalValueUnits;

    // Applies dual-phase decay: partial decay + eternal vesting
    function _applyFairDecay(address user) internal {
        Contribution[] storage userContribs = contributions[user];
        uint256 newTotal = 0;
        
        for (uint256 i = 0; i < userContribs.length; i++) {
            Contribution memory c = userContribs[i];
            uint256 elapsedPeriods = (block.timestamp - c.timestamp) / ACTIVITY_WINDOW;
            
            if (elapsedPeriods > 0 && c.isActive) {
                // Phase 1: Standard decay on non-legacy portion
                uint256 decayable = c.amount * (100 - LEGACY_PRESERVATION) / 100;
                for (uint256 j = 0; j < elapsedPeriods; j++) {
                    decayable = (decayable * (100 - DECAY_RATE)) / 100;
                }
                
                // Phase 2: Permanent legacy preservation
                uint256 legacy = c.amount * LEGACY_PRESERVATION / 100;
                userContribs[i].amount = decayable + legacy;
                userContribs[i].timestamp = block.timestamp;
            }
            newTotal += userContribs[i].amount;
        }
        
        // Update global totals
        totalValueUnits -= (getUserTotal(user) - newTotal);
    }

    // Gets current value including decay calculations
    function getUserTotal(address user) public view returns (uint256) {
        uint256 total;
        Contribution[] memory userContribs = contributions[user];
        
        for (uint256 i = 0; i < userContribs.length; i++) {
            Contribution memory c = userContribs[i];
            uint256 elapsedPeriods = (block.timestamp - c.timestamp) / ACTIVITY_WINDOW;
            
            if (elapsedPeriods > 0 && c.isActive) {
                uint256 decayable = c.amount * (100 - LEGACY_PRESERVATION) / 100;
                uint256 legacy = c.amount * LEGACY_PRESERVATION / 100;
                total += (decayable * (100 - DECAY_RATE)**elapsedPeriods) / (100**elapsedPeriods);
                total += legacy;
            } else {
                total += c.amount;
            }
        }
        return total;
    }
}
