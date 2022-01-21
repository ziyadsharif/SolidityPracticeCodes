pragma solidity >=0.4.22 <0.6.0;

contract Bidding {
    address payable public payee;
    uint public biddingEndTime;
    address public highestBidder;
    uint public highestBid;

    mapping(address => uint) returnRemaining;

    bool ended;

    event HighestBidIncreased(address bidder, uint amount);
    event BiddingEnded(address winner, uint amount);

    constructor(
        uint _biddingTime,
        address payable _payee
    ) public {
        payee = _payee;
        biddingEndTime = now + _biddingTime;
    }

    function bid() public payable {

        require(
            now <= biddingEndTime,
            "Auction already ended."
        );

        require(
            msg.value > highestBid,
            "There already is a higher bid."
        );

        if (highestBid != 0) {
            returnRemaining[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    function withdraw() public returns (bool) {
        uint amount = returnRemaining[msg.sender];
        if (amount > 0) {
            returnRemaining[msg.sender] = 0;

            if (!msg.sender.send(amount)) {
                returnRemaining[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    function biddingEnd() public {
        require(now >= biddingEndTime, "Bidding not yet ended.");
        require(!ended, "Bidding end has already been called.");

        // 2. Effects
        ended = true;
        emit BiddingEnded(highestBidder, highestBid);

        // 3. Interaction
        payee.transfer(highestBid);
    }
}