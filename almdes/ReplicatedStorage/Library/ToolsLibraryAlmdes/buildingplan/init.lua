local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="BuildingPlan";

	Animations={
		Core={Id=8388875136;};
		Use={Id=8388988860};
	};
	Audio={};
	Configurations={
		ComponentCost = {
			Wall={ItemId="wood"; Amount=5;};
			Doorway={ItemId="wood"; Amount=5;};
			WallFrame={ItemId="wood"; Amount=5;};
			WindowFrame={ItemId="wood"; Amount=5;};
		};
	};
	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;