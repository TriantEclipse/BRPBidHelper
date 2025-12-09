local state = {
  weird_vibes_mode = true,
  rollMessages = {},
  rollers = {},
  isRolling = false,
  time_elapsed = 0,
  item_query = 0.5,
  times = 5,
  discover = CreateFrame("GameTooltip", "CustomTooltip1", UIParent, "GameTooltipTemplate"),
  masterLooter = nil,
  srRollCap = 101,
  msRollCap = 100,
  osRollCap = 99,
  tmogRollCap = 50,
  MLRollDuration = 30,
  minimumBid = "10",
  naxx = 0,
  kara = 0,
}

StaticPopupDialogs["CONFIRM_ALL_IN_NAXX"] = {
  text = "Tochno All In?",
  button1 = "Yes",
  button2 = "Ne, peredumal",
  OnAccept = function()
      SendChatMessage(state.naxx, "WHISPER", nil, state.masterLooter)
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3, -- Use a high number to avoid conflicts
}

--StaticPopupDialogs["CONFIRM_ALL_IN_KARA"] = {
--  text = "Eto DKP skeduyushego",
--  button1 = "Yes",
--  button2 = "Ne Ne Ne",
--  OnAccept = function()
--      SendChatMessage(state.kara, "WHISPER", nil, state.masterLooter)
--  end,
--  timeout = 0,
--  whileDead = true,
--  hideOnEscape = true,
--  preferredIndex = 3, -- Use a high number to avoid conflicts
--}

local BUTTON_WIDTH = 120
local BUTTON_HEIGHT = 32
local BUTTON_COUNT = 2
local BUTTON_PADING = 5
local FONT_NAME = "Fonts\\FRIZQT__.TTF"
local FONT_SIZE = 12
local FONT_OUTLINE = "OUTLINE"
local RAID_CLASS_COLORS = {
  ["Warrior"] = "FFC79C6E",
  ["Mage"]    = "FF69CCF0",
  ["Rogue"]   = "FFFFF569",
  ["Druid"]   = "FFFF7D0A",
  ["Hunter"]  = "FFABD473",
  ["Shaman"]  = "FF0070DE",
  ["Priest"]  = "FFFFFFFF",
  ["Warlock"] = "FF9482C9",
  ["Paladin"] = "FFF58CBA",
}
local colors = {
  ADDON_TEXT_COLOR = "FFEDD8BB",
  DEFAULT_TEXT_COLOR = "FFFFFF00",
  SR_TEXT_COLOR = "ffe5302d",
  MS_TEXT_COLOR = "FFFFFF00",
  OS_TEXT_COLOR = "FF00FF00",
  TM_TEXT_COLOR = "FF00FFFF",
  OTHER_TEXT_COLOR = "ffff80be",
}

local LB_PREFIX = "BRPBT"
local LB_GET_DATA = "get data"
local LB_SET_ML = "ML set to "
local LB_SET_ROLL_TIME = "Roll time set to "

local function lb_print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|c" .. colors.ADDON_TEXT_COLOR .. "BRPBidHelper: " .. msg .. "|r")
end

local function resetRolls()
  state.rollMessages = {}
  state.rollers = {}
end

local function sortRolls()
  table.sort(state.rollMessages, function(a, b)
    -- Finally: sort by the actual roll descending.
    return a.bid > b.bid
  end)
end

-- local function formatMsg(message)
--   local msg = message.msg
--   local class = message.class
--   local classColor = RAID_CLASS_COLORS[class]
--   local textColor = colors.DEFAULT_TEXT_COLOR

--   local c_class = format("|c%s%-12s|r", classColor, message.bidder)
--   local c_end = ""

--   return format("%s|c%s%-3s%s|r", c_class, textColor, message.bid, c_end)
-- end

local function formatMsg(message)
  local msg = message.msg
  local class = message.class
  local classColor = RAID_CLASS_COLORS[class]
  local textColor = colors.DEFAULT_TEXT_COLOR

  local c_class = format("|c%s%s|r", classColor, message.bidder)
  local c_rank = message.bidderRank and format(" (%s)", message.bidderRank) or ""
  local c_note = message.note and format(" %s", message.note) or ""
  local c_bid = format(" |c%s%-3s|r", textColor, message.bid)

  return c_class .. c_rank .. c_note .. c_bid
end

