// SPDX-License-Identifier: AGPL-3.0-or-later
// Code written and documented by Venki - https://github.com/metadimensions

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@aragon/osx/core/dao/IDAO.sol";
import "@aragon/osx/core/permission/PermissionLib.sol";
import {PluginSetup, IPluginSetup} from "@aragon/osx/framework/plugin/setup/PluginSetup.sol";
import "./nationDao.sol";


 contract NationDaoSetup is PluginSetup {
    using Address for address;
    using Clones for address;

    NationDao private immutable nationDaoBase;


    struct NationDaoSettings {
        address nftAddress;
        uint256 proposalThreshold;
        uint256 votingDuration;
    }

    function isContractAddress(address account) internal view returns(bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    constructor(NationDao _nationDaoBase) {
        require(isContractAddress(address(_nationDaoBase)), "NationDao base address is not a contract");
        nationDaoBase = _nationDaoBase;
    
    }

    function isContract(address account) internal view returns (bool) {
    bytes32 codehash;
    bytes32 accountHash = keccak256(abi.encodePacked(''));
    // solhint-disable-next-line no-inline-assembly
    assembly { codehash := extcodehash(account) }
    return (codehash != 0x0 && codehash != accountHash);
    }

    function implementation() external view virtual override returns (address) {
        return address(nationDaoBase);
    }

    function prepareInstallation(
        address _dao,
        bytes calldata _data) external override returns (address plugin, PreparedSetupData memory preparedSetupData) {
        NationDaoSettings memory daoSettings = abi.decode(_data, (NationDaoSettings));
        require(isContract(daoSettings.nftAddress), "NFT address is not a contract");

        plugin = address(nationDaoBase).clone();
        NationDao(plugin).initialize(daoSettings.nftAddress, _dao, daoSettings.votingDuration);

        // Permision setup
        PermissionLib.MultiTargetPermission[] memory permissions = new PermissionLib.MultiTargetPermission[](6);
        // Setting up permissions based on the Id

       permissions[0] = PermissionLib.MultiTargetPermission({
        operation: PermissionLib.Operation.Grant,
        where: plugin,
        who: _dao,
        condition: PermissionLib.NO_CONDITION,
        permissionId: nationDaoBase.UPDATE_SETTINGS_PERMISSION_ID()
    });

// Granting a permission related to proposal creation
permissions[1] = PermissionLib.MultiTargetPermission({
    operation: PermissionLib.Operation.Grant,
    where: plugin,
    who: _dao,
    condition: PermissionLib.NO_CONDITION,
    permissionId: nationDaoBase.CREATE_PROPOSAL_PERMISSION_ID()
});

// Granting a permission related to execute actions
permissions[2] = PermissionLib.MultiTargetPermission({
    operation: PermissionLib.Operation.Grant,
    where: _dao,
    who: plugin,
    condition: PermissionLib.NO_CONDITION,
    permissionId: nationDaoBase.EXECUTE_ACTION_PERMISSION_ID()
});

// Granting a permission related to NFT Voting
permissions[3] = PermissionLib.MultiTargetPermission({
    operation: PermissionLib.Operation.Grant,
    where: plugin,
    who: _dao,
    condition: PermissionLib.NO_CONDITION,
    permissionId: nationDaoBase.NFT_VOTING_PERMISSION_ID()
});

// Granting a permission for NFT management
permissions[4] = PermissionLib.MultiTargetPermission({
    operation: PermissionLib.Operation.Grant,
    where: _dao,
    who: plugin,
    condition: PermissionLib.NO_CONDITION,
    permissionId: nationDaoBase.NFT_MANAGEMENT_PERMISSION_ID()
});

// Granting a permission for administrative control
permissions[5] = PermissionLib.MultiTargetPermission({
    operation: PermissionLib.Operation.Grant,
    where: _dao,
    who: plugin,
    condition: PermissionLib.NO_CONDITION,
    permissionId: nationDaoBase.ADMIN_CONTROL_PERMISSION_ID()
});

// Granting the permission setup to the address which is already in the  

    preparedSetupData.helpers = new address[](1);
    preparedSetupData.helpers[0] = daoSettings.nftAddress;
    preparedSetupData.permissions = permissions;
        
    return (plugin, preparedSetupData);
    }

function prepareUninstallation(
    address _dao,
    SetupPayload calldata _payload
) external view returns (PermissionLib.MultiTargetPermission[] memory permissions) {
    // Ensure the uninstallation request is for the correct plugin
    require(_payload.plugin == address(nationDaoBase), "Incorrect plugin address");
    // This number should match the number of permissions originally granted during installation
    permissions = new PermissionLib.MultiTargetPermission[](6);

// Revoking a permission realated to update settings

permissions[0] = PermissionLib.MultiTargetPermission({
    operation: PermissionLib.Operation.Revoke,
    where: _payload.plugin,
    who: _dao,
    condition: PermissionLib.NO_CONDITION,
    permissionId: nationDaoBase.UPDATE_SETTINGS_PERMISSION_ID()
});

// Revoking a permission related to proposal creation
permissions[1] = PermissionLib.MultiTargetPermission({
    operation: PermissionLib.Operation.Revoke,
    where: _payload.plugin,
    who: _dao,
    condition: PermissionLib.NO_CONDITION,
    permissionId: nationDaoBase.CREATE_PROPOSAL_PERMISSION_ID()
});

// Revoking a permission related to executing actions
permissions[2] = PermissionLib.MultiTargetPermission({
    operation: PermissionLib.Operation.Revoke,
    where: _dao,
    who: _payload.plugin,
    condition: PermissionLib.NO_CONDITION,
    permissionId: nationDaoBase.EXECUTE_ACTION_PERMISSION_ID()
});

// Revoking permission for NFT-based voting
permissions[3] = PermissionLib.MultiTargetPermission({
    operation: PermissionLib.Operation.Revoke,
    where: _payload.plugin,
    who: _dao,
    condition: PermissionLib.NO_CONDITION,
    permissionId: nationDaoBase.NFT_VOTING_PERMISSION_ID()
});

// Revoking a permission for NFT management
permissions[4] = PermissionLib.MultiTargetPermission({
    operation: PermissionLib.Operation.Revoke,
    where: _dao,
    who: _payload.plugin,
    condition: PermissionLib.NO_CONDITION,
    permissionId: nationDaoBase.NFT_MANAGEMENT_PERMISSION_ID()
});

// Revoking a permission for administrative control
permissions[5] = PermissionLib.MultiTargetPermission({
    operation: PermissionLib.Operation.Revoke,
    where: _dao,
    who: _payload.plugin,
    condition: PermissionLib.NO_CONDITION,
    permissionId: nationDaoBase.ADMIN_CONTROL_PERMISSION_ID()
});
}
}
