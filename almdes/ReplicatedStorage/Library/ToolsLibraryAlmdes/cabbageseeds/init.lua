local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="SeedTool";

	Animations={
		Core={Id=11490542403;};
	};
	Audio={};
	Configurations={
		SeedType = "cabbage";
		
		SpaceRequired = 1;
		MineralCost = 30;
	};
	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;