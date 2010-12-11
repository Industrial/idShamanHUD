if select(2, UnitClass('player')) ~= 'SHAMAN' then return end

-- TODO: check for feral spirit, deactivate otherwise
-- TODO: make the thing draggable

local _G = _G
local TL, TC, TR = 'TOPLEFT', 'TOP', 'TOPRIGHT'
local ML, MC, MR = 'LEFT', 'CENTER', 'RIGHT'
local BL, BC, BR = 'BOTTOMLEFT', 'BOTTOM', 'BOTTOMRIGHT'

local icon_size = 50

local bindings = {
  ['Lightning Bolt'] = '1',
  ['Stormstrike'] = '2',
  ['Lava Lash'] = '3',
  ['Flame Shock'] = 's2',
  ['Earth Shock'] = 's3',
}

local addon = CreateFrame('Frame')

addon.onupdate_timer = 0

function addon:getNextSpell()
  local getCD = _G.GetSpellCooldown

  local lowest_time
  local lowest_spell

  local ss_start, ss_time, ss_end
  local es_start, es_time, es_end
  local ll_start, ll_time, ll_end
  
  local mw = select(4, UnitBuff('player', 'Maelstrom Weapon'))
  local ss = select(4, UnitDebuff('target', 'Stormstrike'))

  if
    mw and mw == 5 and
    ss and ss > 0
  then
    return 'Lightning Bolt'
  else
    ss_start, ss_time = getCD('Stormstrike')
    ss_end = ss_start + ss_time

    -- flame shock is on the same cooldown
    es_start, es_time = getCD('Earth Shock')
    es_end = es_start + es_time

    ll_start, ll_time = getCD('Lava Lash')
    ll_end = ll_start + ll_time

    lowest_time = ss_end
    lowest_spell = 'Stormstrike'

    if es_end < lowest_time then
      lowest_time = es_end
      if UnitDebuff('target', 'Flame Shock') then
        lowest_spell = 'Earth Shock'
      else
        lowest_spell = 'Flame Shock'
      end
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
  local mwframe = CreateFrame('Frame', 'idShamanHUDMaelstromWeaponFrame', spellframe)

  spellframe.text = spellframe:CreateFontString(nil, 'ARTWORK')

  spellframe:SetWidth(icon_size)
  spellframe:SetHeight(icon_size)
  spellframe:SetPoint(MC, UIParent, MC, 0, 0)
  spellframe:Show()
  spellframe.text:SetPoint(MC, spellframe, MC)
  spellframe.text:SetJustifyH('RIGHT')
  spellframe.text:SetFont(GameFontNormal:GetFont(), 24, 'OUTLINE')
  spellframe.text:SetTextColor(1, 1, 1)
  spellframe.text:SetShadowColor(0, 0, 0)
  spellframe.text:SetShadowOffset(1, -1)
  self.spellframe = spellframe

  spellframe.texture = spellframe:CreateTexture(nil, 'HIGH')
  spellframe.texture:SetAllPoints(spellframe)

  gcdframe:SetWidth(spellframe:GetWidth())
  gcdframe:SetHeight(spellframe:GetHeight() / 4)
  gcdframe:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar');
  gcdframe:SetPoint(BC, spellframe, TC)
  gcdframe:Show()
  self.gcdframe = gcdframe

  gcdframe.background = gcdframe:CreateTexture(nil, 'BACKGROUND')
  gcdframe.background:SetAllPoints(gcdframe)
  gcdframe.background:SetTexture(0, 0, 0, 1)

  mwframe:SetWidth(spellframe:GetWidth() / 4)
  mwframe:SetHeight(spellframe:GetHeight())
  mwframe:SetPoint(ML, spellframe, MR)

  local f, width, height, padding
  width = mwframe:GetWidth()
  padding = width / 5 / 2
  height = mwframe:GetHeight() - padding * 6

  for i = 1, 5 do
    f = mwframe:CreateTexture('nil', 'HIGH')

    f:SetWidth(width / 5 * 4)
    f:SetHeight(height / 5)
    f:SetTexture(1, 0, 0, 1)

    if i == 1 then
      f:SetPoint(TL, mwframe, TL, padding, -padding)
    else
      f:SetPoint(TC, mwframe['count' .. i - 1], BC, 0, -padding)
    end

    mwframe['count' .. i] = f
  end

  mwframe.background = mwframe:CreateTexture(nil, 'BACKGROUND')
  mwframe.background:SetAllPoints(mwframe)
  mwframe.background:SetTexture(0, 0, 0, 1)

  self.mwframe = mwframe

  self:onupdate(1)
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
  local bindingtext = self.spellframe.text
  local cdframe = self.gcdframe

  local spell
  local spell_start
  local spell_duration
  local spell_end

  local binding
  local time = GetTime()

  spell = self:getNextSpell()
  spell_start, spell_duration = getCD(spell)
  spell_end = spell_start + spell_duration

  iconframe:SetTexture(select(3, GetSpellInfo(spell)))

  binding = bindings[spell]
  if binding then
    bindingtext:SetText(bindings[spell])
  end

  cdframe:SetMinMaxValues(spell_start, spell_end)
  cdframe:SetValue(time)
  if spell_start <= 0 then
    cdframe.background:SetTexture(0, 1, 0, 1)
  else
    cdframe.background:SetTexture(0, 0, 0, 1)
  end

  mwcount = select(4, UnitBuff('player', 'Maelstrom Weapon'))
  for i = 1, 5 do
    if mwcount and i <= mwcount then
      self.mwframe['count' .. i]:SetAlpha(100)
    else
      self.mwframe['count' .. i]:SetAlpha(0)
    end
  end
end

addon:RegisterEvent('PLAYER_LOGIN')
addon:SetScript('OnEvent', addon.onevent)
addon:SetScript('OnUpdate', addon.onupdate)

_G.idShamanHUD = addon

