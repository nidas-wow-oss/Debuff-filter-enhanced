local DebuffFilter_DefaultSettings = {
	debuffs = false,
	buffs = true,
	pdebuffs = false,
	pbuffs = true,
	fdebuffs = false,
	fbuffs = false,
	scale = 2.50,
	debuff_layout = {grow="rightdown", per_row=8, time_tb="bottom", time_lr="right", scale=1.0},
	buff_layout = {grow="rightdown", per_row=8, time_tb="bottom", time_lr="right", scale=1.0},
	pdebuff_layout = {grow="leftdown", per_row=8, time_tb="bottom", time_lr="right", scale=1.0},
	pbuff_layout = {grow="rightdown", per_row=8, time_tb="bottom", time_lr="right", scale=1.0},
	fdebuff_layout = {grow="rightdown", per_row=8, time_tb="bottom", time_lr="right", scale=1.0},
	fbuff_layout = {grow="rightdown", per_row=8, time_tb="bottom", time_lr="right", scale=1.0},
	all_pdebuffs = false,
	all_fdebuffs = false,
	all_fbuffs = false,
	count = false,
	cooldowncount = true,
	combat = false,
	tooltips = false,
	lock = false,
	debuff_list = {
		["Sunder Armor"] = {},
		["Faerie Fire"] = {},
		["Curse of Recklessness"] = {},
		["Thunder Clap"] = {},
		["Expose Armor"] = {},
	},
	buff_list = {
		["Anti-Magic Shell"] = {},
		["Berserker Rage"] = {},
		["Bladestorm"] = {},
		["Cheating Death"] = {},
		["Cloak of Shadows"] = {},
		["Deterrence"] = {},
		["Dispersion"] = {},
		["Divine Sacrifice"] = {},
		["Evasion"] = {},
		["Fingers of Frost"] = {},
		["Grounding Totem Effect"] = {},
		["Hand of Freedom"] = {},
		["Hand of Protection"] = {},
		["Hand of Sacrifice"] = {},
		["Ice Block"] = {},
		["Icebound Fortitude"] = {},
		["Intervene"] = {},
		["Lichborne"] = {},
		["Master's Call"] = {},
		["Pain Suppression"] = {},
		["Power Word: Shield"] = {},
		["Predator's Swiftness"] = {},
		["Recklessness"] = {},
		["Retaliation"] = {},
		["Roar of Sacrifice"] = {},
		["Sacred Cleansing"] = {},
		["Shadow Dance"] = {},
		["Shield Block"] = {},
		["Shield Wall"] = {},
		["Spell Reflection"] = {},
	},
	pdebuff_list = {
		["Aimed Shot"] = {},
		["Mortal Strike"] = {},
		["Wound Poison VII"] = {},
	},
	pbuff_list = {
		["Aspect of the Cheetah"] = {},
		["Aspect of the Dragonhawk"] = {},
		["Aspect of the Viper"] = {},
		["Avenging Wrath"] = {},
		["Beacon of Light"] = {},
		["Berserk"] = {},
		["Divine Plea"] = {},
		["Dispersion"] = {},
		["Divine Protection"] = {},
		["Divine Sacrifice"] = {},
		["Hand of Freedom"] = {},
		["Hand of Protection"] = {},
		["Icy Rage"] = {},
		["Intervene"] = {},
		["Infusion of Light"] = {},
		["Master's Call"] = {},
		["Paragon"] = {},
		["Piercing Twilight"] = {},
		["Rapid Fire"] = {},
		["Reckoning"] = {},
		["Roar of Sacrifice"] = {},
		["Sacred Shield"] = {},
		["Swordguard Embroidery"] = {},
		["Water Shield"] = {},
	},
	fdebuff_list = {
		["Mortal Strike"] = {},
	},
	fbuff_list = {
		["Fear Ward"] = {},
	},
	-- saved frame positions (TOPLEFT anchor relative to UIParent BOTTOMLEFT)
	positions = {},
}

local DebuffFilter = {};
-- settings for the current player
local DebuffFilter_PlayerConfig;

-- deep copy utility to avoid shared references between defaults and player config
-- global so the options module can use it for profile copy/import
function DebuffFilter_DeepCopy(orig)
	if type(orig) ~= "table" then return orig end
	local copy = {}
	for k, v in pairs(orig) do
		copy[k] = DebuffFilter_DeepCopy(v)
	end
	return copy
end

