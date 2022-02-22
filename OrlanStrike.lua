OrlanStrike = {};

SLASH_ORLANSTRIKE1 = "/orlanstrike";
SLASH_ORLANSTRIKE2 = "/os";
function SlashCmdList.ORLANSTRIKE(message, editbox)
	if message == "show" then
		OrlanStrike:Show();
	elseif message == "hide" then
		OrlanStrike:Hide();
	elseif string.sub(message, 1, 6) == "scale " then
		local scale = tonumber(string.sub(message, 7, string.len(message)));
		if scale and (scale > 0) and (scale < 100) then
			OrlanStrike:SetScale(scale);
		else
			print("OrlanStrike: Incorrect scale.");
		end;
	end;
end;

function OrlanStrike:SetScale(scale)
	self.Config.Scale = scale;
	self.CastWindow:SetScale(scale);
end;

function OrlanStrike:Initialize(configName)
	local orlanStrike = self;

	self.ConfigName = configName;
	self.EventFrame = CreateFrame("Frame");
	self.ButtonSize = 32;
	self.ButtonSpacing = 5;
	self.RowCount = 4;
	self.ColumnCount = 4;
	self.CastWindowHeight = self.ButtonSize * self.RowCount + self.ButtonSpacing * (self.RowCount + 1);
	self.CastWindowWidth = self.ButtonSize * self.ColumnCount + self.ButtonSpacing * (self.ColumnCount + 1);

	self.FrameRate = 10.0;

	function self.EventFrame:HandleEvent(event, arg1, arg2, arg3)
		if (event == "ADDON_LOADED") and (arg1 == "OrlanStrike") then
			orlanStrike:HandleLoaded();
		elseif (event == "PLAYER_SPECIALIZATION_CHANGED") then
			orlanStrike:HandleSpecChange();
		elseif (event == "UNIT_SPELLCAST_SUCCEEDED") and (arg1 == "player") then
			orlanStrike:HandleAbilityUse(arg3);
		elseif (event == "SPELLS_CHANGED") or (event == "PLAYER_EQUIPMENT_CHANGED") then
			orlanStrike:UpdateSpells();
		end;
	end;

	self.EventFrame:RegisterEvent("ADDON_LOADED");
	self.EventFrame:SetScript("OnEvent", self.EventFrame.HandleEvent);

	self.CastWindowStrata = "LOW";
	self.CastWindowName = "OrlanStrike_CastWindow";

	self.SingleTargetPriorities =
	{
		{
			SpellId = 328620 -- Blessing of Summer
		},
		{
			SpellId = 255937, -- Wake of Ashes
			MinReason = 4 -- +3 holy power
		},
		{
			SpellId = 24275, -- Hammer of Wrath
			MinReason = 2 -- +1 holy power
		},
		{
			SpellId = 184575, -- Blade of Justice
			MinReason = 3 -- +2 holy power
		},
		{
			SpellId = 20271, -- Judgment
			MinReason = 2 -- +1 holy power
		},
		{
			SpellId = 35395, -- Crusader Strike
			MinReason = 3 -- +1 holy power @ 2 charges, no Avenging Wrath, target > 20% health
		},
		{
			SpellId = 53385 -- Divine Storm
		},
		{
			SpellId = 85256 -- Templar's Verdict
		},
		{
			SpellId = 26573 -- Consecration
		},
		{
			SpellId = 35395, -- Crusader Strike
			MinReason = 2 -- +1 holy power
		},
		{
			SpellId = 184575, -- Blade of Justice
			MinReason = 2 -- +1 holy power
		},
		{
			SpellId = 35395 -- Crusader Strike
		},
		{
			SpellId = 184575 -- Blade of Justice
		}
	};
	self.MultiTargetPriorities =
	{
		{
			SpellId = 328620 -- Blessing of Summer
		},
		{
			SpellId = 255937, -- Wake of Ashes
			MinReason = 4 -- +3 holy power
		},
		{
			SpellId = 24275, -- Hammer of Wrath
			MinReason = 2 -- +1 holy power
		},
		{
			SpellId = 184575, -- Blade of Justice
			MinReason = 3 -- +2 holy power
		},
		{
			SpellId = 20271, -- Judgment
			MinReason = 2 -- +1 holy power
		},
		{
			SpellId = 35395, -- Crusader Strike
			MinReason = 3 -- +1 holy power @ 2 charges, no Avenging Wrath, target > 20% health
		},
		{
			SpellId = 53385 -- Divine Storm
		},
		{
			SpellId = 26573 -- Consecration
		},
		{
			SpellId = 35395, -- Crusader Strike
			MinReason = 2 -- +1 holy power
		},
		{
			SpellId = 85256 -- Templar's Verdict
		},
		{
			SpellId = 184575, -- Blade of Justice
			MinReason = 2 -- +1 holy power
		},
		{
			SpellId = 35395 -- Crusader Strike
		},
		{
			SpellId = 184575 -- Blade of Justice
		}
	};
	self.MaxAbilityWaitTime = 0.1;
end;

