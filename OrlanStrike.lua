OrlanStrike = {};

SLASH_ORLANSTRIKE1 = "/orlanstrike";
SLASH_ORLANSTRIKE2 = "/os";
function SlashCmdList.ORLANSTRIKE(message, editbox)
	if message == "show" then
		OrlanStrike:Show();
	elseif message == "hide" then
		OrlanStrike:Hide();
	end;
end;

function OrlanStrike:Initialize(configName)
	local orlanStrike = self;

	self.ConfigName = configName;
	self.EventFrame = CreateFrame("Frame");
	self.ButtonSize = 32;
	self.ButtonSpacing = 5;
	self.RowCount = 4;
	self.ColumnCount = 5;
	self.CastWindowHeight = self.ButtonSize * self.RowCount + self.ButtonSpacing * (self.RowCount + 1);
	self.CastWindowWidth = self.ButtonSize * self.ColumnCount + self.ButtonSpacing * (self.ColumnCount + 1);

	self.FrameRate = 10.0;

	function self.EventFrame:HandleEvent(event, arg1, arg2, arg3, arg4, arg5)
		if (event == "ADDON_LOADED") and (arg1 == "OrlanStrike") then
			orlanStrike:HandleLoaded();
		elseif (event == "UNIT_SPELLCAST_START") and
				(arg1 == "player") and
				(arg5 == 35395) then -- Crusader Strike
			orlanStrike:HandleCrusaderStrike();
		end;
	end;

	self.ElapsedAfterUpdate = 0;
	function self.EventFrame:HandleUpdate(elapsed)
		if orlanStrike.CastWindow:IsShown() then
			orlanStrike.ElapsedAfterUpdate = orlanStrike.ElapsedAfterUpdate + elapsed;
			if orlanStrike.ElapsedAfterUpdate > 1.0 / orlanStrike.FrameRate then
				orlanStrike:UpdateStatus();
				orlanStrike.ElapsedAfterUpdate = 0;
			end;
		end;
	end;

	self.EventFrame:RegisterEvent("ADDON_LOADED");
	self.EventFrame:SetScript("OnEvent", self.EventFrame.HandleEvent);
	self.EventFrame:SetScript("OnUpdate", self.EventFrame.HandleUpdate);

	self.CastWindowStrata = "LOW";
	self.CastWindowName = "OrlanStrike_CastWindow";

	self.AreSpellsAvailable = {};
	self.IsManaEnoughForSpells = {};
	self.AreSpellsAtMaxPower = {};
	self.AreSpellsAlmostAtMaxPower = {};
	self.SpellCooldownExpirations = {};

	self.SingleTargetPriorities =
	{
		84963, -- Inquisition
		85256, -- Templar's Verdict
		35395, -- Crusader Strike
		24275, -- Hammer of Wrath
		879, -- Exorcism
		20271, -- Judgement
		2812, -- Holy Wrath
		26573 -- Consecration
	};
	self.MultiTargetPriorities =
	{
		84963, -- Inquisition
		53385, -- Divine Storm
		35395, -- Crusader Strike
		24275, -- Hammer of Wrath
		879, -- Exorcism
		20271, -- Judgement
		2812, -- Holy Wrath
		26573 -- Consecration
	};
	self.ZealotrySingleTargetPriorities =
	{
		84963, -- Inquisition
		85256, -- Templar's Verdict
		35395 -- Crusader Strike
	};
	self.ZealotryMultiTargetPriorities =
	{
		84963, -- Inquisition
		53385, -- Divine Storm
		35395 -- Crusader Strike
	};
	self.MaxAbilityWaitTime = 0.1;
	self.HealingSpellPriorities =
	{
		85673, -- Word of Glory
		19750, -- Flash of Light
		633, -- Lay on Hands
		642 -- Divine Shield
	};
end;

