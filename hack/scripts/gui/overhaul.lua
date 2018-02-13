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

local Button=defclass(Button,widgets.Widget)

Button.ATTRS={
    on_click = DEFAULT_NIL,
    graphic = DEFAULT_NIL, --refers to the name of a tilepage
    label = DEFAULT_NIL
}

function Button:preUpdateLayout()
    self.frame=self.frame or {}
    if not self.page then self.frame.w=0 self.frame.h=0 return end
    self.frame.w=self.page.page_dim_x
    self.frame.h=self.page.page_dim_y
    self.layoutUpdated=true
end

function Button:onRenderBody(dc)
    if not self.page then return end
    for k,v in ipairs(self.page.texpos) do
        dc:seek(k%self.frame.w,math.floor(k/self.frame.h)):tile(32,v)
    end
end

function Button:onInput(keys)
    if keys._MOUSE_L_DOWN and self:getMousePos() and self.on_click then
        self.on_click()
    end
end

function Button:init(args)
    if not self.graphic then return end
    for k,v in ipairs(df.global.texture.page) do
        if v.token==self.graphic then self.page=v return end
    end
    error('No tilepage found: '..self.graphic)
end

local OverhaulUI=defclass(OverhaulUI,guidm.MenuOverlay)

local function recursiveLabelFind(scr)
    if not scr.visible then return false end
    if scr:getMousePos() and scr.label then return scr.label end
    for _,child in pairs(scr.subviews) do
        local label=recursiveLabelFind(child)
        if label then return label end
    end
end

function OverhaulUI:renderSubviews(dc)
    local highlighted=false
    for _,child in pairs(self.subviews) do
        local label=recursiveLabelFind(child)
        if label then
            self.subviews.highlight_label:setText(recursiveLabelFind(child)) 
            highlighted=true 
        end
        if child.visible then
            child:render(dc)
        end
    end
    if not highlighted then self.subviews.highlight_label:setText('') end
end

function OverhaulUI:onRender()
    self._native.parent:render()
    self:renderSubviews(gui.Painter{})
end

allowedViewscreens={}

allowedViewscreens[df.viewscreen_dwarfmodest]=true

function OverhaulUI:onIdle()
    self._native.parent:logic()
    if not allowedViewscreens[self._native.parent._type] then
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
    if keys.LEAVESCREEN then
        self:setSelected('main_ui')
        df.global.ui.main.mode=df.ui_sidebar_mode.Default
        self.allow_options=true
    end
    for code,_ in pairs(keys) do
        if self.allowKeyPresses or allowedKeys[code] then
            self:sendInputToParent(code)
        end
    end
    self:inputToSubviews(keys)
    df.global.enabler.mouse_lbut=0
    df.global.enabler.mouse_lbut_down=0
    df.global.enabler.mouse_rbut=0
    df.global.enabler.mouse_rbut_down=0
end

function OverhaulUI:onAboutToShow(parent)
    df.global.ui_area_map_width=3
end

local function saveAndQuit()
    dfhack.run_command('quicksave')
    dfhack.run_command('nopause 1')
    dfhack.timeout(2,'ticks',function() dfhack.run_command('die') end)
end

function OverhaulUI:setSelected(view_id)
    local idx = utils.linear_index(self.subviews.pages.subviews, self.subviews[view_id])
    if not idx then
        error('Unknown page: '..view_id)
    end
    self.subviews.pages:setSelected(idx)
    self.allow_options=false
end

function OverhaulUI:preUpdateLayout()
    local frame={b=df.global.gps.dimy-13,r=43,w=43}
    self.subviews.landscaping.frame=frame
    self.subviews.construction.frame=frame
    self.subviews.units.frame=frame
    self.subviews.jobs.frame=frame
    self.subviews.items.frame=frame
    self.subviews.world.frame=frame
    self.subviews.highlight_label.frame={b=1,l=1}
end