function OrlanStrike:CreateCastWindow()
	local castWindow = CreateFrame("Frame", self.CastWindowName, UIParent);
	castWindow:SetScale(self.Config.Scale);

	function castWindow:HandleDragStop()
		self:StopMovingOrSizing();
	end;

	castWindow:SetPoint("CENTER", 0, 0);
	castWindow:SetFrameStrata(self.CastWindowStrata);
	castWindow:SetHeight(self.CastWindowHeight);
	castWindow:SetWidth(self.CastWindowWidth);
	castWindow:EnableMouse(true);
	castWindow:EnableKeyboard(true);
	castWindow:SetMovable(true);
	castWindow:RegisterForDrag("LeftButton");
	castWindow:SetScript("OnDragStart", castWindow.StartMoving);
	castWindow:SetScript("OnDragStop", castWindow.HandleDragStop);

	castWindow:SetUserPlaced(true);

	castWindow.Background = castWindow:CreateTexture();
	castWindow.Background:SetAllPoints();
	castWindow.Background:SetColorTexture(0, 0, 0, 0.3);

	castWindow.Buttons =
	{
		self:CreateButton(
			castWindow,
			self.BurstButton:CloneTo(
			{
				SpellId = 328620, -- Blessing of Summer
				Row = 0,
				Column = 0
			})),
		self:CreateButton(
			castWindow,
			self.WakeOfAshesButton:CloneTo(
			{
				Row = 1,
				Column = 0
			})),
		self:CreateButton(
			castWindow,
			self.HolyPowerGeneratorButton:CloneTo(
			{
				Row = 0,
				Column = 1,
				SpellId = 24275, -- Hammer of Wrath
				HolyPower = 1,
				DoesRequireTarget = true
			})),
		self:CreateButton(
			castWindow,
			self.BladeOfJusticeButton:CloneTo(
			{
				Row = 1,
				Column = 1
			})),
		self:CreateButton(
			castWindow,
			self.JudgmentButton:CloneTo(
			{
				Row = 0,
				Column = 2
			})),
		self:CreateButton(
			castWindow,
			self.CrusaderStrikeButton:CloneTo(
			{
				Row = 1,
				Column = 2
			})),
		self:CreateButton(
			castWindow,
			self.Button:CloneTo(
			{
				SpellId = 26573, -- Consecration
				Row = 0,
				Column = 3
			})),
		self:CreateButton(
			castWindow,
			OrlanStrike.DivineStormButton:CloneTo(
			{
				Row = 1,
				Column = 3
			})),
		self:CreateButton(
			castWindow,
			self.AvengingWrathButton:CloneTo(
			{
				Row = 2,
				Column = 0
			})),
		self:CreateButton(
			castWindow,
			self.BurstPotButton:CloneTo(
			{
				Row = 2,
				Column = 1,
				SpellId = 307164, -- Potion of Spectral Strength
				ItemId = 171275 -- Potion of Spectral Strength
			})),
		self:CreateButton(
			castWindow,
			self.SlotButton:CloneTo(
			{
				Row = 2,
				Column = 2,
				SlotName = "Trinket0Slot"
			})),
		self:CreateButton(
			castWindow,
			self.SlotButton:CloneTo(
			{
				Row = 2,
				Column = 3,
				SlotName = "Trinket1Slot"
			})),
		self:CreateButton(
			castWindow,
			self.ThreeHolyPowerButton:CloneTo(
			{
				SpellId = 85256, -- Templar's Verdict
				DoesRequireTarget = true,
				Row = 3,
				Column = 0
			})),
		self:CreateButton(
			castWindow,
			self.CleanseToxinsButton:CloneTo(
			{
				Row = 3,
				Column = 1
			})),
		self:CreateButton(
			castWindow,
			self.HealthButton:CloneTo(
			{
				SpellId = 184662, -- Shield of Vengeance
				Row = 3,
				Column = 2
			})),
		self:CreateButton(
			castWindow,
			self.RebukeButton:CloneTo(
			{
				Row = 3,
				Column = 3
			})),
	};
	self.SpellCount = 16;

	castWindow.HolyPowerBar = castWindow:CreateTexture();
	castWindow.HolyPowerBar:SetPoint("BOTTOMLEFT", castWindow, "TOPLEFT", 0, 0);
	castWindow.HolyPowerBar:SetHeight(3);

	castWindow.HolyPowerBar2 = castWindow:CreateTexture();
	castWindow.HolyPowerBar2:SetPoint("BOTTOMLEFT", castWindow.HolyPowerBar, "TOPLEFT", 0, 0);
	castWindow.HolyPowerBar2:SetHeight(6);

	castWindow.HealthBar = castWindow:CreateTexture();
	castWindow.HealthBar:SetPoint("BOTTOMRIGHT", castWindow, "BOTTOMLEFT", 0, 0);
	castWindow.HealthBar:SetWidth(3);

	castWindow.ManaBar = castWindow:CreateTexture();
	castWindow.ManaBar:SetPoint("BOTTOMLEFT", castWindow, "BOTTOMRIGHT", 0, 0);
	castWindow.ManaBar:SetWidth(3);

	castWindow.ThreatBar = castWindow:CreateTexture();
	castWindow.ThreatBar:SetPoint("TOPLEFT", castWindow, "BOTTOMLEFT", 0, 0);
	castWindow.ThreatBar:SetHeight(3);

	return castWindow;
end;

function OrlanStrike:UpdateSpells()
	for index = 1, self.SpellCount do
		if self.CastWindow.Buttons[index] then
			self.CastWindow.Buttons[index]:UpdateSpells();
		end;
	end;

	self.SingleTargetPriorityIndexes = self:CalculateSpellPriorityIndexes(self.SingleTargetPriorities);
	self.MultiTargetPriorityIndexes = self:CalculateSpellPriorityIndexes(self.MultiTargetPriorities);
end;

function OrlanStrike:CreateButton(parent, prototype)
	local button = CreateFrame("Frame", nil, parent);

	prototype:CloneTo(button);
	button.OrlanStrike = self;

	button:SetPoint(
		"TOPLEFT", 
		self.ButtonSpacing + (self.ButtonSize + self.ButtonSpacing) * button.Column,
		-(self.ButtonSpacing + (self.ButtonSize + self.ButtonSpacing) * button.Row));
	button:SetHeight(self.ButtonSize);
	button:SetWidth(self.ButtonSize);

	button.Background = button:CreateTexture(nil, "BACKGROUND");
	button.Background:SetAllPoints();

	button.Text = button:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	button.Text:SetHeight(self.ButtonSize / 2);
	button.Text:SetTextColor(1, 1, 1, 1);
	button.Text:SetShadowColor(0, 0, 0, 1);
	button.Text:SetShadowOffset(-1, -1);
	button.Text:SetTextHeight(self.ButtonSize / 2.5);
	button.Text:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -3, 0);
	button.Text:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 3, 0);
	button.Text:SetJustifyH("RIGHT");

	button.Cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate");
	button.Cooldown:SetAllPoints();

	button.Spell = CreateFrame("Button", nil, button, "SecureActionButtonTemplate");
	button.Spell:SetAllPoints();
	button.Spell:RegisterForClicks("LeftButtonDown");

	button:SetupButton();

	self:CreateBorder(button, 2, 2);

	return button;