local function tsize(t)
  c = 0
  for _ in pairs(t) do
    c = c + 1
  end
  if c > 0 then return c else return nil end
end

local function IsInRaid()
  return GetNumRaidMembers() > 0
end

local function IsInGroup()
  return GetNumPartyMembers() + GetNumRaidMembers() > 0
end

local function CheckItem(link)
  state.discover:SetOwner(UIParent, "ANCHOR_PRESERVE")
  state.discover:SetHyperlink(link)

  if discoverTextLeft1 and discoverTooltipTextLeft1:IsVisible() then
    local name = discoverTooltipTextLeft1:GetText()
    discoverTooltip:Hide()

    if name == (RETRIEVING_ITEM_INFO or "") then
      return false
    else
      return true
    end
  end
  return false
end

local function CreateCloseButton(frame)
  -- Add a close button
  local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  closeButton:SetWidth(32) -- Button size
  closeButton:SetHeight(32) -- Button size
  closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5) -- Position at the top right

  -- Set textures if you want to customize the appearance
  closeButton:SetNormalTexture("Interface/Buttons/UI-Panel-MinimizeButton-Up")
  closeButton:SetPushedTexture("Interface/Buttons/UI-Panel-MinimizeButton-Down")
  closeButton:SetHighlightTexture("Interface/Buttons/UI-Panel-MinimizeButton-Highlight")

  -- Hide the frame when the button is clicked
  closeButton:SetScript("OnClick", function()
      frame:Hide()
      resetRolls()
  end)
end

local function CreateActionButton(frame, buttonText, tooltipText, index, onClickAction)
  local panelWidth = frame:GetWidth()
  local spacing = (panelWidth - (BUTTON_COUNT * BUTTON_WIDTH)) / (BUTTON_COUNT + 1)
  local button = CreateFrame("Button", nil, frame, UIParent)
  button:SetWidth(BUTTON_WIDTH)
  button:SetHeight(BUTTON_WIDTH)
  button:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", index*spacing + (index-1)*BUTTON_WIDTH, BUTTON_PADING)

  -- Set button text
  button:SetText(buttonText)
  local font = button:GetFontString()
  font:SetFont(FONT_NAME, FONT_SIZE, FONT_OUTLINE)

  -- Add background 
  local bg = button:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(button)
  bg:SetTexture(1, 1, 1, 1) -- White texture
  bg:SetVertexColor(0.2, 0.2, 0.2, 1) -- Dark gray background

  button:SetScript("OnMouseDown", function(self)
      bg:SetVertexColor(0.6, 0.6, 0.6, 1) -- Even lighter gray when pressed
  end)

  button:SetScript("OnMouseUp", function(self)
      bg:SetVertexColor(0.4, 0.4, 0.4, 1) -- Lighter gray on release
  end)

  -- Add tooltip
  button:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
      GameTooltip:SetText(tooltipText, nil, nil, nil, nil, true)
      bg:SetVertexColor(0.4, 0.4, 0.4, 1) -- Lighter gray on hover
      GameTooltip:Show()
  end)

  button:SetScript("OnLeave", function(self)
      bg:SetVertexColor(0.2, 0.2, 0.2, 1) -- Dark gray when not hovered
      GameTooltip:Hide()
  end)

  -- Add functionality to the button
  button:SetScript("OnClick", function()
    onClickAction()
  end)
end

local function CreateActionButtonNaxx(frame, buttonText, tooltipText, index)
  local panelWidth = frame:GetWidth()
  local spacing = (panelWidth - (BUTTON_COUNT * BUTTON_WIDTH)) / (BUTTON_COUNT + 1)
  local button = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
  button:SetWidth(BUTTON_WIDTH)
  button:SetHeight(BUTTON_HEIGHT)
  button:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", index*spacing + (index-1)*BUTTON_WIDTH, BUTTON_PADING)

  -- Set button text
  button:SetText(buttonText)
  local font = button:GetFontString()
  font:SetFont(FONT_NAME, FONT_SIZE, FONT_OUTLINE)

  -- Add background 
  local bg = button:CreateTexture(nil, "BACKGROUND")
  -- bg:SetAllPoints(button)
  -- bg:SetTexture(1, 1, 1, 1) -- White texture
  -- bg:SetVertexColor(0.2, 0.2, 0.2, 1) -- Dark gray background

  button:SetScript("OnMouseDown", function(self)
      bg:SetVertexColor(0.6, 0.6, 0.6, 1) -- Even lighter gray when pressed
  end)

  button:SetScript("OnMouseUp", function(self)
      bg:SetVertexColor(0.4, 0.4, 0.4, 1) -- Lighter gray on release
  end)

  -- Add tooltip
  button:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
      GameTooltip:SetText(tooltipText, nil, nil, nil, nil, true)
      bg:SetVertexColor(0.4, 0.4, 0.4, 1) -- Lighter gray on hover
      GameTooltip:Show()
  end)

  button:SetScript("OnLeave", function(self)
      bg:SetVertexColor(0.2, 0.2, 0.2, 1) -- Dark gray when not hovered
      GameTooltip:Hide()
  end)

  -- Add functionality to the button
  button:SetScript("OnClick", function()
    StaticPopup_Show("CONFIRM_ALL_IN_NAXX")
  end)
