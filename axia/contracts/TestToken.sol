pragma solidity 0.5.16;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20Pausable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./TaxLib.sol";

/**
 * @title Test Utility Token
 *
 * @dev Implementation of the main Axia Test smart contract.
 */
contract TestToken is ERC20Pausable, ERC20Burnable, ERC20Detailed, Ownable
{
    /**
     * Tax recipient.
     */
    address internal _taxRecipientAddr;

    /**
     * Modifiable tax container.
     */
    TaxLib.DynamicTax private _taxContainer;

    /**
     * @dev Event that is emited when the owner changes the tax of the token.
     */
    event TaxChange(
        uint256 oldAmount,
        uint256 oldShift,
        uint256 newAmount,
        uint256 newShift
    );

    uint256 public constant INITIAL_SUPPLY = 1000000000 * (10 ** 18);

    mapping (address => bool) private _isExcludedFromFee;

    /* Initial Holders */
    address public _privateEarning; /*6.0% */
    address public _teamEarning; /*15% */
    address public _foundersEarning; /*15% */
    address public _salesEarning; /*11% */
    address public _communityEarning; /*20% */
    address public _foundation; /*13% */
    address public _ecosystem; /*12% */
    address public _liquity; /*7% */
    address public _tech; /*1% */

    uint256 public _firstDayDate;

    /**
        The value to be returned as investback
     */
    uint256 public _investBackValue;

    /* First Lap distribuited boolean  */
    bool public _alreadyDistributed;
    bool public _allowInvestBack;

    /**
        Stake reward value
     */
    uint256 public _stakingAmountValue;

    /**
     * @notice We usually require to know who are all the stakeholders.
     */
    address[] internal stakeholders;

    /**
     * @notice The stakes for each stakeholder.
     */
    mapping(address => uint256) internal stakes;

    /**
     * @notice The accumulated rewards for each stakeholder.
     */
    mapping(address => uint256) internal rewards;

    constructor(address taxRecipientAddr) public ERC20Detailed("Test - Workshop", "Test", 18)
    {
        _mint(msg.sender, INITIAL_SUPPLY);
        _firstDayDate = block.timestamp;
        _alreadyDistributed = false;
        _isExcludedFromFee[address(this)] = true;
        _allowInvestBack = false;

        _taxRecipientAddr = taxRecipientAddr;

        /**
         * Tax: Starting at 0.9%
         */
        changeTax(9, 1);
    }

    function initialDistribution(
        address payable privateEarning,
        address payable teamEarning,
        address payable foundersEarning,
        address payable salesEarning,
        address payable communityEarning,
        address payable foundation,
        address payable ecosystem,
        address payable liquity,
        address payable tech
    ) public onlyOwner {
        require(_alreadyDistributed == false, "Executed only once");

        _privateEarning = privateEarning; /*6.0% */
        _teamEarning = teamEarning; /*15% */
        _foundersEarning = foundersEarning; /*15% */
        _salesEarning = salesEarning; /*11% */
        _communityEarning = communityEarning; /*20% */
        _foundation = foundation; /*13% */
        _ecosystem = ecosystem; /*12% */
        _liquity = liquity; /*7% */
        _tech = tech; /*1% */

        _transfer(msg.sender, _privateEarning, 60000000 * (10**18));
        _transfer(msg.sender, _teamEarning, 150000000 * (10**18));
        _transfer(msg.sender, _foundersEarning, 150000000 * (10**18));
        _transfer(msg.sender, _salesEarning, 110000000 * (10**18));
        _transfer(msg.sender, _communityEarning, 200000000 * (10**18));
        _transfer(msg.sender, _foundation, 130000000 * (10**18));
        _transfer(msg.sender, _ecosystem, 120000000 * (10**18));
        _transfer(msg.sender, _liquity, 70000000 * (10**18));
        _transfer(msg.sender, _tech, 10000000 * (10**18));
        _alreadyDistributed = true;
    }

    /**
     * @dev Overrides the OpenZeppelin default transfer
     *
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * @return If the operation was successful
     */
    function transfer(address to, uint256 value) public whenNotPaused returns (bool)
    {
        return _fullTransfer(msg.sender, to, value);
    }

    /**
     *
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     * @return If the operation was successful
     */
    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool)
    {

        if (from == _privateEarning) {
            require(
                block.timestamp >= _firstDayDate + 120 days,
                "Private investidors blocked for 4 months..."
            );
        }
        if (from == _teamEarning) {
            require(
                block.timestamp >= _firstDayDate + 180 days,
                "Team blocked for 6 months..."
            );
        }
        if (from == _foundersEarning) {
            require(
                block.timestamp >= _firstDayDate + 365 days,
                "Founders blocked for 12 months..."
            );
        }

        /*
         * Exempting the tax account to avoid an infinite loop in transferring values from this wallet.
         */
        if (from == taxRecipientAddr() || to == taxRecipientAddr())
        {
            super.transferFrom(from, to, value);

            return true;
        }

        uint256 taxValue = _applyTax(value);

        if (_isExcludedFromFee[from] == false) {
            if(_allowInvestBack) {
                
                uint256 investValue = _applyInvestBack(taxValue);

                _investBackFee(investValue);

                taxValue = taxValue.sub(investValue);
            }
            // Transfer the tax to the recipient
            super.transferFrom(from, taxRecipientAddr(), taxValue);
        }

        // Transfer user's tokens
        super.transferFrom(from, to, value);

        return true;
    }

    /**
     * @dev Batch token transfer (maxium 100 transfers)
     *
     * @param recipients The recipients for transfer to
     * @param values The values
     * @param from Spender address
     * @return If the operation was successful
     */
    function sendBatch(address[] memory recipients, uint256[] memory values, address from) public whenNotPaused returns (bool)
    {
        if (from == _privateEarning) {
            require(
                block.timestamp >= _firstDayDate + 120 days,
                "Private investidors blocked for 4 months..."
            );
        }
        if (from == _teamEarning) {
            require(
                block.timestamp >= _firstDayDate + 180 days,
                "Team blocked for 6 months..."
            );
        }
        if (from == _foundersEarning) {
            require(
                block.timestamp >= _firstDayDate + 365 days,
                "Founders blocked for 12 months..."
            );
        }

        /*
         * The maximum batch send should be 100 transactions.
         * Each transaction we recommend 65000 of GAS limit and the maximum block size is 6700000.
         * 6700000 / 65000 = ~103.0769 ∴ 100 transacitons (safe rounded).
         */
        uint maxTransactionCount = 100;
        uint transactionCount = recipients.length;

        require(transactionCount <= maxTransactionCount, "Max transaction count violated");
        require(transactionCount == values.length, "Wrong data");

        if (msg.sender == from)
        {
            return _sendBatchSelf(recipients, values, transactionCount);
        }

        return _sendBatchFrom(recipients, values, from, transactionCount);
    }

    /**
     * @dev Batch token transfer from MSG sender
     *
     * @param recipients The recipients for transfer to
     * @param values The values
     * @param transactionCount Total transaction count
     * @return If the operation was successful
     */
    function _sendBatchSelf(address[] memory recipients, uint256[] memory values, uint transactionCount) private returns (bool)
    {
        if (msg.sender == _privateEarning) {
            require(
                block.timestamp >= _firstDayDate + 120 days,
                "Private investidors blocked for 4 months..."
            );
        }
        if (msg.sender == _teamEarning) {
            require(
                block.timestamp >= _firstDayDate + 180 days,
                "Team blocked for 6 months..."
            );
        }
        if (msg.sender == _foundersEarning) {
            require(
                block.timestamp >= _firstDayDate + 365 days,
                "Founders blocked for 12 months..."
            );
        }

        for (uint i = 0; i < transactionCount; i++)
        {
            _fullTransfer(msg.sender, recipients[i], values[i]);
        }

        return true;
    }

    /**
     * @dev Batch token transfer from other sender
     *
     * @param recipients The recipients for transfer to
     * @param values The values
     * @param from Spender address
     * @param transactionCount Total transaction count
     * @return If the operation was successful
     */
    function _sendBatchFrom(address[] memory recipients, uint256[] memory values, address from, uint transactionCount) private returns (bool)
    {
        for (uint i = 0; i < transactionCount; i++)
        {
            transferFrom(from, recipients[i], values[i]);
        }

        return true;
    }

    /**
     * @dev Special Axia transfer token for a specified address.
     *
     * @param from The address of the spender
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * @return If the operation was successful
     */
    function _fullTransfer(address from, address to, uint256 value) private returns (bool)
    {

        if (from == _privateEarning) {
            require(
                block.timestamp >= _firstDayDate + 120 days,
                "Private investidors blocked for 4 months..."
            );
        }
        if (from == _teamEarning) {
            require(
                block.timestamp >= _firstDayDate + 180 days,
                "Team blocked for 6 months..."
            );
        }
        if (from == _foundersEarning) {
            require(
                block.timestamp >= _firstDayDate + 365 days,
                "Founders blocked for 12 months..."
            );
        }

        /*
         * Exempting the tax account to avoid an infinite loop in transferring values from this wallet.
         */
        if (from == taxRecipientAddr() || to == taxRecipientAddr())
        {
            _transfer(from, to, value);

            return true;
        }

        if (_isExcludedFromFee[msg.sender] == false) {
            uint256 taxValue = _applyTax(value);
            if(_allowInvestBack) {
                
                uint256 investValue = _applyInvestBack(taxValue);

                _investBackFee(investValue);

                taxValue = taxValue.sub(investValue);
            }

            // Transfer the tax to the recipient
            _transfer(from, taxRecipientAddr(), taxValue);

        }

        // Transfer user's tokens
        _transfer(from, to, value);

        return true;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function disableInvestBack() public onlyOwner {
        _allowInvestBack = false;
    }

    function allowInvestBack() public onlyOwner {
        _allowInvestBack = true;
    }

    /**
        Reflection mechanism
     */
    function _investBackFee(uint256 tFee) private {
        _burn(msg.sender, tFee);
        if(stakes[msg.sender] == 0) addStakeholder(msg.sender);
        stakes[msg.sender] = stakes[msg.sender].add(tFee);
    }

    /** 
        Stake Mechanism
     */

    /**
     * @notice A method for a stakeholder to create a stake.
     * @param _stake The size of the stake to be created.
     */
    function createStake(uint256 _stake)
        public
    {
        _burn(msg.sender, _stake);
        if(stakes[msg.sender] == 0) addStakeholder(msg.sender);
        stakes[msg.sender] = stakes[msg.sender].add(_stake);
    }

    /**
     * @notice A method for a stakeholder to remove a stake.
     */
    function removeStake()
        public
    {
        if(stakes[msg.sender] > 0) {
            removeStakeholder(msg.sender);
            _mint(msg.sender, stakes[msg.sender]);
            stakes[msg.sender] = 0;
        }
    }

    /**
     * @notice A method to retrieve the stake for a stakeholder.
     * @param _stakeholder The stakeholder to retrieve the stake for.
     * @return uint256 The amount of wei staked.
     */
    function stakeOf(address _stakeholder)
        public
        view
        returns(uint256)
    {
        return stakes[_stakeholder];
    }

    /**
     * @notice A method to the aggregated stakes from all stakeholders.
     * @return uint256 The aggregated stakes from all stakeholders.
     */
    function totalStakes()
        public
        view
        returns(uint256)
    {
        uint256 _totalStakes = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            _totalStakes = _totalStakes.add(stakes[stakeholders[s]]);
        }
        return _totalStakes;
    }

    // ---------- STAKEHOLDERS ----------

    /**
     * @notice A method to check if an address is a stakeholder.
     * @param _address The address to verify.
     * @return bool, uint256 Whether the address is a stakeholder, 
     * and if so its position in the stakeholders array.
     */
    function isStakeholder(address _address)
        public
        view
        returns(bool, uint256)
    {
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            if (_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }

    /**
     * @notice A method to add a stakeholder.
     * @param _stakeholder The stakeholder to add.
     */
    function addStakeholder(address _stakeholder)
        public
    {
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);
        if(!_isStakeholder) stakeholders.push(_stakeholder);
    }

    /**
     * @notice A method to remove a stakeholder.
     * @param _stakeholder The stakeholder to remove.
     */
    function removeStakeholder(address _stakeholder)
        private
    {
        (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
        if(_isStakeholder){
            stakeholders[s] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
        } 
    }

    // ---------- REWARDS ----------
    
    /**
     * @notice A method to allow a stakeholder to check his rewards.
     * @param _stakeholder The stakeholder to check rewards for.
     */
    function rewardOf(address _stakeholder) 
        public
        view
        returns(uint256)
    {
        return rewards[_stakeholder];
    }

    /**
     * @notice A method to the aggregated rewards from all stakeholders.
     * @return uint256 The aggregated rewards from all stakeholders.
     */
    function totalRewards()
        public
        view
        returns(uint256)
    {
        uint256 _totalRewards = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            _totalRewards = _totalRewards.add(rewards[stakeholders[s]]);
        }
        return _totalRewards;
    }

    /** 
     * @notice A simple method that calculates the rewards for each stakeholder.
     * @param _stakeholder The stakeholder to calculate rewards for.
     */
    function calculateReward(address _stakeholder)
        public
        view
        returns(uint256)
    {
        uint256 temp = stakes[_stakeholder].mul(_stakingAmountValue);

        return temp / 100;
    }

    /**
     * @notice A method to distribute rewards to all stakeholders.
     */
    function distributeRewards() 
        public
        onlyOwner
    {
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            address stakeholder = stakeholders[s];
            uint256 reward = calculateReward(stakeholder);
            rewards[stakeholder] = rewards[stakeholder].add(reward);
        }
    }

    /**
     * @notice A method to allow a stakeholder to withdraw his rewards.
     */
    function withdrawReward() 
        public
    {
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        _transfer(_liquity, msg.sender, reward);
    }

    /**
        Invest back methods
    */
    function changeInvestBackFee(uint256 amount) public onlyOwner {
        _investBackValue = amount;
    }

    /**
        Invest back methods
    */
    function changeStakeFee(uint256 amount) public onlyOwner {
        _stakingAmountValue = amount;
    }

    /**
     * @dev Apply the tax based on the dynamic tax container
     *
     * @param value The value of transaction
     */
    function _applyInvestBack(uint256 value) internal view returns (uint256)
    {
        uint256 temp = value.mul(_investBackValue);

        return temp.div(100);
    }

    /**
        Taxation methods
     */

     /**
     * Returns the tax recipient account
     */
    function taxRecipientAddr() public view returns (address)
    {
        return _taxRecipientAddr;
    }

    /**
     * @dev Get the current tax amount.
     */
    function currentTaxAmount() public view returns (uint256)
    {
        return _taxContainer.amount;
    }

    /**
     * @dev Get the current tax shift.
     */
    function currentTaxShift() public view returns (uint256)
    {
        return _taxContainer.shift;
    }

    /**
     * @dev Change the dynamic tax.
     *
     * Just the contract admin can change the taxes.
     * The possible tax range is 0% ~ 3% and cannot exceed it.
     * @param amount The new tax amount chosen
     */
    function changeTax(uint256 amount, uint256 shift) public onlyOwner
    {
        if (shift == 0)
        {
            require(amount <= 3, "You can't set a tax greater than 3%");
        }

        emit TaxChange(
            _taxContainer.amount,
            _taxContainer.shift,
            amount,
            shift
        );

        _taxContainer = TaxLib.DynamicTax(
            amount,

            // The maximum decimal places value is checked here
            TaxLib.normalizeShiftAmount(shift)
        );
    }

    /**
     * @dev Apply the tax based on the dynamic tax container
     *
     * @param value The value of transaction
     */
    function _applyTax(uint256 value) internal view returns (uint256)
    {
        return TaxLib.applyTax(
            _taxContainer.amount,
            _taxContainer.shift,
            value
        );
    }
}