local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modAlmdesCore = require(game.ReplicatedStorage.AlmdesCore :: ModuleScript);

for _, s in pairs(script:GetChildren()) do
	if s.ClassName ~= "ModuleScript" then continue end;
	task.spawn(function()
		require(s):Init();
		Debugger:Warn(`Initialized {s.Name}`);
	end)
end