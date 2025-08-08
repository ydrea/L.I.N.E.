// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract LINEProtocol {
    using SafeMath for uint256;
    
    uint256 public constant BASE_GROWTH = 4; // 4% annual growth
    uint256 public constant ACTIVITY_WINDOW = 365 days;
    
    struct Member {
        uint256 contributionScore;
        uint256 lastActivity;
        bool isFounder;
    }
    
    mapping(address => Member) public members;
    uint256 public totalValueUnits;

    // ========================
    // Logarithmic Decay Logic
    // ========================
    function _applyLogarithmicDecay(address member) internal {
        Member storage m = members[member];
        uint256 periodsInactive = (block.timestamp - m.lastActivity) / ACTIVITY_WINDOW;
        
        if (periodsInactive > 0) {
            uint256 decayedScore = _logarithmicDecay(
                m.contributionScore,
                periodsInactive
            );
            
            totalValueUnits -= (m.contributionScore - decayedScore);
            m.contributionScore = decayedScore;
        }
    }

    function log2(uint256 x) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (x >= 2**128) { x >>= 128; result += 128; }
            if (x >= 2**64) { x >>= 64; result += 64; }
            if (x >= 2**32) { x >>= 32; result += 32; }
            if (x >= 2**16) { x >>= 16; result += 16; }
            if (x >= 2**8) { x >>= 8; result += 8; }
            if (x >= 2**4) { x >>= 4; result += 4; }
            if (x >= 2**2) { x >>= 2; result += 2; }
            if (x >= 2**1) { result += 1; }
        }
        return result;
    }

    function _logarithmicDecay(uint256 score, uint256 periods) internal pure returns (uint256) {
        return score / log2(periods + 2); // +2 to avoid log(1)=0
    }

    // ========================
    // Participation Logic
    // ========================
    function participate() external payable {
        Member storage m = members[msg.sender];
        
        // Apply growth annually
        if (block.timestamp % 365 days == 0) {
            totalValueUnits += (totalValueUnits * BASE_GROWTH) / 100;
        }

        // Apply logarithmic decay if inactive
        _applyLogarithmicDecay(msg.sender);

        // Update member
        m.contributionScore += msg.value;
        m.lastActivity = block.timestamp;
        totalValueUnits += msg.value;
    }
}
