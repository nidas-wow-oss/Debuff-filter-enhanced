local DebuffFilterOptions = {};
-- settings for the current player
local DebuffFilter_PlayerConfig;

-- list of debuffs/buffs, used to display in options screen
DebuffFilterOptions.items = {};

-- prefix for string needed to grab proper list of debuffs/buffs
DebuffFilterOptions.target = "";
-- suffix for string needed to grab proper list of debuffs/buffs
DebuffFilterOptions.type = "debuff";

DebuffFilterOptions.Frames = DebuffFilterFrames;

-- direction that debuffs/buffs are positioned
DebuffFilterOptions.LayoutTable = {
	rightdown = {1, "Right-Down"},
	rightup = {2, "Right-Up"},
	leftdown = {3, "Left-Down"},
	leftup = {4, "Left-Up"},
}

-- debuff/buff that is selected in options screen
DebuffFilterOptions_Selection = "";

function DebuffFilterOptions_Initialize()
	-- DebuffFilter_Player is a global variable taken from DebuffFilter.lua
	DebuffFilter_PlayerConfig = DebuffFilter_Config[DebuffFilter_Player];

	UIPanelWindows["DebuffFilterOptionsFrame"] = {area = "center", pushable = 0, whileDead = 1}
	DebuffFilterOptions_UpdateItems();
	DebuffFilterOptions_Title:SetText("Debuff Filter " .. GetAddOnMetadata("DebuffFilter", "Version"));
end

function DebuffFilterOptions_TargetDropDown_OnLoad(self)
	UIDropDownMenu_Initialize(self, DebuffFilterOptions_TargetDropDown_Initialize);
	UIDropDownMenu_SetSelectedID(self, 1);
	UIDropDownMenu_SetWidth(self, 72);

	self.tooltipText = DFILTER_OPTIONS_TARGET_TOOLTIP;
end

function DebuffFilterOptions_TargetDropDown_Initialize()
	local info = {};
	info.text = "Target";
	info.value = "";
	info.func = DebuffFilterOptions_TargetDropDown_OnClick;
	UIDropDownMenu_AddButton(info);

	info.checked = nil;
	info.text = "Player";
	info.value = "p";
	info.func = DebuffFilterOptions_TargetDropDown_OnClick;
	UIDropDownMenu_AddButton(info);

	info.checked = nil;
	info.text = "Focus";
	info.value = "f";
	info.func = DebuffFilterOptions_TargetDropDown_OnClick;
	UIDropDownMenu_AddButton(info);
end

function DebuffFilterOptions_TargetDropDown_OnClick(self)
	UIDropDownMenu_SetSelectedID(DebuffFilterOptions_TargetDropDown, self:GetID());
	DebuffFilterOptions.target = self.value;

	-- dont show self applied option if debuffs/buffs on self are shown
	if (self.value ~= "p") then
		DebuffFilterOptions_CheckButtonSelfApplied:Show();
	else
		DebuffFilterOptions_CheckButtonSelfApplied:Hide();
	end

	DebuffFilterOptions_ClearSelection();
end

function DebuffFilterOptions_GrowDropDown_OnLoad(self)
	UIDropDownMenu_Initialize(self, DebuffFilterOptions_GrowDropDown_Initialize);
	UIDropDownMenu_SetWidth(self, 102);

	self.tooltipText = DFILTER_OPTIONS_GROW_TOOLTIP;
end

-- direction that debuffs/buffs are positioned
function DebuffFilterOptions_GrowDropDown_Initialize()
	local info = {};
	info.text = "Right-Down";
	info.value = "rightdown";
	info.func = DebuffFilterOptions_GrowDropDown_OnClick;
	UIDropDownMenu_AddButton(info);

	info.checked = nil;
	info.text = "Right-Up";
	info.value = "rightup";
	info.func = DebuffFilterOptions_GrowDropDown_OnClick;
	UIDropDownMenu_AddButton(info);

	info.checked = nil;
	info.text = "Left-Down";
	info.value = "leftdown";
	info.func = DebuffFilterOptions_GrowDropDown_OnClick;
	UIDropDownMenu_AddButton(info);

	info.checked = nil;
	info.text = "Left-Up";
	info.value = "leftup";
	info.func = DebuffFilterOptions_GrowDropDown_OnClick;
	UIDropDownMenu_AddButton(info);
