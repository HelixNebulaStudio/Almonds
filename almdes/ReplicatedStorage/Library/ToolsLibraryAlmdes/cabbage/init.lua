local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="FoodTool";

	Animations={
		Core={Id=3296519824;};
		Use={Id=4534092581;};
	};
	Audio={};
	Configurations={
		EffectDuration = 10;
		EffectType = "Food";
		
		Calories = 15;
		Hydration = 5;
		
		UseDuration = 3;
	};
	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;