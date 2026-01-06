local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibraryAlmdes);
local modDeconstructLibrary = shared.require(game.ReplicatedStorage.Library.DeconstructLibrary);
local modItemInterface = shared.require(game.ReplicatedStorage.Library.UI.ItemInterface);
local modItemViewport = shared.require(game.ReplicatedStorage.Library.UI.ItemViewport);
local modFormatNumber = shared.require(game.ReplicatedStorage.Library.FormatNumber);

local interfacePackage = {
    Type = "Player";
};
--==

function interfacePackage.newInstance(interface: InterfaceInstance)
    --MARK: ItemToolTip
    local templateItemTooltip = script:WaitForChild("itemTooltip");

    local itemToolTip = modItemInterface.newItemTooltip();

    local toolTipFrame: Frame = itemToolTip.Frame;
    toolTipFrame.Name = `ItemToolTip`;
    toolTipFrame.BackgroundColor3 = interface.Colors.ForepanelBackground;
    toolTipFrame.AutomaticSize = Enum.AutomaticSize.Y;
	toolTipFrame.Parent = interface.ScreenGui;
    local newStroke = Instance.new("UIStroke");
    newStroke.Thickness = 1;
    newStroke.Color = interface.Colors.BorderColorPrimary;
    newStroke.Parent = toolTipFrame;

    toolTipFrame:WaitForChild("UIGradient"):Destroy();
    toolTipFrame:WaitForChild("UISizeConstraint"):Destroy();

    local toolTipNameTag = toolTipFrame:WaitForChild("NameTag");
    toolTipNameTag.Size = UDim2.new(1, 0, 0, 30);
    toolTipNameTag.BackgroundTransparency = 0.9;
    toolTipNameTag.TextXAlignment = Enum.TextXAlignment.Left;
    local newPadding = Instance.new("UIPadding");
    newPadding.PaddingLeft = UDim.new(0, 20);
    newPadding.Parent = toolTipNameTag;
    local newCorner = Instance.new("UICorner");
    newCorner.CornerRadius = UDim.new(0, 5);
    newCorner.Parent = toolTipNameTag;

    local toolTipCustomFrame: Frame = toolTipFrame:WaitForChild("custom") :: Frame;
    toolTipCustomFrame.AutomaticSize = Enum.AutomaticSize.Y;
    toolTipCustomFrame.Position = UDim2.new(0, 0, 0, 30);
    toolTipCustomFrame.Size = UDim2.new(1, 0, 0, 0);

	local itemTooltipFrame: Frame = templateItemTooltip:Clone();
	itemTooltipFrame.Parent = toolTipCustomFrame;

    local itemsListCache = {};
    local itemIdsUsed = {};

    function itemToolTip.CustomUpdate(toolTip, itemId)
        local itemLib = modItemsLibrary:Find(itemId);
        
        toolTip.Frame.Size = UDim2.new(0, 240, 0, 0);
        toolTip.Frame.custom.Visible = true;
        
        local nameTag = toolTip.Frame:WaitForChild("NameTag");
        nameTag.Text = itemLib.Name;
        
        local descLabel = itemTooltipFrame:WaitForChild("descLabel");
        local descStr = `<font size="16">{itemLib.Description}</font>`;


        local deconstructsList = itemTooltipFrame:WaitForChild("deconstructsList");
        local deconstructLib = modDeconstructLibrary:Find(itemId);
        if deconstructLib then
            local deconstructLabel = deconstructsList:WaitForChild("deconstructLabel");
            local timerLabel = deconstructLabel:WaitForChild("TimerFrame"):WaitForChild("TimerLabel");

            timerLabel.Text = `{deconstructLib.Duration or 5}s`;

            deconstructsList.Visible = true;
            local deconstructRewards = deconstructLib.Rewards;

            for a=1, #deconstructRewards do
                local dLib = deconstructRewards[a];
                local dItemId = dLib.ItemId;
                local dQty = dLib.Quantity;
                local dItemLib = modItemsLibrary:Find(dItemId);

                local itemButtonObject = itemsListCache[dItemId];
                if itemButtonObject == nil then
                    itemButtonObject = modItemInterface.newItemButton(dItemId);
                    itemButtonObject:Update();
                    itemsListCache[dItemId] = itemButtonObject;
                end
                
                local imageButton = itemButtonObject.ImageButton;
                imageButton.Name = dItemId;
                imageButton.Size = UDim2.new(0, 60, 0, 60);

                imageButton.QuantityLabel.Text = `{modFormatNumber.Beautify(dQty.Min)} ~ {modFormatNumber.Beautify(dQty.Max)}`;
                imageButton.QuantityLabel.TextSize = 14;

                itemButtonObject:Update();
                imageButton.Visible = true;
                imageButton.QuantityLabel.Visible = true;
                imageButton.Parent = deconstructsList;
                
                itemIdsUsed[dItemId] = true;
            end
        else
            deconstructsList.Visible = false;
        end
        for ritemId, obj in pairs(itemsListCache) do
            if itemIdsUsed[ritemId] == nil then
                obj.ImageButton.Visible = false;
            end
        end

        descLabel.Text = descStr;
    end


    local itemToolTipElement: InterfaceElement = interface:GetOrDefaultElement("ItemToolTip", {
        ToggleVisible = function(v)
            itemToolTip.Frame.Visible = v;
        end;
        Update = function(itemId, storageItem)
            itemToolTip:Update(itemId, storageItem);
        end;
        SetPosition = function(guiObject)
            itemToolTip:SetPosition(guiObject);
        end
    });

    itemToolTipElement.OnChanged:Connect(function()
    end)

end

return interfacePackage;