end

local function CreateInputFrame(frame)
  local editBox = CreateFrame("EditBox", "MyAddonEditBox", frame, "InputBoxTemplate")
  editBox:SetWidth(110)
  editBox:SetHeight(32)
  editBox:SetPoint("BOTTOM", frame, "BOTTOM", -65, 45)  -- Position in the middle of the screen
  editBox:SetAutoFocus(false) -- Don't auto-focus
  editBox:SetText("10")

  -- Optional: Script handlers
  editBox:SetScript("OnEnterPressed", function()
    -- SendChatMessage(editBox:GetText(), "WHISPER", nil, state.masterLooter);
    editBox:ClearFocus()
  end)

  editBox:SetScript("OnHide", function()
    editBox:SetText("10")
  end)

  local button = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
  button:SetWidth(50)
  button:SetHeight(30)
  button:SetPoint("BOTTOM", frame, "BOTTOM", 37, 45)

  -- Set button text
  button:SetText("Bid")
  local font = button:GetFontString()
  font:SetFont(FONT_NAME, FONT_SIZE, FONT_OUTLINE)

  -- Add background 
  local bg = button:CreateTexture(nil, "BACKGROUND")

  button:SetScript("OnMouseDown", function(self)
      bg:SetVertexColor(0.6, 0.6, 0.6, 1) -- Even lighter gray when pressed
  end)

  button:SetScript("OnMouseUp", function(self)
      bg:SetVertexColor(0.4, 0.4, 0.4, 1) -- Lighter gray on release
  end)

  -- Add tooltip
  button:SetScript("OnEnter", function(self)
      bg:SetVertexColor(0.4, 0.4, 0.4, 1) -- Lighter gray on hover
  end)

  button:SetScript("OnLeave", function(self)
      bg:SetVertexColor(0.2, 0.2, 0.2, 1) -- Dark gray when not hovered
  end)

  -- Add functionality to the button
  button:SetScript("OnClick", function()
    SendChatMessage(editBox:GetText(), "WHISPER", nil, state.masterLooter);
  end)
end

--local function CreateActionButtonKara(frame, buttonText, tooltipText, index)
--  local panelWidth = frame:GetWidth()
--  local spacing = (panelWidth - (BUTTON_COUNT * BUTTON_WIDTH)) / (BUTTON_COUNT + 1)
--  local button = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
--  button:SetWidth(BUTTON_WIDTH)
--  button:SetHeight(BUTTON_HEIGHT)
--  button:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", index*spacing + (index-1)*BUTTON_WIDTH, BUTTON_PADING)

  -- Set button text
--  button:SetText(buttonText)
--  local font = button:GetFontString()
--  font:SetFont(FONT_NAME, FONT_SIZE, FONT_OUTLINE)

  -- Add background 
--  local bg = button:CreateTexture(nil, "BACKGROUND")
  -- bg:SetAllPoints(button)
  -- bg:SetTexture(1, 1, 1, 1) -- White texture
  -- bg:SetVertexColor(0.2, 0.2, 0.2, 1) -- Dark gray background

--  button:SetScript("OnMouseDown", function(self)
--      bg:SetVertexColor(0.6, 0.6, 0.6, 1) -- Even lighter gray when pressed
--  end)

--  button:SetScript("OnMouseUp", function(self)
 --     bg:SetVertexColor(0.4, 0.4, 0.4, 1) -- Lighter gray on release
--  end)

  -- Add tooltip
