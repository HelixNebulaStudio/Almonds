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

	local globalProperties = eventInstance.WorldEvents.GlobalProperties;

	local eventCorePart = eventMap:WaitForChild("Core");

	local interactableCounter = 0;
	for _, obj in pairs(eventCorePart:GetChildren()) do
		if obj.Name == "HeliExfilInteract" then
			interactableCounter = interactableCounter +1;
			local exfilKey = `Exfil${interactableCounter}`;
			
			local newAtt = Instance.new("Attachment");
			newAtt.Name = "HeliExfilInteract";
			newAtt.Parent = eventCorePart;
			newAtt.WorldCFrame = obj:GetPivot();
			newAtt:SetAttribute(`ExfilKey`, exfilKey);
			newAtt:SetAttribute("MarkerId", exfilKey);
			newAtt:SetAttribute("Disabled", false);

			obj:Destroy();
		end
	end
	publicData.HeliExfilCount = interactableCounter;

	local heliExfilInteractables = {};

	local function setupHeliExfils()
		for _, att in pairs(eventCorePart:GetChildren()) do
			if att.Name ~= "HeliExfilInteract" then continue end;

			att:SetAttribute("Disabled", false);
            att:SetAttribute("ExfilCalled", false);
			att:SetAttribute("LeaveTime", nil);
			att:SetAttribute("ReadyLeaveTime", nil);
			att:SetAttribute("WaitDuration", nil);

			local exfilKey = att:GetAttribute("ExfilKey");

			local newHeliExfilInteract = eventPackage.Prefabs.HeliExfilInteract:Clone();
			newHeliExfilInteract.Name = exfilKey;
			newHeliExfilInteract:PivotTo(att.WorldCFrame);
			newHeliExfilInteract.Parent = workspace.Interactables;

			garbageHandler:Tag(newHeliExfilInteract);

			local interactConfig: Configuration = newHeliExfilInteract:WaitForChild("Interactable") :: Configuration;
			local interactable: InteractableInstance = modInteractables.getOrNew(interactConfig);
			interactable.Values.Attachment = att;
			interactable.Values.InteractModel = newHeliExfilInteract;
			table.insert(heliExfilInteractables, interactable);
		end
		garbageHandler:Tag(heliExfilInteractables);
	end

	globalProperties.OnChanged:Connect(function(k, v)
		if k ~= "StormState" then return end;
		if v == "Start" then
			shared.Notify(game.Players:GetPlayers(), `[Radio]: Final exfil has been called! This is the last exfil before the storm hits.`, "Important")
			for _, interactable in pairs(heliExfilInteractables) do
				interactable:Activate(true);
			end

		elseif v == "Active" then
			garbageHandler:Destruct();

		elseif v == "Idle" then
			setupHeliExfils();

		end
	end)
	setupHeliExfils();
	
end

function eventPackage.RenderMarker(mapMarker: MapMarker, eventPublicData: anydict)
	local radialImage: RadialImage = mapMarker.RadialElement.RadialImage;
	local imageLabel: ImageLabel = radialImage.ImageLabel;
	local markerAtt: Attachment = mapMarker.Target :: Attachment;
	
	local serverTime = workspace:GetServerTimeNow();

	local alpha = 1;

	local redcrowStormPublicData = shared.WorldCore.WorldEventsData and shared.WorldCore.WorldEventsData.redcrowstorm;
	if redcrowStormPublicData then
		local activeDuration = redcrowStormPublicData.CycleDuration - redcrowStormPublicData.IdleCycleDuration;
		local timeRemaining = (redcrowStormPublicData.EndTick-activeDuration) - serverTime;
		local duration = redcrowStormPublicData.IdleCycleDuration;
		alpha = math.clamp(timeRemaining/duration, 0, 1);
	end

	local isExfilCalled = markerAtt:GetAttribute("ExfilCalled");
	if isExfilCalled then
		imageLabel.ImageColor3 = modClientGuis.ActiveInterface.Colors.ActivePrimary;

		local waitDuration = markerAtt:GetAttribute("WaitDuration");
        local leaveTime = markerAtt:GetAttribute("LeaveTime");

		if waitDuration and leaveTime then
			local timeRemaining = leaveTime - workspace:GetServerTimeNow();

			local readyLeaveTime = markerAtt:GetAttribute("ReadyLeaveTime");
			if readyLeaveTime then
				timeRemaining = readyLeaveTime - workspace:GetServerTimeNow();
			end

			alpha = math.clamp(timeRemaining/waitDuration, 0, 1);
		else
			alpha = 1;
		end

	else
		imageLabel.ImageColor3 = modClientGuis.ActiveInterface.Colors.Branch;
	end

	radialImage:UpdateLabel(alpha);
end

return eventPackage;