function OrlanStrike:CreateCastWindow()
	local orlanStrike = self;
	local castWindow = CreateFrame("Frame", self.CastWindowName, UIParent);

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
		self:CreateButton(castWindow, 84963, 0, 0), -- Inquisition
		self:CreateButton(castWindow, 85256, 0, 1), -- Templar's Verdict
		self:CreateButton(castWindow, 53385, 0, 2), -- Divine Storm
		self:CreateButton(castWindow, 35395, 0, 3), -- Crusader Strike
		self:CreateButton(castWindow, 24275, 0, 4), -- Hammer of Wrath
		self:CreateButton(castWindow, 879, 1, 0), -- Exorcism
		self:CreateButton(castWindow, 20271, 1, 1), -- Judgement
		self:CreateButton(castWindow, 2812, 1, 2), -- Holy Wrath
		self:CreateButton(castWindow, 26573, 1, 3), -- Consecration
		self:CreateButton(castWindow, 85696, 1, 4), -- Zealotry
		self:CreateButton(castWindow, 31884, 2, 0), -- Avenging Wrath
		self:CreateButton(castWindow, 86150, 2, 1), -- Guardian of Ancient Kings
		self:CreateButton(castWindow, 54428, 2, 2), -- Divine Plea
		self:CreateButton(castWindow, 31801, 2, 3), -- Seal of Truth
		self:CreateButton(castWindow, 20154, 2, 4), -- Seal of Righteousness
		self:CreateButton(castWindow, 4987, 3, 0, true), -- Cleanse
		self:CreateButton(castWindow, 85673, 3, 1, true), -- Word of Glory
		self:CreateButton(castWindow, 19750, 3, 2, true), -- Flash of Light
		self:CreateButton(castWindow, 633, 3, 3, true), -- Lay on Hands
		self:CreateButton(castWindow, 642, 3, 4) -- Divine Shield
	};
	self.SpellCount = 20;

	castWindow.HolyPowerBar = castWindow:CreateTexture();
	castWindow.HolyPowerBar:SetPoint("BOTTOMLEFT", castWindow, "TOPLEFT", 0, 0);
	castWindow.HolyPowerBar:SetHeight(3);

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

function OrlanStrike:CreateButton(parent, spellId, rowIndex, columnIndex, isOnSelf)
	local button = CreateFrame("Frame", nil, parent);
	button:SetPoint(
		"TOPLEFT", 
		self.ButtonSpacing + (self.ButtonSize + self.ButtonSpacing) * columnIndex,
		-(self.ButtonSpacing + (self.ButtonSize + self.ButtonSpacing) * rowIndex));
	button:SetHeight(self.ButtonSize);
	button:SetWidth(self.ButtonSize);
	button.SpellId = spellId;

	button.Background = button:CreateTexture(nil, "BACKGROUND");
	button.Background:SetAllPoints();
	local _, _, icon = GetSpellInfo(spellId);
	button.Background:SetTexture(icon);

	button.Cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate");
	button.Cooldown:SetAllPoints();

	button.Spell = CreateFrame("Button", nil, button, "SecureActionButtonTemplate");
	button.Spell:SetAllPoints();
	button.Spell:RegisterForClicks("LeftButtonDown");
	button.Spell:SetAttribute("type", "spell");
	button.Spell:SetAttribute("spell", spellId);
	if isOnSelf then
		button.Spell:SetAttribute("unit", "player");
	end;

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

	self.CastWindow = self:CreateCastWindow();
	self.SingleTargetPriorityIndexes = self:CalculateSpellPriorityIndexes(self.SingleTargetPriorities);
	self.MultiTargetPriorityIndexes = self:CalculateSpellPriorityIndexes(self.MultiTargetPriorities);
	self.ZealotrySingleTargetPriorityIndexes = self:CalculateSpellPriorityIndexes(self.ZealotrySingleTargetPriorities);
	self.ZealotryMultiTargetPriorityIndexes = self:CalculateSpellPriorityIndexes(self.ZealotryMultiTargetPriorities);
	self.HealingSpellPriorityIndexes = self:CalculateSpellPriorityIndexes(self.HealingSpellPriorities);
	self.DivinePleaSpellIndex = self:CalculateSpellIndex(54428); -- Divine Plea

	self:Show();

	self.EventFrame:RegisterEvent("UNIT_SPELLCAST_START");
end;

function OrlanStrike:CalculateSpellPriorityIndexes(priorities)
	local indexes = {};
	local orlanStrike = self;
	table.foreach(
		priorities,
		function (index, spellId)
			indexes[index] = orlanStrike:CalculateSpellIndex(spellId);
		end);
	return indexes;
end;

function OrlanStrike:CalculateSpellIndex(spellId)
	local result;
	for index = 1, self.SpellCount do
		if self.CastWindow.Buttons[index].SpellId == spellId then
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

