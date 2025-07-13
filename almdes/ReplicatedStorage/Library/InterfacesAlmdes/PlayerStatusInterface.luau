local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local localPlayer = game.Players.localPlayer;

local modStatusLibrary = shared.require(game.ReplicatedStorage.Library.StatusLibrary);
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modSyncTime = shared.require(game.ReplicatedStorage.Library.SyncTime);

local modItemInterface = shared.require(game.ReplicatedStorage.Library.UI.ItemInterface);
local modRadialImage = shared.require(game.ReplicatedStorage.Library.UI.RadialImage);

local RADIAL_CONFIG = '{"version":1,"size":128,"count":128,"columns":8,"rows":8,"images":["rbxassetid://4467212179","rbxassetid://4467212459"]}';
local POPIN_TWEENINFO = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
local BAR_TWEENINFO = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut);

local BUFF_COLOR = Color3.fromRGB(16, 107, 66);
local DEBUFF_COLOR = Color3.fromRGB(110, 44, 44);
local NEUTRAL_COLOR = Color3.fromRGB(52, 52, 176);

local interfacePackage = {
    Type = "Character";
};
--==


function interfacePackage.newInstance(interface: InterfaceInstance)
    local modData = shared.require(localPlayer:WaitForChild("DataModule"));

	local playerClass: PlayerClass = shared.modPlayers.get(localPlayer);
    local healthComp: HealthComp = playerClass.HealthComp;
	local statusComp: StatusComp = playerClass.StatusComp;

	local playerHudFrame = script:WaitForChild("PlayerHud"):Clone();
	playerHudFrame.Parent = interface.ScreenGui;
	
	--MARK: PlayerHud
	local playerHudWindow: InterfaceWindow = interface:NewWindow("PlayerHud", playerHudFrame);
	playerHudWindow.IgnoreHideAll = true;
	playerHudWindow.ReleaseMouse = false;
	playerHudWindow:Open();


	local barsFrame = playerHudFrame:WaitForChild("HealthBars");
	local healthBar = barsFrame:WaitForChild("HealthBar");
	local armorBar = barsFrame:WaitForChild("ArmorBar");

	--MARK: OnUpdate
    playerHudWindow.OnUpdate:Connect(function()
		local health, maxHealth = healthComp.CurHealth, healthComp.MaxHealth;
		local armor, maxArmor = healthComp.CurArmor, healthComp.MaxArmor;
		armor = armor or 0;
		maxArmor = maxArmor or 1;
		
		local maxPool = maxHealth+maxArmor;
			
		local healthRatio = math.clamp(health/maxPool, 0, 1);
		TweenService:Create(healthBar, BAR_TWEENINFO, {
			Size = UDim2.new(healthRatio, 0, 1, 0);
		}):Play();

		local armorRatio = maxArmor > 0 and math.clamp(armor/maxPool, 0, 1) or 0;
		TweenService:Create(armorBar, BAR_TWEENINFO, {
			Size = UDim2.new(armorRatio, 0, 1, 0);
		}):Play();
	end)
	
    local function fireUpdate(new, old, reason)
        playerHudWindow:Update();
    end
    
	interface.Garbage:Tag(healthComp.OnArmorChanged:Connect(fireUpdate));
	interface.Garbage:Tag(healthComp.OnHealthChanged:Connect(fireUpdate));
	interface.Garbage:Tag(healthComp.OnIsDeadChanged:Connect(fireUpdate));
	playerHudWindow:Update();



	--MARK: StatusEffectsHud
    local charWindow = interface:GetWindow("CharacterWindow");
    local lPanel = charWindow.Binds.LPanel;

	local statusEffectFrame = script:WaitForChild("StatusEffectsHud"):Clone();
	statusEffectFrame.Parent = interface.ScreenGui;

	local statusContentList = statusEffectFrame:WaitForChild("ContentList");
	local statusTitleLabel = statusEffectFrame:WaitForChild("Title");
	local templateStatusItem = script:WaitForChild("statusItem");

	local statusEffectsWindow: InterfaceWindow = interface:NewWindow("StatusEffectsHud", statusEffectFrame);
	statusEffectsWindow.UseTween = false;
    statusEffectsWindow.IgnoreHideAll = true;
	statusEffectsWindow.ReleaseMouse = false;

	--MARK: OnWindowToggle
	local isInCharWindow = false;
	interface.OnWindowToggle:Connect(function(window)
		if window.Name ~= "CharacterWindow" then return end;

		if window.Visible then
			statusEffectFrame.Parent = lPanel;
			statusEffectFrame.AnchorPoint = Vector2.new(0.5, 1);
			statusEffectFrame.Position = UDim2.new(0.5, 0, 1, -80);
			statusEffectFrame.Size = UDim2.new(1, 0, 0, 90);
			statusContentList.ScrollingEnabled = true;
			statusTitleLabel.Visible = true;
			isInCharWindow = true;

		else
			statusEffectFrame.Parent = interface.ScreenGui;
			statusEffectFrame.AnchorPoint = Vector2.new(0.5, 1);
			statusEffectFrame.Position = UDim2.new(0.5, 0, 1, -150);
			statusEffectFrame.Size = UDim2.new(1, 0, 0, 40);
			statusContentList.ScrollingEnabled = false;
			statusTitleLabel.Visible = false;
			isInCharWindow = false;

		end

		statusEffectsWindow:Update();
	end)


	--MARK: OnToggle
	statusEffectsWindow.OnToggle:Connect(function(visible)
		if visible then
			statusEffectsWindow._visible = true;
			statusEffectFrame.Visible = true;
		else
			statusEffectsWindow._visible = false;
			statusEffectFrame.Visible = false;
		end
	end);
	statusEffectsWindow:Open();

	local templateStatusTooltip = script:WaitForChild("statusTooltip");
	local statusToolTipObj = modItemInterface.newItemTooltip();
	statusToolTipObj.Frame.Parent = interface.ScreenGui;
	game.Debris:AddItem(statusToolTipObj.Frame:WaitForChild("UISizeConstraint"), 0);

	local statusTooltipFrame = templateStatusTooltip:Clone();
	statusTooltipFrame.Parent = statusToolTipObj.Frame.custom;

	function statusToolTipObj:SetPosition(guiObject)
		local targetPos = guiObject.AbsolutePosition;
		local targetSize = guiObject.AbsoluteSize;
		
		local frameSize = self.Frame.AbsoluteSize;
		
		self.Frame.Position = UDim2.new(
			0, 
			targetPos.X+(targetSize.X/2)-(frameSize.X/2), 
			0, 
			targetPos.Y-frameSize.Y+30
		);
	end

	local statusGuiObjList = {};
	local smoothTime, lastTick, lastOsTime = 0, 0, 0;

	local function updateStatusObj(lib, statusId, statusClass: StatusClassInstance)
		local libId = lib.Id;

		local statusGuiObj = statusGuiObjList[statusId];
		if statusGuiObj == nil then
			statusGuiObj = {
				Lib = lib;
				StatusId = statusId;
				StatusClass = statusClass;
			};
			statusGuiObjList[statusId] = statusGuiObj;
		end

		if statusGuiObj.Button == nil then
			statusGuiObj.Button = templateStatusItem:Clone();
			statusGuiObj.Button.MouseButton1Click:Connect(function()
				if modBranchConfigs.CurrentBranch.Name == "Dev" then
					Debugger:Warn("Status id:",statusId,"table:", statusClass);
				end
			end)
			
			local function toolTipUpdate(self)
				self.Frame.Size = UDim2.new(0, 160, 0, 180);
				self.Frame.custom.Visible = true;

				local nameTag = self.Frame:WaitForChild("NameTag");
				nameTag.Text = lib.Name;

				local descLabel = statusTooltipFrame.descLabel;
				local descText = lib.Description;

				local alpha = 1;
				local duration = statusClass.Duration or 1;
				local expires = statusClass.Expires or smoothTime;
				if statusClass.Expires and statusClass.Duration then
					alpha = math.clamp((expires-smoothTime)/duration, 0, 1);
				end
				
				local timeStamp = `({modSyncTime.ToString(expires-smoothTime)})`;
				descText = descText..(alpha ~= 1 and ` {timeStamp}` or ``);
				
				for k, v in pairs(statusClass.Values) do
					if typeof(v) == "string" or typeof(v) == "number" then 
						descText = descText:gsub("$"..k, v);
					end
				end
					
				descLabel.Text = descText;

				local iconLabel = statusTooltipFrame.Icon;
				iconLabel.Image = lib.Icon;
			end
			
			statusToolTipObj:BindHoverOver(statusGuiObj.Button, function()
				if not statusToolTipObj.Frame.Visible then return end;

				statusToolTipObj.Frame.Parent = interface.ScreenGui;
				statusToolTipObj.CustomUpdate = toolTipUpdate;

				statusToolTipObj:Update();
				statusToolTipObj:SetPosition(statusGuiObj.Button);
			end)
			
			statusGuiObj.Button.Parent = statusContentList;

			local radialBar = statusGuiObj.Button:WaitForChild("radialBar");
			statusGuiObj.Radial = modRadialImage.new(RADIAL_CONFIG, radialBar);
			statusGuiObj.Icon = statusGuiObj.Button:WaitForChild("icon");
			statusGuiObj.Info = statusGuiObj.Button:WaitForChild("info");
			statusGuiObj.Title = statusGuiObj.Button:WaitForChild("title");
			statusGuiObj.Quan = statusGuiObj.Button:WaitForChild("quantity");
			
			statusGuiObj.Icon.Image = lib.Icon or `rbxassetid://484211948`;
			statusGuiObj.Title.Text = lib.Name or libId;

			local alphaValue = Instance.new("NumberValue");
			alphaValue.Value = 0;
			alphaValue.Parent = radialBar;

			statusGuiObj.AlphaValue = alphaValue;
			alphaValue:GetPropertyChangedSignal("Value"):Connect(function()
				statusGuiObj.Radial:UpdateLabel(alphaValue.Value);
			end)
		end
		
		
		local alpha = 1;
		local statusValues = statusClass.Values;
		
		if statusValues.Icon then
			statusGuiObj.Icon.Image = statusValues.Icon;
		end
		if statusValues.IconColor then
			statusGuiObj.Icon.ImageColor3 = statusValues.IconColor;
		end
		if statusClass.Name then
			statusGuiObj.Title.Text = lib.Name or ``;
		end

		if statusClass.Alpha then
			alpha = statusClass.Alpha;

		elseif statusClass.Duration and statusClass.Expires then
			alpha = (statusClass.Expires-smoothTime)/statusClass.Duration;
			
		else
			if lib.MetaStatus then
				local curV = statusClass.Values.CurValue;
				local maxV = statusClass.Values.MaxValue;

				if curV <= 0 then
					alpha = 1;
				else
					alpha = math.clamp((curV/maxV), 0, 1);
				end
			end
		end
		alpha = math.clamp(alpha, 0, 1);
		
		local radialBar = statusGuiObj.Button:WaitForChild("radialBar");
		if lib.MetaStatus then
			local curV = statusClass.Values.CurValue;
			if curV <= 0 then
				radialBar.ImageColor3 = DEBUFF_COLOR;
			else
				radialBar.ImageColor3 = NEUTRAL_COLOR;
			end
		else
			radialBar.ImageColor3 = lib.Buff and BUFF_COLOR or DEBUFF_COLOR;
		end
		
		local statusVisible = true;
		
		if statusClass.Visible == false then
			statusVisible = false;
		end
		
		if isInCharWindow then
			statusGuiObj.Button.Size = UDim2.new(0, 90, 0, 90);

		else
			statusGuiObj.Button.Size = UDim2.new(0, 40, 0, 40);

			if lib.HudVisibleBelow then
				if lib.MetaStatus then
					local curV = statusClass.Values.CurValue;
					if curV <= lib.HudVisibleBelow then
						statusVisible = true;
					else
						statusVisible = false;
					end
				end
			end

			if statusClass.Values.LastSet and lastOsTime-statusClass.Values.LastSet <= 3 then
				statusVisible = true;
			end
		end

		local previousVisible = statusGuiObj.Button.Visible;
		if previousVisible ~= statusVisible then
			statusGuiObj.Button.Visible = statusVisible;
			TweenService:Create(statusGuiObj.AlphaValue, POPIN_TWEENINFO, {Value = alpha}):Play();
		else
			TweenService:Create(statusGuiObj.AlphaValue, POPIN_TWEENINFO, {Value = alpha}):Play();
		end
		
		if lib.QuantityLabel then
			local stat = statusClass[lib.QuantityLabel];
			local str = stat;
			local v = tonumber(stat);
			
			if tonumber(stat) then
				local statStr = tostring(stat);
				if #statStr >= 7 then
					str=(math.round(v/100000)/10).."M";
				elseif #statStr >= 4 then
					str=(math.round(v/100)/10).."K";
				else
					str=math.round(v);
				end
			end
			statusGuiObj.Quan.Text = str or "";
		end
		
		local descStr = lib.Description;
		if descStr then
			if statusClass.Duration and statusClass.Expires then
				local timeRatio = (statusClass.Expires-smoothTime)/statusClass.Duration;
				descStr = descStr.. " ("..modSyncTime.ToString(timeRatio * statusClass.Duration)..")";
				
			end
			
			for k, v in pairs(statusClass.Values) do
				if typeof(v) ~= "string" and typeof(v) ~= "number" then continue end;
				
				if lib.DescProcess and lib.DescProcess[k] then
					v = lib.DescProcess[k](v);
				end
				descStr = descStr:gsub("$"..k, v);
			end
			
			statusGuiObj.Info.Text = descStr;
		end
	end

	--MARK: OnUpdate
	statusEffectsWindow.OnUpdate:Connect(function()
		local newTime = workspace:GetServerTimeNow();
		if lastOsTime ~= newTime then
			lastOsTime = newTime;
			lastTick = tick();
		end
		smoothTime = lastOsTime+tick()-lastTick;
		
		local toDestroyList = {};
		for id, _ in pairs(statusGuiObjList) do
			toDestroyList[id] = true;
		end
		
		for statusId, statusClass: StatusClassInstance in pairs(statusComp.List) do
			local lib = modStatusLibrary:Find(statusClass.Id or statusId);
			if lib == nil then continue end;

			local showStatus = lib.ShowOnHud ~= false or localPlayer:GetAttribute("ShowHiddenStatus") == true;
			if showStatus ~= true then continue end;
			toDestroyList[statusId] = false;

			updateStatusObj(lib, statusId, statusClass);
		end

		for id, shouldDestroy in pairs(toDestroyList) do
			if shouldDestroy and statusGuiObjList[id] then
				if statusGuiObjList[id].Button then statusGuiObjList[id].Button:Destroy() end;
				statusGuiObjList[id] = nil;
			end
		end
	end)

	interface.Scheduler.OnStepped:Connect(function(tickData: TickData)
		statusEffectsWindow:Update();
	end)

end

return interfacePackage;

