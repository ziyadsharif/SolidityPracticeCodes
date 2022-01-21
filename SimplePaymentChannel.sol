pragma solidity >=0.4.24 <0.6.0;

contract PaymentChannel {
    address payable public sender;      
    address payable public reciever;   
    uint256 public expiry;  

    constructor (address payable _reciever, uint256 duration) public payable {
        sender = msg.sender;
        reciever = _reciever;
        expiry = now + duration;
    }

    function isValidSignature(uint256 amount, bytes memory signature) internal view returns (bool) {
        bytes32 message = prefixed(keccak256(abi.encodePacked(this, amount)));
        return recoverSigner(message, signature) == sender;
    }

    function close(uint256 amount, bytes memory signature) public {
        require(msg.sender == reciever);
        require(isValidSignature(amount, signature));
        reciever.transfer(amount);
        
        selfdestruct(sender);
    }

    function extend(uint256 newExpiry) public {
        require(msg.sender == sender);
        require(newExpiry > expiry);

        expiry = newExpiry;
    }

    function claimTimeout() public {
        require(now >= expiry);
        selfdestruct(sender);
    }

    function splitSignature(bytes memory sig) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(sig.length == 65);

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}