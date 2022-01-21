pragma solidity >=0.4.24 <0.6.0;

contract DealFlowContract {
    
    struct client_account{
        int client_id;
        address client_address;
        uint client_balance_in_ether;
        string shipper_Id;
    }
    
    client_account[] clients;
    
    int orderCounter;
    address payable manager;
    mapping(address => uint) public executionDate;
    
    modifier onlyManager() {
        require(msg.sender == manager, "Trade Account Manager");
        _;
    }
    
    modifier onlyClients() {
        bool isclient = false;
        for(uint i=0;i<clients.length;i++){
            if(clients[i].client_address == msg.sender){
                isclient = true;
                break;
            }
        }
        require(isclient, "Allowed By TAM");
        _;
    }
    
    constructor() public{
        orderCounter = 0;
    }
    
    receive() external payable { }
    
    function setManager(address managerAddress) public returns(string memory){
        manager = payable(managerAddress);
        return "";
    }
   
    function joinAsClient() public payable returns(string memory){
        executionDate[msg.sender] = now;
        return "";
    }
    
    function deposit() public payable onlyClients{
        payable(address(this)).transfer(msg.value);
    }
    
    function withdraw(uint amount) public payable onlyClients{
        msg.sender.transfer(amount * 1 ether);
    }
    
    function sendOrder() public payable onlyManager {
        for(uint i=0;i<clients.length;i++){
            address initialAddress = clients[i].client_address;
            uint lastexecutionDate = executionDate[initialAddress];
            if(now < lastexecutionDate + 10 seconds){
                revert("It's just been less than 10 seconds!");
            }
            payable(initialAddress).transfer(1 ether);
            executionDate[initialAddress] = now;
        }
    }
    
    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }
}