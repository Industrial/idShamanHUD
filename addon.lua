if select(2, UnitClass('player')) ~= 'SHAMAN' then return end

-- TODO: make the thing draggable

local GetSpellCooldown = GetSpellCooldown
local GetSpellInfo = GetSpellInfo

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
local weapon1_enchant_frame
local weapon2_enchant_frame

-- functions
local is_enhancement
local get_next_spell
local initialize
local enable
local disable
local onupdate

function is_enhancement()
  return GetPrimaryTalentTree() == 2
end

function get_next_spell()
  local get_cooldown = GetSpellCooldown

  --[[
    This is the current priority:
      1. Lava Lash
      2. Unleash Elements
      3. Flame Shock with Unleash Elements buff
      4. Lightning bolt with Maelstrom Weapon buff * 5
      5. Stormstrike
      6. Earth Shock
  ]]

  -- might not be the best solution to put this at 9999 but it makes the steps
  -- interchangeable so you could re-order them
  local lowest_time = 9999
  local lowest_spell

  -- 1.
  local ll_start, ll_time = get_cooldown('Lava Lash')
  local ll_end = ll_start + ll_time

  if ll_start == 0 then
    return 'Lava Lash'
  end

  -- since this is the first of the spells, don't put this in an if block since
  -- we need lowest_spell filled
  lowest_time = ll_end
  lowest_spell = 'Lava Lash'

  -- 2.
  local ue_start, ue_time = get_cooldown('Unleash Elements')
  local ue_end = ue_start + ue_time

  if ue_start == 0 then
    return 'Unleash Elements'
  end

  if ue_end < lowest_time then
    lowest_time = ue_end
    lowest_spell = 'Unleash Elements'
  end

  -- 3.
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

    if UnitBuff('player', 'Unleash Flame') then
      lowest_spell = 'Flame Shock'
    elseif UnitDebuff('target', 'Flame Shock') then
      lowest_spell = 'Earth Shock'
    else
      lowest_spell = 'Flame Shock'
    end
  end

  -- 4.
  local maelstrom_weapon_count = select(4, UnitBuff('player', 'Maelstrom Weapon'))
  if maelstrom_weapon_count and maelstrom_weapon_count == 5 then
    return 'Lightning Bolt'
  end

  -- 5.
  local ss_start, ss_time = get_cooldown('Stormstrike')
  local ss_end = ss_start + ss_time

  if ss_start == 0 then
    return 'Stormstrike'
  end

  if ss_end < lowest_time then
    lowest_time = ss_end
    lowest_spell = 'Stormstrike'
  end

  -- 6.
  -- See 3.

  return lowest_spell
end

function initialize(addon_name)
  if addon_name ~= 'idShamanHUD' then
    return
  end

  spell_frame = CreateFrame('Frame', 'idShamanHUDSpellFrame', UIParent)
  spell_frame.binding_text = spell_frame:CreateFontString(nil, 'ARTWORK')
  spell_frame.cooldown_text = spell_frame:CreateFontString(nil, 'ARTWORK')
  spell_frame.texture = spell_frame:CreateTexture(nil, 'HIGH')
  shield_frame = CreateFrame('Button', 'idShamanHUDShieldFrame', UIParent, 'SecureActionButtonTemplate')
  shield_frame.binding_text = shield_frame:CreateFontString(nil, 'ARTWORK')
  shield_frame.texture = shield_frame:CreateTexture(nil, 'HIGH')
  weapon1_enchant_frame = CreateFrame('Button', 'idShamanHUDWeapon1EnchantFrame', UIParent, 'SecureActionButtonTemplate')
  weapon1_enchant_frame.texture = weapon1_enchant_frame:CreateTexture(nil, 'HIGH')
  weapon2_enchant_frame = CreateFrame('Button', 'idShamanHUDWeapon2EnchantFrame', UIParent, 'SecureActionButtonTemplate')
  weapon2_enchant_frame.texture = weapon2_enchant_frame:CreateTexture(nil, 'HIGH')

  event_frame:UnregisterEvent('ADDON_LOADED')
end

