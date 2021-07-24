local function ConfigurationWindow(configuration)
    local this =
    {
        title = "Frame Counter - Configuration",
        open = false,
        changed = false,
    }

    local _configuration = configuration

    local _showWindowSettings = function()
        local success
        local anchorList =
        {
            "Top Left (Disabled)", "Left", "Bottom Left",
            "Top", "Center", "Bottom",
            "Top Right", "Right", "Bottom Right",
        }

        if imgui.Checkbox("Enable", _configuration.enable) then
            _configuration.enable = not _configuration.enable
            this.changed = true
        end
        
        if imgui.Checkbox("No title bar", _configuration.NoTitleBar == "NoTitleBar") then
            if _configuration.NoTitleBar == "NoTitleBar" then
                _configuration.NoTitleBar = ""
            else
                _configuration.NoTitleBar = "NoTitleBar"
            end
            _configuration.changed = true
            this.changed = true
        end
        if imgui.Checkbox("No resize", _configuration.NoResize == "NoResize") then
            if _configuration.NoResize == "NoResize" then
                _configuration.NoResize = ""
            else
                _configuration.NoResize = "NoResize"
            end
            _configuration.changed = true
            this.changed = true
        end
        if imgui.Checkbox("No move", _configuration.NoMove == "NoMove") then
            if _configuration.NoMove == "NoMove" then
                _configuration.NoMove = ""
            else
                _configuration.NoMove = "NoMove"
            end
            _configuration.changed = true
            this.changed = true
        end
        if imgui.Checkbox("Always Auto Resize", _configuration.AlwaysAutoResize == "AlwaysAutoResize") then
            if _configuration.AlwaysAutoResize == "AlwaysAutoResize" then
                _configuration.AlwaysAutoResize = ""
            else
                _configuration.AlwaysAutoResize = "AlwaysAutoResize"
            end
            _configuration.changed = true
            this.changed = true
        end

        if imgui.Checkbox("Transparent window", _configuration.TransparentWindow) then
            _configuration.TransparentWindow = not _configuration.TransparentWindow
            _configuration.changed = true
            this.changed = true
        end

        imgui.Text("Position and Size")
        imgui.PushItemWidth(200)
        success, _configuration.Anchor = imgui.Combo("Anchor", _configuration.Anchor, anchorList, table.getn(anchorList))
        imgui.PopItemWidth()
        if success then
            _configuration.changed = true
            this.changed = true
        end

        imgui.PushItemWidth(100)
        success, _configuration.X = imgui.InputInt("X", _configuration.X)
        imgui.PopItemWidth()
        if success then
            _configuration.changed = true
            this.changed = true
        end

        imgui.SameLine(0, 38)
        imgui.PushItemWidth(100)
        success, _configuration.Y = imgui.InputInt("Y", _configuration.Y)
        imgui.PopItemWidth()
        if success then
            _configuration.changed = true
            this.changed = true
        end

        imgui.PushItemWidth(100)
        success, _configuration.W = imgui.InputInt("Width", _configuration.W)
        imgui.PopItemWidth()
        if success then
            _configuration.changed = true
            this.changed = true
        end

        imgui.SameLine(0, 10)
        imgui.PushItemWidth(100)
        success, _configuration.H = imgui.InputInt("Height", _configuration.H)
        imgui.PopItemWidth()
        if success then
            _configuration.changed = true
            this.changed = true
        end

        imgui.Text("")
        imgui.Text("Frame Counter Options")
        imgui.PushItemWidth(100)
        success, _configuration.ClearAfterFrames = imgui.InputInt("Clear History After N Standing Frames", _configuration.ClearAfterFrames)
        imgui.PopItemWidth()
        if success then
            _configuration.changed = true
            this.changed = true
        end
    end


    this.Update = function()
        if this.open == false then
            return
        end

        local success

        imgui.SetNextWindowSize(500, 400, 'FirstUseEver')
        success, this.open = imgui.Begin(this.title, this.open)

        _showWindowSettings()

        imgui.End()
    end

    return this
end

return
{
    ConfigurationWindow = ConfigurationWindow,
}
