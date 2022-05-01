//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";

contract MultiSigWallet {

    ///
    /// variables
    ///    
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public numConfirmationsRequired;

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
    }

    Transaction[] public transactions;

    mapping(uint => mapping(address => bool)) public isConfirmed;

    ///
    /// events
    ///
    event Deposit(address indexed sender, uint amount, uint balance);
    event SubmitTransaction(address indexed owner, uint indexed txIndex);
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, address indexed to, uint indexed txIndex);
    event RevokeTransaction(address indexed owner, uint indexed txIndex);

    ///
    /// modifiers
    ///
    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }
    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }
    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }
    modifier confirmed(uint _txIndex) {
        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");
        _;
    }
    
    /**
     * constructor
     */
    constructor (address[] memory _owners, uint _numConfirmationsRequired) {
        console.log("Deploying MultiSigWallet");
        console.log("Constructor: %d | Owner: %s", _numConfirmationsRequired, _owners[0]);
        uint len = _owners.length;

        require(len > 0, "owners required");
        require(_numConfirmationsRequired > 0 && _numConfirmationsRequired <= len, 
                "invalid number of required confirmations");

        for (uint i = 0; i < len; ++i) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
    }

    /**
     * receive (fallback)
     */
    receive() external payable {
        console.log("Receive: ", msg.sender, msg.value, address(this).balance);
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    /**
     * submitTransaction
     */

    function submitTransaction(
        address _to,
        uint _value,
        bytes calldata _data
    ) public onlyOwner returns(uint _txIndex) {
        console.log("submitTransaction: %s", _to);
        require(_to != address(0), "invalid address");
        require(_value > 0 || _data.length > 0, "invalid value");

        _txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 1
            })
        );

        isConfirmed[_txIndex][msg.sender] = true;

        emit SubmitTransaction(msg.sender, _txIndex);
    }

    /**
     * confirmTransaction
     */
    function confirmTransaction(uint _txIndex) 
        public 
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;

        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    /**
     * executeTransaction
     */
    function executeTransaction(uint _txIndex)
        public 
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(transaction.numConfirmations >= numConfirmationsRequired, "not enough confirmations");

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "tx failed");

        emit ExecuteTransaction(msg.sender, transaction.to, _txIndex);
    }

    /**
     * revokeTransaction
     */
    function revokeTransaction(uint _txIndex)
        public 
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        confirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit revokeTransaction(msg.sender, _txIndex);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(uint _txIndex) 
        public 
        view 
        returns(
            address to;
            uint value;
            bytes data;
            bool executed;
            uint numConfirmations;
        ) 
    {
        Transaction storage transaction = transactions[_txIndex];

        return(
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }

    function isTransactionExecutable(uint _txIndex) public view return(bool) {

        Transaction storage transaction = transactions[_txIndex];

        if (transaction.numConfirmations >= numConfirmationsRequired) 
            return true;

        return false;
    }
}