function enable ()
  if not is_enhancement() then
    return
  end

  spell_frame:SetWidth(icon_size)
  spell_frame:SetHeight(icon_size)
  spell_frame:SetPoint(MC, UIParent, MC, 0, 0)

  spell_frame.binding_text:SetPoint(TL, spell_frame, TL, 3, -3)
  spell_frame.binding_text:SetJustifyH('RIGHT')
  spell_frame.binding_text:SetFont(GameFontNormal:GetFont(), 12, 'OUTLINE')
  spell_frame.binding_text:SetTextColor(1, 1, 1)
  spell_frame.binding_text:SetShadowColor(0, 0, 0)
  spell_frame.binding_text:SetShadowOffset(1, -1)

  spell_frame.cooldown_text:SetPoint(BR, spell_frame, BR, -3, 3)
  spell_frame.cooldown_text:SetJustifyH('RIGHT')
  spell_frame.cooldown_text:SetFont(GameFontNormal:GetFont(), 12, 'OUTLINE')
  spell_frame.cooldown_text:SetTextColor(1, 1, 1)
  spell_frame.cooldown_text:SetShadowColor(0, 0, 0)
  spell_frame.cooldown_text:SetShadowOffset(1, -1)

  spell_frame.texture:SetAllPoints(spell_frame)
  spell_frame.texture:SetTexCoord(.07, .93, .07, .93)

  shield_frame:SetWidth(spell_frame:GetWidth() / 100 * 80)
  shield_frame:SetHeight(spell_frame:GetHeight() / 100 * 80)
  shield_frame:SetPoint(MR, spell_frame, ML, -5, 0)
  shield_frame:SetAttribute('type', 'spell')
  shield_frame:SetAttribute('spell', 'Lightning Shield')

  shield_frame.binding_text:SetPoint(TL, shield_frame, TL, 3, -3)
  shield_frame.binding_text:SetJustifyH('RIGHT')
  shield_frame.binding_text:SetFont(GameFontNormal:GetFont(), 12, 'OUTLINE')
  shield_frame.binding_text:SetTextColor(1, 1, 1)
  shield_frame.binding_text:SetShadowColor(0, 0, 0)
  shield_frame.binding_text:SetShadowOffset(1, -1)
  shield_frame.binding_text:SetText(bindings['Lightning Shield'])

  shield_frame.texture:SetAllPoints(shield_frame)
  shield_frame.texture:SetTexture(select(3, GetSpellInfo('Lightning Shield')))
  shield_frame.texture:SetTexCoord(.07, .93, .07, .93)

  weapon1_enchant_frame:SetWidth(spell_frame:GetWidth() / 100 * 40)
  weapon1_enchant_frame:SetHeight(spell_frame:GetHeight() / 100 * 40)
  weapon1_enchant_frame:SetPoint(TR, spell_frame, BR, -2.5, -5)
  weapon1_enchant_frame:SetAttribute('type', 'spell')
  weapon1_enchant_frame:SetAttribute('spell', 'Windfury Weapon')

  weapon1_enchant_frame.texture:SetAllPoints(weapon1_enchant_frame)
  weapon1_enchant_frame.texture:SetTexture(select(3, GetSpellInfo('Windfury Weapon')))
  weapon1_enchant_frame.texture:SetTexCoord(.07, .93, .07, .93)

  weapon2_enchant_frame:SetWidth(spell_frame:GetWidth() / 100 * 40)
  weapon2_enchant_frame:SetHeight(spell_frame:GetHeight() / 100 * 40)
  weapon2_enchant_frame:SetPoint(TL, spell_frame, BL, 2.5, -5)
  weapon2_enchant_frame:SetAttribute('type', 'spell')
  weapon2_enchant_frame:SetAttribute('spell', 'Flametongue Weapon')

  weapon2_enchant_frame.texture:SetAllPoints(weapon2_enchant_frame)
  weapon2_enchant_frame.texture:SetTexture(select(3, GetSpellInfo('Flametongue Weapon')))
  weapon2_enchant_frame.texture:SetTexCoord(.07, .93, .07, .93)

  event_frame:SetScript('OnUpdate', onupdate)
  spell_frame:Show()
end

function disable()
  spell_frame:Hide()
  event_frame:SetScript('OnUpdate', nil)
end

function onupdate (time_passed)
  local spell
  local spell_start
  local spell_duration
  local spell_end

  local binding
  local time = GetTime()

  spell = get_next_spell()
  spell_start, spell_duration = GetSpellCooldown(spell)
  spell_end = spell_start + spell_duration

  spell_frame.texture:SetTexture(select(3, GetSpellInfo(spell)))

  binding = bindings[spell]
  if binding then
    spell_frame.binding_text:SetText(bindings[spell])
  end

  spell_frame.cooldown_text:SetText(spell_end > time and ('%.1f'):format(spell_end - time) or 0)

  if not UnitBuff('player', 'Lightning Shield') then
    shield_frame:Show()
  else
    shield_frame:Hide()
  end

  hasMainHandEnchant, mainHandExpiration, mainHandCharges, hasOffHandEnchant, offHandExpiration, offHandCharges = GetWeaponEnchantInfo()
  if not hasMainHandEnchant then
    weapon1_enchant_frame:Show()
  else
    weapon1_enchant_frame:Hide()
  end
  if not hasOffHandEnchant then
    weapon2_enchant_frame:Show()
  else
    weapon2_enchant_frame:Hide()
  end
end

event_frame:SetScript('OnEvent', function(frame, event, ...)
  if event == 'ADDON_LOADED' then
    initialize(...)
  elseif event == 'PLAYER_ENTERING_WORLD' then
    enable()
  elseif event == 'PLAYER_LOGOUT' then
    disable()
  elseif event == 'ACTIVE_TALENT_GROUP_CHANGED' then
    disable()
    enable()
  end
end)

event_frame:RegisterEvent('ACTIVE_TALENT_GROUP_CHANGED')
event_frame:RegisterEvent('ADDON_LOADED')
event_frame:RegisterEvent('PLAYER_ENTERING_WORLD')
event_frame:RegisterEvent('PLAYER_LOGOUT')

