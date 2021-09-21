local core_mainmenu = require("core_mainmenu")
local lib_helpers = require("solylib.helpers")
local lib_characters = require("solylib.characters")
local cfg = require("frame_counter.configuration")
local optionsLoaded, options = pcall(require, "frame_counter.options")

local optionsFileName = "addons/frame_counter/options.lua"
local ConfigurationWindow
local _StateByteOffset = 0x348

local FramesInCurrentState = 0
local PreviousState = -1
local StateHistory = {}
local FramesInStateHistory = {}

if optionsLoaded then
    -- If options loaded, make sure we have all those we need
    options.configurationEnableWindow = lib_helpers.NotNilOrDefault(options.configurationEnableWindow, true)
    options.enable                    = lib_helpers.NotNilOrDefault(options.enable, true)
    options.changed                   = lib_helpers.NotNilOrDefault(options.changed, true)
    options.Anchor                    = lib_helpers.NotNilOrDefault(options.Anchor, 1)
    options.X                         = lib_helpers.NotNilOrDefault(options.X, 50)
    options.Y                         = lib_helpers.NotNilOrDefault(options.Y, 5)
    options.W                         = lib_helpers.NotNilOrDefault(options.W, 200)
    options.H                         = lib_helpers.NotNilOrDefault(options.H, 350)
    options.NoTitleBar                = lib_helpers.NotNilOrDefault(options.NoTitleBar, "")
    options.NoResize                  = lib_helpers.NotNilOrDefault(options.NoResize, "")
    options.NoMove                    = lib_helpers.NotNilOrDefault(options.NoMove, "")
    options.AlwaysAutoResize          = lib_helpers.NotNilOrDefault(options.AlwaysAutoResize, "")
    options.TransparentWindow         = lib_helpers.NotNilOrDefault(options.TransparentWindow, false)
    options.ClearAfterFrames          = lib_helpers.NotNilOrDefault(options.ClearAfterFrames, 15)
else
    options = {
        configurationEnableWindow = true,

        enable = true,
        changed = true,
        Anchor = 1,
        X = 50,
        Y = 50,
        W = 450,
        H = 350,
        NoTitleBar = "",
        NoResize = "",
        NoMove = "",
        AlwaysAutoResize = "",
        TransparentWindow = false,
        ClearAfterFrames = 15;
    }
end


local function SaveOptions(options)
    local file = io.open(optionsFileName, "w")
    if file ~= nil then
        io.output(file)

        io.write("return\n")
        io.write("{\n")
        io.write(string.format("    configurationEnableWindow = %s,\n", tostring(options.configurationEnableWindow)))
        io.write(string.format("    enable = %s,\n", tostring(options.enable)))
        io.write(string.format("    Anchor = %i,\n", options.Anchor))
        io.write(string.format("    X = %i,\n", options.X))
        io.write(string.format("    Y = %i,\n", options.Y))
        io.write(string.format("    W = %i,\n", options.W))
        io.write(string.format("    H = %i,\n", options.H))
        io.write(string.format("    NoTitleBar = \"%s\",\n", options.NoTitleBar))
        io.write(string.format("    NoResize = \"%s\",\n", options.NoResize))
        io.write(string.format("    NoMove = \"%s\",\n", options.NoMove))
        io.write(string.format("    AlwaysAutoResize = \"%s\",\n", options.AlwaysAutoResize))
        io.write(string.format("    TransparentWindow = %s,\n", options.TransparentWindow))
        io.write(string.format("    ClearAfterFrames = %i,\n", options.ClearAfterFrames))
        io.write("}\n")

        io.close(file)
    end
end

local function ReadPlayerStateByte()
    local characterPointer = lib_characters.GetSelf()
    if characterPointer ~=0 then
        return pso.read_u32(characterPointer + _StateByteOffset)
    else
        return 0
    end
end

local function GetStateColor(state)
    local color
    if state == 0x01 then
        -- Standing, Gray
        color = "0x77FFFFFF"
    elseif state == 0x05 or state == 0x06 or state == 0x07 then
        -- Attacking, Red
        color = "0xFFFF9999"
    elseif state == 0x08 then
        -- Casting, Blue
        color = "0xFF9999FF"
    else
        color = "0xFFFFFFFF"
    end
    return color
end