end

function DebuffFilterOptions_GrowDropDown_OnClick(self)
	DebuffFilterOptions_ModifyLayout("grow", self.value, self:GetID());
end

function DebuffFilterOptions_Tab_OnClick(type)
	DebuffFilterOptions.type = type;

	DebuffFilterOptions_ClearSelection();
end

-- taken from bongos
function DebuffFilterOptions_SetScale(scale)
	local ratio, x, y;

	DebuffFilter_PlayerConfig.scale = scale;
	ratio = DebuffFilterFrame:GetScale() / scale

	for k in pairs(DebuffFilterOptions.Frames) do
		x, y = _G[k]:GetLeft() * ratio, _G[k]:GetTop() * ratio;
		_G[k]:ClearAllPoints();
		_G[k]:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y);
	end

	DebuffFilterFrame:SetScale(scale);
end

function DebuffFilterOptions_UpdateItems()
	for k in pairs(DebuffFilterOptions.items) do
		DebuffFilterOptions.items[k] = nil;
	end

	local targettype = DebuffFilterOptions.target .. DebuffFilterOptions.type;

	DebuffFilterOptions.list = targettype .. "_list";
	DebuffFilterOptions.layout = targettype .. "_layout";

	for k in pairs(DebuffFilter_PlayerConfig[DebuffFilterOptions.list]) do
		table.insert(DebuffFilterOptions.items, k);
	end

	table.sort(DebuffFilterOptions.items);
	DebuffFilterOptions.count = #DebuffFilterOptions.items;
end

-- update list of debuffs/buffs and highlight the current selection
function DebuffFilterOptions_ScrollFrame_Update()
	local button, name;

	local offset = FauxScrollFrame_GetOffset(DebuffFilterOptions_ScrollFrame);
	FauxScrollFrame_Update(DebuffFilterOptions_ScrollFrame, DebuffFilterOptions.count, 14, 16);

	for i = 1, 14 do
		button = _G["DebuffFilterOptions_Item" .. i];

		if (DebuffFilterOptions.count >= i + offset) then
			name = DebuffFilterOptions.items[i + offset];

			if (name == DebuffFilterOptions_Selection) then
				button:LockHighlight();
			else
				button:UnlockHighlight();
			end

			button:SetText(name);
			button:GetFontString():SetTextColor(1.0, 0.82, 0.0);
			button:Show();
		else
			button:Hide();
		end
	end
end

function DebuffFilterOptions_ModifyLayout(type, value, id)
	if (type == "grow") then
		DebuffFilter_PlayerConfig[DebuffFilterOptions.layout].grow = value;
		UIDropDownMenu_SetSelectedID(DebuffFilterOptions_GrowDropDown, id);
	else
		DebuffFilter_PlayerConfig[DebuffFilterOptions.layout].per_row = value;
	end

	for k, v in pairs(DebuffFilterOptions.Frames) do
		if (v.list_key == DebuffFilterOptions.list) then
			DebuffFilter_UpdateLayout(k);
			
			break;
		end
	end
end

function DebuffFilterOptions_ModifyList(arg)
	local item = DebuffFilterOptions_EditBox:GetText();
	local texture = DebuffFilterOptions_EditBox2:GetText();
	local selfapplied = DebuffFilterOptions_CheckButtonSelfApplied:GetChecked();
	local dontcombine = DebuffFilterOptions_CheckButtonDontCombine:GetChecked();

	if (item ~= "") then
		-- add debuff/buff
		if (arg == "add") then
			DebuffFilter_PlayerConfig[DebuffFilterOptions.list][item] = {};
			DebuffFilter_PlayerConfig[DebuffFilterOptions.list][item].selfapplied = selfapplied;
			DebuffFilter_PlayerConfig[DebuffFilterOptions.list][item].dontcombine = dontcombine;

			if (texture ~= "") then
				DebuffFilter_PlayerConfig[DebuffFilterOptions.list][item].texture = texture;
			else
				DebuffFilter_PlayerConfig[DebuffFilterOptions.list][item].texture = nil;
			end

			DebuffFilterOptions_ClearSelection();
		elseif (arg == "selfapplied" or arg == "dontcombine") then
			if (DebuffFilter_PlayerConfig[DebuffFilterOptions.list][item]) then
				DebuffFilter_PlayerConfig[DebuffFilterOptions.list][item].selfapplied = selfapplied;
				DebuffFilter_PlayerConfig[DebuffFilterOptions.list][item].dontcombine = dontcombine;
			end
		else
			DebuffFilter_PlayerConfig[DebuffFilterOptions.list][item] = nil;

			DebuffFilterOptions_ClearSelection();
		end

		-- update the frame for the current list of debuffs/buffs
		for k, v in pairs(DebuffFilterOptions.Frames) do
			if (v.list_key == DebuffFilterOptions.list) then
				DebuffFilter_Frame_Update(k);
				
				break;
			end
		end
	else
		DebuffFilterOptions_ClearSelection();
	end
