
pragma solidity >0.4.23 <0.6.0;

contract BlindBidding {
    struct Bid {
        bytes32 blindedBid;
        uint deposit;
    }

    address payable public payee;
    uint public biddingEnd;
    uint public divulgeEnd;
    bool public ended;

    mapping(address => Bid[]) public bids;

    address public highestBidder;
    uint public highestBid;


    mapping(address => uint) returnRemaining;

    event BiddingEnded(address winner, uint highestBid);


    modifier Before(uint _time) { require(now < _time); _; }
    modifier After(uint _time) { require(now > _time); _; }

    constructor(
        uint _biddingTime,
        uint _revealTime,
        address payable _payee
    ) public {
        payee = _payee;
        biddingEnd = now + _biddingTime;
        divulgeEnd = biddingEnd + _revealTime;
    }


    function bid(bytes32 _blindedBid)
        public
        payable
        Before(biddingEnd)
    {
        bids[msg.sender].push(Bid({
            blindedBid: _blindedBid,
            deposit: msg.value
        }));
    }


    function reveal(
        uint[] memory _values,
        bool[] memory _fake,
        bytes32[] memory _secret
    )
        public
        After(biddingEnd)
        Before(divulgeEnd)
    {
        uint length = bids[msg.sender].length;
        require(_values.length == length);
        require(_fake.length == length);
        require(_secret.length == length);

        uint refund;
        for (uint i = 0; i < length; i++) {
            Bid storage checkBid = bids[msg.sender][i];
            (uint value, bool fake, bytes32 secret) =
                    (_values[i], _fake[i], _secret[i]);
            if (checkBid.blindedBid != keccak256(abi.encodePacked(value, fake, secret))) {
            
                continue;
            }
            refund += checkBid.deposit;
            if (!fake && checkBid.deposit >= value) {
                if (placeBid(msg.sender, value))
                    refund -= value;
            }
        
            checkBid.blindedBid = bytes32(0);
        }
        msg.sender.transfer(refund);
    }


    function placeBid(address bidder, uint value) internal
            returns (bool success)
    {
        if (value <= highestBid) {
            return false;
        }
        if (highestBidder != address(0)) {
        
            returnRemaining[highestBidder] += highestBid;
        }
        highestBid = value;
        highestBidder = bidder;
        return true;
    }


    function withdraw() public {
        uint amount = returnRemaining[msg.sender];
        if (amount > 0) {
        
            returnRemaining[msg.sender] = 0;

            msg.sender.transfer(amount);
        }
    }


    function auctionEnd()
        public
        After(divulgeEnd)
    {
        require(!ended);
        emit BiddingEnded(highestBidder, highestBid);
        ended = true;
        payee.transfer(highestBid);
    }
}