end;

function OrlanStrike:CreateBorder(window, thickness, offset)
	window.TopBorder = window:CreateTexture();
	window.TopBorder:SetPoint("TOPLEFT", -offset, offset);
	window.TopBorder:SetPoint("TOPRIGHT", offset, offset);
	window.TopBorder:SetHeight(thickness);

	window.BottomBorder = window:CreateTexture();
	window.BottomBorder:SetPoint("BOTTOMLEFT", -offset, -offset);
	window.BottomBorder:SetPoint("BOTTOMRIGHT", offset, -offset);
	window.BottomBorder:SetHeight(thickness);

	window.LeftBorder = window:CreateTexture();
	window.LeftBorder:SetPoint("TOPLEFT", -offset, offset - thickness);
	window.LeftBorder:SetPoint("BOTTOMLEFT", -offset, -offset + thickness);
	window.LeftBorder:SetWidth(thickness);

	window.RightBorder = window:CreateTexture();
	window.RightBorder:SetPoint("TOPRIGHT", offset, offset - thickness);
	window.RightBorder:SetPoint("BOTTOMRIGHT", offset, -offset + thickness);
	window.RightBorder:SetWidth(thickness);
end;

function OrlanStrike:SetBorderColor(window, r, g, b, a)
	window.TopBorder:SetColorTexture(r, g, b, a);
	window.BottomBorder:SetColorTexture(r, g, b, a);
	window.LeftBorder:SetColorTexture(r, g, b, a);
	window.RightBorder:SetColorTexture(r, g, b, a);
end;

function OrlanStrike:SetTopLeftBorderColor(window, r, g, b, a)
	window.TopBorder:SetColorTexture(r, g, b, a);
	window.LeftBorder:SetColorTexture(r, g, b, a);
end;

function OrlanStrike:SetBottomRightBorderColor(window, r, g, b, a)
	window.BottomBorder:SetColorTexture(r, g, b, a);
	window.RightBorder:SetColorTexture(r, g, b, a);
end;

function OrlanStrike:HandleLoaded()
	_G[self.ConfigName] = _G[self.ConfigName] or {};
	self.Config = _G[self.ConfigName];
	self.Config.Scale = self.Config.Scale or 1;

	self.CastWindow = self:CreateCastWindow();

	self:Show();

	self.EventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED");
	self.EventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");
	self.EventFrame:RegisterEvent("SPELLS_CHANGED");
	self.EventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");

	local orlanStrike = self;
	self.ElapsedAfterUpdate = 0;
	function self.EventFrame:HandleUpdate(elapsed)
		if not orlanStrike.IsTalentTreeUpdated then
			orlanStrike:UpdateTalentTree();
		end;
		if orlanStrike.CastWindow:IsShown() then
			orlanStrike.ElapsedAfterUpdate = orlanStrike.ElapsedAfterUpdate + elapsed;
			if orlanStrike.ElapsedAfterUpdate > 1.0 / orlanStrike.FrameRate then
				orlanStrike:UpdateStatus();
				orlanStrike.ElapsedAfterUpdate = 0;
			end;
		end;
	end;
	self.EventFrame:SetScript("OnUpdate", self.EventFrame.HandleUpdate);

	self:UpdateSpells();
end;

function OrlanStrike:HandleSpecChange()
	self.IsTalentTreeUpdated = false;
end;

function OrlanStrike:UpdateTalentTree()
	local spec = GetSpecialization();

	if spec ~= self.LoadedSpec then
		if not spec or (spec == 3) then
			self:Show();
			self.IsTalentTreeUpdated = true;
		elseif spec then
			self:Hide();
			self.IsTalentTreeUpdated = true;
		end;

		self.LoadedSpec = spec;
	end;
end;

function OrlanStrike:CalculateSpellPriorityIndexes(priorities)
	local indexes = {};
	local orlanStrike = self;
	table.foreach(
		priorities,
		function (index, priority)
			indexes[index] = 
				{
					SpellId = priority.SpellId,
					Index = orlanStrike:CalculateSpellIndex(priority.SpellId, priority.Target),
					MinReason = priority.MinReason or 1
				};
		end);
	return indexes;
end;

function OrlanStrike:CalculateSpellIndex(spellId, target)
	local result;
	for index = 1, self.SpellCount do
		if self.CastWindow.Buttons[index] and 
				(self.CastWindow.Buttons[index]:GetSpellId() == spellId) and
				(self.CastWindow.Buttons[index].Target == target) then
			result = index;
			break;
		end;
	end;
	return result;
end;

function OrlanStrike:Show()
	if self:RequestNonCombat() then
		self.CastWindow:Show();
	end;
end;

function OrlanStrike:Hide()
	if self:RequestNonCombat() then
		self.CastWindow:Hide();
	end;
end;

function OrlanStrike:HandleAbilityUse(spellId)
	if self.CastWindow:IsShown() then
		self:DetectAuras();
		self:DetectHealthPercent();
		self:DetectManaPercent();
		self:DetectThreat();

		self:DetectGcd();

		local gameState = self:GetCurrentGameState();
		for spellIndex = 1, self.SpellCount do
			local button = self.CastWindow.Buttons[spellIndex];
			if button and button:GetSpellId() and (button:GetSpellId() == spellId) then
				button:UpdateGameState(gameState);
				self.GameStateOverride = gameState;
				self.GameStateOverrideTimeout = GetTime() + 0.5;
			end;
		end;
	end;
