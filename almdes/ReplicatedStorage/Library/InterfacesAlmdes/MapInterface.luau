local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local UserInputService = game:GetService("UserInputService");
local HttpService = game:GetService("HttpService");
local CollectionService = game:GetService("CollectionService");

local localPlayer = game.Players.LocalPlayer;

local modKeyBindsHandler = shared.require(game.ReplicatedStorage.Library.KeyBindsHandler);
local modSyncTime = shared.require(game.ReplicatedStorage.Library.SyncTime);
local modEventsLibrary = shared.require(game.ReplicatedStorage.Library.EventsLibrary);
local modUIElements = shared.require(game.ReplicatedStorage.Library.UI.UIElements);

local MAP_LEGEND_LIBRARY = {
	["loot"] = {
		Text = "Loot";
		Color = Color3.fromRGB(234, 255, 98);
	};
}

local interfacePackage = {
    Type = "Character";
};
--==


function interfacePackage.newInstance(interface: InterfaceInstance)
	local playerClass: PlayerClass = shared.modPlayers.get(localPlayer);
    local modData = shared.require(localPlayer:WaitForChild("DataModule"));

    local templateMapPointer = script:WaitForChild("templatePointer");
    local templateAxisLine = script:WaitForChild("axisLine");
    local templateGridLabel = script:WaitForChild("gridLabel");
	local templateLegendListing = script:WaitForChild("legendListing");

    local mapCenterVec = Vector2.new(-500, -1000);
    local mapScaleVec = -Vector2.new(5000, 5000);
    local zoomScale = 4;
	local isDraggingMap = false;
	local dragStartVec;
	local newOffsetVec = Vector2.new();
	local mapFollowPlayer = true;

    local windowFrame = script:WaitForChild("MapMenu"):Clone()
    windowFrame.Parent = interface.ScreenGui;

	local lpanel = windowFrame:WaitForChild("LPanel");
	local legendFrame = lpanel:WaitForChild("LegendFrame");

	local mapImageLabel = windowFrame:WaitForChild("mapImage");
	
	local window: InterfaceWindow = interface:NewWindow("Map", windowFrame);
    window.UseMenuBlur = true;
    window.UseTween = false;
    window.DisableInteractables = true;
    window.BoolStringWhenActive = {String="!CharacterHud|CharacterInterface"; Priority=5;};

    local binds = window.Binds;

	local keyId = "KeyWindowMap";
	modKeyBindsHandler:SetDefaultKey(keyId, Enum.KeyCode.M);
	
	local mapQuickButton = interface:NewQuickButton(window.Name, "Map", "rbxassetid://4615489625");
	mapQuickButton.LayoutOrder = 3;
	interface:ConnectQuickButton(mapQuickButton, keyId);

    --MARK: OnToggle
	window.OnToggle:Connect(function(visible)
		if visible then
			windowFrame.Visible = true;
			interface:HideAll{[window.Name]=true};
			
			binds.UpdateEvents();
			binds.UpdateLoots();
            window:Update();
			
		else
			windowFrame.Visible = false;
			isDraggingMap = false;
			
		end
	end)

    local eventsLibraryModule = game.ReplicatedStorage.Library.EventsLibrary;
    local eventsFolder = workspace.Environment.Game.Events;

	local rpanel = windowFrame:WaitForChild("RPanel");
	local buttonsPanel = rpanel:WaitForChild("Buttons");
	
	local closeButton = buttonsPanel:WaitForChild("closeButton");
	local centerButton = buttonsPanel:WaitForChild("centerButton");
	
	closeButton.MouseButton1Click:Connect(function()
		window:Close();
	end)
	
	centerButton.MouseButton1Click:Connect(function()
		mapFollowPlayer = not mapFollowPlayer;
	end)

    local function projectWorldPos(pos)
		local relativePos = (pos-mapCenterVec)/mapScaleVec;
		local projectPos = relativePos * mapImageLabel.AbsoluteSize;
		return projectPos;
	end
	
	local function projectScreenPos(pos)
		local relativePos = pos / mapImageLabel.AbsoluteSize;
		local projectPos = (relativePos * mapScaleVec) + mapCenterVec;
		return projectPos;
	end
	
	local function setMapFramePosition(offset)
		local absSize = mapImageLabel.AbsoluteSize/2;
		
		mapImageLabel.Position = UDim2.new(0.5, 
			math.clamp(newOffsetVec.X + offset.X, -absSize.X, absSize.X), 
			0.5, 
			math.clamp(newOffsetVec.Y + offset.Y, -absSize.Y, absSize.Y)
		);
	end
	
	local function centerOnPlayer()
		local rootPartPos = playerClass.RootPart.Position;
		local projectPos = projectWorldPos(Vector2.new(rootPartPos.X, rootPartPos.Z));
		
		newOffsetVec = -projectPos;
		setMapFramePosition(Vector2.new());
	end
	
	interface.Garbage:Tag(windowFrame.InputChanged:Connect(function(inputObject, gameProcessed)
		if not gameProcessed then
			if inputObject.UserInputType == Enum.UserInputType.MouseWheel then
				local preScale = zoomScale;
				
				zoomScale = math.clamp(zoomScale + inputObject.Position.Z*0.5, 1, 10);
				
				
				if zoomScale ~= preScale then
					if mapFollowPlayer then
						mapImageLabel.Size = UDim2.new(zoomScale, 0, zoomScale, 0);
						centerOnPlayer();
						
					else
						local mousePosition = UserInputService:GetMouseLocation();
						
						local localMousePos = mousePosition - (mapImageLabel.AbsolutePosition + Vector2.new(0, 36) + mapImageLabel.AbsoluteSize/2);
						local rawMousePos = localMousePos/mapImageLabel.AbsoluteSize;
						
						mapImageLabel.Size = UDim2.new(zoomScale, 0, zoomScale, 0);
						
						local offset = localMousePos-(rawMousePos*mapImageLabel.AbsoluteSize);
						setMapFramePosition(offset);
						
					end
					
                    window:Update();
				end
			end
		end
	end));
	
	interface.Garbage:Tag(windowFrame.InputBegan:Connect(function(inputObject, gameProcessed)
		if inputObject.UserInputType == Enum.UserInputType.MouseButton1 
		or inputObject.UserInputType == Enum.UserInputType.Touch then
			isDraggingMap = true;
		end
	end));

	interface.Garbage:Tag(windowFrame.InputEnded:Connect(function(inputObject, gameProcessed)
		if inputObject.UserInputType == Enum.UserInputType.MouseButton1 
		or inputObject.UserInputType == Enum.UserInputType.Touch then
			isDraggingMap = false;
		end
	end));

	binds.MapPoints = {}; 
	
	function binds.AddPointVector(mapPointInfo)
		local id = mapPointInfo.Id;
		local label = mapPointInfo.Label;
		
		for a=1, #binds.MapPoints do
			if binds.MapPoints[a].Id == id then
				return;
			end
		end
		
		
		local localPlayerPointer = mapPointInfo.Pointer or templateMapPointer:Clone();
		localPlayerPointer.Parent = mapImageLabel;
		mapPointInfo.Pointer = localPlayerPointer;
		
		local textLabel = localPlayerPointer:WaitForChild("TextLabel");
		local pointCircle = localPlayerPointer:WaitForChild("PointCircle");
		
		if label then
			pointCircle.Visible = false;
			textLabel.Text = label;
		end
		
		if mapPointInfo.ToolTip then
			textLabel.Text = mapPointInfo.ToolTip;
			textLabel.AnchorPoint = Vector2.new(0.5, 1);
			textLabel.Position = UDim2.new(0.5, 0, 0, -6);
			textLabel.Visible = false;
			
			localPlayerPointer.MouseMoved:Connect(function()
				textLabel.Visible = true;
			end)
			localPlayerPointer.MouseLeave:Connect(function()
				textLabel.Visible = false;
			end)
		end
		
		local eventLib = modEventsLibrary:Find(id);
		if eventLib then
			local radialElement = modUIElements.newRadialButton();
			radialElement.ImageButton.Parent = localPlayerPointer;
			
			local eventIconLabel = radialElement.ImageButton:WaitForChild("icon");
			local titleLabel = radialElement.ImageButton:WaitForChild("title");
			local radialBar = radialElement.ImageButton:WaitForChild("radialBar");
			
			radialElement.ImageButton.Active = false;
			titleLabel.Font = Enum.Font.PermanentMarker;
			titleLabel.TextSize = 28;
			
			mapPointInfo.Radial = radialElement.RadialObject;
			
			eventIconLabel.Image = eventLib.Icon or "";
			eventIconLabel.ZIndex = 1;
			if eventLib.IconSize then
				eventIconLabel.Size = UDim2.new(eventLib.IconSize, 0, eventLib.IconSize, 0);
			end
			
			eventIconLabel.MouseMoved:Connect(function()
				titleLabel.Text = eventLib.Name;
				titleLabel.Visible = true;
			end)
			eventIconLabel.MouseLeave:Connect(function()
				titleLabel.Visible = false;
			end)
			
			mapPointInfo.EventLib = eventLib;
		end
		
		table.insert(binds.MapPoints, mapPointInfo)
		return mapPointInfo;
	end
	
	binds.EventPublicData = {};
	function binds.UpdateEvents()
		local worldEventData = shared.WorldCore.WorldEventsData;
		if worldEventData == nil then return end;

		for eventId, eventPublicData in pairs(worldEventData) do
			local eventLib = modEventsLibrary:Find(eventId);
			
			if eventLib == nil or eventLib.LootMarkOnMap ~= true then continue end;
			binds.EventPublicData[eventId] = eventPublicData;
			
			local eventMap = eventsFolder:FindFirstChild(eventId);
			if eventMap then
				local mapCore = eventMap:FindFirstChild("Core");
				local crateSpawn = mapCore and mapCore:FindFirstChild("CrateSpawn");
				
				binds.AddPointVector({
					Id = eventId;
					Target = crateSpawn;
				});
			end
		end
		
		for eId, _ in pairs(binds.EventPublicData) do
			if worldEventData[eId] then continue end;
			for a=#binds.MapPoints, 1, -1 do
				if binds.MapPoints[a].Id == eId then
					local mapPoint = table.remove(binds.MapPoints, a);
					if mapPoint then
						game.Debris:AddItem(mapPoint.Icon, 0);
					end
				end
			end
		end
	end
	
	binds.UpdateEvents();
	
	function binds.UpdateLoots()
		local lootList = CollectionService:GetTagged("LootCrates");
		
		for a=1, #lootList do
			local lootPrefab = lootList[a];
			local mapPoint = binds.AddPointVector({
				Id = lootPrefab.Name;
				Target = lootPrefab;
				ToolTip = "Loot";
				LegendId = "loot";
			});
			
			if mapPoint then
				local pointerFrame = mapPoint.Pointer;

				local pointCircle = pointerFrame:WaitForChild("PointCircle");
				pointCircle.BackgroundColor3 = Color3.fromRGB(234, 255, 98);
				pointCircle.Size = UDim2.new(0, 6, 0, 6);
			end
		end
	end
	
	interface.Garbage:Tag(CollectionService:GetInstanceAddedSignal("LootCrates"):Connect(function()
		binds.UpdateLoots()
	end));
	interface.Garbage:Tag(CollectionService:GetInstanceRemovedSignal("LootCrates"):Connect(function()
		binds.UpdateLoots()
	end));
	

	--MARK: OnUpdate
	window.OnUpdate:Connect(function()
		local serverTime = workspace:GetServerTimeNow();

		local showLegends = {};

		for a=#binds.MapPoints, 1, -1 do
			local mapPoint = binds.MapPoints[a];
			if mapPoint == nil then continue end;
			
			if mapPoint.LegendId then
				showLegends[mapPoint.LegendId] = (0 or showLegends[mapPoint.LegendId]) + 1;
			end

			if mapPoint.Id == "localplayer" then
				mapPoint.Target = playerClass.RootPart;
			end
			
			local pointerFrame = mapPoint.Pointer;
			local targetObject = mapPoint.Target;
			
			local pos = Vector3.new();
			if typeof(targetObject) == "Vector3" then
				pos = targetObject;
				
			elseif typeof(targetObject) == "Instance" then
				if targetObject:IsA("Model") and targetObject.PrimaryPart then
					pos = targetObject:GetPivot().Position;
					
				elseif targetObject:IsA("BasePart") then
					pos = targetObject.Position;
					
				elseif targetObject:IsA("Attachment") then
					pos = targetObject.WorldPosition;
				end
				
				if not targetObject:IsDescendantOf(workspace) and not targetObject:IsDescendantOf(game.ReplicatedFirst) then
					local remPoint = table.remove(binds.MapPoints, a);
					game.Debris:AddItem(remPoint.Pointer, 0);
				end
				
			end
			
			local projectPos = projectWorldPos(Vector2.new(pos.X, pos.Z));
			pointerFrame.Position = UDim2.new(0.5, projectPos.X, 0.5, projectPos.Y);
			
			local radialObject = mapPoint.Radial;
			if radialObject then
				local imageLabel = radialObject.label;
				
				if mapPoint.EventLib and binds.EventPublicData[mapPoint.Id] then
					local eventPublicData = binds.EventPublicData[mapPoint.Id];
					
					local duration = eventPublicData.RadialDuration;
					local activeTime = eventPublicData.RadialTick or serverTime;
					
					local alpha = 0;

					if eventPublicData.State == "Cooldown" then
						alpha = 1-math.clamp((activeTime-serverTime)/duration, 0, 1);
						imageLabel.ImageColor3 = Color3.fromRGB(255, 255, 255);

					elseif eventPublicData.State == "Idle" or eventPublicData.State == "Active" then
						alpha = 1;
						imageLabel.ImageColor3 = interface.Colors.Branch;

					else
						alpha = 0;
						imageLabel.ImageColor3 = Color3.fromRGB(255, 255, 255);
					end
					
					radialObject:UpdateLabel(alpha);
				end
			end
		end
		
		mapImageLabel.Size = UDim2.new(zoomScale, 0, zoomScale, 0);
		centerButton.BackgroundColor3 = mapFollowPlayer and Color3.fromRGB(50, 50, 100) or Color3.fromRGB(50, 50, 50);


		local legendExist = {};
		for legendId, legendCount in pairs(showLegends) do
			local legendLib = MAP_LEGEND_LIBRARY[legendId];
			legendExist[legendId] = true;

			local newLegend = legendFrame:FindFirstChild(legendId) or templateLegendListing:Clone();
			local textLabel = newLegend:WaitForChild("TextLabel");
			local pointCircle = newLegend:WaitForChild("PointCircle");

			newLegend.Name = legendId;
			newLegend.LayoutOrder = legendCount;
			
			textLabel.Text = legendLib.Text;
			pointCircle.BackgroundColor3 = legendLib.Color;

			newLegend.Parent = legendFrame;
		end
		for _, obj in pairs(legendFrame:GetChildren()) do
			if not obj:IsA("GuiObject") then continue end;
			if legendExist[obj.Name] then continue end;
			obj:Destroy();
		end

	end)
	
	task.spawn(function()
		while true do
			if windowFrame.Visible then
                window:Update();
				
				if isDraggingMap then
					mapFollowPlayer = false;
					
					local mousePosition = UserInputService:GetMouseLocation();
					if dragStartVec == nil then
						dragStartVec = mousePosition;
					end
					
					local offset = mousePosition-dragStartVec;
					
					setMapFramePosition(offset);
					
				else
					if mapFollowPlayer then
						centerOnPlayer();
					end
					
					newOffsetVec = Vector2.new(mapImageLabel.Position.X.Offset, mapImageLabel.Position.Y.Offset);
					dragStartVec = nil;
					
				end
			end
			task.wait();
		end
	end)
	
	local gridCount = 10;
	local gridRatio = 1/gridCount;
	for a=0, gridCount do
		local newAxis = templateAxisLine:Clone();
		newAxis.Size = UDim2.new(99, 0, 0, 1);
		newAxis.Position = UDim2.new(0.5, 0, a * gridRatio, 0);
		newAxis.Parent = mapImageLabel;
	end
	for a=0, gridCount do
		local newAxis = templateAxisLine:Clone();
		newAxis.Size = UDim2.new(0, 1, 99, 0);
		newAxis.Position = UDim2.new(a * gridRatio, 0, 0.5, 0);
		newAxis.Parent = mapImageLabel;
	end
	for x=0, (gridCount-1) do
		for y=0, (gridCount-1) do
			local newLabel = templateGridLabel:Clone();
			newLabel.Text = string.char(65+y)..x;
			newLabel.Position = UDim2.new(x * gridRatio, 15, y * gridRatio, 15);
			newLabel.Parent = mapImageLabel;
		end
	end
	
	binds.AddPointVector({
		Id="localplayer";
		ToolTip="You";
	});
	
	local landMarksFolder = game.ReplicatedFirst:WaitForChild("LandMarks");
	for _, obj in pairs(landMarksFolder:GetChildren()) do
		if obj:IsA("BasePart") then
			binds.AddPointVector({
				Id="landmark"..obj.Name;
				Target=obj;
				Label=obj.Name;
			});
		end
	end



end

return interfacePackage;

