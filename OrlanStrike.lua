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
	self.RowCount = 6;
	self.ColumnCount = 5;
	self.CastWindowHeight = self.ButtonSize * self.RowCount + self.ButtonSpacing * (self.RowCount + 1);
	self.CastWindowWidth = self.ButtonSize * self.ColumnCount + self.ButtonSpacing * (self.ColumnCount + 1);

	self.FrameRate = 10.0;

	function self.EventFrame:HandleEvent(event, arg1, arg2, arg3, arg4, arg5)
		if (event == "ADDON_LOADED") and (arg1 == "OrlanStrike") then
			orlanStrike:HandleLoaded();
		elseif (event == "ACTIVE_TALENT_GROUP_CHANGED") then
			orlanStrike:HandleTalentChange();
		elseif (event == "UNIT_SPELLCAST_START") and (arg1 == "player") then
			orlanStrike:HandleAbilityUse(arg5);
		elseif (event == "SPELLS_CHANGED") or (event == "PLAYER_EQUIPMENT_CHANGED") then
			orlanStrike:UpdateSpells();
		end;
	end;

	self.EventFrame:RegisterEvent("ADDON_LOADED");
	self.EventFrame:SetScript("OnEvent", self.EventFrame.HandleEvent);

	self.CastWindowStrata = "LOW";
	self.CastWindowName = "OrlanStrike_CastWindow";

	self.HolyPowerGenerators =
	{
		[879] = true, -- Exorcism
		[20271] = true, -- Judgment
		[23275] = true, -- Hammer of Wrath
		[35395] = true, -- Crusader Strike
		[53595] = true -- Hammer of the Righteous
	};
	self.SingleTargetPriorities =
	{
		{
			SpellId = 20271, -- Judgment
			MinReason = 2
		},
		{
			SpellId = 105361, -- Seal of Command
			MinReason = 3
		},
		{
			SpellId = 20154, -- Seal of Righteousness
			MinReason = 3
		},
		{
			SpellId = 105361, -- Seal of Command
			MinReason = 2
		},
		{
			SpellId = 152262 -- Seraphim
		},
		{
			SpellId = 85673, -- Word of Glory
			MinReason = 2
		},
		{
			SpellId = 85256, -- Templar's Verdict
			MinReason = 2
		},
		{
			SpellId = 879 -- Exorcism
		},
		{
			SpellId = 24275 -- Hammer of Wrath
		},
		{
			SpellId = 35395 -- Crusader Strike
		},
		{
			SpellId = 20271 -- Judgment
		}
	};
	self.MultiTargetPriorities =
	{
		{
			SpellId = 20271, -- Judgment
			MinReason = 2
		},
		{
			SpellId = 20154, -- Seal of Righteousness
			MinReason = 3
		},
		{
			SpellId = 105361, -- Seal of Command
			MinReason = 3
		},
		{
			SpellId = 20154, -- Seal of Righteousness
			MinReason = 2
		},
		{
			SpellId = 152262 -- Seraphim
		},
		{
			SpellId = 85256, -- Templar's Verdict
			MinReason = 3
		},
		{
			SpellId = 53385, -- Divine Storm
			MinReason = 2
		},
		{
			SpellId = 85673, -- Word of Glory
			MinReason = 2
		},
		{
			SpellId = 85256, -- Templar's Verdict
			MinReason = 2
		},
		{
			SpellId = 879 -- Exorcism
		},
		{
			SpellId = 24275 -- Hammer of Wrath
		},
		{
			SpellId = 53595 -- Hammer of the Righteous
		},
		{
			SpellId = 35395 -- Crusader Strike
		},
		{
			SpellId = 20271 -- Judgment
		}
	};
	self.MaxAbilityWaitTime = 0.1;
	self.HealingSpellPriorities =
	{
		{
			SpellId = 85673, -- Word of Glory
			Target = "player"
		},
		{
			SpellId = 19750, -- Flash of Light
			Target = "player"
		},
		{
			SpellId = 633, -- Lay on Hands
			Target = "player"
		},
		{
			SpellId = 642 -- Divine Shield
		},
		{
			SpellId = 20925, -- Sacred Shield
			Target = "player"
		},
		{
			SpellId = 175699, -- Weapons of the Light
			Target = "player"
		}
	};
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
	castWindow.Background:SetTexture(0, 0, 0, 0.3);

	castWindow.Buttons =
	{
		self:CreateButton(
			castWindow, 
			self.TemplarsVerdictButton:CloneTo(
			{
				Row = 0,
				Column = 1
			})),
		self:CreateButton(
			castWindow,
			self.ExorcismButton:CloneTo(
			{
				Row = 0,
				Column = 2,
			})),
		self:CreateButton(
			castWindow, 
			self.HolyPowerGeneratorButton:CloneTo(
			{
				SpellId = 35395, -- Crusader Strike
				SharedCooldownSpellId = 53595, -- Hammer of the Righteous
				Row = 0,
				Column = 3,
				CooldownLength = 4.5,
				DoesRequireTarget = true
			})),
		self:CreateButton(
			castWindow, 
			self.JudgmentButton:CloneTo(
			{
				Row = 0,
				Column = 4
			})),
		self:CreateButton(
			castWindow, 
			self.DivineStormButton:CloneTo(
			{
				Row = 1,
				Column = 1
			})),
		self:CreateButton(
			castWindow, 
			self.HolyPowerGeneratorButton:CloneTo(
			{
				SpellId = 24275, -- Hammer of Wrath
				Row = 1,
				Column = 2,
				CooldownLength = 6,
				DoesRequireTarget = true
			})),
		self:CreateButton(
			castWindow, 
			self.HolyPowerGeneratorButton:CloneTo(
			{
				SpellId = 53595, -- Hammer of the Righteous
				SharedCooldownSpellId = 35395, -- Crusader Strike
				Row = 1,
				Column = 3,
				CooldownLength = 4.5,
				DoesRequireTarget = true
			})),
		self:CreateButton(
			castWindow, 
			self.PotButton:CloneTo(
			{
				Row = 3,
				Column = 0
			})),
		self:CreateButton(
			castWindow, 
			self.SlotButton:CloneTo(
			{
				Row = 3,
				Column = 1,
				SlotName = "Trinket0Slot"
			})),
		self:CreateButton(
			castWindow, 
			self.SlotButton:CloneTo(
			{
				Row = 3,
				Column = 2,
				SlotName = "Trinket1Slot"
			})),
		self:CreateButton(
			castWindow, 
			self.HolyAvengerButton:CloneTo(
			{
				Row = 2,
				Column = 0
			})),
		self:CreateButton(
			castWindow, 
			self.AvengingWrathButton:CloneTo(
			{
				Row = 2,
				Column = 1
			})),
		self:CreateButton(
			castWindow, 
			self.CleanseButton:CloneTo(
			{
				Row = 4,
				Column = 0
			})),
		self:CreateButton(
			castWindow, 
			self.WordOfGloryButton:CloneTo(
			{
				Row = 4,
				Column = 1
			})),
		self:CreateButton(
			castWindow, 
			self.FlashOfLightButton:CloneTo(
			{
				Row = 4,
				Column = 2
			})),
		self:CreateButton(
			castWindow, 
			self.LayOnHandsButton:CloneTo(
			{
				Row = 4,
				Column = 3
			})),
		self:CreateButton(
			castWindow, 
			self.HealthButton:CloneTo(
			{
				SpellId = 642, -- Divine Shield
				Row = 4,
				Column = 4
			})),
		self:CreateButton(
			castWindow, 
			self.SealOfTruthButton:CloneTo(
			{
				Row = 2,
				Column = 3
			})),
		self:CreateButton(
			castWindow, 
			self.SealOfRighteousnessButton:CloneTo(
			{
				Row = 2,
				Column = 4
			})),
		self:CreateButton(
			castWindow, 
			self.Button:CloneTo(
			{
				SpellId = 114039, -- Hand of Purity
				Row = 5,
				Column = 0,
				Target = "player"
			})),
		self:CreateButton(
			castWindow, 
			self.HealthButton:CloneTo(
			{
				SpellId = 20925, -- Sacred Shield
				Row = 5,
				Column = 1,
				Target = "player"
			})),
		self:CreateButton(
			castWindow, 
			self.Button:CloneTo(
			{
				SpellId = 498, -- Divine Protection
				Row = 5,
				Column = 2,
				Target = "player"
			})),
		self:CreateButton(
			castWindow, 
			self.Button:CloneTo(
			{
				SpellId = 1022, -- Hand of Protection
				Row = 5,
				Column = 4
			})),
		self:CreateButton(
			castWindow, 
			self.RebukeButton:CloneTo(
			{
				Row = 1,
				Column = 4
			})),
		self:CreateButton(
			castWindow,
			self.WeaponsOfTheLightButton:CloneTo(
			{
				Row = 1,
				Column = 0
			})),
		self:CreateButton(
			castWindow,
			self.SelfWeaponsOfTheLightButton:CloneTo(
			{
				Row = 5,
				Column = 3
			})),
		self:CreateButton(
			castWindow,
			self.SeraphimButton:CloneTo(
			{
				Row = 0,
				Column = 0
			})),
		self:CreateButton(
			castWindow,
			self.HarshWordButton:CloneTo(
			{
				Row = 2,
				Column = 2
			}))
	};
	self.SpellCount = 30;

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
	self.HealingSpellPriorityIndexes = self:CalculateSpellPriorityIndexes(self.HealingSpellPriorities);
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
	button.Text:SetTextHeight(self.ButtonSize / 2);
	button.Text:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 0);
	button.Text:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 2, 0);
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
	window.TopBorder:SetTexture(r, g, b, a);
	window.BottomBorder:SetTexture(r, g, b, a);
	window.LeftBorder:SetTexture(r, g, b, a);
	window.RightBorder:SetTexture(r, g, b, a);
