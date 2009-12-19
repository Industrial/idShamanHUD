if select(2, UnitClass('player')) ~= 'SHAMAN' then return end

local _G = _G
local TL, TC, TR = 'TOPLEFT', 'TOP', 'TOPRIGHT'
local ML, MC, MR = 'LEFT', 'CENTER', 'RIGHT'
local BL, BC, BR = 'BOTTOMLEFT', 'BOTTOM', 'BOTTOMRIGHT'

local icon_size = 50

local addon = CreateFrame('Frame')

addon.onupdate_timer = 0

function addon:doLightningbolt ()
	local maelstrom_is_up = select(4, UnitBuff('player', 'Maelstrom Weapon')) == 4

	if maelstrom_is_up then
		return 'Lightning Bolt'
	else
		return false
	end
end

function addon:doStormstrike ()
	local stormstrike_is_up = GetSpellCooldown('Stormstrike') == 0

	if stormstrike_is_up then
		return 'Stormstrike'
	else
		return false
	end
end

function addon:doEarthshock ()
	local earthshock_is_up = GetSpellCooldown('Earth Shock') == 0

	if earthshock_is_up then
		return 'Earth Shock'
	else
		return false
	end
end

function addon:doLavaLash ()
	local lavalash_is_up = GetSpellCooldown('Lava Lash') == 0

	if lavalash_is_up then
		return 'Lava Lash'
	else
		return false
	end
end

function addon:getNextSpell()
	local getCD = _G.GetSpellCooldown
	local rotation = self.rotation

	local lowest_time
	local lowest_spell

	local ss_start, ss_time, ss_end
	local es_start, es_time, es_end
	local ll_start, ll_time, ll_end

	if select(4, UnitBuff('player', 'Maelstrom Weapon')) == 5 then
		return 'Lightning Bolt'
	else
		ss_start, ss_time = getCD('Stormstrike')
		ss_end = ss_start + ss_time

		es_start, es_time = getCD('Earth Shock')
		es_end = es_start + es_time

		ll_start, ll_time = getCD('Lava Lash')
		ll_end = ll_start + ll_time

		lowest_time = ss_end
		lowest_spell = 'Stormstrike'

		if es_end < lowest_time then
			lowest_time = es_end
			lowest_spell = 'Earth Shock'
		end

		if ll_end < lowest_time then
			lowest_time = ll_end
			lowest_spell = 'Lava Lash'
		end

		return lowest_spell
	end
end

function addon:PLAYER_LOGIN ()
	local spellframe = CreateFrame('Frame', 'idShamanHUDSpellFrame', UIParent)
	local gcdframe = CreateFrame('StatusBar', 'idShamanHUDGCDFrame', spellframe)

	spellframe.texture = spellframe:CreateTexture(nil, 'HIGH')
	spellframe.texture:SetAllPoints(spellframe)
	spellframe:SetWidth(icon_size)
	spellframe:SetHeight(icon_size)
	spellframe:SetPoint(MC, UIParent, MC, 100, 100)
	spellframe:Show()
	self.spellframe = spellframe

	gcdframe:SetWidth(spellframe:GetWidth())
	gcdframe:SetHeight(spellframe:GetHeight() / 4)
	gcdframe:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar');
	gcdframe:SetPoint(BC, spellframe, TC)
	gcdframe:Show()
	self.gcdframe = gcdframe

	self.rotation = {
		self.doLightningbolt,
		self.doStormstrike,
		self.doEarthshock,
		self.doLavaLash,
	}
end

function addon:onevent (event_name, ...)
	local handler = self[event_name]

	if handler then
		handler(self, ...)
	end
end

function addon:onupdate (time_passed)
	local getCD = _G.GetSpellCooldown
	local iconframe = self.spellframe.texture
	local cdframe = self.gcdframe

	local spell = self:getNextSpell()
	local spell_start
	local spell_duration
	local spell_end

	local time = GetTime()

	if spell then
		spell_start, spell_duration = getCD(spell)
		spell_end = spell_start + spell_duration

		iconframe:SetTexture(select(3, GetSpellInfo(spell)))

	else
		spell_start, spell_duration = getCD('Lightning Bolt')
		spell_end = spell_start + spell_duration

		iconframe:SetTexture('')
	end

	cdframe:SetMinMaxValues(spell_start, spell_end)
	cdframe:SetValue(time)
end

addon:RegisterEvent('PLAYER_LOGIN')
addon:SetScript('OnEvent', addon.onevent)
addon:SetScript('OnUpdate', addon.onupdate)

_G.idShamanHUD = addon

