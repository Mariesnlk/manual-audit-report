
# Manual Report
## Unresolved, High: Shadowing State Variable
In *UnidoDistribution* smart contract in *_approve(...)* function with input parameter owner that shadows Ownable.owner variable.

**Recommendation:** Rename input parameter in  _approve(...) function.

## Unresolved, High: Partial using of SafeMath
In *UnidoDistribution* smart contract SafeMath library is unused for increment and decrement operations.

**Recommendation:** Add SafeMath to increment and decrement operations.

## Unresolved, High: Event invocations have to be prefixed by "emit"
In *UnidoDistribution* smart contract all events used without prefix emit.

**Recommendation:** add prefix emit to all events that are used in UnidoDistribution.

# Unresolved, High: Unclear token for transfering
*UnidoDistribution* smart contract is saved balances of participates and has the same logic as ERC-20 token. Transfer and transferFrom functions can be called only to transfer ERC-20 token. 

**Recommendation:**  add ERC-20 token to the contract or import one from library *@openzeppelin/contracts*

# Unresolved, High: Not automatically unlocked funds
*UnidoDistribution* smart contract has function *updateRelease()*, which not automatically unlocked distribution token amounts and require the owner to unblock it manually every time making the new transaction.

**Recommendation:**  make *lockoutPeriod* and *lockoutReleaseRates* variables depend on the *block.timestamp* and rewrite the logic of *updateRelease()* function.

# Unresolved, Medium: Absence of emergency withdrawing of funds 
In *UnidoDistribution* smart contract is saved balances of participates with amount that will be partially unlocked over time and available for withdrawal.

**Recommendation:**  add *withdraw* function where every participant can withdraw the amount of his balance.

# Unresolved, Low: Used Enum as key for mapping
In *UnidoDistribution* smart contract is used `mapping(POOL => uint256) public pools` with *POOL enum* as key type. 

**Recommendation:**  Enums are not allowed to be used as a key inside the mappings. Since enums member represented by units
```
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
```

instead of Enum as key type in the mapping can be used *uint8* 
`mapping(uint8 => uint256) public pools`

There could be used array:
**PoolInfo[7] public pools;**

# Unresolved, Low: Spendable functionality is unused
In *UnidoDistribution* smart contract uses a *spendable()* function but in the requirements *require(balances[msg.sender].sub(lockoutBalances[msg.sender]) >= tokens, "Must have enough spendable tokens");*
it is not used.

**Recommendation:** Change requirements to use *require(_spendable(spender) >= amount, "Must have enough spendable tokens");*

# Unresolved, Low: Useless function
In *UnidoDistribution* smart contract is used function *_isTradeable() internal view returns (bool)* that calls only once in the function *isTradeable()*.

**Recommendation:**  delete the function *_isTradeable()* and return *isActive* value in *isTradeable()* function. 

# Unresolved, Low: Declare state in function except of constructor
In *UnidoDistribution* smart contract is used variable *isActive*. By default it is *false*. The true value setted in the function *setTradeable()*. Due to the require that checks is it is tradeable or not and setted only to true value.

**Recommendation:**  move `isActive = true` to the constructor and delete the function *setTradeable()*.

# Unresolved, Low: Inappropriate function visability
In *UnidoDistribution* smart contract the next functions with public visability are not call inside the contract:
```
    function balanceOf(address tokenOwner) public view returns (uint256)
    function allowance(address tokenOwner, address spender) public view returns (uint256)
    function spendable(address tokenOwner) public view returns (uint256)
    function transfer(address to, uint256 tokens) public returns (bool)
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool)
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool)
    function approve(address spender, uint256 tokens) public returns (bool)
```
The function 
```
    _approve(address owner, address spender, uint256 tokens) internal 
```
called only inside the contract as helper function and as we do not have another contract that will be inherited by UnidoDistribution - it can be declared s internal.

**Recommendation:**  declare *balanceOf*, *allowance*, *spendable*, *transfer*, *increaseAllowance*, *decreaseAllowance*, *approve* - external.
Declare  *_approve* - internal.

# Unresolved, Low: Incorrect order of require in function
*UnidoDistribution* smart contract has functions *transfer()*, *burn()* and *transferFrom()* where require checks are not in the order of the passed input data. 

**Recommendation:**  reorder requires. First should be checked incoming parameters, then all necessary checks.

# Unresolved, Low: Setting value to zero instead of deleting it
The delete expression from storage definitely saves gas.

**Recommendation:** Consider changing the reset way.

# Unresolved, Low: Update release function code decreasing

