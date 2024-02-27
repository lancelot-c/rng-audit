// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.23;

import "chainlink/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol"; // ChainLink VRF
import "chainlink/src/v0.8/vrf/VRFConsumerBaseV2.sol"; // ChainLink VRF
import "chainlink/src/v0.8/shared/access/ConfirmedOwner.sol"; // Ownership

contract OnlyRaw is VRFConsumerBaseV2, ConfirmedOwner {

    VRFCoordinatorV2Interface private COORDINATOR;
    address private vrfCoordinator = 0x50d47e4142598E3411aA864e08a44284e471AC6f;
    bytes32 private keyHash = 0x027f94ff1465b3525f9fc03e9ff7d6d2c0953482246dd6ae07570c45d6631414;
    uint64 private s_subscriptionId = 88; // Subscription URL: https://vrf.chain.link/arbitrum-sepolia/88
    uint32 private callbackGasLimit = 2500000;
    uint16 private requestConfirmations = 1; // Number of confirmation blocks on VRF requests before oracles respond
    uint32 public vrfCounter = 0; // Track the number of fulfilled VRF requests
    uint32 public wordsCounter = 0; // Track the number of fulfilled random words

    mapping(uint32 => bytes) public collectedEntropy;

    constructor ()
        VRFConsumerBaseV2(vrfCoordinator)
        ConfirmedOwner(msg.sender)
    {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    }

    /**
    * @notice Make a VRF request
    * @param numWords - Number of random words to ask for
    */
    function makeVrfRequest(uint32 numWords)
        public
    {

        COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
 
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {

        vrfCounter++;
        wordsCounter += uint32(_randomWords.length);

        collectedEntropy[vrfCounter] = abi.encodePacked(_randomWords);
    }
}