-- the direction that debuffs/buffs are organized, what side their time is on,
-- and what side the number of debuffs/buffs is placed
DebuffFilter.Orientation = {
	rightdown = { point="LEFT", relpoint="RIGHT", x=4, y=0 },
	rightup = { point="LEFT", relpoint="RIGHT", x=4, y=0 },
	leftdown = { point="RIGHT", relpoint="LEFT", x=-4, y=0 },
	leftup = { point="RIGHT", relpoint="LEFT", x=-4, y=0 },
	bottom = { point="TOP", relpoint="BOTTOM", x=0, y=-2, next_time="top" },
	top = { point="BOTTOM", relpoint="TOP", x=0, y=2, next_time="bottom" },
	left = { point="RIGHT", relpoint="LEFT", x=-4, y=0, next_time="right" },
	right = { point="LEFT", relpoint="RIGHT", x=4, y=0, next_time="left" },
}

DebuffFilter.Frames = {
	DebuffFilter_DebuffFrame = { option_key="debuffs", list_key="debuff_list", layout_key="debuff_layout", name="debuff", button="DebuffFilter_DebuffButton", isdebuff=true, target="target" },
	DebuffFilter_BuffFrame = { option_key="buffs", list_key="buff_list", layout_key="buff_layout", name="buff", button="DebuffFilter_BuffButton", isdebuff=false, target="target" },
	DebuffFilter_PDebuffFrame = { option_key="pdebuffs", list_key="pdebuff_list", layout_key="pdebuff_layout", name="player debuff" , all_cmd="allpd", button="DebuffFilter_PDebuffButton", isdebuff=true, target="player" },
	DebuffFilter_PBuffFrame = { option_key="pbuffs", list_key="pbuff_list", layout_key="pbuff_layout", name="player buff", button="DebuffFilter_PBuffButton", isdebuff=false, target="player" },
	DebuffFilter_FDebuffFrame = { option_key="fdebuffs", list_key="fdebuff_list", layout_key="fdebuff_layout", name="focus debuff", all_cmd="allfd", button="DebuffFilter_FDebuffButton", isdebuff=true, target="focus" },
	DebuffFilter_FBuffFrame = { option_key="fbuffs", list_key="fbuff_list", layout_key="fbuff_layout", name="focus buff", all_cmd="allfb", button="DebuffFilter_FBuffButton", isdebuff=false, target="focus" },
}

-- global variable that options module can access
DebuffFilterFrames = DebuffFilter.Frames;

-- stores already seen debuffs/buffs so that they can be combined and stacked
DebuffFilter.Stacks = {
	debuffs = {},
	buffs = {},
	pdebuffs = {},
	pbuffs = {},
	fdebuffs = {},
	fbuffs = {},
}

local DebuffFilter_VariablesLoaded = false;

local function DebuffFilter_Initialize(self)
	if (not DebuffFilter_Config) then
		DebuffFilter_Config = {};
	end

	if (not DebuffFilter_Config[DebuffFilter_Player]) then
		DebuffFilter_Config[DebuffFilter_Player] = {};
	end

	-- grab settings for current player
	DebuffFilter_PlayerConfig = DebuffFilter_Config[DebuffFilter_Player];

	for k, v in pairs(DebuffFilter_PlayerConfig) do
		if (DebuffFilter_DefaultSettings[k] == nil) then
			DebuffFilter_PlayerConfig[k] = nil;
		end
	end

	for k, v in pairs(DebuffFilter_DefaultSettings) do
		if (DebuffFilter_PlayerConfig[k] == nil) then
			DebuffFilter_PlayerConfig[k] = DebuffFilter_DeepCopy(v);
		end
	end

	-- ensure per-frame scale exists in saved layouts (upgrade from old configs)
	for k, v in pairs(DebuffFilter.Frames) do
		local layout = DebuffFilter_PlayerConfig[v.layout_key];
		if layout and layout.scale == nil then
			layout.scale = 1.0;
		end
	end

	self:SetScale(DebuffFilter_PlayerConfig.scale);

	local list_key, layout;

	for k, v in pairs(DebuffFilter.Frames) do
		list_key = v.list_key;
		layout = DebuffFilter_PlayerConfig[v.layout_key];

		for listk, listv in pairs(DebuffFilter_PlayerConfig[list_key]) do
			if (listv == 1) then
				DebuffFilter_PlayerConfig[list_key][listk] = {};
			end
		end

		-- hide a frame that the player unchecked
		if (not DebuffFilter_PlayerConfig[v.option_key]) then
			_G[k]:Hide();
		end

		-- show number of debuffs/buffs if player has it checked
		if (DebuffFilter_PlayerConfig.count) then
			_G[k .. "Count"]:Show();
		end

		DebuffFilter_SetCountOrientation(layout, k);
		-- apply per-frame scale
		DebuffFilter_ApplyFrameScale(k, layout.scale or 1.0);
		-- display the frame and its debuffs/buffs
		DebuffFilter_Frame_Update(k);
	end

	-- restore saved frame positions AFTER all scales have been applied,
	-- so ApplyFrameScale does not shift the restored coordinates
	local savedPos = DebuffFilter_PlayerConfig.positions;
	if savedPos then
		for k, pos in pairs(savedPos) do
			local frame = _G[k];
			if frame and pos.x and pos.y then
				frame:ClearAllPoints();
				frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos.x, pos.y);
			end
		end
	end

	if (DebuffFilter_PlayerConfig.lock) then
		DebuffFilter_LockFrames(true);
	end

	if (DebuffFilter_PlayerConfig.combat) then
		self:RegisterEvent("PLAYER_REGEN_DISABLED");
		self:RegisterEvent("PLAYER_REGEN_ENABLED");

		if (not UnitAffectingCombat("player")) then
			self:Hide();
		end
	end

	DebuffFilterOptions_Initialize();

	DebuffFilter_VariablesLoaded = true;

	SlashCmdList["DFILTER"] = DebuffFilter_Command;
	SLASH_DFILTER1 = "/dfilter";
