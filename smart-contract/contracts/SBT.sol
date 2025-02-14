// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {ERC721URIStorageUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";

contract SBT is Initializable,ERC721Upgradeable,ERC721URIStorageUpgradeable,OwnableUpgradeable,ReentrancyGuardUpgradeable,UUPSUpgradeable{

    address public LENDING_CONTRACT_ADDRESS;
    uint256 public ID;

    mapping (uint256 => bool) public check;

     modifier onlyContract {
        require(msg.sender == LENDING_CONTRACT_ADDRESS,"Only Contract can do this");
        _;
    }

    function initialize(address _lendingContractAddress) initializer public {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        __ERC721_init("SoulBoundLvl1","Lvl1");
        __ERC721URIStorage_init();
        LENDING_CONTRACT_ADDRESS = _lendingContractAddress;
    }

    function mint(address _to,string calldata _tokenURI) onlyContract external{
        uint256 id = ++ID;
        _mint(_to, id);
        _setTokenURI(id,_tokenURI);
        check[id] = true;
    }

    function burn(uint256 _tokenId) onlyContract external {
        _burn(_tokenId);
    }

    // function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
    //     require(!check[tokenId],"Cannot make this transfer");
    //     super.safeTransferFrom(from, to, tokenId, data);
    //     // ERC721Utils.checkOnERC721Received(_msgSender(), from, to, tokenId, data);
    // }

    // function transferFrom(address from, address to, uint256 _tokenId) public override {
    //     require(!check[_tokenId],"Cannot make this transfer");
    //     if (to == address(0)) {
    //         revert ERC721InvalidReceiver(address(0));
    //     }
    //     address previousOwner = _update(to, _tokenId, _msgSender());
    //     if (previousOwner != from) {
    //         revert ERC721IncorrectOwner(from, _tokenId, previousOwner);
    //     }
    // }

     function tokenURI(uint256 tokenId) public view virtual override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}