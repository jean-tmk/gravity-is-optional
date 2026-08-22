// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
contract GravityPolicyRegistry {
    struct Policy { uint16 angle; uint8 strength; uint8 stability; bool approved; bytes32 evidence; }
    address public immutable clerk; mapping(bytes32=>Policy) public policies;
    event PolicyFiled(bytes32 indexed slug,uint16 angle,uint8 strength,uint8 stability); event PolicyApprovalChanged(bytes32 indexed slug,bool approved);
    error ClerkOnly(); error InvalidAngle(); error InvalidPercentage();
    constructor(){clerk=msg.sender;} modifier onlyClerk(){if(msg.sender!=clerk)revert ClerkOnly();_;}
    function filePolicy(bytes32 slug,uint16 angle,uint8 strength,uint8 stability,bytes32 evidence) external onlyClerk { if(angle>=360)revert InvalidAngle(); if(strength>100||stability>100)revert InvalidPercentage(); policies[slug]=Policy(angle,strength,stability,false,evidence); emit PolicyFiled(slug,angle,strength,stability); }
    function approve(bytes32 slug,bool value) external onlyClerk { policies[slug].approved=value; emit PolicyApprovalChanged(slug,value); }
}
