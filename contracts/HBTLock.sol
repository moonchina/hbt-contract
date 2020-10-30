pragma solidity 0.6.12;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
// import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract HBTLock is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public blockTime = 15;       //出块时长
    uint256 public timesAwardTotal;      //倍数总奖励
    uint256 public depositTotal;         //抵押总数量
    uint256 public pickDepositTotal;     //已解锁数量
    uint256 public pickTimesAwardTotal;  //已解锁倍数奖励

    address public masterChef;
    IERC20 public hbtSafe;
    unit256 public depositCountTotal = 100;   //用户最大抵押次数

    //锁定记录struct
    struct DepositInfo {
        uint256 endBlock;    //抵押结束区块号
        uint256 number;      //抵押数量
        uint256 times;       //倍数
    }
    mapping (address => DepositInfo[]) public depositInfo;    //锁定记录

    //用户信息
    struct UserInfo {
        uint256 timesAward;         //倍数奖励
        uint256 deposit;            //抵押数量
        uint256 pickDeposit;        //已解锁数量
        uint256 pickTimesAward;     //已解锁倍数奖励
        uint256 depositCount;       //抵押次数
    }
    mapping (address => UserInfo) public userInfo;    //用户记录

    //times
    mapping (uint256 => uint256) times;

    constructor(
        IERC20 _hbt          //HBT Token合约地址
    ) public {
        hbtSafe = _hbt;

        times[15] = 300;
        times[20] = 600;
        times[25] = 1200;
    }

    //masterChef  
    function setMasterChef(address _address) public  onlyOwner {
        masterChef = _address;
    }

    //抵押
    function disposit(address _address, uint256 _number, uint256 _times) public returns (bool) {
        require(_number > 0, "HBTLock:disposit _number Less than zero");
        require(times[_times] > 0, "HBTLock:disposit _times Less than zero");
        require(msg.sender == masterChef, "HBTLock:msg.sender Not equal to masterChef");

        uint256 _endBlockTime = times[_times];
        timesAwardTotal = timesAwardTotal.add(_number.mul(_times).div(10)).sub(_number);
        depositTotal = depositTotal.add(_number);

        userInfo[_address].timesAward.add(_number.mul(_times).div(10).sub(_number));
        userInfo[_address].deposit.add(_number);

        uint256 _endBlock = _endBlockTime.mul(1e12).div(blockTime).div(1e12).add(block.number); //结束时间
        depositInfo[_address].push(DepositInfo({
            endBlock: _endBlock,
            number: _number,
            times: _times
        }));

        return true;
    }

    //可解锁数量
    function unlockInfo(address _address) public view returns (uint256, uint256) {
        uint256 _blcokNumber = block.number;
        uint256 length = depositInfo[_address].length;

        uint256 unlockNumber;
        uint256 unlockDispositNumber;
        for (uint256 id = 0; id < length; ++id) {
            if(depositInfo[_address][id].endBlock < _blcokNumber) {
                unlockNumber = unlockNumber.add(depositInfo[_address][id].number.mul(depositInfo[_address][id].times).div(10));
                unlockDispositNumber = unlockDispositNumber.add(depositInfo[_address][id].number);
            }
        }
        //可解锁数量 = 总抵押量 - 用户已抵押提取量 - 用户分红提取量
        unlockNumber =  unlockNumber.sub(userInfo[_address].pickDeposit).sub(userInfo[_address].pickTimesAward);
        unlockDispositNumber = unlockDispositNumber.sub(userInfo[_address].pickDeposit);

        return (unlockNumber,unlockDispositNumber);
    }
    
    //提取  提完现 
    function  withdraw() public {

        uint256 unlockNumber;
        uint256 unlockDispositNumber;
        address _address = address(msg.sender);

        ( unlockNumber, unlockDispositNumber) = unlockInfo(_address);
        require(unlockNumber > 0 , "HBTLock: unlock number Less than zero");


        hbtSafe.safeTransfer(_address,unlockNumber);
        // hbtSafe.safeTransferFrom(address(this),_address,unlockNumber);

        pickDepositTotal = pickDepositTotal.add(unlockDispositNumber);
        pickTimesAwardTotal = pickTimesAwardTotal.add(unlockNumber.sub(unlockDispositNumber));

        userInfo[_address].pickDeposit = userInfo[_address].pickDeposit.add(unlockDispositNumber);
        userInfo[_address].pickTimesAward = userInfo[_address].pickTimesAward.add(unlockNumber.sub(unlockDispositNumber));
    }
}
