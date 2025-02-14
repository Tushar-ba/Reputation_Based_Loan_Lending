// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {LoanToken} from "./LoanTokens.sol";
import {SBT} from "./SBT.sol";

contract Lending is Initializable,OwnableUpgradeable,ReentrancyGuardUpgradeable,UUPSUpgradeable{

    address public LOAN_TOKEN_CONTRACT_ADDRESS;
    address public SBT_CONTRACT_ADDRESS;
    uint256 public INTEREST = 200;
    uint256 public LOAN_ID;

    struct LoanDetails{
        address to;
        uint256 loanAmount;
        uint256 amountToBePaidBack;
        uint256 loanPeriodStart;
        uint256 loanEndPeriod;
        address SBT_NFT_ADDRESS;
        bool isLoanPaidBack;
    }

    struct Borrower{
        bool notFirstTimeLoan;
        uint256 loanBorrowedTillNow;
        uint256 creditScore;
        uint8 strikes;
    }

    mapping (uint256 => LoanDetails) public details;
    mapping (address => Borrower) public borrower;


    event LoanGranted(uint256 _loanAmount, uint256 _loanId,uint256 _loanDuration);
    event LoanReturned(uint _loanId,uint _amountToBePaidBack);

    error InvalidParams();
    error DurationEnded();
    error LoanDoesNotExist();
    
    function initialize(address _loanTokenAddress,address _sbtContractAddress) initializer public {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        LOAN_TOKEN_CONTRACT_ADDRESS = _loanTokenAddress;
        SBT_CONTRACT_ADDRESS = _sbtContractAddress;
    }

    function lendLoan (uint256 _loanAmount,uint256 _loanEndPeriod) external nonReentrant  returns(uint256) {
        uint loanId = ++LOAN_ID;
        if(_loanEndPeriod > block.timestamp || _loanAmount == 0){
            revert InvalidParams();
        }
        LoanDetails storage info = details[loanId];
        Borrower storage borrowerInfo = borrower[msg.sender];
        if(!borrowerInfo.notFirstTimeLoan){
           info.to = msg.sender;
           info.loanAmount  = _loanAmount;
           info.loanPeriodStart = block.timestamp;
           info.loanEndPeriod = _loanEndPeriod;
           info.amountToBePaidBack = calculateRepay(_loanAmount,INTEREST,_loanDuration);
           borrowerInfo.loanBorrowedTillNow += _loanAmount;
           borrowerInfo.notFirstTimeLoan = true;
           LoanToken(LOAN_TOKEN_CONTRACT_ADDRESS).mint(msg.sender,_loanAmount);
        }else{
            require(SBT(SBT_CONTRACT_ADDRESS).balanceOf(msg.sender)==1,"Not eligible");
        }   
        if(borrowerInfo.notFirstTimeLoan){
            info.to = msg.sender;
            info.loanAmount  = _loanAmount;
            info.loanPeriodStart = block.timestamp;
            info.loanEndPeriod = _loanEndPeriod;
            info.amountToBePaidBack = calculateRepay(_loanAmount,INTEREST,_loanDuration);
            borrowerInfo.loanBorrowedTillNow += _loanAmount;
            LoanToken(LOAN_TOKEN_CONTRACT_ADDRESS).mint(msg.sender,_loanAmount);
        }
        emit LoanGranted(_loanAmount, _loanId,_loanEndPeriod);
        return loanId;   

    }

    function calculateRepay(uint256 _loanAmount,uint _interest,uint _duration) internal pure returns(uint256) {
        return (_loanAmount * _interest * _duration)/(10000 * 365 days);
    }

    function returnLoan(uint256 _loanId, uint256 _amountToBePaidBack) external nonReentrant {
        if(details[_loanId].to == address(0)){
            revert LoanDoesNotExist();
        }
        LoanDetails storage info = details[loanId];
        Borrower storage borrowerInfo = borrower[msg.sender];
        if(info._loanEndPeriod >= block.timestamp){
            require(info.to == msg.sender,"Not the Borrower");
            require(info.amountToBePaidBack == _amountToBePaidBack,"Not the right amount");
            borrowerInfo.creditScore += 10;
            delete details[loanId];
        }else{
            require(info.to == msg.sender,"Not the Borrower");
            require(info.amountToBePaidBack == _amountToBePaidBack,"Not the right amount"); 
            if(borrowerInfo.creditScore < 10){
                borrowerInfo.creditScore = 0;
                if(borrowerInfo.strikes <=3){
                    borrowerInfo.strikes ++;
                }else{
                    SBT(SBT_CONTRACT_ADDRESS).burn(msg.sender,"10 credit points");
                };
            }else{
                info.creditScore -=10;
            }
            emit LoanReturned(_loanId, _amountToBePaidBack);
        }
    }

    function getSBT(uint256 _loanId) external {
        require(borrower[_loanId].creditScore >= 10,"Credit score not enough")
        SBT(SBT_CONTRACT_ADDRESS).mint(msg.sender,"10 credit points");
    }

     function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}