end;

function OrlanStrike:DetectForbearance()
	local forbearanceSpellName = GetSpellInfo(25771); -- Forbearance
	self.HasForbearance = AuraUtil.FindAuraByName("player", forbearanceSpellName) == nil;
end;

function OrlanStrike:DetectDispellableDebuffs()
	self.HasDispellableDebuff = false;
	AuraUtil.ForEachAura(
		"player",
		"HARMFUL",
		nil,
		function(_, _, _, dispelType, ...)
			if (dispelType == "Disease") or (dispelType == "Poison") then
				self.HasDispellableDebuff = true;
				return true;
			end;
			return false;
		end);
end;

function OrlanStrike:DetectAuras()
	self:DetectForbearance();
	self:DetectDispellableDebuffs();
end;

function OrlanStrike:DetectHealthPercent()
	self.HealthPercent = UnitHealth("player") / UnitHealthMax("player");
end;

function OrlanStrike:DetectManaPercent()
	local mana = UnitPower("player", Enum.PowerType.Mana);
	local maxMana = UnitPowerMax("player", Enum.PowerType.Mana);
	if (not mana) or (not maxMana) or (maxMana == 0) then
		self.ManaPercent = 0;
	else
		self.ManaPercent = mana / maxMana;
	end;
end;

function OrlanStrike:DetectThreat()
	self.IsTanking, _, self.ThreatPercent, self.RawThreatPercent, self.Threat = UnitDetailedThreatSituation("player", "target");
end;

function OrlanStrike:GetRawCooldownExpiration(start, duration, enabled)
	local expiration;
	if start and duration and (duration ~= 0) and (start + duration > GetTime()) then
		expiration = start + duration;
	else
		expiration = GetTime();
	end;
	return expiration;
end;

function OrlanStrike:GetCooldownExpiration(start, duration, enabled)
	local expiration = self:GetRawCooldownExpiration(start, duration, enabled);
	if expiration < self.GcdExpiration then
		expiration = self.GcdExpiration;
	end;
	return expiration;
end;

function OrlanStrike:DetectGcd()
	local start, duration, enabled = GetSpellCooldown(19750); -- Flash of Light
	self.GcdExpiration = self:GetRawCooldownExpiration(start, duration, enabled);
end;

function OrlanStrike:UpdateHolyPowerBar()
	local holyPower = self:GetCurrentGameState().HolyPower;
	local basePower = holyPower;
	if basePower > 3 then
		basePower = 3;
	end;
	local additionalPower = holyPower - basePower;
	self.CastWindow.HolyPowerBar:SetWidth(self.CastWindowWidth * basePower / 3);
	self.CastWindow.HolyPowerBar2:SetWidth(self.CastWindowWidth * additionalPower / 3);
	if holyPower == 0 then
		self.CastWindow.HolyPowerBar:SetColorTexture(0, 0, 0, 0);
	elseif holyPower == 1 then
		self.CastWindow.HolyPowerBar:SetColorTexture(1, 0, 0, 0.3);
	elseif holyPower == 2 then
		self.CastWindow.HolyPowerBar:SetColorTexture(1, 1, 0, 0.3);
	else
		self.CastWindow.HolyPowerBar:SetColorTexture(0, 1, 0, 0.3);
	end;
	if additionalPower == 0 then
		self.CastWindow.HolyPowerBar2:SetColorTexture(0, 0, 0, 0);
	else
		self.CastWindow.HolyPowerBar2:SetColorTexture(0.5, 1, 0.5, 0.3);
	end;
end;

function OrlanStrike:UpdateHealthBar()
	self.CastWindow.HealthBar:SetHeight(self.CastWindowHeight * self.HealthPercent);
	if self.HealthPercent > 0.4 then
		self.CastWindow.HealthBar:SetColorTexture(0, 1, 0, 0.5);
	elseif self.HealthPercent > 0.2 then
		self.CastWindow.HealthBar:SetColorTexture(1, 0.5, 0, 1);
	elseif self.HealthPercent > 0 then
		self.CastWindow.HealthBar:SetColorTexture(1, 0, 0, 1);
	else
		self.CastWindow.HealthBar:SetColorTexture(0, 0, 0, 0);
	end;
end;

function OrlanStrike:UpdateManaBar()
	if self.ManaPercent > 0 then
		self.CastWindow.ManaBar:SetHeight(self.CastWindowHeight * self.ManaPercent);
		self.CastWindow.ManaBar:SetColorTexture(0.2, 0.2, 1, 0.7);
	else
		self.CastWindow.ManaBar:SetColorTexture(0, 0, 0, 0);
	end;
end;

function OrlanStrike:UpdateThreatBar()
	if not self.Threat then
		self.CastWindow.ThreatBar:SetColorTexture(0, 0, 0, 0);
	elseif self.IsTanking then
		self.CastWindow.ThreatBar:SetWidth(self.CastWindowWidth);
		self.CastWindow.ThreatBar:SetColorTexture(1, 0, 0, 1);
	elseif self.ThreatPercent > 100 then
		self.CastWindow.ThreatBar:SetWidth(self.CastWindowWidth);
		self.CastWindow.ThreatBar:SetColorTexture(1, 1, 0, 1);
	elseif self.RawThreatPercent > 100 then
		self.CastWindow.ThreatBar:SetWidth(self.CastWindowWidth * self.ThreatPercent / 100);
		self.CastWindow.ThreatBar:SetColorTexture(1, 1, 0, 1);
	else
		self.CastWindow.ThreatBar:SetWidth(self.CastWindowWidth * self.ThreatPercent / 100);
		self.CastWindow.ThreatBar:SetColorTexture(1, 0, 1, 0.5);
	end;
end;

