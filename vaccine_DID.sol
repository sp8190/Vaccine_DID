// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

abstract contract OwnerHelper {
    address private owner;

  	event OwnerTransferPropose(address indexed _from, address indexed _to);

  	modifier onlyOwner {
		require(msg.sender == owner);
		_;
  	}

  	constructor() {
		owner = msg.sender;
  	}

  	function transferOwnership(address _to) onlyOwner public {
        require(_to != owner);
        require(_to != address(0x0));
    	owner = _to;
    	emit OwnerTransferPropose(owner, _to);
  	}
}

abstract contract IssuerHelper is OwnerHelper {
    mapping(address => bool) public issuers;

    event AddIssuer(address indexed _issuer);
    event DelIssuer(address indexed _issuer);

    modifier onlyIssuer {
        require(isIssuer(msg.sender) == true);
        _;
    }

    constructor() {
        issuers[msg.sender] = true;
    }

    function isIssuer(address _addr) public view returns (bool) {
        return issuers[_addr];
    }

    function addIssuer(address _addr) onlyOwner public returns (bool) {
        require(issuers[_addr] == false);
        issuers[_addr] = true;
        emit AddIssuer(_addr);
        return true;
    }

    function delIssuer(address _addr) onlyOwner public returns (bool) {
        require(issuers[_addr] == true);
        issuers[_addr] = false;
        emit DelIssuer(_addr);
        return true;
    }
}

contract CredentialBox is IssuerHelper {
    uint256 private idCount;
    mapping(uint8 => string) private vaccineEnum;

    struct Credential{
        uint256 id; // 몇번째 index 인지
        address issuer; // 접종 기관의 주소
        uint8 vaccineType; // 백신 type
        uint8 statusType; // 현재 접종 상태
        string value; // 암호화 된 정보
        uint256 createDate; // Credential의 생성일자
    }

    mapping(address => Credential) private credentials;

    constructor() {
        idCount = 1;
        vaccineEnum[0] = "Astrazeneca"; // 아스트라제네카
        vaccineEnum[1] = "Janssen"; // 얀센
        vaccineEnum[2] = "Moderna"; // 모더나
        vaccineEnum[3] = "Pfizer"; // 화이자
    }

    // 해당 함수를 통해 백신시스템 발급
     function claimCredential(address _vaccineAddress, uint8 _vaccineType, string calldata _value) onlyIssuer public returns(bool){
        Credential storage credential = credentials[_vaccineAddress];
        require(credentials[_vaccineAddress].id == 0);
        credential.id = idCount;
        credential.issuer = msg.sender;
        credential.vaccineType = _vaccineType;
        credential.statusType = 1; // 백신 1차 접종 완료
        credential.value = _value;
        credential.createDate = block.timestamp; //타임스탬프

        idCount+=1;
        return true;
    }

    // Credential 확인
    function getCredential(address _vaccineAddress) public view returns (Credential memory){
        return credentials[_vaccineAddress];
    }

    // statusType 확인해서 백신접종 여부 확인
    function checkCredential(address _vaccineAddress) public view returns (bool){
         require(credentials[_vaccineAddress].statusType >=1); 
	 return true;
    }

    // 백신 종류 확인
    function getVaccineType(uint8 _vaccineType) public view returns (string memory) { 
        return vaccineEnum[_vaccineType];
    }

    //백신 접종 회차 추가
    function changeStatus(address _vaccineAddress) onlyIssuer public returns (bool){
        require(credentials[_vaccineAddress].statusType >=1); // 접종자 확인
        credentials[_vaccineAddress].statusType += 1;
        return true;
    }

    //백신 접종 2주 경과 여부
    function checkTwoWeeks(address _vaccineAddress) public view returns (bool) {
         return ((block.timestamp-(credentials[_vaccineAddress].createDate)) > 2 weeks);
    }

}
