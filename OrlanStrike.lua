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
		elseif (event == "ACTIVE_TALENT_GROUP_CHANGED") then
			orlanStrike:HandleTalentChange();
		elseif (event == "UNIT_SPELLCAST_START") and
				(arg1 == "player") and
				(arg5 == 35395) then -- Crusader Strike
			orlanStrike:HandleCrusaderStrike();
		end;
	end;

	self.EventFrame:RegisterEvent("ADDON_LOADED");
	self.EventFrame:SetScript("OnEvent", self.EventFrame.HandleEvent);

	self.CastWindowStrata = "LOW";
	self.CastWindowName = "OrlanStrike_CastWindow";

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
		self:CreateButton(
			castWindow, 
			self.InquisitionButton:CloneTo(
			{
				Row = 0,
				Column = 0
			})),
		self:CreateButton(
			castWindow, 
			self.HolyPowerScaledButton:CloneTo(
			{
				SpellId = 85256, -- Templar's Verdict
				Row = 0,
				Column = 1
			})),
		self:CreateButton(
			castWindow, 
			self.HolyPowerScaledButton:CloneTo(
			{
				SpellId = 53385, -- Divine Storm
				Row = 0,
				Column = 2
			})),
		self:CreateButton(
			castWindow, 
			self.Button:CloneTo(
			{
				SpellId = 35395, -- Crusader Strike
				Row = 0,
				Column = 3
			})),
		self:CreateButton(
			castWindow, 
			self.Button:CloneTo(
			{
				SpellId = 24275, -- Hammer of Wrath
				Row = 0,
				Column = 4
			})),
		self:CreateButton(
			castWindow, 
			self.ExorcismButton:CloneTo(
			{
				Row = 1,
				Column = 0
			})),
		self:CreateButton(
			castWindow, 
			self.Button:CloneTo(
			{
				SpellId = 20271, -- Judgement
				Row = 1,
				Column = 1
			})), -- Judgement
		self:CreateButton(
			castWindow, 
			self.Button:CloneTo(
			{
				SpellId = 2812, -- Holy Wrath
				Row = 1,
				Column = 2
			})),
		self:CreateButton(
			castWindow, 
			self.ConsecrationButton:CloneTo(
			{
				Row = 1,
				Column = 3
			})),
		self:CreateButton(
			castWindow, 
			self.ZealotryButton:CloneTo(
			{
				Row = 1,
				Column = 4
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
			self.GuardianOfAncientKingsButton:CloneTo(
			{
				Row = 2,
				Column = 1
			})),
		self:CreateButton(
			castWindow, 
			self.Button:CloneTo(
			{
				SpellId = 54428, -- Divine Plea
				Row = 2,
				Column = 2
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
			self.CleanseButton:CloneTo(
			{
				Row = 3,
				Column = 0
			})),
		self:CreateButton(
			castWindow, 
			self.HolyPowerScaledButton:CloneTo(
			{
				SpellId = 85673, -- Word of Glory
				Row = 3,
				Column = 1,
				Target = "player"
			})),
		self:CreateButton(
			castWindow, 
			self.Button:CloneTo(
			{
				SpellId = 19750, -- Flash of Light
				Row = 3,
				Column = 2,
				Target = "player"
			})),
		self:CreateButton(
			castWindow, 
			self.LayOnHandsButton:CloneTo(
			{
				Row = 3,
				Column = 3
			})),
		self:CreateButton(
			castWindow, 
			self.Button:CloneTo(
			{
				SpellId = 642, -- Divine Shield
				Row = 3,
				Column = 4
			}))
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
	local _, _, icon = GetSpellInfo(button.SpellId);
	button.Background:SetTexture(icon);

	button.Cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate");
	button.Cooldown:SetAllPoints();

	button.Spell = CreateFrame("Button", nil, button, "SecureActionButtonTemplate");
	button.Spell:SetAllPoints();
	button.Spell:RegisterForClicks("LeftButtonDown");
	button.Spell:SetAttribute("type", "spell");
	button.Spell:SetAttribute("spell", button.SpellId);
	if button.Target then
		button.Spell:SetAttribute("unit", button.Target);
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

	self.EventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED");
	self.EventFrame:RegisterEvent("UNIT_SPELLCAST_START");

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
end;

function OrlanStrike:HandleTalentChange()
	self.IsTalentTreeUpdated = false;
end;

function OrlanStrike:UpdateTalentTree()
	local tree = GetPrimaryTalentTree();
	if (tree == 3) then
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
	local hasInquisition, _, _, _, _, _, expires = UnitBuff("player", inquisitionSpellName);
	self.HasInquisition = hasInquisition;
	if self.HasInquisition then
		self.InquisitionDurationLeft = expires - self.Now;
	else
		self.InquisitionDurationLeft = 0;
	end;
end;

function OrlanStrike:DetectAvengingWrath()
	local avengingWrathSpellName = GetSpellInfo(31884); -- Avenging Wrath
	self.HasAvengingWrath = UnitBuff("player", avengingWrathSpellName);
end;

function OrlanStrike:DetectSealOfTruth()
	local sealOfTruthSpellName = GetSpellInfo(31801); -- Seal of Truth
	self.HasSealOfTruth = UnitBuff("player", sealOfTruthSpellName);
end;

function OrlanStrike:DetectSealOfRighteousness()
	local sealOfRighteousnessSpellName = GetSpellInfo(20154); -- Seal of Righteousness
	self.HasSealOfRighteousness = UnitBuff("player", sealOfRighteousnessSpellName);
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
	self:DetectZealotry();
	self:DetectArtOfWar();
	self:DetectHandOfLight();
	self:DetectInquisition();
	self:DetectAvengingWrath();
	self:DetectForbearance();
	self:DetectSealOfTruth();
	self:DetectSealOfRighteousness();
	self:DetectDispellableDebuffs();
end;

function OrlanStrike:DetectHolyPower()
	self.HolyPowerAmount = UnitPower("player", SPELL_POWER_HOLY_POWER);
	if self.HolyPowerOverride and 
			(self.HolyPowerOverrideTimeout > self.Now) and
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

function OrlanStrike:UpdateStatus()
	self:DetectNow();
	self:DetectAuras();
	self:DetectHolyPower();
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
		button:UpdateState();
		button:UpdateDisplay();
	end;

	local thisSingleTargetSpellIndex, nextSingleTargetSpellIndex, thisMultiTargetSpellIndex, nextMultiTargetSpellIndex;
	if (not self.Threat) or self.IsTanking or ((self.RawThreatPercent < 95) and (self.Threat * (1 - self.RawThreatPercent) / 100 < 40000 * 100)) then
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

	for spellIndex = 1, self.SpellCount do
		local button = self.CastWindow.Buttons[spellIndex];

		self:UpdateButtonCooldown(button);
	end;

	local healingSpellIndex = 1;
	while self.HealingSpellPriorityIndexes[healingSpellIndex] do
		local spellIndex = self.HealingSpellPriorityIndexes[healingSpellIndex];
		local button = self.CastWindow.Buttons[spellIndex];

		if button.IsAvailable and 
				button.IsManaEnough and
				(button.CooldownExpiration < self.Now + 1.5) then
			if ((self.HealthPercent <= 0.4) and (button.SpellId == 85673) and button.IsAtMaxPower) or -- Word of Glory
					(self.HealthPercent <= 0.2) then
				self:SetBorderColor(button, 1, 0.5, 0.5, 1);
				button:SetAlpha(1);
				break;
			end;
		end;

		healingSpellIndex = healingSpellIndex + 1;
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
		local button = self.CastWindow.Buttons[spellIndex];
		if button.IsAvailable and button.IsAtMaxPower then
			if not button.IsManaEnough then
				isManaLow = true;
			end;

			if (not minCooldownExpiration) or (minCooldownExpiration - self.MaxAbilityWaitTime > button.CooldownExpiration) then
				minCooldownExpiration = button.CooldownExpiration;
				firstSpellIndex = spellIndex;
				firstSpellId = self.CastWindow.Buttons[firstSpellIndex].SpellId;
			end;
		end;

		index = index + 1;
	end;

	local nextSpellCooldownExpirations = {};
	if firstSpellIndex then
		for spellIndex = 1, self.SpellCount do
			local button = self.CastWindow.Buttons[spellIndex];
			if button.CooldownExpiration < minCooldownExpiration + 1.5 then
				nextSpellCooldownExpirations[spellIndex] = minCooldownExpiration + 1.5;
			else
				nextSpellCooldownExpirations[spellIndex] = button.CooldownExpiration;
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
			local button = self.CastWindow.Buttons[spellIndex];
			if button.IsAvailable and 
					(button.IsAtMaxPower or 
						(button.IsAlmostAtMaxPower and (firstSpellId == 35395))) then -- Crusader Strike
				if (not nextMinCooldownExpiration) or (nextMinCooldownExpiration > nextSpellCooldownExpirations[spellIndex]) then
					nextMinCooldownExpiration = nextSpellCooldownExpirations[spellIndex];
					nextSpellIndex = spellIndex;
					nextSpellId = self.CastWindow.Buttons[nextSpellIndex].SpellId;
				end;
			end;

			index = index + 1;
		end;

		local divinePleaButton = self.CastWindow.Buttons[self.DivinePleaSpellIndex];
		if (UnitPower("player", SPELL_POWER_MANA) / UnitPowerMax("player", SPELL_POWER_MANA) < 0.9) and
				divinePleaButton.IsAvailable and
				(divinePleaButton.CooldownExpiration <= minCooldownExpiration) and
				(isManaLow or (minCooldownExpiration >= self.Now + 1.5 + self.MaxAbilityWaitTime)) then
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

function OrlanStrike.Button:UpdateState()
	self.IsLearned = FindSpellBookSlotBySpellID(self.SpellId);
	local isUsable, noMana = IsUsableSpell(self.SpellId);
	self.IsAvailable = self.IsLearned and (isUsable or noMana);
	self.IsManaEnough = self.IsLearned and isUsable;
	self.CooldownExpiration = self.OrlanStrike:GetCooldownExpiration(self.SpellId);
	self.IsAtMaxPower = true;
	self.IsAlmostAtMaxPower = false;
end;

function OrlanStrike.Button:UpdateDisplay()
	self:SetAlpha(0.5);
	self.OrlanStrike:SetBorderColor(self, 0, 0, 0, 0);

	if not self.IsAvailable or not self.IsManaEnough then
		self:SetAlpha(0.1);
	end;
end;

function OrlanStrike.Button:UpdateBurstButtonDisplay()
	if self.IsAvailable and self.IsManaEnough and self.IsAtMaxPower and (self.CooldownExpiration <= self.OrlanStrike.GcdExpiration) then
		self:SetAlpha(1);
		self.OrlanStrike:SetBorderColor(self, 1, 1, 1, 1);
	end;
end;

function OrlanStrike.Button:UpdateSealButtonDisplay()
	if self.IsAvailable and self.IsManaEnough and self.IsAtMaxPower then
		self.OrlanStrike:SetBorderColor(self, 0.2, 0.2, 1, 1);
	end;
end;


OrlanStrike.HolyPowerScaledButton = OrlanStrike.Button:CloneTo({});

function OrlanStrike.HolyPowerScaledButton:UpdateState()
	self.OrlanStrike.Button.UpdateState(self);

	self.IsAtMaxPower = (self.OrlanStrike.HolyPowerAmount == 3) or self.OrlanStrike.HasHandOfLight;
	self.IsAlmostAtMaxPower = not self.IsAtMaxPower and (self.OrlanStrike.HasZealotry or (self.OrlanStrike.HolyPowerAmount == 2));
	self.IsAvailable = self.IsLearned and ((self.OrlanStrike.HolyPowerAmount > 0) or self.OrlanStrike.HasZealotry);
end;


OrlanStrike.ExorcismButton = OrlanStrike.Button:CloneTo(
{
	SpellId = 879
});

function OrlanStrike.ExorcismButton:UpdateState()
	self.OrlanStrike.Button.UpdateState(self);

	self.IsAtMaxPower = self.OrlanStrike.HasArtOfWar;
end;


OrlanStrike.MaxHolyPowerButton = OrlanStrike.Button:CloneTo({});

function OrlanStrike.MaxHolyPowerButton:UpdateState()
	self.OrlanStrike.Button.UpdateState(self);

	self.IsAvailable = self.IsLearned;
	self.IsAtMaxPower = self.OrlanStrike.HasHandOfLight or (self.OrlanStrike.HolyPowerAmount == 3);
	self.IsAlmostAtMaxPower = self.IsLearned and 
		(not self.IsAtMaxPower) and
		(self.HasZealotry or (self.HolyPowerAmount == 2));
end;


OrlanStrike.InquisitionButton = OrlanStrike.MaxHolyPowerButton:CloneTo(
{
	SpellId = 84963
});

function OrlanStrike.InquisitionButton:UpdateState()
	self.OrlanStrike.MaxHolyPowerButton.UpdateState(self);

	self.IsAtMaxPower = self.IsAtMaxPower and (self.OrlanStrike.InquisitionDurationLeft < 8);
	self.IsAlmostAtMaxPower = self.IsAlmostAtMaxPower and (self.OrlanStrike.InquisitionDurationLeft < 8);
end;


OrlanStrike.ZealotryButton = OrlanStrike.MaxHolyPowerButton:CloneTo(
{
	SpellId = 85696
});

function OrlanStrike.ZealotryButton:UpdateState()
	self.OrlanStrike.MaxHolyPowerButton.UpdateState(self);

	self.IsAtMaxPower = self.IsAtMaxPower and not (self.OrlanStrike.HasZealotry or self.OrlanStrike.HasAvengingWrath);
	self.IsAlmostAtMaxPower = self.IsAlmostAtMaxPower and not (self.OrlanStrike.HasZealotry or self.OrlanStrike.HasAvengingWrath);
end;

function OrlanStrike.ZealotryButton:UpdateDisplay()
	self.OrlanStrike.MaxHolyPowerButton.UpdateDisplay(self);

	self:UpdateBurstButtonDisplay();
end;


OrlanStrike.AvengingWrathButton = OrlanStrike.Button:CloneTo(
{
	SpellId = 31884
});

function OrlanStrike.AvengingWrathButton:UpdateState()
	self.OrlanStrike.Button.UpdateState(self);

	self.IsAtMaxPower = self.IsAtMaxPower and not (self.OrlanStrike.HasZealotry or self.OrlanStrike.HasAvengingWrath);
end;

function OrlanStrike.AvengingWrathButton:UpdateDisplay()
	self.OrlanStrike.Button.UpdateDisplay(self);

	self:UpdateBurstButtonDisplay();
end;


OrlanStrike.ConsecrationButton = OrlanStrike.Button:CloneTo(
{
	SpellId = 26573
});

function OrlanStrike.ConsecrationButton:UpdateState()
	self.OrlanStrike.Button.UpdateState(self);

	self.IsAtMaxPower = self.OrlanStrike.ManaPercent > 0.666;
end;


OrlanStrike.LayOnHandsButton = OrlanStrike.Button:CloneTo(
{
	SpellId = 633,
	Target = "player"
});

function OrlanStrike.LayOnHandsButton:UpdateStatus()
	self.OrlanStrike.Button.UpdateState(self);

	self.IsAvailable = self.IsAvailable and not self.OrlanStrike.HasForbearance;
end;


OrlanStrike.SealOfTruthButton = OrlanStrike.Button:CloneTo(
{
	SpellId = 31801
});

function OrlanStrike.SealOfTruthButton:UpdateState()
	self.OrlanStrike.Button.UpdateState(self);

	self.IsAtMaxPower = not self.OrlanStrike.HasSealOfTruth;
end;

function OrlanStrike.SealOfTruthButton:UpdateDisplay()
	self.OrlanStrike.Button.UpdateDisplay(self);

	self:UpdateSealButtonDisplay();
end;


OrlanStrike.SealOfRighteousnessButton = OrlanStrike.Button:CloneTo(
{
	SpellId = 20154
});

function OrlanStrike.SealOfRighteousnessButton:UpdateState()
	self.OrlanStrike.Button.UpdateState(self);

	self.IsAtMaxPower = not self.OrlanStrike.HasSealOfRighteousness;
end;

function OrlanStrike.SealOfRighteousnessButton:UpdateDisplay()
	self.OrlanStrike.Button.UpdateDisplay(self);

	self:UpdateSealButtonDisplay();
end;


OrlanStrike.GuardianOfAncientKingsButton = OrlanStrike.Button:CloneTo(
{
	SpellId = 86150
});

function OrlanStrike.GuardianOfAncientKingsButton:UpdateDisplay()
	self.OrlanStrike.Button.UpdateDisplay(self);

	self:UpdateBurstButtonDisplay();
end;


OrlanStrike.CleanseButton = OrlanStrike.Button:CloneTo(
{
	SpellId = 4987, -- Cleanse
	Target = "player"
});


function OrlanStrike.CleanseButton:UpdateState()
	self.OrlanStrike.Button.UpdateState(self);

	self.IsAtMaxPower = self.OrlanStrike.HasDispellableDebuff;
end;

function OrlanStrike.CleanseButton:UpdateDisplay()
	self.OrlanStrike.Button.UpdateDisplay(self);

	if self.IsAvailable and self.IsManaEnough and self.IsAtMaxPower then
		self.OrlanStrike:SetBorderColor(self, 1, 0, 1, 1);
		self:SetAlpha(1);
	end;
end;


OrlanStrike:Initialize("OrlanStrikeConfig");
