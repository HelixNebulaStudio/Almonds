local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");
local GuiService = game:GetService("GuiService");

local camera = workspace.CurrentCamera;
local localPlayer = game.Players.LocalPlayer;

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurationsAlmdes);
local modKeyBindsHandler = shared.require(game.ReplicatedStorage.Library.KeyBindsHandler);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modItemInterface = shared.require(game.ReplicatedStorage.Library.UI.ItemInterface);

local organizedItemsList;
local isDevBranch = shared.gameConfig.BranchName == "Dev";

local catInfoLib = {
	Resource={Order=10; Title="Resources";};
	Gun={Order=20; Title="Guns";};
	Melee={Order=30; Title="Melees";};
	Throwable={Order=40; Title="Throwables";};
	
	--== Clothing
	--Clothing={Order=50;};
	["Head"]={Order=51; Title="Head";};
	["Chest"]={Order=52; Title="Chest";};
	--["Legs"]={Order=53; Title="Legs";};
	["Gloves"]={Order=54; Title="Gloves";};
	["Shoes"]={Order=55; Title="Shoes";};
	["Utility Wear"]={Order=56; Title="Utility Wear";};
	
	Storage={Order=100;};
	Structure={Order=110; Title="Structure";};
	Component={Order=120; Title="Components";};
	Commodity={Order=130; Title="Commodities";};
	Food={Order=140; Title="Food";};

	Instrument={Order=180; Title="Instruments";};
	
	Tool={Order=210; Title="Tools";};
	Deployable={Order=220; Title="Deployables";};
	Mission={Order=250; Title="Mission";};
	
	["April Fools"]={Order=280;};
	["Easter"]={Order=290;};
	["Summer"]={Order=300;};
	["Slaughterfest"]={Order=310;};
	["Frostivus"]={Order=320;};

	["Unobtainable"]=(isDevBranch and {Order=500; Title="[Dev Branch] Unobtainable";} or nil);
	["Dev"]=(isDevBranch and {Order=999; Title="[Dev Branch] Developer Tools";} or nil);
}

local interfacePackage = {
    Type = "Player";
};
--==