function OrlanStrike:GetCurrentGameState()
	local _;

	local gameState =
	{
		CloneTo = self.CloneTo,
		HolyPower = UnitPower("player", Enum.PowerType.HolyPower), 
		Time = self.GcdExpiration,
		DivinePurposeExpirationTime = select(6, AuraUtil.FindAuraByName("player", GetSpellInfo(223819))),
		HasDivinePurpose = function(self)
			return self.DivinePurposeExpirationTime and
				self.DivinePurposeExpirationTime > self.Time;
		end,
		EmpyreanPowerExpirationTime = select(6, AuraUtil.FindAuraByName("player", GetSpellInfo(326733))),
		HasEmpyreanPower = function(self)
			return self.EmpyreanPowerExpirationTime and
				self.EmpyreanPowerExpirationTime > self.Time;
		end,
		AvengingWrathExpirationTime = select(6, AuraUtil.FindAuraByName("player", GetSpellInfo(31884))),
		HasAvengingWrath = function(self)
			return self.AvengingWrathExpirationTime and
				self.AvengingWrathExpirationTime > self.Time;
		end,
		TheFiresOfJusticeExpirationTime = select(6, AuraUtil.FindAuraByName("player", GetSpellInfo(209785))),
		HasTheFiresOfJustice = function(self)
			return self.TheFiresOfJusticeExpirationTime and
				self.TheFiresOfJusticeExpirationTime > self.Time;
		end,
		HealthPercent = self.HealthPercent
	};

	if self.GameStateOverride and (self.GameStateOverrideTimeout > GetTime()) then
		self.GameStateOverride:CloneTo(gameState);
	end;

	return gameState;
end;

function OrlanStrike:UpdateStatus()
	self:DetectAuras();
	self:DetectHealthPercent();
	self:DetectManaPercent();
	self:DetectThreat();

	self:DetectGcd();

	self:UpdateHolyPowerBar();
	self:UpdateHealthBar();
	self:UpdateManaBar();
	self:UpdateThreatBar();

	for spellIndex = 1, self.SpellCount do
		local button = self.CastWindow.Buttons[spellIndex];
		if button then
			button:UpdateDisplay(button, self:GetCurrentGameState());
		end;
	end;

	local thisSingleTargetSpellIndex, nextSingleTargetSpellIndex, thisMultiTargetSpellIndex, nextMultiTargetSpellIndex;
	if (not self.Threat) or self.IsTanking or ((self.RawThreatPercent < 95) and (self.Threat * (1 - self.RawThreatPercent) / 100 < UnitHealthMax("player") * 100 / 2)) then
		thisSingleTargetSpellIndex, nextSingleTargetSpellIndex = self:GetSpellsToCast(self.SingleTargetPriorityIndexes);
		thisMultiTargetSpellIndex, nextMultiTargetSpellIndex = self:GetSpellsToCast(self.MultiTargetPriorityIndexes);
	end;

	if nextSingleTargetSpellIndex then
		self:SetTopLeftBorderColor(self.CastWindow.Buttons[nextSingleTargetSpellIndex], 1, 1, 0, 1);
	end;

	if thisSingleTargetSpellIndex then
		self.CastWindow.Buttons[thisSingleTargetSpellIndex]:SetAlpha(1);
		self:SetTopLeftBorderColor(self.CastWindow.Buttons[thisSingleTargetSpellIndex], 0, 1, 0, 1);
	end;

	if nextMultiTargetSpellIndex then
		self:SetBottomRightBorderColor(self.CastWindow.Buttons[nextMultiTargetSpellIndex], 1, 0.5, 0, 1);
	end;

	if thisMultiTargetSpellIndex then
		self.CastWindow.Buttons[thisMultiTargetSpellIndex]:SetAlpha(1);
		self:SetBottomRightBorderColor(self.CastWindow.Buttons[thisMultiTargetSpellIndex], 1, 0, 0, 1);
	end;

	for spellIndex = 1, self.SpellCount do
		local button = self.CastWindow.Buttons[spellIndex];
		if button then
			self:UpdateButtonCooldown(button);
		end;
	end;
end;

function OrlanStrike:IsPrioritySpell(priorityIndex, gameState)
	local button = self.CastWindow.Buttons[priorityIndex.Index];
	return button and (button:GetReason(gameState) >= priorityIndex.MinReason);
end;

function OrlanStrike:GetHasteMultiplier()
	return 1 / (1 + (GetHaste() / 100.0));
end;

function OrlanStrike:GetSpellsToCast(priorityIndexes)
	local minCooldownExpiration;
	local firstSpellIndex;
	local sharedCooldownSpellId;
	local index = 1;
	local gameState = self:GetCurrentGameState();
	while priorityIndexes[index] do
		local priorityIndex = priorityIndexes[index];
		local spellIndex = priorityIndex.Index;
		local button = self.CastWindow.Buttons[spellIndex];
		if button and (button:GetSpellId() == priorityIndex.SpellId) then
			local cooldownExpiration = button:GetCooldownExpiration();
			if (not minCooldownExpiration) or 
					(minCooldownExpiration - self.MaxAbilityWaitTime > cooldownExpiration) then
				gameState.Time = cooldownExpiration;
				if self:IsPrioritySpell(priorityIndex, gameState) then
					minCooldownExpiration = cooldownExpiration;
					firstSpellIndex = spellIndex;
					sharedCooldownSpellId = button:GetSharedCooldownSpellId();
				end;
			end;
		end;

		index = index + 1;
	end;

	local nextMinCooldownExpiration;
	local nextSpellIndex;
	if firstSpellIndex then
		local nextTime = minCooldownExpiration + 1.25;
		local nextSpellCooldownExpirations = {};
		local nextGameState = self:GetCurrentGameState();
		local firstSpellButton = self.CastWindow.Buttons[firstSpellIndex];
		firstSpellButton:UpdateGameState(nextGameState);
		for spellIndex = 1, self.SpellCount do
			local button = self.CastWindow.Buttons[spellIndex];
			if button and button:GetCooldownExpiration() then
				if button:GetCooldownExpiration() < nextTime then
					nextSpellCooldownExpirations[spellIndex] = nextTime;
				else
					nextSpellCooldownExpirations[spellIndex] = button:GetCooldownExpiration();
				end;
			end;
			if sharedCooldownSpellId and 
					button and 
					(button:GetSpellId() == sharedCooldownSpellId) and
					firstSpellButton:GetCooldownLength() then
				nextSpellCooldownExpirations[spellIndex] = minCooldownExpiration +
					firstSpellButton:GetCooldownLength();
			end;
		end;
		if firstSpellButton:GetCooldownLength() then
			nextSpellCooldownExpirations[firstSpellIndex] = minCooldownExpiration +
				firstSpellButton:GetCooldownLength();
		end;
		nextGameState.Time = nextTime;

		index = 1;
		while priorityIndexes[index] do
			local priorityIndex = priorityIndexes[index];
			local spellIndex = priorityIndex.Index;
			local button = self.CastWindow.Buttons[spellIndex];

			if button and (button:GetSpellId() == priorityIndex.SpellId) then
				local cooldownExpiration = button:GetCooldownExpiration();
				if (not nextMinCooldownExpiration) or 
						(nextMinCooldownExpiration - self.MaxAbilityWaitTime > 
							nextSpellCooldownExpirations[spellIndex]) then
					nextGameState.Time = nextSpellCooldownExpirations[spellIndex];
					if self:IsPrioritySpell(priorityIndex, nextGameState) then
						nextMinCooldownExpiration = nextSpellCooldownExpirations[spellIndex];
						nextSpellIndex = spellIndex;
					end;
				end;
			end;

			index = index + 1;
		end;
	end;

	return firstSpellIndex, nextSpellIndex;
