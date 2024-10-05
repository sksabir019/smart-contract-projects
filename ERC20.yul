object "Token" {
    code {
        // Store the creator in slot zero.
        sstore(0, caller())

        // Deploy the contract
        datacopy(0, dataoffset("runtime"), datasize("runtime"))
        return(0, datasize("runtime"))
    }
    object "runtime" {
        code {
            // Protection against sending Ether
            require(iszero(callvalue()))

            // Dispatcher
            switch selector()
            case 0x70a08231 /* "balanceOf(address)" */ {
                returnUint(balanceOf(decodeAsAddress(0)))
            }
            case 0x18160ddd /* "totalSupply()" */ {
                returnUint(totalSupply())
            }
            case 0xa9059cbb /* "transfer(address,uint256)" */ {
                transfer(decodeAsAddress(0), decodeAsUint(1))
                returnTrue()
            }
            case 0x23b872dd /* "transferFrom(address,address,uint256)" */ {
                transferFrom(decodeAsAddress(0), decodeAsAddress(1), decodeAsUint(2))
                returnTrue()
            }
            case 0x095ea7b3 /* "approve(address,uint256)" */ {
                approve(decodeAsAddress(0), decodeAsUint(1))
                returnTrue()
            }
            case 0xdd62ed3e /* "allowance(address,address)" */ {
                returnUint(allowance(decodeAsAddress(0), decodeAsAddress(1)))
            }
            case 0x40c10f19 /* "mint(address,uint256)" */ {
                mint(decodeAsAddress(0), decodeAsUint(1))
                returnTrue()
            }
            default {
                revert(0, 0)
            }

            function mint(account, amount) {
                require(calledByOwner())

                mintTokens(amount)
                addToBalance(account, amount)
                emitTransfer(0, account, amount)
            }
            function transfer(to, amount) {
                executeTransfer(caller(), to, amount)
            }
            function approve(spender, amount) {
                revertIfZeroAddress(spender)
                setAllowance(caller(), spender, amount)
                emitApproval(caller(), spender, amount)
            }
            function transferFrom(from, to, amount) {
                decreaseAllowanceBy(from, caller(), amount)
                executeTransfer(from, to, amount)
            }

            function executeTransfer(from, to, amount) {
                revertIfZeroAddress(to)
                deductFromBalance(from, amount)
                addToBalance(to, amount)
                emitTransfer(from, to, amount)
            }


            /* ---------- calldata decoding functions ----------- */
            function selector() -> s {
                s := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)
            }

            function decodeAsAddress(offset) -> v {
                v := decodeAsUint(offset)
                if iszero(iszero(and(v, not(0xffffffffffffffffffffffffffffffffffffffff)))) {
                    revert(0, 0)
                }
            }
            function decodeAsUint(offset) -> v {
                let pos := add(4, mul(offset, 0x20))
                if lt(calldatasize(), add(pos, 0x20)) {
                    revert(0, 0)
                }
                v := calldataload(pos)
            }
            /* ---------- calldata encoding functions ---------- */
            function returnUint(v) {
                mstore(0, v)
                return(0, 0x20)
            }
            function returnTrue() {
                returnUint(1)
            }

            /* -------- events ---------- */
            function emitTransfer(from, to, amount) {
                let signatureHash := 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
                emitEvent(signatureHash, from, to, amount)
            }
            function emitApproval(from, spender, amount) {
                let signatureHash := 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925
                emitEvent(signatureHash, from, spender, amount)
            }
            function emitEvent(signatureHash, indexed1, indexed2, nonIndexed) {
                mstore(0, nonIndexed)
                log3(0, 0x20, signatureHash, indexed1, indexed2)
            }

            /* -------- storage layout ---------- */
            function ownerPos() -> p { p := 0 }
            function totalSupplyPos() -> p { p := 1 }
            function accountToStorageOffset(account) -> offset {
                offset := add(0x1000, account)
            }
            function allowanceStorageOffset(account, spender) -> offset {
                offset := accountToStorageOffset(account)
                mstore(0, offset)
                mstore(0x20, spender)
                offset := keccak256(0, 0x40)
            }

            /* -------- storage access ---------- */
            function owner() -> o {
                o := sload(ownerPos())
            }
            function totalSupply() -> supply {
                supply := sload(totalSupplyPos())
            }
            function mintTokens(amount) {
                sstore(totalSupplyPos(), safeAdd(totalSupply(), amount))
            }
            function balanceOf(account) -> bal {
                bal := sload(accountToStorageOffset(account))
            }
            function addToBalance(account, amount) {
                let offset := accountToStorageOffset(account)
                sstore(offset, safeAdd(sload(offset), amount))
            }
            function deductFromBalance(account, amount) {
                let offset := accountToStorageOffset(account)
                let bal := sload(offset)
                require(lte(amount, bal))
                sstore(offset, sub(bal, amount))
            }
            function allowance(account, spender) -> amount {
                amount := sload(allowanceStorageOffset(account, spender))
            }
            function setAllowance(account, spender, amount) {
                sstore(allowanceStorageOffset(account, spender), amount)
            }
            function decreaseAllowanceBy(account, spender, amount) {
                let offset := allowanceStorageOffset(account, spender)
                let currentAllowance := sload(offset)
                require(lte(amount, currentAllowance))
                sstore(offset, sub(currentAllowance, amount))
            }

            /* ---------- utility functions ---------- */
            function lte(a, b) -> r {
                r := iszero(gt(a, b))
            }
            function gte(a, b) -> r {
                r := iszero(lt(a, b))
            }
            function safeAdd(a, b) -> r {
                r := add(a, b)
                if or(lt(r, a), lt(r, b)) { revert(0, 0) }
            }
            function calledByOwner() -> cbo {
                cbo := eq(owner(), caller())
            }
            function revertIfZeroAddress(addr) {
                require(addr)
            }
            function require(condition) {
                if iszero(condition) { revert(0, 0) }
            }
        }
    }
}

