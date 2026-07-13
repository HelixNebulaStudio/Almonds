local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");
local HttpService = game:GetService("HttpService");
local TweenService = game:GetService("TweenService");

local camera = workspace.CurrentCamera;
local localPlayer = game.Players.LocalPlayer;

local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurationsAlmdes);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modCameraGraphics = shared.require(game.ReplicatedStorage.PlayerScripts.CameraGraphics);
local modClientLighting = shared.require(game.ReplicatedStorage.PlayerScripts.ClientLighting);
local modKeyBindsHandler = shared.require(game.ReplicatedStorage.Library.KeyBindsHandler);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibraryAlmdes);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local modTimeDownUI = shared.require(game.ReplicatedStorage.Library.UI.TimeDownUI);
local modItemInterface = shared.require(game.ReplicatedStorage.Library.UI.ItemInterface);
local modScreenRelativeTextSize = shared.require(game.ReplicatedStorage.Library.UI.ScreenRelativeTextSize);

local BASIC_TWEENINFO = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut);
local QUEUE_PROCESS_FREQ = 60;

local interfacePackage = {
    Type = "Player";
};
--==

function interfacePackage.newInstance(interface: InterfaceInstance)
    local curPage = "Root";
    local activePlayPage = "OptionsFrame";

    local templateItemSlot = interface.newTemplate("ItemSlot");

    local modData = shared.require(localPlayer:WaitForChild("DataModule"));

    local remoteMainMenu = modRemotesManager:Get("MainMenuRemote");
    local remoteLoadoutSaves = modRemotesManager:Get("LoadoutSaves");

    local frame = script:WaitForChild("MainMenuFrame"):Clone();
    frame.Parent = interface.ScreenGui;
    local bodyFrame = frame:WaitForChild("PageBody");

    local menuMusic: Sound = frame:WaitForChild("MenuMusic");

    local window: InterfaceWindow = interface:NewWindow("MainMenu", frame);
    window.BoolStringWhenActive = {String="!CharacterHud"; Priority=2;};
    window.IgnoreHideAll = true;
    window.UseMenuBlur = true;
    window.UseTween = false;
    window.DisableHotKeysHint = true;

    local binds = window.Binds;

    local navBar = frame:WaitForChild("NavBar")
    local navBarContent = navBar:WaitForChild("Content");
    local hudFrame;

    if modConfigurations.SafehomeMode then
        hudFrame = script:WaitForChild("MenuHudFrame"):Clone();
        hudFrame.Parent = interface.ScreenGui;

        if modConfigurations.CompactInterface then
            hudFrame.AnchorPoint = Vector2.new(0, 0);
            hudFrame.Position = UDim2.new(0, 10, 0, interface.Properties.TopbarInset.Height+25);
        end

        local keyId = `KeyWindow{window.Name}`;
        modKeyBindsHandler:SetDefaultKey(keyId, Enum.KeyCode.Tab);
        
        local codexQuickButton = interface:NewQuickButton(window.Name, "MainMenu", "rbxassetid://121177091124921");
        codexQuickButton.LayoutOrder = 0;
        interface:ConnectQuickButton(codexQuickButton, keyId);

        hudFrame.Visible = true;
    end

    local navButtonCooldown = tick();

    --MARK: OnToggle
    window.OnToggle:Connect(function(visible)
        if visible then
            curPage = "Root";
            frame.Position = UDim2.new(0,0,0,0);

            if localPlayer.Character == nil then
                game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false);
                
                modCameraGraphics:Bind("menucamera", {
                    RenderStepped=function(camera, delta, totalDelta)
                        local focusPart = localPlayer.ReplicationFocus;
                        if focusPart == nil then return end;
                        
                        local origin = focusPart.CFrame;
                        camera.Focus = origin * CFrame.Angles(0, math.rad(totalDelta)*2, 0)
                            * CFrame.Angles(math.rad(-20), 0, 0)
                        camera.CFrame = camera.Focus * CFrame.new(0, 40, 0);
                           
                    end;
                }, 2);

                modClientLighting:SetAtmosphere("Menu");

                if menuMusic.IsPlaying == false then
                    menuMusic.Volume = 0.5;
                    menuMusic:Play();
                end
            end

            interface:HideAll();
            window:Update();
            frame.Visible = true;
            hudFrame.Visible = false;

        else

            hudFrame.Visible = true;
            interface:ToggleWindow("UpdateWindow", false);
            modClientLighting:SetAtmosphere("Spawn");

            modCameraGraphics:Unbind("menucamera");
            frame.Visible = false;
            if menuMusic.IsPlaying then
                local musicTween: Tween = TweenService:Create(menuMusic, TweenInfo.new(10), {Volume=0;});
                musicTween.Completed:Once(function()
                    menuMusic:Stop();
                end)
                musicTween:Play();
            end

        end
    end)

    interface.Garbage:Tag(function()
        modClientLighting:SetAtmosphere("Spawn");
        modCameraGraphics:Unbind("menucamera");
        menuMusic:Stop();
        game.Debris:AddItem(menuMusic, 0);
    end)

    local menuButton = navBar:WaitForChild("MenuButton");
    local function menuButtonOnClick()
        if tick()-navButtonCooldown <= 0.1 then return end;
        navButtonCooldown = tick();
        interface:PlayButtonClick();

        curPage = "Root";
        window:Update();
    end
    menuButton.MouseButton1Click:Connect(menuButtonOnClick);

    local menuButtonImage = menuButton:WaitForChild("ButtonIcon");
    local menuButtonTitle = menuButton:WaitForChild("GameTitle");
    local function toggleMenuButtonMouseEvent(isOn)
        local objects = {menuButtonImage, menuButtonTitle};
        for a=1, #objects do
            local guiObj = objects[a];
            if not guiObj:IsA("GuiObject") then continue end;

            if guiObj:IsA("ImageLabel") then
                TweenService:Create(guiObj, BASIC_TWEENINFO, {
                    Size = isOn and UDim2.new(1.3, 0, 1.3, 0) or UDim2.new(1.2, 0, 1.2, 0);
                    ImageColor3 = isOn and interface.Colors.Branch or Color3.fromRGB(255, 255, 255);
                }):Play();

            elseif guiObj:IsA("TextLabel") then
                TweenService:Create(guiObj, BASIC_TWEENINFO, {
                    Size = isOn and UDim2.new(0, 0, 1.1, 0) or UDim2.new(0, 0, 1, 0);
                    TextColor3 = isOn and interface.Colors.Branch or Color3.fromRGB(255, 255, 255);
                }):Play();

            end
        end
    end
    menuButton:GetPropertyChangedSignal("GuiState"):Connect(function()
        if menuButton.GuiState == Enum.GuiState.Hover then
            toggleMenuButtonMouseEvent(true);
        else
            toggleMenuButtonMouseEvent(false);
        end
    end)

    local playButton = navBar:WaitForChild("Content"):WaitForChild("PlayPage");
    local playLoading = playButton:WaitForChild("LoadingImage");

    local PAGES = {
        ["QueuePage"] = {
            _loaded = false;

            Frame = bodyFrame.QueuePage;
            Button = nil;

            -- @functions
            Load = nil;
            Update = nil;
        };
        ["PlayPage"] = {
            _loaded = false;

            Frame = bodyFrame.PlayPage;
            Button = playButton;

            -- @functions
            Load = nil;
            Update = nil;
        };
        ["LoadoutsPage"] = {
            _loaded = false;

            Frame = bodyFrame.LoadoutsPage;
            Button = nil;

            -- @functions
            Load = nil;
            Update = nil;
        };
    };

    local function updatePages()
        local queueState = modData.QueueState;
        if queueState ~= nil then
            playButton.Text = "Unqueue";

        else
            playButton.Text = "Play";

        end

        if queueState and curPage == "PlayPage" then
            curPage = "QueuePage";
        end
        for pageId, pageContent in pairs(PAGES) do
            if pageId == curPage then
                if pageContent.Load then
                    pageContent.Load();
                end

                local pageFrame: Frame = pageContent.Frame;
                if pageFrame.Visible == false then
                    pageFrame.Position = UDim2.new(0.5, 0, -1, 0);
                    pageFrame.Visible = true;
                    local tween = TweenService:Create(pageFrame, BASIC_TWEENINFO, {
                        Position = UDim2.new(0.5, 0, 0, 0);
                    });
                    tween:Play();
                end

                if pageContent.Update then
                    pageContent.Update();
                end

            else
                pageContent.Frame.Visible = false;

            end
        end
    end

    local navButtons = navBarContent:GetChildren();
    for a=1, #navButtons do
        local button = navButtons[a];
        if not button:IsA("GuiObject") then continue end;

        button.MouseButton1Click:Connect(function()
            if tick()-navButtonCooldown <= 0.1 then return end;
            navButtonCooldown = tick();
            interface:PlayButtonClick();

            curPage = button.Name;
            window:Update();
        end)

        if button:FindFirstChild("SelectedHighlight") then
            local selectedHighlight = button.SelectedHighlight;

            button:GetPropertyChangedSignal("GuiState"):Connect(function()
                if button.GuiState == Enum.GuiState.Hover then
                    selectedHighlight.Visible = true;
                else
                    selectedHighlight.Visible = false;
                end
            end)
        end
        if PAGES[button.Name] then
            PAGES[button.Name].Button = button;
        end
    end

    --MARK: OnUpdate
    window.OnUpdate:Connect(function()
        if window.Visible then
            menuButtonTitle.Visible = interface.ActiveScale > 0.8;
            interface.VersionLabel.ZIndex = 2;

        else
            interface.VersionLabel.ZIndex = 0;
            interface:ToggleWindow("UpdateWindow", false);
            interface:ToggleWindow("CodexWindow", false);

            return;
        end

        local menuEqualizer = menuMusic:FindFirstChild("EqualizerSoundEffect") :: EqualizerSoundEffect;
        menuEqualizer.Enabled = curPage == "Root";

        if curPage == "Root" then
            interface:ToggleWindow("UpdateWindow", true);
            interface:ToggleWindow("CodexWindow", false);
        else
            interface:ToggleWindow("UpdateWindow", false);
            interface:ToggleWindow("CodexWindow", false);
        end

        updatePages();
    end)

    local function onTopBarInsetChanged(k, v, ov)
        if k ~= "TopBarInset" then return end;

        local padding = 15;
        if interface.ActiveScale <= 0.5 then
            padding = 0;
        end

        navBar.Size = UDim2.new(1.4, 0, 0, interface.Properties.TopbarInset.Height+padding);
        bodyFrame.Size = UDim2.new(1, 0, 1, -interface.Properties.TopbarInset.Height-padding);

        if hudFrame then
            hudFrame.Size = UDim2.new(1, 0, 1, -interface.Properties.TopbarInset.Height-padding);
        end
    end
    interface.Properties.OnChanged:Connect(onTopBarInsetChanged)
    onTopBarInsetChanged("TopBarInset");



    --MARK: Queue Page
    PAGES.QueuePage.Load = function()
        if PAGES.QueuePage._loaded then return end;
        PAGES.QueuePage._loaded = true;
    end
    PAGES.QueuePage.Update = function()
        local queueState = modData.QueueState;

        Debugger:Warn("Queue state", queueState);

        local queuePageFrame = PAGES.QueuePage.Frame;
        local queueInfoDialog = queuePageFrame.QueueInfo;
        local queueLabel = queueInfoDialog.QueueLabel;

        local queueTimeDown = window.Binds.QueueTimeDown or modTimeDownUI.new();
        window.Binds.QueueTimeDown = queueTimeDown;

        if queueState == nil then
            queueTimeDown.Frame.Visible = false;
            queueLabel.Text = `You are not in a queue.`;

            return; 
        end

        queueTimeDown.Frame.Visible = true;
        queueTimeDown.Frame.Parent = interface.ScreenGui;
        queueTimeDown.Frame.AnchorPoint = Vector2.new(0.5, 0);
        queueTimeDown.Frame.Position = UDim2.new(0.5, 0, 0, interface.Properties.TopbarInset.Height + 30);
        queueTimeDown.Frame.Size = UDim2.new(0.1, 0, 0.1, 0);

        local ftFrame = queueTimeDown.Frame.FtFrame;
        ftFrame.BackgroundColor3 = interface.Colors.ActivePrimary;

        local nextQueueProccessTick = queueState.JoinTimestamp + (queueState.Values.LocalSearchTimeLimit or 30);
        if queueState.GlobalEnteredAt then
            nextQueueProccessTick = queueState.GlobalEnteredAt;
        end
        nextQueueProccessTick = math.ceil(nextQueueProccessTick / QUEUE_PROCESS_FREQ) * QUEUE_PROCESS_FREQ;
        nextQueueProccessTick += 7;

        local changeStr = nil;
        if queueState.CIndex == 1 then
            changeStr = `Queued into nearby queue..`;
        elseif queueState.CIndex == 2 then
            changeStr = `Requeued into global queue..`;
        end
        queueState.CIndex = nil;

        queueTimeDown.BindOnTick = function(self, timeLeft)
            if timeLeft > 10 then return end;
            queueTimeDown.Frame.Size = UDim2.new(0.15, 0, 0.15, 0);
        end;
        queueTimeDown:Set{
            EndTime = nextQueueProccessTick;
            Text = changeStr;
        };


        local queueTypes = {
            Default = "Quick Play";
        };
        queueLabel.Text = `Queueing {
            queueState.Queue == "LOCAL" and "nearby" or "global"
        } for {
            queueTypes[queueState.QueueType]
        }`;
    end



    --== MARK: Play Page
    PAGES.PlayPage.Load = function()
        if PAGES.PlayPage._loaded then return end;
        PAGES.PlayPage._loaded = true;

        local isMenuWorld = shared.WorldName == "Genesis";
        local isTutorialFinished = modData:GetEvent("tutorialFinished");

        local playPageFrame = PAGES.PlayPage.Frame;
        
        local PlayPages = {
            Options = playPageFrame:WaitForChild("OptionsFrame");
            ServerBrowser = playPageFrame:WaitForChild("ServerBrowserFrame");
            SpawningFrame = playPageFrame:WaitForChild("SpawningFrame");
        }
        
        local optionsScrollFrame = PlayPages.Options:WaitForChild("OptionsScrollFrame");
        local PlayOptions = {
            Tutorial = optionsScrollFrame:WaitForChild("PlayOptionTutorial");
            Play = optionsScrollFrame:WaitForChild("PlayOptionPlay");
            Servers = optionsScrollFrame:WaitForChild("PlayOptionServers");
            Event = optionsScrollFrame:WaitForChild("PlayOptionEvent");
        };
        
        local selectionName = PlayOptions.Play.Name;
        local selectionHighlight = script:WaitForChild("SelectionHighlight"):Clone();

        local function updateSelectionHighlight()
            for key, optionsButton in pairs(PlayOptions) do
                local isSelected = optionsButton.Name == selectionName;

                local isLocked = optionsButton:GetAttribute("Locked");

                local textLabel: TextLabel = optionsButton.TextLabel;
                if textLabel:GetAttribute("Text") == nil then
                    textLabel:SetAttribute("Text", textLabel.Text);
                end
                textLabel.Text = `{textLabel:GetAttribute("Text")}{isLocked and " (Locked)" or ""}`

                local buttonImage: ImageLabel = optionsButton.ImageLabel;
                if isSelected then
                    if isLocked ~= true then
                        selectionHighlight.Parent = buttonImage;
                    end
                elseif selectionName == nil then
                    selectionHighlight.Parent = nil;
                end

                local descLabel: TextLabel = optionsButton.DescLabel;

                if descLabel:GetAttribute("IsSelected") ~= isSelected then
                    descLabel:SetAttribute("IsSelected", isSelected);

                    TweenService:Create(descLabel, BASIC_TWEENINFO, {
                        TextStrokeTransparency = isSelected and 0.75 or 1;
                        TextTransparency = isSelected and 0 or 1;
                        BackgroundTransparency = isSelected and 0.2 or 1;
                    }):Play();
                end

                if isLocked then
                    buttonImage.ImageColor3 = Color3.fromRGB(100, 50, 50);
                elseif isSelected then
                    buttonImage.ImageColor3 = Color3.fromRGB(255,255,255);
                else
                    buttonImage.ImageColor3 = Color3.fromRGB(200,200,200);
                end
            end
        end

        local templateServerListing = script:WaitForChild("ServerListing");
        local function updateServerBrowser()
            local jsonServersMeta = workspace:GetAttribute("ServersMeta");
            if jsonServersMeta == nil then
                Debugger:Warn("Servers list data unavailable.");
                return;
            end
            
            local serverBrowserScrollFrame = PlayPages.ServerBrowser.ScrollFrame;
            
            local serversMeta = HttpService:JSONDecode(jsonServersMeta);
            local serverTime = workspace:GetServerTimeNow();
            print("serversMeta", serversMeta);
            
            local updatedJobId = {};
            for a=1, #serversMeta.List do
                local serverInfo = serversMeta.List[a];
                if serverInfo.JobId:sub(1,4) == "test" and not RunService:IsStudio() then continue end;
                if (serverTime - serverInfo.LastUpdated) >= 300 then 
                    Debugger:Warn("server JobId(",serverInfo.JobId,") expired.") 
                    continue 
                end;
                
                local newListing = serverBrowserScrollFrame:FindFirstChild(serverInfo.JobId);
                if newListing == nil then
                    newListing = templateServerListing:Clone();
                end
                newListing.Name = serverInfo.JobId;
                newListing.Parent = serverBrowserScrollFrame;
                
                local titleLabel = newListing:WaitForChild("ServerTitle");
                local playersLabel = newListing:WaitForChild("ServerPlayers");
                local pingLabel = newListing:WaitForChild("ServerPing");
                local descLabel = newListing:WaitForChild("ServerDesc");
                
                local worldName = modBranchConfigurations.GetWorldName(serverInfo.PlaceId);
                
                titleLabel.Name = `Official Server #{serverInfo.JobId}`;
                playersLabel.Text = `{#serverInfo.Players} / {serverInfo.MaxPlayers}`;
                pingLabel.Text = serverInfo.RegionCode;
                descLabel.Text = `Official vanilla almonds server. World: {modBranchConfigurations.GetWorldDisplayName(worldName)}`;
                
                updatedJobId[newListing.Name] = true;
            end
            
            for _, obj in pairs(serverBrowserScrollFrame:GetChildren()) do
                if not obj:IsA("TextButton") then continue end;
                if updatedJobId[obj.Name] then continue end;
                
                game.Debris:AddItem(updatedJobId[obj.Name], 0);
            end
            
        end
        workspace:GetAttributeChangedSignal("ServersMeta"):Connect(updateServerBrowser);

        interface.Properties.OnChanged:Connect(function(k, v, ov)
            if k == "TopBarInset" then
                playPageFrame.TitleFrame.Size = UDim2.new(1, 0, 0, interface.Properties.TopbarInset.Height);
            end
        end)

        PAGES.PlayPage.Update = function()
            for _, pageFrame in pairs(PlayPages) do
                pageFrame.Visible = pageFrame.Name == activePlayPage;
            end
            
            if activePlayPage == "SpawningFrame" then

            elseif activePlayPage == "ServerBrowserFrame" then
                playPageFrame.TitleFrame.Title.Text = "SERVERS";
                updateServerBrowser();
                
            else
                playPageFrame.TitleFrame.Title.Text = "PLAY";
            end
        end

        local loadingTween: Tween;
        playLoading:GetPropertyChangedSignal("Visible"):Connect(function()
            if loadingTween then
                loadingTween:Cancel();
            end

            if not playLoading.Visible then return end;

            loadingTween = TweenService:Create(
                playLoading, 
                TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), 
                {
                    Rotation = 360;
                }
            );
            loadingTween:Play();
        end)

        local function deploy(action)
            if remoteMainMenu:Debounce() then return end;

            if action == "playtutorial" 
            or action == "quickplay" then
                playLoading.Visible = true;
                playButton.Text = "";
            end
            local rPacket = remoteMainMenu:InvokeServer(action) or {};
            playLoading.Visible = false;
            
            if rPacket.Success then
                if rPacket.NewState then
                    modData.QueueState = rPacket.NewState;
                    modData.QueueState.CIndex = 1;
                                
                    curPage = "QueuePage";
                    PAGES.QueuePage.Update();
                    window:Update();
                end

            else
                if rPacket.FailMsg then
                    modClientGuis.promptWarning(rPacket.FailMsg or "Please try again!");
                end

                curPage = "Root";
                window:Open();

            end
        end

        for key, optionsButton: TextButton in pairs(PlayOptions) do
            if isMenuWorld and key == "Play" then
                optionsButton:SetAttribute("Locked", true);
            end


            optionsButton:GetPropertyChangedSignal("GuiState"):Connect(function()
                if optionsButton.GuiState == Enum.GuiState.Hover then
                    selectionName = optionsButton.Name;
                    updateSelectionHighlight();
                else
                    selectionName = nil;
                    updateSelectionHighlight();
                end
            end)
            updateSelectionHighlight();


            optionsButton.MouseButton1Click:Connect(function()
                if optionsButton:GetAttribute("Locked") then return end;

                interface:PlayButtonClick();

                if key == "Tutorial" then
                    Debugger:Warn(`Clicked Tutorial`);

                    activePlayPage = "SpawningFrame";
                    PAGES.PlayPage.Update();
                    deploy("playtutorial");
                    
                elseif key == "Play" then
                    Debugger:Warn(`Clicked Quick play`);
                    
                    activePlayPage = "SpawningFrame";
                    PAGES.PlayPage.Update();
                    deploy("quickplay");

                elseif key == "Servers" then
                    Debugger:Warn(`Clicked Server`);
                    activePlayPage = "ServerBrowserFrame";
                    PAGES.PlayPage.Update();
                    
                elseif key == "Event" then
                    Debugger:Warn(`Clicked Event`);
                    
                    
                end
            end)
            
            local descLabel = optionsButton:WaitForChild("DescLabel");
            descLabel.TextSize = modScreenRelativeTextSize.GetTextSize();
        end
    end



    --== MARK: Loadouts Page
    local templateLoadoutSlot = script:WaitForChild("LoadoutSlot");
    PAGES.LoadoutsPage.Load = function()
        if PAGES.LoadoutsPage._loaded then return end;
        PAGES.LoadoutsPage._loaded = true;

        local fetchCooldown = nil;
        local setloadoutDebounce = tick();

        local loadoutsPage: Frame = PAGES.LoadoutsPage.Frame;
        local loadoutsFrame: Frame = loadoutsPage:WaitForChild("LoadoutsFrame") :: Frame;
        local loadoutsScrollFrame: ScrollingFrame = loadoutsFrame:WaitForChild("LoadoutsScrollFrame") :: ScrollingFrame;

        PAGES.LoadoutsPage.Update = function()
            local rawLoadoutSaves = binds.LoadoutSaves;

            if fetchCooldown == nil or tick()-fetchCooldown >= 10 then
                local rPacket = remoteLoadoutSaves:InvokeServer("fetch");
                if rPacket == nil or rPacket.Success == false then return end;

                rawLoadoutSaves = rPacket.Data;
                binds.LoadoutSaves = rawLoadoutSaves;
                fetchCooldown = tick();
            end

            for _, obj in pairs(loadoutsScrollFrame:GetChildren()) do
                if not obj:IsA("GuiObject") then continue end;
                obj:Destroy();
            end

            local activeLoadoutHighlight: UIStroke = script:WaitForChild("SelectionHighlight"):Clone();
            local selectLoadoutHighlight: UIStroke = script:WaitForChild("SelectionHighlight"):Clone();

            local activeLoadoutIndex = rawLoadoutSaves.ActiveLoadout;

            local selectedLoadoutIndex = 1;
            local loadoutSlotButtons = {};
            local function updateLoadoutSelectionHighlight()
                for index, slotButton in pairs(loadoutSlotButtons) do
                    local useButton = slotButton:WaitForChild("UseButton");
                    
                    useButton.Visible = index == selectedLoadoutIndex and index ~= activeLoadoutIndex;
                end

                if selectedLoadoutIndex == nil then
                    selectLoadoutHighlight.Parent = nil;
                    return;
                end

                local selectedSlot = loadoutSlotButtons[selectedLoadoutIndex];
                selectLoadoutHighlight.Parent = selectedSlot.Highlight;
            end


            local function setLoadoutSlot(index)
                if index == activeLoadoutIndex then return end;
                
                interface:PlayButtonClick();
                if tick()-setloadoutDebounce <= 0.3 then return end;
                setloadoutDebounce = tick();

                local rPacket = remoteLoadoutSaves:InvokeServer("setloadout", {
                    LoadoutIndex = selectedLoadoutIndex;
                });
                if rPacket == nil or rPacket.Success == false then return end;

                rawLoadoutSaves = rPacket.Data;
                binds.LoadoutSaves = rawLoadoutSaves;
                PAGES.LoadoutsPage.Update();
            end


            for index=1, rawLoadoutSaves.MaxLoadouts do
                local newLoadoutSlot = templateLoadoutSlot:Clone();
                newLoadoutSlot.Name = index;
                newLoadoutSlot.LayoutOrder = index;
                newLoadoutSlot.Parent = loadoutsScrollFrame;
                loadoutSlotButtons[index] = newLoadoutSlot;

                newLoadoutSlot.MouseEnter:Connect(function()
                    selectedLoadoutIndex = index;
                    updateLoadoutSelectionHighlight();

                end)
                newLoadoutSlot.MouseMoved:Connect(function()
                    selectedLoadoutIndex = index;
                    updateLoadoutSelectionHighlight();

                    newLoadoutSlot.AutoButtonColor = index ~= activeLoadoutIndex;
                end)
                newLoadoutSlot.MouseLeave:Connect(function()
                    selectedLoadoutIndex = nil;
                    updateLoadoutSelectionHighlight();
                end)

                local useButton = newLoadoutSlot:WaitForChild("UseButton");
                useButton.MouseButton1Click:Connect(function()
                    setLoadoutSlot(index);
                end)
                newLoadoutSlot.MouseButton1Click:Connect(function()
                    setLoadoutSlot(index);
                end)

                if index == activeLoadoutIndex then
                    activeLoadoutHighlight.Color = interface.Colors.ActivePrimary;
                    activeLoadoutHighlight.Parent = newLoadoutSlot:WaitForChild("Highlight");
                end

                local titleLabel: TextLabel = newLoadoutSlot:WaitForChild("TitleLabel");
                titleLabel.Text = index == 1 and `Primary`
                    or index == 2 and `Secondary`
                    or index == 3 and `Auxiliary `
                    or `{index}`;

                local activeLabel: TextLabel = newLoadoutSlot:WaitForChild("ActiveLabel");
                activeLabel.Visible = index == activeLoadoutIndex;

                local loadoutData = rawLoadoutSaves.Loadouts[index];
                if loadoutData == nil or loadoutData.State ~= "Filled" then
                    local emptyLabel: TextLabel = newLoadoutSlot:WaitForChild("EmptyLabel");
                    emptyLabel.Visible = true;
                    continue;
                end;

                local storagesFrame: ScrollingFrame = newLoadoutSlot:WaitForChild("Storages") :: ScrollingFrame;
                local coldStorages = loadoutData.ColdStorages;

                local slotColors = {};
                for siid, clothingStorage in pairs(coldStorages.Clothing.Container) do
                    local itemLib = modItemsLibrary:Find(clothingStorage.ItemId);
                    if itemLib.SlotColor then
                        slotColors[siid] = itemLib.SlotColor;
                    end
                end

                local storageFrames = {};
                for sid, storage: Storage in pairs(coldStorages) do
                    local newStorageFrame = script:WaitForChild("ColdStorageFrame"):Clone();
                    newStorageFrame.Name = sid;

                    if sid == "Clothing" then
                        newStorageFrame.LayoutOrder = 1;

                        local signImg = Instance.new("ImageLabel");
                        signImg.Name = `SignSlot`;
                        signImg.Image = "rbxassetid://99478960624946";
                        signImg.LayoutOrder = 0;
                        signImg.Size = UDim2.new(0, 60, 0, 60);
                        signImg.BackgroundTransparency = 1;
                        signImg.Parent = newStorageFrame;

                        local signStroke = Instance.new("UIStroke");
                        signStroke.BorderStrokePosition = Enum.BorderStrokePosition.Inner;
                        signStroke.Thickness = 3;
                        signStroke.Transparency = 0.5;
                        signStroke.Color = Color3.fromRGB(20, 20, 20);
                        signStroke.Parent = signImg;

                        local uiCorner = Instance.new("UICorner");
                        uiCorner.Parent = signImg;

                    elseif sid == "Inventory" then
                        newStorageFrame.LayoutOrder = 2;

                        local signImg = Instance.new("ImageLabel");
                        signImg.Name = `SignSlot`;
                        signImg.Image = "rbxassetid://11191077792";
                        signImg.LayoutOrder = 0;
                        signImg.Size = UDim2.new(0, 60, 0, 60);
                        signImg.BackgroundTransparency = 1;
                        signImg.Parent = newStorageFrame;

                        local signStroke = Instance.new("UIStroke");
                        signStroke.BorderStrokePosition = Enum.BorderStrokePosition.Inner;
                        signStroke.Thickness = 3;
                        signStroke.Transparency = 0.5;
                        signStroke.Color = Color3.fromRGB(20, 20, 20);
                        signStroke.Parent = signImg;

                        local uiCorner = Instance.new("UICorner");
                        uiCorner.Parent = signImg;

                    else
                        newStorageFrame.LayoutOrder = 3;
                    end

                    storageFrames[sid] = newStorageFrame;
                    newStorageFrame.Parent = storagesFrame;
                end

                for sid, storage: Storage in pairs(coldStorages) do
                    local newStorageFrame = storageFrames[sid];

                    local slotFrames = {};
                    for index=1, storage.Size do
                        local newSlot = templateItemSlot:Clone();
                        newSlot.LayoutOrder = index;
                        newSlot.Visible = false;
                        newSlot.Parent = newStorageFrame;
                        if slotColors[sid] then
                            newSlot.ImageColor3 = slotColors[sid];
                        end
                        slotFrames[index] = newSlot;
                    end

                    for siid, storageItem: StorageItem in pairs(storage.Container) do
                        local newSlot = slotFrames[storageItem.Index];
                        newSlot.Visible = true;
                        
                        if slotColors[siid] then
                            newSlot.ImageColor3 = slotColors[siid];

                            local matchingStorageFrame = storageFrames[siid];
                            if matchingStorageFrame then
                                local cloneSignSlot = newSlot:Clone();
                                cloneSignSlot.LayoutOrder = 0;
                                cloneSignSlot.Parent = matchingStorageFrame;
                                cloneSignSlot.ImageTransparency = 1;
                                cloneSignSlot.Name = "SignSlot";

                                local itemButtonObject = modItemInterface.newItemButton(storageItem.ItemId);
                                itemButtonObject.ImageButton.Parent = cloneSignSlot;
                                itemButtonObject.HideTypeIcon = true;
                                itemButtonObject:Update(storageItem);

                                local signStroke = Instance.new("UIStroke");
                                signStroke.BorderStrokePosition = Enum.BorderStrokePosition.Inner;
                                signStroke.Thickness = 3;
                                signStroke.Transparency = 0.5;
                                signStroke.Color = slotColors[siid];
                                signStroke.Parent = cloneSignSlot;

                                matchingStorageFrame.LayoutOrder = 2+ newSlot.LayoutOrder;
                            end

                        elseif slotColors[sid] then
                            newSlot.ImageColor3 = slotColors[sid];
                        end

                        local itemButtonObject = modItemInterface.newItemButton(storageItem.ItemId);
                        itemButtonObject.ImageButton.Parent = newSlot;
                        itemButtonObject:Update(storageItem);

                        newSlot.Parent.Visible = true;
                    end
                end

            end
        end
    end;

    interface:BindEvent("queueupdate", function()
        PAGES.QueuePage.Update();
    end)
end

return interfacePackage;

