local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local UserInputService = game:GetService("UserInputService");
local TweenService = game:GetService("TweenService");

local camera = workspace.CurrentCamera;

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManagerAlmdes);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);
local modSyncTime = shared.require(game.ReplicatedStorage.Library.SyncTime);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

local FRAME_TWEENINFO = TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut);

local STAT_KEYS = {
    {Key="NpcKills", Name="Npc Kills"};
    {Key="PlayerKills", Name="Player Kills"};
    {Key="ContractsCompleted", Name="Contracts Completed"};
    {Key="MissionsCompleted", Name="Missions Completed"};
    {Key="StorageOpened", Name="Crates Opened"};
};

local interfacePackage = {
    Name = script.Name;
    Type = "Player";
};
--==


function interfacePackage.newInstance(interface: InterfaceInstance)
    local remoteMainMenuRemote = modRemotesManager:Get("MainMenuRemote");

    local gameEndWindow: InterfaceWindow;

    --MARK: DeathScreen
    local uiElement: InterfaceElement = interface:GetOrDefaultElement("DeathScreenElement");
    uiElement._visible = false;
    uiElement.BoolStringWhenActive = {String="!CharacterHud"; Priority=6;};

    local deathFrame = script:WaitForChild("AlmdesDeath"):Clone();
    deathFrame.Parent = uiElement.Frame;

    uiElement.OnChanged:Connect(function(k, v, ov)
        if k == "Visible" then
            deathFrame.Visible = v;
        end
    end)
    
    local buttonsFrame = deathFrame:WaitForChild("Buttons");
    
    local helpButton = buttonsFrame:WaitForChild("HelpButton");
    local endButton = buttonsFrame:WaitForChild("EndButton");
    
    endButton.MouseButton1Click:Connect(function()
        interface:PlayButtonClick();

        local timeLeft = math.round(workspace:GetAttribute("StormCycleTick") - workspace:GetServerTimeNow());
        modClientGuis.promptDialogBox({
            Title=`Are you sure you want to end this run?`;
            Desc=`You can not respawn for <b>{timeLeft} seconds</b>, you should call for help instead.`;
            Buttons={
                {
                    Text="End";
                    Style="Confirm";
                    OnPrimaryClick=function(dialogWindow)
                        buttonsFrame.Visible = false;
                        local rPacket = remoteMainMenuRemote:InvokeServer("endrun");
                        if rPacket.Success then
                            gameEndWindow.Binds.RunSummary = rPacket.RunSummary;
                            interface:ToggleWindow("GameEndWindow", true);
                        end
                    end;
                };
                {
                    Text="Cancel";
                    Style="Cancel";
                };
            }
        });
    end)

    helpButton.MouseButton1Click:Connect(function()
        interface:PlayButtonClick();
        Debugger:Warn("Help button clicked");
        local rPacket = remoteMainMenuRemote:InvokeServer("rescuerequest");
    end)




    --MARK: EndMenu
    local gameEndFrame = script:WaitForChild("GameEndMenu"):Clone();
    gameEndFrame.Parent = interface.ScreenGui;
    gameEndWindow = interface:NewWindow("GameEndWindow", gameEndFrame);
    gameEndWindow.IgnoreHideAll = true;
	gameEndWindow.UseTween = false;
	gameEndWindow.UseMenuBlur = true;
    gameEndWindow.DisableInteractables = true;
    gameEndWindow.DisableHotKeysHint = true;
    gameEndWindow.BoolStringWhenActive = {String="EndScreen"; Priority=5;};
    gameEndWindow.Layers = {"EndScreen"};
    gameEndWindow:SetClosePosition(gameEndFrame.Position, gameEndFrame.Position);

    local binds = gameEndWindow.Binds;
    binds.Page = "Summary";

    local navBarContent = gameEndFrame:WaitForChild("NavBar"):WaitForChild("Content");

    local function setPage(pageName: string)
        binds.Page = pageName;
        gameEndWindow:Update();
    end

    local function backToMenuClick()
        interface:PlayButtonClick();
        interface:ToggleGameBlinds(false, 3);
        local rPacket = remoteMainMenuRemote:InvokeServer("returnmenu");
        if rPacket.Success then
            modClientGuis.reload();
        end
    end

    for _, button in pairs(navBarContent:GetChildren()) do
        if not button:IsA("GuiObject") then continue end;

        if button.Name == "BackToMenu" then
            button.MouseButton1Click:Connect(backToMenuClick);
            continue;
        end

        local pageFrame = gameEndFrame:WaitForChild(button.Name);
        if pageFrame == nil then continue end;
        pageFrame.Visible = false;

        button.MouseButton1Click:Connect(function()
            interface:PlayButtonClick();
            setPage(button.Name);
        end);
    end

    --MARK: OnToggle
    gameEndWindow.OnToggle:Connect(function(visible)
        if visible then
            buttonsFrame.Visible = false;
            gameEndFrame.Visible = true;
            gameEndWindow._visible = true;
            gameEndFrame.BackgroundTransparency = 1;
            TweenService:Create(gameEndFrame, FRAME_TWEENINFO, {
                BackgroundTransparency = 0.75;
            }):Play();
            
        else
            local tween: Tween = TweenService:Create(gameEndFrame, FRAME_TWEENINFO, {
                BackgroundTransparency = 1;
            });
            tween.Completed:Once(function(status)
                if status ~= Enum.PlaybackState.Completed then return end;
                buttonsFrame.Visible = true;
            end)
            gameEndWindow._visible = false;
            gameEndFrame.Visible = false;
            interface:HideAll();
            tween:Play();
        end

        if not visible then return end;
        gameEndWindow:Update();
    end)

    --MARK: OnUpdate
    gameEndWindow.OnUpdate:Connect(function()
        Debugger:Warn(`OnUpdate {binds.Page}`);

        local pageFrame = gameEndFrame:WaitForChild(binds.Page);
        if binds.Page == "Summary" then
            local runSummary = binds.RunSummary;

            local titleLabel = pageFrame:WaitForChild("TitleLabel");
            local notesFrame = pageFrame:WaitForChild("notes");
            local noteLabel = notesFrame:WaitForChild("textLabel");

            Debugger:Log(`runSummary:`, runSummary);
            local firstLoad = false;
            if pageFrame.Visible == false then
                pageFrame.Visible = true;
                notesFrame.Visible = false;
                titleLabel.TextTransparency = 1;
                TweenService:Create(titleLabel, TweenInfo.new(1), {
                    TextTransparency = 0;
                }):Play();
                task.wait(1);
                notesFrame.Visible = true;
                firstLoad = true;
            end

            local runTimelapse = runSummary.EndTime - runSummary.StartTime;
            local runTimeStr = modSyncTime.ToString(runTimelapse);

            local notes = {};

            if runSummary.Status == "Success" then
                table.insert(notes, `<font size="24" color="#{Color3.fromHex("#54c968"):ToHex()}"><b>Success</b></font>`);
            else
                table.insert(notes, `<font size="24" color="#{Color3.fromHex("#c05c5c"):ToHex()}"><b>Failed</b></font>`);
            end
            if runSummary.EndReason == "HeliExfil" then
                table.insert(notes, "You have been extracted by helicopter.");
            elseif runSummary.EndReason == "Died" then
                table.insert(notes, "You have died.");
            end
            table.insert(notes, `You have survived for {runTimeStr}.\n`);

            for a=1, #STAT_KEYS do
                local k = STAT_KEYS[a].Key;
                local v = runSummary.Stats[k];
                if v == nil then continue end;

                local name = STAT_KEYS[a].Name;
                table.insert(notes, `{name}: {v}`);
            end

            if firstLoad then
                task.spawn(function()
                    for a=1, #notes do
                        task.wait(0.4);
                        modAudio.Play("WritingShort").PlaybackSpeed = math.random(90, 110)/100;
                        task.wait(0.1);
                        noteLabel.Text = table.concat(notes, "\n", 1, a);
                    end
                end)
            else
                noteLabel.Text = table.concat(notes, "\n");
            end
        end
    end)

end

return interfacePackage;

