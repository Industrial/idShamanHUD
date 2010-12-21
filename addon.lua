if select(2, UnitClass('player')) ~= 'SHAMAN' then return end

-- TODO: make the thing draggable
-- TODO: make it work for all levels, adding spells when you have them
-- TODO: make it do nothing if not enhancement specced

local TL, TC, TR = 'TOPLEFT', 'TOP', 'TOPRIGHT'
local ML, MC, MR = 'LEFT', 'CENTER', 'RIGHT'
local BL, BC, BR = 'BOTTOMLEFT', 'BOTTOM', 'BOTTOMRIGHT'
local icon_size = 50
local bindings = {
  ['Lava Lash'] = '1',
  ['Stormstrike'] = '2',
  ['Earth Shock'] = '3',
  ['Searing Totem'] = '4',
  ['Feral Spirit'] = '6',
  ['Unleash Elements'] = 'S1',
  ['Flame Shock'] = 'S2',
  ['Lightning Bolt'] = 'S3',
  ['Lightning Shield'] = 'S=',
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

  --[[
    This is the current priority:
      1. Searing Totem
      2. Lava Lash
      3. Unleash Elements
      4. Flame Shock with Unleash Elements buff
      5. Lightning bolt with Maelstrom Weapon buff * 5
      6. Stormstrike
      7. Earth Shock
      8. Spirit Wolves
  ]]

  -- might not be the best solution to put this at 9999 but it makes the steps
  -- interchangeable so you could re-order them
  local lowest_time = 9999
  local lowest_spell

  -- 1.
  local active, name, _, _, _ = GetTotemInfo(1)
  if not active or name ~= 'Searing Totem' then
    return 'Searing Totem'
  end

  -- 2.
  local ll_start, ll_time = get_cooldown('Lava Lash')
  local ll_end = ll_start + ll_time

  if ll_start == 0 then
    return 'Lava Lash'
  end

  if ll_end < lowest_time then
    lowest_time = ll_end
    lowest_spell = 'Lava Lash'
  end

  -- 3.
  local ue_start, ue_time = get_cooldown('Unleash Elements')
  local ue_end = ue_start + ue_time

  if ue_start == 0 then
    return 'Unleash Elements'
  end

  if ue_end < lowest_time then
    lowest_time = ue_end
    lowest_spell = 'Unleash Elements'
  end

  -- 4.
  local fs_start, fs_time = get_cooldown('Flame Shock')
  local fs_end = fs_start + fs_time

  if UnitBuff('player', 'Unleash Flame') then
    if fs_start == 0 then
      return 'Flame Shock'
    end
  elseif UnitBuff('target', 'Flame Shock') then
    if fs_start == 0 then
      return 'Earth Shock'
    end
  end

  if fs_end < lowest_time then
    lowest_time = fs_end

    if UnitBuff('target', 'Flame Shock') then
      lowest_spell = 'Earth Shock'
    else
      lowest_spell = 'Flame Shock'
    end
  end

  -- 5.
  local maelstrom_weapon_count = select(4, UnitBuff('player', 'Maelstrom Weapon'))
  if maelstrom_weapon_count and maelstrom_weapon_count == 5 then
    return 'Lightning Bolt'
  end

  -- 6.
  local ss_start, ss_time = get_cooldown('Stormstrike')
  local ss_end = ss_start + ss_time

  if ss_start == 0 then
    return 'Stormstrike'
  end

  if ss_end < lowest_time then
    lowest_time = ss_end
    lowest_spell = 'Stormstrike'
  end

  -- 7.
  -- See 4.

  -- 8.
  local frsp_start, frsp_time = get_cooldown('Feral Spirit')
  local frsp_end = frsp_start + frsp_time

  if frsp_start == 0 then
    return 'Feral Spirit'
  end

  if frsp_end < lowest_time then
    lowest_time = frsp_end
    lowest_spell = 'Feral Spirit'
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

  shield_frame.binding_text = shield_frame:CreateFontString(nil, 'ARTWORK')
  shield_frame.binding_text:SetPoint(TL, shield_frame, TL, 3, -3)
  shield_frame.binding_text:SetJustifyH('RIGHT')
  shield_frame.binding_text:SetFont(GameFontNormal:GetFont(), 12, 'OUTLINE')
  shield_frame.binding_text:SetTextColor(1, 1, 1)
  shield_frame.binding_text:SetShadowColor(0, 0, 0)
  shield_frame.binding_text:SetShadowOffset(1, -1)
  shield_frame.binding_text:SetText(bindings['Lightning Shield'])

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

