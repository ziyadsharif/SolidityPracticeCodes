pragma solidity >=0.4.22 <0.6.0;

contract Buy {
    uint public value;
    address payable public seller;
    address payable public purchaser;
    enum State { Created, Locked, Inactive }
    State public state;

    constructor() public payable {
        seller = msg.sender;
        value = msg.value / 2;
        require((2 * value) == msg.value, "Value has to be even.");
    }

    modifier condition(bool _condition) {
        require(_condition);
        _;
    }

    modifier onlyPurchaser() {
        require(
            msg.sender == purchaser,
            "Only purchaser can call this."
        );
        _;
    }

    modifier onlySeller() {
        require(
            msg.sender == seller,
            "Only seller can call this."
        );
        _;
    }

    modifier inState(State _state) {
        require(
            state == _state,
            "Invalid state."
        );
        _;
    }

    event Aborted();
    event BuyConfirmed();
    event ItemCollected();

    function abort()
        public
        onlySeller
        inState(State.Created)
    {
        emit Aborted();
        state = State.Inactive;
        seller.transfer(address(this).balance);
    }

    function confirmBuy()
        public
        inState(State.Created)
        condition(msg.value == (2 * value))
        payable
    {
        emit BuyConfirmed();
        purchaser = msg.sender;
        state = State.Locked;
    }

    function confirmCollected()
        public
        onlyPurchaser
        inState(State.Locked)
    {
        emit ItemCollected();
        state = State.Inactive;
        purchaser.transfer(value);
        seller.transfer(address(this).balance);
    }
}