local function GetStateDisplay(state)
    local display
    if state == 0x01 then
        display = "Standing"
    elseif state == 0x02 then
        display = "Walking"
    elseif state == 0x04 then
        display = "Running"
    elseif state == 0x05 then
        display = "Attack(1)"
    elseif state == 0x06 then
        display = "Attack(2)"
    elseif state == 0x07 then
        display = "Attack(3)"
    elseif state == 0x08 then
        display = "Casting"
    elseif state == 0x09 then
        display = "PB Startup"
    elseif state == 0x0A then
        display = "Recoil"
    elseif state == 0x0E then
        display = "Knocked Down"
    elseif state == 0x0F then
        display = "Dead"
    elseif state == 0x13 then
        display = "Photon Blast"
    elseif state == 0x14 then
        display = "Teleporting"
    elseif state == 0x17 then
        display = "Emote"
    else
        -- Lots of missing possible states, just display the code
        display = string.format("Unknown(0x%02X)", state)
    end
    return display
end

local function present()
    -- If the addon has never been used, open the config window
    -- and disable the config window setting
    if options.configurationEnableWindow then
        ConfigurationWindow.open = true
        options.configurationEnableWindow = false
    end
    ConfigurationWindow.Update()

    if ConfigurationWindow.changed then
        ConfigurationWindow.changed = false
        SaveOptions(options)
    end

    -- Global enable here to let the configuration window work
    if options.enable == false then
        return
    end

    local windowName = "Frame Counter"

    if options.TransparentWindow == true then
        imgui.PushStyleColor("WindowBg", 0.0, 0.0, 0.0, 0.0)
    end

    if options.AlwaysAutoResize == "AlwaysAutoResize" then
        imgui.SetNextWindowSizeConstraints(150, 0, options.W, options.H)
    end

    if imgui.Begin(windowName,
        nil,
        {
            options.NoTitleBar,
            options.NoResize,
            options.NoMove,
            options.AlwaysAutoResize,
        }
    ) then
        -- imgui.PushItemWidth(400)
        imgui.Columns(2)
        imgui.SetColumnOffset(1, 0.7 * imgui.GetWindowWidth())
        imgui.SetColumnOffset(2, 0.9 * imgui.GetWindowWidth())

        local currentState = ReadPlayerStateByte()
        if currentState ~= PreviousState then
            if FramesInCurrentState > options.ClearAfterFrames and PreviousState == 1 then
                -- New action after standing for enough frames, start fresh
                StateHistory = {}
                FramesInStateHistory = {}
            elseif PreviousState ~= -1 then
                -- New action in a sequence, append
                StateHistory[#(StateHistory)+1] = PreviousState
                FramesInStateHistory[#(FramesInStateHistory)+1] = FramesInCurrentState
            end
            FramesInCurrentState = 1
        elseif FramesInCurrentState < 999 then
            -- Continuing the previous action. Capped at 999 just to keep things pretty
            FramesInCurrentState = FramesInCurrentState + 1
        end
        PreviousState = currentState

        -- Print history
        for i= 1,#(StateHistory) do
            local state = StateHistory[i]
            local stateColor = GetStateColor(state)
            lib_helpers.TextC(true, stateColor, "%s", GetStateDisplay(state))
            imgui.NextColumn()
            lib_helpers.TextC(true, stateColor, "%d", FramesInStateHistory[i])
            imgui.NextColumn()
        end       

        -- Print current state
        local stateColor = GetStateColor(currentState)
        lib_helpers.TextC(true, stateColor, "%s", GetStateDisplay(currentState))
        imgui.NextColumn()
        lib_helpers.TextC(true, stateColor, "%d", FramesInCurrentState)
        imgui.NextColumn()

        lib_helpers.WindowPositionAndSize(windowName,
            options.X,
            options.Y,
            options.W,
            options.H,
            options.Anchor,
            options.AlwaysAutoResize,
            options.changed)
    end
    imgui.End()

    if options.TransparentWindow == true then
        imgui.PopStyleColor()
    end

    options.changed = false
end

local function init()
    ConfigurationWindow = cfg.ConfigurationWindow(options)

    local function mainMenuButtonHandler()
        ConfigurationWindow.open = not ConfigurationWindow.open
    end

    core_mainmenu.add_button("Frame Counter", mainMenuButtonHandler)

    return
    {
        name = "Frame Counter",
        version = "1.0.0",
        author = "phelix",
        description = "Counts frames spent in animation",
        present = present,
    }
end

return
{
    __addon =
    {
        init = init
    }
}
