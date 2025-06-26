local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");
local HttpService = game:GetService("HttpService");
local TweenService = game:GetService("TweenService");

local camera = workspace.CurrentCamera;
local localPlayer = game.Players.LocalPlayer;

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modCameraGraphics = shared.require(game.ReplicatedStorage.PlayerScripts.CameraGraphics);
local modClientLighting = shared.require(game.ReplicatedStorage.PlayerScripts.ClientLighting);

local modScreenRelativeTextSize = shared.require(game.ReplicatedStorage.Library.UI.ScreenRelativeTextSize);

local BASIC_TWEENINFO = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut);

local interfacePackage = {
    Type = "Player";
};
--==

function interfacePackage.newInstance(interface: InterfaceInstance)
    local curPage = "Root";
    local activePlayPage = "OptionsFrame";

    local remoteMainMenu = modRemotesManager:Get("MainMenuRemote");

    local frame = script:WaitForChild("MainMenuFrame"):Clone();
    frame.Parent = interface.ScreenGui;
    local bodyFrame = frame:WaitForChild("PageBody");

    local menuMusic: Sound = frame:WaitForChild("MenuMusic");


    local window: InterfaceWindow = interface:NewWindow("MainMenu", frame);
    window.IgnoreHideAll = true;
    window.UseMenuBlur = true;
    window.UseTween = false;
    window.DisableHotKeysHint = true;

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

        else
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

    local navBar = frame:WaitForChild("NavBar"):WaitForChild("Content");
    local navButtons = navBar:GetChildren();
    local navCooldown = tick();
    for a=1, #navButtons do
        local button = navButtons[a];
        if not button:IsA("GuiObject") then continue end;

        button.MouseButton1Click:Connect(function()
            if tick()-navCooldown <= 0.1 then return end;
            navCooldown = tick();
            interface:PlayButtonClick();
            curPage = button.Name;
            window:Update();
        end)

        if button:FindFirstChild("SelectedHighlight") then
            local selectedHighlight = button.SelectedHighlight;
            button.MouseEnter:Connect(function()
                selectedHighlight.Visible = true;
            end)
            button.MouseLeave:Connect(function()
                selectedHighlight.Visible = false;
            end)
        end
    end


    local menuButton = frame:WaitForChild("NavBar"):WaitForChild("MenuButton");
    local function menuButtonOnClick()
        if tick()-navCooldown <= 0.1 then return end;
        navCooldown = tick();
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
                    Size = isOn and UDim2.new(1.7, 0, 1.7, 0) or UDim2.new(1.6, 0, 1.6, 0);
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
    menuButton.MouseEnter:Connect(function() toggleMenuButtonMouseEvent(true); end);
    menuButton.MouseLeave:Connect(function() toggleMenuButtonMouseEvent(false); end);


    local loadPlayPageFunc;
    local updatePlayPages;

    local function updatePages()
        if curPage == "PlayPage" then
            loadPlayPageFunc();

            local playPage: Frame = bodyFrame.PlayPage;
            if playPage.Visible == false or activePlayPage ~= "OptionsFrame" then
                activePlayPage = "OptionsFrame";

                playPage.Position = UDim2.new(0.5, 0, -1, 0);
                playPage.Visible = true;
                local tween = TweenService:Create(playPage, BASIC_TWEENINFO, {
                    Position = UDim2.new(0.5, 0, 0, 0);
                });
                tween:Play();
            end

        else
            bodyFrame.PlayPage.Visible = false;

        end
    end

    window.OnUpdate:Connect(function()
        if window.Visible then
            interface.VersionLabel.ZIndex = 2;
        else
            interface.VersionLabel.ZIndex = 0;
            interface:ToggleWindow("UpdateWindow", false);
            return;
        end

        local menuEqualizer = menuMusic:FindFirstChild("EqualizerSoundEffect") :: EqualizerSoundEffect;
        menuEqualizer.Enabled = curPage == "Root";

        if curPage == "Root" then
            interface:ToggleWindow("UpdateWindow", true);
            updatePages();

        elseif curPage == "PlayPage" then
            interface:ToggleWindow("UpdateWindow", false);
            updatePages()
            updatePlayPages();

        end
    end)

    local function updateBodySize(k, v, ov)
        if k ~= "TopBarInset" then return end;
        bodyFrame.Size = UDim2.new(1, 0, 0.9, -interface.Properties.TopbarInset.Height);
    end
    interface.Properties.OnChanged:Connect(updateBodySize)
    updateBodySize("TopBarInset");


    --== MARK: Play Page
    local playPageLoaded = false;
    loadPlayPageFunc = function()
        if playPageLoaded then return end;
        playPageLoaded = true;

        local modData = shared.require(localPlayer:WaitForChild("DataModule"));
        
        local isMenuWorld = modBranchConfigs.IsWorld("Genesis");
        local isTutorialFinished = modData:GetEvent("tutorialFinished");

        local playPageFrame = bodyFrame:WaitForChild("PlayPage");

        
        local PlayPages = {
            Options = playPageFrame:WaitForChild("OptionsFrame");
            ServerBrowser = playPageFrame:WaitForChild("ServerBrowserFrame");
            SpawningFrame = playPageFrame:WaitForChild("SpawningFrame");
        }
        
        local optionsScrollFrame = PlayPages.Options:WaitForChild("OptionsScrollFrame");
        local PlayOptions = {
            Play = optionsScrollFrame:WaitForChild("PlayOptionPlay");
            Servers = optionsScrollFrame:WaitForChild("PlayOptionServers");
            Event = optionsScrollFrame:WaitForChild("PlayOptionEvent");
            Tutorial = optionsScrollFrame:WaitForChild("PlayOptionTutorial");
        };
        
        local selectionName = PlayOptions.Play.Name;
        local selectionHighlight = script:WaitForChild("SelectionHighlight"):Clone();

        local function updateSelectionHighlight()
            for key, optionsButton in pairs(PlayOptions) do
                local isSelected = optionsButton.Name == selectionName;

                local buttonImage: ImageLabel = optionsButton.ImageLabel;
                if isSelected then
                    selectionHighlight.Parent = buttonImage;
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

                buttonImage.ImageColor3 = isSelected and Color3.fromRGB(255,255,255) or Color3.fromRGB(225,225,225);
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
                
                local worldName = modBranchConfigs.GetWorldName(serverInfo.PlaceId);
                
                titleLabel.Name = "Official Server #".. serverInfo.JobId;
                playersLabel.Text = #serverInfo.Players .." / ".. serverInfo.MaxPlayers;
                pingLabel.Text = serverInfo.RegionCode;
                descLabel.Text = "Official vanilla almonds server. World: ".. modBranchConfigs.GetWorldDisplayName(worldName); 
                
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

        updatePlayPages = function()
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


        local function deploy(action)
            TweenService:Create(frame, BASIC_TWEENINFO, {Position=UDim2.new(0,0,0.2,0)}):Play();

            if remoteMainMenu:Debounce() then return end;

            local replyPacket = remoteMainMenu:InvokeServer(action) or {};
            if replyPacket.Success then

            else
                curPage = "Root";
                TweenService:Create(frame, BASIC_TWEENINFO, {Position=UDim2.new(0,0,0,0)}):Play();
                window:Open();
            end
        end

        for key, optionsButton: TextButton in pairs(PlayOptions) do
            optionsButton.MouseEnter:Connect(function()
                selectionName = optionsButton.Name;
                updateSelectionHighlight();
            end)
            optionsButton.MouseMoved:Connect(function()
                selectionName = optionsButton.Name;
                updateSelectionHighlight();
            end)
            optionsButton.MouseLeave:Connect(function()
                selectionName = nil;
                updateSelectionHighlight();
            end)
            
            if key == "Tutorial" then
                optionsButton.Visible = isMenuWorld and isTutorialFinished == nil;
            elseif key == "Play" then
                optionsButton.Visible = not (isMenuWorld and isTutorialFinished == nil);
            end
            optionsButton.MouseButton1Click:Connect(function()
                interface:PlayButtonClick();
                
                if key == "Tutorial" then
                    Debugger:Warn(`Clicked Tutorial`);

                    activePlayPage = "SpawningFrame";
                    updatePlayPages();
                    deploy("playtutorial");
                    
                elseif key == "Play" then
                    Debugger:Warn(`Clicked Quick play`);
                    
                    activePlayPage = "SpawningFrame";
                    updatePlayPages();
                    deploy("quickplay");

                elseif key == "Servers" then
                    Debugger:Warn(`Clicked Server`);
                    activePlayPage = "ServerBrowserFrame";
                    updatePlayPages();
                    
                elseif key == "Event" then
                    Debugger:Warn(`Clicked Event`);
                    
                    
                end
            end)
            
            local descLabel = optionsButton:WaitForChild("DescLabel");
            descLabel.TextSize = modScreenRelativeTextSize.GetTextSize();
        end
    end

    function remoteMainMenu.OnClientInvoke()
        
    end
end

return interfacePackage;