end

function DebuffFilter_OnMouseDown(self, button)
	if (button == "LeftButton" and IsShiftKeyDown()) then
		self:GetParent():StartMoving();
	elseif (button == "RightButton" and IsControlKeyDown()) then
		local next_time;
		local frame = self:GetParent():GetName();
		local layout_key = DebuffFilter.Frames[frame].layout_key;
		local layout = DebuffFilter_PlayerConfig[layout_key];

		-- switch position of the debuffs/buffs time, if it's bottom make it top
		-- if there's only 1 per row, switch it to left or right side
		if (layout.per_row == 1) then
			next_time = DebuffFilter.Orientation[layout.time_lr].next_time;
			layout.time_lr = next_time;
		else
			next_time = DebuffFilter.Orientation[layout.time_tb].next_time;
			layout.time_tb = next_time;
		end

		-- reposition the times for the debuffs/buffs of a certain frame
		DebuffFilter_SetTimeOrientation(next_time, DebuffFilter.Frames[frame].button);
		DebuffFilter_Print(DebuffFilter.Frames[frame].name .. " time orientation: " .. next_time);
	end
end

function DebuffFilter_OnMouseUp(self, button)
	if (button == "LeftButton") then
		self:GetParent():StopMovingOrSizing();
	end
end

function DebuffFilter_OnLoad(self)
	-- get name of current player in order to load its settings
	DebuffFilter_Player = (UnitName("player").." - "..GetRealmName());
	self:RegisterEvent("VARIABLES_LOADED");
	self:RegisterEvent("PLAYER_LOGIN");
	self:RegisterEvent("PLAYER_TARGET_CHANGED");
	self:RegisterEvent("PLAYER_FOCUS_CHANGED");
	self:RegisterEvent("UNIT_AURA");
	self:RegisterEvent("PLAYER_LOGOUT");
end

function DebuffFilter_Button_OnLoad(self)
	local name = self:GetName();

	self.icon = _G[name .. "Icon"];
	self.time = _G[name .. "Duration"];
	self.cooldown = _G[name .. "Cooldown"];
	-- current number of debuff/buff's stack
	self.count = _G[name .. "Count"];
	-- number of same debuffs/buffs that are combined
	self.count2 = _G[name .. "Count2"];
	self.border = _G[name .. "Border"];
	self.update = 0;
	self.isTimeVisible = false;
end

function DebuffFilter_ShowButton(button, index, texture, applications, duration, expiretime, target)
	button.index = index;
	button.expiretime = expiretime;
	button.target = target;
	button.icon:SetTexture(texture);

	-- show stack number of a debuff/buff
	if (applications > 1) then
		button.count:SetText(applications);
		button.count:Show();
	else
		button.count:Hide();
	end

	-- show time remaining for a debuff/buff, if it exists, as a time
	-- or display it as a cooldown on the debuff/buff itself similar to a clock
	if (duration and duration > 0) then
		if (not DebuffFilter_PlayerConfig.cooldowncount) then
			DebuffFilter_SetTime(button, expiretime-GetTime());
			button.time:Show();
		else
			CooldownFrame_SetTimer(button.cooldown, expiretime-duration, duration, 1);
		end
	else
		button.time:Hide();
		button.cooldown:Hide();

		-- dunno what this is for, maybe addon OmniCC?
		if (button.timer) then
			button.timer:Hide();
		end
	end

	button:Show();
