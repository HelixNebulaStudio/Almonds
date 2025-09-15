local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local PLACE_NORMAL_LIMIT = math.rad(20);

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="DeployableTool";

	Animations={
		Core={Id=11490542403;};
	};
	Audio={};
	Configurations={
		DisplayName = "Cabbage";
		DeployableType = "Seed";
		UseToolModelItemId = "cabbage";
		
		PlaceNormalLimits = NumberRange.new(-PLACE_NORMAL_LIMIT, PLACE_NORMAL_LIMIT);

		SeedType = "cabbage";
		SpaceRequired = 1;

		WaterCostPerMin = 30;

		InteractableName = "Seed";
		CollectionTags = {"Seed"};
	};
	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;