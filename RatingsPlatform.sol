// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./BBTians.sol";

contract BBTRating is Ownable {

    address public operator;
    address payable public feeCollector;
    address public token;
    uint256 public ratingFee;
    
    struct Profile {
        uint id;
        string name;
        uint reviewsCount;
        uint sumRating;
        mapping(address => bool) hasReviewed;
    }

    event ProfileAdded(
        uint id,
        string name
    );

    event ProfileReviewed(
        uint id,
        uint avgRating,
        address reviewer
    );

    uint numProfiles;
    mapping(uint => Profile) profiles;
    uint public profileCount = 0;

    modifier onlyOwnerOrOperator {
        require(msg.sender == operator || msg.sender == owner(), "BBT Platform: only accessible by operator or owner");
        _;
    }
    constructor (address _operator, address payable _feeCollector, address _token, uint256 _ratingFee) {
        operator = _operator;
        feeCollector = _feeCollector;
        token = _token;
        ratingFee = _ratingFee;
    }

    function addProfile(
        string memory _name)
        public onlyOwnerOrOperator {
        require(keccak256(bytes(_name)) != keccak256(""), "The name property is required.");

        Profile storage p = profiles[numProfiles++];
        
            p.id = profileCount;
            p.name = _name;
            p.reviewsCount = 0;
            p.sumRating = 0;

            profileCount++;
    }
        
    function addReview(uint _profileId, uint8 _rating) public payable {
        BBTians _token = BBTians(address(token));
        _token.mint(tx.origin, 10);
        
        Profile storage profile = profiles[_profileId];

        feeCollector.transfer(msg.value); 
        require(msg.value >= ratingFee);

        require(keccak256(bytes(profile.name)) != keccak256(""), "Profile not found.");
        require(_rating >= 1 && _rating <= 5, "Rating is out of range.");
        require(!profile.hasReviewed[msg.sender], "This address already reviewed this profile.");
    
        profile.sumRating += _rating * 10;
        profile.hasReviewed[msg.sender] = true;
        profile.reviewsCount++;

        emit ProfileReviewed(profile.id, profile.sumRating / profile.reviewsCount, msg.sender);
    }
    
    function getProfile(uint profileId) public view returns (
        uint id, 
        string memory name,
        uint avgRating, 
        uint reviewsCount) {
        Profile storage profile = profiles[profileId];
        uint _avgRating = 0;

    if(profile.reviewsCount > 0)
            _avgRating = profile.sumRating / profile.reviewsCount;
        
        return (
            profile.id,
            profile.name,
            _avgRating,
            profile.reviewsCount
        );
    }

    function editProfile(uint _profileId, string memory _name) public onlyOwnerOrOperator {
        Profile storage profile = profiles[_profileId];

        profile.name = _name;
    }

    function updateToken(address _token) public onlyOwner {
        token = _token;
    }

    function newOperator(address _operator) public onlyOwner {
        operator = _operator;
    }

    function updateRatingFee(uint256 newRatingFee) public onlyOwner {
        ratingFee = newRatingFee;
    }

    function updateFeeCollector(address payable _feeCollector) public onlyOwner{
        feeCollector = _feeCollector;
    }
}