function OverhaulUI:init(args)
    self.allow_options=true
    self.view_id='overhaul_ui'
    self:addviews{
        widgets.Panel{
            frame={t=0,l=0,h=20,r=0},
            on_render=function(dc)
                dc:clear()
            end,
        },
        widgets.Pages{
            view_id='pages',
            subviews={
            widgets.Panel{
                view_id='main_ui',
                subviews={
                Button{
                    --Some designations, farm plots.
                    graphic="LANDSCAPE_BUTTON",
                    label="Manipulate the land in various ways.",
                    on_click=function()
                        self:setSelected('landscaping')
                    end,
                    frame={t=1,l=1}
                },
                Button{
                    --Basically the whole building menu excepting workshops and furnaces.
                    graphic="CONSTRUCTION_BUTTON",
                    label="Construct walls, furniture and similar.",
                    on_click=function()
                        self:setSelected('construction')                    
                    end,
                    frame={t=1,l=10}
                },
                Button{
                    --Reports, unit list, military, squads, burrows, nobles.
                    graphic="UNIT_BUTTON",
                    label="Manage your "..df.creature_raw.find(df.global.ui.race_id).name[1]..", their pets, and other citizens.",
                    on_click=function()
                        self:setSelected('units')
                    end,
                    frame={t=1,l=19}
                },
                Button{
                    --Orders, some designations, job list, burrows (again), zones, rooms/buildings, workshops, furnaces, job manager.
                    graphic="JOB_BUTTON",
                    label="Manage "..df.creature_raw.find(df.global.ui.race_id).name[2].." labors.",
                    on_click=function()
                        self:setSelected('jobs')
                    end,
                    frame={t=10,l=1}
                },
                Button{
                    --Some designations, hauling, stock screens, artifacts, stockpiles.
                    graphic="ITEM_BUTTON",
                    label="Manage your fortress's items.",
                    on_click=function()
                        self:setSelected('items')
                    end,
                    frame={t=10,l=10}
                },
                Button{
                    --Status, locations, civilization/world info, depot access, points/routes/notes, announcements
                    graphic="WORLD_BUTTON",
                    label="Manage the fortress and its environs.",
                    on_click=function()
                        self:setSelected('world')
                    end,
                    frame={t=10,l=19}
                },
            }
            },

            widgets.Panel{
                view_id='landscaping',
                subviews={
                Button{
                    graphic="LANDSCAPE_BUTTON",
                    label="Mining",
                    on_click=function()
                        df.global.ui.main.mode=df.ui_sidebar_mode.DesignateMine
                        self.subviews.landscaping_label:setText("Currently: Mining")
                    end
                },
                widgets.Label{
                    frame={b=1,l=1},

                    view_id='landscaping_label',
                    text=' '
                }
                }
            },
            widgets.Panel{
                view_id='construction',
                subviews={
                    Button{
                        graphic="LANDSCAPE_BUTTON",
                        label="Wall",
                        on_click=function()
                            df.global.ui.main.mode=df.ui_sidebar_mode.DesignateMine
                            self.subviews.landscaping_label:setText("Currently: Mining")
                        end
                    },
                }
            },
            widgets.Panel{
                view_id='units',
                subviews={
                
                }
            },
            widgets.Panel{
                view_id='jobs',
                subviews={
                
                }
            },
            widgets.Panel{
                view_id='items',
                subviews={
                
                }
            },
            widgets.Panel{
                view_id='world',
                subviews={
                
                }
            },

            }
        },
        widgets.Label{
            view_id='highlight_label',
            text=' '
        },
        Button{
            graphic="SAVE_BUTTON",
            label="Save and quit the game.",
            on_click=function()
                dlg.showYesNoPrompt("Dwarf Fortress","Are you sure you want to quit the game?",COLOR_WHITE,saveAndQuit)
            end,
            frame={t=1,r=1}
        },
        Button{
            
        }
    }
end

viewscreenActions={}

viewscreenActions[df.viewscreen_dwarfmodest]=function()
    local overhaul=OverhaulUI{}
    overhaul:show()
end


local function checkViewscreen()
    local viewfunc=viewscreenActions[dfhack.gui.getCurViewscreen()._type]
    if viewfunc then viewfunc() end
end

require('repeat-util').scheduleUnlessAlreadyScheduled("putnam_overhaul",1,"frames",checkViewscreen)