function OrlanStrike:HandleCrusaderStrike()
	local holyPowerAmount = UnitPower("player", SPELL_POWER_HOLY_POWER);
	if holyPowerAmount < 3 then
		self:DetectZealotry();

		if self.HasZealotry then
			self.HolyPowerOverride = 3;
		else
			self.HolyPowerOverride = holyPowerAmount + 1;
		end;
		self.HolyPowerOverrideTimeout = GetTime() + 1;
	end;
end;

function OrlanStrike:DetectZealotry()
	local zealotrySpellName = GetSpellInfo(85696); -- Zealotry
	self.HasZealotry = UnitBuff("player", zealotrySpellName);
end;

function OrlanStrike:DetectArtOfWar()
	local artOfWarSpellName = GetSpellInfo(59578); -- Art of War
	self.HasArtOfWar = UnitBuff("player", artOfWarSpellName);
end;

function OrlanStrike:DetectHandOfLight()
	local handOfLightSpellName = GetSpellInfo(90174); -- Hand of Light
	self.HasHandOfLight = UnitBuff("player", handOfLightSpellName);
end;

function OrlanStrike:DetectInquisition()
	local inquisitionSpellName = GetSpellInfo(84963); -- Inquisition
	self.HasInquisition = UnitBuff("player", inquisitionSpellName);
end;

function OrlanStrike:DetectAvengingWrath()
	local avengingWrathSpellName = GetSpellInfo(31884); -- Avenging Wrath
	self.HasAvengingWrath = UnitBuff("player", avengingWrathSpellName);
end;

function OrlanStrike:DetectForbearance()
	local forbearanceSpellName = GetSpellInfo(25771); -- Forbearance
	self.HasForbearance = UnitDebuff("player", forbearanceSpellName);
end;

function OrlanStrike:DetectAuras()
	self:DetectZealotry();
	self:DetectArtOfWar();
	self:DetectHandOfLight();
	self:DetectInquisition();
	self:DetectAvengingWrath();
	self:DetectForbearance();
end;

function OrlanStrike:DetectHolyPower()
	self.HolyPowerAmount = UnitPower("player", SPELL_POWER_HOLY_POWER);
	if self.HolyPowerOverride and 
			(self.HolyPowerOverrideTimeout > GetTime()) and
			(self.HolyPowerOverride > self.HolyPowerAmount) then
		self.HolyPowerAmount = self.HolyPowerOVerride;
	end;
end;

function OrlanStrike:DetectHealthPercent()
	self.HealthPercent = UnitHealth("player") / UnitHealthMax("player");
end;

function OrlanStrike:DetectManaPercent()
	self.ManaPercent = UnitPower("player", SPELL_POWER_MANA) / UnitPowerMax("player", SPELL_POWER_MANA);
end;

function OrlanStrike:DetectThreat()
	self.IsTanking, _, self.ThreatPercent, self.RawThreatPercent, self.Threat = UnitDetailedThreatSituation("player", "target");
end;

function OrlanStrike:DetectNow()
	self.Now = GetTime();
end;

function OrlanStrike:GetRawCooldownExpiration(spellId)
	local expiration;
	local start, duration = GetSpellCooldown(spellId);
	if start and duration and (duration ~= 0) and (start + duration > self.Now) then
		expiration = start + duration;
	else
		expiration = self.Now;
	end;
	return expiration;
end;

function OrlanStrike:GetCooldownExpiration(spellId)
	local expiration = self:GetRawCooldownExpiration(spellId);
	if expiration < self.GcdExpiration then
		expiration = self.GcdExpiration;
	end;
	return expiration;
end;

function OrlanStrike:DetectGcd()
	self.GcdExpiration = self:GetRawCooldownExpiration(20154); -- Seal of Righteousness
end;