end;

function OrlanStrike:SetTopLeftBorderColor(window, r, g, b, a)
	window.TopBorder:SetTexture(r, g, b, a);
	window.LeftBorder:SetTexture(r, g, b, a);
end;

function OrlanStrike:SetBottomRightBorderColor(window, r, g, b, a)
	window.BottomBorder:SetTexture(r, g, b, a);
	window.RightBorder:SetTexture(r, g, b, a);
end;

function OrlanStrike:HandleLoaded()
	_G[self.ConfigName] = _G[self.ConfigName] or {};
	self.Config = _G[self.ConfigName];
	self.Config.Scale = self.Config.Scale or 1;

	self.CastWindow = self:CreateCastWindow();

	self:Show();

	self.EventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED");
	self.EventFrame:RegisterEvent("UNIT_SPELLCAST_START");
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

function OrlanStrike:HandleTalentChange()
	self.IsTalentTreeUpdated = false;
end;

function OrlanStrike:UpdateTalentTree()
	local tree = GetSpecialization();
	if not tree or (tree == 3) then
		self:Show();
		self.IsTalentTreeUpdated = true;
	elseif tree then
		self:Hide();
		self.IsTalentTreeUpdated = true;
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
	self.HasForbearance = UnitDebuff("player", forbearanceSpellName);