end

function DebuffFilter_Frame_Update(framename)
	local frameitem = DebuffFilter.Frames[framename];
	local isdebuff, target = frameitem.isdebuff, frameitem.target;
	local option_key = frameitem.option_key;
	if (not DebuffFilter_PlayerConfig[option_key]) then
		return;
	end
	
	local button;
	local buttonname = frameitem.button;
	local name, texture, applications, debufftype, duration, expiretime, caster, ismine;
	local selfapplied, dontcombine, texturefilter;
	local nametexture, color;
	local width = 0;
	local targetisplayer = target == "player";
	local already_seen_debuffs = DebuffFilter.Stacks[option_key];

	-- iterate through every debuff/buff player has and perhaps display it
	local i = 1;
	if isdebuff then
		name, _, texture, applications, debufftype, duration, expiretime, caster = UnitDebuff(target, i);
	else
		name, _, texture, applications, debufftype, duration, expiretime, caster = UnitBuff(target, i);
	end
	while texture do
		-- if we are not dealing with the current player's debuffs/buffs,
		-- check that the current debuff/buff was applied by the current player
		if not targetisplayer then
			ismine = caster == "player";
		end
	
		-- display number of debuffs/buffs raider has
		_G[framename .. "Count"]:SetText(i);
		
		-- check if current debuff/buff is on list of debuffs/buffs to display
		local debuff = DebuffFilter_PlayerConfig[frameitem.list_key][name];
		
		-- check if we are to display all debuffs/buffs
		local all_debuffs;
		if frameitem.all_cmd then
			all_debuffs = DebuffFilter_PlayerConfig["all_" .. option_key]
		end
		
		if debuff or all_debuffs then
			-- dont need to know these settings if we are displaying all debuffs/buffs
			if all_debuffs == nil or not all_debuffs then
				-- show only debuff/buff current player applied
				selfapplied = debuff.selfapplied;
				-- dont combine same debuff/buff from different players into one
				dontcombine = debuff.dontcombine;
				texturefilter = debuff.texture;
			else
				-- reset per-entry flags so previous iteration values don't bleed through
				selfapplied = nil;
				dontcombine = nil;
				texturefilter = nil;
			end
			
			-- if texture field is not nil, look for a match with the name of debuff/buff's texture
			-- problem with this, is that i have seen spells who have texture names that are much different than the spell name
			if (targetisplayer or (not selfapplied or ismine)) and (not texturefilter or string.match(texture, texturefilter)) then
				nametexture = name .. texture;

				if (not dontcombine and already_seen_debuffs[nametexture]) then
					button = _G[buttonname .. already_seen_debuffs[nametexture]];
				
					DebuffFilter_CombineStacks(button);

					if (targetisplayer or ismine) then
						DebuffFilter_ShowButton(button, i, texture, applications, duration, expiretime, target);
					end
				else
					-- assume it sets the color of the border of the debuff, but I can't find
					-- the DebuffTypeColor list anywhere
					if isdebuff then
						if (debufftype) then
							color = DebuffTypeColor[debufftype];
						else
							color = DebuffTypeColor["none"];
						end
					end	

					width = width + 1;
			
					button = _G[buttonname .. width];

					if (not button) then
						if isdebuff then
							button = CreateFrame("Button", buttonname .. width, _G[framename], "DebuffFilter_DebuffButtonTemplate");
						else
							button = CreateFrame("Button", buttonname .. width, _G[framename], "DebuffFilter_BuffButtonTemplate");
						end
						button:EnableMouse(not DebuffFilter_PlayerConfig.lock);
						-- set the position of the button, and its time
						DebuffFilter_SetButtonLayout(DebuffFilter_PlayerConfig[frameitem.layout_key], framename, button, width);
					end

					-- make time visible and have it updated every second, if debuff/buff has a time, and if
					-- user does not want the cooldown appearing on debuff/buff, similar to a clock
					if duration and duration > 0 and not DebuffFilter_PlayerConfig.cooldowncount and not button.isTimeVisible then
						button:SetScript("OnUpdate",DebuffFilter_Button_OnUpdate);
						button.isTimeVisible = true;
					elseif (not duration or duration == 0 or DebuffFilter_PlayerConfig.cooldowncount) and button.isTimeVisible then
						button:SetScript("OnUpdate",nil);
						button.isTimeVisible = false;
					end
					
					if isdebuff then button.border:SetVertexColor(color.r, color.g, color.b) end
					button.count2:SetText("");
					DebuffFilter_ShowButton(button, i, texture, applications, duration, expiretime, target);

					already_seen_debuffs[nametexture] = width;
				end
			end
		end
		i = i + 1;
		if isdebuff then
			name, _, texture, applications, debufftype, duration, expiretime, caster = UnitDebuff(target, i);
		else
			name, _, texture, applications, debufftype, duration, expiretime, caster = UnitBuff(target, i);
		end
	end

	-- hide remaining buttons that were visible from before
	i = width + 1;
	button = _G[buttonname .. i];
	while button do
		button:Hide();
		i = i + 1;
		button = _G[buttonname .. i];
	end

	if (width == 0) then
		_G[framename .. "Count"]:SetText("");
	end

	-- better to reuse this table then use up memory by creating a new one
	for k in pairs(already_seen_debuffs) do
		already_seen_debuffs[k] = nil;
	end
