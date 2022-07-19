//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Casino {

  struct ProposedBet {
    address sideA;
    uint value;
    uint placedAt;
    bool accepted;
       
  }    // struct ProposedBet


  struct AcceptedBet {
    address sideB;
    uint acceptedAt;
    uint randomB;
    uint hashB;
    bool Brevealed;
  }   // struct AcceptedBet

  // Proposed bets, keyed by the commitment value
  mapping(uint => ProposedBet) public proposedBet;

  // Accepted bets, also keyed by commitment value
  mapping(uint => AcceptedBet) public acceptedBet;

  event BetProposed (
    uint indexed _commitment,
    uint value
  );

  event BetAccepted (
    uint indexed _commitmentA,
    uint indexed _commitmentB,
    address indexed _sideA,
    address  _sideB
  );


  event BetSettled (
    uint indexed _commitment,
    address winner,
    address loser,
    uint value    
  );


  // Called by sideA to start the process
  function proposeBet(uint _commitment) external payable {
    require(proposedBet[_commitment].value == 0,
      "there is already a bet on that commitment");
    require(msg.value > 0,
      "you need to actually bet something");

    proposedBet[_commitment].sideA = msg.sender;
    proposedBet[_commitment].value = msg.value;
    proposedBet[_commitment].placedAt = block.timestamp;
    // accepted is false by default

    emit BetProposed(_commitment, msg.value);
  }  // function proposeBet


  // Called by sideB to continue
  function acceptBet(uint _commitmentA, uint _commitmentB) external payable {

    require(!proposedBet[_commitmentA].accepted,
      "Bet has already been accepted");
    require(proposedBet[_commitmentA].sideA != address(0),
      "Nobody made that bet");
    require(msg.value == proposedBet[_commitmentA].value,
      "Need to bet the same amount as sideA");

    acceptedBet[_commitmentA].sideB = msg.sender;
    acceptedBet[_commitmentA].acceptedAt = block.timestamp;
    acceptedBet[_commitmentA].hashB = _commitmentB;
    // proposedBet[_commitmentB].sideA = proposedBet[_commitmentA].sideA; //Store the commitment to point the address of side A
    proposedBet[_commitmentA].accepted = true;

    emit BetAccepted(_commitmentA,_commitmentB, proposedBet[_commitmentA].sideA,acceptedBet[_commitmentA].sideB);
  }   // function acceptBet

  /*function getOrginalRandomByA(uint256 _random) public {
      require(proposedBet[_commitmentA].accepted,
      "Bet has not been accepted");
      uint _commitmentA = uint256(keccak256(abi.encodePacked(_random)));
            acceptedBet[_commitmentA].randomA=_random;
  }*/
  function getOrginalRandomByB(uint256 _random,uint _commitmentA) public {
      require(proposedBet[_commitmentA].accepted,
      "Bet has not been accepted");
      uint _commitmentB = uint256(keccak256(abi.encodePacked(_random)));
            require(acceptedBet[_commitmentA].hashB == _commitmentB,"Wrong Value of B");
            acceptedBet[_commitmentA].randomB=_random;
            acceptedBet[_commitmentA].Brevealed=true;

  }


  // Called by sideA to reveal their random value and conclude the bet
  function reveal(uint _random) external {
      
    uint _commitment = uint256(keccak256(abi.encodePacked(_random)));
    require(acceptedBet[_commitment].Brevealed,"B Not revealed Yet Or Wrong Value of you random Number");
    address payable _sideA = payable(msg.sender);
    address payable _sideB = payable(acceptedBet[_commitment].sideB);
    uint _agreedRandom = _random ^ acceptedBet[_commitment].randomB;
    uint _value = proposedBet[_commitment].value;

    require(proposedBet[_commitment].sideA == msg.sender,
      "Not a bet you placed or wrong value");
    require(proposedBet[_commitment].accepted,
      "Bet has not been accepted yet");

    // Pay and emit an event
    if (_agreedRandom % 2 == 0) {
      // sideA wins
      _sideA.transfer(2*_value);
      emit BetSettled(_commitment, _sideA, _sideB, _value);
    } else {
      // sideB wins
      _sideB.transfer(2*_value);
      emit BetSettled(_commitment, _sideB, _sideA, _value);      
    }

    // Cleanup
    delete proposedBet[_commitment];
    delete acceptedBet[_commitment];

  }  // function reveal

}   // contract Casino
