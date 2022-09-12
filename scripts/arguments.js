module.exports = [
    "ReceivableToken",                              // Name of Collection
    "RBT",                                          // Symbol of Collection           
    {                                               // Payment Token
        tokenType: false,                           // false if ERC20, true if anything else  
        tokenAddress: mockERC20.address,            // Address of token, or zero address (0x0000000000000000000000000000000000000000) if ETH
        tokenId: 0,                                 // ID of token if ERC1155
        aux: 1                                      // Amount of input tokens that result in 1 output token
    },
    101,                                            // Max supply of receivable tokens (real number + 1): in this case max supply is really 100
    "ipfs://"                                       // URI of receivable token metadata     
]