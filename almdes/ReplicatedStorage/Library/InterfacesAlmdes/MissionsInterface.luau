local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");

local camera = workspace.CurrentCamera;
local localPlayer = game.Players.LocalPlayer;

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modKeyBindsHandler = shared.require(game.ReplicatedStorage.Library.KeyBindsHandler);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modMissionLibrary = shared.require(game.ReplicatedStorage.Library.MissionLibraryAlmdes);

local interfacePackage = {
    Type = "Player";
};
--==


function interfacePackage.newInstance(interface: InterfaceInstance)
    local modData = shared.require(localPlayer:WaitForChild("DataModule"));

    local remoteMissionRemote = modRemotesManager:Get("MissionRemote");

    local isDev = shared.gameConfig.BranchName == "Dev";

	local windowFrame = script:WaitForChild("MissionsWindow"):Clone();
	windowFrame.Parent = interface.ScreenGui;
    
    --MARK: Window
	local window: InterfaceWindow = interface:NewWindow("Missions", windowFrame);
    window.IgnoreHideAll = true;
	window.DisableInteractables = true;
    window.CloseWithInteract = true;
    window.UseTween = false;
	
	local keyId = "KeyWindowMissions";
	modKeyBindsHandler:SetDefaultKey(keyId, Enum.KeyCode.B);
	local quickButton = interface:NewQuickButton("Missions", "Missions", "rbxassetid://2273398923");
	local amtLabel = quickButton:WaitForChild("AmtFrame"):WaitForChild("AmtLabel");
	quickButton.LayoutOrder = 3;
	interface:ConnectQuickButton(quickButton, keyId);

    local contentFrame = windowFrame:WaitForChild("Content");
    local contentUiCorner = contentFrame:WaitForChild("UICorner");

    interface.OnWindowToggle:Connect(function(otherWindow: InterfaceWindow, otherVisible: boolean)
        if otherWindow.Name == "CharacterWindow" and otherVisible == false then 
            window:Close();
        end
    end)

    --MARK: OnToggle
    window.OnToggle:Connect(function(visible)
        local mainMenuWindow = interface:GetWindow("MainMenu");
        local charWindow = interface:GetWindow("CharacterWindow");

        if visible then
            if charWindow then
                local rPanel = charWindow.Binds.RPanel;
                windowFrame.Parent = rPanel;
                contentUiCorner.CornerRadius = UDim.new(0, 5);
                contentFrame.Position = UDim2.new(1, 0, 1, -70);
                contentFrame.Size = UDim2.new(1, 0, 1, -140);
                contentFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20);
                contentFrame.BackgroundTransparency = 0.5;
                TweenService:Create(contentFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Position = UDim2.new(0.5, 0, 1, -70);
                }):Play();
                interface:ToggleWindow("Inventory", true);

            else
                windowFrame.Parent = interface.ScreenGui;
                contentUiCorner.CornerRadius = UDim.new(0, 0);
                contentFrame.Position = UDim2.new(0.5, 0, 0.9, -20);
                contentFrame.Size = UDim2.new(0.6, 0, 0.8, -20);
                contentFrame.BackgroundColor3 = Color3.fromRGB(35, 24, 40);
                contentFrame.BackgroundTransparency = 0.1;
                interface:HideAll{[window.Name]=true;};

            end
            
            windowFrame.Visible = true;
            window:Update(true);
            window.Binds.UpdateMissionHudTasks();

        else
            interface:ToggleWindow("Inventory", false);
            windowFrame.Visible = false;

            if mainMenuWindow and mainMenuWindow.Visible then
                mainMenuWindow:Update();
            end
        end
    end)

    local function formatTaskLabel(mission, taskStr)
        if mission.SaveData == nil then return taskStr; end;

        for k, v in pairs(mission.SaveData) do
            if taskStr:find(`${k}`) == nil then continue end;
            local newVal = v;
            
            if tonumber(newVal) then
                newVal = interface.beautifyNumber(tonumber(newVal) :: number);
            end
            
            taskStr = taskStr:gsub(`${k}`, newVal);
        end
        
        return taskStr;
    end

    --MARK: Mission HudTask
    function window.Binds.UpdateMissionHudTasks()
        local activeMissionsList = {};

        local missionsList = modData:GetMissionsList();
        for a=1, #missionsList do
            local mission: Mission = missionsList[a];

            if mission.Type == 1 then
                table.insert(activeMissionsList, mission);
            end
        end
        table.sort(activeMissionsList, function(a, b) return a.Id < a.Id; end);
        
		local taskHudWindow: InterfaceWindow = interface:GetWindow("TaskListHud");
        if taskHudWindow == nil then return end;

        Debugger:Log("activeMissionsList", activeMissionsList);

        for a=1, 3 do
            local HUD_TASK_ID = `ACTIVE_MISSION_{a}`;        
            local mission: Mission = activeMissionsList[a];
            
            if mission == nil then            
                local missionHudTask = taskHudWindow.Binds.getOrNewTask(HUD_TASK_ID);

                if missionHudTask then
                    taskHudWindow.Binds.destroyHudTask(HUD_TASK_ID);
                end

                continue;
            end

            local missionLib = mission.Library;
            local missionHudTask = taskHudWindow.Binds.getOrNewTask(HUD_TASK_ID, true);
            local missionPoint = mission.ProgressionPoint;

            missionHudTask.Properties.TitleText = "";
            missionHudTask.Properties.HeaderText = missionLib.Name;

            local checkpointInfo = missionLib.Checkpoint[missionPoint];

            local taskStr = `{isDev and `[{missionPoint}] ` or ``}{checkpointInfo.Text}`;
            taskStr = formatTaskLabel(mission, taskStr);
            missionHudTask.Properties.DescText = taskStr;
        end
    end


    --MARK: Mission update signal
    interface:BindEvent("syncmission", function(mission)
        window.Binds.UpdateMissionHudTasks();
    end)

end

return interfacePackage;

