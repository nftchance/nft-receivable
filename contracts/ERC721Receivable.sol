// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

/// @dev Core processing definitions for ERC721Receivable.
import { ERC721A } from "erc721a/contracts/ERC721A.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { ERC1155Receiver } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/// @dev Interface to transfer payments in and out.
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * @title ReceivableToken
 * @author nftchance
 * @notice ReceivableToken is a contract that allows users to mint ERC721 tokens
 *         by paying a fee in ETH, ERC20, ERC721 or ERC1155 tokens depending on 
 *        the payment token type.
 * @dev The primary appeal of using this architecture is that a user does not have to 
 *      pre-approve the token besides for ERC20 due to the standard ERC20 interface.
 *      This is because the contract is not transferring the tokens from the user (besides for ERC20)
 *      and instead is processing the mint when a token is received. This is a more gas efficient
 *      approach than the standard ERC721 transferFrom approach that can complex caveats and orders.
 * @dev Because everything processes at the time of receiving, `mintToken()` is only used for ERC20 and
 *      everything else is a normal transfer.
 */
contract ERC721Receivable is
      ERC721A
    , ERC721Holder
    , ERC1155Receiver
    , Ownable
{
    /**
     * @dev Expanded payment token data structure.
     * @param tokenType A hacky switch{} to handle 4 cases with 1 values.
     * ---- false if ERC20, true if anything else
     * @param tokenAddress The address of the token being used for payment.
     * @param aux An auxiliary value for the token being used for payment
     * ---- amount of tokens if NATIVE, ERC20 or ERC1155.
     */
    struct PaymentToken { 
        bool tokenType;
        address tokenAddress;
        uint256 aux;
    }

    /// @dev The max number of tokens that can be minted.
    uint256 immutable maxSupply;

    /// @dev The payment schema for the mint.
    PaymentToken paymentToken;

    constructor(
          string memory _name
        , string memory _symbol
        , PaymentToken memory _paymentToken
        , uint256 _maxSupply
    )
        ERC721A(
              _name
            , _symbol
        )
    {
        paymentToken = _paymentToken;
        maxSupply = _maxSupply;
    }

    /**
     * @notice Enables seamless minting by just sending ETH to the contract.
     * @dev    By using this function the sender is essentially choosing
     *         how many they want to mint without defining that as well as
     *         us no longer needing the payment check. We love saving gas
     *         just by having better logic than the rest :) 
     *
     * Requirements:
     * - The contract must be accepting native token mints.
     */
    receive() 
        external 
        payable 
    {
        require(
              paymentToken.tokenType
            , "ERC721Receivable: Only native tokens are accepted. Everything else must be sent directly."
        );

        /// @dev Mint the tokens.
        /// @dev We don't need to check the amount because we are using
        ///      the native token and the amount is already defined in
        ///      the paymentToken struct.
        _mintToken(
              msg.sender
            , msg.value
        );
    }

    /**
     * @notice Detects when an ERC721 token is received and mints a token.
     * @param _operator The address of the sender of the ERC721 token.
     * @return selector `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     *
     * Requirements:
     * - The contract must be accepting tokens from the provided ERC721 token contract.
     */
    function onERC721Received(
        address _operator,
        address,
        uint256,
        bytes memory
    ) 
        override 
        public 
        virtual 
        returns (
            bytes4 selector
        ) 
    {
        /// @dev Confirm the address of the token is the same as the payment token.
        require(
              msg.sender == paymentToken.tokenAddress
            , "ERC721Receivable::onERC721Received: invalid token."
        );

        /// @dev Mint the token.
        _mintToken(
              _operator
            , 1
        );

        return this.onERC721Received.selector;
    }

    /**
     * @notice Enables the minting of tokens by sending specified ERC1155 tokens.
     * @param _operator The address of the operator that is sending the tokens.
     * @param _value The amounts of tokens being used for purchase power.
     * @return selector `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     *
     * Requirements:
     * - The contract must be accepting tokens from the provided ERC1155 token contract.
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
            bytes4 selector
        )
    {
        /// @dev Confirm the address of the token is the same as the payment token.
        require(
              msg.sender == paymentToken.tokenAddress
            , "ERC721Receivable::onERC1155Received: invalid token."
        );

        /// @dev Mint the tokens.
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

    /**
     * @notice Determines the amount of tokens that the sender has permission to mint.
     * @param _aux The amount of tokens being used for payment.
     * @return quantity The amount of tokens that can be minted.
     * 
     * Requirements:
     * - If the payment token is ERC20, the sender must transfer them to this contract.
     */
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
        if(!paymentToken.tokenType) {
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

    /**
     * @notice Mints the tokens to the sender.
     * @param _to The address of the receiver of the tokens.
     * @param _aux The amount of tokens being used for payment.
     * 
     * Requirements:
     * - The user must pass the `_beforeMint` check extended by the top-level.
     * - The total supply must not be exceeded.
     * - The user must pass the `_afterMint` check extended by the top-level.
     */
    function _mintToken(
          address _to
        , uint256 _aux
    )
        internal
        virtual
    {
        /// @dev Run the pre-hook that allows any implementer to extend the logic.
        _beforeMint(_aux);

        /// @dev Determine the amount of tokens that have been minted.
        uint256 _totalSupply = totalSupply();

        /// @dev Determine the amount of tokens that can be minted.
        uint256 _quantity = _fundMint(_aux);

        require(
              _totalSupply + _quantity < maxSupply
            , "ERC721Receivable::mintToken: total supply exceeded."
        );

        /// @dev Mint the tokens.
        _mint(
              _to
            , _quantity
        );

        _afterMint(
              _to
            , _quantity
        );
    }

 /**
     * @notice Allows a user to mint a token with an ERC20.
     * @param _aux The amount of ERC20 tokens to pay.
     * 
     * Requirements:
     * - The payment token must be setup to accept ERC20s.
     */
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

        /// @dev Mint the tokens.
        _mintToken(
              msg.sender
            , _aux
        );
    }

    /**
     * @notice Allows an implementation to extend pre-mint logic.
     * @param _aux The amount of tokens being used for payment.
     */
    function _beforeMint(
        uint256 _aux
    ) 
        internal 
        virtual 
    {}

    /**
     * @notice Allows an implementation to extend post-mint logic.
     * @param _to The address of the receiver of the tokens.
     * @param _quantity The amount of tokens being minted.
     */
    function _afterMint(
        address _to,
        uint256 _quantity
    ) 
        internal 
        virtual 
    {}

    /**
     * @notice Allows the owner of the contract to withdraw the ETH that has been earned.
     * @param _to The address of the receiver of the ETH.
     * 
     * Requirements:
     * - The caller must be the owner of the contract.
     * - The transfer of the ETH must be successful.
     */ 
    function withdrawETH(
        address _to
    ) 
        external
        onlyOwner() 
    {
        (bool success, ) = _to.call{value: address(this).balance}('');
        require(
              success
            , "_transferEth: Eth transfer failed"
        );
    }

    /**
     * @notice Allows the owner of the contract to withdraw the ERC20 tokens that have been earned.
     * @param _to The address of the receiver of the tokens.
     * @dev When this function is called it will automatically determine how much of the ERC20 is held
     *      in the contract and transfer it all instead of keeping track of the amount of tokens that
     *      have been minted / withdrawn.
     * 
     * Requirements:
     * - The caller must be the owner of the contract.
     */
    function withdrawERC20(
          address _tokenAddress
        , address _to
    ) 
        external
        onlyOwner()
    { 
        IERC20(_tokenAddress).transfer(
              _to
            , IERC20(_tokenAddress).balanceOf(address(this))
        );
    }

    /**
     * @notice Allows the owner of the contract to withdraw the ERC721 tokens that have been earned.
     * @param _to The address of contract to the tokens being withdrawn.
     * @param _tokenIds The ids of the tokens to withdraw.
     * @param _to The address of the receiver of the tokens.
     * 
     * Requirements:
     * - The caller must be the owner of the contract.
     */
    function withdrawERC721(
          address _tokenAddress
        , uint256[] calldata _tokenIds
        , address _to
    ) 
        external
        onlyOwner() 
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            IERC721(_tokenAddress).transferFrom(
                  address(this)
                , _to
                , _tokenIds[i]
            );
        }
    }

    /**
     * @notice Allows the owner of the contract to withdraw the ERC1155 tokens that have been earned.
     * @param _tokenAddress The address of contract to the tokens being withdrawn.
     * @param _tokenIds The ids of the tokens to withdraw.
     * @param _amounts The amounts of the tokens to withdraw.
     * @param _to The address of the receiver of the tokens.
     *
     * Requirements:
     * - The caller must be the owner of the contract.
     */
    function withdrewERC1155(
          address _tokenAddress
        , uint256[] calldata _tokenIds
        , uint256[] calldata _amounts
        , address _to
    ) 
        external 
        onlyOwner()
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            IERC1155(_tokenAddress).safeTransferFrom(
                  address(this)
                , _to
                , _tokenIds[i]
                , _amounts[i]
                , ""
            );
        }
    }

    /**
     * @notice Return whether or not this contract supports a specific functionality
     * @param _interfaceId The interface identifier, as specified in ERC-165.
     * @return `true` if the contract implements `_interfaceId`.
     */
    function supportsInterface(
        bytes4 _interfaceId
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
        return super.supportsInterface(_interfaceId);
    }
}