--  button:SetScript("OnEnter", function(self)
--      GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
--      GameTooltip:SetText(tooltipText, nil, nil, nil, nil, true)
--      bg:SetVertexColor(0.4, 0.4, 0.4, 1) -- Lighter gray on hover
--      GameTooltip:Show()
--  end)

--  button:SetScript("OnLeave", function(self)
--      bg:SetVertexColor(0.2, 0.2, 0.2, 1) -- Dark gray when not hovered
--      GameTooltip:Hide()
--  end)

  -- Add functionality to the button
--  button:SetScript("OnClick", function()
    -- SendChatMessage(state.kara, "WHISPER", nil, state.masterLooter);
--    StaticPopup_Show("CONFIRM_ALL_IN_KARA")
--  end)
--end

local function CreateItemRollFrame()
  local frame = CreateFrame("Frame", "ItemRollFrame", UIParent)
  frame:SetWidth(300) -- Adjust size as needed
  frame:SetHeight(220)
  frame:SetPoint("CENTER",UIParent,"CENTER",0,0) -- Position at center of the parent frame
  frame:SetBackdrop({
      bgFile = "Interface/Tooltips/UI-Tooltip-Background",
      edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
      tile = true, tileSize = 16, edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 }
  })
  frame:SetBackdropColor(0, 0, 0, 1) -- Black background with full opacity

  frame:SetMovable(true)
  frame:EnableMouse(true)

  frame:RegisterForDrag("LeftButton") -- Only start dragging with the left mouse button
  frame:SetScript("OnDragStart", function () frame:StartMoving() end)
  frame:SetScript("OnDragStop", function () frame:StopMovingOrSizing() end)
  CreateCloseButton(frame)
  CreateInputFrame(frame)
  CreateActionButtonNaxx(frame, "ALL IN", "BCE HA KRACHOE!!!", 1)
--  CreateActionButtonKara(frame, "ALL IN KARA", "Bid ALL IN KARA DKP", 2)
  frame:Hide()

  return frame
end

local itemRollFrame = CreateItemRollFrame()

local function InitItemInfo(frame)
  -- Create the texture for the item icon
  local icon = frame:CreateTexture()
  icon:SetWidth(40) -- Size of the icon
  icon:SetHeight(40) -- Size of the icon
  icon:SetPoint("TOP", frame, "TOP", 0, -10)

  -- Create a button for mouse interaction
  local iconButton = CreateFrame("Button", nil, frame)
  iconButton:SetWidth(40) -- Size of the icon
  iconButton:SetHeight(40) -- Size of the icon
  iconButton:SetPoint("TOP", frame, "TOP", 0, -10)

  -- Create a FontString for the frame hide timer
  local timerText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  timerText:SetPoint("CENTER", frame, "TOPLEFT", 30, -32)
  timerText:SetFont(timerText:GetFont(), 20)

  -- Create a FontString for the item name
  local name = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  name:SetPoint("TOP", icon, "BOTTOM", 0, -2)

  frame.icon = icon
  frame.iconButton = iconButton
  frame.timerText = timerText
  frame.name = name
  frame.itemLink = ""

  local tt = CreateFrame("GameTooltip", "CustomTooltip2", UIParent, "GameTooltipTemplate")

  -- Set up tooltip
  iconButton:SetScript("OnEnter", function()
    tt:SetOwner(iconButton, "ANCHOR_RIGHT")
    tt:SetHyperlink(frame.itemLink)
    tt:Show()
  end)
  iconButton:SetScript("OnLeave", function()
    tt:Hide()
  end)
  iconButton:SetScript("OnClick", function()
    if ( IsControlKeyDown() ) then
      DressUpItemLink(frame.itemLink);
    elseif ( IsShiftKeyDown() and ChatFrameEditBox:IsVisible() ) then
      local itemName, itemLink, itemQuality, _, _, _, _, _, itemIcon = GetItemInfo(frame.itemLink)
      ChatFrameEditBox:Insert(ITEM_QUALITY_COLORS[itemQuality].hex.."\124H"..itemLink.."\124h["..itemName.."]\124h"..FONT_COLOR_CODE_CLOSE);
    end
  end)
end

-- Function to return colored text based on item quality
local function GetColoredTextByQuality(text, qualityIndex)
  -- Get the color associated with the item quality
  local r, g, b, hex = GetItemQualityColor(qualityIndex)
  -- Return the text wrapped in WoW's color formatting
  return string.format("%s%s|r", hex, text)
