import { ethers } from "hardhat"
import chai from "chai"
import chaiAsPromised from "chai-as-promised"
import {
    PoolSwapLibrary,
    LeveragedPool,
    TestToken,
    ERC20,
    PoolCommitter,
    PoolKeeper,
} from "../../../typechain"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { POOL_CODE } from "../../constants"
import {
    getEventArgs,
    deployPoolAndTokenContracts,
    getRandomInt,
    generateRandomAddress,
    createCommit,
    CommitEventArgs,
    timeout,
} from "../../utilities"
import { BytesLike } from "ethers"

chai.use(chaiAsPromised)
const { expect } = chai

const amountCommitted = ethers.utils.parseEther("2000")
const amountMinted = ethers.utils.parseEther("10000")
const feeAddress = generateRandomAddress()
const lastPrice = getRandomInt(99999999, 1)
const updateInterval = 2
const frontRunningInterval = 1 // seconds
const fee = "0x00000000000000000000000000000000"
const leverage = 2
const commitType = [2] //long mint;

describe("PoolCommiter - executeCommitment: Basic test cases", () => {
    let token: TestToken
    let pool: LeveragedPool
    let library: PoolSwapLibrary
    let signers: SignerWithAddress[]
    let poolCommiter: PoolCommitter

    describe("Revert cases", () => {
        before(async () => {
            const result = await deployPoolAndTokenContracts(
                POOL_CODE,
                frontRunningInterval,
                updateInterval,
                fee,
                leverage,
                feeAddress,
                amountMinted
            )
            pool = result.pool
            signers = result.signers
            token = result.token
            library = result.library
            poolCommiter = result.poolCommiter
        })
        it("should revert if the commitment is too new", async () => {
            await token.approve(pool.address, amountCommitted)
            const commit = await createCommit(
                poolCommiter,
                commitType,
                amountCommitted
            )
            await expect(
                pool.poolUpkeep(lastPrice, lastPrice)
            ).to.be.rejectedWith(Error)
        })

        it("should revert if the commitment doesn't exist", async () => {
            await expect(
                pool.poolUpkeep(lastPrice, lastPrice)
            ).to.be.rejectedWith(Error)
        })
    })

    describe("Single commitment", () => {
        let commit: CommitEventArgs
        beforeEach(async () => {
            const result = await deployPoolAndTokenContracts(
                POOL_CODE,
                frontRunningInterval,
                updateInterval,
                fee,
                leverage,
                feeAddress,
                amountMinted
            )
            pool = result.pool
            signers = result.signers
            token = result.token
            library = result.library
            poolCommiter = result.poolCommiter

            await token.approve(pool.address, amountCommitted)
            commit = await createCommit(
                poolCommiter,
                commitType,
                amountCommitted
            )
            await pool.setKeeper(signers[0].address)
        })

        it("should remove the commitment after execution", async () => {
            expect((await poolCommiter.commits(commit.commitID)).amount).to.eq(
                amountCommitted
            )
            await timeout(2000)
            await pool.poolUpkeep(9, 10)
            expect((await poolCommiter.commits(commit.commitID)).amount).to.eq(
                0
            )
        })

        // TODO this can not get the ExecuteCommit event because it happens internally (not at top level)
        // Not sure how to account for this/test it
        it.skip("should emit an event for commitment removal", async () => {
            await timeout(2000)
            const receipt = await (await pool.poolUpkeep(9, 10)).wait()
            expect(getEventArgs(receipt, "ExecuteCommit")?.commitID).to.eq(
                commit.commitID
            )
        })
        it("should not allow anyone to execute a commitment", async () => {
            await timeout(2000)
            await expect(
                pool.connect(signers[1]).poolUpkeep(9, 10)
            ).to.be.revertedWith("msg.sender not keeper")
            // Doesn't delete commit
            expect((await poolCommiter.commits(commit.commitID)).amount).to.eq(
                amountCommitted
            )
        })
    })
})