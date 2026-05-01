// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title DonorCoin — Custom ERC-20 Token for the Charity Donation Tracker
/// @notice A simple ERC-20 coin ("Donor Coin" / DNRC) where only the Admin
///         can mint new tokens.  Normal users can transfer tokens freely.
/// @dev    Built by Member 2 (Custom Coin + Batch Ops + Ownership Transfer)

contract DonorCoin {

    // -----------------------------------------------------------------------
    //  ERC-20 Token Metadata
    // -----------------------------------------------------------------------

    /// @notice Full name of the token
    string public name = "Donor Coin";

    /// @notice Ticker symbol
    string public symbol = "DNRC";

    /// @notice Number of decimal places (standard 18)
    uint8 public decimals = 18;

    /// @notice Total number of tokens in existence
    uint256 public totalSupply;

    // -----------------------------------------------------------------------
    //  State Variables
    // -----------------------------------------------------------------------

    /// @notice Admin address — set to deployer; only admin can mint
    address public admin;

    /// @notice Token balances for each address
    mapping(address => uint256) public balanceOf;

    /// @notice ERC-20 allowances: owner => spender => amount
    mapping(address => mapping(address => uint256)) public allowance;

    // -----------------------------------------------------------------------
    //  Events
    // -----------------------------------------------------------------------

    /// @notice Emitted on every token transfer (including mints from address(0))
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice Emitted when an allowance is set via approve()
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // -----------------------------------------------------------------------
    //  Modifiers
    // -----------------------------------------------------------------------

    /// @notice Restricts function to the current admin
    modifier onlyOwner() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    // -----------------------------------------------------------------------
    //  Constructor
    // -----------------------------------------------------------------------

    /// @notice Sets the deployer as admin with zero initial supply
    constructor() {
        admin = msg.sender;
    }

    // -----------------------------------------------------------------------
    //  Admin Functions
    // -----------------------------------------------------------------------

    /// @notice Mint new Donor Coins to a recipient (admin only)
    /// @param _to     Recipient address
    /// @param _amount Number of tokens to mint (in smallest unit)
    function mint(address _to, uint256 _amount) public onlyOwner {
        require(_to != address(0), "Mint to zero address");
        require(_amount > 0, "Zero amount");

        totalSupply       += _amount;
        balanceOf[_to]    += _amount;

        emit Transfer(address(0), _to, _amount);
    }

    // -----------------------------------------------------------------------
    //  ERC-20 Standard Functions
    // -----------------------------------------------------------------------

    /// @notice Transfer tokens from the caller to another address
    /// @param _to     Recipient address
    /// @param _amount Number of tokens to transfer
    /// @return success True if the transfer succeeded
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(_to != address(0), "Transfer to zero address");
        require(balanceOf[msg.sender] >= _amount, "Insufficient balance");

        balanceOf[msg.sender] -= _amount;
        balanceOf[_to]        += _amount;

        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    /// @notice Approve a spender to transfer tokens on behalf of the caller
    /// @param _spender Address allowed to spend
    /// @param _amount  Maximum amount the spender can transfer
    /// @return success True if the approval succeeded
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowance[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /// @notice Transfer tokens on behalf of another address (requires allowance)
    /// @param _from   Address to transfer from
    /// @param _to     Address to transfer to
    /// @param _amount Number of tokens to transfer
    /// @return success True if the transfer succeeded
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public returns (bool success) {
        require(_to != address(0), "Transfer to zero address");
        require(balanceOf[_from] >= _amount, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _amount, "Allowance exceeded");

        balanceOf[_from]                 -= _amount;
        balanceOf[_to]                   += _amount;
        allowance[_from][msg.sender]     -= _amount;

        emit Transfer(_from, _to, _amount);
        return true;
    }
}