function OrlanStrike:UpdateHolyPowerBar()
	self.CastWindow.HolyPowerBar:SetWidth(self.CastWindowWidth * self.HolyPowerAmount / 3);
	if self.HolyPowerAmount == 0 then
		self.CastWindow.HolyPowerBar:SetTexture(0, 0, 0, 0);
	elseif self.HolyPowerAmount == 1 then
		self.CastWindow.HolyPowerBar:SetTexture(1, 0, 0, 0.3);
	elseif self.HolyPowerAmount == 2 then
		self.CastWindow.HolyPowerBar:SetTexture(1, 1, 0, 0.3);
	else
		self.CastWindow.HolyPowerBar:SetTexture(0, 1, 0, 0.3);
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
		self.CastWindow.ThreatBar:SetWidth(self.CastWindowWidth * self.ThreatPercent);
		self.CastWindow.ThreatBar:SetTexture(1, 1, 0, 1);
	else
		self.CastWindow.ThreatBar:SetWidth(self.CastWindowWidth * self.ThreatPercent);
		self.CastWindow.ThreatBar:SetTexture(1, 0, 1, 0.5);
	end;
end;

function OrlanStrike:UpdateStatus()
	self:DetectAuras();
	self:DetectHolyPower();
	self:DetectHealthPercent();
	self:DetectManaPercent();
	self:DetectThreat();

	self:DetectNow();
	self:DetectGcd();

	self:UpdateHolyPowerBar();
	self:UpdateHealthBar();
	self:UpdateManaBar();
	self:UpdateThreatBar();

	for spellIndex = 1, self.SpellCount do
		local button = self.CastWindow.Buttons[spellIndex];

		button:SetAlpha(0.5);
		self:SetBorderColor(button, 0, 0, 0, 0);

		local isLearned = FindSpellBookSlotBySpellID(button.SpellId);
		local isUsable, noMana = IsUsableSpell(button.SpellId);
		self.AreSpellsAvailable[spellIndex] = isLearned and (isUsable or noMana);
		self.IsManaEnoughForSpells[spellIndex] = isLearned and isUsable;

		self.SpellCooldownExpirations[spellIndex] = self:GetCooldownExpiration(button.SpellId);

		if (button.SpellId == 85256) or  -- Templar's Verdict
				(button.SpellId == 53385) then -- Divine Storm
			self.AreSpellsAtMaxPower[spellIndex] = (self.HolyPowerAmount == 3) or self.HasHandOfLight;
			self.AreSpellsAlmostAtMaxPower[spellIndex] = 
				not self.AreSpellsAtMaxPower[spellIndex] and (self.HasZealotry or (self.HolyPowerAmount == 2));
			self.AreSpellsAvailable[spellIndex] = isLearned and ((self.HolyPowerAmount > 0) or self.HasZealotry);
		elseif button.SpellId == 879 then -- Exorcism
			self.AreSpellsAtMaxPower[spellIndex] = self.HasArtOfWar;
			self.AreSpellsAlmostAtMaxPower[spellIndex] = false;
		elseif button.SpellId == 85696 then -- Zealotry
			self.AreSpellsAtMaxPower[spellIndex] = isUsable;
			self.AreSpellsAlmostAtMaxPower[spellIndex] = isLearned and 
				(not isUsable) and 
				(not noMana) and 
				(self.HasZealotry or (self.HolyPowerAmount == 2));
			self.AreSpellsAvailable[spellIndex] = isLearned and (isUsable or self.AreSpellsAlmostAtMaxPower[spellIndex]);
		elseif button.SpellId == 84963 then -- Inquisition
			self.AreSpellsAtMaxPower[spellIndex] = isUsable and not self.HasInquisition;
			self.AreSpellsAlmostAtMaxPower[spellIndex] = 
				(not isUsable) and (not noMana) and (not self.HasInquisition) and (self.HasZealotry or (self.HolyPowerAmount == 2));
			self.AreSpellsAvailable[spellIndex] = isLearned and (isUsable or self.AreSpellsAlmostAtMaxPower[spellIndex]);
		elseif button.SpellId == 26573 then -- Consecration
			self.AreSpellsAtMaxPower[spellIndex] = UnitPower("player", SPELL_POWER_MANA) / UnitPowerMax("player", SPELL_POWER_MANA) > 0.666;
			self.AreSpellsAlmostAtMaxPower[spellIndex] = false;
		elseif button.SpellId == 85673 then -- Word of Glory
			self.AreSpellsAtMaxPower[spellIndex] = isLearned and ((self.HolyPowerAmount == 3) or self.HasHandOfLight);
			self.AreSpellsAlmostAtMaxPower[spellIndex] = false;
			self.AreSpellsAvailable[spellIndex] = isLearned and ((self.HolyPowerAmount > 0) or self.HasZealotry);
		elseif button.SpellId == 633 then -- Lay on Hands
			self.AreSpellsAvailable[spellIndex] = self.AreSpellsAvailable[spellIndex] and not self.HasForbearance;
			self.AreSpellsAtMaxPower[spellIndex] = true;
			self.AreSpellsAlmostAtMaxPower[spellIndex] = false;
		else
			self.AreSpellsAtMaxPower[spellIndex] = true;
			self.AreSpellsAlmostAtMaxPower[spellIndex] = false;
		end
	end;

	local thisSingleTargetSpellIndex, nextSingleTargetSpellIndex, thisMultiTargetSpellIndex, nextMultiTargetSpellIndex;
	if (not self.Threat) or self.IsTanking or ((self.RawThreatPercent < 99) and (self.Threat * (1 - self.RawThreatPercent) / 100 < 30000 * 100)) then
		if self.HasZealotry then
			thisSingleTargetSpellIndex, nextSingleTargetSpellIndex = self:GetSpellsToCast(self.ZealotrySingleTargetPriorityIndexes);
			thisMultiTargetSpellIndex, nextMultiTargetSpellIndex = self:GetSpellsToCast(self.ZealotryMultiTargetPriorityIndexes);
		else
			thisSingleTargetSpellIndex, nextSingleTargetSpellIndex = self:GetSpellsToCast(self.SingleTargetPriorityIndexes);
			thisMultiTargetSpellIndex, nextMultiTargetSpellIndex = self:GetSpellsToCast(self.MultiTargetPriorityIndexes);
		end;
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

	local sealOfTruthSpellName = GetSpellInfo(31801); -- Seal of Truth
	local hasSealOfTruth = UnitBuff("player", sealOfTruthSpellName);
	local sealOfRighteousnessSpellName = GetSpellInfo(20154); -- Seal of Righteousness
	local hasSealOfRighteousness = UnitBuff("player", sealOfRighteousnessSpellName);

	for spellIndex = 1, self.SpellCount do
		local button = self.CastWindow.Buttons[spellIndex];

		self:UpdateButtonCooldown(button);

		if not self.AreSpellsAvailable[spellIndex] or not self.IsManaEnoughForSpells[spellIndex] then
			button:SetAlpha(0.1);
		elseif (button.SpellId == 86150) and -- Guardian of the Ancient Kings
				self.AreSpellsAtMaxPower[spellIndex] and
				self.SpellCooldownExpirations[spellIndex] <= self.GcdExpiration then
			button:SetAlpha(1);
			self:SetBorderColor(button, 1, 1, 1, 1);
		elseif (button.SpellId == 85696) and -- Zealotry
				not self.HasAvengingWrath and
				self.AreSpellsAtMaxPower[spellIndex] and
				self.SpellCooldownExpirations[spellIndex] <= self.GcdExpiration then
			button:SetAlpha(1);
			self:SetBorderColor(button, 1, 1, 1, 1);
		elseif (button.SpellId == 31884) and -- Avenging Wrath
				not self.HasZealotry and
				self.AreSpellsAtMaxPower[spellIndex] and
				self.SpellCooldownExpirations[spellIndex] <= self.GcdExpiration then
			button:SetAlpha(1);
			self:SetBorderColor(button, 1, 1, 1, 1);
		elseif (button.SpellId == 31801) and not hasSealOfTruth then -- Seal of Truth
			self:SetBorderColor(button, 0.2, 0.2, 1, 1);
		elseif (button.SpellId == 20154) and not hasSealOfRighteousness then -- Seal of Righteousness
			self:SetBorderColor(button, 0.2, 0.2, 1, 1);
		elseif button.SpellId == 4987 then -- Cleanse
			self:UpdateDispellButton(button);
		end;
	end;

	local healingSpellIndex = 1;
	while self.HealingSpellPriorityIndexes[healingSpellIndex] do
		local spellIndex = self.HealingSpellPriorityIndexes[healingSpellIndex];
		local button = self.CastWindow.Buttons[spellIndex];

		if self.AreSpellsAvailable[spellIndex] and 
				self.IsManaEnoughForSpells[spellIndex] and
				self.SpellCooldownExpirations[spellIndex] < self.Now + 1.5 then
			if ((self.HealthPercent <= 0.4) and (button.SpellId == 85673) and self.AreSpellsAtMaxPower[spellIndex]) or -- Word of Glory
					(self.HealthPercent <= 0.2) then
				self:SetBorderColor(button, 1, 0.5, 0.5, 1);
				button:SetAlpha(1);
				break;
			end;
		end;

		healingSpellIndex = healingSpellIndex + 1;
	end;
