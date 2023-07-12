// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// Interface for interacting with ERC721 tokens
interface IERC721 {
    function transferFrom(address _from, address _to, uint256 _id) external;
}

contract Escrow {
    // Addresses involved in the escrow contract
    // this are state varibale (store in smart contract)
    address public nftAddress; // Address of the ERC721 token contract
    // * but we use 'payable' type because the seller is the person who's going to receive cryptocurrency in this trnsaction so you must make their address 'payable' here becuase we're actually going to transfer ether to them
    address payable public seller; // Address of the seller
    address public inspector; // Address of the inspector
    address public lender; // Address of the lender

    // ? Modifiers to restrict access to certain functions
    modifier onlyBuyer(uint256 _nftID) {
        require(msg.sender == buyer[_nftID], "Only buyer can call this method");
        _;
    }

    modifier onlySeller() {
        require(msg.sender == seller, "Only seller can call this method");
        _;
    }

    modifier onlyInspector() {
        require(msg.sender == inspector, "Only inspector can call this method");
        _;
    }

    // Storage mappings to store data related to escrow transactions
    mapping(uint256 => bool) public isListed; //? Mapping to track if an NFT is listed for sale

    mapping(uint256 => uint256) public purchasePrice; //? Mapping to store the purchase price of an NFT
    mapping(uint256 => uint256) public escrowAmount; //? Mapping to store the escrow amount for an NFT
    mapping(uint256 => address) public buyer; //? Mapping to store the buyer of an NFT

    mapping(uint256 => bool) public inspectionPassed; //? Mapping to track inspection status of an NFT

    mapping(uint256 => mapping(address => bool)) public approval; //? Mapping to track approval status for different parties

    // Constructor to initialize the escrow contract
    constructor(
        // this are the local variable / function arguments (acsess inside this function )
        address _nftAddress,
        address payable _seller,
        address _inspector,
        address _lender
    ) {
        nftAddress = _nftAddress;
        seller = _seller;
        inspector = _inspector;
        lender = _lender;
    }

    //* Function to list an NFT for sale
    function list(
        uint256 _nftID,
        address _buyer,
        uint256 _purchasePrice,
        uint256 _escrowAmount
    ) public payable onlySeller {
        // ? Transfer NFT from seller to this contract
        IERC721(nftAddress).transferFrom(msg.sender, address(this), _nftID);

        //? Update the relevant storage mappings
        isListed[_nftID] = true;
        purchasePrice[_nftID] = _purchasePrice;
        escrowAmount[_nftID] = _escrowAmount;
        buyer[_nftID] = _buyer;
    }

    // Function for the buyer to deposit earnest money
    function depositEarnest(uint256 _nftID) public payable onlyBuyer(_nftID) {
        //? Check if the deposited amount is equal to or greater than the escrow amount
        require(msg.value >= escrowAmount[_nftID]);
    }

    // Function for the inspector to update the inspection status
    function updateInspectionStatus(
        uint256 _nftID,
        bool _passed
    ) public onlyInspector {
        //? Update the inspection status for the specified NFT
        inspectionPassed[_nftID] = _passed;
    }

    // Function for parties to approve the sale
    function approveSale(uint256 _nftID) public {
        //? Mark the approval status for the caller of this function and the specified NFT as true
        approval[_nftID][msg.sender] = true;
    }

    // Function to finalize the sale and transfer the NFT and funds
    function finalizeSale(uint256 _nftID) public {
        //? Require that the inspection status is passed
        require(inspectionPassed[_nftID]);

        //? Require approval from the buyer, seller, and lender
        require(approval[_nftID][buyer[_nftID]]);
        require(approval[_nftID][seller]);
        require(approval[_nftID][lender]);

        //? Require that the contract balance is sufficient to cover the purchase price
        require(address(this).balance >= purchasePrice[_nftID]);

        //? Set the NFT as unlisted
        isListed[_nftID] = false;

        //? Transfer the funds to the seller
        (bool success, ) = payable(seller).call{value: address(this).balance}(
            ""
        );
        require(success);

        //? Transfer the NFT to the buyer
        IERC721(nftAddress).transferFrom(address(this), buyer[_nftID], _nftID);
    }

    // Function to cancel the sale and handle the earnest deposit
    // function cancelSale(uint256 _nftID) public {
    //     if (inspectionPassed[_nftID] == false) {
    //         // Refund the earnest deposit to the buyer if inspection status is not approved
    //         payable(buyer[_nftID]).transfer(address(this).balance);
    //     } else {
    //         // Send the earnest deposit to the seller if inspection status is approved
    //         payable(seller).transfer(address(this).balance);
    //     }
    // }

    // Fallback function to receive ether
    receive() external payable {}

    // Function to get the contract balance
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