end

function DebuffFilter_OnEvent(self, event, ...)
	local arg1, arg2, arg3 = ...;
	if (event == "UNIT_AURA" and arg1 == "target") then
		DebuffFilter_Frame_Update("DebuffFilter_DebuffFrame");
		DebuffFilter_Frame_Update("DebuffFilter_BuffFrame");
	elseif (event == "PLAYER_TARGET_CHANGED") then
		DebuffFilter_Frame_Update("DebuffFilter_DebuffFrame");
		DebuffFilter_Frame_Update("DebuffFilter_BuffFrame");
	elseif (event == "UNIT_AURA" and arg1 == "player") then
		DebuffFilter_Frame_Update("DebuffFilter_PDebuffFrame");
		DebuffFilter_Frame_Update("DebuffFilter_PBuffFrame");
	elseif (event == "UNIT_AURA" and arg1 == "focus") then
		DebuffFilter_Frame_Update("DebuffFilter_FDebuffFrame");
		DebuffFilter_Frame_Update("DebuffFilter_FBuffFrame");
	elseif (event == "PLAYER_FOCUS_CHANGED") then
		DebuffFilter_Frame_Update("DebuffFilter_FDebuffFrame");
		DebuffFilter_Frame_Update("DebuffFilter_FBuffFrame");
	elseif (event == "PLAYER_REGEN_DISABLED") then
		self:Show();
	elseif (event == "PLAYER_REGEN_ENABLED") then
		self:Hide();
	elseif (event == "VARIABLES_LOADED") then
		self:UnregisterEvent(event);
		DebuffFilter_Initialize(self);
	elseif (event == "PLAYER_LOGIN") then
		self:UnregisterEvent(event);
		if DebuffFilter_VariablesLoaded then self:SetScale(DebuffFilter_PlayerConfig.scale) end
	elseif (event == "PLAYER_LOGOUT") then
		DebuffFilter_SavePositions();
	end
end

-- update time on debuff/buff every second, while loop is used to make sure, that if the players 
-- framerate is very low, it'll still do the updates as many times as needed
function DebuffFilter_Button_OnUpdate(self, elapsed)

	self.update = self.update + elapsed;
	while (self.update >= 1) do
		self.update = self.update - 1;

		DebuffFilter_SetTime(self, self.expiretime-GetTime());
	end
end

-- increment number after combining two of the same debuffs/buffs
function DebuffFilter_CombineStacks(button)
	local total = (tonumber(button.count2:GetText()) or 1) + 1;
	button.count2:SetText(total);
end

-- taken from ctmod
function DebuffFilter_SetTime(button, time)
	time = floor(time or 0);

	local min, sec;

	if ( time >= 60 ) then
		min = floor(time/60);
		sec = time - min*60;
	else
		sec = time;
		min = 0;
	end

	if ( sec <= 9 ) then sec = "0" .. sec; end
	if ( min <= 9 ) then min = "0" .. min; end

	if (10 >= time) then
		button.time:SetTextColor(1, 0, 0);
	else
		button.time:SetTextColor(1, 0.82, 0);
	end

	button.time:SetText(min .. ":" .. sec);
end

-- reposition or redraw frame's debuffs/buffs after options have been changed
function DebuffFilter_UpdateLayout(frame)
	local button;
	local name = DebuffFilter.Frames[frame].button;
	local layout_key = DebuffFilter.Frames[frame].layout_key;
	local layout = DebuffFilter_PlayerConfig[layout_key];

	local i = 1;
	button = _G[name .. i];
	while button do
		button:ClearAllPoints();
		DebuffFilter_SetButtonLayout(layout, frame, button, i);
	
		i = i + 1;
		button = _G[name .. i];
	end
	
	DebuffFilter_SetCountOrientation(layout, frame);
