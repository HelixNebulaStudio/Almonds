local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");

local localPlayer = game.Players.LocalPlayer;

local modRecipeLibrary = shared.require(game.ReplicatedStorage.Library.RecipeLibrary);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibraryAlmdes);
local modTableManager = shared.require(game.ReplicatedStorage.Library.TableManager);
local modFormatNumber = shared.require(game.ReplicatedStorage.Library.FormatNumber);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManagerAlmdes);
local modItemInterface = shared.require(game.ReplicatedStorage.Library.UI.ItemInterface);
local modBoolString = shared.require(game.ReplicatedStorage.Library.Util.BoolString);

local LIST_TWEENINFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut);

local interfacePackage = {
    Type = "Character";
};
--==

function interfacePackage.newInstance(interface: InterfaceInstance)
    local modData = shared.require(localPlayer:WaitForChild("DataModule"));
    local remoteItemProcessor = modRemotesManager:Get("ItemProcessor");

    local playerClass: PlayerClass = shared.modPlayers.get(localPlayer);
    
    local templateListCate = script:WaitForChild("listCategory");
    local templateRecipeTooltip = script:WaitForChild("recipeTooltip");
    local templateProgressBar = script:WaitForChild("progressBar");

    local charWindow = interface:GetWindow("CharacterWindow");
    local lPanel = charWindow.Binds.LPanel;

    local craftingMenu = script:WaitForChild("CraftingMenu"):Clone();
    craftingMenu.Parent = lPanel;

	local recipesCateLib = modRecipeLibrary:Categorize();

    local window: InterfaceWindow = interface:NewWindow("CraftingMenu", craftingMenu);
    window.IgnoreHideAll = true;
    window:SetClosePosition(UDim2.new(-0.5, 0, 1, -220));

    local binds = window.Binds;
    binds.CategoriesEnabled = {};

    --MARK: OnToggle
    window.OnToggle:Connect(function(visible)
        if visible then
            binds.RefreshRecipesLists();
            binds.UpdateMenuContent();
        end
    end)


	local navList = craftingMenu:WaitForChild("NavList");
	local recipesList = craftingMenu:WaitForChild("RecipesList");
	local queueList = craftingMenu:WaitForChild("CraftQueue");

    queueList:GetPropertyChangedSignal("Visible"):Connect(function()
        if queueList.Visible then
            recipesList.Size = UDim2.new(1, -40, 1, -55);
        else
            recipesList.Size = UDim2.new(1, -40, 1, 0);
        end
    end)

    function binds.RefreshRecipesLists()
        local filterTestFunction = window.Properties.FilterTestFunction;

        for _, categoryListFrame in pairs(recipesList:GetChildren()) do
            local category = categoryListFrame.Name;
            if not categoryListFrame:IsA("GuiObject") or recipesCateLib[category] == nil then continue end;

            local visibleCount = 0;
            local unlockedCount = 0;
            local totalCount = 0;

            local listContent = categoryListFrame:WaitForChild("listContent");
            for _, obj in pairs(listContent:GetChildren()) do
                if not obj:IsA("ImageButton") then continue end;
                totalCount = totalCount +1;

                if filterTestFunction == nil then
                    if obj.BackgroundTransparency ~= 1 then
                        unlockedCount = unlockedCount +1;
                    end
                    visibleCount = visibleCount + 1;
                    obj.Visible = true;
                    continue;
                end

                local filterTable = {
                    obj:GetAttribute("RecipeCategory"):lower();
                    obj.Name:lower();
                };

                if filterTestFunction(filterTable) then
                    if obj.BackgroundTransparency ~= 1 then
                        unlockedCount = unlockedCount +1;
                    end
                    visibleCount = visibleCount + 1;
                    obj.Visible = true;
                else
                    obj.Visible = false;
                end
            end


            local listTitle = categoryListFrame:WaitForChild("listTitle");

            local useFilter = next(binds.CategoriesEnabled) ~= nil;
            local isVisible = visibleCount > 0;
            if useFilter then
                isVisible = binds.CategoriesEnabled[category] == true;
            end

            if isVisible then
                local listLayout = listContent.UIListLayout;
                TweenService:Create(categoryListFrame, LIST_TWEENINFO, {
                    Size = UDim2.new(1, 0, 0, listLayout.AbsoluteContentSize.Y + 25);
                }):Play();
                listTitle.Text = `- {category} ({unlockedCount}/{totalCount}) -`;
            else
                TweenService:Create(categoryListFrame, LIST_TWEENINFO, {
                    Size = UDim2.new(1, 0, 0, 20);
                }):Play();
                listTitle.Text = `+ {category} ({unlockedCount}/{totalCount}) +`;
            end

        end

    end

    function binds.UpdateFilterBoolString()
        local boolstring = nil;
        for k, v in pairs(binds.CategoriesEnabled) do
            if v == false then continue end;
            boolstring = `{boolstring or ""}|{k}`;
        end
        if boolstring then
            window.Properties.FilterTestFunction = modBoolString.newTestFunction(`({boolstring:lower()})`);
        else
            window.Properties.FilterTestFunction = nil;
        end
    end

    window.Properties.OnChanged:Connect(function(k, v)
        if k == "FilterTestFunction" then
            binds.RefreshRecipesLists();
        end
    end)

	local recipeToolTip = modItemInterface.newItemTooltip();
    local toolTipFrame: Frame = recipeToolTip.Frame;
    toolTipFrame.Name = `RecipeToolTip`;
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
    toolTipCustomFrame.Size = UDim2.new(1, 0, 0, 80);
	
	local recipeTooltipFrame: Frame = templateRecipeTooltip:Clone();
	recipeTooltipFrame.Parent = toolTipCustomFrame;

    local itemsList = recipeTooltipFrame:WaitForChild("itemsList");
    local itemsListLayout = itemsList:WaitForChild("UIListLayout");

    local resultItemButton = modItemInterface.newItemButton("wood");
    resultItemButton.ImageButton.LayoutOrder = 99;
    resultItemButton.ImageButton.Parent = itemsList;

    local craftMenuContent = {};
    local recipeItemsListCache = {};
    local fulfillRecipe = false;
    
    function recipeToolTip.CustomUpdate(toolTip, itemId)
        local recipeLib = modRecipeLibrary:Find(itemId);
        local itemLib = modItemsLibrary:Find(itemId);
        local craftAmount = recipeLib.Amount or 1;
        
        fulfillRecipe = true;
        toolTip.Frame.Size = UDim2.new(0, math.clamp(itemsListLayout.AbsoluteContentSize.X, 340, 460), 0, 100);
        toolTip.Frame.custom.Visible = true;
        
        local nameTag = toolTip.Frame:WaitForChild("NameTag");
        nameTag.Text = itemLib.Name ..(craftAmount > 1 and " x".. craftAmount or "");
        
        local recipeCostStr = {};
        local itemIdsUsed = {};
        for b=1, #recipeLib.Recipe do
            local recipeInfo = recipeLib.Recipe[b];

            local rItemId = recipeInfo.ItemId;
            local rItemLib = modItemsLibrary:Find(rItemId);

            table.insert(recipeCostStr, `• {rItemLib.Name} x{recipeInfo.Amount}`);

            local itemButtonObject = recipeItemsListCache[rItemId];
            if itemButtonObject == nil then
                itemButtonObject = modItemInterface.newItemButton(rItemId)
                itemButtonObject.ImageButton:WaitForChild("TypeIcon").Visible = false;
                recipeItemsListCache[rItemId] = itemButtonObject;
            end
            
            local imageButton = itemButtonObject.ImageButton;
            imageButton.Name = rItemId;
            imageButton.Size = UDim2.new(0, 60, 0, 60);
            
            if recipeInfo.Type ~= "Item" then
                itemButtonObject.CustomUpdate = function()
                    print("custom update")
                end;
            else
                local storageItemList = modData.ListItemIdFromCharacter(rItemId);
                local totalQuantity = 0;
                for c=1, #storageItemList do
                    totalQuantity = totalQuantity + storageItemList[c].Quantity;
                end
                
                local hasEnough = totalQuantity >= recipeInfo.Amount;
                imageButton.QuantityLabel.Text = `{modFormatNumber.Beautify(totalQuantity)}/{modFormatNumber.Beautify(recipeInfo.Amount)}`;
                imageButton.QuantityLabel.TextColor3 = hasEnough 
                    and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(255, 149, 149);
                imageButton.BackgroundColor3 = hasEnough
                    and Color3.fromRGB(20, 40, 20) or Color3.fromRGB(40, 20, 20);
                
                if totalQuantity < recipeInfo.Amount then
                    fulfillRecipe = false;
                end
            end
            
            itemButtonObject:Update();
            imageButton.Visible = true;
            imageButton.QuantityLabel.Visible = true;
            imageButton.Parent = itemsList;
            
            itemIdsUsed[rItemId] = true;
        end
        for ritemId, obj in pairs(recipeItemsListCache) do
            if itemIdsUsed[ritemId] == nil then
                obj.ImageButton.Visible = false;
            end
        end

        resultItemButton.ImageButton.QuantityLabel.Text = modFormatNumber.Beautify(craftAmount);
        resultItemButton.ImageButton.Size = UDim2.new(0, 60, 0, 60);
        
        local descLabel = recipeTooltipFrame:WaitForChild("descLabel");
        local descStr = `<font size="16">{itemLib.Description}</font>\n\n{table.concat(recipeCostStr, "\n")}`;

        local shortHintFrame = descLabel:WaitForChild("ShortHintsFrame");

        local timerFrame = shortHintFrame:WaitForChild("TimerFrame");
        local timerLabel = timerFrame:WaitForChild("TimerLabel");
        timerLabel.Text = `{recipeLib.Duration or 1}s`;

        local wbFrame = shortHintFrame:WaitForChild("WbFrame");
        if recipeLib.Workbench then
            local wbItemLib = modItemsLibrary:Find(recipeLib.Workbench);

            local wbIcon = wbFrame:WaitForChild("WbIcon");
            wbIcon.Image = wbItemLib.Icon;

            wbFrame.Visible = true;
        else
            wbFrame.Visible = false;
        end


        local requiredWorkbench = recipeLib.Workbench;
        local workbenchItemLib = requiredWorkbench and modItemsLibrary:Find(requiredWorkbench);
        if workbenchItemLib then
            descStr = `{descStr}\n\nRequires <b>{workbenchItemLib.Name}</b>`;
        end

        descLabel.Text = descStr;
        resultItemButton:SetItemId(itemId);
        resultItemButton:Update();
    end

	for category, _ in pairs(recipesCateLib) do
		local cateLib = modRecipeLibrary.Categories[category];
		
		local newCateList = templateListCate:Clone();
		newCateList.Name = category;
		
		local listContent = newCateList:WaitForChild("listContent");
		local listTitle = newCateList:WaitForChild("listTitle");
		
		--== Nav button
		local navItemButtonObject = modItemInterface.newItemButton(cateLib.IconItemId);
		navItemButtonObject:Update();

		local newNavButton = navItemButtonObject.ImageButton;
		newNavButton.LayoutOrder = cateLib.Order;
        newNavButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
        newNavButton.Size = UDim2.new(0, 35, 0, 35);
		newNavButton.Parent = navList;

		local navButtonTypeIcon = newNavButton:WaitForChild("TypeIcon");
		navButtonTypeIcon.Visible = false;


        --==
		local recipesLibs = recipesCateLib[category];
		for a=1, #recipesLibs do
			local recipeLib = recipesLibs[a];
			local itemId = recipeLib.Id;
			local craftAmount = recipeLib.Amount or 1;
			
			local itemLib = modItemsLibrary:Find(itemId);

			local newItemButtonObject = modItemInterface.newItemButton(itemId);
			newItemButtonObject.HideTypeIcon = true;
			newItemButtonObject:Update();
			
			local newCraftButton = newItemButtonObject.ImageButton;
			
			newCraftButton.Name = itemId;
            newCraftButton.Size = UDim2.new(0, 70, 0, 70);
            newCraftButton:SetAttribute("RecipeCategory", category);
			craftMenuContent[itemId] = newItemButtonObject;

			newCraftButton.Image = itemLib.Icon;
			local quantityLabel = newCraftButton:WaitForChild("QuantityLabel");
			quantityLabel.Text = craftAmount > 1 and " x".. craftAmount or "";
			quantityLabel.Visible = true;

            local requiredWorkbench = recipeLib.Workbench;
            local workbenchItemLib = requiredWorkbench and modItemsLibrary:Find(requiredWorkbench);
            if workbenchItemLib then
                local typeIcon = newCraftButton:WaitForChild("TypeIcon");
                typeIcon.Image = workbenchItemLib.Icon;
            end
			
			newItemButtonObject.RefreshCraftButton = function(_, validWorkbench)
                if validWorkbench then
                    newCraftButton.Active = true;
                    newCraftButton.BackgroundTransparency = 0.75;
                    newCraftButton.ImageColor3 = Color3.fromRGB(255, 255, 255);
                    newCraftButton.ImageTransparency = 0;
                    newCraftButton.LayoutOrder = a;

                else
					newCraftButton.Active = false;
					newCraftButton.ImageColor3 = Color3.fromRGB(0, 0, 0);
					newCraftButton.BackgroundTransparency = 1;
					newCraftButton.ImageTransparency = 0.5;
					newCraftButton.LayoutOrder = a+1000;

                end
			end
			
			newCraftButton.MouseButton1Click:Connect(function()
				local returnPacket = remoteItemProcessor:InvokeServer("craftrequest", {
					RecipeId=itemId;
				})
				
				if returnPacket and returnPacket.Success then
                    interface:FireEvent("DataItemProcessorUpdate", returnPacket);
				end
			end)
			
			recipeToolTip:BindHoverOver(newCraftButton, function()
				if not recipeToolTip.Frame.Visible then return end;

				recipeToolTip.Frame.Parent = interface.ScreenGui;
                recipeToolTip:Update(itemId);
				recipeToolTip:SetPosition(newCraftButton);
			end)
			
			newCraftButton.Parent = listContent;
		end
		
        local function toggleCategory()
            if binds.CategoriesEnabled[category] == nil then
                binds.CategoriesEnabled[category] = true;
            else
                binds.CategoriesEnabled[category] = nil;
            end

            local useFilters = next(binds.CategoriesEnabled) ~= nil;
            if useFilters and binds.CategoriesEnabled[category] then
                newNavButton.BackgroundTransparency = 0.5;
            else
                newNavButton.BackgroundTransparency = 1;
            end

            binds.UpdateFilterBoolString();
            binds.RefreshRecipesLists();
        end
		newNavButton.MouseButton1Click:Connect(function()
			interface:PlayButtonClick();
            toggleCategory();
		end)
		listTitle.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				interface:PlayButtonClick();
                toggleCategory();
			end
		end)

		newCateList.LayoutOrder = cateLib.Order;
		newCateList.Parent = recipesList;
	end


    function binds.UpdateMenuContent()
        local statusComp: StatusComp = playerClass.StatusComp;
        local workbenchStatus: StatusClassInstance? = statusComp:GetOrDefault("Workbench");

        for itemId, itemButtonObject in pairs(craftMenuContent) do
            local validWorkbench = true;

            local recipeLib = modRecipeLibrary:Find(itemId);
            local requiredWorkbench = recipeLib.Workbench;
            if requiredWorkbench then
                validWorkbench = false;

                local activeWbInteractable: InteractableInstance? = workbenchStatus and workbenchStatus.Values.ActiveInteractable;
                if activeWbInteractable and activeWbInteractable.Variant == requiredWorkbench then
                    validWorkbench = true;
                end
            end

            itemButtonObject:RefreshCraftButton(validWorkbench);
        end
    end

    --MARK: ItemProcessor
    local craftingProcessItemButtons = {};
    interface:BindEvent("DataItemProcessorUpdate", function() 
		local itemProcessor = modData.ItemProcessor;
		if itemProcessor == nil then return end;

		local craftProcesses = itemProcessor.Queues["CR"];
		if craftProcesses == nil then return end;
		
		local curServerTime = workspace:GetServerTimeNow();

        local existNums = {};
		for a=1, #craftProcesses do
			local processData = craftProcesses[a];
            local processNum = tostring(processData.Num);
            local processItemId = processData.Id;

            local itemLib = modItemsLibrary:Find(processItemId);
            
            existNums[processNum] = true;


            local craftButtonObject = craftingProcessItemButtons[processNum];
            if craftButtonObject == nil then
                craftButtonObject = modItemInterface.newItemButton(processItemId);
                craftButtonObject:Update();
                craftingProcessItemButtons[processNum] = craftButtonObject;

                craftButtonObject.ImageButton.LayoutOrder = -a;
                craftButtonObject.ImageButton.BackgroundTransparency = 0.5;
                craftButtonObject.ImageButton.Size = UDim2.new(0, 45, 0, 45);
                craftButtonObject.ImageButton.Parent = queueList:WaitForChild("ContentList");

                local progressBar = templateProgressBar:Clone();
                progressBar.Parent = craftButtonObject.ImageButton;
                craftButtonObject.ProgressBar = progressBar;

                craftButtonObject.ImageButton.MouseButton1Click:Connect(function()
                    interface:PlayButtonClick();
                    interface:FireEvent("DataItemProcessorUpdate",
                        remoteItemProcessor:InvokeServer("cancelcraft", {
                            AddTick = processData.AddTick;
                        })
                    );
                end)
            end

            local progressFrame = craftButtonObject.ProgressBar;
            local bar = progressFrame:WaitForChild("Bar");
            bar.ZIndex = 2;

            local queueIndex = processData.QueueIndex;
            local endTick = processData.EndTick;

            progressFrame.Visible = true;
            if endTick then
                bar.Size = UDim2.new(0, 0, 1, 0);

                local activeTween = bar:GetAttribute("ActiveTween");
                if activeTween == nil or activeTween ~= endTick then
                    bar:SetAttribute("ActiveTween", endTick);

                    local timeRemaining = processData.EndTick-curServerTime;
                    local tween = TweenService:Create(bar, TweenInfo.new(timeRemaining), {
                        Size = UDim2.new(1, 0, 1, 0);
                    });
                    tween.Completed:Connect(function(state)
                        if state ~= Enum.PlaybackState.Completed then 
                            return;
                        end;
                        progressFrame.Visible = false;
                        progressFrame.Size = UDim2.new(1, 0, 1, 0);
                    end)
                    tween:Play();
                end

            else
                bar:SetAttribute("ActiveTween", nil);
                TweenService:Create(bar, TweenInfo.new(0.1), {
                    Size = UDim2.new(0, 0, 1, 0);
                }):Play();
                progressFrame.Visible = true;
            end

            local label = progressFrame.Label;
            label.Text = queueIndex or ``;
        end
        for processNum, obj in pairs(craftingProcessItemButtons) do
            if existNums[processNum] then continue end;
            obj:Destroy();
        end

        queueList.Visible = next(existNums) ~= nil;
    end)

    interface:BindEvent("UpdateCraftingStatus", function()
        binds.UpdateMenuContent();
    end)
end

return interfacePackage;

