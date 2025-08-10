local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local camera = workspace.CurrentCamera;

local eventPackage = {
	Id = "extractionpoints";
	Name = "Extraction Points";
};

--==
function eventPackage.onRequire()

end

function eventPackage.newInstance(worldEventHandler: WorldEventInstance)
	Debugger:Warn(`newInstance {eventPackage.Id}`);

	local scheduler: Scheduler = worldEventHandler.Scheduler;
	local properties: PropertiesVariable<{}> = worldEventHandler.Properties;
	local garbageHandler: GarbageHandler = worldEventHandler.Garbage;
	local publicData = worldEventHandler.Public;

	

end

return eventPackage;