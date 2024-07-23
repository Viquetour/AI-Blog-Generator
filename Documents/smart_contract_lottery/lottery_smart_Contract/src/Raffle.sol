//SPDX-License-Identifier: MIT
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
pragma solidity 0.8.25;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

/**
* @title A sample Raffle Contract
* @author Victor Ubi 
* @notice This contract is for creating a simple raffle
* @dev Implements chainlink VRFv2
*/ 

contract Raffle is VRFConsumerBaseV2 {

  
         
         error Raffle__NotEnoughEthSent();
         error Raffle__TransferFailed();
         error Raffle__RaffleNotOpen();
         error Raffle__upKeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);

         //bool lotteryState = open, closed, calculating
         /*Type declarations*/ 

         enum RaffleState {
            OPEN, //0
            CALCULATING //1
         }

         /**STATE VARIABLES */
    uint16 private constant REQUEST_CONFIRMATIONS = 3; 
    uint32 private constant NUM_WORDS = 1;    
    
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    //uint256 private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLine;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;


    address payable [] private s_players; 
    uint256 private s_lastTimestamp; 
    address private s_recentWinner;
    RaffleState private s_raffleState;
     
    /** EVENTS */ 
    event EnteredRaffle(address indexed player);
    event PickedWinner(address indexed winner);

    constructor(uint256 entranceFee, uint256 interval, 
    address vrfCoordinator, bytes32 gasLine, uint64 subscriptionId,
    uint32 callbackGasLimit)VRFConsumerBaseV2(vrfCoordinator){
       i_entranceFee = entranceFee;
       i_interval = interval;
       i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
       i_gasLine = gasLine;
       i_subscriptionId = subscriptionId;
       i_callbackGasLimit = callbackGasLimit;
       s_raffleState = RaffleState.OPEN;
       s_lastTimestamp = block.timestamp;
       
    }

function enterRaffle() external payable{
     if (msg.value < i_entranceFee) {
        revert Raffle__NotEnoughEthSent();
     }
     if (s_raffleState != RaffleState.OPEN){
      revert Raffle__RaffleNotOpen();
     }
       s_players.push(payable(msg.sender));
      // 1. makes migration easier
      // 2. makes front end "indexing" easier

      emit EnteredRaffle(msg.sender);

    } 

  //1. Get a random number
  //2. Use the random number to pick a player
  //3. Be automatically called
  ////////////////////////////////////////
  ////                                ///
  ///////////////////////////////////////

  //When is the winner supposed to be picked?
  /**
  * @dev This is the function that the chainlink Automation nodes call
  * to see if it's time to perform an upkeep.
  * the following should be true for this to return true:
  * 1. The time interval has passed between raffle runs
  * 2.the raffle is in the OPEN state
  * 3. The contract has ETH(aka, players!)
  * 4. (Implicit)The subscription is founded with Link
  */

    function checkUpKeep( bytes memory /* checkData */)
     public view  returns(bool upKeepNeeded, bytes memory /*performData */ ){
       bool timeHasPassed = (block.timestamp - s_lastTimestamp) >= i_interval;
       bool isOpen = RaffleState.OPEN == s_raffleState;
       bool hasBalance = address(this).balance > 0;   
       upKeepNeeded =  (timeHasPassed && isOpen && hasBalance);
       return(upKeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /*performData*/ ) external {
         (bool upKeepNeeded,) = checkUpKeep("");

         if (!upKeepNeeded) {
          revert Raffle__upKeepNotNeeded(
            address(this).balance,
            s_players.length,
            uint256(s_raffleState)
          );
         }
         // check to see if enough time has passed
         //1200 - 500. 600 seconds
        s_raffleState  = RaffleState.CALCULATING;
        i_vrfCoordinator.requestRandomWords(
            i_gasLine,
            i_subscriptionId,
             REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        //1.  Request the RMG 
        //2. Get the random number
    }
////////CHECKS EFFECTS INTERACTIONS 
    function fulfillRandomWords(
        uint256 /*requestId */,
        uint256[] memory randomWords
    ) internal override {
      //Checks
      //Effects Our Own Contract
      uint256 indexOfWinner = randomWords[0] % s_players.length;
      address payable winner = s_players[indexOfWinner]; 
      s_recentWinner = winner;
      s_raffleState = RaffleState.OPEN;


      s_players = new address payable[](0);
      s_lastTimestamp = block.timestamp;
      emit PickedWinner(winner);
      //Interactions (Other contracts)
      (bool success,) = winner.call{value: address(this).balance}("");

      if (!success){
        revert Raffle__TransferFailed();
      }
      
    }
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /**Getter function */

    function getEntranceFee() external view returns(uint256){
        return i_entranceFee;    
    }
    function getRaffleState() external view returns(RaffleState) {
       return s_raffleState;
    }

    function getPlayer(uint256 indexOfPlayer) external view returns(address) {
      return s_players[indexOfPlayer];
    } 
}