end

local function SetItemInfo(frame, itemLinkArg)
  local itemName, itemLink, itemQuality, _, _, _, _, _, itemIcon = GetItemInfo(itemLinkArg)
  if not frame.icon then InitItemInfo(frame) end

  -- if we know the item, and the quality isn't green+, don't show it
  if itemName and itemQuality < 2 then return false end
  if not itemIcon then
    frame.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    frame.name:SetText("Unknown item, attempting to query...")
    -- could be an item we want to see, try to show it
    return true
  end

  frame.icon:SetTexture(itemIcon)
  frame.iconButton:SetNormalTexture(itemIcon)  -- Sets the same texture as the icon

  frame.name:SetText(GetColoredTextByQuality(itemName,itemQuality))

  frame.itemLink = itemLink
  return true
end

local function ShowFrame(frame,duration,item)
  frame:SetScript("OnUpdate", function()
    state.time_elapsed = state.time_elapsed + arg1
    state.item_query = state.item_query - arg1
    local delta = duration - state.time_elapsed
    if frame.timerText then frame.timerText:SetText(format("%.1f", delta > 0 and delta or 0)) end
    if state.time_elapsed >= max(duration,FrameShownDuration) then
      frame.timerText:SetText("0.0")
      frame:SetScript("OnUpdate", nil)
      state.time_elapsed = 0
      state.item_query = 1.5
      state.times = 3
      rollMessages = {}
      state.isRolling = false
      if FrameAutoClose and not (state.masterLooter == UnitName("player")) then frame:Hide() end
    end
    if state.times > 0 and state.item_query < 0 and not CheckItem(item) then
      state.times = state.times - 1
    else
      if not SetItemInfo(itemRollFrame,item) then frame:Hide() end
      state.times = 5
    end
  end)
  frame:Show()
end

local function CreateTextArea(frame)
  local textArea = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  textArea:SetFont("Interface\\AddOns\\BRPBidHelper\\MonaspaceNeonFrozen-Regular.ttf", 12, "")
  textArea:SetHeight(100)
  -- textArea:SetWidth(150)
  textArea:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -70)
  textArea:SetJustifyH("LEFT")
  textArea:SetJustifyV("TOP")

  return textArea
end

local function GetClassOfRoller(rollerName)
  -- Iterate through the raid roster
  for i = 1, GetNumRaidMembers() do
      local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i)
      if name == rollerName then
          return class -- Return the class as a string (e.g., "Warrior", "Mage")
      end
  end
  return nil -- Return nil if the player is not found in the raid
end

local function UpdateTextArea(frame)
  if not frame.textArea then
    frame.textArea = CreateTextArea(frame)
  end

  text = "Current Master Looter: " .. state.masterLooter .. "\n" .. "\n"
  local bidderRank, note = getPlayerRank(UnitName("player"))

  local _,_,ep = string.find(note,".*{(%d+):%d+}.*")
  local _,_,gp = string.find(note,".*{%d+:(%d+)}.*")
  state.naxx = ep
  state.kara = gp
  
  text = text .. "Your Rank: " .. bidderRank .. "\n"
  text = text .. "Tekushee DKP: " .. ep .. "\n"
  text = text .. "Next Raid DKP: " .. gp

  -- local colored_msg = ""
  -- local count = 0

  -- sortRolls()

  -- for i, v in ipairs(state.rollMessages) do
  --   -- if count >= 9 then break end
  --   colored_msg = v.msg
  --   text = text .. formatMsg(v) .. "\n"
  --   count = count + 1
  -- end

  frame.textArea:SetText(text)
end

local function ExtractItemLinksFromMessage(message)
  local itemLinks = {}
  -- This pattern matches the standard item link structure in WoW
  for link in string.gfind(message, "|c.-|H(item:.-)|h.-|h|r") do
    table.insert(itemLinks, link)
  end
  return itemLinks
end

-- this isn't quite right, should just check if you are ML, since it can only check you and your party anyway rather than the whole raid
local function IsSenderMasterLooter(sender)
  local lootMethod, masterLooterPartyID = GetLootMethod()
  if lootMethod == "master" and masterLooterPartyID then
    if masterLooterPartyID == 0 then
      return sender == UnitName("player")
    else
      local senderUID = "party" .. masterLooterPartyID
      local masterLooterName = UnitName(senderUID)
      return masterLooterName == sender
    end
  end
  return false
