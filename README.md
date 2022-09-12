# ERC721Receivable

ERC721Receivable is a simple implementation for a broad `PaymentToken` implementation allowing ETH, ERC20, ERC721, and ERC1155 as payment to mint an ERC721. With a simple struct, you have granular control over the type of payment your mint will accept.

```solidity
    /**
        * @dev Expanded payment token data structure.
        * @param tokenType A hacky switch{} to handle 4 cases with 1 values.
        * @param tokenAddress The address of the token being used for payment.
        * ---- false if ERC20, true if anything else
        * @param aux An auxiliary value for the token being used for payment
        * ---- amount of tokens if NATIVE, ERC20 or ERC1155.
        */
    struct PaymentToken { 
        bool tokenType;
        address tokenAddress;
        uint256 aux;
    }
```

This simple structure allows for nearly seemless token payment with far less need for requirement checks or complicated in-contract processing.

## Use Cases

In current time, many creators struggle to create a smart contract that can accept a token redemption. More opinionated though, the current state of smart contracts lends to treating non-fungible tokens as fungible. This is just one version of an exploration into how a mechanism that forgoes the days of simplistic fungibility payments.

- Want to have a mint that uses an ERC20 like $APE.
- Want to have a redemption mint that turns 1 ERC721 in for another.
- Want to have a trade for multiple ERC1155s for a new edition.
- The possibilities are pretty endless.

With this, instead of users needing to handle pesky approvals or figuring out how much to pay. A user can transfer the payment token directly to the contract and the resulting quantity of tokens will be automatically determined.

## Tests

The tests are pretty simple, but they do a good job of showing the functionality of the contract.

```bash
  Receivable
    Token Deployment
      ✓ ReceivableToken successfully. (1ms)
    ETH Payments
      ✓ Minting 10 tokens by transferring ETH value to contract. (29ms)
    1155 Payments
      ✓ Can mint 1 with the transfer of an ERC1155 (75ms)
    721 Payments
      ✓ Can mint 1 with the transfer of an ERC721 (66ms)
      ✓ Cannot mint 1 with the transfer of a non-supposed ERC721 (122ms)
    ERC20 Payments
      ✓ Can mint 1 with the transfer of an ERC20 (60ms)
```

## Usage

You can find an example implementation at [ReceivableToken.sol](/contracts/ReceivableToken.sol).

To install the needed libraries run:
`npm i`

With your libraries installed run:
`npx hardhat test`

To the contract for yourself:

* `Fork this repository`
* `Edit arguments.js`
* `Deploy the contract`

Copy-pasting is completely allowed and you can use this however.