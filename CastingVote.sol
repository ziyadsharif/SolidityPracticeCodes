pragma solidity >=0.4.22 <0.6.0;

contract Election {
    
    struct VotingCenter {
        bytes32 name;   
        uint voteCount; 
    }
    
    struct Voter {
        uint weight; 
        bool voted;  
        address delegate;
        uint vote;   
    }
    
    address public presidingOfficer;
    mapping(address => Voter) public voters;
    VotingCenter[] public VotingCenters;

    constructor(bytes32[] memory VotingCenterNames) public {
        presidingOfficer = msg.sender;
        voters[presidingOfficer].weight = 1;

        for (uint i = 0; i < VotingCenterNames.length; i++) {
            VotingCenters.push(VotingCenter({
                name: VotingCenterNames[i],
                voteCount: 0
            }));
        }
    }

    function assignVotingRight(address voter) public {
        require(msg.sender == presidingOfficer,"You are not a Presiding Officer so you cannot give rights to vote.");
        require( !voters[voter].voted, "User already voted");
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }

    function delegate(address to) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "vote already casted");
        require(to != msg.sender, "You cannot assign yourself");

        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;
            require(to != msg.sender, "Found loop in delegation.");
        }

        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_ = voters[to];
        
        if (delegate_.voted) {
            VotingCenters[delegate_.vote].voteCount += sender.weight;
        } else {
            delegate_.weight += sender.weight;
        }
    }

    function vote(uint VotingCenter) public {
        Voter storage sender = voters[msg.sender];
        
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted.");

        sender.voted = true;
        sender.vote = VotingCenter;

        VotingCenters[VotingCenter].voteCount += sender.weight;
    }

    function maxCountVotingCenter() public view returns (uint maxCountVotingCenter_) {
        uint winningVoteCount = 0;
        for (uint p = 0; p < VotingCenters.length; p++) {
            if (VotingCenters[p].voteCount > winningVoteCount) {
                winningVoteCount = VotingCenters[p].voteCount;
                maxCountVotingCenter_ = p;
            }
        }
    }

    function electedWinnerName() public view returns (bytes32 electedWinnerName_) {
        electedWinnerName_ = VotingCenters[maxCountVotingCenter()].name;
    }
}