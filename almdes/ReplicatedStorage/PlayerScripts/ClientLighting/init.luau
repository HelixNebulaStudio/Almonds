local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");
local Lighting = game.Lighting;

local modCameraGraphics = shared.require(game.ReplicatedStorage.PlayerScripts.CameraGraphics);

local fadeInTweenInfo = TweenInfo.new(5);

local ClientLighting = {};
ClientLighting.__index = ClientLighting;
--==
function ClientLighting:SetAtmosphere(aType)
	if aType == "Menu" then
		modCameraGraphics.Effects:Remove("death");
		modCameraGraphics.Effects:Set("menu", {
			Atmosphere = {
				Density = 0.125;
				Offset = 0;
				Color = Color3.fromRGB(207, 251, 255);
				Decay = Color3.fromRGB(255, 0, 187);
				Glare = 1;
				Haze = 5;
			};
			Ambient = Color3.fromRGB(180, 180, 180);
		}, modCameraGraphics.EffectsPriority.Game);

	elseif aType == "Death" then
		modCameraGraphics.Effects:Remove("menu");
		modCameraGraphics.Effects:Set("death", {
			Atmosphere = {
				Density = 1;
				Offset = 0;
				Color = Color3.fromRGB(0, 0, 0);
				Decay = Color3.fromRGB(0, 0, 0);
				Glare = 0;
				Haze = 10;
			};
			Ambient = Color3.fromRGB(10, 10, 10);
		}, modCameraGraphics.EffectsPriority.Game);

	elseif aType == "Spawn" then
		modCameraGraphics.Effects:Remove("death");
		modCameraGraphics.Effects:Remove("menu");

	end
end

function ClientLighting.onRequire()
end

return ClientLighting;