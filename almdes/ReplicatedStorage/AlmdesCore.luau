local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local AlmdesCore = {};
--==
local modInteractables = Debugger:Require(game.ReplicatedStorage.Library.InteractablesAlmdes :: ModuleScript);

Debugger:Warn("Init AlmdesCore.");
return AlmdesCore;