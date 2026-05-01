// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title CharityCampaigns — Core Smart Contract for the Charity Donation Tracker
/// @notice Stores charity campaigns on-chain, handles donations, user registration,
///         access control (onlyOwner), and an emergency pause mechanism.
/// @dev    Built by Member 1 (Core + Access Control + Pause/Resume)
///         Batch operations added by Member 2

contract CharityCampaigns {

    // -----------------------------------------------------------------------
    //  Structs
    // -----------------------------------------------------------------------

    /// @notice Represents a single charity campaign
    struct Campaign {
        uint256 id;
        string  name;
        string  description;
        uint256 goalAmount;      // fundraising goal in wei
        uint256 totalDonated;    // total donations received in wei
        bool    active;
    }

    // -----------------------------------------------------------------------
    //  State Variables
    // -----------------------------------------------------------------------

    /// @notice The admin address — set to the deployer in the constructor
    address public admin;

    /// @notice Emergency-stop flag; when true all user-facing actions are blocked
    bool public paused;

    /// @notice Auto-increment counter used as the next campaign ID
    uint256 public campaignCount;

    /// @notice Campaign storage: campaignId => Campaign
    mapping(uint256 => Campaign) public campaigns;

    /// @notice Registered display names: walletAddress => name
    mapping(address => string) public userNames;

    /// @notice Tracks whether an address has already registered
    mapping(address => bool) public registered;

    // -----------------------------------------------------------------------
    //  Events
    // -----------------------------------------------------------------------

    event CampaignAdded(uint256 id, string name);
    event CampaignUpdated(uint256 id, string name);
    event DonationMade(address indexed donor, uint256 indexed campaignId, uint256 amount);
    event UserRegistered(address indexed user, string name);
    event Paused(address admin);
    event Resumed(address admin);
    event OwnershipTransferred(address indexed oldAdmin, address indexed newAdmin);

    // -----------------------------------------------------------------------
    //  Modifiers
    // -----------------------------------------------------------------------

    /// @notice Restricts function to the current admin
    modifier onlyOwner() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    /// @notice Blocks execution while the contract is paused
    modifier whenNotPaused() {
        require(!paused, "Contract paused");
        _;
    }

    // -----------------------------------------------------------------------
    //  Constructor
    // -----------------------------------------------------------------------

    /// @notice Sets the deployer as admin and initialises paused to false
    constructor() {
        admin  = msg.sender;
        paused = false;
    }

    // -----------------------------------------------------------------------
    //  Admin Functions (onlyOwner)
    // -----------------------------------------------------------------------

    /// @notice Add a new charity campaign
    /// @param _name        Campaign name (must not be empty)
    /// @param _description Campaign description
    /// @param _goalAmount  Fundraising goal in wei (must be > 0)
    function addCampaign(
        string memory _name,
        string memory _description,
        uint256 _goalAmount
    ) public onlyOwner {
        require(bytes(_name).length > 0, "Empty name");
        require(_goalAmount > 0, "Zero goal");

        campaignCount++;
        campaigns[campaignCount] = Campaign(
            campaignCount,
            _name,
            _description,
            _goalAmount,
            0,
            true
        );

        emit CampaignAdded(campaignCount, _name);
    }

    /// @notice Update an existing campaign's name and goal
    /// @param _id       Campaign ID (must exist)
    /// @param _name     New name (must not be empty)
    /// @param _goalAmount New goal in wei (must be > 0)
    function updateCampaign(
        uint256 _id,
        string memory _name,
        uint256 _goalAmount
    ) public onlyOwner {
        require(_id > 0 && _id <= campaignCount, "Campaign not found");
        require(bytes(_name).length > 0, "Empty name");
        require(_goalAmount > 0, "Zero goal");

        campaigns[_id].name       = _name;
        campaigns[_id].goalAmount = _goalAmount;

        emit CampaignUpdated(_id, _name);
    }

    /// @notice Batch-add multiple campaigns in a single transaction (Member 2 task)
    /// @dev    Arrays must have equal length; every entry is validated individually.
    ///         If any entry is invalid the whole transaction reverts.
    /// @param _names        Array of campaign names
    /// @param _descriptions Array of campaign descriptions
    /// @param _goals        Array of fundraising goals in wei
    function batchAddCampaigns(
        string[] memory _names,
        string[] memory _descriptions,
        uint256[] memory _goals
    ) public onlyOwner {
        require(
            _names.length == _descriptions.length && _names.length == _goals.length,
            "Array length mismatch"
        );

        for (uint256 i = 0; i < _names.length; i++) {
            require(bytes(_names[i]).length > 0, "Empty name");
            require(_goals[i] > 0, "Zero goal");

            campaignCount++;
            campaigns[campaignCount] = Campaign(
                campaignCount,
                _names[i],
                _descriptions[i],
                _goals[i],
                0,
                true
            );

            emit CampaignAdded(campaignCount, _names[i]);
        }
    }

    /// @notice Pause the contract — blocks all user-facing actions
    function pause() public onlyOwner {
        paused = true;
        emit Paused(admin);
    }

    /// @notice Resume the contract after a pause
    function resume() public onlyOwner {
        paused = false;
        emit Resumed(admin);
    }

    /// @notice Transfer admin rights to a new address
    /// @param _newAdmin The address of the new admin (must not be zero address)
    function transferOwnership(address _newAdmin) public onlyOwner {
        require(_newAdmin != address(0), "Zero address");
        address oldAdmin = admin;
        admin = _newAdmin;
        emit OwnershipTransferred(oldAdmin, _newAdmin);
    }

    /// @notice Returns the current admin address
    /// @return The admin address
    function getAdmin() public view returns (address) {
        return admin;
    }

    // -----------------------------------------------------------------------
    //  User Functions (whenNotPaused)
    // -----------------------------------------------------------------------

    /// @notice Donate ETH to a specific campaign
    /// @param _campaignId The ID of the campaign to donate to
    function donate(uint256 _campaignId) public payable whenNotPaused {
        require(_campaignId > 0 && _campaignId <= campaignCount, "Campaign not found");
        require(campaigns[_campaignId].active, "Campaign not active");
        require(msg.value > 0, "Zero donation");

        campaigns[_campaignId].totalDonated += msg.value;

        emit DonationMade(msg.sender, _campaignId, msg.value);
    }

    /// @notice Register a display name for the caller's address (one-time only)
    /// @param _name The display name to register (must not be empty)
    function registerUser(string memory _name) public whenNotPaused {
        require(!registered[msg.sender], "Already registered");
        require(bytes(_name).length > 0, "Empty name");

        userNames[msg.sender]  = _name;
        registered[msg.sender] = true;

        emit UserRegistered(msg.sender, _name);
    }

    /// @notice Get full details of a campaign by ID
    /// @param _id The campaign ID
    /// @return id, name, description, goalAmount, totalDonated, active
    function getCampaign(uint256 _id) public view returns (
        uint256, string memory, string memory, uint256, uint256, bool
    ) {
        require(_id > 0 && _id <= campaignCount, "Campaign not found");
        Campaign memory c = campaigns[_id];
        return (c.id, c.name, c.description, c.goalAmount, c.totalDonated, c.active);
    }

    /// @notice Get the registered display name for an address
    /// @param _user The wallet address to look up
    /// @return The registered name (empty string if not registered)
    function getUserName(address _user) public view returns (string memory) {
        return userNames[_user];
    }
}
