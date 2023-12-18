// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockNFT is ERC721 {
    uint256 private _nextTokenId = 1;

    constructor() ERC721("MockNFT", "MNFT") {}

    function mint(address to, uint256 tokenId) public {
     // This is just a example in real time need to have access control to restrict who can mint tokens
        _safeMint(to, tokenId);
    }
    function _baseURI() internal pure override returns (string memory) {
        return "http://example.com/api/token/";
    }

    function _getNextTokenId() private returns (uint256) {
        return _nextTokenId++;
    }
}