end

-- clear everything except for checkboxes in settings, and refresh lots of stuff
function DebuffFilterOptions_ClearSelection()
	DebuffFilterOptions_Selection = "";
	DebuffFilterOptions_EditBox:SetText("");
	DebuffFilterOptions_EditBox2:SetText("");
	DebuffFilterOptions_CheckButtonSelfApplied:SetChecked(0);
	DebuffFilterOptions_CheckButtonDontCombine:SetChecked(0);

	DebuffFilterOptions_ScrollFrameScrollBar:SetValue(0);
	DebuffFilterOptions_UpdateItems();
	DebuffFilterOptions_ScrollFrame_Update();

	DebuffFilterOptions_GetLayout();
end

-- display number of debuffs/buffs per row, how they are positioned, and per-frame scale
function DebuffFilterOptions_GetLayout()
	local grow = DebuffFilter_PlayerConfig[DebuffFilterOptions.layout].grow;

	UIDropDownMenu_SetSelectedID(DebuffFilterOptions_GrowDropDown, DebuffFilterOptions.LayoutTable[grow][1]);
	UIDropDownMenu_SetText(DebuffFilterOptions_GrowDropDown, DebuffFilterOptions.LayoutTable[grow][2]);

	DebuffFilterOptions_RowSlider:SetValue(DebuffFilter_PlayerConfig[DebuffFilterOptions.layout].per_row);

	-- update per-frame scale slider
	local frame_scale = DebuffFilter_PlayerConfig[DebuffFilterOptions.layout].scale or 1.0;
	DebuffFilterOptions_FrameScaleSlider:SetValue(frame_scale);
	_G[DebuffFilterOptions_FrameScaleSlider:GetName() .. "Text"]:SetText(DFILTER_OPTIONS_FRAME_SCALE .. " (" .. string.format("%.2f", frame_scale) .. ")");
end

-- modify per-frame scale for the currently selected target/type
function DebuffFilterOptions_ModifyFrameScale(scale)
	DebuffFilter_PlayerConfig[DebuffFilterOptions.layout].scale = scale;

	for k, v in pairs(DebuffFilterOptions.Frames) do
		if (v.layout_key == DebuffFilterOptions.layout) then
			DebuffFilter_ApplyFrameScale(k, scale);
			break;
		end
	end
end

function DebuffFilterOptions_GetOptions(item)
	DebuffFilterOptions_CheckButtonSelfApplied:SetChecked(DebuffFilter_PlayerConfig[DebuffFilterOptions.list][item].selfapplied);
	DebuffFilterOptions_CheckButtonDontCombine:SetChecked(DebuffFilter_PlayerConfig[DebuffFilterOptions.list][item].dontcombine);
	DebuffFilterOptions_EditBox2:SetText(DebuffFilter_PlayerConfig[DebuffFilterOptions.list][item].texture or "");
end

----------------------------------------------------------------------
-- Serializer: table <-> copyable string
----------------------------------------------------------------------
local function DebuffFilter_SerializeValue(val)
	local t = type(val);
	if t == "string" then
		return string.format("%q", val);
	elseif t == "number" then
		return tostring(val);
	elseif t == "boolean" then
		return val and "true" or "false";
	elseif t == "table" then
		local parts = {};
		for k, v in pairs(val) do
			local key;
			if type(k) == "string" then
				key = "[" .. string.format("%q", k) .. "]";
			else
				key = "[" .. tostring(k) .. "]";
			end
			table.insert(parts, key .. "=" .. DebuffFilter_SerializeValue(v));
		end
		return "{" .. table.concat(parts, ",") .. "}";
	else
		return "nil";
	end
end

