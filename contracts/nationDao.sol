// SPDX-License-Identifier: AGPL-3.0-or-later
// Code written and documented by Venki - https://github.com/metadimensions

pragma solidity ^0.8.8;

import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {ERC721EnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IDAO } from "@aragon/osx/core/dao/IDAO.sol";


contract NationDao is Initializable, AccessControlUpgradeable {
    ERC721EnumerableUpgradeable public nation3NFT;
    IDAO public dao;

    bytes32 public constant PROPOSAL_CREATOR_ROLE = keccak256("PROPOSAL_CREATOR_ROLE");
    bytes32 public constant UPDATE_SETTINGS_PERMISSION_ID = keccak256("UPDATE_SETTINGS_PERMISSION");
    bytes32 public constant CREATE_PROPOSAL_PERMISSION_ID = keccak256("CREATE_PROPOSAL_PERMISSION");
    bytes32 public constant EXECUTE_ACTION_PERMISSION_ID = keccak256("EXECUTE_ACTION_PERMISSION");
    bytes32 public constant NFT_VOTING_PERMISSION_ID = keccak256("NFT_VOTING_PERMISSION");
    bytes32 public constant NFT_MANAGEMENT_PERMISSION_ID = keccak256("NFT_MANAGEMENT_PERMISSION");
    bytes32 public constant ADMIN_CONTROL_PERMISSION_ID = keccak256("ADMIN_CONTROL_PERMISSION");


    struct Proposal {
        address creator;
        string description;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) hasVoted;
        mapping(uint256 => bool) votes;
    }

    uint256 private proposalCount;
    uint256 public defaultVotingDuration;
    mapping(uint256 => Proposal) public proposals;

    event ProposalCreated(uint256 indexed proposalId, address indexed creator);
    event VoteCast(address indexed voter, uint256 indexed proposalId, bool support, uint256 balance);

    event ProposalFinalized(uint256 indexed proposalId, bool approved);
    

    function initialize(address _nation3NFT, address _dao, uint256 _defaultVotingDuration) public initializer {
        require(_nation3NFT != address(0), "Nation3 NFT address cannot be the zero address");
        require(_dao != address(0), "DAO address cannot be the zero address");

        __AccessControl_init();
         _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        nation3NFT = ERC721EnumerableUpgradeable(_nation3NFT);
        dao = IDAO(_dao);
        defaultVotingDuration = _defaultVotingDuration;
    }

    function vote(uint256 proposalId, bool support, address voter) public {
        require(canVote(proposalId, voter), "Voter cannot vote on this proposal");

        Proposal storage proposal = proposals[proposalId];
        uint256 balance = nation3NFT.balanceOf(voter);
        
        for(uint256 i = 0; i < balance; ++i) {
            uint256 tokenId = nation3NFT.tokenOfOwnerByIndex(voter, i);
            require(!proposal.votes[tokenId], "Already voted with this NFT");
            proposal.votes[tokenId] = support;
        }

        emit VoteCast(voter, proposalId, support, balance);
    }
    
    // function to get the votes to be gettingVoted with that functions expected 
    function getVotes(uint256 proposalId) public view returns (uint256 yesVotes, uint256 noVotes) {
        Proposal storage proposal = proposals[proposalId];
        uint256 totalSupply = nation3NFT.totalSupply();

        for (uint256 tokenId = 0; tokenId < totalSupply; ++tokenId) {
            if (nation3NFT.ownerOf(tokenId) != address(0)) {
                if (proposal.votes[tokenId]) yesVotes++;
                else noVotes++;
            }
        }
    }

    // function to createproposal 

    function createProposal(string memory _description) external onlyRole(PROPOSAL_CREATOR_ROLE) returns (uint256) {
        uint256 proposalId = _getNextProposalId();
        Proposal storage proposal = proposals[proposalId];
        proposal.creator = msg.sender;
        proposal.description = _description;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + defaultVotingDuration;
        proposal.executed = false;

        emit ProposalCreated(proposalId, msg.sender);
        return proposalId;
    }
    
    //function to countVotes
    function countVotes(uint256 _proposalId) external returns (bool) {
        require(_proposalId < proposalCount, "Proposal does not exist");
        require(block.timestamp > proposals[_proposalId].endTime, "Voting period has not ended yet");

        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Proposal has already been finalized");
        proposal.executed = true;

        bool isApproved = proposal.yesVotes > proposal.noVotes;
        emit ProposalFinalized(_proposalId, isApproved);
        return isApproved;
    }

    function canVote(uint256 proposalId, address voter) public view returns (bool) {
        Proposal storage proposal = proposals[proposalId];
        uint256 balance = nation3NFT.balanceOf(voter);
        bool isVotingPeriodActive = block.timestamp >= proposal.startTime && block.timestamp <= proposal.endTime;
        return balance > 0 && isVotingPeriodActive;
    }

    function _getNextProposalId() internal returns (uint256) {
        return ++proposalCount;
    }
}
