// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract MultiSigWallet {
    // Events declaration for logging activities on the blockchain.
    event Deposit(address indexed sender, uint amount);
    event Submit(uint indexed txId);
    event Approve(address indexed owner, uint indexed txId);
    event Revoke(address indexed owner, uint indexed txId);
    event Execute(uint indexed txId);

    // A structure to hold transaction details.
    struct Transaction {
        address to; // Recipient of the transaction.
        uint value; // Amount of ether to send.
        bytes data; // Data payload for the transaction.
        bool executed; // Whether the transaction has been executed.
    }

    // Dynamic array of 'owners' of the wallet.
    address[] public owners;
    // Mapping to quickly check if an address is an owner.
    mapping(address => bool) public isOwner;
    // The number of approvals required for a transaction to be executed.
    uint public required;

    // Dynamic array of 'Transaction' structs.
    Transaction[] public transactions;
    // Nested mapping to track approvals: transaction ID => (owner => approval status).
    mapping(uint => mapping(address => bool)) public approved;

    // Modifiers to enforce certain conditions.
    
    // Ensures that the caller is an owner of the wallet.
    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    // Ensures the transaction exists.
    modifier txExists(uint _txId) {
        require(_txId < transactions.length, "tx does not exist");
        _;
    }

    // Ensures the transaction has not been approved by the caller.
    modifier notApproved(uint _txId) {
        require(!approved[_txId][msg.sender], "tx already approved");
        _;
    }

    // Ensures the transaction has not been executed.
    modifier notExecuted(uint _txId) {
        require(!transactions[_txId].executed, "tx already executed");
        _;
    }

    // Constructor to set up the wallet with initial owners and the required number of approvals.
    constructor(address[] memory _owners, uint _required) {
        require(_owners.length > 0, "owners required");
        require(_required > 0 && _required <= _owners.length,
                "invalid required number of owners");

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }
        required = _required;
    }

    // Allows the contract to receive Ether and emits a deposit event.
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    // Function to submit a new transaction by an owner.
    function submit(address _to, uint _value, bytes calldata _data) external onlyOwner {
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false
        }));
        emit Submit(transactions.length - 1);
    }

    // Allows an owner to approve a transaction.
    function approve(uint _txId) external onlyOwner txExists(_txId) notApproved(_txId) notExecuted(_txId) {
        approved[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);
    }
    
    // Private view function to count the approvals for a transaction.
    function _getApprovalCount(uint _txId) private view returns (uint count) {
        for(uint i = 0; i < owners.length; i++) {
            if (approved[_txId][owners[i]]) {
                count += 1;
            }
        }
    }

    // Executes a transaction if it has the required approvals.
    function execute(uint _txId) external txExists(_txId) notExecuted(_txId) {
        require(_getApprovalCount(_txId) >= required, "approvals < required");
        Transaction storage transaction = transactions[_txId];
        transaction.executed = true;
        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "tx failed");
        emit Execute(_txId);
    }

    // Allows an owner to revoke their approval for a transaction.
    function revoke(uint _txId) external onlyOwner txExists(_txId) notExecuted(_txId) {
        require(approved[_txId][msg.sender], "tx not approved");
        approved[_txId][msg.sender] = false;
        emit Revoke(msg.sender, _txId);
    }
}
