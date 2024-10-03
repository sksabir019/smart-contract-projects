// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Solidity Interface
 * @author Sabir
 * @notice Facts about interface
 * 
 * In Solidity, interfaces are used to define a set of functions that can be called by other contracts. Here are some key rules and restrictions to keep in mind when working with interfaces:

1. Function Signatures Only

Interfaces can only contain function signatures, which include the function name, parameters, and return types. They cannot contain function implementations or any other type of code.

2. No State Variables

Interfaces cannot have state variables, which means they cannot store any data. This is because interfaces are meant to define a contract's external API, not its internal state.

3. No Structs or Enums

As we discussed earlier, interfaces cannot define structs or enums. These should be defined in separate contracts or libraries and then used in the interface.

4. No Modifiers

Interfaces cannot use modifiers, such as onlyOwner or whenNotPaused, which are used to restrict access to certain functions.

5. No Events

Interfaces cannot define events, which are used to notify external contracts of certain actions or changes.

6. No Constructors

Interfaces cannot have constructors, which are used to initialize contracts when they are deployed.

7. No Inheritance

Interfaces cannot inherit from other contracts or interfaces. However, a contract can implement multiple interfaces.

8. No Function Bodies

Interfaces cannot contain function bodies, which means they cannot have any executable code.

9. No Import Statements

Interfaces cannot have import statements, which are used to import other contracts or libraries.

10. Abstract

Interfaces are abstract, which means they cannot be deployed on their own and must be implemented by another contract.


 */
interface IUser {
    function createUser(address userAddress, string memory username) external;
}

contract Game {
    uint public gameCount;
    IUser public userContract;

    constructor(address _userContractAddress) {
        userContract = IUser(_userContractAddress);
    }

    function startGame(string memory username) external {
        // Create a user in the User contract
        userContract.createUser(msg.sender, username);
        gameCount++;
    }
}