**Recommendation:** Consider changing function code to:
```
    function updateRelease() external onlyOwner returns (bool) {
        uint256 len = participants.length;
        uint256 continueAddScan = _continuePoint.add(_scanLength);
        for (uint256 i = _continuePoint; i < len && i < continueAddScan; i++) {
            address p = participants[i];
            UserInfo storage data = participantsData[p];
            if (data.lockoutPeriod > 0) data.lockoutPeriod.sub(1);
            else if (data.lockoutReleaseRate > 0) {
                // First release of reserve is 12.5%
                data.lockoutBalance = data.lockoutBalance.sub(
                    data.lockoutReleaseRate == 18
                        ? data.lockoutBalance.div(8)
                        : data.lockoutBalance.div(data.lockoutReleaseRate)
                );
                data.lockoutReleaseRate.sub(1);
            } else _deletions.push(i);
        }
        _continuePoint = _continuePoint.add(_scanLength);
        if (_continuePoint >= len) {
            delete _continuePoint;
            while (_deletions.length > 0) {
                uint256 index = _deletions[_deletions.length.sub(1)];
                _deletions.pop();

                participants[index] = participants[participants.length.sub(1)];
                participants.pop();
            }
            return false;
        }

        return true;
    }
```

# Unresolved, Low: Absence of require checking
*UnidoDistribution* has function *_approve()* and *addParticipants()* requirements to check incoming parameters to avoid unpdedicted transaction revert.

**Recommendation:**  add require for all incoming parameters.

# Unresolved, Low: Balance & allowance functionality optimization
Private mappings and their getters could be rewritten from
```
mapping(address => uint256) private balances;
mapping(address => mapping(address => uint256)) private allowances;

function balanceOf(address tokenOwner) public view returns (uint256) {
   return balances[tokenOwner];
}

function allowance(address tokenOwner, address spender) public view returns (uint256) {
   return allowances[tokenOwner][spender];
}
```
to only:
```
mapping(address => uint256) public balanceOf;
mapping(address => mapping(address => uint256)) public allowance;
```

**Recommendation:** Consider optimization.

# Unresolved, Low: Transfer optimization
Transfer functionality could be rewritten to such way:
```
   function transfer(address to, uint256 tokens) external returns (bool) {
        return _transferFrom(msg.sender, to, tokens);
   }
 
    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external returns (bool) {
        return _transferFrom(from, to, tokens);
    }
    function _transferFrom(
        address from,
        address to,
        uint256 tokens
    ) internal notZeroAddress(from) notZeroAddress(to) notZero(tokens) onlySpendable(from, tokens) returns (bool) {
        require(isTradeable, "Contract is not trading yet");
        require(allowance[from][msg.sender] >= tokens, "Must be approved to spend that much");
 
        balanceOf[from] = balanceOf[from].sub(tokens);
        balanceOf[to] = balanceOf[to].add(tokens);
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(tokens);
 
        emit Transfer(from, to, tokens);
 
        return true;
```

# Unresolved, Low: Cyclomatic complexity
*UnidoDistribution* function *addParticipants()* has cyclomatic complexity 9, but allowed no more than 7. 
Instead of if-else condition in  *addParticipants()* function to optimize contract code could be added 
```
    struct PoolInfo {
        uint256 totalSupply;
        uint256 lockoutPeriod;
        uint256 lockoutReleaseRate;
    }
And constructor will have following body:
    constructor() {
        // SEED Setup
        pools[0].totalSupply = 15e24;
        pools[0].lockoutPeriod = 1;
        pools[0].lockoutReleaseRate = 5;

        // PRIVATE Setup
        pools[1].totalSupply = 14e24;
        pools[1].lockoutReleaseRate = 4;

        // TEAM Setup
        pools[2].totalSupply = 184e23;
        pools[2].lockoutPeriod = 12;
        pools[2].lockoutReleaseRate = 12;

        // ADVISOR Setup
        pools[3].totalSupply = 1035e22;
        pools[3].lockoutPeriod = 6;
        pools[3].lockoutReleaseRate = 6;

        // ECOSYSTEM Setup
        pools[4].totalSupply = 14375e21;
        pools[4].lockoutPeriod = 3;
        pools[4].lockoutReleaseRate = 9;

        // LIQUIDITY Setup
        pools[5].totalSupply = 43125e20;
        pools[5].lockoutPeriod = 1;
        pools[5].lockoutReleaseRate = 1;

        // RESERVE Setup
        pools[6].totalSupply = 3225e22;
        pools[6].lockoutReleaseRate = 18;

        totalSupply = 115e24;

        // Give POLS private sale directly
        balanceOf[0xeFF02cB28A05EebF76cB6aF993984731df8479b1] = 2e24;

        // Give LIQUIDITY pool their half directly
        balanceOf[0xd6221a4f8880e9Aa355079F039a6012555556974] = 43125e20;
    }
```

**Recommendation:** rewrite if-else condition to increase cyclomatic complexity. Consider optimization.

# Unresolved, Low: Untriggered require
*UnidoDistribution* function *addParticipants()* has require checking that checks if the passed parameter is in the range of values of enum *Pool*. But blockchain will always reverted transaction with nonexistent enum value.