local function DebuffFilter_Serialize(tbl)
	return "return " .. DebuffFilter_SerializeValue(tbl);
end

local function DebuffFilter_Deserialize(str)
	if not str or str == "" then return nil, "Empty string" end
	local func, err = loadstring(str);
	if not func then return nil, err end
	setfenv(func, {});
	local ok, result = pcall(func);
	if not ok then return nil, result end
	if type(result) ~= "table" then return nil, "Invalid data" end
	return result;
end

----------------------------------------------------------------------
-- Profiles: copy config from another character on same account
----------------------------------------------------------------------
function DebuffFilterOptions_ProfileDropDown_OnLoad(self)
	UIDropDownMenu_Initialize(self, DebuffFilterOptions_ProfileDropDown_Initialize);
	UIDropDownMenu_SetWidth(self, 150);
	self.tooltipText = DFILTER_OPTIONS_PROFILE_TOOLTIP;
end

function DebuffFilterOptions_ProfileDropDown_Initialize()
	if not DebuffFilter_Config then return end
	local info;
	for name, _ in pairs(DebuffFilter_Config) do
		if name ~= DebuffFilter_Player then
			info = {};
			info.text = name;
			info.value = name;
			info.func = DebuffFilterOptions_ProfileDropDown_OnClick;
			UIDropDownMenu_AddButton(info);
		end
	end
end

function DebuffFilterOptions_ProfileDropDown_OnClick(self)
	UIDropDownMenu_SetSelectedValue(DebuffFilterOptions_ProfileDropDown, self.value);
	UIDropDownMenu_SetText(DebuffFilterOptions_ProfileDropDown, self.value);
	DebuffFilterOptions.selectedProfile = self.value;
end

function DebuffFilterOptions_CopyProfile()
	local source = DebuffFilterOptions.selectedProfile;
	if not source or not DebuffFilter_Config[source] then
		DebuffFilter_Print(DFILTER_PROFILE_NO_SELECT);
		return;
	end

	for k, v in pairs(DebuffFilter_Config[source]) do
		DebuffFilter_Config[DebuffFilter_Player][k] = DebuffFilter_DeepCopy(v);
	end

	DebuffFilter_Print(DFILTER_PROFILE_COPIED .. source);
	ReloadUI();
end

----------------------------------------------------------------------
-- Export: serialize current config to copyable text
----------------------------------------------------------------------
function DebuffFilterOptions_Export()
	local data = DebuffFilter_Serialize(DebuffFilter_Config[DebuffFilter_Player]);

	DebuffFilterOptions_ImportExportFrame:Show();
	DebuffFilterOptions_ImportExportTitle:SetText(DFILTER_EXPORT_TITLE);
	DebuffFilterOptions_ImportExportEditBox:SetText(data);
	DebuffFilterOptions_ImportExportEditBox:HighlightText();
	DebuffFilterOptions_ImportExportEditBox:SetFocus();
	DebuffFilterOptions_ImportExportButton:Hide();
end

----------------------------------------------------------------------
-- Import: paste text to overwrite current config
----------------------------------------------------------------------
function DebuffFilterOptions_ShowImport()
	DebuffFilterOptions_ImportExportFrame:Show();
	DebuffFilterOptions_ImportExportTitle:SetText(DFILTER_IMPORT_TITLE);
	DebuffFilterOptions_ImportExportEditBox:SetText("");
	DebuffFilterOptions_ImportExportEditBox:SetFocus();
	DebuffFilterOptions_ImportExportButton:SetText(DFILTER_IMPORT_BUTTON);
	DebuffFilterOptions_ImportExportButton:Show();
end

function DebuffFilterOptions_DoImport()
	local text = DebuffFilterOptions_ImportExportEditBox:GetText();
	local data, err = DebuffFilter_Deserialize(text);

	if not data then
		DebuffFilter_Print(DFILTER_IMPORT_ERROR .. (err or ""));
		return;
	end

	for k, v in pairs(data) do
		DebuffFilter_Config[DebuffFilter_Player][k] = v;
	end

	DebuffFilter_Print(DFILTER_IMPORT_SUCCESS);
	DebuffFilterOptions_ImportExportFrame:Hide();
	ReloadUI();
