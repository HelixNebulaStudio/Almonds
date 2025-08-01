local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="FoodTool";

	Animations={
		Core={Id=17145574614;};
		Use={Id=17145576789;};
	};
	Audio={};
	
	Configurations={
		EffectDuration = 10;
		EffectType = "Food";

		Calories = 35;
		Hydration = -5;

		UseDuration = 2;
	};
	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;