end;

function OrlanStrike:DetectDispellableDebuffs()
	local debuffIndex = 1;
	while true do
		local debuffName, _, _, _, dispelType = UnitDebuff("player", debuffIndex);
		if not debuffName then
			self.HasDispellableDebuff = false;
			break;
		end;
		if (dispelType == "Disease") or (dispelType == "Poison") then
			self.HasDispellableDebuff = true;
			break;
		end;

		debuffIndex = debuffIndex + 1;
	end;
end;

function OrlanStrike:DetectAuras()
	self:DetectForbearance();
	self:DetectDispellableDebuffs();
end;

function OrlanStrike:DetectHealthPercent()
	self.HealthPercent = UnitHealth("player") / UnitHealthMax("player");
end;

function OrlanStrike:DetectManaPercent()
	local mana = UnitPower("player", SPELL_POWER_MANA);
	local maxMana = UnitPowerMax("player", SPELL_POWER_MANA);
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
	local start, duration, enabled = GetSpellCooldown(20154); -- Seal of Righteousness
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
		self.CastWindow.HolyPowerBar:SetTexture(0, 0, 0, 0);
	elseif holyPower == 1 then
		self.CastWindow.HolyPowerBar:SetTexture(1, 0, 0, 0.3);
	elseif holyPower == 2 then
		self.CastWindow.HolyPowerBar:SetTexture(1, 1, 0, 0.3);
	else
		self.CastWindow.HolyPowerBar:SetTexture(0, 1, 0, 0.3);
	end;
	if additionalPower == 0 then
		self.CastWindow.HolyPowerBar2:SetTexture(0, 0, 0, 0);
	else
		self.CastWindow.HolyPowerBar2:SetTexture(0.5, 1, 0.5, 0.3);
	end;
end;

function OrlanStrike:UpdateHealthBar()
	self.CastWindow.HealthBar:SetHeight(self.CastWindowHeight * self.HealthPercent);
	if self.HealthPercent > 0.4 then
		self.CastWindow.HealthBar:SetTexture(0, 1, 0, 0.5);
	elseif self.HealthPercent > 0.2 then
		self.CastWindow.HealthBar:SetTexture(1, 0.5, 0, 1);
	elseif self.HealthPercent > 0 then
		self.CastWindow.HealthBar:SetTexture(1, 0, 0, 1);
	else
		self.CastWindow.HealthBar:SetTexture(0, 0, 0, 0);
	end;
end;

function OrlanStrike:UpdateManaBar()
	if self.ManaPercent > 0 then
		self.CastWindow.ManaBar:SetHeight(self.CastWindowHeight * self.ManaPercent);
		self.CastWindow.ManaBar:SetTexture(0.2, 0.2, 1, 0.7);
	else
		self.CastWindow.ManaBar:SetTexture(0, 0, 0, 0);
	end;
end;

function OrlanStrike:UpdateThreatBar()
	if not self.Threat then
		self.CastWindow.ThreatBar:SetTexture(0, 0, 0, 0);
	elseif self.IsTanking then
		self.CastWindow.ThreatBar:SetWidth(self.CastWindowWidth);
		self.CastWindow.ThreatBar:SetTexture(1, 0, 0, 1);
	elseif self.ThreatPercent > 100 then
		self.CastWindow.ThreatBar:SetWidth(self.CastWindowWidth);
		self.CastWindow.ThreatBar:SetTexture(1, 1, 0, 1);
	elseif self.RawThreatPercent > 100 then
		self.CastWindow.ThreatBar:SetWidth(self.CastWindowWidth * self.ThreatPercent / 100);
		self.CastWindow.ThreatBar:SetTexture(1, 1, 0, 1);
	else
		self.CastWindow.ThreatBar:SetWidth(self.CastWindowWidth * self.ThreatPercent / 100);
		self.CastWindow.ThreatBar:SetTexture(1, 0, 1, 0.5);
	end;
end;

