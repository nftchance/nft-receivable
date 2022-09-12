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
        _mintToken(
              _msgSender()
            , _paymentToken
        );
    }
}