end

-- set the location of a debuff/buff and the location of its time
function DebuffFilter_SetButtonLayout(layout, frame, button, index)
	local point, relpoint, x, y;
	local grow = layout.grow;
	local per_row = layout.per_row;
	local offset = 14;

	point, relpoint = DebuffFilter.Orientation[grow].point, DebuffFilter.Orientation[grow].relpoint;
	x, y = DebuffFilter.Orientation[grow].x, DebuffFilter.Orientation[grow].y;

	-- place time to the left or right of debuff/buff if debuffs/buffs are arranged vertically
	if (per_row == 1 or DebuffFilter_PlayerConfig.cooldowncount) then
		offset = 4;
		DebuffFilter_SetTimeOrientation(layout.time_lr, button);
	else
		DebuffFilter_SetTimeOrientation(layout.time_tb, button);
	end

	if (index > 1) then
		-- start a new row if the current one has enough debuffs/buffs
		if (mod(index, per_row) == 1 or per_row == 1) then
			if (layout.grow == "rightdown" or layout.grow == "leftdown") then
				button:SetPoint("TOP", DebuffFilter.Frames[frame].button .. (index-per_row), "BOTTOM", 0, -offset);
			else
				button:SetPoint("BOTTOM", DebuffFilter.Frames[frame].button .. (index-per_row), "TOP", 0, offset);
			end
		else
			DebuffFilter_SetTimeOrientation(layout.time_tb, button);
			button:SetPoint(point, DebuffFilter.Frames[frame].button .. (index-1), relpoint, x, y)
		end
	else
		button:SetPoint(point, frame, point, 0, 0);
	end
end

function DebuffFilter_SetTimeOrientation(orientation, button)
	local point, relpoint, x, y;

	point, relpoint = DebuffFilter.Orientation[orientation].point, DebuffFilter.Orientation[orientation].relpoint;
	x, y = DebuffFilter.Orientation[orientation].x, DebuffFilter.Orientation[orientation].y;

	-- set the position of the time, somewhere around the debuff/buff
	if (button.time) then
		button.time:ClearAllPoints();
		button.time:SetPoint(point, button, relpoint, x, y);
	-- set the positions of the times for the debuffs/buffs of a certain frame
	else
		local time;
		local name = button;

		local i = 1;
		button = name .. i;
		time = _G[button .. "Duration"];
		while time do
			time:ClearAllPoints();
			time:SetPoint(point, button, relpoint, x, y);
			
			i = i + 1;
			button = name .. i;
			time = _G[button .. "Duration"];
		end
	end
end

-- set the location for the number of debuffs/buffs for the frame
function DebuffFilter_SetCountOrientation(layout, frame)
	local grow = layout.grow;
	local per_row = layout.per_row;

	local count = _G[frame .. "Count"];
	count:ClearAllPoints();

	if (per_row > 1) then
		if (grow == "rightdown" or grow == "rightup") then
			count:SetPoint("RIGHT", frame, "LEFT", 0, 0);
		else
			count:SetPoint("LEFT", frame, "RIGHT", 0, 0);
		end
	else
		if (grow == "rightdown" or grow == "leftdown") then
			count:SetPoint("BOTTOM", frame, "TOP", 0, 8);
		else
			count:SetPoint("TOP", frame, "BOTTOM", 0, -8);
		end
	end
end

-- lock the frames, so they cannot be moved, or unlock them
-- also allows mouse events to pass through debuffs/buffs if locked
function DebuffFilter_LockFrames(lock)
	local button;

	for k, v in pairs(DebuffFilter.Frames) do
		_G[k]:EnableMouse(not lock);

		local i = 1;
		button = _G[v.button .. i];
		while button do
			button:EnableMouse(not lock);
			
			i = i + 1;
			button = _G[v.button .. i];
		end
	end
end

-- apply individual scale to a specific frame (independent of global scale)
-- compensates position so the frame stays in place, same as global scale
function DebuffFilter_ApplyFrameScale(framename, scale)
	local frame = _G[framename];
	if not frame then return end

	local oldScale = frame:GetScale();
	if oldScale > 0 then
		local ratio = oldScale / scale;
		local left = frame:GetLeft();
		local top = frame:GetTop();
		if left and top then
			frame:ClearAllPoints();
			frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left * ratio, top * ratio);
		end
	end
	frame:SetScale(scale);
end

