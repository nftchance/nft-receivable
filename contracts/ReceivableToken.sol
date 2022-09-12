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
        , uint256 _maxSupply
    )
        ERC721Receivable(
              _name
            , _symbol
            , _paymentToken
            , _maxSupply
        )
    { }

    function mintToken(
        uint256 _aux
    )
        external
        payable
    {
        require(
              !paymentToken.tokenType
            , "ReceivableToken: can only call this function when using ERC20 as payment."
        );

        _mintToken(
              msg.sender
            , _aux
        );
    }
}
