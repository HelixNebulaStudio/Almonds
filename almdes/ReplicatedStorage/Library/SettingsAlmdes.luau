local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modSettings = shared.require(game.ReplicatedStorage.Library.Settings);
--==

function modSettings.onRequire()
	local baseConfigInterface = modSettings.DefaultConfigInterface;

    
	local uiKeyCheck = modSettings.Checks.IgnoreMouseKeys(modSettings.Checks.KeyCheck);

	modSettings.Add("KeyWindowInventory", uiKeyCheck);
    modSettings.Add("KeyWindowMap", uiKeyCheck);

	modSettings.SettingsKeybindControlsTable = {
		{Order=1; Type="Border"; Text="Almonds"};

        {Order=114; Type="Option"; Id="KeyWindowInventory"; Text="Inventory"; };
        {Order=115; Type="Option"; Id="KeyWindowMap"; Text="Map Menu"; };
	};
end

return modSettings;