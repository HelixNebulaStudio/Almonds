local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="FoodTool";

	Animations={
		Core={Id=17145603824;};
		Use={Id=17145607603;};
	};
	Audio={};
	
	Configurations={
		EffectDuration = 10;
		EffectType = "Food";

		Calories = 45;
		Hydration = 25;
		
		UseDuration = 4;
	};
	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;