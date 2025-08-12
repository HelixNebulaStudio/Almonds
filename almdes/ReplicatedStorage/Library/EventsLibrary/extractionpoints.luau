local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local camera = workspace.CurrentCamera;

local modInteractables = shared.require(game.ReplicatedStorage.Library.InteractablesAlmdes);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local eventPackage = {
	Id = "extractionpoints";
	Name = "Extraction Points";

	Prefabs = {
		Helicopter = nil;
		HeliExfilInteract = nil;
	};

	MapMarkers = {
		["HeliExfilInteract"] = {
			Icon = "rbxassetid://126643722874405";
			Label = "Helicopter Extraction";
		};
	};

	TemplateEventMap = nil;
};

--==
function eventPackage.onRequire()
	if RunService:IsClient() then return end;

	local prefabStorage = game.ServerStorage.Prefabs;
	eventPackage.Prefabs = {
		HeliExfilInteract = prefabStorage:WaitForChild("Interactables"):WaitForChild("HeliExfilInteract");
	};
end

function eventPackage.newInstance(eventInstance: WorldEventInstance)
	Debugger:Warn(`newInstance {eventPackage.Id}`);

	local scheduler: Scheduler = eventInstance.Scheduler;
	local properties: PropertiesVariable<{}> = eventInstance.Properties;
	local garbageHandler: GarbageHandler = eventInstance.Garbage;
	local publicData = eventInstance.Public;

	local eventMap = eventInstance.TemplateEventMap;
	eventMap.Parent = workspace.Environment.Game.Events;

	publicData.StartTime = workspace:GetServerTimeNow();
	publicData.ExpireTime = publicData.StartTime + (60*7);

	local eventCorePart = eventMap:WaitForChild("Core");
	local interactableCounter = 0;

	for _, att in pairs(eventCorePart:GetChildren()) do
		if not att:IsA("Attachment") then continue end;

		interactableCounter = interactableCounter +1;
		local exfilKey = `Exfil${interactableCounter}`;
		att:SetAttribute(`ExfileKey`, exfilKey);

		if att.Name == "HeliExfilInteract" then
			local newHeliExfilInteract = eventPackage.Prefabs.HeliExfilInteract:Clone();
			newHeliExfilInteract.Name = exfilKey;
			newHeliExfilInteract:PivotTo(att.WorldCFrame);
			newHeliExfilInteract.Parent = workspace.Interactables;

			garbageHandler:Tag(newHeliExfilInteract);

			local interactConfig: Configuration = newHeliExfilInteract:WaitForChild("Interactable") :: Configuration;
			local interactable: InteractableInstance = modInteractables.getOrNew(interactConfig);
			interactable.Values.InteractModel = newHeliExfilInteract;
		end
	end
	
end

function eventPackage.RenderMarker(mapMarker: MapMarker, eventPublicData: anydict)
	local radialImage: RadialImage = mapMarker.RadialElement.RadialImage;
	local imageLabel: ImageLabel = radialImage.ImageLabel;
	local markerAtt: Attachment = mapMarker.Target :: Attachment;
	
	local serverTime = workspace:GetServerTimeNow();

	local duration = eventPublicData.ExpireTime - eventPublicData.StartTime;
	local lapse = eventPublicData.ExpireTime - serverTime;

	local alpha = math.clamp(lapse/duration, 0, 1);

	local exfilKey = markerAtt:GetAttribute("ExfileKey");
	local interactModel: Model = workspace.Interactables:FindFirstChild(exfilKey);

	if interactModel == nil then return end;
	local config: Configuration? = interactModel:FindFirstChild("Interactable") :: Configuration;
	if config == nil then return end;

	local interactable: InteractableInstance = modInteractables.getOrNew(config);
	if interactable.Values.ExfilCalled then
		imageLabel.ImageColor3 = Color3.fromRGB(204, 0, 255);
	else
		imageLabel.ImageColor3 = modClientGuis.ActiveInterface.Colors.Branch;
	end

	radialImage:UpdateLabel(alpha);
end

return eventPackage;