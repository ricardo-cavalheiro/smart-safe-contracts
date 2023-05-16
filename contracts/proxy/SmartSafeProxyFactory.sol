// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * @author Ricardo Passos - @ricardo-passos
 */
contract SmartSafeProxyFactory {
    error DeployFailed(bytes);
    error CallerIsNotAnOwner();
    error AddressIsNotAContract();
    error MismatchedAddress(address required, address received);

    event Called(bytes);
    event Deployed(address indexed);

    address private owner;
    uint64 private nonce = 0;
    address public smartSafeImplementation;

    constructor(address _owner, address _smartSafeImplementation) {
        owner = _owner;
        smartSafeImplementation = _smartSafeImplementation;
    }

    function renounceOwnernship(address _newOwner) external {
        onlyOwner(msg.sender);

        owner = _newOwner;
    }

    function setSmartSafeImplementation(
        address _newSmartSafeImplementation
    ) external {
        onlyOwner(msg.sender);

        if (isContract(_newSmartSafeImplementation) == false) {
            revert AddressIsNotAContract();
        }

        smartSafeImplementation = _newSmartSafeImplementation;
    }

    function computeSalt(address _owner) private view returns (bytes32) {
        return bytes32(uint256(uint160(_owner) + nonce));
    }

    function computeAddress(address _owner) public view returns (address) {
        bytes32 salt = computeSalt(_owner);

        return
            Clones.predictDeterministicAddress(smartSafeImplementation, salt);
    }

    function deploySmartSafeProxy(
        address[] calldata _owners,
        uint8 _threshold
    ) external payable {
        if (isContract(smartSafeImplementation) == false) {
            revert AddressIsNotAContract();
        }

        bytes32 salt = computeSalt(_owners[0]);
        address predictedAddress = computeAddress(_owners[0]);
        address deployedProxyAddress = Clones.cloneDeterministic(
            smartSafeImplementation,
            salt
        );

        if (deployedProxyAddress != predictedAddress) {
            revert MismatchedAddress(predictedAddress, deployedProxyAddress);
        }

        // TODO:
        // it's possible to hard-code the "setupOwners(address[],uint8)" string
        // and just encode it with the rest of the parameters;
        // it will save some gas;
        bytes memory initializeSmartSafeData = abi.encodeWithSignature(
            "setupOwners(address[],uint8)",
            _owners,
            _threshold
        );
        (bool success, bytes memory returndata) = deployedProxyAddress.call{
            value: msg.value
        }(initializeSmartSafeData);

        if (!success && returndata.length > 0) {
            revert DeployFailed(returndata);
        }

        emit Deployed(deployedProxyAddress);
    }

    function isContract(address _address) private view returns (bool) {
        return _address.code.length > 0;
    }

    function onlyOwner(address _owner) private view {
        if (_owner != owner) {
            revert CallerIsNotAnOwner();
        }
    }

    function callImpl(bytes calldata _data, address _impl) external payable {
        (bool success, bytes memory returndata) = _impl.call{value: msg.value}(
            _data
        );

        if (!success && returndata.length > 0) {
            revert DeployFailed(returndata);
        }

        emit Called(returndata);
    }
}
