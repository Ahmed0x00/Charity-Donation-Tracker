// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Charity Donation Tracker - Core Contract
// Handles campaigns, donations, user registration, and admin controls

contract CharityCampaigns {

    struct Campaign {
        uint256 id;
        string name;
        string description;
        uint256 goalAmount;     // in wei
        uint256 totalDonated;   // in wei
        bool active;
    }

    // state variables
    address public admin;
    bool public paused;
    uint256 public campaignCount;

    mapping(uint256 => Campaign) public campaigns;
    mapping(address => string) public userNames;
    mapping(address => bool) public registered;

    // events
    event CampaignAdded(uint256 id, string name);
    event CampaignUpdated(uint256 id, string name);
    event DonationMade(address indexed donor, uint256 indexed campaignId, uint256 amount);
    event UserRegistered(address indexed user, string name);
    event Paused(address admin);
    event Resumed(address admin);
    event OwnershipTransferred(address indexed oldAdmin, address indexed newAdmin);

    // only the admin can call functions with this
    modifier onlyOwner() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    // blocks everything when contract is paused
    modifier whenNotPaused() {
        require(!paused, "Contract paused");
        _;
    }

    constructor() {
        admin = msg.sender;
        paused = false;
    }

    // ---- Admin functions ----

    function addCampaign(string memory _name, string memory _description, uint256 _goalAmount) public onlyOwner {
        require(bytes(_name).length > 0, "Empty name");
        require(_goalAmount > 0, "Zero goal");

        campaignCount++;
        campaigns[campaignCount] = Campaign(campaignCount, _name, _description, _goalAmount, 0, true);
        emit CampaignAdded(campaignCount, _name);
    }

    function updateCampaign(uint256 _id, string memory _name, uint256 _goalAmount) public onlyOwner {
        require(_id > 0 && _id <= campaignCount, "Campaign not found");
        require(bytes(_name).length > 0, "Empty name");
        require(_goalAmount > 0, "Zero goal");

        campaigns[_id].name = _name;
        campaigns[_id].goalAmount = _goalAmount;
        emit CampaignUpdated(_id, _name);
    }

    // batch add - takes arrays, loops through them, adds each one
    function batchAddCampaigns(
        string[] memory _names,
        string[] memory _descriptions,
        uint256[] memory _goals
    ) public onlyOwner {
        require(_names.length == _descriptions.length && _names.length == _goals.length, "Array length mismatch");

        for (uint256 i = 0; i < _names.length; i++) {
            require(bytes(_names[i]).length > 0, "Empty name");
            require(_goals[i] > 0, "Zero goal");

            campaignCount++;
            campaigns[campaignCount] = Campaign(campaignCount, _names[i], _descriptions[i], _goals[i], 0, true);
            emit CampaignAdded(campaignCount, _names[i]);
        }
    }

    function pause() public onlyOwner {
        paused = true;
        emit Paused(admin);
    }

    function resume() public onlyOwner {
        paused = false;
        emit Resumed(admin);
    }

    function transferOwnership(address _newAdmin) public onlyOwner {
        require(_newAdmin != address(0), "Zero address");
        address oldAdmin = admin;
        admin = _newAdmin;
        emit OwnershipTransferred(oldAdmin, _newAdmin);
    }

    function getAdmin() public view returns (address) {
        return admin;
    }

    // ---- User functions (blocked when paused) ----

    function donate(uint256 _campaignId) public payable whenNotPaused {
        require(_campaignId > 0 && _campaignId <= campaignCount, "Campaign not found");
        require(campaigns[_campaignId].active, "Campaign not active");
        require(msg.value > 0, "Zero donation");

        campaigns[_campaignId].totalDonated += msg.value;
        emit DonationMade(msg.sender, _campaignId, msg.value);
    }

    // register once, can't change name after
    function registerUser(string memory _name) public whenNotPaused {
        require(!registered[msg.sender], "Already registered");
        require(bytes(_name).length > 0, "Empty name");

        userNames[msg.sender] = _name;
        registered[msg.sender] = true;
        emit UserRegistered(msg.sender, _name);
    }

    function getCampaign(uint256 _id) public view returns (uint256, string memory, string memory, uint256, uint256, bool) {
        require(_id > 0 && _id <= campaignCount, "Campaign not found");
        Campaign memory c = campaigns[_id];
        return (c.id, c.name, c.description, c.goalAmount, c.totalDonated, c.active);
    }

    function getUserName(address _user) public view returns (string memory) {
        return userNames[_user];
    }
}