end
----------------------------------------------------------------------
-- ArcaneBlue theme — applied every time the panel is shown
----------------------------------------------------------------------
function DebuffFilterOptions_ApplyArcaneTheme()
	local f = DebuffFilterOptionsFrame;

	-- Main panel
	f:SetBackdrop({
		bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile     = true, tileSize = 16, edgeSize = 16,
		insets   = {left=5, right=5, top=5, bottom=5},
	});
	f:SetBackdropColor(0.028, 0.048, 0.095, 0.97);
	f:SetBackdropBorderColor(0.22, 0.52, 0.92, 0.95);

	-- Title box: narrow frame protruding above the panel top edge (exact EnemyCooldowns style)
	-- Create once only
	if not DebuffFilterOptions_TitleBox then
		local box = CreateFrame("Frame", "DebuffFilterOptions_TitleBox", DebuffFilterOptionsFrame);
		box:SetWidth(260);
		box:SetHeight(36);
		box:SetPoint("BOTTOM", DebuffFilterOptionsFrame, "TOP", 0, -20);
		box:SetFrameLevel(DebuffFilterOptionsFrame:GetFrameLevel() + 5);
		box:SetBackdrop({
			bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true, tileSize = 16, edgeSize = 16,
			insets = {left=4, right=4, top=4, bottom=4},
		});
		box:SetBackdropColor(0.035, 0.065, 0.140, 1.0);
		box:SetBackdropBorderColor(0.28, 0.68, 1.0, 1.0);

		-- Create a NEW FontString parented to the box itself so it always renders on top
		local fs = box:CreateFontString("DebuffFilterOptions_TitleFS", "OVERLAY", "GameFontNormalLarge");
		fs:SetPoint("CENTER", box, "CENTER", 0, 0);
		fs:SetTextColor(1.0, 0.82, 0.0);
		fs:SetShadowColor(0.0, 0.0, 0.0, 1.0);
		fs:SetShadowOffset(1, -1);
		fs:SetText("Debuff Filter " .. GetAddOnMetadata("DebuffFilter", "Version"));
	end

	-- Hide the original XML FontString so it doesn't conflict
	DebuffFilterOptions_Title:Hide();

	-- Hide the flat texture strip
	if DebuffFilterOptions_TitleBG then
		DebuffFilterOptions_TitleBG:Hide();
	end

	-- List area: background and scrollbar repositioned to far right
	if not DebuffFilterOptions_ListBG then
		local bg = DebuffFilterOptions_ListFrame:CreateTexture("DebuffFilterOptions_ListBG", "BACKGROUND");
		bg:SetPoint("TOPLEFT", DebuffFilterOptions_ListFrame, "TOPLEFT", 5, -5);
		bg:SetPoint("BOTTOMRIGHT", DebuffFilterOptions_ListFrame, "BOTTOMRIGHT", -5, 5);
		bg:SetTexture(0.04, 0.08, 0.16, 0.85);
	end

	-- Move scrollbar to the far right edge of the ListFrame
	local sb = DebuffFilterOptions_ScrollFrameScrollBar;
	if sb then
		sb:ClearAllPoints();
		sb:SetPoint("TOPRIGHT", DebuffFilterOptions_ListFrame, "TOPRIGHT", -4, -18);
		sb:SetPoint("BOTTOMRIGHT", DebuffFilterOptions_ListFrame, "BOTTOMRIGHT", -4, 18);
	end
	local sliders = {
		"DebuffFilterOptions_RowSlider",
		"DebuffFilterOptions_FrameScaleSlider",
		"DebuffFilterOptions_Slider1",
	};
	for _, name in ipairs(sliders) do
		local sl = _G[name];
		if sl then
			_G[name .. "Text"]:SetTextColor(0.55, 0.80, 1.0);
			_G[name .. "Low"]:SetTextColor(0.30, 0.50, 0.75);
			_G[name .. "High"]:SetTextColor(0.30, 0.50, 0.75);
		end
	end

	-- EditBox label colors (the FontStrings above the boxes)
	-- They are anonymous children; we color by iterating regions of the editboxes
	local function colorRegions(frame)
		for _, region in ipairs({frame:GetRegions()}) do
			if region:GetObjectType() == "FontString" then
				region:SetTextColor(0.30, 0.55, 0.85);
			end
		end
	end
	colorRegions(DebuffFilterOptions_EditBox);
	colorRegions(DebuffFilterOptions_EditBox2);
end