end;

function OrlanStrike:UpdateDispellButton(button)
	local debuffIndex = 1;
	while true do
		local debuffName, _, _, _, dispelType = UnitDebuff("player", debuffIndex);
		if not debuffName then
			break;
		end;
		if (dispelType == "Disease") or (dispelType == "Poison") then
			self:SetBorderColor(button, 1, 0, 1, 1);
			button:SetAlpha(1);
			break;
		end;

		debuffIndex = debuffIndex + 1;
	end;
end;

function OrlanStrike:GetSpellsToCast(priorityIndexes)
	local minCooldownExpiration;
	local firstSpellIndex;
	local firstSpellId;
	local index = 1;
	local isManaLow;
	while priorityIndexes[index] do
		local spellIndex = priorityIndexes[index];
		if self.AreSpellsAvailable[spellIndex] and self.AreSpellsAtMaxPower[spellIndex] then
			if not self.IsManaEnoughForSpells[spellIndex] then
				isManaLow = true;
			end;

			if (not minCooldownExpiration) or (minCooldownExpiration - self.MaxAbilityWaitTime > self.SpellCooldownExpirations[spellIndex]) then
				minCooldownExpiration = self.SpellCooldownExpirations[spellIndex];
				firstSpellIndex = spellIndex;
				firstSpellId = self.CastWindow.Buttons[firstSpellIndex].SpellId;
			end;
		end;

		index = index + 1;
	end;

	local nextSpellCooldownExpirations = {};
	if firstSpellIndex then
		for spellIndex = 1, self.SpellCount do
			if self.SpellCooldownExpirations[spellIndex] < minCooldownExpiration + 1.5 then
				nextSpellCooldownExpirations[spellIndex] = minCooldownExpiration + 1.5;
			else
				nextSpellCooldownExpirations[spellIndex] = self.SpellCooldownExpirations[spellIndex];
			end;
		end;
		nextSpellCooldownExpirations[firstSpellIndex] = minCooldownExpiration + 1000;
	end;

	local nextMinCooldownExpiration;
	local nextSpellIndex;
	local nextSpellId;
	if firstSpellIndex then
		index = 1;
		while priorityIndexes[index] do
			local spellIndex = priorityIndexes[index];
			if self.AreSpellsAvailable[spellIndex] and 
					(self.AreSpellsAtMaxPower[spellIndex] or 
						(self.AreSpellsAlmostAtMaxPower[spellIndex] and (firstSpellId == 35395))) then -- Crusader Strike
				if (not nextMinCooldownExpiration) or (nextMinCooldownExpiration > nextSpellCooldownExpirations[spellIndex]) then
					nextMinCooldownExpiration = nextSpellCooldownExpirations[spellIndex];
					nextSpellIndex = spellIndex;
					nextSpellId = self.CastWindow.Buttons[nextSpellIndex].SpellId;
				end;
			end;

			index = index + 1;
		end;

		if (UnitPower("player", SPELL_POWER_MANA) / UnitPowerMax("player", SPELL_POWER_MANA) < 0.9) and
				self.AreSpellsAvailable[self.DivinePleaSpellIndex] and
				(self.SpellCooldownExpirations[self.DivinePleaSpellIndex] <= minCooldownExpiration) and
				(isManaLow or (minCooldownExpiration >= GetTime() + 1.5 + self.MaxAbilityWaitTime)) then
			nextSpellIndex = firstSpellIndex;
			firstSpellIndex = self.DivinePleaSpellIndex;
		end;
	end;

	return firstSpellIndex, nextSpellIndex;
end;

function OrlanStrike:UpdateButtonCooldown(button)
	local start, duration, enabled = GetSpellCooldown(button.SpellId);
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
			button.Cooldown:SetCooldown(0, 10);
		end;
	end;
end;

function OrlanStrike:RequestNonCombat()
	if InCombatLockdown() then
		print("OrlanStrike: Cannot be done in combat.");
		return false;
	else
		return true;
	end;
end;

OrlanStrike:Initialize("OrlanStrikeConfig");
