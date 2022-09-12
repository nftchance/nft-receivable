// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

/// @dev Core processing definitions for ReceivableToken.
import { ERC721Receivable } from "./ERC721Receivable.sol";

contract ReceivableToken is
    ERC721Receivable
{
    /// @dev Metadata URI for the token.
    string public metadataURI;

    /// @dev Controls whether or not the sale has started.
    bool public mintOpen;

    constructor(
          string memory _name
        , string memory _symbol
        , PaymentToken memory _paymentToken
        , uint256 _maxSupply
        , string memory _metadataURI
    )
        ERC721Receivable(
              _name
            , _symbol
            , _paymentToken
            , _maxSupply
        )
    { 
        metadataURI = _metadataURI;
    }

    /**
     * @notice Returns the base metadata URI for the token.
     * @dev This is used by the ERC721A contract to generate the token URI.
     * @return The base metadata URI for the token.
     */
    function _baseURI() 
        override
        internal 
        view 
        virtual 
        returns (
            string memory
        ) 
    {
        return metadataURI;
    }

    /**
     * @notice Sets the base metadata URI for the token.
     * @dev This is done this way due to the `tokenURI` abstraction in ERC721A.
     * @param _metadataURI The base metadata URI for the token.
     */
    function _setBaseURI(
        string memory _metadataURI
    )
        external
        virtual
        onlyOwner()
    {
        metadataURI = _metadataURI;
    }

    /**
     * @notice Allows contract owner to change the sale state.
     * @param _mintOpen The new sale state.
     * 
     * Requirements:
     * - The caller must be the owner of the contract.
     */
    function setMintOpen(
        bool _mintOpen
    )
        external
        virtual
        onlyOwner()
    {
        mintOpen = _mintOpen;
    }

    /**
     * @notice Extends `_beforeMint` so that control over start time is given to the owner.
     */
    function _beforeMint(
        uint256
    )
        override
        internal
        virtual
    {
        require(
              mintOpen
            , "ReceivableToken: minting not started"
        );
    }
}