function OrlanStrike:GetCurrentGameState()
	local _;

	local gameState =
	{
		CloneTo = self.CloneTo,
		HolyPower = UnitPower("player", SPELL_POWER_HOLY_POWER), 
		Time = self.GcdExpiration,
		DivinePurposeExpirationTime = select(7, UnitBuff("player", GetSpellInfo(90174))),
		HasDivinePurpose = function(self)
			return self.DivinePurposeExpirationTime and
				self.DivinePurposeExpirationTime > self.Time;
		end,
		FinalVerdictExpirationTime = select(7, UnitBuff("player", GetSpellInfo(157048))),
		HasFinalVerdict = function(self)
			return self.FinalVerdictExpirationTime and
				self.FinalVerdictExpirationTime > self.Time;
		end,
		SeraphimExpirationTime = select(7, UnitBuff("player", GetSpellInfo(152262))),
		HasSeraphim = function(self)
			return self.SeraphimExpirationTime and
				self.SeraphimExpirationTime > self.Time;
		end,
		AvengingWrathExpirationTime = select(7, UnitBuff("player", GetSpellInfo(31884))),
		HasAvengingWrath = function(self)
			return self.AvengingWrathExpirationTime and
				self.AvengingWrathExpirationTime > self.Time;
		end,
		HasSealOfTruth = GetShapeshiftForm() == 1,
		HasSealOfRighteousness = GetShapeshiftForm() == 2,
		HolyAvengerExpirationTime = select(7, UnitBuff("player", GetSpellInfo(105809))),
		HasHolyAvenger = function(self)
			return self.HolyAvengerExpirationTime and
				self.HolyAvengerExpirationTime > self.Time;
		end,
		HealthPercent = self.HealthPercent,
		MaraadsTruthExpirationTime = select(7, UnitBuff("player", GetSpellInfo(156990))),
		HasMaraadsTruth = function(self)
			return self.MaraadsTruthExpirationTime and
				self.MaraadsTruthExpirationTime > self.Time;
		end,
		LiadrinsRighteousnessExpirationTime = select(7, UnitBuff("player", GetSpellInfo(156989))),
		HasLiadrinsRighteousness = function(self)
			return self.LiadrinsRighteousnessExpirationTime and
				self.LiadrinsRighteousnessExpirationTime > self.Time;
		end,
		BlazingContemptExpirationTime = select(7, UnitBuff("player", GetSpellInfo(166831))),
		HasBlazingContempt = function(self)
			return self.BlazingContemptExpirationTime and
				self.BlazingContemptExpirationTime > self.Time;
		end,
		DivineCrusaderExpirationTime = select(7, UnitBuff("player", GetSpellInfo(144595))),
		HasDivineCrusader = function(self)
			return self.DivineCrusaderExpirationTime and
				self.DivineCrusaderExpirationTime > self.Time;
		end
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
	if (not self.Threat) or self.IsTanking or ((self.RawThreatPercent < 95) and (self.Threat * (1 - self.RawThreatPercent) / 100 < 150000 * 100)) then
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

	local healingSpellIndex = 1;
	while self.HealingSpellPriorityIndexes[healingSpellIndex] do
		local priorityIndex = self.HealingSpellPriorityIndexes[healingSpellIndex];
		if self:IsPrioritySpell(priorityIndex, self:GetCurrentGameState()) then
			local button = self.CastWindow.Buttons[priorityIndex.Index];
			self:SetBorderColor(button, 1, 0.5, 0.5, 1);
			button:SetAlpha(1);
			break;
		end;

		healingSpellIndex = healingSpellIndex + 1;
	end;
end;

function OrlanStrike:IsPrioritySpell(priorityIndex, gameState)
	local button = self.CastWindow.Buttons[priorityIndex.Index];
	return button and (button:GetReason(gameState) >= priorityIndex.MinReason);
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
					firstSpellButton.CooldownLength then
				nextSpellCooldownExpirations[spellIndex] = minCooldownExpiration + firstSpellButton.CooldownLength;
			end;
		end;
		if firstSpellButton.CooldownLength then
			nextSpellCooldownExpirations[firstSpellIndex] = minCooldownExpiration + firstSpellButton.CooldownLength;
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
		if start and duration and (enabled == 1) then
			expirationTime = start + duration;
		else
			start = nil;
			duration = nil;
			expirationTime = nil;
		end;

		duration = duration or 0;
		expirationTime = expirationTime or 0;
		if expirationTime ~= button.Cooldown.Off then
			button.Cooldown.Off = expirationTime;
			if (duration ~= 0) and (expirationTime ~= 0) then
				button.Cooldown:SetCooldown(expirationTime - duration, duration);
			else
				button.Cooldown:SetCooldown(GetTime() - 20, 10);
			end;
		end;
	end;
end;

function OrlanStrike:IsSeraphimCooldownEnding(gameState)
	local seraphimCooldownExpiration = self:GetCooldownExpiration(GetSpellCooldown(GetSpellInfo(152262)));
	return (seraphimCooldownExpiration > gameState.Time) and (seraphimCooldownExpiration < gameState.Time + 3);
end;

function OrlanStrike:IsSeraphimEnding(gameState)
	return gameState:HasSeraphim() and (gameState.SeraphimExpirationTime < gameState.Time + 3.5);
end;

function OrlanStrike:IsAvengingWrathEnding(gameState)
	return gameState:HasAvengingWrath() and (gameState.AvengingWrathExpirationTime < gameState.Time + 2);
end;

function OrlanStrike:AreEmpoweredSealsKnown()
	return select(4, GetTalentInfo(7, 1, GetActiveSpecGroup()));
end;

function OrlanStrike:HasGlyph(glyphId)
	for socket = 1, NUM_GLYPH_SLOTS do
		local _, _, _, currentGlyphId = GetGlyphSocketInfo(socket);
		if currentGlyphId == glyphId then
			return true;
		end;
	end;
	return false;
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
	return GetSpellCooldown(GetSpellInfo(self:GetSpellId()));
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
		((not self.DoesRequireTarget) or
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
end;

function OrlanStrike.Button:IsEmpty()
	return self:GetSpellId() == nil;
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

OrlanStrike.HolyPowerGeneratorButton = OrlanStrike.Button:CloneTo({});

function OrlanStrike.HolyPowerGeneratorButton:UpdateGameState(gameState)
	self.OrlanStrike.Button.UpdateGameState(self, gameState);

	if gameState:HasHolyAvenger() then
		gameState.HolyPower = gameState.HolyPower + 3;
	else
		gameState.HolyPower = gameState.HolyPower + 1;
	end;

	local maxHolyPower = UnitPowerMax("player", SPELL_POWER_HOLY_POWER);
	if gameState.HolyPower > maxHolyPower then
		gameState.HolyPower = maxHolyPower;
	end;
end;

OrlanStrike.JudgmentButton = OrlanStrike.HolyPowerGeneratorButton:CloneTo(
{
	SpellId = 20271,
	CooldownLength = 6,
	DoesRequireTarget = true
});

function OrlanStrike.JudgmentButton:GetReason(gameState)
	if self.OrlanStrike.HolyPowerGeneratorButton.GetReason(self, gameState) == 0 then
		return 0;
	elseif self.OrlanStrike:AreEmpoweredSealsKnown() then
		if gameState.HasSealOfTruth then
			if ((not gameState:HasMaraadsTruth()) or 
				(gameState.MaraadsTruthExpirationTime < gameState.Time + 2)) then
				return 2;
			elseif ((not gameState:HasLiadrinsRighteousness()) or 
					(gameState.LiadrinsRighteousnessExpirationTime < gameState.Time + 2)) and
				(gameState.MaraadsTruthExpirationTime <= gameState.Time + 12) then
				return 2;
			elseif gameState:HasLiadrinsRighteousness() and
				(gameState.MaraadsTruthExpirationTime - gameState.LiadrinsRighteousnessExpirationTime <= 10) then
				return 2;
			end;
		elseif gameState.HasSealOfRighteousness then
			if ((not gameState:HasLiadrinsRighteousness()) or 
				(gameState.LiadrinsRighteousnessExpirationTime < gameState.Time + 2)) then
				return 2;
			elseif ((not gameState:HasMaraadsTruth()) or 
					(gameState.MaraadsTruthExpirationTime < gameState.Time + 2)) and
				(gameState.LiadrinsRighteousnessExpirationTime <= gameState.Time + 12) then
				return 2;
			elseif gameState:HasMaraadsTruth() and
				(gameState.LiadrinsRighteousnessExpirationTime - gameState.MaraadsTruthExpirationTime <= 10) then
				return 2;
			end;
		end;
	end;
	return 1;
end;

function OrlanStrike.JudgmentButton:UpdateGameState(gameState)
	self.OrlanStrike.HolyPowerGeneratorButton.UpdateGameState(self, gameState);
	if self.OrlanStrike:AreEmpoweredSealsKnown() then
		if gameState.HasSealOfTruth then
			gameState.MaraadsTruthExpirationTime = gameState.Time + 20;
		elseif gameState.HasSealOfRighteousness then
			gameState.LiadrinsRighteousnessExpirationTime = gameState.Time + 20;
		end;
	end;
end;

OrlanStrike.ExorcismButton = OrlanStrike.HolyPowerGeneratorButton:CloneTo(
{
	SpellId = 879, -- Exorcism
	CooldownLength = 15,
	DoesRequireTarget = true
});

function OrlanStrike.ExorcismButton:UpdateGameState(gameState)
	self.OrlanStrike.Button.UpdateGameState(self, gameState);

	if gameState:HasBlazingContempt() then
		gameState.HolyPower = gameState.HolyPower + 3;
		gameState.BlazingContemptExpirationTime = nil;
	elseif gameState:HasHolyAvenger() then
		gameState.HolyPower = gameState.HolyPower + 3;
	else
		gameState.HolyPower = gameState.HolyPower + 1;
	end;

	local maxHolyPower = UnitPowerMax("player", SPELL_POWER_HOLY_POWER);
	if gameState.HolyPower > maxHolyPower then
		gameState.HolyPower = maxHolyPower;
	end;
end;

function OrlanStrike.ExorcismButton:GetCooldown()
	local start1, duration1, enable1 = GetSpellCooldown(GetSpellInfo(self:GetSpellId()));
	local start2, duration2, enable2 = GetSpellCooldown(GetSpellInfo(122032)); -- Exorcism with Glyph of Mass Exorcism
	local start, duration, enable;
	if duration1 and ((not duration2) or (duration1 > duration2)) then
		start = start1;
		duration = duration1;
		enable = enable1;
	else
		start = start2;
		duration = duration2;
		enable = enable2;
	end;
	return start, duration, enable;
end;

OrlanStrike.BurstButton = OrlanStrike.Button:CloneTo({});

function OrlanStrike.BurstButton:UpdateDisplay(window, gameState)
	self.OrlanStrike.Button.UpdateDisplay(self, window, gameState);

	if self:GetReason(gameState) > 0 then
		window:SetAlpha(1);
		self.OrlanStrike:SetBorderColor(window, 1, 1, 1, 1);
	end;
end;

OrlanStrike.HolyAvengerButton = OrlanStrike.BurstButton:CloneTo(
{
	SpellId = 105809
});

function OrlanStrike.HolyAvengerButton:UpdateGameState(gameState)
	self.OrlanStrike.BurstButton.UpdateGameState(self, gameState);
	gameState.HolyAvengerExpirationTime = gameState.Time + 18;
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

OrlanStrike.PotButton = OrlanStrike.BurstButton:CloneTo(
{
	SpellId = 156428, -- Draenic Strength Potion
	ItemId = 109219 -- Draenic Strength Potion
});

function OrlanStrike.PotButton:UpdateDisplay(window, gameState)
	self.OrlanStrike.BurstButton.UpdateDisplay(self, window, gameState);

	window.Text:SetText(tostring(GetItemCount(self.ItemId)));

	if not self:IsAvailable() then
		self.OrlanStrike:SetBorderColor(window, 0, 1, 1, 1);
		window:SetAlpha(0.4);
	end;
end;

function OrlanStrike.PotButton:SetupButton()
	self.Spell:SetAttribute("type", "macro");
	self.Spell:SetAttribute("macrotext", "/use " .. GetItemInfo(self.ItemId));
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

OrlanStrike.WeaponsOfTheLightButton = OrlanStrike.BurstButton:CloneTo(
{
	SpellId = 175699
});

function OrlanStrike.WeaponsOfTheLightButton:SetupButton()
	self.Spell:SetAttribute("type", "macro");
	self.Spell:SetAttribute("macrotext", "/cast " .. GetSpellInfo(self:GetSpellId()));
end;

OrlanStrike.SealButton = OrlanStrike.Button:CloneTo({});

function OrlanStrike.SealButton:UpdateDisplay(window, gameState)
	self.OrlanStrike.Button.UpdateDisplay(self, window, gameState);

	if self:GetReason(gameState) > 0 then
		self.OrlanStrike:SetBorderColor(window, 0.2, 0.2, 1, 1);
	else
		window:SetAlpha(0.1);
	end;
end;

function OrlanStrike.SealButton:UpdateGameState(gameState)
	self.OrlanStrike.Button.UpdateGameState(self, gameState);
	gameState.HasSealOfTruth = false;
	gameState.HasSealOfRighteousness = false;
end;

OrlanStrike.HolyPowerButton = OrlanStrike.Button:CloneTo({});

function OrlanStrike.HolyPowerButton:IsLackingMana()
	return false;
end;

function OrlanStrike.HolyPowerButton:IsUsable(gameState)
	return self.OrlanStrike.Button.IsUsable(self, gameState) and 
		((gameState.HolyPower > 0) or gameState:HasDivinePurpose());
end;

function OrlanStrike.HolyPowerButton:UpdateGameState(gameState)
	self.OrlanStrike.Button.UpdateGameState(self, gameState);

	if gameState:HasDivinePurpose() then
		gameState.DivinePurposeExpirationTime = nil;
	elseif gameState.HolyPower < 3 then
		gameState.HolyPower = 0;
	else
		gameState.HolyPower = gameState.HolyPower - 3;
	end;
end;

function OrlanStrike.HolyPowerButton:GetReason(gameState)
	if self.OrlanStrike.Button.GetReason(self, gameState) == 0 then
		return 0;
	elseif gameState:HasDivinePurpose() or
		self.OrlanStrike:IsSeraphimEnding(gameState) or
		self.OrlanStrike:IsAvengingWrathEnding(gameState) or
		((gameState.HolyPower == UnitPowerMax("player", SPELL_POWER_HOLY_POWER)) and
			not self.OrlanStrike:IsSeraphimCooldownEnding(gameState)) then
		return 2;
	end;
	return 1;
end;

OrlanStrike.ThreeHolyPowerButton = OrlanStrike.HolyPowerButton:CloneTo({});

function OrlanStrike.ThreeHolyPowerButton:IsUsable(gameState)
	return ((gameState.HolyPower >= 3) or gameState:HasDivinePurpose()) and 
		self.OrlanStrike.Button.IsUsable(self, gameState);
end;

OrlanStrike.TemplarsVerdictButton = OrlanStrike.ThreeHolyPowerButton:CloneTo(
{
	SpellId = 85256,
	DoesRequireTarget = true
});

function OrlanStrike.TemplarsVerdictButton:IsFinalVerdictKnown()
	return select(4, GetTalentInfo(7, 3, GetActiveSpecGroup()));
end;

function OrlanStrike.TemplarsVerdictButton:UpdateGameState(gameState)
	self.OrlanStrike.ThreeHolyPowerButton.UpdateGameState(self, gameState);
	if self:IsFinalVerdictKnown() then
		gameState.FinalVerdictExpirationTime = gameState.Time + 30;
	end;
end;

function OrlanStrike.TemplarsVerdictButton:GetReason(gameState)
	local baseReason = self.OrlanStrike.ThreeHolyPowerButton.GetReason(self, gameState);
	if (baseReason == 2) and self:IsFinalVerdictKnown() and not gameState:HasFinalVerdict() then
		return 3;
	end;
	return baseReason;
end;

OrlanStrike.DivineStormButton = OrlanStrike.ThreeHolyPowerButton:CloneTo(
{
	SpellId = 53385
});

function OrlanStrike.DivineStormButton:UpdateGameState(gameState)
	self.OrlanStrike.Button.UpdateGameState(self, gameState);

	if gameState:HasDivinePurpose() or gameState:HasDivineCrusader() then
	elseif gameState.HolyPower < 3 then
		gameState.HolyPower = 0;
	else
		gameState.HolyPower = gameState.HolyPower - 3;
	end;

	gameState.DivinePurposeExpirationTime = nil;
	gameState.DivineCrusaderExpirationTime = nil;
	gameState.FinalVerdictExpirationTime = nil;
end;

function OrlanStrike.DivineStormButton:GetReason(gameState)
	local baseReason = self.OrlanStrike.ThreeHolyPowerButton.GetReason(self, gameState);
	if (baseReason == 1) and gameState:HasDivineCrusader() then
		baseReason = 2;
	end;
	if (baseReason == 2) and gameState:HasFinalVerdict() then
		return 3;
	end;
	return baseReason;
end;

function OrlanStrike.DivineStormButton:IsUsable(gameState)
	return ((gameState.HolyPower >= 3) or gameState:HasDivinePurpose() or gameState:HasDivineCrusader()) and 
		self.OrlanStrike.Button.IsUsable(self, gameState);
end;

OrlanStrike.SeraphimButton = OrlanStrike.HolyPowerButton:CloneTo(
{
	SpellId = 152262
});

function OrlanStrike.SeraphimButton:IsUsable(gameState)
	return (gameState.HolyPower >= 5) and 
		self.OrlanStrike.Button.IsUsable(self, gameState);
end;

function OrlanStrike.SeraphimButton:GetReason(gameState)
	if self:IsUsable(gameState) and not self.OrlanStrike:IsAvengingWrathEnding(gameState) then
		return 1;
	end;
	return 0;
end;

function OrlanStrike.SeraphimButton:UpdateGameState(gameState)
	self.OrlanStrike.Button.UpdateGameState(self, gameState);

	gameState.HolyPower = gameState.HolyPower - 5;
	gameState.SeraphimExpirationTime = gameState.Time + 30;
end;

OrlanStrike.HealthButton = OrlanStrike.Button:CloneTo({});

function OrlanStrike.HealthButton:GetReason(gameState)
	if (gameState.HealthPercent <= 0.2) and 
		(self.OrlanStrike.Button.GetReason(self, gameState) > 0) then
		return 1;
	end;
	return 0;
end;

OrlanStrike.SelfWeaponsOfTheLightButton = OrlanStrike.HealthButton:CloneTo(
{
	SpellId = 175699,
	Target = "player"
});

function OrlanStrike.SelfWeaponsOfTheLightButton:SetupButton()
	self.Spell:SetAttribute("type", "macro");
	self.Spell:SetAttribute("macrotext", "/cast [target=player] " .. GetSpellInfo(self:GetSpellId()));
end;

OrlanStrike.FlashOfLightButton = OrlanStrike.HealthButton:CloneTo(
{
	SpellId = 19750,
	Target = "player"
});

function OrlanStrike.FlashOfLightButton:UpdateGameState(gameState)
	self.OrlanStrike.HealthButton.UpdateGameState(self, gameState);
	gameState.HealthPercent = gameState.HealthPercent + 0.5;
end;

OrlanStrike.LayOnHandsButton = OrlanStrike.HealthButton:CloneTo(
{
	SpellId = 633,
	Target = "player"
});

function OrlanStrike.LayOnHandsButton:UpdateGameState(gameState)
	self.OrlanStrike.HealthButton.UpdateGameState(self, gameState);
	gameState.HealthPercent = 1;
end;

OrlanStrike.SealOfTruthButton = OrlanStrike.SealButton:CloneTo(
{
	SpellId = 105361
});

function OrlanStrike.SealOfTruthButton:GetReason(gameState)
	if (self.OrlanStrike.SealButton.GetReason(self, gameState) == 0) or gameState.HasSealOfTruth then
		return 0;
	elseif self.OrlanStrike:AreEmpoweredSealsKnown() then
		local judgmentCooldownExpiration = self.OrlanStrike:GetCooldownExpiration(GetSpellCooldown(GetSpellInfo(20271)));
		if not gameState.HasSealOfRighteousness then
			return 3;
		elseif gameState:HasLiadrinsRighteousness() and 
			(gameState.LiadrinsRighteousnessExpirationTime - gameState.Time >= 15) and
			((not gameState:HasMaraadsTruth()) or (gameState.MaraadsTruthExpirationTime - gameState.Time < 2)) and
			(judgmentCooldownExpiration - gameState.Time < 2) then
			return 3;
		elseif gameState:HasLiadrinsRighteousness() and
			(gameState.LiadrinsRighteousnessExpirationTime - gameState.Time >= 
				8 + math.max(judgmentCooldownExpiration - gameState.Time - 1.5, 0)) then
			return 2;
		end;
	end;
	return 1;
end;

function OrlanStrike.SealOfTruthButton:UpdateGameState(gameState)
	self.OrlanStrike.SealButton.UpdateGameState(self, gameState);
	gameState.HasSealOfTruth = true;
end;

OrlanStrike.SealOfRighteousnessButton = OrlanStrike.SealButton:CloneTo(
{
	SpellId = 20154
});

function OrlanStrike.SealOfRighteousnessButton:GetReason(gameState)
	if (self.OrlanStrike.SealButton.GetReason(self, gameState) == 0) or gameState.HasSealOfRighteousness then
		return 0;
	elseif self.OrlanStrike:AreEmpoweredSealsKnown() then
		local judgmentCooldownExpiration = self.OrlanStrike:GetCooldownExpiration(GetSpellCooldown(GetSpellInfo(20271)));
		if not gameState.HasSealOfTruth then
			return 3;
		elseif gameState:HasMaraadsTruth() and 
			(gameState.MaraadsTruthExpirationTime - gameState.Time >= 12) and
			((not gameState:HasLiadrinsRighteousness()) or 
				(gameState.LiadrinsRighteousnessExpirationTime - gameState.Time < 2)) and
			(judgmentCooldownExpiration - gameState.Time < 2) then
			return 3;
		elseif gameState:HasMaraadsTruth() and
			(gameState.MaraadsTruthExpirationTime - gameState.Time >= 
				8 + math.max(judgmentCooldownExpiration - gameState.Time - 1.5, 0)) then
			return 2;
		end;
	end;
	return 1;
end;

function OrlanStrike.SealOfRighteousnessButton:UpdateGameState(gameState)
	self.OrlanStrike.SealButton.UpdateGameState(self, gameState);
	gameState.HasSealOfRighteousness = true;
end;

OrlanStrike.CleanseButton = OrlanStrike.Button:CloneTo(
{
	SpellId = 4987, -- Cleanse
	Target = "player"
});

function OrlanStrike.CleanseButton:IsUsable(gameState)
	return self.OrlanStrike.Button.IsUsable(self, gameState) and self.OrlanStrike.HasDispellableDebuff;
end;

function OrlanStrike.CleanseButton:UpdateDisplay(window, gameState)
	self.OrlanStrike.Button.UpdateDisplay(self, window, gameState);

	if self:GetReason(gameState) > 0 then
		self.OrlanStrike:SetBorderColor(window, 1, 0, 1, 1);
		window:SetAlpha(1);
	end;
end;

OrlanStrike.WordOfGloryButton = OrlanStrike.HolyPowerButton:CloneTo(
{
	SpellId = 85673, -- Word of Glory
	Target = "player"
});

function OrlanStrike.WordOfGloryButton:GetReason(gameState)
	if self.OrlanStrike.HolyPowerButton.GetReason(self, gameState) == 0 then
		return 0;
	elseif gameState.HealthPercent <= 0.2 then
		return 2;
	elseif gameState.HealthPercent <= 0.4 then
		return 1;
	end;
	return 0;
end;

function OrlanStrike.WordOfGloryButton:UpdateGameState(gameState)
	self.OrlanStrike.HolyPowerButton.UpdateGameState(self, gameState);
	gameState.HealthPercent = 1;
end;

OrlanStrike.HarshWordButton = OrlanStrike.HolyPowerButton:CloneTo(
{
	SpellId = 85673, -- Word of Glory
	DoesRequireTarget = true
});

function OrlanStrike.HarshWordButton:SetupButton()
	self.Spell:SetAttribute("type", "macro");
	self.Spell:SetAttribute("macrotext", "/cast " .. GetSpellInfo(self:GetSpellId()));
end;

function OrlanStrike.HarshWordButton:IsUsable(gameState)
	return self.OrlanStrike.HolyPowerButton.IsUsable(self, gameState) and
		UnitCanAttack("player", "target") and
		self.OrlanStrike:HasGlyph(54938); -- Glyph of Harsh Words
end;

OrlanStrike.RebukeButton = OrlanStrike.Button:CloneTo(
{
	SpellId = 96231 -- Rebuke
});

function OrlanStrike.RebukeButton:GetReason(gameState)
	local spell, _, _, _, _, _, _, _, nonInterruptible = UnitCastingInfo("target");
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

OrlanStrike.VariableButton = OrlanStrike.Button:CloneTo({});

function OrlanStrike.VariableButton:UpdateSpells()
	local activeChoice;
	table.foreach(
		self.Choices,
		function (index, choice)
			if IsSpellKnown(choice:GetSpellId()) then
				activeChoice = choice;
			end;
		end);

	self.ActiveChoice = activeChoice;

	self:SetupButton();
end;

function OrlanStrike.VariableButton:IsUsable(gameState)
	if self.ActiveChoice then
		return self.ActiveChoice:IsUsable(gameState);
	end;
	return false;
end;

function OrlanStrike.VariableButton:GetReason(gameState)
	if self.ActiveChoice then
		return self.ActiveChoice:GetReason(gameState);
	end;
	return 0;
end;

function OrlanStrike.VariableButton:UpdateDisplay(window, gameState)
	if self.ActiveChoice then
		self.ActiveChoice:UpdateDisplay(window, gameState);
	else
		window:SetAlpha(0);
	end;
end;

function OrlanStrike.VariableButton:GetSpellId()
	if self.ActiveChoice then
		return self.ActiveChoice:GetSpellId();
	end;
	return nil;
end;

function OrlanStrike.VariableButton:IsLearned()
	if self.ActiveChoice then
		return self.ActiveChoice:IsLearned();
	end;
	return false;
end;

function OrlanStrike.VariableButton:IsLackingMana()
	if self.ActiveChoice then
		return self.ActiveChoice:IsLackingMana();
	end;
	return false;
end;

function OrlanStrike.VariableButton:IsAvailable()
	if self.ActiveChoice then
		return self.ActiveChoice:IsAvailable();
	end;
	return false;
end;

function OrlanStrike.VariableButton:UpdateGameState(gameState)
	if self.ActiveChoice then
		self.ActiveChoice:UpdateGameState(gameState);
	end;
end;

function OrlanStrike.VariableButton:GetCooldownExpiration()
	if self.ActiveChoice then
		return self.ActiveChoice:GetCooldownExpiration();
	end;
	return GetTime();
end;

function OrlanStrike.VariableButton:GetSharedCooldownSpellId()
	if self.ActiveChoice then
		return self.ActiveChoice:GetSharedCooldownSpellId();
	end;
	return nil;
end;

OrlanStrike:Initialize("OrlanStrikeConfig");