end;

function OrlanStrike:UpdateButtonCooldown(button)
	if not button:IsEmpty() then
		local start, duration, enabled = button:GetCooldown();
		local expirationTime;
		if start and (start ~= 0) and duration and (duration ~= 0) and (enabled == 1) then
			expirationTime = start + duration;
		else
			start = 0;
			duration = 0;
			expirationTime = 0;
		end;

		if expirationTime ~= button.Cooldown.Off then
			button.Cooldown.Off = expirationTime;
			if (duration ~= 0) and (expirationTime ~= 0) then
				button.Cooldown:SetCooldown(expirationTime - duration, duration);
			else
				button.Cooldown:SetCooldown(GetTime() - 1, 1);
			end;
		end;
	end;
end;

function OrlanStrike:IsAvengingWrathEnding(gameState)
	return gameState:HasAvengingWrath() and (gameState.AvengingWrathExpirationTime < gameState.Time + 2);
end;

function OrlanStrike:RequestNonCombat()
	if InCombatLockdown() then
		print("OrlanStrike: Cannot be done in combat.");
		return false;
	else
		return true;
	end;
end;

function OrlanStrike:CloneTo(table)
	for key, value in pairs(self) do
		table[key] = value;
	end;
	return table;
end;


OrlanStrike.Button = 
{
	CloneTo = OrlanStrike.CloneTo
};

function OrlanStrike.Button:UpdateGameState(gameState)
end;

function OrlanStrike.Button:GetCooldown()
	return GetSpellCooldown(self:GetSpellId());
end;

function OrlanStrike.Button:IsLearned()
	return IsSpellKnown(self:GetSpellId());
end;

function OrlanStrike.Button:IsAvailable()
	local isUsable, isLackingResources = IsUsableSpell(GetSpellInfo(self:GetSpellId()));
	return self:IsLearned() and (isUsable or isLackingResources);
end;

function OrlanStrike.Button:IsLackingMana()
	local _, isLackingResources = IsUsableSpell(GetSpellInfo(self:GetSpellId()));
	return self:IsAvailable() and isLackingResources;
end;

function OrlanStrike.Button:GetCooldownExpiration()
	local start, duration, enable = self:GetCooldown();
	return self.OrlanStrike:GetCooldownExpiration(start, duration, enable);
end;

function OrlanStrike.Button:IsUsable(gameState)
	return self:IsAvailable() and 
		(self:GetCooldownExpiration() <= gameState.Time) and
		(not self:IsLackingMana()) and
		((not self:DoesRequireTargetCore()) or
			(not UnitCanAttack("player", "target")) or
			(IsSpellInRange(GetSpellInfo(self:GetSpellId()), "target") == 1));
end;

function OrlanStrike.Button:GetReason(gameState)
	if (self:IsUsable(gameState)) then
		return 1;
	end;
	return 0;
end;

function OrlanStrike.Button:UpdateDisplay(window, gameState)
	window:SetAlpha(0.5);
	self.OrlanStrike:SetBorderColor(window, 0, 0, 0, 0);

	if not self:IsUsable(gameState) then
		window:SetAlpha(0.1);
	end;

	local charges, maxCharges = GetSpellCharges(GetSpellInfo(self:GetSpellId()));
	if charges and maxCharges and (maxCharges > 1) then
		window.Text:SetText(tostring(charges));
	end;
end;

function OrlanStrike.Button:IsEmpty()
	return self:GetSpellId() == nil;
end;

function OrlanStrike.Button:DoesRequireTargetCore()
	return self.DoesRequireTarget;
end;

function OrlanStrike.Button:GetSpellId()
	return self.SpellId;
end;

function OrlanStrike.Button:UpdateSpells()
	if self:GetSpellId() then
		local _, _, icon = GetSpellInfo(self:GetSpellId());
		self.Background:SetTexture(icon);
	end;

	if self.Target == "player" then
		self.Text:SetText("self");
	else
		self.Text:SetText("");
	end;
end;

function OrlanStrike.Button:GetSharedCooldownSpellId()
	return self.SharedCooldownSpellId;
end;

function OrlanStrike.Button:SetupButton()
	self.Spell:SetAttribute("type", "spell");
	self.Spell:SetAttribute("spell", self:GetSpellId());
	if self.Target then
		self.Spell:SetAttribute("unit", self.Target);
	end;
