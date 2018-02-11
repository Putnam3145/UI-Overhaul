-- Replaces DF's UI with an entirely new one.
--[====[

gui/overhaul
================
Adds a new mouse-enabled UX that should be self-explanatory.

]====]

local utils = require('utils')
local gui = require('gui')
local guidm = require('gui.dwarfmode')
local widgets = require('gui.widgets')
local dlg = require('gui.dialogs')

local OverhaulUI=defclass(OverhaulUI,guidm.MenuOverlay)

local function round(num)
    return math.floor(num+0.5)
end

function OverhaulUI:onRender()
    self._native.parent:render()
end

function OverhaulUI:onIdle()
    self._native.parent:logic()
    if dfhack.gui.getFocusString(self._native.parent)~="dwarfmode/Default" then
        self:dismiss()
    end
end

local allowedKeys={
    D_PAUSE=true, D_ONESTEP=true,
    CURSOR_UP=true, CURSOR_DOWN=true,
    CURSOR_LEFT=true, CURSOR_RIGHT=true,
    CURSOR_UPLEFT=true, CURSOR_UPRIGHT=true,
    CURSOR_DOWNLEFT=true, CURSOR_DOWNRIGHT=true,
    CURSOR_UP_FAST=true, CURSOR_DOWN_FAST=true,
    CURSOR_LEFT_FAST=true, CURSOR_RIGHT_FAST=true,
    CURSOR_UPLEFT_FAST=true, CURSOR_UPRIGHT_FAST=true,
    CURSOR_DOWNLEFT_FAST=true, CURSOR_DOWNRIGHT_FAST=true,
    CURSOR_UP_Z=true, CURSOR_DOWN_Z=true,
    CURSOR_UP_Z_AUX=true, CURSOR_DOWN_Z_AUX=true,
    _MOUSE_L=true, _MOUSE_L_DOWN=true,
    _MOUSE_R=true, _MOUSE_R_DOWN=true,
}

function OverhaulUI:onInput(keys)
    if keys._MOUSE_L then
        df.global.enabler.mouse_lbut=1
    end
    if keys._MOUSE_L_DOWN then
        df.global.enabler.mouse_lbut_down=1
    end
    if keys._MOUSE_R then
        df.global.enabler.mouse_rbut=1
    end
    if keys._MOUSE_R_DOWN then
        df.global.enabler.mouse_rbut_down=1
    end
    for code,_ in pairs(keys) do
        print(code)
        if allowedKeys[code] then
            self:sendInputToParent(code)
        end
    end
    df.global.enabler.mouse_lbut=0
    df.global.enabler.mouse_lbut_down=0
    df.global.enabler.mouse_rbut=0
    df.global.enabler.mouse_rbut_down=0
end

function OverhaulUI:onAboutToShow(parent)
    self.allow_options=true
end

viewscreenActions={}

viewscreenActions["dwarfmode/Default"]=function()
    local overhaul=OverhaulUI{}
    overhaul:show()
end


local function checkViewscreen()
    local viewfunc=viewscreenActions[dfhack.gui.getCurFocus]
    if viewfunc then viewfunc() end
end

require('repeat-util').scheduleUnlessAlreadyScheduled("putnam_overhaul",1,"frames",checkViewscreen)