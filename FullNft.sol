// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract FullNFT is ERC721URIStorage, ERC2981, Ownable, Pausable {
    // ── Supply & Pricing ──
    uint256 public maxSupply = 1000;
    uint256 public publicMintPrice = 0.01 ether;
    uint256 public whitelistMintPrice = 0.005 ether;
    uint256 public maxPerWallet = 3;
    uint256 public maxPerWhitelist = 2;
    uint256 public totalMinted;

    // ── Sale Phases ──
    bool public publicSaleActive = false;
    bool public whitelistSaleActive = false;

    // ── Reveal ──
    bool public revealed = false;
    string public hiddenMetadataURI;
    string public baseURI;

    // ── Whitelist ──
    bytes32 public merkleRoot;

    // ── Tracking ──
    mapping(address => uint256) public publicMintedPerWallet;
    mapping(address => uint256) public whitelistMintedPerWallet;

    // ── Events ──
    event NFTMinted(address indexed to, uint256 tokenId);
    event Revealed(string baseURI);
    event Withdrawn(address owner, uint256 amount);

    constructor(
        string memory name_,
        string memory symbol_,
        string memory hiddenMetadataURI_,
        bytes32 merkleRoot_
    ) ERC721(name_, symbol_) Ownable(msg.sender) {
        hiddenMetadataURI = hiddenMetadataURI_;
        merkleRoot = merkleRoot_;
        _setDefaultRoyalty(msg.sender, 500);
    }

    // ── Public Mint ──
    function mint(uint256 amount) external payable whenNotPaused {
        require(publicSaleActive, "Public sale not active");
        require(totalMinted + amount <= maxSupply, "Exceeds max supply");
        require(msg.value >= publicMintPrice * amount, "Insufficient ETH");
        require(
            publicMintedPerWallet[msg.sender] + amount <= maxPerWallet,
            "Exceeds max per wallet"
        );

        for (uint256 i = 0; i < amount; i++) {
            totalMinted++;
            publicMintedPerWallet[msg.sender]++;
            _safeMint(msg.sender, totalMinted);
            emit NFTMinted(msg.sender, totalMinted);
        }
    }

    // ── Whitelist Mint ──
    function whitelistMint(
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external payable whenNotPaused {
        require(whitelistSaleActive, "Whitelist sale not active");
        require(totalMinted + amount <= maxSupply, "Exceeds max supply");
        require(msg.value >= whitelistMintPrice * amount, "Insufficient ETH");
        require(
            whitelistMintedPerWallet[msg.sender] + amount <= maxPerWhitelist,
            "Exceeds whitelist limit"
        );

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, leaf),
            "Invalid merkle proof"
        );

        for (uint256 i = 0; i < amount; i++) {
            totalMinted++;
            whitelistMintedPerWallet[msg.sender]++;
            _safeMint(msg.sender, totalMinted);
            emit NFTMinted(msg.sender, totalMinted);
        }
    }

    // ── Owner Free Mint ──
    function ownerMint(address to, uint256 amount) external onlyOwner {
        require(totalMinted + amount <= maxSupply, "Exceeds max supply");

        for (uint256 i = 0; i < amount; i++) {
            totalMinted++;
            _safeMint(to, totalMinted);
            emit NFTMinted(to, totalMinted);
        }
    }

    // ── Token URI (handles reveal) ──
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721URIStorage) returns (string memory) {
        require(tokenId <= totalMinted, "Token does not exist");

        if (!revealed) {
            return hiddenMetadataURI;
        }

        return string(abi.encodePacked(baseURI, "/", _toString(tokenId), ".json"));
    }

    // ── Reveal ──
    function reveal(string memory baseURI_) external onlyOwner {
        revealed = true;
        baseURI = baseURI_;
        emit Revealed(baseURI_);
    }

    // ── Withdraw ──
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Nothing to withdraw");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
        emit Withdrawn(owner(), balance);
    }

    // ── Owner Controls ──
    function setPublicSaleActive(bool active) external onlyOwner {
        publicSaleActive = active;
    }

    function setWhitelistSaleActive(bool active) external onlyOwner {
        whitelistSaleActive = active;
    }

    function setPublicMintPrice(uint256 newPrice) external onlyOwner {
        publicMintPrice = newPrice;
    }

    function setWhitelistMintPrice(uint256 newPrice) external onlyOwner {
        whitelistMintPrice = newPrice;
    }

    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        merkleRoot = newMerkleRoot;
    }

    function setMaxPerWallet(uint256 newMax) external onlyOwner {
        maxPerWallet = newMax;
    }

    function setHiddenMetadataURI(string memory newURI) external onlyOwner {
        hiddenMetadataURI = newURI;
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // ── Required Overrides ──
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721URIStorage, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // ── Helper ──
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}