-- set the individual scale for a frame type, called from options
function DebuffFilter_SetFrameScale(framename, layout_key, scale)
	DebuffFilter_PlayerConfig[layout_key].scale = scale;
	DebuffFilter_ApplyFrameScale(framename, scale);
end

function DebuffFilter_Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Debuff Filter|r: " .. msg);
end

-- save each frame's current position to SavedVariables so it persists across sessions
function DebuffFilter_SavePositions()
	if not DebuffFilter_PlayerConfig then return end
	local positions = DebuffFilter_PlayerConfig.positions;
	for k in pairs(DebuffFilter.Frames) do
		local frame = _G[k];
		local x, y = frame:GetLeft(), frame:GetTop();
		if x and y then
			positions[k] = { x = x, y = y };
		end
	end
end

function DebuffFilter_Options(opt)
	-- Hide or show the frame the user just checked/unchecked
	if (opt == "debuffs" or opt == "buffs" or opt == "pdebuffs" or opt == "pbuffs" or opt == "fdebuffs" or opt == "fbuffs") then
		for k, v in pairs(DebuffFilter.Frames) do
			if (v.option_key == opt) then
				if (DebuffFilter_PlayerConfig[v.option_key]) then
					DebuffFilter_PlayerConfig[v.option_key] = false;
					_G[k]:Hide();
				else
					DebuffFilter_PlayerConfig[v.option_key] = true;
					DebuffFilter_Frame_Update(k);
					_G[k]:Show();
				end

				break;
			end
		end
	-- hide or show the number of debuffs/buffs for each frame, including the ones not shown
	elseif (opt == "count") then
		if (DebuffFilter_PlayerConfig.count) then
			DebuffFilter_PlayerConfig.count = false;
			for k in pairs(DebuffFilter.Frames) do
				_G[k .. "Count"]:Hide();
			end
		else
			DebuffFilter_PlayerConfig.count = true;
			for k in pairs(DebuffFilter.Frames) do
				_G[k .. "Count"]:Show();
			end
		end
	elseif (opt == "cooldowncount") then
		local button, i;

		if (DebuffFilter_PlayerConfig.cooldowncount) then
			DebuffFilter_PlayerConfig.cooldowncount = false;
			for k, v in pairs(DebuffFilter.Frames) do
				i = 1;
				button = _G[v.button .. i];
				while button do
					button.cooldown:Hide();

					if (button.timer) then
						button.timer:Hide();
					end
				
					i = i + 1;
					button = _G[v.button .. i];
				end
				
				DebuffFilter_UpdateLayout(k);
				DebuffFilter_Frame_Update(k);
			end
		else
			DebuffFilter_PlayerConfig.cooldowncount = true;
			for k, v in pairs(DebuffFilter.Frames) do
				i = 1;
				button = _G[v.button .. i];
				while button do
					button.time:Hide();
					
					i = i + 1;
					button = _G[v.button .. i];
				end
				
				DebuffFilter_UpdateLayout(k);
				DebuffFilter_Frame_Update(k);
			end
		end
	-- decides if frames are shown out of combat
	elseif (opt == "combat") then
		if (DebuffFilter_PlayerConfig.combat) then
			DebuffFilter_PlayerConfig.combat = false;
			DebuffFilterFrame:UnregisterEvent("PLAYER_REGEN_DISABLED");
			DebuffFilterFrame:UnregisterEvent("PLAYER_REGEN_ENABLED");
			DebuffFilterFrame:Show();
		else
			DebuffFilter_PlayerConfig.combat = true;
			DebuffFilterFrame:RegisterEvent("PLAYER_REGEN_DISABLED");
			DebuffFilterFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
			if (not UnitAffectingCombat("player")) then
				DebuffFilterFrame:Hide();
			end
		end
	elseif (opt == "tooltips") then
		if (DebuffFilter_PlayerConfig.tooltips) then
			DebuffFilter_PlayerConfig.tooltips = false;
		else
			DebuffFilter_PlayerConfig.tooltips = true;
		end
	elseif (opt == "lock") then
		if (DebuffFilter_PlayerConfig.lock) then
			DebuffFilter_PlayerConfig.lock = false;
			DebuffFilter_LockFrames(false);
		else
			DebuffFilter_PlayerConfig.lock = true;
			DebuffFilter_LockFrames(true);
		end
	-- decides if backdrops are shown, which allows frames to be moved
	elseif (opt == "backdrop") then
		if (DebuffFilter.backdrop) then
			DebuffFilter.backdrop = false;
			for k in pairs(DebuffFilter.Frames) do
				_G[k .. "Backdrop"]:Hide();
			end
		else
			DebuffFilter.backdrop = true;
			for k in pairs(DebuffFilter.Frames) do
				_G[k .. "Backdrop"]:Show();
			end
		end
	end