/**
*This YUL code defines a simple Ethereum smart contract that manages tokens (similar to an ERC-20 token). YUL is an intermediate language in the Ethereum stack that allows low-level operations like assembly but with higher-level structures. Here's a breakdown of its key parts:

1. Main Token Object
This object is the contract's entry point, setting up initial storage and deploying the contract.

Storing the Creator in Slot 0:
sstore(0, caller()) stores the creator of the contract (the deployer) in storage slot 0. The deployer becomes the contract owner.

Contract Deployment:
It copies and deploys the "runtime" code from the contract's data section using datacopy and return.

2. Runtime Object
This object contains the actual runtime code that handles the token's operations after deployment.

Ether Protection:
require(iszero(callvalue())) ensures the contract cannot receive Ether. If a transaction sends Ether, it will revert.
3. Function Selector Dispatcher
This section decodes incoming function calls and maps them to the appropriate internal logic. It uses the switch selector() to match the function signature (or selector) with specific operations.

Some key functions are:

balanceOf(address) (0x70a08231): Returns the balance of a given address.
totalSupply() (0x18160ddd): Returns the total supply of tokens.
transfer(address,uint256) (0xa9059cbb): Transfers tokens to a specified address.
transferFrom(address,address,uint256) (0x23b872dd): Allows tokens to be transferred on behalf of one address by another.
approve(address,uint256) (0x095ea7b3): Approves another address to spend tokens on the owner's behalf.
allowance(address,address) (0xdd62ed3e): Returns the remaining tokens allowed for the spender by the owner.
mint(address,uint256) (0x40c10f19): Creates new tokens and assigns them to an account (only callable by the contract owner).
If the function selector does not match any known function, the contract reverts (revert(0, 0)).

4. Token Functions
The contract defines core operations like mint, transfer, approve, and transferFrom. Here's a summary:

Minting Tokens:
The mint() function allows the contract owner to create new tokens and assign them to an account. It updates the total supply and balance of the receiving account.

Transfering Tokens:
The transfer() function transfers tokens from the caller to a specified address. The transferFrom() function allows an approved spender to transfer tokens on behalf of an owner.

Approving Token Transfers:
The approve() function allows an owner to grant permission to another address (a spender) to transfer tokens from their account.

5. Storage Access and Helpers
Storage Layout:
The contract uses specific storage slots for the owner's address (sload(0)), total supply, and individual balances. It calculates offsets for account balances and allowances.

Storage Modifiers:
Functions like addToBalance(), deductFromBalance(), and setAllowance() are responsible for updating these values.

Event Emissions:
The contract emits Transfer and Approval events, following ERC-20 standards. These are logged with log3 using a signature hash to define the event type.

6. Utility Functions
Calldata Decoding:
The contract decodes input data to extract function arguments, such as addresses and token amounts, using decodeAsAddress() and decodeAsUint().

Math and Checks:
Functions like safeAdd(), lte(), and gte() handle basic arithmetic with overflow protection. The contract also checks if operations are called by the owner (calledByOwner()), and ensures valid addresses using revertIfZeroAddress().
*/