end

local function GetMasterLooterInParty()
  local lootMethod, masterLooterPartyID = GetLootMethod()
  if lootMethod == "master" and masterLooterPartyID then
    if masterLooterPartyID == 0 then
      return UnitName("player")
    else
      local senderUID = "party" .. masterLooterPartyID
      local masterLooterName = UnitName(senderUID)
      return masterLooterName
    end
  end
  return nil
end

-- todo, test this
local function PlayerIsML()
  local lootMethod, masterLooterPartyID = GetLootMethod()
  return lootMethod == "master" and masterLooterPartyID and (masterLooterPartyID == 0)
end

local pendingRequest, requestDelay = false, 0
local pendingSet, setDelay, setName = false, 0.5, ""
local function RequestML(delay)
  pendingRequest = true
  requestDelay   = delay or 3.0
end

local delayFrame = CreateFrame("Frame")
delayFrame:SetScript("OnUpdate", function()
  local elapsed = arg1
  if pendingRequest then
    requestDelay = requestDelay - elapsed
    if requestDelay<=0 then
      pendingRequest = false
      -- if IsInGroup() then
      SendAddonMessage(LB_PREFIX, LB_GET_DATA, GetNumRaidMembers() > 0 and "RAID" or "PARTY")
      -- end
    end
  end
  if pendingSet then
    setDelay = setDelay - elapsed
    if setDelay<=0 then
      pendingSet = false
      setDelay = 0.5

      if not state.masterLooter or (state.masterLooter and (state.masterLooter ~= setName)) then
        lb_print("Masterlooter set to |cFF00FF00" .. setName .. "|r")
      end
      state.masterLooter = setName
    end
  end
end)

function itemRollFrame:CHAT_MSG_LOOT(message)
  -- Hide frame for masterlooter when loot is awarded
  if not ItemRollFrame:IsVisible() or state.masterLooter ~= UnitName("player") then return end

  local _,_,who = string.find(message, "^(%a+) receive.? loot:")
  local links = ExtractItemLinksFromMessage(message)

  if who and tsize(links) == 1 then
    if this.itemLink == links[1] then
      resetRolls()
      this:Hide()
    end
  end
end

function itemRollFrame:CHAT_MSG_SYSTEM(message)
  -- detect ML announcements
  local _,_, newML = string.find(message,"(.+) is now the loot master")
  if newML then
    -- state.masterLooter = newML
    -- lb_print("Master looter set to "..newML)
    itemRollFrame:SendML(newML)
    return
  end
  -- if state.isRolling and string.find(message, "rolls") and string.find(message, "(%d+)") then
  --   local _,_,roller, roll, minRoll, maxRoll = string.find(message, "(%S+) rolls (%d+) %((%d+)%-(%d+)%)")
  --   if roller and roll and (state.rollers[roller] == nil or LB_DEBUG) then
  --     roll = tonumber(roll)
  --     minRoll = tonumber(minRoll)
  --     maxRoll = tonumber(maxRoll)
  --     state.rollers[roller] = 1
  --     message = { roller = roller, roll = roll, minRoll = minRoll, maxRoll = maxRoll, msg = message, class = GetClassOfRoller(roller) }

  --     table.insert(state.rollMessages, message)
  --     UpdateTextArea(itemRollFrame)
  --   end
  -- end
end

function itemRollFrame:CHAT_MSG_RAID_WARNING(message,sender)
  if sender ~= state.masterLooter then return end

  local links = ExtractItemLinksFromMessage(message)
  if tsize(links) == 1 then
    -- interaction with other looting addons
    if string.find(message, "^No one has nee") or
      -- prevents reblaring on loot award
      string.find(message,"has been sent to") or
      string.find(message, " received ") then
      return
    end
    resetRolls()
    UpdateTextArea(itemRollFrame)
    state.time_elapsed = 0
    state.isRolling = true
    ShowFrame(itemRollFrame,state.MLRollDuration,links[1])
  end
end

function itemRollFrame:SendML(masterlooter)
  if not masterlooter then return end

  local chan = GetNumRaidMembers() > 0 and "RAID" or "PARTY"
  -- send the chosen ML
  SendAddonMessage(LB_PREFIX,LB_SET_ML .. masterlooter,chan)
  -- send time if we're the chosen ML
  if masterLooter == UnitName("player") then
    SendAddonMessage(LB_PREFIX,LB_SET_ROLL_TIME .. FrameShownDuration,chan)
  end
