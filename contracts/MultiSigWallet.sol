//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";

contract MultiSigWallet {

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

    event Deposit(address indexed sender, uint amount, uint balance);

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

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

    receive() external payable {
        console.log("Receive: ", msg.sender, msg.value, address(this).balance);
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submitTransaction(
        address _to,
        uint _value,
        bytes calldata _data
    ) public onlyOwner returns(uint txId) {
        console.log("submitTransaction");
        require(_to != address(0), "invalid address");
        require(_value > 0, "invalid value");

        txId = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );
    }
}