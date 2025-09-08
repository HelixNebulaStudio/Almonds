local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");

local camera = workspace.CurrentCamera;
local localPlayer = game.Players.LocalPlayer;

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modFuelsLibrary = shared.require(game.ReplicatedStorage.Library.FuelsLibrary);
local modCookLibrary = shared.require(game.ReplicatedStorage.Library.CookLibrary);
local modGarbageHandler = shared.require(game.ReplicatedStorage.Library.GarbageHandler);

local modColorPicker = shared.require(game.ReplicatedStorage.Library.UI.ColorPicker);

local MIX_TWEENINFO = TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1);
local BURN_COLOR0 = Color3.fromRGB(200, 20, 20);
local BURN_COLOR1 = Color3.fromRGB(100, 20, 20);

local interfacePackage = {
    Type = "Character";
    LoadOrder = 1000;
};
--==


function interfacePackage.newInstance(interface: InterfaceInstance)
    local modData = shared.require(localPlayer:WaitForChild("DataModule"));

	local remoteStorageService = modRemotesManager:Get("StorageService");
    
    local furnaceFrame = script:WaitForChild("FurnaceFrame"):Clone();

	local fireIcon1 = furnaceFrame:WaitForChild("FireIcon1");
	local fire1Gradient = fireIcon1:WaitForChild("UIGradient");
	
	local fireIcon2 = furnaceFrame:WaitForChild("FireIcon2");
	local fire2Gradient = fireIcon2:WaitForChild("UIGradient");
	
	local mixIcon = furnaceFrame:WaitForChild("MixIcon");
	local mixTween: Tween = TweenService:Create(mixIcon, MIX_TWEENINFO, {Rotation=359});

	local igniteToggleButton = furnaceFrame:WaitForChild("IgniteToggle");

    local window: InterfaceWindow = interface:NewWindow("FurnaceWindow", furnaceFrame);
    window.IgnoreHideAll = true;
    window.UseTween = false;
    window.DisableInteractables = true;
    window.CloseWithInteract = true;

    local externalStorageWindow: InterfaceWindow = interface:GetWindow("ExternalStorage");
    furnaceFrame.Visible = false;
    furnaceFrame.Parent = externalStorageWindow.Frame;

    local furnaceEvents = modGarbageHandler.new();
    interface.Garbage:Tag(furnaceEvents);

    --MARK: OnToggle
    window.OnToggle:Connect(function(visible, interactable)
        if visible then
            local furnaceStorageId = interactable.Values.StorageId;
            Debugger:Warn(`furnaceStorageId`, furnaceStorageId);

            furnaceEvents:Destruct();
            furnaceFrame.Visible = true;

            furnaceEvents:Tag(modData.OnStorageUpdate:Connect(function(storage)
                local storageId = storage.Id;
                if storageId == furnaceStorageId then
                    window:Update();
                end
            end))
            window:Update();

        else
            furnaceFrame.Visible = false;
            furnaceEvents:Destruct();
            
        end
    end)
    externalStorageWindow.OnToggle:Connect(function(visible)
        if not visible then
            window:Close();
        end
    end)

    --MARK: OnUpdate
	window.OnUpdate:Connect(function()
        local storageInterface = externalStorageWindow.Binds.ActiveStorageInterface;
        if not storageInterface then return end;

        local currTime = workspace:GetServerTimeNow();

        local storage = modData.GetStorage(storageInterface.StorageId);
        local storageValues = storage.Values;

        local activeFuel = storageValues.ActiveFuel or {};
		local fuelLib = activeFuel.FuelId and modFuelsLibrary:Find(activeFuel.FuelId);
		
		local activeTime = activeFuel.Active and (activeFuel.Active - currTime) or 0;
		
		if activeFuel.Tick and fuelLib then
			local alpha = (currTime - activeFuel.Tick) / fuelLib.BurnTime;
			fire1Gradient.Color = modColorPicker.GradientLerp(BURN_COLOR0, BURN_COLOR1, alpha);
		else
			if fuelLib and activeTime > 0 then
				local alpha = activeTime / (fuelLib.BurnTime*2);
				fire1Gradient.Color = modColorPicker.GradientLerp(BURN_COLOR0, BURN_COLOR1, alpha);
				
			elseif fuelLib and activeFuel.ID then
				fire1Gradient.Color = ColorSequence.new(BURN_COLOR1);
				
			else
				fire1Gradient.Color = ColorSequence.new(Color3.fromRGB(20, 20, 20));
			end
		end
		
		
		local activeCook = storageValues.ActiveCook or {};
		local cookLib = activeCook.CookId and modCookLibrary:Find(activeCook.CookId);
		if cookLib and activeTime > 0 then
			if activeCook.Tick then
				local alpha = (currTime - activeCook.Tick) / cookLib.CookTime;
				fire2Gradient.Color = modColorPicker.GradientLerp(BURN_COLOR0, BURN_COLOR1, alpha);
				
			else
				fire2Gradient.Color = ColorSequence.new(BURN_COLOR1);
				
			end
			
		else
			if cookLib and activeFuel.Tick then
				fire2Gradient.Color = ColorSequence.new(BURN_COLOR1);
			else
				fire2Gradient.Color = ColorSequence.new(Color3.fromRGB(20, 20, 20));
			end
			
		end

		if activeCook.Mix == 2 and activeTime > 0 then
			mixIcon.ImageColor3 = Color3.fromRGB(84, 130, 185);
			if mixTween.PlaybackState ~= Enum.PlaybackState.Playing then
				mixTween:Play();
			end

		elseif activeCook.Mix == 1 then
			mixIcon.ImageColor3 = Color3.fromRGB(84, 130, 185);
			if mixTween.PlaybackState == Enum.PlaybackState.Playing then
				mixTween:Cancel();
			end

		else
			mixIcon.ImageColor3 = Color3.fromRGB(20, 20, 20);
			if mixTween.PlaybackState == Enum.PlaybackState.Playing then
				mixTween:Cancel();
			end

		end

		if storageValues.Ignited == true then
			igniteToggleButton.Text = "Extinguish";
			igniteToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 100);
		else
			igniteToggleButton.Text = "Ignite";
			igniteToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50);
		end
    end)

    interface.Scheduler.OnStepped:Connect(function()
        if window.Visible ~= true then return end;
        window:Update();
    end)

	local toggleDebounce = false;
	igniteToggleButton.MouseButton1Click:Connect(function()
        local storageInterface = externalStorageWindow.Binds.ActiveStorageInterface;
        if not storageInterface then return end;

		if toggleDebounce then return end;
		toggleDebounce = true;

		interface:PlayButtonClick();

		if igniteToggleButton.Text == "Ignite" then
			igniteToggleButton.Text = "Igniting..";
		else
			igniteToggleButton.Text = "Extinguishing..";
		end

		local storageId = storageInterface.StorageId;

		local rPacket = remoteStorageService:InvokeServer{
			Action = "toggleignite";
			StorageId = storageId;
		};
		
		if rPacket.Success then
			local newStorageValues = rPacket.Values;

			local storage = modData.GetStorage(storageId);
			storage.Values.Ignited = newStorageValues.Ignited;

			window:Update();
		end

		toggleDebounce = false;
	end)

end

return interfacePackage;

