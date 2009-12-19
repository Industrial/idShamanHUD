if select(2, UnitClass('player')) ~= 'SHAMAN' then return end

local _G = _G
local TL, TC, TR = 'TOPLEFT', 'TOP', 'TOPRIGHT'
local ML, MC, MR = 'LEFT', 'CENTER', 'RIGHT'
local BL, BC, BR = 'BOTTOMLEFT', 'BOTTOM', 'BOTTOMRIGHT'

local addon = CreateFrame('Frame')

addon.spells = {
	rotation = {},
	notifiers = {}
}

function addon:PLAYER_LOGIN ()
	print('PLAYER_LOGIN')
end

function addon:onevent (event_name, ...)
	local handler = self[event_name]

	if handler then
		handler(...)
	end
end

addon:RegisterEvent('PLAYER_LOGIN')
addon:SetScript('OnEvent', addon.onevent)

_G.idShamanHUD = addon

