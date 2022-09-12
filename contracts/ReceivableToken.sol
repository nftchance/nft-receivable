// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;


import { ERC721Receivable } from "./ERC721Receivable.sol";

contract ReceivableToken is
    ERC721Receivable
{
    constructor(
          string memory _name
        , string memory _symbol
        , PaymentToken memory _paymentToken
    )
        ERC721Receivable(
              _name
            , _symbol
            , _paymentToken
        )
    { }

    function mintToken(
          PaymentToken memory _paymentToken
    )
        external
        payable
    {
        require(
              _paymentToken.tokenType == TOKEN_TYPE.ERC20
            , "ReceivableToken: Only ERC20 tokens are accepted. Everything else must be sent directly."
        );

        _mintToken(
              _msgSender()
            , _paymentToken
        );
    }
}
