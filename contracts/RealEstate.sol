//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/** 
* * Counters.sol: This contract from OpenZeppelin helps create and manage counters, which are useful for generating unique identifiers or tracking event counts.

* * ERC721.sol: This contract implements the ERC721 standard, which is widely used for non-fungible tokens (NFTs) on Ethereum. It provides the core functionality for creating and managing NFTs, including ownership, transfers, and approvals.

* * ERC721URIStorage.sol: This contract extends ERC721 by enabling the storage and retrieval of additional metadata (e.g., token URIs) for each token. It allows developers to associate extra information with their NFTs, such as images, descriptions, or external links.
*/

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

// * what we're going to do instead of creating a complete nft from scratch is we're going to use third-party library to help us create the NFT quickly , we are going to use open Zeppelin library for doing this

contract RealEstate is ERC721URIStorage {
    /*
     *  basically this is going to allows us create an innumerable ERC721 token
     */

    /*
     * so basically whenever we create this NFT , we're gonna mint them from scratch. so when we put nft in the blockchain we depoly the smart contract out there 's not going to be any properties  whenever we grade it , all right we're actually going to create them manually from scratch one by one by calling the mint function
     */

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("Real Estate", "REAL") {}

    //* mint function is used to create and mint a new NFT
    function mint(string memory tokenURI) public returns (uint256) {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }

    //* bascially see how many nfts have been currently minted
    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }
}
