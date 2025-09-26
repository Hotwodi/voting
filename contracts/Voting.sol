// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Voting is Ownable, ReentrancyGuard {
    struct Poll {
        string title;
        bool open;
        uint256 totalVotes;
        mapping(uint256 => uint256) votes; // optionId => count
        mapping(address => bool) voted;
        string[] options;
    }

    Poll[] public polls;

    event PollCreated(uint256 indexed pollId, string title);
    event OptionAdded(uint256 indexed pollId, uint256 optionId, string option);
    event VoteCast(uint256 indexed pollId, uint256 optionId, address indexed voter);
    event PollClosed(uint256 indexed pollId);

    function createPoll(string calldata title, string[] calldata options) external onlyOwner returns (uint256) {
        Poll storage p = polls.push();
        p.title = title;
        p.open = true;
        for (uint i = 0; i < options.length; i++) {
            p.options.push(options[i]);
            emit OptionAdded(polls.length - 1, i, options[i]);
        }
        emit PollCreated(polls.length - 1, title);
        return polls.length - 1;
    }

    function vote(uint256 pollId, uint256 optionId) external nonReentrant {
        require(pollId < polls.length, "Invalid poll");
        Poll storage p = polls[pollId];
        require(p.open, "Poll closed");
        require(!p.voted[msg.sender], "Already voted");
        require(optionId < p.options.length, "Invalid option");

        p.votes[optionId] += 1;
        p.totalVotes += 1;
        p.voted[msg.sender] = true;

        emit VoteCast(pollId, optionId, msg.sender);
    }

    function closePoll(uint256 pollId) external onlyOwner {
        require(pollId < polls.length, "Invalid poll");
        Poll storage p = polls[pollId];
        p.open = false;
        emit PollClosed(pollId);
    }

    function getOptions(uint256 pollId) external view returns (string[] memory) {
        require(pollId < polls.length, "Invalid poll");
        return polls[pollId].options;
    }

    function getVotes(uint256 pollId, uint256 optionId) external view returns (uint256) {
        require(pollId < polls.length, "Invalid poll");
        return polls[pollId].votes[optionId];
    }

    function getTotalVotes(uint256 pollId) external view returns (uint256) {
        require(pollId < polls.length, "Invalid poll");
        return polls[pollId].totalVotes;
    }
}