function interfacePackage.newInstance(interface: InterfaceInstance)
    local modData = shared.require(localPlayer:WaitForChild("DataModule"));

    local codexWindow = script:WaitForChild("CodexWindow"):Clone();

    local templateNavButton = script:WaitForChild("templateNavButton");
    local templateListFrame = script:WaitForChild("templateList");
    local templateTabButton = script:WaitForChild("templateTab");

    local window: InterfaceWindow = interface:NewWindow("CodexWindow", codexWindow);
    window.IgnoreHideAll = true;
    window.UseTween = false;
    window.DisableInteractables = true;
    window.CloseWithInteract = true;

	local keyId = `KeyWindow{window.Name}`;
	modKeyBindsHandler:SetDefaultKey(keyId, Enum.KeyCode.N);
	
	local codexQuickButton = interface:NewQuickButton(window.Name, "Codex", "rbxassetid://95170475140897");
	codexQuickButton.LayoutOrder = 4;
	interface:ConnectQuickButton(codexQuickButton, keyId);

    local contentFrame = codexWindow:WaitForChild("Content");
    local contentUiCorner = contentFrame:WaitForChild("UICorner");
    local contentDropShadow = contentFrame:WaitForChild("_dropShadow");
    local navListScrollFrame = contentFrame:WaitForChild("NavList");
    local itemsListScrollFrame = contentFrame:WaitForChild("ItemsList");

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
                codexWindow.Parent = rPanel;
                contentUiCorner.CornerRadius = UDim.new(0, 5);
                contentDropShadow.Visible = false;
                contentFrame.Position = UDim2.new(1, 0, 1, -70);
                contentFrame.Size = UDim2.new(1, 0, 1, -140);
                contentFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20);
                contentFrame.BackgroundTransparency = 0.5;
                TweenService:Create(contentFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Position = UDim2.new(0.5, 0, 1, -70);
                }):Play();
                interface:ToggleWindow("Inventory", true);

            else
                codexWindow.Parent = interface.ScreenGui;
                contentUiCorner.CornerRadius = UDim.new(0, 0);
                contentDropShadow.Visible = true;
                contentFrame.Position = UDim2.new(0.5, 0, 0.9, -20);
                contentFrame.Size = UDim2.new(0.6, 0, 0.8, -20);
                contentFrame.BackgroundColor3 = Color3.fromRGB(35, 24, 40);
                contentFrame.BackgroundTransparency = 0.1;
                interface:HideAll{[window.Name]=true;};

            end
            
            codexWindow.Visible = true;
            window:Update(true);

        else
            codexWindow.Visible = false;

            if mainMenuWindow and mainMenuWindow.Visible then
                mainMenuWindow:Update();
            end
        end
    end)

    --MARK: OnUpdate
    local typeCategory = {};
	window.OnUpdate:Connect(function()
        local itemCodexPacket = modData:GetFlag("ItemCodex");
        local itemUnlockFlag = itemCodexPacket and itemCodexPacket.Data or {};

        if organizedItemsList == nil then
            organizedItemsList = {};
            
            local indexedList = modItemsLibrary.Library:GetIndexList();
            for i=1, #indexedList do
                local itemLib = indexedList[i];

                local tags = itemLib.Tags;
                if table.find(tags, "HideFromCodex") then
                    continue;
                end
                
                for a=1, #tags do
                    if catInfoLib[tags[a]] then
                        table.insert(organizedItemsList, {
                            ItemLib=itemLib;
                            Tag=tags[a];
                            Unobtainable=table.find(tags, "Unobtainable") ~= nil;
                        });
                    end
                end
            end
        end

        local itemToolTipElement: InterfaceElement = interface:GetOrDefaultElement("ItemToolTip");
        local function onItemHighlightStart(itemId, button)
            itemToolTipElement.Update(itemId);
            itemToolTipElement.SetPosition(button);
            itemToolTipElement.ToggleVisible(true);
        end
        local function onItemHighlightEnd()
            itemToolTipElement.ToggleVisible(false);
        end

        for a=1, #organizedItemsList do
            local itemLib = organizedItemsList[a].ItemLib;
            local itemTag = organizedItemsList[a].Tag;
            local itemIsUnobtainable = organizedItemsList[a].Unobtainable;
            
            if isDevBranch then
                itemIsUnobtainable = false;
            end
            
            local typeInfo = catInfoLib[itemTag];
            local catInfo = typeCategory[itemTag];
            
            local newTab, newList;
            if catInfo == nil and typeInfo then
                newTab = templateTabButton:Clone();
                newTab.Name = itemTag;

                local titleLabel = newTab:WaitForChild("titleLabel");
                local _semiCollapseSign = newTab:WaitForChild("semiCollapseSign");
                local _collapseSign = newTab:WaitForChild("collapseSign");
                local _expandSign = newTab:WaitForChild("expandSign");
                
                titleLabel.Text = typeInfo.Title or itemTag;
                
                newTab.LayoutOrder = typeInfo.Order;
                newTab.Parent = itemsListScrollFrame;
                
                newList = templateListFrame:Clone();
                newList.Name = itemTag;
                newList.LayoutOrder = typeInfo.Order+0.5;
                newList.Parent = itemsListScrollFrame;
                
                catInfo = {
                    Tab = newTab;
                    List = newList;
                    Content = {};
                }
                typeCategory[itemTag] = catInfo;
            end
            
            local itemUnlocked = isDevBranch or itemUnlockFlag[itemLib.Id];
            if itemUnlocked then
                itemIsUnobtainable = false;
            end
            
            if catInfo and itemIsUnobtainable == false and catInfo.Content[itemLib.Id] == nil then
                local itemButtonObj = modItemInterface.newItemButton(itemLib.Id, true);
                catInfo.Content[itemLib.Id] = itemButtonObj;
                itemButtonObj:SetZIndex(1);

                local newItemButton: ImageButton = itemButtonObj.ImageButton;
                newItemButton.LayoutOrder = a;
                newItemButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30);
                newItemButton.BackgroundTransparency = 0.2;
                
                itemButtonObj:Update();

                newItemButton.InputBegan:Connect(function(inputObject, gameProcessed)
                    if inputObject.UserInputType == Enum.UserInputType.MouseMovement then
                        onItemHighlightStart(itemLib.Id, newItemButton);
                    end
                end)
                newItemButton.InputChanged:Connect(function(inputObject, gameProcessed)
                    if inputObject.UserInputType == Enum.UserInputType.MouseMovement then
                        onItemHighlightStart(itemLib.Id, newItemButton);
                    end
                end)
                newItemButton.InputEnded:Connect(function(inputObject, gameProcessed)
                    if inputObject.UserInputType == Enum.UserInputType.MouseMovement then
                        onItemHighlightEnd();
                    end
                end)

                newItemButton.SelectionGained:Connect(function()
                    onItemHighlightStart(itemLib.Id, newItemButton);
                end)
                newItemButton.SelectionLost:Connect(onItemHighlightEnd)

                newItemButton.Parent = catInfo.List;
            end
        end
    end)

    task.spawn(function()
        modData:GetFlag("ItemCodex", true);
    end)
end

return interfacePackage;

