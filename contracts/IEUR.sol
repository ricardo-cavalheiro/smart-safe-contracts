// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract IEUR {
    address public immutable owner;
    string public constant name = "iEUR";
    string public constant symbol = "iEUR";
    uint64 public constant decimals = 1000000000000000000;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    event Mint(address indexed to, uint256 indexed amount);
    event Burn(address indexed from, uint256 indexed amount);
    event Transfer(
        address indexed from,
        uint256 indexed amount,
        address indexed to
    );

    constructor(uint256 initialSupply) {
        require(
            initialSupply >= 1,
            "[IEUR#constructor]: Invalid initialSupply."
        );

        owner = msg.sender;
        totalSupply = initialSupply * decimals;
        balanceOf[address(this)] = totalSupply;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "[IEUR]: Caller is not the owner.");
        _;
    }

    function transfer(address to, uint256 amount) external {
        require(
            balanceOf[msg.sender] >= amount,
            "[IEUR#transfer]: Insufficient balance."
        );

        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;

        emit Transfer(msg.sender, amount, to);
    }

    function mint(address to, uint256 amount) external {
        require(amount <= totalSupply, "[IEUR#mint]: Insufficient balance.");

        balanceOf[address(this)] -= amount;
        balanceOf[to] += amount;

        emit Mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        require(
            amount <= balanceOf[from],
            "[IEUR#burn]: Insufficient balance."
        );

        balanceOf[address(this)] += amount;
        balanceOf[from] -= amount;

        emit Burn(from, amount);
    }
}