end

function DebuffFilter_Command(cmd)
	cmd = string.lower(cmd);

	-- decides if all player debuffs, all focus debuffs, or all focus buffs are shown
	if (cmd == "allpd" or cmd == "allfd" or cmd == "allfb") then
		for k, v in pairs(DebuffFilter.Frames) do
			if (v.all_cmd == cmd) then
				local all_key = "all_" .. v.option_key;

				if (DebuffFilter_PlayerConfig[all_key]) then
					DebuffFilter_PlayerConfig[all_key] = false;
					DebuffFilter_Frame_Update(k);
					DebuffFilter_Print("display all " .. v.name .. "s disabled.");
				else
					DebuffFilter_PlayerConfig[all_key] = true;
					DebuffFilter_Frame_Update(k);
					DebuffFilter_Print("display all " .. v.name .. "s enabled.");
				end

				break;
			end
		end
	elseif (cmd == "resetpos") then
		-- clear saved positions so they don't override the reset on next login
		if DebuffFilter_PlayerConfig and DebuffFilter_PlayerConfig.positions then
			for k in pairs(DebuffFilter_PlayerConfig.positions) do
				DebuffFilter_PlayerConfig.positions[k] = nil;
			end
		end
		DebuffFilter_DebuffFrame:ClearAllPoints();
		DebuffFilter_DebuffFrame:SetPoint("CENTER", UIParent, "CENTER", -40, 0);
		DebuffFilter_BuffFrame:ClearAllPoints();
		DebuffFilter_BuffFrame:SetPoint("LEFT", DebuffFilter_DebuffFrame, "RIGHT", 70, 0);
		DebuffFilter_PDebuffFrame:ClearAllPoints();
		DebuffFilter_PDebuffFrame:SetPoint("TOP", DebuffFilter_DebuffFrame, "BOTTOM", 0, -30);
		DebuffFilter_PBuffFrame:ClearAllPoints();
		DebuffFilter_PBuffFrame:SetPoint("LEFT", DebuffFilter_PDebuffFrame, "RIGHT", 70, 0);
		DebuffFilter_FDebuffFrame:ClearAllPoints();
		DebuffFilter_FDebuffFrame:SetPoint("TOP", DebuffFilter_PDebuffFrame, "BOTTOM", 0, -30);
		DebuffFilter_FBuffFrame:ClearAllPoints();
		DebuffFilter_FBuffFrame:SetPoint("LEFT", DebuffFilter_FDebuffFrame, "RIGHT", 70, 0);
	elseif (cmd == "status") then
		DebuffFilter_Print("current settings:");
		DebuffFilter_Print("show all player debuffs: |cff00ccff" .. tostring(DebuffFilter_PlayerConfig.all_pdebuffs) .. "|r");
		DebuffFilter_Print("show all focus target debuffs: |cff00ccff" .. tostring(DebuffFilter_PlayerConfig.all_fdebuffs) .. "|r");
		DebuffFilter_Print("show all focus target buffs: |cff00ccff" .. tostring(DebuffFilter_PlayerConfig.all_fbuffs) .. "|r");
	elseif (cmd == "help") then
		DEFAULT_CHAT_FRAME:AddMessage("Debuff Filter commands:");
		DEFAULT_CHAT_FRAME:AddMessage("/dfilter |cff00ccffconfig|r: display the configuration menu.");
		DEFAULT_CHAT_FRAME:AddMessage("/dfilter |cff00ccffallpd|r || |cff00ccffallfd|r || |cff00ccffallfb|r: display all player debuffs or focus target debuffs and buffs.");
		DEFAULT_CHAT_FRAME:AddMessage("/dfilter |cff00ccffresetpos|r: resets frame positions.");
		DEFAULT_CHAT_FRAME:AddMessage("/dfilter |cff00ccffstatus|r: display current command-line settings.");
		DEFAULT_CHAT_FRAME:AddMessage("To move the frames, shift+left click and drag a backdrop or a monitored debuff/buff.");
		DEFAULT_CHAT_FRAME:AddMessage("To change the frame or time orientation, shift+right click or ctrl+right click, respectively.");
	else
		if (not DebuffFilterOptionsFrame:IsVisible() and DebuffFilter_VariablesLoaded) then
			ShowUIPanel(DebuffFilterOptionsFrame);
		else
			HideUIPanel(DebuffFilterOptionsFrame);
		end
	end
end