**Recommendation:**  delete require for the enum.

# Unresolved, Low: Error message for require is too long
Error message for require can be not more than 120 chars length.

**Recommendation:**  reduce size of the error message in requires.

# Unresolved, Low: Not valid requirements
There are few checkings that always return true value:
in *_approve() function:* 
```require(owner_ != address(0), "Cannot approve from the 0 address");```
in *transferFrom() function:* ```require(from != address(0), "Cannot send from the 0 address");```
in *addParticipants() function:* ```require(pool >= POOL.SEED && pool <= POOL.RESERVE, "Must select a valid pool");```

**Recommendation:** Remove previous requirements.

# Unresolved, Low: Absent of modifier
In *UnidoDistribution* smart contract there are few identical requirements that could be added to modifiers before constructor.
For example:
```
    modifier notZeroAddress(address participant) {
        require(participant != address(0), "Error: Zero address");
        _;
    }

    modifier notZero(uint256 amount) {
        require(amount > 0, "Error: Zero amount");
        _;
    }

    modifier onlySpendable(address spender, uint256 amount) {
        require(_spendable(spender) >= amount, "Must have enough spendable tokens");
        _;
    }
```

**Recommendation:** consider decreasing contract code.


# Unresolved, Low: Abcent events for token transfering
In *UnidoDistribution* smart contract function *addParticipants()* is missed event Transfer to track changings in balances of the participants after adding them to the list.

**Recommendation:**  add an event to track changes in the balance of participants.

# Unresolved, Low: Abcent of zero checking
In *UnidoDistribution* smart contract function *finalizeParticipants()* is missed checking for zero value in mapping.

**Recommendation:**  add check for zero value in mapping pools[pool].

# Unresolved, Low: Avoid stack to deep
In *UnidoDistribution* smart contract 3 mapping has the same key - address of the participants that is used more slots than it`s possible (max 16 elements counting from the top to the downwards). 

**Recommendation:**  to avoid “stack to deep” in the future reorganize 3 mapping lockoutPeriods, lockoutBalances, lockoutReleaseRates to one struct with the next fields:
```
There could be created 
    struct UserInfo {
        uint256 lockoutPeriod;
        uint256 lockoutBalance;
        uint256 lockoutReleaseRate;
    }
for mapping(address => UserInfo) public participantsData;
```

# Unresolved, Informational: Incorrect layout
In *unido-1* smart contract has 3 different contracts `(contract UnidoDistribution, library SafeMath, contract Ownable)` in one file unido-1.sol

**Recommendation:**  split unido-1.sol for 3 different files

# Unresolved, Informational: Incorrect order of layout, functions
In *UnidoDistribution* smart contract has 3 different contracts in the next order :
```
    contract Ownable
    library SafeMath
    contract UnidoDistribution
```

Also, declared variables don`t order to their type declaration.
```
    uint256 public totalSupply;

    string public constant name = "Unido";
    uint256 public constant decimals = 18;
    string public constant symbol = "UDO";
    address[] public participants;

    bool private isActive;
    uint256 private scanLength = 150;
    uint256 private continuePoint;
    uint256[] private deletions;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    mapping(address => uint256) public lockoutPeriods;
    mapping(address => uint256) public lockoutBalances;
    mapping(address => uint256) public lockoutReleaseRates;
```
**Recommendation:**  layouts, functions and modifier order should be grouped according to Solidity documantation:
```
    Layouts:
        interfaces;
        libraries;
        contracts;
    Fnctions:
        constructor;
        receive;
        fallback;
        external;
        public;
        internal;
        private;
        view/pure;
```

# Unresolved, Informational: Used custom contracts instead of OpenZeppelin
In *unido-1* smart contract is 2 custom contracts contract Ownable and library SafeMath.

**Recommendation:**  use *@openzeppelin/contracts* library as import 
```
    import “@openzeppelin/contracts/access/Ownable.sol”
    import “@aopenzeppelin/contracts/utils/math/SafeMath.sol”
```

# Unresolved, Informational: Not covered by NatSpec
The *unido-1* smart contract is not covered with NatSpec.

**Recommendation:**  add NatSpec to functions and variables using Solidity documentation for NatSpec.

# Unresolved, Informational: Uncleared naming
In *UnidoDistribution*  smart contract rename some functions and variables naming to clear the meaning (e.g. *addParticipants* function do not saved only participants addresses butalso stakes)

**Recommendation:**  rename functions whose names do not correspond to their functionality and rename variables with one letter or short form.

# Unresolved, Informational: Naming style
In *UnidoDistribution* smart contract private variables names should start with *_(private visibility):*
```
    uint256 private _scanLength = 150;
    uint256 private _continuePoint;
    uint256[] private _deletions;
```

**Recommendation:** Consider naming style.


 