end

-- todo why is lootblare sending stale info when I personally change the ML
function itemRollFrame:CHAT_MSG_ADDON(prefix,message,channel,sender)
  local player = UnitName("player")

  -- Someone is asking for the master looter and his roll time
  if message == LB_GET_DATA then
    self:SendML(GetMasterLooterInParty())
  end

  -- Someone is setting the master looter
  if string.find(message, LB_SET_ML) then
    if GetLootMethod() ~= "master" then return end
    local _,_, newML = string.find(message, "ML set to (%S+)")
    if newML then
      pendingSet = true
      setName = newML
    end
    return
  end

  -- Someone is setting the roll time
  if string.find(message, LB_SET_ROLL_TIME) then
    local _,_,duration = string.find(message, "Roll time set to (%d+)")
    duration = tonumber(duration)
    if duration and duration ~= state.MLRollDuration then
      state.MLRollDuration = duration
      if not IsSenderMasterLooter(player) then
        local roll_string = "Roll time set to " .. state.MLRollDuration .. " seconds by Master Looter."
        if state.MLRollDuration ~= FrameShownDuration then
          roll_string = roll_string .. " Your display time is " .. FrameShownDuration .." seconds."
        end
        lb_print(roll_string)
      end
    end
    return
  end
end

function itemRollFrame:RAID_ROSTER_UPDATE()
  RequestML(0.5)
end

function itemRollFrame:PARTY_MEMBERS_CHANGED()
  RequestML(0.5)
end

function itemRollFrame:PLAYER_ENTERING_WORLD()
  RequestML(8)
end

function itemRollFrame:PARTY_LOOT_METHOD_CHANGED()
  RequestML(0.5)
end

function is_number(str)
  return tonumber(str) ~= nil
end

function getPlayerRank(playerName)
  for i = 1, GetNumGuildMembers() do
    local name, rankName, rankIndex, _, _, _, _, note = GetGuildRosterInfo(i)

    if name == playerName then
      return rankName, note
    end
  end
  return "none", "{}"
end

-- function itemRollFrame:CHAT_MSG_WHISPER(message,sender)
--   if is_number(message) then
--     local bid = tonumber(message)
--     local bidder = sender
--     local bidderRank, note = getPlayerRank(bidder)
    
--     -- local unit = GetUnit(bidder)
--     -- lb_print(unit)
--     -- if unit == "none" then return end

--     -- local guild, rankstr, rankid = GetGuildInfo(bidder)
--     -- lb_print(rankstr)

--     local msg = { bidder = bidder, bid = bid, msg = message, class = GetClassOfRoller(bidder), bidderRank = bidderRank, note = note }

--     table.insert(state.rollMessages, msg)

--     UpdateTextArea(itemRollFrame)
--   end
-- end

function itemRollFrame:ADDON_LOADED(addon)
  if addon ~= "BRPBidHelper" then return end
 
  if FrameShownDuration == nil then FrameShownDuration = 30 end
  if FrameAutoClose == nil then FrameAutoClose = true end
  -- state.MLRollDuration = FrameShownDuration
end

itemRollFrame:RegisterEvent("ADDON_LOADED")
itemRollFrame:RegisterEvent("CHAT_MSG_SYSTEM")
itemRollFrame:RegisterEvent("CHAT_MSG_RAID_WARNING")
-- itemRollFrame:RegisterEvent("CHAT_MSG_RAID")
-- itemRollFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
itemRollFrame:RegisterEvent("CHAT_MSG_ADDON")
itemRollFrame:RegisterEvent("CHAT_MSG_LOOT")
itemRollFrame:RegisterEvent("RAID_ROSTER_UPDATE")
itemRollFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
itemRollFrame:RegisterEvent("PARTY_LOOT_METHOD_CHANGED")
itemRollFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
-- itemRollFrame:RegisterEvent("CHAT_MSG_WHISPER")

-- itemRollFrame:SetScript("OnEvent", function () HandleChatMessage(event,arg1,arg2) end)
itemRollFrame:SetScript("OnEvent", function ()
  itemRollFrame[event](itemRollFrame,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9)
end)
