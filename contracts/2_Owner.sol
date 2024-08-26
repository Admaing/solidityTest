// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "hardhat/console.sol";

contract Worldcup{
    address public admin;
    uint8 public currRound;
    uint256 public immutable deadline;
    uint256 public lockedAmts;

    enum Country{
        CHINA,
        FRANCH,
        KOREA
    }
    struct Player{
        bool isSet;
        mapping(Country=>uint256) counts;  //投注国
    }

    mapping(uint256=>mapping (address=>Player)) players;
    mapping (uint256=>mapping ( Country=>address[])) public countryToPlayers;
    mapping(address=>uint256)public winnerVaults;


    event Play(uint8 _currRound, address _player, Country _country);
    event Finialize(uint8 _currRound, uint256 _country);
    event ClaimReward(address _claimer, uint256 _amt);

    modifier onlyAdmin{
        require(msg.sender==admin,"not authorized");
        _;
    }
    constructor(uint256 _deadline) {
        admin = msg.sender;
        require(_deadline > block.timestamp, "WorldCupLottery: invalid deadline!");
        deadline = _deadline;
    }
    function play(Country _selected) external payable{
        //投注限制1
        require(msg.value==1 gwei,"invalid funds provided");
        require(block.timestamp< deadline,"it's all over");
        countryToPlayers[currRound][_selected].push(msg.sender);
        //引用？ 使用memory不会更改其中的值
        Player storage player = players[currRound][msg.sender];
        player.counts[_selected] +=1;
         emit Play(currRound, msg.sender, _selected);
    }
    //最终使用oracle
    function finialize(Country _country)onlyAdmin external {
        address[] memory winners = countryToPlayers[currRound][_country];
        uint256 distributeAmt;
        uint curBalance = getVaultBalance()-lockedAmts;
        for(uint i=0; i<winners.length; i++){
            address currWinner = winners[i];
            Player storage winner = players[currRound][currWinner];
            if (winner.isSet){
                console.log("this winner has been set already, will be skipped!");
                continue;
            }
            winner.isSet = true;
            uint currCounts = winner.counts[_country];
            //根据比例分配
            uint amt = (curBalance/countryToPlayers[currRound][_country].length)*currCounts;
            winnerVaults[currWinner] +=amt;
            distributeAmt +=amt;
            //如果之前几期没领过，新的一期应该不可以领所有的，智能领取当期
            lockedAmts +=amt;
            console.log("winner:", currWinner, "currCounts:", currCounts);
            console.log("reward amt curr:", amt, "total:", winnerVaults[currWinner]);
        }
                uint giftAmt = curBalance - distributeAmt;
        if (giftAmt > 0) {
            winnerVaults[admin] += giftAmt;
        }

        emit Finialize(currRound++, uint256(_country));
    }
    //获取这个用户这个国家投了多少注
    function getPlayerInfo(uint8 _round, address _player, Country _country)external view returns(uint256){
        return players[_round][_player].counts[_country];
    }

    function getCountryPlayersCount(uint8 _round, Country _country)external view returns(uint256){
        return countryToPlayers[_round][_country].length;
    }

    function getVaultBalance()public view returns(uint256){
        return address(this).balance;
    }
    function claimReward()external {
        uint256 rewards = winnerVaults[msg.sender];
        require(rewards>0,"nothing to claim");
        winnerVaults[msg.sender] = 0;
        lockedAmts -= rewards;
       (bool succeed,) = msg.sender.call{value: rewards}("");
       emit ClaimReward(msg.sender, rewards);
    }
}