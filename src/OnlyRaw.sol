// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.23;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol"; // ChainLink VRF
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol"; // ChainLink VRF
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol"; // Ownership

contract OnlyRaw is VRFConsumerBaseV2, ConfirmedOwner {

    event RandomnessFulfilled(uint32 counter, bytes totalEntropy);

    VRFCoordinatorV2Interface COORDINATOR;
    uint64 private s_subscriptionId;
    address vrfCoordinator = 0x50d47e4142598E3411aA864e08a44284e471AC6f;
    bytes32 keyHash = 0x027f94ff1465b3525f9fc03e9ff7d6d2c0953482246dd6ae07570c45d6631414;
    uint32 callbackGasLimit = 2500000;
    uint32 numWords = 500; // numWords should be <= 500, see https://sepolia.arbiscan.io/address/0x50d47e4142598e3411aa864e08a44284e471ac6f#code#F18#L80
    uint32 public counter = 0; // Track the number of fulfilled VRF requests

    mapping(uint32 => bytes) public collectedEntropy;

    constructor (
        uint64 subscriptionId
    )
        VRFConsumerBaseV2(vrfCoordinator)
        ConfirmedOwner(msg.sender)
    {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
    }

    function getEntropy(uint32 at) external view returns (bytes) {
        return collectedEntropy[at];
    }

    function getCounter() external view returns (uint32) {
        return counter;
    }

    function increment() private {
        counter++;
    }

    // requestConfirmations should be <= 200, see https://sepolia.arbiscan.io/address/0x50d47e4142598e3411aa864e08a44284e471ac6f#code#F18#L79
    function makeChainlinkVRFRequests(uint32 nbRequests, uint requestConfirmations)
        external
    {

        for (uint32 i = 0; i < nbRequests; i++) {
-
            COORDINATOR.requestRandomWords(
                keyHash,
                s_subscriptionId,
                requestConfirmations,
                callbackGasLimit,
                numWords
            );

        }
 
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {

        increment();

        bytes memory totalEntropy = abi.encodePacked(_randomWords);
        collectedEntropy[counter] = totalEntropy;

        emit RandomnessFulfilled(counter, totalEntropy);
    }
}
