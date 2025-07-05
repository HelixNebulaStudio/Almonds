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
		DisplayName = "Window Barricade";
		StructureType = "WindowFrame";
		
		BuildDuration = 2;
		PlacementOffset = CFrame.new(0, 4, 0) * CFrame.Angles(0, 0, 0);
		
		ResizeToFit = true;
		StructureHealth = 250;
	};
	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;