end;

function OrlanStrike.Button:GetCooldownLength()
	local inMilliseconds = GetSpellBaseCooldown(self:GetSpellId());
	if inMilliseconds then
		return inMilliseconds / 1000.0 * self.OrlanStrike:GetHasteMultiplier();
	end;
	return nil;
end;

OrlanStrike.HolyPowerGeneratorButton = OrlanStrike.Button:CloneTo({});

function OrlanStrike.HolyPowerGeneratorButton:GetHolyPower()
	return self.HolyPower;
end;

function OrlanStrike.HolyPowerGeneratorButton:GetNewHolyPower(gameState)
	local newHolyPower = gameState.HolyPower + self:GetHolyPower();
	local maxHolyPower = UnitPowerMax("player", Enum.PowerType.HolyPower);
	if newHolyPower > maxHolyPower then
		newHolyPower = maxHolyPower;
	end;
	return newHolyPower;
end;

function OrlanStrike.HolyPowerGeneratorButton:UpdateGameState(gameState)
	self.OrlanStrike.Button.UpdateGameState(self, gameState);

	gameState.HolyPower = self:GetNewHolyPower(gameState);
end;

-- 0 -- no reason
-- 1 -- just damage
-- x + 1 -- +x holy power
function OrlanStrike.HolyPowerGeneratorButton:GetReason(gameState)
	local baseReason = OrlanStrike.Button.GetReason(self, gameState);
	if baseReason == 0 then
		return 0;
	end;

	local newHolyPower = self:GetNewHolyPower(gameState);
	return (newHolyPower - gameState.HolyPower) + 1;
end;

OrlanStrike.BladeOfJusticeButton = OrlanStrike.HolyPowerGeneratorButton:CloneTo(
{
	SpellId = 184575,
	DoesRequireTarget = true
});

function OrlanStrike.BladeOfJusticeButton:GetHolyPower()
	if UnitLevel("player") >= 34 then
		return 2;
	end;
	return 1;
end;

OrlanStrike.JudgmentButton = OrlanStrike.HolyPowerGeneratorButton:CloneTo(
{
	SpellId = 20271,
	DoesRequireTarget = true
});


function OrlanStrike.JudgmentButton:GetHolyPower()
	if UnitLevel("player") >= 16 then
		return 1;
	end;
	return 0;
end;

OrlanStrike.BurstButton = OrlanStrike.Button:CloneTo({});

function OrlanStrike.BurstButton:UpdateDisplay(window, gameState)
	self.OrlanStrike.Button.UpdateDisplay(self, window, gameState);

	if self:GetReason(gameState) > 0 then
		window:SetAlpha(1);
		self.OrlanStrike:SetBorderColor(window, 1, 1, 1, 1);
	end;
end;

OrlanStrike.AvengingWrathButton = OrlanStrike.BurstButton:CloneTo(
{
	SpellId = 31884
});

function OrlanStrike.AvengingWrathButton:UpdateGameState(gameState)
	self.OrlanStrike.BurstButton.UpdateGameState(self, gameState);
	gameState.AvengingWrathExpirationTime = gameState.Time + 20;
end;

OrlanStrike.SlotButton = OrlanStrike.BurstButton:CloneTo({});

function OrlanStrike.SlotButton:SetupButton()
	self.Spell:SetAttribute("type", "item");
	self.Spell:SetAttribute("item", GetInventorySlotInfo(self.SlotName));
end;

function OrlanStrike.SlotButton:UpdateSpells()
	local slotId, texture = GetInventorySlotInfo(self.SlotName);
	texture = GetInventoryItemTexture("player", slotId) or texture;
	self.Background:SetTexture(texture);
end;

function OrlanStrike.SlotButton:GetCooldown()
	return GetInventoryItemCooldown("player", GetInventorySlotInfo(self.SlotName));
end;

function OrlanStrike.SlotButton:IsLearned()
	return true;
end;

function OrlanStrike.SlotButton:IsAvailable()
	local _, _, enabled = GetInventoryItemCooldown("player", GetInventorySlotInfo(self.SlotName));
	return enabled == 1;
end;

function OrlanStrike.SlotButton:IsLackingMana()
	return false;
end;

function OrlanStrike.SlotButton:IsEmpty()
	return false;
end;

OrlanStrike.PotButton = OrlanStrike.Button:CloneTo({});

function OrlanStrike.PotButton:UpdateDisplay(window, gameState)
	self.OrlanStrike.Button.UpdateDisplay(self, window, gameState);

	window.Text:SetText(tostring(GetItemCount(self.ItemId)));
end;

function OrlanStrike.PotButton:SetupButton()
	if GetItemInfo(self.ItemId) then
		self.Spell:SetAttribute("type", "macro");
		self.Spell:SetAttribute("macrotext", "/use " .. GetItemInfo(self.ItemId));
	else
		local button = self;
		C_Timer.After(1, function() OrlanStrike.PotButton.SetupButton(button); end);
	end;
end;

function OrlanStrike.PotButton:GetCooldown()
	return GetItemCooldown(self.ItemId);
end;

function OrlanStrike.PotButton:IsLearned()
	return true;
end;

function OrlanStrike.PotButton:IsAvailable()
	return GetItemCount(self.ItemId) > 0;
end;

function OrlanStrike.PotButton:IsLackingMana()
	return false;
end;

OrlanStrike.BurstPotButton = OrlanStrike.PotButton:CloneTo({});

function OrlanStrike.BurstPotButton:UpdateDisplay(window, gameState)
	self.OrlanStrike.PotButton.UpdateDisplay(self, window, gameState);

	if self:GetReason(gameState) > 0 then
		window:SetAlpha(1);
		self.OrlanStrike:SetBorderColor(window, 1, 1, 1, 1);
	end;

	if not self:IsAvailable() then
		self.OrlanStrike:SetBorderColor(window, 0, 1, 1, 1);
		window:SetAlpha(0.4);
	end;
