local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modStatusLibrary = require(game.ReplicateStorage.Library.StatusLibrary);

local function loadModule(module: Instance) 
	if not module:IsA("ModuleScript") then return end;
	if module.Name == "StatusClass" then return end;
	modStatusLibrary:LoadModule(module);
end

for _, ms in pairs(script:GetChildren()) do
    loadModule(ms);
end
script.ChildAdded:Connect(loadModule);


return modStatusLibrary;