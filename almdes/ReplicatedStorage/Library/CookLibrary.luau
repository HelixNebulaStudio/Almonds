local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modLibraryManager = shared.require(game.ReplicatedStorage.Library.LibraryManager);

local library = modLibraryManager.new();

local CookingTypes = {
	Foods = {
		Campfire=true;
		Furnace=true;
	};
	Metals = {
		Furnace=true;
	};
};
library.CookingTypes = CookingTypes;

--==

library:Add{
	Type=CookingTypes.Metals;
	
	Id="cannedbeans";
	InputQuantity=1;
	
	OutputItemId="metal";
	OutputQuantity=8;
	
	CookTime=15;
};

library:Add{
	Type=CookingTypes.Metals;
	
	Id="cannedfish";
	InputQuantity=1;

	OutputItemId="metal";
	OutputQuantity=8;

	CookTime=15;
};

library:Add{
	Type=CookingTypes.Metals;

	Id="bloxycola";
	InputQuantity=1;

	OutputItemId="metal";
	OutputQuantity=8;

	CookTime=15;
};

library:Add{
	Type=CookingTypes.Metals;

	Id="metal";
	InputQuantity=2;
	
	MixInItemId="charcoal";
	MixInQuantity=2;
	
	--MixOutItemId="sulfur";
	--MixOutQuantity=1;
	ConsumeMix=true;
	
	OutputItemId="steelfragments";
	OutputQuantity=1;

	CookTime=3;
};

return library;
