// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

/**
 * @title SoulBoundNFT
 * @dev A soul-bound NFT contract where tokens are bound to owners and cannot be transferred if soul-bound.
 *      The contract tracks ownership with unique token IDs and allows minting, binding, unbinding, with enforced rules.
 *      Inherits from ERC721 and Ownable for NFT standard and access control.
 *
 * @author ooracle100
 *
 */
contract SoulBoundNFT is ERC721, Ownable {
    /// @dev Counter for assigning unique token IDs
    uint256 private tokenIdCounter;

    /// @dev Initial owner address (immutable)
    address immutable initialOwner;

    /// @dev Base URI used for all token metadata
    string private baseURI;

    /// @dev Mapping of soul-bound token IDs to owner addresses
    mapping(uint256 => address) private soulBoundTokens;

    /// @dev Emitted when a soul-bound token is minted/bound
    event SoulBound(uint256 indexed tokenId, address owner);

    /// @dev Emitted when a soul-bound token is unbound
    event SoulUnbound(uint256 indexed tokenId);

    /**
     * @dev Contract constructor initializing owner, name, symbol, and base URI.
     * @param _owner Address to set as initial owner (Ownable).
     * @param org Token collection name.
     * @param url Base URI for token metadata.
     * @param sym Token symbol.
     */
    constructor(address _owner, string memory org, string memory url, string memory sym) 
        ERC721(org, sym) 
        Ownable() 
    {
        initialOwner = _owner;
        baseURI = url;
    }

    /**
     * @dev Returns base URI for computing {tokenURI}.
     * @return string memory base URI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @notice Mints a new soul-bound token and binds it to the given address.
     * @dev Only callable by the contract owner.
     * @param to The address to mint and bind the token to.
     */
    function mintSoulBound(address to) external onlyOwner {
        _mint(to, tokenIdCounter);
        soulBoundTokens[tokenIdCounter] = to;
        emit SoulBound(tokenIdCounter, to);
        tokenIdCounter++;
    }

    /**
     * @notice Checks if a token is soul-bound to a specific owner.
     * @param tokenId Token ID to check.
     * @param owner Address to verify binding.
     * @return bool true if the token is soul-bound to the owner, false otherwise.
     */
    function isSoulBound(uint256 tokenId, address owner) external view returns (bool) {
        return soulBoundTokens[tokenId] == owner;
    }

    /**
     * @notice Unbinds a soul-bound token, allowing transfer.
     * @dev Only callable by the contract owner. Verifies token existence and binding before unbinding.
     * @param tokenId Token ID to unbind.
     */
    function unbindSoul(uint256 tokenId) external onlyOwner {
        require(_exists(tokenId), "TOKEN_DOES_NOT_EXIST");
        address owner = ownerOf(tokenId);
        require(soulBoundTokens[tokenId] == owner, "TOKEN_NOT_BOUND_TO_CALLER");

        soulBoundTokens[tokenId] = address(0);

        emit SoulUnbound(tokenId);
    }

    /**
     * @dev Overrides _beforeTokenTransfer to enforce soul-bound transfer restriction.
     *      Reverts if token is currently soul-bound to the sender.
     * @param from Address sending the token.
     * @param to Address receiving the token.
     * @param tokenId Token ID being transferred.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable, ERC721URIStorage) {
        super._beforeTokenTransfer(from, to, tokenId);
        require(soulBoundTokens[tokenId] != from, "TOKEN_BOUND_TO_SELLER");
    }
}
