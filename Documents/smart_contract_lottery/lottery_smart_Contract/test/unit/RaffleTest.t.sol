//SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
contract RaffleTest is Test{
     /*Events */
     event EnterdRaffle(address indexed player);

    Raffle raffle;
    HelperConfig helperConfig;

    uint256 entranceFee;
    uint256 interval; 
    address vrfCoordinator;
    bytes32 gasLine;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address link;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    function setUp()external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        (
             entranceFee,
             interval, 
             vrfCoordinator,
             gasLine,
             subscriptionId,
             callbackGasLimit,
             link
        ) = helperConfig.activeNetworkConfig();
        vm.deal(PLAYER, STARTING_USER_BALANCE);
  
    
    }

    function TestRaffleInitializesInOpenState() public view{
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }
    /////////////////////////////////////
    // ENTERRAFFLE FUNCTION /////////////    
    ////////////////////////////////////

    function testRaffleRevertWhenYouDontPayEnough() public {
        //Arrange
        vm.prank(PLAYER);
        //Act / Assert
       vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector); 
       raffle.enterRaffle();
    }

    function testRaffleRecordsPlayerWhenTheyEnter() public {
         vm.prank(PLAYER);
         raffle.enterRaffle{value: entranceFee}();
         address playerRecorded = raffle.getPlayer(0);
         assert(playerRecorded == PLAYER);
    }
    function testEmitsEventOnEntrance() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit Raffle.EnteredRaffle(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }
    
    function testCantEnterWhenRaffleIsCalculating() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp +  interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep(""); 

        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

}