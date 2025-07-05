local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="DeployableTool";

	Animations={
		Core={Id=4379418967;};
		Placing={Id=4379471624};
	};
	Audio={};
	Configurations={
		DisplayName = "Wall";
		StructureType = "Wall";
		
		BuildDuration = 2;
		PlacementOffset = CFrame.Angles(0, 0, 0);
		
		ResizeToFit = true;
		StructureHealth = 500;
	};
	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;