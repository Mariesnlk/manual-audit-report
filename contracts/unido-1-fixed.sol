// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

contract Ownable {
    address public owner;
    address private _nextOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the owner of the contract can do that"
        );
        _;
    }

    function transferOwnership(address nextOwner) public onlyOwner {
        _nextOwner = nextOwner;
    }

    function takeOwnership() public {
        require(msg.sender == _nextOwner, "Must be given ownership to do that");
        emit OwnershipTransferred(owner, _nextOwner);
        owner = _nextOwner;
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b != 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract UnidoDistribution is Ownable {
    using SafeMath for uint256;

    // 0 - SEED
    // 1 - PRIVATE
    // 2 - TEAM
    // 3 - ADVISOR
    // 4 - ECOSYSTEM
    // 5 - LIQUIDITY
    // 6 - RESERVE
    enum POOL {
        SEED,
        PRIVATE,
        TEAM,
        ADVISOR,
        ECOSYSTEM,
        LIQUIDITY,
        RESERVE
    }

    string public constant name = "Unido";
    uint256 public constant decimals = 18;
    string public constant symbol = "UDO";
    uint256 private constant ten_decimals = 10**18;

    bool private isActive;
    // TODO move to constructor as it chenged
    uint256 private scanLength = 150;
    uint256 private continuePoint;
    uint256[] private deletions;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    // TODO enum cannot be key value in mapping
    mapping(uint8 => uint256) public pools;

    uint256 public totalSupply;
    address[] public participants;

    mapping(address => uint256) public lockoutPeriods;
    mapping(address => uint256) public lockoutBalances;
    mapping(address => uint256) public lockoutReleaseRates;

    event Active(bool isActive);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Burn(address indexed tokenOwner, uint256 tokens);

    constructor() {
        // TODO is it good?
        pools[uint8(POOL.SEED)] = 15000000 * decimals;
        pools[uint8(POOL.PRIVATE)] = 16000000 * decimals;
        pools[uint8(POOL.TEAM)] = 18400000 * decimals;
        pools[uint8(POOL.ADVISOR)] = 10350000 * decimals;
        pools[uint8(POOL.ECOSYSTEM)] = 14375000 * decimals;
        pools[uint8(POOL.LIQUIDITY)] = 8625000 * decimals;
        pools[uint8(POOL.RESERVE)] = 32250000 * decimals;

        // TODO is it good?
        // set this variable once
        totalSupply =
            pools[uint8(POOL.SEED)] +
            pools[uint8(POOL.PRIVATE)] +
            pools[uint8(POOL.TEAM)] +
            pools[uint8(POOL.ADVISOR)] +
            pools[uint8(POOL.ECOSYSTEM)] +
            pools[uint8(POOL.LIQUIDIT)] +
            pools[uint8(POOL.RESERVE)];

        // Give POLS private sale directly
        // TODO make it static and not declare in the constructor
        uint256 pols = 2000000 * 10**decimals;
        pools[uint8(POOL.PRIVATE)] = pools[uint8(POOL.PRIVATE)].sub(pols);
        // TODO unsafe to use the address in the code
        balances[address(0xeFF02cB28A05EebF76cB6aF993984731df8479b1)] = pols;

        // Give LIQUIDITY pool their half directly
        uint256 liquid = pools[POOL.LIQUIDITY].div(2);
        pools[uint8(POOL.LIQUIDITY)] = pools[uint8(POOL.LIQUIDITY)].sub(liquid);
        balances[address(0xd6221a4f8880e9Aa355079F039a6012555556974)] = liquid;
    }

    // TODO order of functions external public internal private view/pure

    // TODO should  return isActive;
    function isTradeable() public view returns (bool) {
        return isActive;
    }

    function setTradeable() external onlyOwner {
        require(
            !isActive,
            "Can only set tradeable when its not already tradeable"
        );
        isActive = true;

        emit Active(true);
    }

    // TODO moved the declaration of  scanLength to constructor or add event for setting to track this value
    function setScanLength(uint256 len) external onlyOwner {
        scanLength = len;
    }

    function balanceOf(address tokenOwner) external view returns (uint256) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender)
        external
        view
        returns (uint256)
    {
        return allowances[tokenOwner][spender];
    }

    // Maybe pure???
    function spendable(address tokenOwner) external view returns (uint256) {
        return balances[tokenOwner].sub(lockoutBalances[tokenOwner]);
    }

    function transfer(address to, uint256 tokens) external returns (bool) {
        require(tokens > 0, "Must transfer non-zero amount");
        require(to != address(0), "Cannot send to the 0 address");
        require(isTradeable(), "Contract is not tradeable yet");
        require(
            balances[msg.sender].sub(lockoutBalances[msg.sender]) >= tokens,
            "Must have enough spendable tokens"
        );

        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);

        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    // maybe check for spender and addedValue
    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    // maybe check for spender and subtractedValue
    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            allowances[msg.sender][spender].sub(subtractedValue)
        );
        return true;
    }

    function approve(address spender, uint256 tokens) external returns (bool) {
        _approve(msg.sender, spender, tokens);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 tokens
    ) private {
        require(owner != address(0), "Cannot approve from the 0 address");
        require(spender != address(0), "Cannot approve the 0 address");

        allowances[owner][spender] = tokens;

        emit Approval(owner, spender, tokens);
    }

    function burn(uint256 tokens) external {
        require(tokens > 0, "Must burn non-zero amount");
        require(
            balances[msg.sender].sub(lockoutBalances[msg.sender]) >= tokens,
            "Must have enough spendable tokens"
        );

        balances[msg.sender] = balances[msg.sender].sub(tokens);
        totalSupply = totalSupply.sub(tokens);

        emit Burn(msg.sender, tokens);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external returns (bool) {
        require(tokens > 0, "Must transfer non-zero amount");
        require(from != address(0), "Cannot send from the 0 address");
        require(to != address(0), "Cannot send to the 0 address");

        require(isTradeable(), "Contract is not trading yet");
        require(
            balances[from].sub(lockoutBalances[from]) >= tokens,
            "Must have enough spendable tokens"
        );
        require(
            allowances[from][msg.sender] >= tokens,
            "Must be approved to spend that much"
        );

        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        // TODO maybe move to the 366 line
        allowances[from][msg.sender] = allowances[from][msg.sender].sub(tokens);
        
        emit Transfer(from, to, tokens);
        return true;
    }

    // TODO function has cyclomatic complexity 9 but allowed no more than 7
    function addParticipants(
        POOL pool,
        address[] calldata _participants,
        uint256[] calldata _stakes
    ) external onlyOwner {
        require(
            _participants.length == _stakes.length,
            "Must have equal array sizes"
        );

        uint256 lockoutPeriod;
        uint256 lockoutReleaseRate;

        if (pool == POOL.SEED) {
            lockoutPeriod = 1;
            lockoutReleaseRate = 5;
        } else if (pool == POOL.PRIVATE) {
            lockoutReleaseRate = 4;
        } else if (pool == POOL.TEAM) {
            lockoutPeriod = 12;
            lockoutReleaseRate = 12;
        } else if (pool == POOL.ADVISOR) {
            lockoutPeriod = 6;
            lockoutReleaseRate = 6;
        } else if (pool == POOL.ECOSYSTEM) {
            lockoutPeriod = 3;
            lockoutReleaseRate = 9;
        } else if (pool == POOL.LIQUIDITY) {
            lockoutReleaseRate = 1;
            lockoutPeriod = 1;
        } else if (pool == POOL.RESERVE) {
            lockoutReleaseRate = 18;
        }

        uint256 sum;
        // TODO unused
        uint256 len = _participants.length;
        // TODO used _participants.length
        for (uint256 i = 0; i < len; i++) {
            // TODO unclear declaration of p
            address p = _participants[i];
            // TODO reqire message is too long
            require(
                lockoutBalances[p] == 0,
                "Participants can't be involved"
            );

            // TODO is not emitting Transfer event on assigning tokens to participants addresses
            participants.push(p);
            lockoutBalances[p] = _stakes[i];
            balances[p] = balances[p].add(_stakes[i]);
            lockoutPeriods[p] = lockoutPeriod;
            lockoutReleaseRates[p] = lockoutReleaseRate;
            sum = sum.add(_stakes[i]);
        }

        require(
            sum <= pools[pool],
            "Insufficient amount left in pool for this"
        );
        pools[pool] = pools[pool].sub(sum);
    }

    // TODO 447 446
    function finalizeParticipants(POOL pool) external onlyOwner {
        uint256 leftover = pools[pool];
        pools[pool] = 0;
        totalSupply = totalSupply.sub(leftover);
    }

    /**
     * For each account with an active lockout, if their lockout has expired
     * then release their lockout at the lockout release rate
     * If the lockout release rate is 0, assume its all released at the date
     * Only do max 100 at a time, call repeatedly which it returns true
     */
    function updateRelease() external onlyOwner returns (bool) {
        // TODO unnecessary declaration
        uint256 scan = scanLength;
        // TODO unnecessary declaration
        uint256 len = participants.length;
        // TODO not clear declaration
        uint256 continueAddScan = continuePoint.add(scan);
        
        for (uint256 i = continuePoint; i < len && i < continueAddScan; i++) {
            address participant = participants[i];

            if (lockoutPeriods[participant] > 0) {
                lockoutPeriods[participant]--;
            } else if (lockoutReleaseRates[participant] > 0) {
                uint256 rate = lockoutReleaseRates[participant];

                // TODO inclear and unused variable
                uint256 release;
                if (rate == 18) {
                    // First release of reserve is 12.5%
                    release = lockoutBalances[participant].div(8);
                } else {
                    // TODO why not rate???
                    release = lockoutBalances[participant].div(lockoutReleaseRates[participant]);
                }

                lockoutBalances[participant] = lockoutBalances[p].sub(release);
                lockoutReleaseRates[participant]--;
            } else {
                deletions.push(i);
            }
        }

        continuePoint = continuePoint.add(scan);

        if (continuePoint >= len) {
            continuePoint = 0;
            while (deletions.length > 0) {
                uint256 index = deletions[deletions.length - 1];
                deletions.pop();

                participants[index] = participants[participants.length - 1];
                participants.pop();
            }
            return false;
        }

        return true;
    }

    // no withdraw function
}
