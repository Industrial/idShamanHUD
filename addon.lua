if select(2, UnitClass('player')) ~= 'SHAMAN' then return end

-- TODO: make the thing draggable
-- TODO: make it work for all levels, adding spells when you have them
-- TODO: make it do nothing if not enhancement specced

local TL, TC, TR = 'TOPLEFT', 'TOP', 'TOPRIGHT'
local ML, MC, MR = 'LEFT', 'CENTER', 'RIGHT'
local BL, BC, BR = 'BOTTOMLEFT', 'BOTTOM', 'BOTTOMRIGHT'
local icon_size = 50
local bindings = {
  ['Unleash Elements'] = '1',
  ['Stormstrike'] = '2',
  ['Lava Lash'] = '3',
  ['Lightning Bolt'] = 's1',
  ['Flame Shock'] = 's2',
  ['Earth Shock'] = 's3',
  ['Lightning Shield'] = 's4',
}
local event_frame = CreateFrame('Frame')
local spell_frame
local shield_frame

-- functions
local get_next_spell
local enable
local onupdate

function get_next_spell()
  local get_cooldown = GetSpellCooldown

  local maelstrom_weapon_count = select(4, UnitBuff('player', 'Maelstrom Weapon'))
  if maelstrom_weapon_count and maelstrom_weapon_count == 5 then
    return 'Lightning Bolt'
  end

  local ue_start, ue_time = get_cooldown('Unleash Elements')
  local ue_end = ue_start + ue_time

  local ss_start, ss_time = get_cooldown('Stormstrike')
  local ss_end = ss_start + ss_time

  local ll_start, ll_time = get_cooldown('Lava Lash')
  local ll_end = ll_start + ll_time

  local fs_start, fs_time = get_cooldown('Flame Shock')
  local fs_end = fs_start + fs_time

  local lowest_time = ue_end
  local lowest_spell = 'Unleash Elements'

  if ss_end < lowest_time then
    lowest_time = ss_end
    lowest_spell = 'Stormstrike'
  end

  if ll_end < lowest_time then
    lowest_time = ll_end
    lowest_spell = 'Lava Lash'
  end

  if fs_end < lowest_time then
    lowest_time = fs_end

    -- if the target has Flame Shock on him use Earth Shock
    if UnitDebuff('target', 'Flame Shock') then
      lowest_spell = 'Earth Shock'
    else
      lowest_spell = 'Flame Shock'
    end
  end

  return lowest_spell
end

function enable ()
  spell_frame = CreateFrame('Frame', 'idShamanHUDSpellFrame', UIParent)
  shield_frame = CreateFrame('Frame', 'idShamanHUDShieldFrame', UIParent)

  spell_frame:SetWidth(icon_size)
  spell_frame:SetHeight(icon_size)
  spell_frame:SetPoint(MC, UIParent, MC, 0, -150)
  spell_frame:Show()

  spell_frame.binding_text = spell_frame:CreateFontString(nil, 'ARTWORK')
  spell_frame.binding_text:SetPoint(TL, spell_frame, TL, 3, -3)
  spell_frame.binding_text:SetJustifyH('RIGHT')
  spell_frame.binding_text:SetFont(GameFontNormal:GetFont(), 12, 'OUTLINE')
  spell_frame.binding_text:SetTextColor(1, 1, 1)
  spell_frame.binding_text:SetShadowColor(0, 0, 0)
  spell_frame.binding_text:SetShadowOffset(1, -1)

  spell_frame.cooldown_text = spell_frame:CreateFontString(nil, 'ARTWORK')
  spell_frame.cooldown_text:SetPoint(BR, spell_frame, BR, -3, 3)
  spell_frame.cooldown_text:SetJustifyH('RIGHT')
  spell_frame.cooldown_text:SetFont(GameFontNormal:GetFont(), 12, 'OUTLINE')
  spell_frame.cooldown_text:SetTextColor(1, 1, 1)
  spell_frame.cooldown_text:SetShadowColor(0, 0, 0)
  spell_frame.cooldown_text:SetShadowOffset(1, -1)

  spell_frame.texture = spell_frame:CreateTexture(nil, 'HIGH')
  spell_frame.texture:SetAllPoints(spell_frame)
  spell_frame.texture:SetTexCoord(.07, .93, .07, .93)

  shield_frame:SetWidth(spell_frame:GetWidth() / 100 * 80)
  shield_frame:SetHeight(spell_frame:GetHeight() / 100 * 80)
  shield_frame:SetPoint(MR, spell_frame, ML, -5, 0)
  shield_frame:Show()

  shield_frame.texture = shield_frame:CreateTexture(nil, 'HIGH')
  shield_frame.texture:SetAllPoints(shield_frame)
  shield_frame.texture:SetTexture(select(3, GetSpellInfo('Lightning Shield')))
  shield_frame.texture:SetTexCoord(.07, .93, .07, .93)

  event_frame:SetScript('OnUpdate', onupdate)
end

function onupdate (time_passed)
  local getCD = GetSpellCooldown

  local spell
  local spell_start
  local spell_duration
  local spell_end

  local binding
  local time = GetTime()

  spell = get_next_spell()
  spell_start, spell_duration = getCD(spell)
  spell_end = spell_start + spell_duration

  spell_frame.texture:SetTexture(select(3, GetSpellInfo(spell)))

  binding = bindings[spell]
  if binding then
    spell_frame.binding_text:SetText(bindings[spell])
  end

  spell_frame.cooldown_text:SetText(spell_end > time and ('%.1f'):format(spell_end - time) or 0)

  if not UnitBuff('player', 'Lightning Shield') then
    shield_frame:SetAlpha(1)
  else
    shield_frame:SetAlpha(0)
  end
end

event_frame:SetScript('OnEvent', function(frame, event, ...)
  if event == 'PLAYER_LOGIN' then
    enable()
  end
end)

event_frame:RegisterEvent('PLAYER_LOGIN')
