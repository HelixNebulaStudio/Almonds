local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modLibraryManager = shared.require(game.ReplicatedStorage.Library.LibraryManager);

local library = modLibraryManager.new();

library:Add{
	Id="wood";
	InputQuantity=4;
	
	OutputItemId="charcoal";
	OutputQuantity=3;
	
	BurnTime=6;
};

return library;
