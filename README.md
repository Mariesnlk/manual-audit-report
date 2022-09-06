# audit-smart-contract

# Manual Report
## Unresolved, High: Event invocations have to be prefixed by "emit"
In UnidoDistribution smart contract all events used without prefix emit.
Recommendation: add prefix emit to all events that are used in UnidoDistribution.

# Unresolved, High: Unclear token for transfering
UnidoDistribution smart contract is saved balances of participates and has the same logic as ERC-20 token. Transfer and transferFrom functions can be called only to transfer ERC-20 token. 
Recommendation: add ERC-20 token to the contract or import one from library @openzeppelin/contracts

# Unresolved, High: Not automatically unlocked funds
UnidoDistribution smart contract has function updateRelease(), which not automatically unlocked distribution token amounts and require the owner to unblock it manually every time making the new transaction.
Recommendation: make lockoutPeriod and lockoutReleaseRates variables depend on the block.timestamp and rewrite the logic of updateRelease() function.

# Unresolved, Medium: Absence of emergency withdrawing of funds 
In UnidoDistribution smart contract is saved balances of participates with amount that will be partially unlocked over time and available for withdrawal.
Recommendation: add withdraw function where every participant can withdraw the amount of his balance.

# Unresolved, Low: Used Enum as key for mapping
In UnidoDistribution smart contract is used mapping(POOL => uint256) public pools with POOL enum as key type. 
Recommendation: Enums are not allowed to be used as a key inside the mappings. Since enums member represented by units
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

instead of Enum as key type in the mapping can be used uint8
mapping(uint8 => uint256) public pools

# Unresolved, Low: Useless function
In UnidoDistribution Smart Contract is used function _isTradeable() internal view returns (bool) that calls only once in the function isTradeable().
Recommendation: delete the function _isTradeable() and return isActive value in isTradeable() function. 

# Unresolved, Low: Declare state in function except of constructor
In UnidoDistribution Smart Contract is used variable isActive. By default it is false. The true value setted in the function setTradeable(). Due to the require that checks is it is tradeable or not and setted only to true value.
Recommendation: move isActive = true; to the constructor and delete the function setTradeable().

# Unresolved, Low: Inappropriate function visability
In UnidoDistribution Smart Contract the next functions with public visability are not call inside the contract:
function balanceOf(address tokenOwner) public view returns (uint256)
function allowance(address tokenOwner, address spender) public view returns (uint256)
function spendable(address tokenOwner) public view returns (uint256)
function transfer(address to, uint256 tokens) public returns (bool)
function increaseAllowance(address spender, uint256 addedValue) public returns (bool)
function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool)
function approve(address spender, uint256 tokens) public returns (bool)
The function _approve(address owner, address spender, uint256 tokens) internal called only inside the contract as helper function and as we do not have another contract that will be inherited by UnidoDistribution - it can be declared s internal.
Recommendation: declare balanceOf, allowance, spendable, transfer, increaseAllowance, decreaseAllowance, approve - external.
Declare  _approve - internal

# Unresolved, Low: Incorrect order of require in function
UnidoDistribution Smart Contract has functions transfer(), burn()and transferFrom() where require checks are not in the order of the passed input data. 
Recommendation: reorder requires. First should be checked incoming parameters, then all necessary checks

# Unresolved, Low: Absence of require checking
UnidoDistribution function _approve() and addParticipants() requirements to check incoming parameters to avoid unpdedicted transaction revert.
Recommendation: Add require for all incoming parameters.

# Unresolved, Low: Cyclomatic complexity
UnidoDistribution function addParticipants() has cyclomatic complexity 9, but allowed no more than 7.
Recommendation: Rewrite if-else condition to increase cyclomatic complexity.

# Unresolved, Low: Untriggered require
UnidoDistribution function addParticipants() has require checking that checks if the passed parameter is in the range of values of enum Pool. But blockchain will always reverted transaction with nonexistent enum value.
Recommendation: delete require for the enum.

# Unresolved, Low: Error message for require is too long
Error message for require can be not more than 120 chars length.
Recommendation: reduce size of the error message in requires.

# Unresolved, Low: Abcent events for token transfering
In UnidoDistribution smart contract function addParticipants() is missed event Transfer to track changings in balances of the participants after adding them to the list.
Recommendation: add an event to track changes in the balance of participants.

# Unresolved, Low: Abcent of zero checking
In UnidoDistribution smart contract function finalizeParticipants() is missed checking for zero value in mapping.
Recommendation: add check for zero value in mapping pools[pool].

# Unresolved, Low: Avoid stack to deep
In UnidoDistribution smart contract 3 mapping has the same key - address of the participants that is used more slots than it`s possible (ma 16 elements counting from the top to the downwards). 
Recommendation: to avoid “stack to deep” in the future reorganize 3 mapping lockoutPeriods, lockoutBalances, lockoutReleaseRates to one struct with the next fields:
address participant;
uint256 lockoutPeriod;
uint256 lockoutBalance;
uint256 lockoutReleaseRate;

# Unresolved, Informational: Incorrect layout
In unido-1 Smart Contract has 3 different contracts (contract UnidoDistribution, library SafeMath, contract Ownable) in one file unido-1.sol
Recommendation: split unido-1.sol for 3 different files

# Unresolved, Informational: Incorrect order of layout, functions
In UnidoDistribution Smart Contract has 3 different contracts in the next order :
contract Ownable
library SafeMath
contract UnidoDistribution

Also, declared variables don`t order to their type declaration.
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
Recommendation: layouts, functions and modifier order should be grouped according to Solidity documantation:
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


# Unresolved, Informational: Used custom contracts instead of OpenZeppelin
In unido-1 Smart Contract is 2 custom contracts contract Ownable and library SafeMath.
Recommendation: use @openzeppelin/contracts library as import 
import “@openzeppelin/contracts/access/Ownable.sol”
import “@aopenzeppelin/contracts/utils/math/SafeMath.sol”

# Unresolved, Informational: Not covered by NatSpec
The unido-1 Smart Contract is not covered with NatSpec.
Recommendation: add NatSpec to functions and variables using Solidity documentation for NatSpec.

# Unresolved, Informational: Uncleared naming
In UnidoDistribution  smart contract rename some functions and variables naming to clear the meaning (e.g. addParticipants function do not saved only participants addresses butalso stakes)
Recommendation: rename functions whose names do not correspond to their functionality and rename variables with one letter or short form.

 
