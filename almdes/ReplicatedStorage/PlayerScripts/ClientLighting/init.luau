local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");
local Lighting = game.Lighting;

local fadeInTweenInfo = TweenInfo.new(5);

local lightingAtmosphere;

local ClientLighting = {};
ClientLighting.__index = ClientLighting;
--==
function ClientLighting:SetAtmosphere(aType)
	if aType == "Death" then
		TweenService:Create(lightingAtmosphere, fadeInTweenInfo, {
			Density = 1; 
			Haze=10;
			Glare=0;
			Color=Color3.fromRGB(0, 0, 0);
			Decay=Color3.fromRGB(0, 0, 0);
		}):Play();
		Lighting.Ambient = Color3.fromRGB(10, 10, 10);
		
	elseif aType == "Spawn"  then
		TweenService:Create(lightingAtmosphere, fadeInTweenInfo, {
			Density = 0; 
			Haze=0;
			Glare=0;
			Color=Color3.fromRGB(0, 0, 0);
			Decay=Color3.fromRGB(0, 0, 0);
		}):Play();
		Lighting.Ambient = Color3.fromRGB(10, 10, 10);
		
	elseif aType == "Menu" then
		TweenService:Create(lightingAtmosphere, fadeInTweenInfo, {
			Density = 0.125; 
			Haze=5;
			Glare=1;
			Color=Color3.fromRGB(207, 251, 255);
			Decay=Color3.fromRGB(255, 0, 187);
		}):Play();
		Lighting.Ambient = Color3.fromRGB(180, 180, 180);
		
	end
end

function ClientLighting:OnCharacterAdded(character)
	ClientLighting:SetAtmosphere("Spawn");
end

function ClientLighting:OnCharacterDied(character)
	ClientLighting:SetAtmosphere("Death");
end

function ClientLighting.onRequire()
	lightingAtmosphere = script:WaitForChild("Atmosphere");
	lightingAtmosphere.Parent = Lighting;
	
	Debugger:Log("Initialized");
end

return ClientLighting;