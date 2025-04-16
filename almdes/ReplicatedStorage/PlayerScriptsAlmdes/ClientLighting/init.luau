local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local ClientHandler = {};
ClientHandler.__index = ClientHandler;

local TweenService = game:GetService("TweenService");
local Lighting = game.Lighting;

local fadeInTweenInfo = TweenInfo.new(5);
local lightingAtmosphere = script:WaitForChild("Atmosphere");

--==
function ClientHandler:SetAtmosphere(aType)
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

function ClientHandler:OnCharacterAdded(character)
	ClientHandler:SetAtmosphere("Spawn");
end

function ClientHandler:OnCharacterDied(character)
	ClientHandler:SetAtmosphere("Death");
end

function ClientHandler:Init()
	lightingAtmosphere.Parent = Lighting;

	Debugger:Log("Initialized");
end

return ClientHandler;