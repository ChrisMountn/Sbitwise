# Sbitwise
Solidity practice project - backend for a DAPP that mimics the functionality of "Splitwise", but with a built-in transfer system via the ethereum blockchain. 

Sbitwise allows users to contribute to a group fund, with the expectation that everyone will be paid back evenly. Users indicate that they have bought something (in real life, with personal money) using the addToPaid function. Once all users have used addToPaid to indicate everything they have bought for the group, all users will use agreeToSplit to indicate that they agree those really are the values that their friends have spent (this is based on real life group consensus). Then users are able to use putMoneyInContract to add money to the contract. Finally, the settleUp function redistributes the money in the contract to compensate those who have spent more than the average group member on purchases for the group, using the money input by users who spent less than the the average group member. 

If the financial state of the contract is changed after all users have called agreeToSplit, their agreements are voided and they must agree again. 

I do not intend to put this idea into production, but it was good practice for writing and testing solidity code wth Truffle, Mocha, and Chai. 

The solidity contract can be found in Sbitwise/Truffle_Project_2_Sbitwise/contracts/Sbitwise.sol. 
The JavaScript unit tests can be found in Sbitwise/Truffle_Project_2_Sbitwise/test/sbitwise_test.js.
