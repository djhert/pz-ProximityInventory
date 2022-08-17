ProxInv = {}
ProxInv.isToggled = true
ProxInv.isHighlightEnable = true
ProxInv.isForceSelected = false
ProxInv.inventoryIcon = getTexture("media/ui/ProximityInventory.png")
ProxInv.bannedTypes = {
	stove = true,
	fridge = true,
	freezer = true,
	barbecue = true,
	fireplace = true,
	woodstove = true,
	microwave = true,
}
ProxInv.toggleState = function ()
	ProxInv.isToggled = not ProxInv.isToggled
	ISInventoryPage.dirtyUI() -- This calls refreshBackpacks()
end
ProxInv.setForceSelected = function ()
	ProxInv.isForceSelected = not ProxInv.isForceSelected
	ISInventoryPage.dirtyUI()
end
ProxInv.setHighlightEnable = function ()
	ProxInv.isHighlightEnable = not ProxInv.isHighlightEnable
	ISInventoryPage.dirtyUI()
end
ProxInv.isLocalContainerSelected = false
ProxInv.buttonCache = nil
ProxInv.containerCache = {}
ProxInv.resetContainerCache = function ()
	ProxInv.containerCache = {}
end

ProxInv.getTooltip = function ()
	local text = "Right click for settings"
	text = not ProxInv.isToggled and "Disabled - "..text or text
	return text
end

ProxInv.canBeAdded = function (container, playerObj)
	-- Do not allow if it's a stove or washer or similiar "Active things"
	-- It can cause issues like the item stops cooking or stops drying
	-- Also don't allow to see inside containers locked to you
	local object = container:getParent()
	if object and instanceof(object, "IsoThumpable") and object:isLockedToCharacter(playerObj) then
		return false
	end

	return not ProxInv.bannedTypes[container:getType()]
end

ProxInv.populateContextMenuOptions = function (context)
	local toggleText = ProxInv.isToggled and "OFF" or "ON" 
	local optToggle = context:addOption("Toggle "..toggleText, nil, ProxInv.toggleState)
	-- option.iconTexture = getTexture("media/ui/Panel_Icon_Gear.png");
	optToggle.iconTexture = ProxInv.inventoryIcon;

	local forceSelectedText = ProxInv.isForceSelected and "Disable" or "Enable"
	local optForce = context:addOption(forceSelectedText.." Force Selected", nil, ProxInv.setForceSelected)

	local highlightText = ProxInv.isHighlightEnable and "Disable" or "Enable"
	local optForce = context:addOption(highlightText.." Highlight", nil, ProxInv.setHighlightEnable)
end

ProxInv.OnButtonsAdded = function (invSelf)
	local localContainer = ISInventoryPage.GetLocalContainer(invSelf.player)
	localContainer:removeItemsFromProcessItems()
	localContainer:clear()

	local title = "Proximity Inv"
	local proxInvButton = invSelf:addContainerButton(localContainer, ProxInv.inventoryIcon, title, ProxInv.getTooltip())
	proxInvButton.capacity = 0
	proxInvButton:setY(invSelf:titleBarHeight() - 1)
	ProxInv.buttonCache = proxInvButton
	ProxInv.resetContainerCache()

	-- Add All backpacks content except last which is proxInv
	for i = 1, (#invSelf.backpacks - 1) do
		local buttonToPatch = invSelf.backpacks[i]
		local invToAdd = invSelf.backpacks[i].inventory
		if ProxInv.canBeAdded(invToAdd) then
			local items = invToAdd:getItems()
			proxInvButton.inventory:getItems():addAll(items)
			table.insert(ProxInv.containerCache, invToAdd)
		end
		-- Since I'm looping here I might aswell also take care of patching all the buttons Y position
		buttonToPatch:setY(buttonToPatch:getY() + invSelf.buttonSize)
	end

	if not ProxInv.isToggled then
		-- Remove the backpack from the list
		table.remove(invSelf.backpacks, #invSelf.backpacks)
	end
end

ProxInv.OnBeginRefresh = function (invSelf)
	-- This avoid the generation of multiple buttons when it's off
	-- Since childrens gets removed via #invSelf.backpacks, and when it's toggled off the button does not appear
	-- in the #invSelf.backpacks
	if ProxInv.isToggled then
		return
	end
	invSelf:removeChild(ProxInv.buttonCache)
end

ProxInv.OnRefreshInventoryWindowContainers = function(invSelf, state)
	local playerObj = getSpecificPlayer(invSelf.player)
    if invSelf.onCharacter or playerObj:getVehicle() then
		-- Ignore character containers, as usual
		-- Ignore in vehicles
        return
	end

	if state == "begin" then
		return ProxInv.OnBeginRefresh(invSelf)
	end

	if state == "buttonsAdded" then
		return ProxInv.OnButtonsAdded(invSelf)
	end
	-- Test add button dynamically? 
end

Events.OnRefreshInventoryWindowContainers.Add(ProxInv.OnRefreshInventoryWindowContainers)
