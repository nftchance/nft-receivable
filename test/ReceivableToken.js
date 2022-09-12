const { assert } = require('chai')

var chai = require('chai')
    .use(require('chai-as-promised'))
    .should()

const { ethers } = require("hardhat");

describe("Receivable", function () {
    before(async () => {
        [owner, address1] = await ethers.getSigners();

        ReceivableToken = await ethers.getContractFactory("ReceivableToken");
        receivableToken = await ReceivableToken.deploy(
            "ReceivableToken",
            "RBT",
            {
                tokenType: 0,
                tokenAddress: "0x0000000000000000000000000000000000000000",
                tokenId: 0,
                aux: ethers.utils.parseEther('0.02')
            },
        );
        receivableToken = await receivableToken.deployed();
    })

    describe('Token Deployment', async () => {
        it('ReceivableToken successfully.', async () => {
            const address = receivableToken.address
            assert.notEqual(address, '')
            assert.notEqual(address, 0x0)
            assert.notEqual(address, null)
            assert.notEqual(address, undefined)
        })
    });

    describe("ETH Payments", async () => {
        it("Minting 10 tokens by transferring ETH value to contract.", async () => {
            balance = await receivableToken.balanceOf(owner.address)
            await owner.sendTransaction({ to: receivableToken.address, value: ethers.utils.parseEther('0.2') });
            balance = await receivableToken.balanceOf(owner.address)
            assert.equal(balance.toString(), 10)
        })
    })

    describe("1155 Payments", async () => {
        before(async () => {
            // Deploy mock 1155 that can be used as payment
            const MockERC1155 = await ethers.getContractFactory("MockERC1155");
            mockERC1155 = await MockERC1155.deploy("ipfs://");
            mockERC1155 = await mockERC1155.deployed();

            // Mint 10 tokens to address 1
            await mockERC1155.connect(address1).mint(address1.address, 0, 1, "0x");
            assert.equal((await mockERC1155.balanceOf(address1.address, 0)).toString(), 1)

            // Deploy receivable token
            receivable1155 = await ReceivableToken.deploy(
                "ReceivableToken",
                "RBT",
                {
                    tokenType: 3,
                    tokenAddress: mockERC1155.address,
                    tokenId: 0,
                    aux: 1
                },
            );
            receivable1155 = await receivable1155.deployed();
        })

        it("Can mint 1 with the transfer of an ERC1155", async () => {
            // Mint 10 tokens to owner by transferring the mock erc1155 to the receivable token
            await mockERC1155.connect(address1).safeTransferFrom(address1.address, receivable1155.address, 0, 1, "0x");

            assert.equal((await receivable1155.balanceOf(address1.address)).toString(), 1)
        })
    })

    describe("721 Payments", async () => {
        before(async () => {
            // Deploy mock 721 that can be used as payment
            const MockERC721 = await ethers.getContractFactory("MockERC721");
            mockERC721 = await MockERC721.deploy("MockERC721", "M721");
            mockERC721 = await mockERC721.deployed();

            // Mint 10 tokens to address 1
            await mockERC721.connect(address1).mint(address1.address, 0);
            assert.equal((await mockERC721.balanceOf(address1.address)).toString(), 1)

            // Deploy receivable token
            receivable721 = await ReceivableToken.deploy(
                "ReceivableToken",
                "RBT",
                {
                    tokenType: 2,
                    tokenAddress: mockERC721.address,
                    tokenId: 0,
                    aux: 1
                },
            );
            receivable721 = await receivable721.deployed();
        })

        it("Can mint 1 with the transfer of an ERC721", async () => {
            // Mint 10 tokens to owner by transferring the mock erc721 to the receivable token
            await mockERC721.connect(address1)['safeTransferFrom(address,address,uint256)'](
                address1.address,
                receivable721.address,
                0 // token id
            ); // syntax is as such due to overloaded function

            assert.equal((await receivable721.balanceOf(address1.address)).toString(), 1)
        })

        it("Cannot mint 1 with the transfer of a non-supposed ERC721", async() => { 
            // Deploy mock 721 that can be used as payment
            const MockERC7212 = await ethers.getContractFactory("MockERC721");
            mockERC7212 = await MockERC7212.deploy("MockERC721", "M721");
            mockERC7212 = await mockERC7212.deployed();

            // Mint 10 tokens to address 1
            await mockERC7212.connect(address1).mint(address1.address, 0);
            assert.equal((await mockERC7212.balanceOf(address1.address)).toString(), 1) 

            // Mint 10 tokens to owner by transferring the mock erc721 to the receivable token
            await mockERC7212.connect(address1)['safeTransferFrom(address,address,uint256)'](
                address1.address,
                receivable721.address,
                0 // token id
            ).should.be.revertedWith("ERC721Receivable::onERC721Received: invalid token."); // syntax is as such due to overloaded function
        })
    });

    describe("ERC20 Payments", async () => {
        before(async () => {
            // Deploy mock ERC20 that can be used as payment
            const MockERC20 = await ethers.getContractFactory("MockERC20");
            mockERC20 = await MockERC20.deploy("MockERC20", "M20");
            mockERC20 = await mockERC20.deployed();

            // Mint 10 tokens to address 1
            await mockERC20.connect(address1).mint(address1.address, 10);
            assert.equal((await mockERC20.balanceOf(address1.address)).toString(), 10)

            // Deploy receivable token
            receivableERC20 = await ReceivableToken.deploy(
                "ReceivableToken",
                "RBT",
                {
                    tokenType: 1,
                    tokenAddress: mockERC20.address,
                    tokenId: 0,
                    aux: 1
                },
            );
            receivableERC20 = await receivableERC20.deployed();
        })

        it("Can mint 1 with the transfer of an ERC20", async () => {
            // set allowance for erc20 token
            await mockERC20.connect(address1).approve(receivableERC20.address, 1);

            // Mint 1 token to owner by transferring the mock erc20 to the receivable token
            await receivableERC20.connect(address1).mintToken(1);

            assert.equal((await receivableERC20.balanceOf(address1.address)).toString(), 1)
        })

        // it("Can mint entire supply", async () => { 
        //     await mockERC20.connect(address1).mint(address1.address, 1000);

        //     // set allowance for erc20 token
        //     await mockERC20.connect(address1).approve(receivableERC20.address, 99);

        //     // Mint 10 tokens to owner by transferring the mock erc20 to the receivable token
        //     await receivableERC20.connect(address1).mintToken({
        //         tokenType: 1,
        //         tokenAddress: mockERC20.address,
        //         tokenId: 0,
        //         aux: 99
        //     });

        //     assert.equal((await receivableERC20.balanceOf(address1.address)).toString(), 100)
        // })

        // it("Cannot mint over erc721 receivable max supply", async () => { 
        //     await mockERC20.connect(address1).mint(address1.address, 1000);

        //     // set allowance for erc20 token
        //     await mockERC20.connect(address1).approve(receivableERC20.address, 100);

        //     // Mint 10 tokens to owner by transferring the mock erc20 to the receivable token
        //     await receivableERC20.connect(address1).mintToken({
        //         tokenType: 1,
        //         tokenAddress: mockERC20.address,
        //         tokenId: 0,
        //         aux: 100
        //     }).should.be.revertedWith("ERC721Receivable::mintToken: total supply exceeded.");
        // });
    });
});