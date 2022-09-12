// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import { ERC721A } from "erc721a/contracts/ERC721A.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import { ERC1155Receiver } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract ERC721Receivable is
      ERC721A
    , ERC721Holder
    , ERC1155Holder
{
    enum TOKEN_TYPE {
          NATIVE
        , ERC20
        , ERC721
        , ERC1155
    }

    struct PaymentTokenBitpacked { 
        uint32 tokenData;
        uint256 aux;
    }

    /**
     * @dev Expanded payment token data structure
     * @param tokenType The type of token being used for payment
     * ---- 0 = native, 1 = ERC20, 2 = ERC721, 3 = ERC1155.
     * @param tokenAddress The address of the token being used for payment
     * ---- 0x0 for NATIVE, contract address for every other type.
     * @param aux An auxiliary value for the token being used for payment
     * ---- amount of tokens if NATIVE, ERC20 or ERC1155.
     */
    struct PaymentToken { 
        TOKEN_TYPE tokenType;
        address tokenAddress;
        uint256 aux;
    }

    uint256 constant MAX_SUPPLY = 101;

    uint256[] private EMPTY_TOKEN_IDS = new uint256[](0);

    PaymentToken paymentToken;

    constructor(
          string memory _name
        , string memory _symbol
        , PaymentToken memory _paymentToken
    )
        ERC721A(
              _name
            , _symbol
        )
    {
        _setPaymentToken(_paymentToken);
    }

    /**
     * @notice Enables seamless minting by just sending ETH to the contract.
     * @dev    By using this function the sender is essentially choosing
     *         how many they want to mint without defining that as well as
     *         us no longer needing the payment check. We love saving gas
     *         just by having better logic than the rest :) 
     */
    receive() 
        external 
        payable 
    {
        require(
              paymentToken.tokenType == TOKEN_TYPE.NATIVE
            , "ERC721Receivable: Only native tokens are accepted. Everything else must be sent directly."
        );

        _mintToken(
              msg.sender
            , msg.value
        );
    }

    /**
     * @notice Detects when an ERC721 token is received and mints a token.
     * @param _from The address of the sender of the ERC721 token.
     * @return The selector of this function to signal transfer was completed.
     */
    function onERC721Received(
        address _from,
        address,
        uint256,
        bytes memory
    ) 
        override 
        public 
        virtual 
        returns (
            bytes4
        ) 
    {
        /// @dev Confirm the address of the token is the same as the payment token.
        require(
              msg.sender == paymentToken.tokenAddress
            , "ERC721Receivable::onERC721Received: invalid token."
        );

        _mintToken(
              _from
            , 1
        );

        return this.onERC721Received.selector;
    }

    /**
     * @notice Enables the minting of tokens by sending specified ERC1155 tokens.
     * @param _operator The address of the operator that is sending the tokens.
     * @param _value The amounts of tokens being used for purchase power.
     * @return bytes4 `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     */
    function onERC1155Received(
          address _operator
        , address 
        , uint256 
        , uint256 _value
        , bytes memory 
    )
        override
        public
        returns (
            bytes4
        )
    {
        /// @dev Confirm the address of the token is the same as the payment token.
        require(
              msg.sender == paymentToken.tokenAddress
            , "ERC721Receivable::onERC1155Received: invalid token."
        );

        /// @dev Process the payment and mint the purchased tokens to the operator of the tokens
        _mintToken(
              _operator
            , _value
        );

        return this.onERC1155Received.selector;
    }

    /**
     * @notice Batch sending of ERC1155s is not supported as it would require a more complex payment
     *         processing system. This function is only here to satisfy the ERC1155Receiver interface.
     *         It will revert if called.
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory 
    )
        override
        public 
        pure
        returns(
            bytes4
        )
    {
        /// @dev Revert because this model does not support multiple tokens
        revert("ERC721Receivable::onERC1155BatchReceived: batch transfer feature not supported.");
    }

    /// @dev Enable the ability to change the payment structure
    function _setPaymentToken(
        PaymentToken memory _paymentToken
    )
        internal
    {
        paymentToken = _paymentToken;
    }
    
    /**
     * @notice Determines how many tokens can be minted based on the payment token.
     * @param _value The amount of tokens being used for payment.
     * @return _value The amount of tokens that can be minted.
     */
    function _valueQuantity(
        uint256 _value
    )
        internal
        view
        returns (
            uint256 
        )
    {
        return _value / paymentToken.aux;
    }

    function _fundMint(
        uint256 _aux
    )
        internal
        returns (
            uint256 quantity 
        )
    { 
        /// @dev Handling payments in ERC20 because the delivery cannot be guaranteed
        ///      as there is no received hook due to bad erc design.
        if(paymentToken.tokenType == TOKEN_TYPE.ERC20) {
            IERC20 _token = IERC20(paymentToken.tokenAddress);

            /// @dev Transfer the tokens to the contract
            require(
                  _token.transferFrom(
                        msg.sender
                      , address(this)
                      , _aux
                  )
                , "ERC721Receivable::mintToken: insufficient allowance."
            );
        }

        /// @dev Handles the quantity control for ERC20 and ERC1155
        quantity = _valueQuantity(_aux);
    }

    function _mintToken(
          address _to
        , uint256 _aux
    )
        internal
        virtual
    {
        uint256 _totalSupply = totalSupply();

        uint256 _quantity = _fundMint(_aux);         

        require(
              _totalSupply + _quantity < MAX_SUPPLY
            , "ERC721Receivable::mintToken: total supply exceeded."
        );
        
        _mint(
              _to
            , _quantity
        );
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(
            ERC721A
          , ERC1155Receiver
        )
        returns (
            bool
        )
    {
        return super.supportsInterface(interfaceId);
    }
}