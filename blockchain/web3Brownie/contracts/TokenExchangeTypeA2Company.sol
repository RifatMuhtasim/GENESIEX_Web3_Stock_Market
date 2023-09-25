// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// A2 = Book binding price 


contract TokenTypeA2 {
    address owner;
    uint companySecretKey;
    // Company Side
    uint companyId;
    event Log(string message);

    constructor() payable {
        owner = msg.sender;
        companySecretKey = 747;
        companyId = 0;
    }


    // Add a company
    mapping(address => bool) public isCompanyAlreadyListed;
    mapping(string => bool) isCompanyCodeAlreadyListed;
    mapping(address => bool) public isCompanyCutOff;
    mapping(address => typeA2CompanyStruct) public typeA2Company;

    struct typeA2CompanyStruct {
        uint companyId;
        address payable companyAddress;
        string companyCode;
        string companyName;
        uint listedToken;
        uint maximumAmountOfTokenOneCanBuy;
        uint floorPrice;
        uint capPrice;
        uint timestamp;
    }
    typeA2CompanyStruct[] typeA2Companies;
    event typeA2CompanyEvent(uint companyId, address payable companyAddress, string companyCode, string companyName, uint listedToken, uint maximumAmountOfTokenOneCanBuy, uint floorPrice, uint capPrice, uint timestamp);
    

    function addTypeA2Company( address payable _companyAddress, string memory _companyCode, string memory _companyName, uint _listedToken, uint _maximumAmountOfTokenOneCanBuy, uint _floorPrice, uint _capPrice, uint _secretKey) external {
        require(msg.sender == _companyAddress, "Authentication Failed !!");
        require(isCompanyAlreadyListed[_companyAddress] == false, "No Need to add. Company already listed");
        require(isCompanyCodeAlreadyListed[_companyCode] == false, "Company Code not available");
        require(companySecretKey == _secretKey, "Secret key is not matched");

        typeA2Company[_companyAddress] = typeA2CompanyStruct(companyId, _companyAddress, _companyCode, _companyName, _listedToken, _maximumAmountOfTokenOneCanBuy, _floorPrice, _capPrice, block.timestamp);
        typeA2Companies.push(typeA2CompanyStruct(companyId, _companyAddress, _companyCode, _companyName, _listedToken, _maximumAmountOfTokenOneCanBuy, _floorPrice, _capPrice, block.timestamp));
        isCompanyAlreadyListed[_companyAddress] = true;
        isCompanyCodeAlreadyListed[_companyCode] = true;
        companyId += 1;
        emit typeA2CompanyEvent(companyId, _companyAddress, _companyCode, _companyName, _listedToken, _maximumAmountOfTokenOneCanBuy, _floorPrice, _capPrice, block.timestamp);
    }


    function getAllTokenA2ListedCompany() external view returns(typeA2CompanyStruct[] memory) {
        return typeA2Companies;
    }



    // investor purchased token from ipo
    mapping(address => mapping(address => mapping(uint => IPOBidInvestorSessionStorageStruct))) public IPOInvestorOnBidPrice;
    mapping(address => mapping(address => mapping(uint => bool))) isInvestorAlreadyListed;
    event IPOInvestorStorageEvent(uint _companyId, string companyCode, address payable companyAddress, address payable investorAddress, uint numberOfTokenWantToPurchased, uint bidPrice, uint timestamp);

    struct IPOBidInvestorSessionStorageStruct {
        address payable investorAddress;
        address payable companyAddress;
        uint companyId;
        string companyCode;
        uint numberOfTokenWantToPurchased;
        uint bidPrice;
        uint timestamp;
    }

    function bidTokenOnA2Company(uint _companyId, string memory _companyCode, address payable _companyAddress, address payable _investorAddress, uint _numberOfTokenWantToPurchased, uint _bidPrice, uint _genFee) external payable {
        require(msg.sender == _investorAddress, "Authentication Failed!!");

        // Comment - Transaction fee
        address genesiexLabAddress = 0x73c71CF12B396B46cF730Aa66C0FDDaf15ba7A2B;
        (bool success, ) = genesiexLabAddress.call{value: _genFee}("");
        require(success, "Transaction Failed");

        if(isInvestorAlreadyListed[_companyAddress][_investorAddress][_bidPrice] == false) {
            IPOInvestorOnBidPrice[_companyAddress][_investorAddress][_bidPrice] = IPOBidInvestorSessionStorageStruct(_investorAddress, _companyAddress, _companyId, _companyCode, _numberOfTokenWantToPurchased, _bidPrice, block.timestamp);
            numberOftokenOnBidPrice[_companyAddress][_bidPrice] += _numberOfTokenWantToPurchased;
            addressOnBidPrice[_companyAddress][_bidPrice].push(_investorAddress);
            isInvestorAlreadyListed[_companyAddress][_investorAddress][_bidPrice] = true;
            emit IPOInvestorStorageEvent(_companyId,_companyCode, _companyAddress, _investorAddress, _numberOfTokenWantToPurchased, _bidPrice, block.timestamp);
    
        } else {
            IPOBidInvestorSessionStorageStruct storage getInvestorData = IPOInvestorOnBidPrice[_companyAddress][_investorAddress][_bidPrice];
            getInvestorData.numberOfTokenWantToPurchased += _numberOfTokenWantToPurchased;
        }
    
    }


    // find cutoff price
    mapping(address => bool) isCutoffPrice;
    mapping(address => uint) public cutoffPrice;
    mapping(address => uint) public extraTokenOnCutoff;
    mapping(address => uint) public totalBidTokens;
    mapping(address => mapping(uint => uint)) public numberOftokenOnBidPrice;
    
    function selectCutOffPrice(address payable _companyAddress) public returns(uint, uint) {
        typeA2CompanyStruct storage companyInfo = typeA2Company[_companyAddress];
        totalBidTokens[_companyAddress] = 0;
        isCutoffPrice[_companyAddress] = false;

        uint companyListedTokens = companyInfo.listedToken;
        uint companyTokenPriceDifference = companyInfo.capPrice - companyInfo.floorPrice;

        for(uint i=0; i <= companyTokenPriceDifference; i++) {
            uint currentPrice = companyInfo.capPrice - i;
            totalBidTokens[_companyAddress] += numberOftokenOnBidPrice[_companyAddress][currentPrice];

            if(totalBidTokens[_companyAddress] >= companyListedTokens){
                if(isCutoffPrice[_companyAddress] == false){
                    cutoffPrice[_companyAddress] = currentPrice;
                    extraTokenOnCutoff[_companyAddress] = totalBidTokens[_companyAddress] - companyListedTokens;
                    isCutoffPrice[_companyAddress] = true;
                }
            } 
        }
        return(cutoffPrice[_companyAddress], extraTokenOnCutoff[_companyAddress]);
    }


    // Give Token to the investor who Bid More than or equal cutoff price
    mapping(address => mapping(uint => address[])) public addressOnBidPrice;
    mapping(address=> mapping(address => investorInfoStruct)) public investorInfo;
    mapping(address=> mapping(address => bool)) investorAlreadyListed;

    struct investorInfoStruct{
        address payable companyAddress;
        uint companyId;
        address payable investorAddress;
        uint amountOfTokens;
        string companyCode;
        string companyName;
        uint timestamp;
    }


    function IPOTokenExchange(address payable _companyAddress, uint256 _cutoffPrice) external {
        require(isCompanyCutOff[_companyAddress] == false, "Company Already Listed");

        typeA2CompanyStruct storage getCompanyInfo = typeA2Company[_companyAddress];
        uint capToFloorPrice = getCompanyInfo.capPrice - getCompanyInfo.floorPrice;
        for(uint a=0; a <= capToFloorPrice; a++) {
            uint _currentPrice = getCompanyInfo.capPrice - a;

            if(_currentPrice > _cutoffPrice) {
                uint bidPriceInvestorsLength  = addressOnBidPrice[_companyAddress][_currentPrice].length;
                uint differenceBetweenPrice = _currentPrice - _cutoffPrice;
                for(uint i = 0; i < bidPriceInvestorsLength; i++){
                    address _currentInvestorAddress = addressOnBidPrice[_companyAddress][_currentPrice][i];
                    IPOBidInvestorSessionStorageStruct storage getInvestorInfo = IPOInvestorOnBidPrice[_companyAddress][_currentInvestorAddress][_currentPrice];

                    // comment - Transaction
                    uint256 purchasedToken = getInvestorInfo.numberOfTokenWantToPurchased * _cutoffPrice * 1000000000;
                    (bool success, ) = _companyAddress.call{value: purchasedToken}("");
                    require(success, "Transaction Failed");
                    (bool successfullyRefund, ) = getInvestorInfo.investorAddress.call{value: differenceBetweenPrice * 1000000000}("");
                    require(successfullyRefund, "Refund Transaction Failed");
                    
                    getCompanyInfo.listedToken -= getInvestorInfo.numberOfTokenWantToPurchased;
                    if(investorAlreadyListed[getInvestorInfo.companyAddress][getInvestorInfo.investorAddress] == false) {
                        investorInfo[getInvestorInfo.companyAddress][getInvestorInfo.investorAddress] = investorInfoStruct(getCompanyInfo.companyAddress, getCompanyInfo.companyId, getInvestorInfo.investorAddress, getInvestorInfo.numberOfTokenWantToPurchased, getCompanyInfo.companyCode, getCompanyInfo.companyName, block.timestamp );
                        investorAlreadyListed[getInvestorInfo.companyAddress][getInvestorInfo.investorAddress] = true;
                        investorAllCompanyList[getInvestorInfo.investorAddress].push(getInvestorInfo.companyAddress);

                    } else {
                        investorInfoStruct storage investorInfoStorage = investorInfo[getInvestorInfo.companyAddress][getInvestorInfo.investorAddress];
                        uint numberOfToken = investorInfoStorage.amountOfTokens + getInvestorInfo.numberOfTokenWantToPurchased;
                        investorInfo[getInvestorInfo.companyAddress][getInvestorInfo.investorAddress] = investorInfoStruct(getInvestorInfo.companyAddress, getInvestorInfo.companyId, getInvestorInfo.investorAddress, numberOfToken, getCompanyInfo.companyCode, getCompanyInfo.companyName, block.timestamp );
                    }
                }


            } else if (_currentPrice == _cutoffPrice) {
                uint bidPriceInvestorsLength = addressOnBidPrice[_companyAddress][_currentPrice].length;
                for(uint i = 0; i < bidPriceInvestorsLength; i++){
                    address _currentInvestorAddress = addressOnBidPrice[_companyAddress][_currentPrice][i];
                    IPOBidInvestorSessionStorageStruct storage getInvestorInfo = IPOInvestorOnBidPrice[_companyAddress][_currentInvestorAddress][_currentPrice];
                    uint _cutoffprice = _cutoffPrice;
                    typeA2CompanyStruct storage getcompanyInfo = typeA2Company[_companyAddress];

                    if(getCompanyInfo.listedToken >= getInvestorInfo.numberOfTokenWantToPurchased){
                        getCompanyInfo.listedToken -= getInvestorInfo.numberOfTokenWantToPurchased;

                        uint256 purchasedToken = getInvestorInfo.numberOfTokenWantToPurchased * _cutoffPrice * 1000000000;
                        (bool success, ) = _companyAddress.call{value: purchasedToken}("");
                        require(success, "Transaction Failed");

                        if(investorAlreadyListed[getInvestorInfo.companyAddress][getInvestorInfo.investorAddress] == false) {
                            investorInfo[getInvestorInfo.companyAddress][getInvestorInfo.investorAddress] = investorInfoStruct(getCompanyInfo.companyAddress, getCompanyInfo.companyId, getInvestorInfo.investorAddress, getInvestorInfo.numberOfTokenWantToPurchased, getCompanyInfo.companyCode, getCompanyInfo.companyName, block.timestamp );
                            investorAllCompanyList[getInvestorInfo.investorAddress].push(getInvestorInfo.companyAddress);
                        } else {
                            investorInfoStruct storage investorInfoStorage = investorInfo[getInvestorInfo.companyAddress][getInvestorInfo.investorAddress];
                            uint numberOfToken = investorInfoStorage.amountOfTokens + getInvestorInfo.numberOfTokenWantToPurchased;
                            investorInfo[getInvestorInfo.companyAddress][getInvestorInfo.investorAddress] = investorInfoStruct(getInvestorInfo.companyAddress, getInvestorInfo.companyId, getInvestorInfo.investorAddress, numberOfToken, getCompanyInfo.companyCode, getCompanyInfo.companyName, block.timestamp );
                        }

                    } else if (getCompanyInfo.listedToken != 0) {
                        uint _investorExtraToken = getInvestorInfo.numberOfTokenWantToPurchased - getCompanyInfo.listedToken;

                        uint256 purchasedToken = getCompanyInfo.listedToken * _cutoffPrice * 1000000000;
                        (bool successful, ) = _companyAddress.call{value: purchasedToken}("");
                        require(successful, "Transaction Failed");
                        (bool success, ) = _currentInvestorAddress.call{value: _cutoffprice * _investorExtraToken * 1000000000}("");
                        require(success, "Transaction Failed");

                        if(investorAlreadyListed[getInvestorInfo.companyAddress][getInvestorInfo.investorAddress] == false) {
                            investorInfo[getInvestorInfo.companyAddress][getInvestorInfo.investorAddress] = investorInfoStruct(getCompanyInfo.companyAddress, getCompanyInfo.companyId, getInvestorInfo.investorAddress, getCompanyInfo.listedToken, getCompanyInfo.companyCode, getCompanyInfo.companyName, block.timestamp );
                            investorAllCompanyList[getInvestorInfo.investorAddress].push(getInvestorInfo.companyAddress);
                        } else {
                            investorInfoStruct storage investorInfoStorage = investorInfo[getInvestorInfo.companyAddress][getInvestorInfo.investorAddress];
                            uint numberOfToken = investorInfoStorage.amountOfTokens + getCompanyInfo.listedToken;
                            investorInfo[getcompanyInfo.companyAddress][getInvestorInfo.investorAddress] = investorInfoStruct(getcompanyInfo.companyAddress, getInvestorInfo.companyId, getInvestorInfo.investorAddress, numberOfToken, getcompanyInfo.companyCode, getcompanyInfo.companyName, block.timestamp );
                        }

                        

                    } else {
                        // comment - Transaction
                        (bool success, ) = _currentInvestorAddress.call{value: _cutoffPrice * getInvestorInfo.numberOfTokenWantToPurchased * 1000000000}("");
                        require(success, "Transaction Failed");
                        emit Log("Sorry Token is not Valid");
                    }
                }


            } else {
                uint bidPriceInvestorsLength = addressOnBidPrice[_companyAddress][_currentPrice].length;
                for(uint i = 0; i < bidPriceInvestorsLength; i++){
                    address _currentInvestorAddress = addressOnBidPrice[_companyAddress][_currentPrice][i];
                    IPOBidInvestorSessionStorageStruct storage getInvestorInfo = IPOInvestorOnBidPrice[_companyAddress][_currentInvestorAddress][_currentPrice];

                    // comment - Transaction
                    uint refundPayment = getInvestorInfo.numberOfTokenWantToPurchased * getInvestorInfo.bidPrice;
                    (bool success, ) = _currentInvestorAddress.call{value: refundPayment * 1000000000 }("");
                    require(success, "Transaction Failed");
                }
            }
        }
        isCompanyCutOff[_companyAddress] = true;
        typeA2Companies[getCompanyInfo.companyId].listedToken = 0;
    }


    // Investor Side 
    mapping(address => address[]) public investorAllCompanyList;

    function getAllInvestorCompanyLength(address _investorAddress) external view returns (uint ){
        return investorAllCompanyList[_investorAddress].length;
    }

    function getAllInvestorToken(address _investorAddress, uint _id) external view returns(investorInfoStruct memory) {
        address _companyAddress = investorAllCompanyList[_investorAddress][_id];
        return investorInfo[_companyAddress][_investorAddress];
    }

}


