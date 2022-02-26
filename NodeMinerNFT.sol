pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NMFT is ERC721, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;
  
  uint256 public cost = 3 ;
  uint256 public maxSupply = 3025;
  uint256 public maxMintAmountPerTx = 5;
  uint256 public presaleSupply = 25;
  uint256 public nftPerAddressLimit = 10;
  bool public paused = true;
  bool public revealed = false;
  mapping(address => uint256) public addressMintedBalance;

  constructor(
    string memory _name,
    string memory _symbol,
    address treasury
  ) ERC721(_name,_symbol) {
      _mintLoop(treasury,presaleSupply);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(!paused, "The contract is paused!");
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) { 
    uint256 nftCost = cost;
    require(msg.value >= nftCost * _mintAmount, "insufficient funds");
    uint256 ownerMintedCount = addressMintedBalance[msg.sender];
    require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "Max NFT per address exceeded");
    _mintLoop(msg.sender, _mintAmount);
    addressMintedBalance[msg.sender] = addressMintedBalance[msg.sender]+_mintAmount;
        if (totalSupply() >= maxSupply) {
          setPaused(true);
        } 
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
   {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
      require(
        _exists(_tokenId),
        "ERC721Metadata: URI query for nonexistent token"
      );

      if (revealed == false) {
        return hiddenMetadataUri;
      }

      string memory currentBaseURI = _baseURI();
      return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }
 
  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }
  function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os); 
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal   {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}
