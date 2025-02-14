// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract LoanToken is Initializable,ERC20Upgradeable,OwnableUpgradeable,ReentrancyGuardUpgradeable,UUPSUpgradeable{

    address public LENDING_CONTRACT_ADDRESS;


    modifier onlyContract {
        require(msg.sender == LENDING_CONTRACT_ADDRESS,"Only Contract can do this");
        _;
    }

    function initialize(address _lendingContractAddress) initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        __ERC20_init("LoanToken", "LT");
        LENDING_CONTRACT_ADDRESS = _lendingContractAddress;
    }

    function mint (address _account,uint256 _value) onlyContract external{
         _mint(_account, _value);
    } 

    function burn (address _account, uint256 _value) onlyContract external{
        _burn(_account, _value);
    }

    function changeLendingContractAddress(address _contractAddress ) onlyOwner {
        LENDING_CONTRACT_ADDRESS = _contractAddress;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

}