end;

OrlanStrike.ThreeHolyPowerButton = OrlanStrike.Button:CloneTo({});

function OrlanStrike.ThreeHolyPowerButton:IsLackingMana()
	return false;
end;

function OrlanStrike.ThreeHolyPowerButton:HasJusticarsVengeanceTalent()
	local _, _, _, isTalentSelected, _, spellId = GetTalentInfo(5, 1, 1); -- Justicar's Vengeance
	return (spellId == 215661) and isTalentSelected; -- Justicar's Vengeance
end;

function OrlanStrike.ThreeHolyPowerButton:IsUsable(gameState)
	if not self.OrlanStrike.Button.IsUsable(self, gameState) then
		return false;
	end;

	return gameState.HolyPower >= self:GetHolyPowerCost(gameState);
end;

function OrlanStrike.ThreeHolyPowerButton:GetHolyPowerCost(gameState)
	local cost = 3;
	if gameState:HasTheFiresOfJustice() then
		cost = cost - 1;
	end;
	if gameState:HasDivinePurpose() then
		cost = 0;
	end;
	return cost;
end;

function OrlanStrike.ThreeHolyPowerButton:UpdateGameState(gameState)
	self.OrlanStrike.Button.UpdateGameState(self, gameState);

	local cost = self:GetHolyPowerCost(gameState);

	if gameState.HolyPower < cost then
		gameState.HolyPower = 0;
	else
		gameState.HolyPower = gameState.HolyPower - cost;
	end;
end;

function OrlanStrike.ThreeHolyPowerButton:GetReason(gameState)
	local baseReason = OrlanStrike.Button.GetReason(self, gameState);
	if baseReason == 0 then
		return 0;
	end;
	if self:HasJusticarsVengeanceTalent() and (gameState.HealthPercent <= 0.2) then
		return 0;
	end;
	return baseReason;
end;

OrlanStrike.DivineStormButton = OrlanStrike.ThreeHolyPowerButton:CloneTo(
{
	SpellId = 53385 -- Divine Storm
});

function OrlanStrike.DivineStormButton:GetHolyPowerCost(gameState)
	if gameState:HasEmpyreanPower() then
		return 0;
	end;
	return OrlanStrike.ThreeHolyPowerButton.GetHolyPowerCost(self, gameState);
end;

OrlanStrike.HealthButton = OrlanStrike.Button:CloneTo({});

function OrlanStrike.HealthButton:GetReason(gameState)
	if (gameState.HealthPercent <= 0.3) and 
		(self.OrlanStrike.Button.GetReason(self, gameState) > 0) then
		return 1;
	end;
	return 0;
end;

OrlanStrike.CleanseToxinsButton = OrlanStrike.Button:CloneTo(
{
	SpellId = 213644,
	Target = "player"
});

function OrlanStrike.CleanseToxinsButton:IsUsable(gameState)
	return self.OrlanStrike.Button.IsUsable(self, gameState) and self.OrlanStrike.HasDispellableDebuff;
end;

function OrlanStrike.CleanseToxinsButton:UpdateDisplay(window, gameState)
	self.OrlanStrike.Button.UpdateDisplay(self, window, gameState);

	if self:GetReason(gameState) > 0 then
		self.OrlanStrike:SetBorderColor(window, 1, 0, 1, 1);
		window:SetAlpha(1);
	end;
end;

OrlanStrike.RebukeButton = OrlanStrike.Button:CloneTo(
{
	SpellId = 96231 -- Rebuke
});

function OrlanStrike.RebukeButton:GetReason(gameState)
	local spell, _, _, _, _, _, _, nonInterruptible = UnitCastingInfo("target");
	if (self.OrlanStrike.Button.GetReason(self, gameState) > 0) and 
		spell and 
		not nonInterruptible then
		return 1;
	end;
	return 0;
end;

function OrlanStrike.RebukeButton:UpdateDisplay(window, gameState)
	self.OrlanStrike.Button.UpdateDisplay(self, window, gameState);

	if self:GetReason(gameState) > 0 then
		self.OrlanStrike:SetBorderColor(window, 0.6, 0.3, 0, 1);
		window:SetAlpha(1);
	else
		window:SetAlpha(0.1);
	end;
end;

OrlanStrike.WakeOfAshesButton = OrlanStrike.HolyPowerGeneratorButton:CloneTo(
{
	SpellId = 255937,
	HolyPower = 3
});

function OrlanStrike.WakeOfAshesButton:UpdateDisplay(window, gameState)
	self.OrlanStrike.HolyPowerGeneratorButton.UpdateDisplay(self, window, gameState);

	if self:GetReason(gameState) >= 4 then
		window:SetAlpha(1);
		self.OrlanStrike:SetBorderColor(window, 1, 1, 1, 1);
	end;
end;

OrlanStrike.CrusaderStrikeButton = OrlanStrike.HolyPowerGeneratorButton:CloneTo(
{
	SpellId = 35395,
	DoesRequireTarget = true,
	HolyPower = 1
});

-- 0 -- no reason
-- 1 -- just damage
-- 2 -- +1 holy power @ 1 charge or Avenging Wrath or <20% target health
-- 3 -- +1 holy power @ 2 charges
function OrlanStrike.HolyPowerGeneratorButton:GetReason(gameState)
	local baseReason = OrlanStrike.CrusaderStrikeButton.GetReason(self, gameState);
	if baseReason < 2 then
		return baseReason;
	end;

	if gameState.HasAvengingWrath() then
		return 2;
	end;

	local targetHealth = UnitHealth("target");
	if (targetHealth > 0) and (targetHealth * 5 < UnitMaxHealth("target")) then
		return 2;
	end;

	local charges = GetSpellCharges(GetSpellInfo(self:GetSpellId()));
	if charges >= 2 then
		return 3;
	end;

	return baseReason;
end;

OrlanStrike:Initialize("OrlanStrikeConfig");
