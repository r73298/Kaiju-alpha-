-- On-screen error report (so you can see why the GUI failed)
local function __tb(e)
    return debug.traceback(tostring(e), 2)
end
local function __report(stage, err)
    local text = "[GUI ERROR] " .. stage .. "\n" .. tostring(err)
    warn(text)
    pcall(function()
        local g = Instance.new("ScreenGui")
        g.Name = "GuiErrorReport"
        g.ResetOnSpawn = false
        g.DisplayOrder = 10000
        g.IgnoreGuiInset = true
        local placed = false
        if type(gethui) == "function" then placed = pcall(function() g.Parent = gethui() end) end
        if not placed then placed = pcall(function() g.Parent = game:GetService("CoreGui") end) end
        if not placed then g.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") end
        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1, -20, 0, 220)
        t.Position = UDim2.new(0, 10, 1, -230)
        t.BackgroundColor3 = Color3.fromRGB(20, 0, 0)
        t.BackgroundTransparency = 0.1
        t.TextColor3 = Color3.fromRGB(255, 120, 120)
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.TextYAlignment = Enum.TextYAlignment.Top
        t.TextWrapped = true
        t.TextSize = 13
        t.Font = Enum.Font.Code
        t.Text = text
        t.Parent = g
    end)
end

--[[
    ==============================================================
    DEOBFUSCATED BY @notninjaa3530 (Discord)
    ==============================================================
--]]

local players = game:GetService("Players")
local player = players.LocalPlayer
while not player do
    task.wait()
    player = players.LocalPlayer
end

local serviceCache = {}
local function getService(name)
    local service = serviceCache[name]
    if not service then
        service = game:GetService(name)
        if type(cloneref) == "function" then
            service = cloneref(service)
        end
        serviceCache[name] = service
    end
    return service
end
local argumentHelpers = { [108] = table.pack, [66] = unpack, [58] = table.move }
argumentHelpers.unpackValues = function(helpers, values)
    return helpers[66](values, 1, values.n)
end
argumentHelpers.appendValues = function(helpers, destination, offset, ...)
    local packedValues = helpers[108](...)
    helpers[58](packedValues, 1, packedValues.n, offset + 1, destination)
end
argumentHelpers.appendPackedValues = function(_helpers, destination, offset, values)
    for index = 1, values.n, 1 do
        destination[offset + index] = values[index]
    end
    destination.n = offset + values.n
end

-- ==================================================================
--  HIGH-PING FREEZE
--  ping >= HI  -> everything freezes in place (loops, timers, buying, rolling)
--  ping <= LO for HOLD seconds -> everything continues exactly where it stopped
--  Only the ping check itself keeps running while frozen.
-- ==================================================================
do
    local old = rawget(_G, "HyzePing")
    if old then old.paused = false end -- a previous copy must never stay frozen
    local HP = { enabled = true, paused = false, total = 0, pauseAt = 0, ping = 0, hi = 1000, lo = 900, hold = 5 }
    _G.HyzePing = HP
    local rawWait, rawClock = task.wait, os.clock
    -- script clock: does not count the time spent frozen, so wait timers / stall checks / deadlines do not run out meanwhile
    function HP.clock()
        local t = rawClock() - HP.total
        if HP.paused then t = t - (rawClock() - HP.pauseAt) end
        return t
    end
    -- drop-in for task.wait: a frozen thread sits here and carries on from the next line when unfrozen
    function HP.wait(t)
        while HP.paused do rawWait(0.1) end
        local r = rawWait(t)
        while HP.paused do rawWait(0.1) end
        return r
    end
    HP.enabled = false -- ping freeze removed: loops never pause
    task.spawn(function()
        do return end -- (the ping monitor is switched off)
        local okSince = nil
        while _G.HyzePing == HP do
            local ping
            pcall(function()
                ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
            end)
            if not HP.enabled then
                -- switched off in the Extras tab: never frozen
                if HP.paused then
                    HP.total += rawClock() - HP.pauseAt
                    HP.paused, okSince = false, nil
                    if HP.onChange then pcall(HP.onChange, false, ping or 0) end
                end
            elseif ping then
                HP.ping = ping
                if not HP.paused then
                    if ping >= HP.hi then
                        HP.paused, HP.pauseAt, okSince = true, rawClock(), nil
                        if HP.onChange then pcall(HP.onChange, true, ping) end
                    end
                elseif ping <= math.min(HP.lo, HP.hi - 50) then
                    okSince = okSince or rawClock()
                    if rawClock() - okSince >= HP.hold then
                        HP.total += rawClock() - HP.pauseAt
                        HP.paused, okSince = false, nil
                        if HP.onChange then pcall(HP.onChange, false, ping) end
                    end
                else
                    okSince = nil -- went back above LO: the 5 second wait starts over
                end
            end
            rawWait(0.25)
        end
    end)
end

local components = {}

components.coreSettings = function(context)
    context.DEV = false
    context.NOVIS = true
    if not (game:IsLoaded()) then
        game.Loaded:Wait()
    end
    -- stop a previous copy of the original script if one is still running
    if type(_G.DungeonAutofarmDestruct) == "function" then
        local success, err = pcall(_G.DungeonAutofarmDestruct)
        if not success then
            warn("[DQ] could not stop the previous copy: " .. tostring(err))
        end
        task.wait(0.1)
    end
    local players = getService("Players")
    local localPlayer = players.LocalPlayer
    while not localPlayer do
        task.wait(0.1)
        localPlayer = players.LocalPlayer
    end
    context.Players = players
    context.LocalPlayer = localPlayer
    context.RunService = getService("RunService")
    context.UserInputService = getService("UserInputService")
    -- the only settings / state the GUI itself reads
    context.CFG = {
        streamer = true,
        streamerNameText = "harvard student",
    }
    context.RT = { destroyed = false }
    context.sliderConnections = {}
    context.loadConfig = function() end
end

components.uiLibrary = function(context)
    local runtimeState, config, localPlayer, userInputService =
        context.RT, context.CFG, context.LocalPlayer, context.UserInputService
    local runService, theme = context.RunService, {}
    theme.TextPrimary = Color3.fromHex("f0f0f4")
    theme.TextSub = Color3.fromHex("9898a2")
    theme.TextMuted = Color3.fromHex("686872")
    theme.TextOnAccent = Color3.fromHex("000000")
    theme.StatusBad = Color3.fromHex("D50000")
    theme.StatusGood = Color3.fromHex("2FBF71")
    theme.SurfaceHeader = Color3.fromHex("18181c")
    theme.SurfaceElement = Color3.fromHex("26262c")
    theme.SurfaceHover = Color3.fromHex("303038")
    theme.SurfaceField = Color3.fromHex("1c1c21")
    theme.SurfaceSection = Color3.fromHex("1e1e24")
    theme.SurfaceWell = Color3.fromHex("121216")
    theme.SurfaceChip = Color3.fromHex("0c0c0f")
    theme.Hairline = Color3.fromHex("323338")
    theme.BodyTop = Color3.fromHex("2a2a2f")
    theme.BodyMid = Color3.fromHex("1a1a1e")
    theme.BodyBot = Color3.fromHex("101013")
    theme.BodyTopA = 0.05
    theme.BodyMidA = 0.13
    theme.BodyBotA = 0.42
    theme.SweepSpeed = 0.22
    theme.AccentA = Color3.fromHex("A30000")
    theme.AccentMid = Color3.fromHex("F43120")
    theme.AccentB = Color3.fromHex("D50000")
    theme.AccentDark = Color3.fromHex("7A0000")
    theme.RadiusSm = 5
    theme.RadiusMd = 6
    theme.RadiusLg = 8
    theme.GapSm = 6
    theme.GapMd = 8
    theme.GapLg = 12
    theme.GapXl = 14
    theme.RowH = 34
    theme.HeaderH = 40
    local fontFamilies, sharedValue =
        {
            sans = "rbxasset://fonts/families/Montserrat.json",
            mono = "rbxasset://fonts/families/RobotoMono.json",
        }, {}
    sharedValue[Enum.FontWeight.Regular] = Enum.Font.Gotham
    sharedValue[Enum.FontWeight.Medium] = Enum.Font.GothamMedium
    sharedValue[Enum.FontWeight.SemiBold] = Enum.Font.GothamBold
    sharedValue[Enum.FontWeight.Bold] = Enum.Font.GothamBold
    local function setFont(argument, argument2, argument3)
        if
            not (
                pcall(function()
                    argument.FontFace = Font.new(fontFamilies[argument2], argument3)
                end)
            )
        then
            argument.Font = sharedValue[argument3] or Enum.Font.Gotham
        end
    end
    local sharedValue2 = {}
    sharedValue2.windowTitle =
        { family = "sans", weight = Enum.FontWeight.SemiBold, size = 15, color = "TextPrimary" }
    sharedValue2.windowChip =
        { family = "sans", weight = Enum.FontWeight.Bold, size = 15, color = "TextPrimary" }
    sharedValue2.rowLabel =
        { family = "sans", weight = Enum.FontWeight.Medium, size = 13, color = "TextPrimary" }
    sharedValue2.rowButton =
        { family = "sans", weight = Enum.FontWeight.SemiBold, size = 13, color = "TextOnAccent" }
    sharedValue2.rowEntry =
        { family = "sans", weight = Enum.FontWeight.SemiBold, size = 13, color = "TextPrimary" }
    sharedValue2.rowStat =
        { family = "sans", weight = Enum.FontWeight.Medium, size = 14, color = "TextPrimary" }
    sharedValue2.captionKey =
        { family = "sans", weight = Enum.FontWeight.Medium, size = 12, color = "TextSub" }
    sharedValue2.captionSub =
        { family = "sans", weight = Enum.FontWeight.Regular, size = 10, color = "TextMuted" }
    sharedValue2.captionStat =
        { family = "sans", weight = Enum.FontWeight.Bold, size = 12, color = "TextSub" }
    sharedValue2.monoValue =
        { family = "mono", weight = Enum.FontWeight.Medium, size = 11, color = "TextOnAccent" }
    sharedValue2.monoMeta =
        { family = "mono", weight = Enum.FontWeight.Medium, size = 10, color = "TextMuted" }
    sharedValue2.monoStat = { family = "mono", weight = Enum.FontWeight.Medium, size = 13, color = "TextSub" }
    local function corner(parent, argument)
        local corner2 = Instance.new("UICorner")
        corner2.CornerRadius = UDim.new(0, argument)
        corner2.Parent = parent
        return corner2
    end
    local function stroke(parent, argument, argument2)
        local stroke2 = Instance.new("UIStroke")
        stroke2.Color = argument or theme.Hairline
        stroke2.Thickness = argument2 or 1
        stroke2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke2.Parent = parent
        return stroke2
    end
    local function pad(parent, argument, argument2, argument3, argument4)
        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, argument)
        padding.PaddingRight = UDim.new(0, argument2)
        padding.PaddingBottom = UDim.new(0, argument3)
        padding.PaddingLeft = UDim.new(0, argument4)
        padding.Parent = parent
        return padding
    end
    local function vlist(parent, argument, argument2)
        local listLayout = Instance.new("UIListLayout")
        listLayout.FillDirection = Enum.FillDirection.Vertical
        listLayout.Padding = UDim.new(0, argument or theme.GapSm)
        listLayout.SortOrder = argument2 or Enum.SortOrder.LayoutOrder
        listLayout.Parent = parent
        return listLayout
    end
    local function flexFill(argument, argument2, argument3, argument4)
        if not argument2 then
            return false
        end
        argument.Size = UDim2.new(1, -argument2, argument3 or 1, argument4 or 0)
        return true
    end
    local function hlist(parent, argument)
        local listLayout = Instance.new("UIListLayout")
        listLayout.FillDirection = Enum.FillDirection.Horizontal
        listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        listLayout.Padding = UDim.new(0, argument or theme.GapMd)
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Parent = parent
        return listLayout
    end
    local function label(parent, argument, argument2, argument3)
        local value, label2 = sharedValue2[argument2] or sharedValue2.rowLabel, Instance.new("TextLabel")
        label2.BackgroundTransparency = 1
        label2.Text = argument or ""
        label2.TextColor3 = theme[value.color]
        label2.TextSize = value.size
        label2.TextXAlignment = Enum.TextXAlignment.Left
        label2.TextYAlignment = Enum.TextYAlignment.Center
        label2.LayoutOrder = argument3 or 1
        label2.Size = UDim2.new(1, 0, 1, 0)
        setFont(label2, value.family, value.weight)
        label2.Parent = parent
        return label2
    end
    local function accentGradient(parent, argument)
        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, theme.AccentA),
            ColorSequenceKeypoint.new(0.53, theme.AccentMid),
            ColorSequenceKeypoint.new(1, theme.AccentB),
        })
        gradient.Rotation = argument or 0
        gradient.Parent = parent
        return gradient
    end
    local sharedValue3, sharedValue4 = {}
    local function accentSweep(parent)
        parent.ClipsDescendants = true
        local sweep = Instance.new("Frame")
        sweep.Name = "Sweep"
        sweep.BackgroundColor3 = Color3.new(1, 1, 1)
        sweep.BorderSizePixel = 0
        sweep.Size = UDim2.new(2, 0, 1, 0)
        sweep.Position = UDim2.new(-1, 0, 0, 0)
        sweep.ZIndex = parent.ZIndex
        sweep.Parent = parent
        parent = Instance.new("UIGradient")
        parent.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, theme.AccentA),
            ColorSequenceKeypoint.new(0.125, theme.AccentMid),
            ColorSequenceKeypoint.new(0.25, theme.AccentB),
            ColorSequenceKeypoint.new(0.375, theme.AccentMid),
            ColorSequenceKeypoint.new(0.5, theme.AccentA),
            ColorSequenceKeypoint.new(0.625, theme.AccentMid),
            ColorSequenceKeypoint.new(0.75, theme.AccentB),
            ColorSequenceKeypoint.new(0.875, theme.AccentMid),
            ColorSequenceKeypoint.new(1, theme.AccentA),
        })
        parent.Parent = sweep
        sharedValue3[#sharedValue3 + 1] = sweep
        sharedValue4 = sharedValue4
            or runService.RenderStepped:Connect(function()
                local value = os.clock() * (theme.SweepSpeed or 0.22) % 1
                local position = UDim2.new(value - 1, 0, 0, 0)
                for index = #sharedValue3, 1, -1 do
                    value = sharedValue3[index]
                    if value.Parent then
                        value.Position = position
                    else
                        table.remove(sharedValue3, index)
                    end
                end
            end)
        return sweep
    end
    local function stopSweeps()
        if sharedValue4 then
            pcall(function()
                sharedValue4:Disconnect()
            end)
            sharedValue4 = nil
        end
        for index = #sharedValue3, 1, -1 do
            sharedValue3[index] = nil
        end
    end
    local function bodyGradient(parent)
        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, theme.BodyTop),
            ColorSequenceKeypoint.new(0.45, theme.BodyMid),
            ColorSequenceKeypoint.new(1, theme.BodyBot),
        })
        gradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, theme.BodyTopA),
            NumberSequenceKeypoint.new(0.45, theme.BodyMidA),
            NumberSequenceKeypoint.new(1, theme.BodyBotA),
        })
        gradient.Rotation = 90
        gradient.Parent = parent
        return gradient
    end
    local function shadow(argument, argument2, argument3, argument4, argument5, argument6)
        argument2, argument3, argument4, argument5, argument6 =
            argument2 or 8, argument3 or 1.5, argument4 or 10, argument5 or 0.04, argument6 or theme.RadiusLg
        local parent = Instance.new("Frame")
        parent.Name = (argument.Name or "Window") .. "Shadow"
        parent.BackgroundTransparency = 1
        parent.ZIndex = math.max(argument.ZIndex - 1, 0)
        local function helper()
            parent.Position, parent.Size, parent.AnchorPoint, parent.Visible =
                argument.Position, argument.Size, argument.AnchorPoint, argument.Visible
        end
        helper()
        parent.Parent = argument.Parent
        local value = { "Position", "Size", "AnchorPoint", "Visible" }
        for index, entry in ipairs(value) do
            argument:GetPropertyChangedSignal(entry):Connect(helper)
        end
        local function frame()
            if argument.Parent then
                if parent.Parent ~= argument.Parent then
                    parent.Parent = argument.Parent
                end
            else
                parent:Destroy()
            end
        end
        argument.AncestryChanged:Connect(frame)
        for index2 = 1, argument2, 1 do
            value, helper, frame = index2 * argument3, argument4 * (index2 / argument2), Instance.new("Frame")
            frame.Name = "L" .. index2
            frame.BackgroundColor3 = Color3.new(0, 0, 0)
            frame.BackgroundTransparency = 1 - argument5
            frame.BorderSizePixel = 0
            frame.ZIndex = argument.ZIndex - 1
            frame.Position = UDim2.fromOffset(-value, -value + helper)
            frame.Size = UDim2.new(1, value * 2, 1, value * 2)
            corner(frame, argument6 + value)
            frame.Parent = parent
        end
        return parent
    end
    local sharedValue5 = { frame = nil, label = nil, target = nil, showAt = nil, conn = nil }
    local function ensureTip(argument)
        if sharedValue5.frame then
            if sharedValue5.frame.Parent then
                return
            end
        end
        local tooltip = Instance.new("Frame")
        tooltip.Name = "Tooltip"
        tooltip.BackgroundColor3 = Color3.fromHex("3a3a42")
        tooltip.BorderSizePixel = 0
        tooltip.Visible = false
        tooltip.ZIndex = 500
        tooltip.AutomaticSize = Enum.AutomaticSize.XY
        tooltip.Size = UDim2.fromOffset(0, 0)
        tooltip.Parent = argument
        corner(tooltip, theme.RadiusSm)
        stroke(tooltip, Color3.fromHex("4a4a55"), 1)
        pad(tooltip, 6, 8, 6, 8)
        argument = Instance.new("TextLabel")
        argument.BackgroundTransparency = 1
        argument.AutomaticSize = Enum.AutomaticSize.XY
        argument.Size = UDim2.fromOffset(0, 0)
        argument.TextWrapped = true
        argument.TextXAlignment = Enum.TextXAlignment.Left
        argument.TextYAlignment = Enum.TextYAlignment.Top
        argument.TextColor3 = Color3.fromHex("e8e8ee")
        argument.TextSize = 11
        argument.ZIndex = 501
        setFont(argument, "sans", Enum.FontWeight.Medium)
        argument.Parent = tooltip
        local value = Instance.new("UISizeConstraint")
        value.MaxSize = Vector2.new(240, math.huge)
        value.Parent = argument
        sharedValue5.frame = tooltip
        sharedValue5.label = argument
        if sharedValue5.conn then
            sharedValue5.conn:Disconnect()
        end
        sharedValue5.conn = runService.RenderStepped:Connect(function()
            if not sharedValue5.target then
                return
            end
            local value2 = os.clock()
            if not sharedValue5.frame.Visible then
                if value2 < sharedValue5.showAt then
                    return
                end
                sharedValue5.frame.Visible = true
                local value3, stroke2 =
                    getService("TweenService"), sharedValue5.frame:FindFirstChildOfClass("UIStroke")
                sharedValue5.frame.BackgroundTransparency, sharedValue5.label.TextTransparency = 1, 1
                if stroke2 then
                    stroke2.Transparency = 1
                    value3:Create(stroke2, TweenInfo.new(0.16), { Transparency = 0 }):Play()
                end
                value3:Create(sharedValue5.frame, TweenInfo.new(0.16), { BackgroundTransparency = 0 }):Play()
                value3:Create(sharedValue5.label, TweenInfo.new(0.16), { TextTransparency = 0 }):Play()
            end
            local vector, value4 = userInputService:GetMouseLocation(), workspace.CurrentCamera
            local vector2, value5, value6 =
                value4 and value4.ViewportSize or Vector2.new(1920, 1080),
                sharedValue5.frame.AbsoluteSize.X,
                sharedValue5.frame.AbsoluteSize.Y
            value4, value2 =
                vector.X + 16 + value5 > vector2.X and vector.X - 16 - value5 or vector.X + 16,
                vector.Y + 18 + value6 > vector2.Y and vector.Y - 12 - value6 or vector.Y + 18
            sharedValue5.frame.Position = UDim2.fromOffset(value4, value2)
        end)
    end
    local function hideTip()
        sharedValue5.target = nil
        if sharedValue5.frame then
            sharedValue5.frame.Visible = false
        end
    end
    local sharedValue6 = {}
    context.tipTextOf = function(argument)
        return sharedValue6[argument]
    end
    local function tip(target, text)
        if not text or text == "" then
            return target
        end
        sharedValue6[target] = text
        local function helper()
            sharedValue6[target] = nil
        end
        target.Destroying:Connect(helper)
        local function helper2()
            if not sharedValue5.frame then
                return
            end
            sharedValue5.target = target
            sharedValue5.showAt = os.clock() + 0.45
            sharedValue5.frame.Visible = false
            sharedValue5.label.Text = text
        end
        target.MouseEnter:Connect(helper2)
        local function helper3()
            if sharedValue5.target == target then
                hideTip()
            end
        end
        target.MouseLeave:Connect(helper3)
        local function helper4()
            local value = game
            if not (target:IsDescendantOf(value)) then
                if sharedValue5.target == target then
                    hideTip()
                end
            end
        end
        target.AncestryChanged:Connect(helper4)
        return target
    end
    local sharedValue7 = {
        plus = 10734924532,
        x = 10747384394,
        pin = 10734922324,
        info = 10723415903,
        check = 10709790644,
        ["chevron-down"] = 10709790948,
        ["chevron-up"] = 10709791523,
        ["chevron-left"] = 10709791281,
        ["chevron-right"] = 10709791437,
        crown = 10709818626,
        ["trash-2"] = 10747362241,
        swords = 10734975692,
        eye = 10723346959,
        bell = 10709775704,
        coins = 10709811110,
        users = 10747373426,
        palette = 10734910430,
        map = 10734886202,
        camera = 10709789686,
        bug = 10709782845,
        search = 10734943674,
        ["alert-triangle"] = 10709753149,
        shield = 10734951847,
    }
    local function icon(parent, argument, argument2, argument3, zIndex)
        local image = Instance.new("ImageLabel")
        image.Name = "Icon_" .. tostring(argument)
        image.BackgroundTransparency = 1
        image.BorderSizePixel = 0
        image.Image = "rbxassetid://" .. tostring(sharedValue7[argument] or sharedValue7.info)
        image.ImageColor3 = argument3 or theme.TextSub
        image.ScaleType = Enum.ScaleType.Fit
        image.Size = UDim2.fromOffset(argument2 or 16, argument2 or 16)
        if zIndex then
            image.ZIndex = zIndex
        end
        image.Parent = parent
        return image
    end
    local function chevron(parent)
        local chevron2 = Instance.new("Frame")
        chevron2.Name = "Chevron"
        chevron2.BackgroundTransparency = 1
        chevron2.Size = UDim2.fromOffset(16, 16)
        chevron2.LayoutOrder = 99
        chevron2.Parent = parent
        local value = icon(chevron2, "chevron-down", 16, theme.TextSub)
        value.AnchorPoint, value.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
        return {
            frame = chevron2,
            setOpen = function(argument)
                value.Rotation = argument and 180 or 0
                value.ImageColor3 = argument and theme.AccentMid or theme.TextSub
            end,
        }
    end
    local sharedValue8 = getService("GuiService")
    local function helper5(argument)
        local value = argument
        while value and not (value.GetAttribute and value:GetAttribute("hlWin")) do
            value = value.Parent
        end
        return value
    end
    local function helper6(argument)
        local parent = argument.Parent
        return argument.ZIndex * 100000 + (parent and table.find(parent:GetChildren(), argument) or 0)
    end
    local function helper7(argument)
        if argument then
            if argument.UserInputType == Enum.UserInputType.Touch then
                local vector = sharedValue8:GetGuiInset()
                return argument.Position.X + vector.X, argument.Position.Y + vector.Y
            end
        end
        argument = userInputService:GetMouseLocation()
        return argument.X, argument.Y
    end
    local function helper8(argument, argument2, argument3)
        local value, value2
        for index, child in ipairs(argument3:GetChildren()) do
            if child:IsA("GuiObject") then
                if child.Visible then
                    if child:GetAttribute("hlWin") then
                        local absolutePosition, absoluteSize = child.AbsolutePosition, child.AbsoluteSize
                        if argument >= absolutePosition.X then
                            if argument2 >= absolutePosition.Y then
                                if argument <= absolutePosition.X + absoluteSize.X then
                                    if argument2 <= absolutePosition.Y + absoluteSize.Y then
                                        index = helper6(child)
                                        if value then
                                            if index > value then
                                                value, value2 = index, child
                                            end
                                        else
                                            value, value2 = index, child
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        return value2
    end
    local function pressOnTop(argument, argument2)
        local value = helper5(argument)
        if value then
            if not value.Parent then
                return true
            end
        else
            return true
        end
        local value2, value3 = helper7(argument2)
        argument2 = helper8(value2, value3, value.Parent)
        return argument2 == nil or argument2 == value
    end
    context.pressOnTop = pressOnTop
    local function row(parent, argument, argument2, argument3, argument4)
        local row2 = Instance.new("Frame")
        row2.Name = "Row"
        row2.BackgroundColor3 = theme.SurfaceElement
        row2.BorderSizePixel = 0
        row2.Size = UDim2.new(1, 0, 0, argument3 or theme.RowH)
        row2.LayoutOrder = argument2 or 1
        row2.Parent = parent
        corner(row2, theme.RadiusMd)
        stroke(row2, theme.Hairline, 1)
        pad(row2, 0, theme.GapLg, 0, theme.GapLg)
        argument3, parent = hlist(row2, theme.GapMd), label(row2, argument, "rowLabel", 1)
        parent.Size = UDim2.new(1, 0, 1, 0)
        parent.TextTruncate = Enum.TextTruncate.AtEnd
        flexFill(parent, argument4 or 24)
        return row2, parent, argument3
    end
    local function hoverable(argument, argument2)
        local backgroundColor3 = argument.BackgroundColor3
        local value = getService("TweenService")
        local function helper()
            if pressOnTop(argument) then
                value
                    :Create(
                        argument,
                        TweenInfo.new(0.14, Enum.EasingStyle.Quint),
                        { BackgroundColor3 = theme.SurfaceHover }
                    )
                    :Play()
            end
        end
        argument.MouseEnter:Connect(helper)
        local function helper2()
            value
                :Create(
                    argument,
                    TweenInfo.new(0.2, Enum.EasingStyle.Quint),
                    { BackgroundColor3 = backgroundColor3 }
                )
                :Play()
        end
        argument.MouseLeave:Connect(helper2)
        if not argument2 then
            return nil
        end
        argument.Active = true
        return {
            onClick = function(argument3)
                local function helper3(input)
                    if
                        input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch
                    then
                        if pressOnTop(argument, input) then
                            argument3()
                        end
                    end
                end
                argument.InputBegan:Connect(helper3)
            end,
        }
    end
    local function toggle(argument, argument2, argument3, argument4, argument5, argument6)
        local value = row(argument, argument2, argument5, nil, 46)
        local value2, track = hoverable(value, true), Instance.new("Frame")
        track.Name = "Track"
        track.BackgroundColor3 = theme.SurfaceField
        track.BorderSizePixel = 0
        track.Size = UDim2.fromOffset(38, 20)
        track.LayoutOrder = 2
        track.Parent = value
        corner(track, 10)
        local value3 = stroke(track, theme.Hairline, 1)
        local value4 = accentGradient(track, 0)
        value4.Enabled = false
        local knob = Instance.new("Frame")
        knob.Name = "Knob"
        knob.BackgroundColor3 = theme.TextMuted
        knob.BorderSizePixel = 0
        knob.Size = UDim2.fromOffset(14, 14)
        knob.Position = UDim2.fromOffset(2, 3)
        knob.ZIndex = 2
        corner(knob, 7)
        knob.Parent = track
        local value5 = false
        local function render()
            local enabled = argument3() and true or false
            value4.Enabled = enabled
            track.BackgroundColor3 = enabled and Color3.new(1, 1, 1) or theme.SurfaceField
            value3.Transparency = enabled and 1 or 0
            knob.BackgroundColor3 = enabled and theme.TextOnAccent or theme.TextMuted
            local position = UDim2.fromOffset(enabled and 22 or 2, 3)
            if value5 then
                if knob.Position ~= position then
                    enabled = game
                    if knob:IsDescendantOf(enabled) then
                        getService("TweenService")
                            :Create(
                                knob,
                                TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                                { Position = position }
                            )
                            :Play()
                    else
                        knob.Position = position
                    end
                else
                    knob.Position = position
                end
            else
                knob.Position = position
            end
            value5 = true
        end
        render()
        value2.onClick(function()
            argument4(not argument3())
            render()
        end)
        tip(value, argument6)
        return { row = value, render = render }
    end
    local function helper9(argument, argument2, argument3, argument4)
        if context.COMPACT ~= true then
            return false
        end
        local value, value2 = argument2 - argument, argument3 or (argument4 and 0.1 or 1)
        return value / value2 > 60
    end
    local function helper10(argument, argument2, argument3, argument4, argument5)
        argument = math.clamp(argument, argument2, argument3)
        argument = if argument5
            then math.floor(argument / argument5 + 0.5) * argument5
            else if argument4 then math.floor(argument * 10 + 0.5) / 10 else math.floor(argument + 0.5)
        return math.clamp(argument, argument2, argument3)
    end
    local function helper11(argument, argument2)
        if argument2 then
            return string.format("%.1f", argument)
        end
        return tostring(math.floor(argument + 0.5))
    end
    local function helper12(textControl)
        return tonumber((string.gsub(textControl.Text, "[^%d%.%-]", "")))
    end
    local function helper13(parent, argument, layoutOrder)
        local number = Instance.new("TextBox")
        number.Name = "Number"
        number.BackgroundColor3 = theme.SurfaceField
        number.BorderSizePixel = 0
        number.Size = UDim2.fromOffset(argument, 24)
        number.LayoutOrder = layoutOrder
        number.TextColor3 = theme.TextPrimary
        number.TextSize = 12
        number.ClearTextOnFocus = false
        number.TextXAlignment = Enum.TextXAlignment.Center
        setFont(number, "sans", Enum.FontWeight.SemiBold)
        number.Parent = parent
        corner(number, theme.RadiusSm)
        stroke(number, theme.Hairline, 1)
        return number
    end
    local function helper14(argument, argument2, argument3, argument4)
        local value = label(argument, tostring(argument2 or ""):gsub("^%s+", ""), "captionSub", argument4)
        value.Size = UDim2.fromOffset(argument3, 24)
        value.TextXAlignment = Enum.TextXAlignment.Left
        return value
    end
    local function helper15(
        argument,
        argument2,
        argument3,
        argument4,
        argument5,
        argument6,
        argument7,
        argument8,
        argument9,
        argument10,
        argument11
    )
        local holder = row(argument, argument2, argument9, nil, 136)
        local textControl = helper13(holder, 80, 2)
        helper14(holder, argument3, 40, 3)
        local function render()
            textControl.Text = helper11(tonumber(argument7()) or argument4, argument6)
        end
        local function helper()
            local value = helper12(textControl)
            if value then
                argument8(helper10(value, argument4, argument5, argument6, argument11))
            end
            render()
        end
        textControl.FocusLost:Connect(helper)
        render()
        tip(holder, argument10)
        return { holder = holder, render = render }
    end
    local function helper16(
        argument,
        argument2,
        argument3,
        argument4,
        argument5,
        argument6,
        argument7,
        argument8,
        argument9
    )
        local holder = row(argument, argument2, argument8, nil, 200)
        local textControl = helper13(holder, 58, 2)
        argument2 = label(holder, "to", "captionSub", 3)
        argument2.Size, argument2.TextXAlignment = UDim2.fromOffset(16, 24), Enum.TextXAlignment.Center
        local textControl2 = helper13(holder, 58, 4)
        helper14(holder, argument3, 36, 5)
        local function render()
            local value, value2 = argument6()
            textControl.Text, textControl2.Text =
                helper11(tonumber(value) or argument4), helper11(tonumber(value2) or argument5)
        end
        local function helper()
            local value, value2 = argument6()
            local value3, value4 =
                helper10(helper12(textControl) or tonumber(value) or argument4, argument4, argument5),
                helper10(helper12(textControl2) or tonumber(value2) or argument5, argument4, argument5)
            if value3 > value4 then
                value3, value4 = value4, value3
            end
            argument7(value3, value4)
            render()
        end
        textControl.FocusLost:Connect(helper)
        textControl2.FocusLost:Connect(helper)
        render()
        tip(holder, argument9)
        return { holder = holder, render = render }
    end
    local function slider(
        head,
        argument,
        argument2,
        argument3,
        argument4,
        argument5,
        argument6,
        argument7,
        argument8,
        argument9,
        argument10
    )
        if helper9(argument3, argument4, argument10, argument5) then
            return helper15(
                head,
                argument,
                argument2,
                argument3,
                argument4,
                argument5,
                argument6,
                argument7,
                argument8,
                argument9,
                argument10
            )
        end
        local slider2 = Instance.new("Frame")
        slider2.Name = "Slider"
        slider2.BackgroundTransparency = 0
        slider2.BackgroundColor3 = theme.SurfaceElement
        slider2.BorderSizePixel = 0
        slider2.AutomaticSize = Enum.AutomaticSize.Y
        slider2.Size = UDim2.new(1, 0, 0, 0)
        slider2.LayoutOrder = argument8 or 1
        slider2.Parent = head
        corner(slider2, theme.RadiusMd)
        stroke(slider2, theme.Hairline, 1)
        pad(slider2, 7, 12, 9, 12)
        vlist(slider2, theme.GapSm)
        head = Instance.new("Frame")
        head.Name = "Head"
        head.BackgroundTransparency = 1
        head.AutomaticSize = Enum.AutomaticSize.Y
        head.Size = UDim2.new(1, 0, 0, 0)
        head.LayoutOrder = 1
        head.Parent = slider2
        vlist(head, 1)
        label(head, argument, "rowLabel", 1).Size = UDim2.new(1, 0, 0, 18)
        if argument2 then
            if argument2 ~= "" then
                label(head, argument2, "captionSub", 2).Size = UDim2.new(1, 0, 0, 12)
            end
        end
        local track = Instance.new("Frame")
        track.Name = "Track"
        track.BackgroundColor3 = theme.SurfaceField
        track.BorderSizePixel = 0
        track.Size = UDim2.new(1, 0, 0, 18)
        track.ClipsDescendants = true
        track.LayoutOrder = 2
        track.Active = true
        track.Parent = slider2
        corner(track, theme.RadiusSm)
        stroke(track, theme.Hairline, 1)
        local fill = Instance.new("Frame")
        fill.Name = "Fill"
        fill.BackgroundColor3 = Color3.new(1, 1, 1)
        fill.BorderSizePixel = 0
        fill.Size = UDim2.fromScale(0, 1)
        fill.Parent = track
        corner(fill, theme.RadiusSm)
        accentGradient(fill, 0)
        local value = Instance.new("TextLabel")
        value.Name = "Value"
        value.BackgroundTransparency = 1
        value.Size = UDim2.new(1, -8, 1, 0)
        value.Position = UDim2.fromOffset(0, 0)
        value.TextXAlignment = Enum.TextXAlignment.Right
        value.TextColor3 = theme.TextOnAccent
        value.TextSize = 11
        value.ZIndex = 3
        setFont(value, "mono", Enum.FontWeight.Medium)
        value.Parent = fill
        local function helper(argument11)
            if argument10 then
                return (string.format("%.3f", argument11):gsub("0+$", ""):gsub("%.$", ""))
            end
            if argument5 then
                return string.format("%.1f", argument11)
            end
            return tostring(math.floor(argument11 + 0.5))
        end
        local function render()
            local value2 = argument6()
            local value3 = math.clamp((value2 - argument3) / (argument4 - argument3), 0, 1)
            fill.Size = UDim2.fromScale(value3, 1)
            value.Text = helper(value2)
            if value3 < 0.22 then
                value.Parent = track
                value.Size = UDim2.new(1, -8, 1, 0)
                value.TextColor3 = theme.TextPrimary
            else
                value.Parent = fill
                value.Size = UDim2.new(1, -8, 1, 0)
                value.TextColor3 = theme.TextOnAccent
            end
        end
        render()
        local value4 = false
        local function helper2(argument11)
            if track.AbsoluteSize.X <= 0 then
                return
            end
            local value2 = math.clamp((argument11 - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            argument11 = argument3 + (argument4 - argument3) * value2
            argument7(
                if argument10
                    then math.floor(argument11 / argument10 + 0.5) * argument10
                    else if argument5
                        then math.floor(argument11 * 10 + 0.5) / 10
                        else math.floor(argument11 + 0.5)
            )
            render()
        end
        track.InputBegan:Connect(function(input)
            if not (pressOnTop(track, input)) then
                return
            end
            if
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            then
                value4 = true
                helper2(input.Position.X)
            end
        end)
        table.insert(
            context.sliderConnections,
            userInputService.InputChanged:Connect(function(input)
                local value2 = value4
                    and (
                        input.UserInputType == Enum.UserInputType.MouseMovement
                        or input.UserInputType == Enum.UserInputType.Touch
                    )
                if value2 then
                    helper2(input.Position.X)
                end
            end)
        )
        table.insert(
            context.sliderConnections,
            userInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    value4 = false
                elseif input.UserInputType == Enum.UserInputType.Touch then
                    value4 = false
                end
            end)
        )
        tip(slider2, argument9)
        return { holder = slider2, render = render }
    end
    local function rangeSlider(
        top,
        argument,
        argument2,
        argument3,
        argument4,
        argument5,
        argument6,
        head,
        argument7,
        argument8
    )
        if helper9(argument3, argument4, nil, false) then
            return helper16(
                top,
                argument,
                argument8,
                argument3,
                argument4,
                argument5,
                argument6,
                head,
                argument7
            )
        end
        local rangeSlider2 = Instance.new("Frame")
        rangeSlider2.Name = "RangeSlider"
        rangeSlider2.BackgroundTransparency = 0
        rangeSlider2.BackgroundColor3 = theme.SurfaceElement
        rangeSlider2.BorderSizePixel = 0
        rangeSlider2.AutomaticSize = Enum.AutomaticSize.Y
        rangeSlider2.Size = UDim2.new(1, 0, 0, 0)
        rangeSlider2.LayoutOrder = head or 1
        rangeSlider2.Parent = top
        corner(rangeSlider2, theme.RadiusMd)
        stroke(rangeSlider2, theme.Hairline, 1)
        pad(rangeSlider2, 7, 12, 9, 12)
        vlist(rangeSlider2, theme.GapSm)
        head = Instance.new("Frame")
        head.Name = "Head"
        head.BackgroundTransparency = 1
        head.AutomaticSize = Enum.AutomaticSize.Y
        head.Size = UDim2.new(1, 0, 0, 0)
        head.LayoutOrder = 1
        head.Parent = rangeSlider2
        vlist(head, 1)
        top = Instance.new("Frame")
        top.Name = "Top"
        top.BackgroundTransparency = 1
        top.Size = UDim2.new(1, 0, 0, 18)
        top.LayoutOrder = 1
        top.Parent = head
        label(top, argument, "rowLabel", 1).Size = UDim2.new(1, -96, 1, 0)
        local textControl = label(top, "", "captionKey", 2)
        textControl.Size = UDim2.new(0, 96, 1, 0)
        textControl.Position = UDim2.new(1, -96, 0, 0)
        textControl.TextXAlignment = Enum.TextXAlignment.Right
        if argument2 then
            if argument2 ~= "" then
                label(head, argument2, "captionSub", 2).Size = UDim2.new(1, 0, 0, 12)
            end
        end
        local track = Instance.new("Frame")
        track.Name = "Track"
        track.BackgroundColor3 = theme.SurfaceField
        track.BorderSizePixel = 0
        track.Size = UDim2.new(1, 0, 0, 18)
        track.ClipsDescendants = false
        track.LayoutOrder = 2
        track.Active = true
        track.Parent = rangeSlider2
        corner(track, theme.RadiusSm)
        stroke(track, theme.Hairline, 1)
        local fill = Instance.new("Frame")
        fill.Name = "Fill"
        fill.BackgroundColor3 = Color3.new(1, 1, 1)
        fill.BorderSizePixel = 0
        fill.Size = UDim2.fromScale(0, 1)
        fill.Parent = track
        corner(fill, theme.RadiusSm)
        accentGradient(fill, 0)
        local function helper(name2)
            local frame = Instance.new("Frame")
            frame.Name = name2
            frame.AnchorPoint = Vector2.new(0.5, 0.5)
            frame.BackgroundColor3 = theme.TextPrimary
            frame.BorderSizePixel = 0
            frame.Size = UDim2.fromOffset(8, 22)
            frame.ZIndex = 3
            frame.Parent = track
            corner(frame, 3)
            stroke(frame, theme.Hairline, 1)
            return frame
        end
        local value = helper("Low")
        local value2 = helper("High")
        local value3 = math.max(argument4 - argument3, 1)
        local value4 = argument8 and argument8 ~= "" and " " .. argument8 or ""
        local function helper2()
            local value5, value6 = argument5()
            value5, value6 =
                math.clamp(math.floor((tonumber(value5) or argument3) + 0.5), argument3, argument4),
                math.clamp(math.floor((tonumber(value6) or argument4) + 0.5), argument3, argument4)
            if value6 < value5 then
                value5, value6 = value6, value5
            end
            return value5, value6
        end
        local function render()
            local value5, value6 = helper2()
            local value7, value8 = (value5 - argument3) / value3, (value6 - argument3) / value3
            fill.Position = UDim2.fromScale(value7, 0)
            fill.Size = UDim2.fromScale(value8 - value7, 1)
            value.Position = UDim2.fromScale(value7, 0.5)
            value2.Position = UDim2.fromScale(value8, 0.5)
            textControl.Text = value5 == value6 and tostring(value5) .. value4
                or ("%d - %d"):format(value5, value6) .. value4
        end
        render()
        local value9
        local function helper3(argument9)
            local value5 = math.clamp((argument9 - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            return math.floor(argument3 + (argument4 - argument3) * value5 + 0.5)
        end
        local function helper4(argument9)
            if value9 then
                if track.AbsoluteSize.X <= 0 then
                    return
                end
            else
                return
            end
            local value5, value6, value7 = helper3(argument9), helper2()
            if value9 == "both" then
                if value5 > value7 then
                    value9 = "hi"
                elseif value5 < value6 then
                    value9 = "lo"
                else
                    return
                end
            end
            if value9 == "lo" then
                value6 = math.min(value5, value7)
            else
                value7 = math.max(value5, value6)
            end
            argument6(value6, value7)
            render()
        end
        track.InputBegan:Connect(function(input)
            if not (pressOnTop(track, input)) then
                return
            end
            if
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            then
                if track.AbsoluteSize.X <= 0 then
                    return
                end
                local value5, value6, value7 = helper3(input.Position.X), helper2()
                value9 = if value6 == value7 and value5 == value6
                    then "both"
                    else if value5 <= value6
                        then "lo"
                        else if value5 >= value7
                            then "hi"
                            else value5 - value6 <= value7 - value5 and "lo" or "hi"
                helper4(input.Position.X)
            end
        end)
        table.insert(
            context.sliderConnections,
            userInputService.InputChanged:Connect(function(input)
                local value5 = value9
                    and (
                        input.UserInputType == Enum.UserInputType.MouseMovement
                        or input.UserInputType == Enum.UserInputType.Touch
                    )
                if value5 then
                    helper4(input.Position.X)
                end
            end)
        )
        table.insert(
            context.sliderConnections,
            userInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    value9 = nil
                elseif input.UserInputType == Enum.UserInputType.Touch then
                    value9 = nil
                end
            end)
        )
        tip(rangeSlider2, argument7)
        return { holder = rangeSlider2, render = render }
    end
    local function listInput(
        parent,
        argument,
        argument2,
        argument3,
        argument4,
        head,
        argument5,
        argument6,
        argument7
    )
        local value, value2, value3 = 26, 4, 4
        local value4 = argument7 or 5
        local listInput2 = Instance.new("Frame")
        listInput2.Name = "ListInput"
        listInput2.BackgroundTransparency = 1
        listInput2.AutomaticSize = Enum.AutomaticSize.Y
        listInput2.Size = UDim2.new(1, 0, 0, 0)
        listInput2.LayoutOrder = head or 1
        listInput2.Parent = parent
        vlist(listInput2, theme.GapSm)
        head = Instance.new("Frame")
        head.Name = "Head"
        head.BackgroundTransparency = 1
        head.AutomaticSize = Enum.AutomaticSize.Y
        head.Size = UDim2.new(1, 0, 0, 0)
        head.LayoutOrder = 1
        head.Parent = listInput2
        vlist(head, 1)
        label(head, argument, "rowLabel", 1).Size = UDim2.new(1, 0, 0, 18)
        if argument2 then
            if argument2 ~= "" then
                label(head, argument2, "captionSub", 2).Size = UDim2.new(1, 0, 0, 12)
            end
        end
        local list = Instance.new("ScrollingFrame")
        list.Name = "List"
        list.BackgroundColor3 = theme.SurfaceField
        list.BorderSizePixel = 0
        list.LayoutOrder = 2
        list.Size = UDim2.new(1, 0, 0, 34)
        list.CanvasSize = UDim2.new()
        list.AutomaticCanvasSize = Enum.AutomaticSize.Y
        list.ScrollingDirection = Enum.ScrollingDirection.Y
        list.ScrollBarThickness = 4
        list.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 95)
        list.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
        list.Parent = listInput2
        corner(list, theme.RadiusMd)
        stroke(list, theme.Hairline, 1)
        pad(list, value3, value3, value3, value3)
        vlist(list, value2)
        local value5, value6 = {}, false
        local function helper(argument8)
            return (tostring(argument8 or ""):gsub("^%s+", ""):gsub("%s+$", ""))
        end
        local function helper2()
            local value7 = math.clamp(#value5, 1, value4)
            list.Size = UDim2.new(1, 0, 0, value3 * 2 + value7 * value + (value7 - 1) * value2)
        end
        local function helper3()
            if value6 then
                return
            end
            local value7 = {}
            for index, entry in ipairs(value5) do
                index = helper(entry.Text)
                if index ~= "" then
                    value7[#value7 + 1] = index
                end
            end
            argument4(value7)
        end
        local function toBottom()
            task.defer(function()
                if list.Parent then
                    list.CanvasPosition =
                        Vector2.new(0, math.max(0, list.AbsoluteCanvasSize.Y - list.AbsoluteWindowSize.Y))
                end
            end)
        end
        local helper4
        local function helper17()
            for index = #value5 - 1, 1, -1 do
                local textControl = value5[index]
                if helper(textControl.Text) == "" then
                    table.remove(value5, index)
                    textControl:Destroy()
                end
            end
            if #value5 == 0 then
                helper4("")
            elseif helper(value5[#value5].Text) ~= "" then
                helper4("")
            end
            for index2, entry in ipairs(value5) do
                entry.LayoutOrder = index2
            end
            helper2()
        end
        helper4 = function(argument8)
            local entry = Instance.new("TextBox")
            entry.Name = "Entry"
            entry.BackgroundColor3 = theme.SurfaceElement
            entry.BorderSizePixel = 0
            entry.Size = UDim2.new(1, 0, 0, value)
            entry.LayoutOrder = #value5 + 1
            entry.Text = argument8 or ""
            entry.PlaceholderText = argument6 or "Add a name"
            entry.PlaceholderColor3 = theme.TextMuted
            entry.TextColor3 = theme.TextPrimary
            entry.TextSize = 12
            entry.ClearTextOnFocus = false
            entry.TextXAlignment = Enum.TextXAlignment.Left
            entry.TextTruncate = Enum.TextTruncate.AtEnd
            setFont(entry, "sans", Enum.FontWeight.Medium)
            entry.Parent = list
            corner(entry, theme.RadiusSm)
            stroke(entry, theme.Hairline, 1)
            pad(entry, 0, 8, 0, 8)
            value5[#value5 + 1] = entry
            entry:GetPropertyChangedSignal("Text"):Connect(function()
                if value6 then
                    return
                end
                if value5[#value5] == entry then
                    if helper(entry.Text) ~= "" then
                        helper4("")
                        helper2()
                        toBottom()
                    end
                end
                helper3()
            end)
            entry.FocusLost:Connect(function()
                if value6 then
                    return
                end
                helper17()
                helper3()
            end)
            return entry
        end
        local function render()
            value6 = true
            for index, entry in ipairs(value5) do
                entry:Destroy()
            end
            table.clear(value5)
            local value7 = argument3()
            if type(value7) == "table" then
                for index2, entry2 in ipairs(value7) do
                    index2 = helper(entry2)
                    if index2 ~= "" then
                        helper4(index2)
                    end
                end
            end
            helper4("")
            value6 = false
            helper2()
        end
        render()
        tip(listInput2, argument5)
        return { holder = listInput2, render = render, toBottom = toBottom }
    end
    local function dropdown(
        parent,
        fillDirectionMaxCells,
        argument,
        argument2,
        argument3,
        argument4,
        argument5
    )
        local dropdown2 = Instance.new("Frame")
        dropdown2.Name = "Dropdown"
        dropdown2.BackgroundTransparency = 1
        dropdown2.AutomaticSize = Enum.AutomaticSize.Y
        dropdown2.Size = UDim2.new(1, 0, 0, 0)
        dropdown2.LayoutOrder = argument4 or 1
        dropdown2.Parent = parent
        vlist(dropdown2, 4)
        argument4 = row(dropdown2, fillDirectionMaxCells, 1, nil, 150)
        local value, textControl = hoverable(argument4, true), label(argument4, "", "captionKey", 2)
        textControl.Size = UDim2.fromOffset(118, 18)
        textControl.AutomaticSize = Enum.AutomaticSize.None
        textControl.TextTruncate = Enum.TextTruncate.AtEnd
        textControl.TextXAlignment = Enum.TextXAlignment.Right
        local value2 = chevron(argument4)
        local menu = Instance.new("Frame")
        menu.Name = "Menu"
        menu.BackgroundColor3 = theme.SurfaceField
        menu.BorderSizePixel = 0
        menu.AutomaticSize = Enum.AutomaticSize.Y
        menu.Size = UDim2.new(1, 0, 0, 0)
        menu.Visible = false
        menu.LayoutOrder = 2
        menu.Parent = dropdown2
        corner(menu, theme.RadiusMd)
        stroke(menu, theme.Hairline, 1)
        pad(menu, 4, 4, 4, 4)
        local value3, value4
        if #argument > 6 then
            fillDirectionMaxCells = #argument > 10 and 3 or 2
            value3 = Instance.new("UIGridLayout")
            value3.CellSize = UDim2.new(
                1 / fillDirectionMaxCells,
                -math.ceil(2 * (fillDirectionMaxCells - 1) / fillDirectionMaxCells) - 1,
                0,
                26
            )
            value3.CellPadding, value3.FillDirectionMaxCells, value3.SortOrder =
                UDim2.fromOffset(2, 2), fillDirectionMaxCells, Enum.SortOrder.LayoutOrder
            value3.Parent = menu
            value4 = value3
        else
            value3 = vlist(menu, 2)
            value4 = value3
        end
        local value5 = false
        local function helper(visible)
            value5 = visible
            value2.setOpen(visible)
            if context.Shell then
                if context.Shell.slideTo then
                    if context.Shell.isShown then
                        if context.Shell.isShown() then
                            context.Shell.slideTo(menu, value4, 8, visible)
                        else
                            menu.Visible = visible
                        end
                    else
                        menu.Visible = visible
                    end
                else
                    menu.Visible = visible
                end
            else
                menu.Visible = visible
            end
        end
        local value6 = {}
        local function render()
            local value7 = argument2()
            textControl.Text = tostring(value7)
            for key, entry in pairs(value6) do
                local value8 = key == value7
                entry.BackgroundColor3 = value8 and theme.SurfaceHover or theme.SurfaceElement
                entry.TextColor3 = value8 and theme.AccentMid or theme.TextSub
            end
        end
        for index, entry2 in ipairs(argument) do
            parent = Instance.new("TextButton")
            parent.Name = tostring(entry2.value)
            parent.BackgroundColor3 = theme.SurfaceElement
            parent.BorderSizePixel = 0
            parent.Size = UDim2.new(1, 0, 0, 26)
            parent.Text = entry2.label or tostring(entry2.value)
            parent.TextColor3 = theme.TextSub
            parent.TextSize = 12
            parent.LayoutOrder = index
            setFont(parent, "sans", Enum.FontWeight.Medium)
            parent.Parent = menu
            corner(parent, 4)
            local function helper2()
                argument3(entry2.value)
                helper(false)
                render()
            end
            parent.MouseButton1Click:Connect(helper2)
            value6[entry2.value] = parent
        end
        render()
        value.onClick(function()
            helper(not value5)
        end)
        render()
        tip(argument4, argument5)
        return { holder = dropdown2, render = render }
    end
    local function multiDropdown(parent, title, list, getSet, onToggle, order, tipText)
        local frame = Instance.new("Frame")
        frame.Name = "MultiDropdown"
        frame.BackgroundTransparency = 1
        frame.AutomaticSize = Enum.AutomaticSize.Y
        frame.Size = UDim2.new(1, 0, 0, 0)
        frame.LayoutOrder = order or 1
        frame.Parent = parent
        vlist(frame, 4)
        local head = row(frame, title, 1, nil, 150)
        local hov, shown = hoverable(head, true), label(head, "", "captionKey", 2)
        shown.Size = UDim2.fromOffset(118, 18)
        shown.AutomaticSize = Enum.AutomaticSize.None
        shown.TextTruncate = Enum.TextTruncate.AtEnd
        shown.TextXAlignment = Enum.TextXAlignment.Right
        local chev = chevron(head)
        local menu = Instance.new("Frame")
        menu.Name = "Menu"
        menu.BackgroundColor3 = theme.SurfaceField
        menu.BorderSizePixel = 0
        menu.AutomaticSize = Enum.AutomaticSize.Y
        menu.Size = UDim2.new(1, 0, 0, 0)
        menu.Visible = false
        menu.LayoutOrder = 2
        menu.Parent = frame
        corner(menu, theme.RadiusMd)
        stroke(menu, theme.Hairline, 1)
        pad(menu, 4, 4, 4, 4)
        local cells = #list > 10 and 3 or 2
        local grid = Instance.new("UIGridLayout")
        grid.CellSize = UDim2.new(1 / cells, -math.ceil(2 * (cells - 1) / cells) - 1, 0, 26)
        grid.CellPadding, grid.FillDirectionMaxCells, grid.SortOrder =
            UDim2.fromOffset(2, 2), cells, Enum.SortOrder.LayoutOrder
        grid.Parent = menu
        local open = false
        local function setOpen(visible)
            open = visible
            chev.setOpen(visible)
            if context.Shell and context.Shell.slideTo and context.Shell.isShown and context.Shell.isShown() then
                context.Shell.slideTo(menu, grid, 8, visible)
            else
                menu.Visible = visible
            end
        end
        local buttons = {}
        local function render()
            local set = getSet() or {}
            local n = 0
            for _, name in ipairs(list) do
                if set[name] then n = n + 1 end
            end
            shown.Text = n .. " selected"
            for name, b in pairs(buttons) do
                local on = set[name] == true
                b.BackgroundColor3 = on and theme.SurfaceHover or theme.SurfaceElement
                b.TextColor3 = on and theme.AccentMid or theme.TextSub
            end
        end
        for index, name in ipairs(list) do
            local b = Instance.new("TextButton")
            b.Name = tostring(name)
            b.BackgroundColor3 = theme.SurfaceElement
            b.BorderSizePixel = 0
            b.Size = UDim2.new(1, 0, 0, 26)
            b.Text = tostring(name)
            b.TextColor3 = theme.TextSub
            b.TextSize = 12
            b.LayoutOrder = index
            setFont(b, "sans", Enum.FontWeight.Medium)
            b.Parent = menu
            corner(b, 4)
            b.MouseButton1Click:Connect(function()
                pcall(onToggle, name)
                render() -- the menu stays open so you can tick more
            end)
            buttons[name] = b
        end
        render()
        hov.onClick(function() setOpen(not open) end)
        tip(head, tipText)
        return { holder = frame, render = render }
    end
    local function colorRow(parent, shade, argument, argument2, parent2, argument3)
        local color = Instance.new("Frame")
        color.Name = "Color"
        color.BackgroundTransparency = 1
        color.AutomaticSize = Enum.AutomaticSize.Y
        color.Size = UDim2.new(1, 0, 0, 0)
        color.LayoutOrder = parent2 or 1
        color.Parent = parent
        vlist(color, theme.GapSm)
        parent2 = row(color, shade, 1, nil, 54)
        local value, swatch = hoverable(parent2, true), Instance.new("Frame")
        swatch.Name = "Swatch"
        swatch:SetAttribute("HLThemeSkipTree", true)
        swatch.BackgroundColor3 = argument()
        swatch.BorderSizePixel = 0
        swatch.Size = UDim2.fromOffset(46, 20)
        swatch.LayoutOrder = 2
        swatch.Parent = parent2
        corner(swatch, theme.RadiusSm)
        stroke(swatch, theme.Hairline, 1)
        local picker = Instance.new("Frame")
        picker.Name = "Picker"
        picker:SetAttribute("HLThemeSkipTree", true)
        picker.BackgroundTransparency = 1
        picker.Size = UDim2.new(1, 0, 0, 140)
        picker.Visible = false
        picker.LayoutOrder = 2
        picker.Parent = color
        hlist(picker, theme.GapMd)
        local parent3 = Instance.new("Frame")
        parent3.Name = "SV"
        parent3.BackgroundColor3 = Color3.new(1, 1, 1)
        parent3.BorderSizePixel = 0
        parent3.Size = UDim2.new(1, -22, 1, 0)
        parent3.Active = true
        parent3.LayoutOrder = 1
        parent3.Parent = picker
        corner(parent3, theme.RadiusMd)
        flexFill(parent3, 22)
        local gradient = Instance.new("UIGradient")
        gradient.Rotation = 0
        gradient.Parent = parent3
        shade = Instance.new("Frame")
        shade.Name = "Shade"
        shade.BackgroundColor3 = Color3.new(0, 0, 0)
        shade.BorderSizePixel = 0
        shade.Size = UDim2.fromScale(1, 1)
        shade.Parent = parent3
        corner(shade, theme.RadiusMd)
        parent = Instance.new("UIGradient")
        parent.Rotation = 90
        parent.Transparency =
            NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
        parent.Parent = shade
        local cursor = Instance.new("Frame")
        cursor.Name = "Cursor"
        cursor.BackgroundTransparency = 1
        cursor.AnchorPoint = Vector2.new(0.5, 0.5)
        cursor.Size = UDim2.fromOffset(12, 12)
        cursor.ZIndex = 4
        cursor.Parent = parent3
        corner(cursor, 6)
        stroke(cursor, Color3.new(1, 1, 1), 2)
        local hue = Instance.new("Frame")
        hue.Name = "Hue"
        hue.BackgroundColor3 = Color3.new(1, 1, 1)
        hue.BorderSizePixel = 0
        hue.Size = UDim2.new(0, 14, 1, 0)
        hue.Active = true
        hue.LayoutOrder = 2
        hue.Parent = picker
        corner(hue, theme.RadiusSm)
        parent = Instance.new("UIGradient")
        parent.Rotation = 90
        parent.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
        })
        parent.Parent = hue
        local marker = Instance.new("Frame")
        marker.Name = "Marker"
        marker.BackgroundColor3 = Color3.new(1, 1, 1)
        marker.BorderSizePixel = 0
        marker.AnchorPoint = Vector2.new(0.5, 0.5)
        marker.Size = UDim2.fromOffset(20, 3)
        marker.Position = UDim2.new(0.5, 0, 0, 0)
        marker.ZIndex = 4
        corner(marker, 2)
        marker.Parent = hue
        local value2, value3, value4 = argument():ToHSV()
        local function render()
            local backgroundColor3 = Color3.fromHSV(value2, value3, value4)
            swatch.BackgroundColor3 = backgroundColor3
            gradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromHSV(value2, 1, 1))
            cursor.Position = UDim2.fromScale(value3, 1 - value4)
            marker.Position = UDim2.new(0.5, 0, value2, 0)
            argument2(backgroundColor3)
        end
        render()
        local value5, value6 = false, false
        local function helper(argument4, argument5)
            if parent3.AbsoluteSize.X <= 0 then
                return
            end
            value3 = math.clamp((argument4 - parent3.AbsolutePosition.X) / parent3.AbsoluteSize.X, 0, 1)
            value4 = 1 - math.clamp((argument5 - parent3.AbsolutePosition.Y) / parent3.AbsoluteSize.Y, 0, 1)
            render()
        end
        local function helper2(argument4)
            if hue.AbsoluteSize.Y <= 0 then
                return
            end
            value2 = math.clamp((argument4 - hue.AbsolutePosition.Y) / hue.AbsoluteSize.Y, 0, 1)
            render()
        end
        parent3.InputBegan:Connect(function(input)
            if not (pressOnTop(parent3, input)) then
                return
            end
            if
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            then
                value5 = true
                helper(input.Position.X, input.Position.Y)
            end
        end)
        hue.InputBegan:Connect(function(input)
            if not (pressOnTop(hue, input)) then
                return
            end
            if
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            then
                value6 = true
                helper2(input.Position.Y)
            end
        end)
        table.insert(
            context.sliderConnections,
            userInputService.InputChanged:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.MouseMovement then
                    if input.UserInputType ~= Enum.UserInputType.Touch then
                        return
                    end
                end
                if value5 then
                    helper(input.Position.X, input.Position.Y)
                end
                if value6 then
                    helper2(input.Position.Y)
                end
            end)
        )
        table.insert(
            context.sliderConnections,
            userInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    value5, value6 = false, false
                elseif input.UserInputType == Enum.UserInputType.Touch then
                    value5, value6 = false, false
                end
            end)
        )
        value.onClick(function()
            picker.Visible = not picker.Visible
        end)
        tip(parent2, argument3)
        return { holder = color, render = render }
    end
    local function colorWheel(parent, gradient, argument, argument2, argument3, argument4)
        local colorWheel2 = Instance.new("Frame")
        colorWheel2.Name = "ColorWheel"
        colorWheel2.BackgroundTransparency = 1
        colorWheel2.AutomaticSize = Enum.AutomaticSize.Y
        colorWheel2.Size = UDim2.new(1, 0, 0, 0)
        colorWheel2.LayoutOrder = argument3 or 1
        colorWheel2.Parent = parent
        vlist(colorWheel2, theme.GapSm)
        parent = row(colorWheel2, gradient, 1, nil, 54)
        local value, swatch = hoverable(parent, true), Instance.new("Frame")
        swatch.Name = "Swatch"
        swatch:SetAttribute("HLThemeSkipTree", true)
        swatch.BorderSizePixel = 0
        swatch.Size = UDim2.fromOffset(46, 20)
        swatch.LayoutOrder = 2
        swatch.Parent = parent
        corner(swatch, theme.RadiusSm)
        stroke(swatch, theme.Hairline, 1)
        local picker = Instance.new("Frame")
        picker.Name = "Picker"
        picker:SetAttribute("HLThemeSkipTree", true)
        picker.BackgroundTransparency = 1
        picker.Size = UDim2.new(1, 0, 0, 180)
        picker.Visible = false
        picker.LayoutOrder = 2
        picker.Parent = colorWheel2
        local wheel = Instance.new("Frame")
        wheel.Name = "Wheel"
        wheel.BackgroundTransparency = 1
        wheel.AnchorPoint = Vector2.new(0.5, 0)
        wheel.Position = UDim2.new(0.5, 0, 0, 0)
        wheel.Size = UDim2.fromOffset(150, 150)
        wheel.Active = true
        wheel.Parent = picker
        for index = 0, 35, 1 do
            argument3 = Instance.new("Frame")
            argument3.Name = "Spoke"
            argument3.BorderSizePixel = 0
            argument3.BackgroundColor3 = Color3.new(1, 1, 1)
            argument3.AnchorPoint = Vector2.new(0.5, 0.5)
            argument3.Position = UDim2.fromScale(0.5, 0.5)
            argument3.Size = UDim2.fromOffset(150, 10)
            argument3.Rotation = index * 360 / 72
            gradient = Instance.new("UIGradient")
            gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromHSV((index + 36) % 72 / 72, 1, 1)),
                ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromHSV(index / 72, 1, 1)),
            })
            gradient.Parent = argument3
            argument3.Parent = wheel
        end
        local shade = Instance.new("Frame")
        shade.Name = "Shade"
        shade.BorderSizePixel = 0
        shade.BackgroundColor3 = Color3.new(0, 0, 0)
        shade.Size = UDim2.fromScale(1, 1)
        shade.ZIndex = 3
        shade.Parent = wheel
        corner(shade, 150)
        argument3 = Instance.new("Frame")
        argument3.Name = "Rim"
        argument3.BackgroundTransparency = 1
        argument3.Size = UDim2.fromScale(1, 1)
        argument3.ZIndex = 4
        argument3.Parent = wheel
        corner(argument3, 150)
        stroke(argument3, theme.Hairline, 2)
        local cursor = Instance.new("Frame")
        cursor.Name = "Cursor"
        cursor.BackgroundTransparency = 1
        cursor.AnchorPoint = Vector2.new(0.5, 0.5)
        cursor.Size = UDim2.fromOffset(12, 12)
        cursor.ZIndex = 5
        cursor.Parent = wheel
        corner(cursor, 6)
        stroke(cursor, Color3.new(1, 1, 1), 2)
        local brightness = Instance.new("Frame")
        brightness.Name = "Brightness"
        brightness.BorderSizePixel = 0
        brightness.BackgroundColor3 = Color3.new(1, 1, 1)
        brightness.AnchorPoint = Vector2.new(0.5, 0)
        brightness.Position = UDim2.new(0.5, 0, 0, 162)
        brightness.Size = UDim2.fromOffset(150, 12)
        brightness.Active = true
        brightness.Parent = picker
        corner(brightness, theme.RadiusSm)
        stroke(brightness, theme.Hairline, 1)
        local gradient2 = Instance.new("UIGradient")
        gradient2.Parent = brightness
        local marker = Instance.new("Frame")
        marker.Name = "Marker"
        marker.BackgroundColor3 = Color3.new(1, 1, 1)
        marker.BorderSizePixel = 0
        marker.AnchorPoint = Vector2.new(0.5, 0.5)
        marker.Size = UDim2.fromOffset(4, 18)
        marker.ZIndex = 4
        marker.Parent = brightness
        corner(marker, 2)
        local value2, value3, backgroundTransparency = argument():ToHSV()
        local function helper()
            local backgroundColor3 = Color3.fromHSV(value2, value3, backgroundTransparency)
            swatch.BackgroundColor3 = backgroundColor3
            shade.BackgroundTransparency = backgroundTransparency
            local value4 = value2 * 2 * 3.141592653589793
            cursor.Position =
                UDim2.fromScale(0.5 + math.cos(value4) * value3 * 0.5, 0.5 + math.sin(value4) * value3 * 0.5)
            gradient2.Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.fromHSV(value2, value3, 1))
            marker.Position = UDim2.new(backgroundTransparency, 0, 0.5, 0)
            return backgroundColor3
        end
        local function helper2()
            argument2(helper())
        end
        local function render()
            value2, value3, backgroundTransparency = argument():ToHSV()
            helper()
        end
        render()
        local value5, value6 = false, false
        local function helper3(argument5, argument6)
            local absoluteSize = wheel.AbsoluteSize
            if absoluteSize.X <= 0 then
                return
            end
            local vector = wheel.AbsolutePosition + absoluteSize * 0.5
            local value4, value7 = argument5 - vector.X, argument6 - vector.Y
            value2 = math.atan2(value7, value4) / 6.283185307179586 % 1
            value3 = math.clamp(math.sqrt(value4 * value4 + value7 * value7) / (absoluteSize.X * 0.5), 0, 1)
            helper2()
        end
        local function helper4(argument5)
            if brightness.AbsoluteSize.X <= 0 then
                return
            end
            backgroundTransparency =
                math.clamp((argument5 - brightness.AbsolutePosition.X) / brightness.AbsoluteSize.X, 0, 1)
            helper2()
        end
        wheel.InputBegan:Connect(function(input)
            if not (pressOnTop(wheel, input)) then
                return
            end
            if
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            then
                value5 = true
                helper3(input.Position.X, input.Position.Y)
            end
        end)
        brightness.InputBegan:Connect(function(input)
            if not (pressOnTop(brightness, input)) then
                return
            end
            if
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            then
                value6 = true
                helper4(input.Position.X)
            end
        end)
        table.insert(
            context.sliderConnections,
            userInputService.InputChanged:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.MouseMovement then
                    if input.UserInputType ~= Enum.UserInputType.Touch then
                        return
                    end
                end
                if value5 then
                    helper3(input.Position.X, input.Position.Y)
                end
                if value6 then
                    helper4(input.Position.X)
                end
            end)
        )
        table.insert(
            context.sliderConnections,
            userInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    value5, value6 = false, false
                elseif input.UserInputType == Enum.UserInputType.Touch then
                    value5, value6 = false, false
                end
            end)
        )
        value.onClick(function()
            picker.Visible = not picker.Visible
        end)
        tip(parent, argument4)
        return { holder = colorWheel2, render = render }
    end
    local function button(parent, text, argument, argument2, success, argument3)
        local button2 = Instance.new("TextButton")
        button2.Name = "Button"
        button2.BorderSizePixel = 0
        button2.Size = UDim2.new(1, 0, 0, 32)
        button2.Text = text
        button2.TextSize = 13
        button2.AutoButtonColor = false
        button2.LayoutOrder = success or 1
        setFont(button2, "sans", Enum.FontWeight.SemiBold)
        button2.Parent = parent
        corner(button2, theme.RadiusMd)
        success, parent = pcall(function()
            local value, value2, gothamBold, value3 =
                getService("TextService"),
                tostring(text),
                Enum.Font.GothamBold,
                argumentHelpers[108](Vector2.new(2000, 40))
            return value:GetTextSize(value2, 13, gothamBold, argumentHelpers:unpackValues(value3))
        end)
        local value4 = Instance.new("UISizeConstraint")
        value4.MaxSize = Vector2.new(math.max(220, (success and parent.X or 180) + 44), math.huge)
        value4.Parent = button2
        if context.Shell then
            if context.Shell.pressable then
                context.Shell.pressable(button2)
            end
        end
        if argument == "accent" or argument == "danger" then
            button2.BackgroundTransparency = 1
            button2.TextTransparency = 1
            local fill = Instance.new("Frame")
            fill.Name, fill.BackgroundColor3, fill.BorderSizePixel, fill.Size, fill.ZIndex =
                "Fill", Color3.new(1, 1, 1), 0, UDim2.fromScale(1, 1), button2.ZIndex
            fill.Parent = button2
            corner(fill, theme.RadiusMd)
            value4 = Instance.new("UIGradient")
            value4.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, theme.AccentB),
                ColorSequenceKeypoint.new(0.5, theme.AccentDark),
                ColorSequenceKeypoint.new(1, theme.AccentB),
            })
            value4.Parent = fill
            local label2 = Instance.new("TextLabel")
            label2.Name, label2.BackgroundTransparency, label2.Size, label2.ZIndex, label2.Text, label2.TextColor3, label2.TextSize =
                "Label",
                1,
                UDim2.fromScale(1, 1),
                button2.ZIndex + 1,
                button2.Text,
                theme.TextOnAccent,
                button2.TextSize
            setFont(label2, "sans", Enum.FontWeight.SemiBold)
            label2.Parent = button2
            local function helper()
                label2.Text = button2.Text
            end
            button2:GetPropertyChangedSignal("Text"):Connect(helper)
            local function helper2()
                fill.BackgroundColor3 = Color3.new(0.68, 0.68, 0.68)
            end
            button2.MouseEnter:Connect(helper2)
            local function helper3()
                fill.BackgroundColor3 = Color3.new(1, 1, 1)
            end
            button2.MouseLeave:Connect(helper3)
        else
            button2.BackgroundColor3 = theme.SurfaceElement
            button2.TextColor3 = theme.TextPrimary
            stroke(button2, theme.Hairline, 1)
            local function helper4()
                button2.BackgroundColor3 = theme.SurfaceHover
            end
            button2.MouseEnter:Connect(helper4)
            local function helper17()
                button2.BackgroundColor3 = theme.SurfaceElement
            end
            button2.MouseLeave:Connect(helper17)
        end
        if argument2 then
            button2.MouseButton1Click:Connect(argument2)
        end
        tip(button2, argument3)
        return button2
    end
    local function textInput(argument, argument2, argument3, argument4, argument5, argument6, argument7)
        local value, input = row(argument, argument2, argument5, nil, 196), Instance.new("TextBox")
        input.Name = "Input"
        input.BackgroundColor3 = theme.SurfaceField
        input.BorderSizePixel = 0
        input.Size = UDim2.fromOffset(180, 24)
        input.LayoutOrder = 2
        input.Text = tostring(argument3() or "")
        input.PlaceholderText = argument7 or "empty = hidden"
        input.PlaceholderColor3 = theme.TextMuted
        input.TextColor3 = theme.TextPrimary
        input.TextSize = 12
        input.ClearTextOnFocus = false
        input.TextXAlignment = Enum.TextXAlignment.Left
        input.TextTruncate = Enum.TextTruncate.AtEnd
        setFont(input, "sans", Enum.FontWeight.Medium)
        input.Parent = value
        corner(input, theme.RadiusSm)
        stroke(input, theme.Hairline, 1)
        pad(input, 0, 8, 0, 8)
        local function render()
            input.Text = tostring(argument3() or "")
        end
        local function helper()
            argument4(input.Text)
        end
        input.FocusLost:Connect(helper)
        tip(value, argument6)
        return { row = value, render = render, box = input }
    end
    local function buttonRow(parent, argument)
        local buttons = Instance.new("Frame")
        buttons.Name = "Buttons"
        buttons.BackgroundTransparency = 1
        buttons.Size = UDim2.new(1, 0, 0, 32)
        buttons.LayoutOrder = argument or 1
        buttons.Parent = parent
        hlist(buttons, theme.GapMd)
        local value, value2 = 0, {}
        argument = {
            frame = buttons,
            add = function(argument2, argument3, argument4, argument5)
                value += 1
                local value3 = button(buttons, argument2, argument3, argument4, value, argument5)
                value3.Size = UDim2.new(0, 0, 1, 0)
                value2[value] = value3
                for index, entry in ipairs(value2) do
                    entry.Size = UDim2.new(1 / value, -(theme.GapMd * (value - 1)) / value, 1, 0)
                end
                return value3
            end,
        }
        return argument
    end
    local sharedValue9
    local sharedValue10 = 0
    local function raiseWindow(argument)
        sharedValue10 += 1
        argument:SetAttribute("hlTop", sharedValue10)
        argument.ZIndex = (tonumber(context.CFG and context.CFG.menuZ) or 20) + 1 + sharedValue10
        local parent = argument.Parent
        if parent then
            argument.Parent = nil
            argument.Parent = parent
        end
    end
    context.raiseWindow = raiseWindow
    local function makeDraggable(argument, argument2)
        local value, parent, position = false
        argument.InputBegan:Connect(function(input)
            if
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            then
                if pressOnTop(argument2, input) then
                    local rank = argument2:GetAttribute("hlTop")
                        or (
                                argument2.Parent and table.find(argument2.Parent:GetChildren(), argument2)
                                or 0
                            )
                            / 1000
                    local value2 = {
                        rank = rank,
                        go = function()
                            local parent2, position2
                            parent2, position2, value = input.Position, argument2.Position, true
                            parent, position = parent2, position2
                            sharedValue10 += 1
                            argument2:SetAttribute("hlTop", sharedValue10)
                            argument2.ZIndex = (tonumber(context.CFG and context.CFG.menuZ) or 20)
                                + 1
                                + sharedValue10
                            parent2 = argument2.Parent
                            if parent2 then
                                argument2.Parent = nil
                                argument2.Parent = parent2
                            end
                        end,
                    }
                    if sharedValue9 then
                        rank = sharedValue9
                        rank[#rank + 1] = value2
                        return
                    end
                    sharedValue9 = { value2 }
                    task.defer(function()
                        local value3, value4 = sharedValue9[1], sharedValue9
                        for index, entry in ipairs(value4) do
                            value3 = if entry.rank > value3.rank then entry else value3
                        end
                        sharedValue9 = nil
                        value3.go()
                    end)
                end
            end
        end)
        argument.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                value = false
            elseif input.UserInputType == Enum.UserInputType.Touch then
                value = false
            end
        end)
        table.insert(
            context.sliderConnections,
            userInputService.InputChanged:Connect(function(input)
                if not value then
                    return
                end
                if input.UserInputType ~= Enum.UserInputType.MouseMovement then
                    if input.UserInputType ~= Enum.UserInputType.Touch then
                        return
                    end
                end
                local vector = input.Position - parent
                argument2.Position = UDim2.new(
                    position.X.Scale,
                    position.X.Offset + vector.X,
                    position.Y.Scale,
                    position.Y.Offset + vector.Y
                )
            end)
        )
    end
    local function window(header, argument)
        local value = Instance.new("Frame")
        value.Name = argument.name or "Window"
        value.BackgroundColor3 = Color3.new(1, 1, 1)
        value.BorderSizePixel = 0
        value.Size = UDim2.fromOffset(argument.width or 310, argument.height or 460)
        value.Position = argument.position or UDim2.fromOffset(40, 40)
        value.Visible = argument.visible ~= false
        value.Active = true
        value.ClipsDescendants = true
        value.ZIndex = 2
        value:SetAttribute("hlWin", true)
        value.Parent = header
        local function helper(input)
            if
                (
                    input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch
                )
                and pressOnTop(value, input)
                and value.Parent
            then
                helper7(input)
                local value2, value3
                for index, child in ipairs(value.Parent:GetChildren()) do
                    if child:IsA("GuiObject") then
                        if child.Visible then
                            if child:GetAttribute("hlWin") then
                                index = helper6(child)
                                if value2 then
                                    if index > value2 then
                                        value2, value3 = index, child
                                    end
                                else
                                    value2, value3 = index, child
                                end
                            end
                        end
                    end
                end
                if value3 ~= value then
                    task.defer(raiseWindow, value)
                end
            end
        end
        value.InputBegan:Connect(helper)
        corner(value, theme.RadiusLg)
        stroke(value, theme.Hairline, 1)
        bodyGradient(value)
        shadow(value)
        header = Instance.new("Frame")
        header.Name = "Header"
        header.BackgroundColor3 = theme.SurfaceHeader
        header.BorderSizePixel = 0
        header.Size = UDim2.new(1, 0, 0, theme.HeaderH)
        header.Position = UDim2.fromOffset(0, 3)
        header.Active = true
        header.ZIndex = 3
        header.Parent = value
        corner(header, theme.RadiusLg)
        pad(header, 0, 12, 0, 14)
        helper = Instance.new("Frame")
        helper.Name = "HeaderFill"
        helper.BackgroundColor3 = theme.SurfaceHeader
        helper.BorderSizePixel = 0
        helper.Position = UDim2.fromOffset(0, theme.HeaderH + 3 - theme.RadiusLg)
        helper.Size = UDim2.new(1, 0, 0, theme.RadiusLg)
        helper.ZIndex = 3
        helper.Parent = value
        helper = Instance.new("CanvasGroup")
        helper.Name = "AccentBar"
        helper.BackgroundTransparency = 1
        helper.BorderSizePixel = 0
        helper.Position = UDim2.fromOffset(0, 0)
        helper.Size = UDim2.new(1, 0, 0, theme.RadiusLg + 3)
        helper.ZIndex = 4
        helper.Parent = value
        corner(helper, theme.RadiusLg)
        local value4 = Instance.new("Frame")
        value4.Name = "Band"
        value4.BackgroundColor3 = Color3.new(1, 1, 1)
        value4.BorderSizePixel = 0
        value4.Size = UDim2.new(1, 0, 0, 3)
        value4.ZIndex = 4
        value4.Parent = helper
        accentSweep(value4)
        hlist(header, theme.GapLg)
        makeDraggable(header, value)
        helper = nil
        if argument.icon and sharedValue7[argument.icon] then
            helper = icon(header, argument.icon, 16, Color3.new(1, 1, 1), 4)
            helper.Name = "Icon"
            helper.LayoutOrder = 1
        else
            helper = Instance.new("Frame")
            helper.Name = "Icon"
            helper.BackgroundColor3 = Color3.new(1, 1, 1)
            helper.BorderSizePixel = 0
            helper.Size = UDim2.fromOffset(14, 14)
            helper.LayoutOrder = 1
            helper.ZIndex = 4
            helper.Parent = header
            corner(helper, 4)
        end
        accentGradient(helper, 45)
        helper = label(header, argument.title or "Window", "windowTitle", 2)
        helper.ZIndex = 4
        flexFill(helper, 58 + (argument.info and 32 or 0))
        local value5 = false
        local pin = Instance.new("TextButton")
        pin.Name = "Pin"
        pin.BackgroundColor3 = theme.SurfaceElement
        pin.BorderSizePixel = 0
        pin.Size = UDim2.fromOffset(20, 20)
        pin.Text = ""
        pin.AutoButtonColor = false
        pin.LayoutOrder = 3
        pin.ZIndex = 4
        pin.Parent = header
        corner(pin, 6)
        local value6 = stroke(pin, theme.Hairline, 1)
        local value7 = icon(pin, "pin", 13, theme.TextMuted, 5)
        value7.AnchorPoint, value7.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
        local function helper2()
            local imageColor3 = value5 and theme.AccentMid or theme.TextMuted
            value7.ImageColor3 = imageColor3
            value6.Color = value5 and theme.AccentMid or theme.Hairline
            pin.BackgroundColor3 = value5 and theme.SurfaceHover or theme.SurfaceElement
        end
        helper2()
        tip(
            pin,
            "Pin this window so it stays on screen after you close the interface. You can still drag it. Click again to let it hide with the rest."
        )
        if argument.info then
            value4 = Instance.new("TextLabel")
            value4.Name = "Info"
            value4.BackgroundColor3 = theme.SurfaceElement
            value4.BorderSizePixel = 0
            value4.Size = UDim2.fromOffset(20, 20)
            value4.Text = ""
            value4.TextColor3 = theme.TextSub
            value4.TextSize = 12
            value4.LayoutOrder = 3
            value4.ZIndex = 4
            setFont(value4, "sans", Enum.FontWeight.Bold)
            value4.Parent = header
            corner(value4, 10)
            stroke(value4, theme.Hairline, 1)
            local value8 = icon(value4, "info", 13, theme.TextSub, 5)
            value8.AnchorPoint, value8.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
            tip(value4, argument.info)
        end
        value4 = Instance.new("Frame")
        value4.Name = "Divider"
        value4.BackgroundColor3 = theme.Hairline
        value4.BorderSizePixel = 0
        value4.Size = UDim2.new(1, 0, 0, 1)
        value4.Position = UDim2.fromOffset(0, 3 + theme.HeaderH)
        value4.ZIndex = 3
        value4.Parent = value
        value4 = Instance.new("ScrollingFrame")
        value4.Name = "Body"
        value4.BackgroundTransparency = 1
        value4.BorderSizePixel = 0
        value4.Position = UDim2.fromOffset(0, 4 + theme.HeaderH)
        value4.Size = UDim2.new(1, 0, 1, -(4 + theme.HeaderH + theme.RadiusLg))
        value4.CanvasSize = UDim2.new()
        value4.AutomaticCanvasSize = Enum.AutomaticSize.Y
        value4.ScrollBarThickness = 4
        value4.ScrollBarImageColor3 = Color3.fromHex("50505f")
        value4.ZIndex = 3
        value4.Parent = value
        pad(value4, 10, theme.GapLg, theme.GapXl, theme.GapLg)
        local value9 = vlist(value4, theme.GapSm)
        local value10 = argument.maxHeight or argument.height or 460
        local function fit()
            local value2 = 4
                + theme.HeaderH
                + 10
                + value9.AbsoluteContentSize.Y
                + theme.GapXl
                + theme.RadiusLg
            local value3 = math.clamp(value2, theme.HeaderH + 48, value10)
            value.Size = UDim2.fromOffset(argument.width or 310, value3)
        end
        if argument.autoHeight ~= false then
            value9:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(fit)
            task.defer(fit)
        end
        local value11 = {
            frame = value,
            header = header,
            body = value4,
            title = helper,
            fit = fit,
            isPinned = function()
                local value2 = value5
                return value2
            end,
        }
        value11.setPinned = function(argument2)
            value5 = argument2 and true or false
            helper2()
            if argument.onPinChanged then
                argument.onPinChanged(value11)
            end
        end
        pin.MouseButton1Click:Connect(function()
            value11.setPinned(not value5)
        end)
        return value11
    end
    local function section(parent, argument, argument2, argument3)
        local section2 = Instance.new("Frame")
        section2.Name = "Section"
        section2.BackgroundTransparency = 1
        section2.AutomaticSize = Enum.AutomaticSize.Y
        section2.Size = UDim2.new(1, 0, 0, 0)
        section2.LayoutOrder = argument2 or 1
        section2.Parent = parent
        vlist(section2, theme.GapSm)
        local head, textControl = row(section2, argument, 1, nil, 24)
        head.BackgroundColor3 = theme.SurfaceSection
        setFont(textControl, "sans", Enum.FontWeight.SemiBold)
        local value, value2 = hoverable(head, true), chevron(head)
        local content = Instance.new("Frame")
        content.Name = "Content"
        content.BackgroundColor3 = theme.SurfaceWell
        content.BorderSizePixel = 0
        content.AutomaticSize = Enum.AutomaticSize.Y
        content.Size = UDim2.new(1, 0, 0, 0)
        content.Visible = false
        content.LayoutOrder = 2
        content.Parent = section2
        corner(content, theme.RadiusMd)
        local value3 = vlist(content, theme.GapSm)
        pad(content, 6, 6, 6, 6)
        local visible = false
        local function setOpen(argument4, argument5)
            argument4 = argument4 and true or false
            local value4 = argument4 ~= visible
            visible = argument4
            value2.setOpen(visible)
            textControl.TextColor3 = visible and theme.AccentMid or theme.TextPrimary
            if value4 then
                if argument5 then
                    content.Visible = visible
                elseif context.Shell then
                    if context.Shell.slideTo then
                        if context.Shell.isShown then
                            if context.Shell.isShown() then
                                local value5 = game
                                if section2:IsDescendantOf(value5) then
                                    context.Shell.slideTo(content, value3, 12, visible)
                                else
                                    content.Visible = visible
                                end
                            else
                                content.Visible = visible
                            end
                        else
                            content.Visible = visible
                        end
                    else
                        content.Visible = visible
                    end
                else
                    content.Visible = visible
                end
            else
                content.Visible = visible
            end
        end
        setOpen(false, true)
        value.onClick(function()
            setOpen(not visible)
        end)
        tip(head, argument3)
        if argument3 then
            if argument3 ~= "" then
                argument2 = label(content, argument3, "captionSub", -1000)
                argument2.Name = "Description"
                argument2.TextSize = 11
                argument2.AutomaticSize = Enum.AutomaticSize.Y
                argument2.Size = UDim2.new(1, 0, 0, 0)
                argument2.TextWrapped = true
                argument2.TextYAlignment = Enum.TextYAlignment.Top
                pad(argument2, 2, 4, 2, 4)
            end
        end
        context.sectionReg = context.sectionReg or {}
        context.sectionReg[section2] = {
            head = head,
            content = content,
            setOpen = setOpen,
            isOpen = function()
                local visible2 = visible
                return visible2
            end,
        }
        argument2 = {
            holder = section2,
            content = content,
            setOpen = function(argument4, argument5)
                if not argument4 then
                    setOpen(false, argument5)
                end
            end,
            isOpen = function()
                local visible2 = visible
                return visible2
            end,
        }
        return argument2
    end
    context.UIKit = {
        Theme = theme,
        setFont = setFont,
        corner = corner,
        stroke = stroke,
        pad = pad,
        vlist = vlist,
        hlist = hlist,
        label = label,
        caption = function(argument, argument2, argument3)
            local value = label(argument, argument2, "captionSub", argument3)
            value.AutomaticSize = Enum.AutomaticSize.Y
            value.Size = UDim2.new(1, 0, 0, 0)
            value.TextWrapped = true
            value.TextYAlignment = Enum.TextYAlignment.Top
            return value
        end,
        flexFill = flexFill,
        accentGradient = accentGradient,
        accentSweep = accentSweep,
        stopSweeps = stopSweeps,
        bodyGradient = bodyGradient,
        shadow = shadow,
        ensureTip = ensureTip,
        tip = tip,
        hideTip = hideTip,
        chevron = chevron,
        row = row,
        hoverable = hoverable,
        icon = icon,
        toggle = toggle,
        slider = slider,
        dropdown = dropdown,
        multiDropdown = multiDropdown,
        textInput = textInput,
        rangeSlider = rangeSlider,
        listInput = listInput,
        colorRow = colorRow,
        colorWheel = colorWheel,
        button = button,
        buttonRow = buttonRow,
        window = window,
        section = section,
        makeDraggable = makeDraggable,
    }
end


-- ============================================================
--  Main GUI shell (window, sidebar tabs, search, header)
-- ============================================================
components.shellKit = function(context)
    local uiLibrary = context.UIKit
    local theme = context.UIKit.Theme
    local config = context.CFG
    local runtimeState = context.RT
    local localPlayer = context.LocalPlayer
    local runService = context.RunService
    local userInputService = context.UserInputService
    local sliderConnections = context.sliderConnections
    local sharedValue5 = getService("Players")
    local ver = context.shellVersion or ""
    context.buildShell = function(argument)
        local value2 = getService("TweenService")
        getService("TextService")
        local value3, value4 = { pages = {}, order = {} }, {}
        local function helper6(argument2, argument3)
            local connection = argument2:Connect(argument3)
            value4[#value4 + 1] = connection
            sliderConnections[#sliderConnections + 1] = connection
            return connection
        end
        local function helper22(argument2, argument3, parent)
            local value = Instance.new(argument2)
            for key, entry in pairs(argument3 or {}) do
                value[key] = entry
            end
            if parent then
                value.Parent = parent
            end
            return value
        end
        local radiusSm, radiusMd = theme.RadiusSm, theme.RadiusMd
        local radiusLg = theme.RadiusLg
        local icon, fontWeight = theme.RowH, Enum.FontWeight
        local function helper23(argument2, argument3)
            return uiLibrary.corner(argument2, argument3 or radiusMd)
        end
        local function helper24(argument2, argument3, argument4)
            return uiLibrary.stroke(argument2, argument3 or theme.Hairline, argument4 or 1)
        end
        local function helper25(argument2, argument3, argument4, argument5, argument6)
            return uiLibrary.pad(
                argument2,
                argument3,
                argument4 or argument3,
                argument5 or argument3,
                argument6 or argument4 or argument3
            )
        end
        local function helper26(argument2, argument3)
            return uiLibrary.vlist(argument2, argument3 or 0)
        end
        local function helper27(argument2, argument3, argument4)
            local value = uiLibrary.hlist(argument2, argument3 or 0)
            if argument4 then
                value.HorizontalAlignment = Enum.HorizontalAlignment.Right
            end
            return value
        end
        local function helper28(argument2, text, textSize, textColor3, argument3, argument4)
            local value = helper22("TextLabel", {
                BackgroundTransparency = 1,
                Text = text,
                TextSize = textSize,
                TextColor3 = textColor3,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                Size = UDim2.new(1, 0, 0, textSize + 6),
            }, argument2)
            uiLibrary.setFont(value, "sans", argument3 or fontWeight.Regular)
            for key, entry in pairs(argument4 or {}) do
                value[key] = entry
            end
            return value
        end
        local function helper29(argument2, argument3, argument4, argument5, argument6)
            local value = uiLibrary.icon(argument2, argument3, argument4, argument5)
            for key, entry in pairs(argument6 or {}) do
                value[key] = entry
            end
            return value
        end
        local function helper30(argument2, argument3)
            local value = helper22(
                "TextButton",
                { AutoButtonColor = false, Text = "", BackgroundTransparency = 1, BorderSizePixel = 0 },
                argument2
            )
            for key, entry in pairs(argument3 or {}) do
                value[key] = entry
            end
            return value
        end
        local function helper31(argument2)
            argument2.AnchorPoint, argument2.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
            return argument2
        end
        local value5 = context.COMPACT == true
        local function helper32(input)
            return input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
        end
        local function helper33(input)
            return input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch
        end
        local function helper34(argument2, argument3, argument4)
            local value = value2:Create(
                argument2,
                TweenInfo.new(argument3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                argument4
            )
            value:Play()
            return value
        end
        local function twd(argument2, argument3, argument4, argument5, argument6, argument7)
            local value = value2:Create(
                argument2,
                TweenInfo.new(
                    argument3,
                    argument6 or Enum.EasingStyle.Quint,
                    argument7 or Enum.EasingDirection.Out,
                    0,
                    false,
                    argument5 or 0
                ),
                argument4
            )
            value:Play()
            return value
        end
        value3.tw = helper34
        value3.twd = twd
        local value6, value7, value8, value9, value10, value11, value12 = 780, 600, 184, 58, 3, 620, 400
        local function helper35()
            local camera = workspace.CurrentCamera
            return camera and camera.ViewportSize or Vector2.new(1920, 1080)
        end
        local function helper36()
            local absoluteSize = argument.AbsoluteSize
            if absoluteSize.X > 0 then
                if absoluteSize.Y > 0 then
                    return absoluteSize
                end
            end
            return helper35()
        end
        local value13, value14, value15, value16, value17
        if value5 then
            local vector = helper36()
            value9, value11, value12 = 44, 460, 260
            value6 = math.floor(math.clamp(vector.X - 48, value11, 720))
            value7 = math.floor(math.clamp(vector.Y - 20, value12, 440))
            value13, value14, value8, value15, value16, value17 = value6, value7, 56, value9, value11, value12
        else
            value13, value14, value15, value16, value17 = value6, value7, value9, value11, value12
        end
        local value18 = "HarvardLabs/configs/menu_window.json"
        local value19 = value5 and "phone" or "pc"
        local function helper37()
            local success, value = pcall(function()
                local value20, value21 = getService("HttpService"), argumentHelpers[108](readfile(value18))
                return value20:JSONDecode(argumentHelpers:unpackValues(value21))
            end)
            return success and type(value) == "table" and value or {}
        end
        local visible = helper37()[value19]
        local value22, value23, value24, value25 =
            type(visible) == "table" and tonumber(visible.w) or nil,
            type(visible) == "table" and tonumber(visible.h) or nil
        if value22 then
            local value26, value27
            if value23 then
                visible = value5 and helper36() or helper35()
                local value28 = math.floor(math.clamp(value22, value16, math.max(value16, visible.X - 20)))
                local value29 = math.floor(math.clamp(value23, value17, math.max(value17, visible.Y - 20)))
                value26, value27 = value28, value29
            else
                value26, value27 = value13, value14
            end
            value24, value25 = value26, value27
        else
            value24, value25 = value13, value14
        end
        local function helper38()
            local value = helper37()
            value[value19] = { w = value24, h = value25 }
            pcall(function()
                writefile(value18, getService("HttpService"):JSONEncode(value))
            end)
        end
        local value30 = helper22("Frame", {
            Name = "HLMenu",
            Size = UDim2.fromOffset(value24, value25),
            BackgroundTransparency = 1,
            Visible = false,
            ZIndex = tonumber(config.menuZ) or 20,
        }, argument)
        value30:SetAttribute("hlWin", true)
        value30:SetAttribute("HLUIMotionOwned", true)
        local value31 = helper22("UIScale", {}, value30)
        local value32 = helper22(
            "Frame",
            { Name = "Shadow", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) },
            value30
        )
        for index = 1, 8, 1 do
            value23, visible = index * 1.5, 10 * index / 8
            helper23(
                helper22("Frame", {
                    BackgroundColor3 = Color3.new(0, 0, 0),
                    BackgroundTransparency = 0.96,
                    BorderSizePixel = 0,
                    Position = UDim2.fromOffset(-value23, -value23 + visible),
                    Size = UDim2.new(1, value23 * 2, 1, value23 * 2),
                }, value32),
                radiusLg + value23
            )
        end
        local root = helper22("Frame", {
            Name = "Window",
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            ClipsDescendants = true,
            Active = true,
        }, value30)
        helper22("TextButton", {
            Name = "FreeMouse",
            Modal = true,
            Text = "",
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(0, 0),
        }, root)
        helper23(root, radiusLg)
        helper24(root, theme.Hairline, 1)
        helper22("UIGradient", {
            Rotation = 90,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, theme.BodyTop),
                ColorSequenceKeypoint.new(0.45, theme.BodyMid),
                ColorSequenceKeypoint.new(1, theme.BodyBot),
            }),
        }, root)
        value3.holder = value30
        value3.root = root
        local value33, value34 = 1, false
        local value35 = Vector2.zero
        local value36, value37 = Vector2.zero, 1
        local function helper39()
            local scale = value33 * value37
            value31.Scale = scale
            local value = Vector2.new(value30.Size.X.Offset, value30.Size.Y.Offset)
            local vector2 = value * (value33 - scale) / 2
            value30.Position = UDim2.fromOffset(
                math.floor(value36.X + vector2.X + 0.5),
                math.floor(value36.Y + vector2.Y + 0.5)
            )
        end
        local value38
        local function helper40()
            local vector2 = value5 and helper36() or helper35()
            return math.clamp(math.min((vector2.X - 24) / 312, (vector2.Y - 24) / 520), 0.5, 1)
        end
        local function stroke()
            local vector2 = value5 and helper36() or helper35()
            value33 = if value5
                then math.clamp(math.min((vector2.X - 8) / value13, (vector2.Y - 8) / value14), 0.6, 1)
                else math.clamp(math.min((vector2.X - 24) / value13, (vector2.Y - 24) / value14), 0.5, 1)
            if value38 then
                value38.Scale = helper40()
            end
            if not value34 then
                value34 = true
                value35 = Vector2.new(
                    math.floor((vector2.X - value24 * value33) / 2),
                    math.floor((vector2.Y - value25 * value33) / 2)
                )
                value36 = value35
            end
            helper39()
        end
        stroke()
        if workspace.CurrentCamera then
            helper6(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), stroke)
        end
        local function helper41(argument2)
            local value, value20 = argument2 - root.AbsolutePosition, value33
            return value / value20
        end
        value23 = helper22("CanvasGroup", {
            Name = "AccentBar",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, radiusLg + value10),
            ZIndex = 6,
        }, root)
        helper23(value23, radiusLg)
        stroke = helper22("Frame", {
            Name = "Band",
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, value10),
            ZIndex = 6,
        }, value23)
        uiLibrary.accentSweep(stroke)
        value3.accentBar = value23
        local header = helper22("Frame", {
            Name = "Header",
            BackgroundColor3 = theme.SurfaceHeader,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(0, value10),
            Size = UDim2.new(1, 0, 0, value15),
            ZIndex = 3,
        }, root)
        helper22("Frame", {
            Name = "Divider",
            BackgroundColor3 = theme.Hairline,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(0, value10 + value15),
            Size = UDim2.new(1, 0, 0, 1),
            ZIndex = 3,
        }, root)
        local value39, value40 =
            {}, {
                "...#....",
                "..#.....",
                ".##.....",
                ".##..#..",
                ".##.###.",
                ".###.###",
                ".##..##.",
                ".##..##.",
                ".##..##.",
                "###..##.",
                ".###.##.",
                "..#..##.",
                ".....##.",
                ".....#..",
                "....#...",
                "...#....",
            }
        do
            local value41 = helper22("Frame", {
                Name = "Logo",
                Position = value5 and UDim2.fromOffset(12, 7) or UDim2.fromOffset(16, 10),
                Size = value5 and UDim2.fromOffset(28, 30) or UDim2.fromOffset(36, 38),
                BackgroundTransparency = 1,
                ZIndex = 4,
            }, header)
            value41:SetAttribute("HLThemeSkipTree", true)
            if
                not (
                    pcall(function()
                        local parent, camera =
                            helper22("ViewportFrame", {
                                Size = UDim2.fromScale(1, 1),
                                BackgroundTransparency = 1,
                                Ambient = Color3.new(1, 1, 1),
                                LightColor = Color3.new(0, 0, 0),
                                ZIndex = 4,
                            }, value41), Instance.new("Camera")
                        camera.FieldOfView = 22
                        camera.CFrame = CFrame.new(Vector3.new(0, 0, 11.6), Vector3.new(0, 0, 0))
                        camera.Parent = parent
                        parent.CurrentCamera = camera
                        local parent2 = Instance.new("Model")
                        local value, value20, value21, value42 = #value40, #value40[1], 0.25, 0.5
                        local value43, value44 = value20 * value21 / 2, value * value21 / 2
                        for index2 = 1, value, 1 do
                            for index3 = 1, value20, 1 do
                                if value40[index2]:sub(index3, index3) == "#" then
                                    camera = Instance.new("Part")
                                    camera.Anchored, camera.CanCollide, camera.CastShadow, camera.Material =
                                        true, false, false, Enum.Material.SmoothPlastic
                                    camera.Size = Vector3.new(0.252, 0.252, value42)
                                    camera.CFrame = CFrame.new(
                                        (index3 - 1) * value21 + 0.125 - value43,
                                        value44 - (index2 - 1) * value21 - 0.125,
                                        0
                                    )
                                    camera.Color = theme.AccentB
                                    camera.Parent = parent2
                                    value39[#value39 + 1] = {
                                        p = camera,
                                        u = ((index3 - 1) / (value20 - 1) + (index2 - 1) / (value - 1)) * 0.5,
                                        ax = (index3 - 0.5) / value20,
                                        ay = (index2 - 0.5) / value,
                                    }
                                end
                            end
                        end
                        parent2.Parent = parent
                        parent2.WorldPivot = CFrame.new()
                        local function helper42(argument2)
                            return argument2 < 0.5 and 4 * argument2 * argument2 * argument2
                                or 1 - (-2 * argument2 + 2) ^ 3 / 2
                        end
                        local value45
                        local value46 = 0
                        parent2:PivotTo(CFrame.Angles(0, -0.17453292519943295, 0))
                        helper6(runService.RenderStepped, function()
                            if not value30.Visible then
                                return
                            end
                            local now = os.clock()
                            local value47 = now % 3
                            local value48 = value47 < 1 and -10 + 360 * helper42(value47) or -10
                            if value48 ~= value45 then
                                value45 = value48
                                parent2:PivotTo(CFrame.Angles(0, math.rad(value48), 0))
                            end
                            if now - value46 < 0.03333333333333333 then
                                return
                            end
                            value46 = now
                            value48, value47 = theme.AccentB
                            if context.themeLive then
                                local value49, value50 = context.themeLive(now)
                                value48, value47 = value49 or theme.AccentB, value50
                            end
                            if value47 then
                                local vector2, absoluteSize =
                                    value41.AbsolutePosition - value30.AbsolutePosition, value41.AbsoluteSize
                                for index4, entry in ipairs(value39) do
                                    entry.p.Color = value47(
                                        now,
                                        vector2.X + entry.ax * absoluteSize.X,
                                        vector2.Y + entry.ay * absoluteSize.Y
                                    )
                                end
                            else
                                local value51, value52, value53 = value48:ToHSV()
                                local value54, value55 =
                                    Color3.fromHSV(value51, value52, value53 * 0.55),
                                    Color3.fromHSV(value51, value52 * 0.88, math.min(1, value53 * 1.12))
                                for index5, entry2 in ipairs(value39) do
                                    entry2.p.Color = value54:Lerp(
                                        value55,
                                        0.5
                                            + 0.5
                                                * math.cos(
                                                    (entry2.u * 0.8 - now * 0.25) * 3.141592653589793 * 2
                                                )
                                    )
                                end
                            end
                        end)
                    end)
                )
            then
                visible = helper23(
                    helper22("Frame", {
                        Size = UDim2.fromOffset(32, 32),
                        Position = UDim2.fromOffset(2, 3),
                        BackgroundColor3 = Color3.new(1, 1, 1),
                        ZIndex = 4,
                    }, value41),
                    radiusMd
                )
                uiLibrary.accentGradient(visible, 45)
                helper28(
                    visible,
                    "h",
                    22,
                    theme.TextOnAccent,
                    fontWeight.Bold,
                    { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 5 }
                )
            end
            local value56, value57, bold, value58 =
                value5 and 15 or 17,
                theme.TextPrimary,
                fontWeight.Bold,
                { Position = value5 and UDim2.fromOffset(48, 5) or UDim2.fromOffset(60, 10) }
            value58.Size, value58.ZIndex = UDim2.fromOffset(value5 and 220 or 320, value5 and 19 or 22), 4
            helper28(header, tostring(context.shellTitle or "My GUI"), value56, value57, bold, value58)
            value23, stroke, value56, value57, value22 =
                tostring(ver),
                value5 and 11 or 12,
                theme.TextMuted,
                fontWeight.Medium,
                { Position = value5 and UDim2.fromOffset(48, 23) or UDim2.fromOffset(60, 31) }
            value22.Size, value22.ZIndex = UDim2.fromOffset(value5 and 220 or 320, value5 and 14 or 16), 4
            helper28(header, value23, stroke, value56, value57, value22)
        end
        local value59 = helper22("Frame", {
            Name = "Overlay",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            ZIndex = 50,
            Visible = false,
        }, root)
        local value60 = helper30(value59, { Size = UDim2.fromScale(1, 1), ZIndex = 50 })
        local function helper43()
            for index2, child in ipairs(value59:GetChildren()) do
                if child ~= value60 then
                    child:Destroy()
                end
            end
            value59.Visible = false
        end
        helper6(value60.Activated, helper43)
        local function pressable(argument2)
            local value = helper22("UIScale", {}, argument2)
            helper6(argument2.MouseButton1Down, function()
                twd(value, 0.08, { Scale = 0.96 }, 0, Enum.EasingStyle.Quad)
            end)
            local function helper42()
                twd(value, 0.28, { Scale = 1 }, 0, Enum.EasingStyle.Back)
            end
            helper6(argument2.MouseButton1Up, helper42)
            helper6(argument2.MouseLeave, helper42)
        end
        value3.pressable = pressable
        local value61 = {}
        local function slideTo(argument2, argument3, argument4, argument5, argument6)
            local value = (value61[argument2] or 0) + 1
            value61[argument2] = value
            local value20 = argument2.Size.X
            local value21 = argument2.Visible and argument2.AbsoluteSize.Y / math.max(value33, 0.01) or 0
            value21 = if argument2:FindFirstAncestorOfClass("ScreenGui") ~= argument
                    or not value30:IsAncestorOf(argument2)
                then argument2.Visible and argument2.AbsoluteSize.Y or 0
                else value21
            argument2.ClipsDescendants = true
            argument2.AutomaticSize = Enum.AutomaticSize.None
            argument2.Size = UDim2.new(value20.Scale, value20.Offset, 0, value21)
            argument2.Visible = true
            task.defer(function()
                if value61[argument2] ~= value then
                    return
                end
                local value42 = value30:IsAncestorOf(argument2) and value33 or 1
                local value43 = argument5 and argument3.AbsoluteContentSize.Y / value42 + argument4 or 0
                value42 = value2:Create(
                    argument2,
                    TweenInfo.new(
                        argument5 and 0.34 or 0.24,
                        Enum.EasingStyle.Quint,
                        Enum.EasingDirection.Out
                    ),
                    { Size = UDim2.new(value20.Scale, value20.Offset, 0, value43) }
                )
                value42:Play()
                local function helper42()
                    if value61[argument2] ~= value then
                        return
                    end
                    value61[argument2] = nil
                    if not argument5 then
                        argument2.Visible = false
                    end
                    argument2.AutomaticSize = Enum.AutomaticSize.Y
                    argument2.Size = UDim2.new(value20.Scale, value20.Offset, 0, 0)
                    argument2.ClipsDescendants = false
                    if argument6 then
                        argument6()
                    end
                end
                value42.Completed:Once(helper42)
            end)
        end
        value3.slideTo = slideTo
        local value62, value63 = {}, {}
        local function helper44(argument2, prop, argument3, dur)
            local value, value20 = value63[argument2]
            if value then
                if value[prop] then
                    local value21 = value[prop].to
                    value[prop].dead = true
                    value20 = value21
                else
                    value20 = argument2[prop]
                end
            else
                value20 = argument2[prop]
            end
            if value20 >= 0.999 then
                return
            end
            local value42 = { o = argument2, prop = prop, to = value20, t0 = argument3, dur = dur }
            value = value or {}
            value[prop] = value42
            value63[argument2] = value
            argument2[prop] = 1
            value62[#value62 + 1] = value42
        end
        local function helper45(argument2, argument3, argument4, argument5)
            local value = os.clock() + (argument3 or 0)
            argument4 = argument4 or 0.42
            argument3 = argument5 and { argument2 } or argument2:GetDescendants()
            if not argument5 then
                table.insert(argument3, 1, argument2)
            end
            for index2, entry in ipairs(argument3) do
                if entry:IsA("GuiObject") then
                    if entry.Visible then
                        helper44(entry, "BackgroundTransparency", value, argument4)
                        if entry:IsA("TextLabel") then
                            helper44(entry, "TextTransparency", value, argument4)
                        elseif entry:IsA("TextButton") then
                            helper44(entry, "TextTransparency", value, argument4)
                        elseif entry:IsA("TextBox") then
                            helper44(entry, "TextTransparency", value, argument4)
                        end
                        if entry:IsA("ImageLabel") then
                            helper44(entry, "ImageTransparency", value, argument4)
                        elseif entry:IsA("ImageButton") then
                            helper44(entry, "ImageTransparency", value, argument4)
                        end
                    end
                elseif entry:IsA("UIStroke") then
                    if not argument5 then
                        helper44(entry, "Transparency", value, argument4)
                    end
                end
            end
        end
        helper6(runService.RenderStepped, function()
            if #value62 == 0 then
                return
            end
            local now = os.clock()
            for index2 = #value62, 1, -1 do
                local value = value62[index2]
                if value.dead or not value.o.Parent then
                    table.remove(value62, index2)
                    if not value.dead then
                        if value63[value.o] then
                            value63[value.o] = nil
                        end
                    end
                else
                    local value20 = (now - value.t0) / value.dur
                    if value20 >= 1 then
                        value.o[value.prop] = value.to
                        local value21 = value63[value.o]
                        if value21 then
                            if value21[value.prop] == value then
                                value21[value.prop] = nil
                                if next(value21) == nil then
                                    value63[value.o] = nil
                                end
                            end
                        end
                        table.remove(value62, index2)
                    elseif value20 > 0 then
                        value.o[value.prop] = 1 + (value.to - 1) * (1 - (1 - value20) ^ 3)
                    end
                end
            end
        end)
        local function helper46(argument2, argument3)
            if argument2.AutomaticSize ~= Enum.AutomaticSize.None then
                return
            end
            local value = argument2:FindFirstChildOfClass("UIPadding") or helper22("UIPadding", {}, argument2)
            if value:GetAttribute("hlT") == nil then
                value:SetAttribute("hlT", value.PaddingTop.Offset)
            end
            argument2 = value:GetAttribute("hlT")
            value.PaddingTop = UDim.new(0, argument2 + 8)
            twd(value, 0.45, { PaddingTop = UDim.new(0, argument2) }, argument3)
        end
        local function helper47(argument2)
            local value, value20, value21 = 0.045, 18, 0
            local function helper42()
                local value42 = math.min(value21, value20) * value
                value21 += 1
                return value42
            end
            local function helper48(argument3)
                local value42, value43 = {}, {}
                for index2, child in ipairs(argument3:GetChildren()) do
                    if child:IsA("GuiObject") then
                        if child.Visible then
                            value42[#value42 + 1] = child
                            value43[child] = index2
                        end
                    end
                end
                table.sort(value42, function(argument4, argument5)
                    if argument4.LayoutOrder ~= argument5.LayoutOrder then
                        return argument4.LayoutOrder < argument5.LayoutOrder
                    end
                    return value43[argument4] < value43[argument5]
                end)
                return value42
            end
            local value44 = helper48(argument2)
            for index3, entry in ipairs(value44) do
                index3 = value3.sections[entry]
                if index3 then
                    helper45(index3.head, (helper42()))
                    if index3.content.Visible then
                        helper45(index3.content, math.max(0, value21 - 1) * value + 0.04, 0.34, true)
                        for index4, entry2 in ipairs((helper48(index3.content))) do
                            index4 = helper42()
                            helper45(entry2, index4)
                            helper46(entry2, index4)
                        end
                    end
                else
                    argument2 = helper42()
                    helper45(entry, argument2)
                    helper46(entry, argument2)
                end
            end
        end
        value3.sections = context.sectionReg or {}
        context.sectionReg = value3.sections
        do
            local textControl = helper22("TextLabel", {
                AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.new(0.5, 0, 1, -16),
                Size = UDim2.fromOffset(0, 32),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundColor3 = Color3.fromHex("3a3a42"),
                TextColor3 = theme.TextPrimary,
                TextSize = 12,
                Text = "",
                ZIndex = 70,
                Visible = false,
            }, root)
            uiLibrary.setFont(textControl, "sans", fontWeight.Medium)
            helper23(textControl, radiusMd)
            helper24(textControl, theme.Hairline, 1)
            helper25(textControl, 0, 14, 0, 14)
            local value64 = 0
            value3.toast = function(text)
                value64 += 1
                local value = value64
                textControl.Text = text
                textControl.Visible = true
                textControl.TextTransparency = 1
                textControl.BackgroundTransparency = 1
                textControl.Position = UDim2.new(0.5, 0, 1, -6)
                helper34(
                    textControl,
                    0.3,
                    { TextTransparency = 0, BackgroundTransparency = 0, Position = UDim2.new(0.5, 0, 1, -16) }
                )
                task.delay(2.4, function()
                    if value64 ~= value then
                        return
                    elseif not textControl.Parent then
                        return
                    end
                    helper34(textControl, 0.3, { TextTransparency = 1, BackgroundTransparency = 1 })
                    task.delay(0.3, function()
                        if value64 == value then
                            if textControl.Parent then
                                textControl.Visible = false
                            end
                        end
                    end)
                end)
            end
        end
        local value65 = value5 and 30 or 28
        local value66 = helper22("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, value5 and -10 or -14, 0.5, 0),
            Size = UDim2.fromOffset(value65 * 3 + 12, value65),
            BackgroundTransparency = 1,
            ZIndex = 4,
        }, header)
        helper27(value66, 6, true)
        local function helper49(layoutOrder, argument2, argument3, argument4)
            local value = helper30(value66, {
                Size = UDim2.fromOffset(value65, value65),
                LayoutOrder = layoutOrder,
                BackgroundColor3 = theme.SurfaceElement,
                BackgroundTransparency = 0,
                ZIndex = 4,
            })
            helper23(value, radiusMd)
            helper24(value, theme.Hairline, 1)
            argument2(value)
            helper6(value.MouseEnter, function()
                helper34(value, 0.14, { BackgroundColor3 = theme.SurfaceHover })
            end)
            helper6(value.MouseLeave, function()
                helper34(value, 0.2, { BackgroundColor3 = theme.SurfaceElement })
            end)
            pressable(value)
            helper6(value.Activated, argument4)
            uiLibrary.tip(value, argument3)
            return value
        end
        local value67, value68, value69, value70, value71 = false, false, value13, value14
        local function helper50()
            helper34(
                value30,
                0.25,
                { Size = UDim2.fromOffset(value24, value67 and value10 + value15 + 1 or value25) }
            )
        end
        helper49(
            1,
            function(argument2)
                helper31(helper22("Frame", {
                    Size = UDim2.fromOffset(11, 2),
                    BackgroundColor3 = theme.TextMuted,
                    BorderSizePixel = 0,
                    ZIndex = 5,
                }, argument2))
            end,
            "Fold the window up to its header.",
            function()
                value67 = not value67
                helper50()
            end
        )
        helper49(
            2,
            function(argument2)
                local value = helper31(
                    helper22(
                        "Frame",
                        { Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 1, ZIndex = 5 },
                        argument2
                    )
                )
                helper23(value, 2)
                helper24(value, theme.TextMuted, 1.5)
            end,
            "Make the window as big as the screen allows, or back to the size it was.",
            function()
                value68, value67 = not value68, false
                if value68 then
                    value69, value70, value71 = value24, value25, value35
                    local value, vector2 = value5 and 6 or 40, (value5 and helper36() or helper35()) / value33
                    local value20, value21 =
                        math.max(value16, math.floor(vector2.X - 2 * value)),
                        math.max(value17, math.floor(vector2.Y - 2 * value))
                    value24, value25 = value20, value21
                    value35 = Vector2.new(value * value33, value * value33)
                else
                    value24, value25 = value69, value70
                    if value71 then
                        value35 = value71
                    end
                end
                helper50()
            end
        )
        helper49(
            3,
            function(argument2)
                helper31(helper29(argument2, "x", 14, theme.TextMuted, { ZIndex = 5 }))
            end,
            "Close the menu. The menu key opens it again.",
            function()
                if value3.onClose then
                    value3.onClose()
                end
            end
        )
        do
            local value72, value73
            helper6(header.InputBegan, function(argument2)
                if helper32(argument2) then
                    if context.pressOnTop(value30, argument2) then
                        local value
                        value, value72 =
                            Vector2.new(argument2.Position.X, argument2.Position.Y) - value35, true
                        value73 = value
                    end
                end
            end)
            helper6(userInputService.InputChanged, function(argument2)
                if value72 then
                    if helper33(argument2) then
                        value35 = Vector2.new(argument2.Position.X, argument2.Position.Y) - value73
                    end
                end
            end)
            helper6(userInputService.InputEnded, function(argument2)
                if helper32(argument2) then
                    value72 = false
                end
            end)
            helper6(runService.RenderStepped, function(argument2)
                local vector2 = value35 - value36
                if vector2.Magnitude > 0.35 then
                    local value = value36
                    value36 = value + vector2 * (1 - math.exp(-argument2 * 13))
                    helper39()
                elseif vector2.Magnitude > 0 then
                    value36 = value35
                    helper39()
                end
            end)
        end
        do
            value22 = value5 and 30 or 16
            local value74, value75 =
                helper30(root, {
                    Name = "Resize",
                    AnchorPoint = Vector2.new(1, 1),
                    Position = UDim2.new(1, -4, 1, -4),
                    Size = UDim2.fromOffset(value22, value22),
                    ZIndex = 65,
                }), {}
            for index6 = 0, 2, 1 do
                for index7 = 0, 2 - index6, 1 do
                    value75[#value75 + 1] = helper22("Frame", {
                        Position = UDim2.fromOffset(value22 - 4 - 4 * index6, value22 - 4 - 4 * index7),
                        Size = UDim2.fromOffset(2, 2),
                        BackgroundColor3 = theme.TextMuted,
                        BorderSizePixel = 0,
                        ZIndex = 66,
                    }, value74)
                end
            end
            helper6(value74.MouseEnter, function()
                for index2, entry in ipairs(value75) do
                    entry.BackgroundColor3 = theme.TextPrimary
                end
            end)
            helper6(value74.MouseLeave, function()
                for index2, entry in ipairs(value75) do
                    entry.BackgroundColor3 = theme.TextMuted
                end
            end)
            uiLibrary.tip(value74, "Drag to resize the window.")
            local value76, position, value77, value78
            helper6(value74.InputBegan, function(argument2)
                if helper32(argument2) then
                    local position2
                    position2, value76 = argument2.Position, true
                    position, value77, value78, value67, value68 = position2, value24, value25, false, false
                end
            end)
            helper6(userInputService.InputChanged, function(argument2)
                if value76 then
                    if helper33(argument2) then
                        local vector2, vector3, value, value20, value21 =
                            Vector2.new(argument2.Position.X - position.X, argument2.Position.Y - position.Y)
                                / value33,
                            (value5 and helper36() or helper35()) / value33,
                            math.clamp,
                            math.floor,
                            value77
                        value24 = value(
                            value20(value21 + vector2.X),
                            value16,
                            math.max(value16, math.floor(vector3.X - 20))
                        )
                        value20, value, value21 = math.clamp, math.floor, value78
                        value25 = value20(
                            value(value21 + vector2.Y),
                            value17,
                            math.max(value17, math.floor(vector3.Y - 20))
                        )
                        value30.Size = UDim2.fromOffset(value24, value25)
                    end
                end
            end)
            helper6(userInputService.InputEnded, function(argument2)
                if helper32(argument2) then
                    if value76 then
                        value76 = false
                        helper38()
                    end
                end
            end)
        end
        value23 = value10 + value15 + 1
        value22 = helper22("Frame", {
            Name = "Sidebar",
            Position = UDim2.fromOffset(0, value23),
            Size = UDim2.new(0, value8, 1, -value23),
            BackgroundColor3 = Color3.fromHex("141418"),
            BorderSizePixel = 0,
        }, root)
        helper22("Frame", {
            Name = "Rule",
            Position = UDim2.new(1, -1, 0, 0),
            Size = UDim2.new(0, 1, 1, 0),
            BackgroundColor3 = theme.Hairline,
            BorderSizePixel = 0,
        }, value22)
        local value79 = value5 and 8 or 10
        local value80, value81 = value5 and 40 or icon + 4, 4
        -- v93: the tab list is a ScrollingFrame now, so it scrolls when there are more tabs than fit
        helper49 = helper22("ScrollingFrame", {
            Name = "TabList",
            Position = UDim2.fromOffset(value79, value79),
            Size = UDim2.new(1, -2 * value79, 1, value5 and -16 or -86),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Color3.fromHex("50505f"),
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
        }, value22)
        helper26(helper49, value81)
        local value82 = helper22("Frame", {
            Name = "NavMark",
            Position = UDim2.fromOffset(value5 and 3 or 10, 19),
            Size = UDim2.fromOffset(3, 20),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            ZIndex = 3,
        }, value22)
        helper23(value82, 2)
        uiLibrary.accentGradient(value82, 90)
        local iconGrad, value83 =
            helper22("Frame", {
                Name = "Content",
                Position = UDim2.fromOffset(value8, value23),
                Size = UDim2.new(1, -value8, 1, -value23),
                BackgroundTransparency = 1,
            }, root), value5 and 44 or 60
        local value84 = value5 and 11 or 6
        local value85 = helper22("Frame", {
            Size = UDim2.new(1, -32, 0, value83),
            Position = UDim2.fromOffset(18, 0),
            BackgroundTransparency = 1,
        }, iconGrad)
        local value86 = helper29(
            value85,
            "swords",
            18,
            Color3.new(1, 1, 1),
            { Position = UDim2.fromOffset(0, value5 and 13 or 10) }
        )
        uiLibrary.accentGradient(value86, 45)
        local title = helper28(
            value85,
            "",
            16,
            theme.TextPrimary,
            fontWeight.Bold,
            { Position = UDim2.fromOffset(28, value84), Size = UDim2.new(0.58, -36, 0, 22) }
        )
        icon, value23, stroke, visible =
            theme.TextMuted, fontWeight.Regular, {
                Position = UDim2.fromOffset(28, 28),
                Size = UDim2.new(0.58, -36, 0, 28),
                TextWrapped = true,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextTruncate = Enum.TextTruncate.AtEnd,
            }, not value5
        stroke.Visible = visible
        local textControl2 = helper28(value85, "", 11, icon, value23, stroke)
        helper22("Frame", {
            Position = UDim2.new(0, 18, 0, value83),
            Size = UDim2.new(1, -36, 0, 1),
            BackgroundColor3 = theme.Hairline,
            BorderSizePixel = 0,
        }, iconGrad)
        local value87 = helper22("Frame", {
            Name = "Pages",
            Position = UDim2.fromOffset(0, value83 + 1),
            Size = UDim2.new(1, 0, 1, -(value83 + 1)),
            BackgroundTransparency = 1,
        }, iconGrad)
        value23 = value5 and 30 or 32
        local value88 = helper22("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.new(0.42, 0, 0, value23),
            BackgroundColor3 = theme.SurfaceField,
            BorderSizePixel = 0,
        }, value85)
        helper22("UISizeConstraint", {
            MinSize = Vector2.new(value5 and 150 or 170, value23),
            MaxSize = Vector2.new(value5 and 260 or 300, value23),
        }, value88)
        helper23(value88, radiusMd)
        local value89 = helper24(value88, theme.Hairline, 1)
        local value90 = helper29(
            value88,
            "search",
            15,
            theme.TextMuted,
            { Position = UDim2.fromOffset(10, (value23 - 15) / 2) }
        )
        local textControl3 = helper22("TextBox", {
            Position = UDim2.fromOffset(32, 0),
            Size = UDim2.new(1, -40, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            PlaceholderText = "Search every option...",
            PlaceholderColor3 = theme.TextMuted,
            TextColor3 = theme.TextPrimary,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = false,
        }, value88)
        uiLibrary.setFont(textControl3, "sans", fontWeight.Medium)
        local value91, value92, value93, value94 = getService("TextService"), 0, 0, {}
        local value95 = value5 and 2 or 4
        local function helper51(argument2)
            if value5 then
                return value84
            end
            local value = value94[argument2 or textControl2.Text]
            if value then
                if value.w == value93 then
                    if value.lines <= 1 then
                        return math.floor((value83 - 33) / 2)
                    end
                end
            end
            return value84
        end
        local function helper52(argument2)
            local value, value20 = helper51(), value94[textControl2.Text]
            textControl2.TextSize = value20 and value20.w == value93 and value20.size or 11
            if argument2 == "now" then
                title.Position, textControl2.Position, value86.Position =
                    UDim2.fromOffset(28, value),
                    UDim2.fromOffset(28, value + 22),
                    UDim2.fromOffset(0, value + value95)
                return
            end
            if argument2 then
                title.Position, textControl2.Position =
                    UDim2.fromOffset(28, value + argument2), UDim2.fromOffset(28, value + 22 + argument2)
            end
            twd(title, 0.4, { Position = UDim2.fromOffset(28, value) })
            twd(textControl2, 0.4, { Position = UDim2.fromOffset(28, value + 22) }, argument2 and 0.05 or 0)
            helper34(value86, 0.3, { Position = UDim2.fromOffset(0, value + value95) })
        end
        local function helper53(text, width)
            local function helper42(size)
                local success, value = pcall(function()
                    local textControl4 = Instance.new("GetTextBoundsParams")
                    textControl4.Text, textControl4.Font = text, textControl2.FontFace
                    textControl4.Size = size
                    textControl4.Width = width
                    return value91:GetTextBoundsAsync(textControl4).Y
                end)
                return success and value or nil
            end
            local value20 = helper42(11)
            if not value20 then
                return nil
            end
            if value20 <= 28 then
                return { w = width, size = 11, lines = math.max(1, math.floor(value20 / 11 + 0.5)) }
            end
            value20 = helper42(10) or 20
            return { w = width, size = 10, lines = math.max(1, math.floor(value20 / 10 + 0.5)) }
        end
        local value96 = {}
        local function helper54()
            local value = math.max(120, math.floor(value85.AbsoluteSize.X - value88.AbsoluteSize.X - 28 - 14))
            title.Size = UDim2.new(0, value, 0, 22)
            textControl2.Size = UDim2.new(0, value, 0, 28)
            value93 = value
            value92 += 1
            local value20, value21 = value92, {}
            argumentHelpers:appendValues(value21, 0, textControl2.Text)
            for entry in pairs(value96) do
                if entry ~= textControl2.Text then
                    value21[#value21 + 1] = entry
                end
            end
            task.spawn(function()
                for index2, entry2 in ipairs(value21) do
                    if value20 ~= value92 then
                        return
                    end
                    index2 = value94[entry2]
                    if entry2 ~= "" then
                        if index2 then
                            if index2.w ~= value then
                                value94[entry2] = helper53(entry2, value)
                            end
                        else
                            value94[entry2] = helper53(entry2, value)
                        end
                    end
                end
                if value20 == value92 then
                    helper52(nil)
                end
            end)
        end
        value85:GetPropertyChangedSignal("AbsoluteSize"):Connect(helper54)
        value88:GetPropertyChangedSignal("AbsoluteSize"):Connect(helper54)
        local function label()
            value96[textControl2.Text] = true
            helper54()
        end
        textControl2:GetPropertyChangedSignal("Text"):Connect(label)
        task.defer(helper54)
        local value97, value98, value99 = context.shellTabs or {}, {}, nil
        local value100, value101, value102, selectTab = false, false, false
        for index8, entry3 in ipairs(value97) do
            local frame = helper30(helper49, {
                LayoutOrder = index8,
                Size = UDim2.new(1, 0, 0, value80),
                BackgroundColor3 = theme.SurfaceElement,
                BackgroundTransparency = 1,
            })
            helper23(frame, radiusMd)
            stroke = helper24(frame, theme.Hairline, 1)
            stroke.Enabled = false
            icon = helper29(
                frame,
                entry3.icon,
                value5 and 18 or 16,
                theme.TextSub,
                { Position = UDim2.fromOffset(13, 11) }
            )
            if value5 then
                helper31(icon)
            end
            iconGrad = uiLibrary.accentGradient(icon, 45)
            iconGrad.Enabled = false
            label = helper28(frame, entry3.name, 13, theme.TextSub, fontWeight.Medium, {
                Position = UDim2.fromOffset(40, 0),
                Size = UDim2.new(1, -44, 1, 0),
                TextTruncate = Enum.TextTruncate.AtEnd,
            })
            if value5 then
                label.Visible = false
                uiLibrary.tip(frame, entry3.name)
            end
            value98[entry3.id] = {
                frame = frame,
                stroke = stroke,
                icon = icon,
                iconGrad = iconGrad,
                label = label,
                index = index8,
            }
            helper6(frame.MouseEnter, function()
                local value = value99
                if value ~= entry3.id then
                    helper34(frame, 0.14, { BackgroundTransparency = 0.4 })
                end
            end)
            helper6(frame.MouseLeave, function()
                local value = value99
                if value ~= entry3.id then
                    helper34(frame, 0.2, { BackgroundTransparency = 1 })
                end
            end)
            helper6(frame.Activated, function()
                selectTab(entry3.id)
            end)
            value23 = helper22("Frame", {
                Name = entry3.id,
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Visible = false,
            }, value87)
            local body = helper22("ScrollingFrame", {
                Name = "Body",
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ScrollBarThickness = 4,
                ScrollBarImageColor3 = Color3.fromHex("50505f"),
                CanvasSize = UDim2.new(),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ScrollingDirection = Enum.ScrollingDirection.Y,
            }, value23)
            if value5 then
                helper25(body, 8, 10, 16, 10)
            else
                helper25(body, 12, 18, 24, 18)
            end
            helper26(body, 10)
            value3.pages[entry3.id] = { frame = value23, body = body, tab = entry3 }
            value3.order[index8] = entry3.id
        end
        local function helper55(argument2, argument3)
            local value = value98[argument2]
            if not value then
                return
            end
            local value20, value21 =
                value79 + (value.index - 1) * (value80 + value81) + (value80 - 20) / 2, value5 and 3 or 10
            -- v93: follow the scrolled tab list, and hide the marker while its tab is scrolled out of view
            value20 = value20 - helper49.CanvasPosition.Y
            local listH = helper49.AbsoluteSize.Y
            value82.Visible = listH <= 0 or (value20 >= value79 - 4 and value20 + 20 <= value79 + listH + 4)
            if argument3 then
                twd(
                    value82,
                    0.38,
                    { Position = UDim2.fromOffset(value21, value20) },
                    0,
                    Enum.EasingStyle.Back
                )
            else
                value82.Position = UDim2.fromOffset(value21, value20)
            end
        end
        helper49:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
            if value99 then
                helper55(value99, false)
            end
        end)
        selectTab = function(argument2, argument3)
            if value99 == argument2 then
                return
            end
            value99 = argument2
            local value
            for key, page in pairs(value3.pages) do
                page.frame.Visible = key == argument2
                if key == argument2 then
                    if not argument3 then
                        page.frame.Position = UDim2.fromOffset(18, 0)
                        local frame2, value20 = page.frame, {}
                        value20.Position = UDim2.fromOffset(0, 0)
                        twd(frame2, 0.4, value20)
                    end
                    value = page
                end
            end
            for key2, entry in pairs(value98) do
                local enabled, value21, value42 = key2 == argument2, entry.frame, {}
                value42.BackgroundTransparency = enabled and 0 or 1
                helper34(value21, 0.2, value42)
                entry.stroke.Enabled = enabled
                value42, value21 = entry.label, {}
                value21.TextColor3 = enabled and theme.TextPrimary or theme.TextSub
                helper34(value42, 0.2, value21)
                uiLibrary.setFont(entry.label, "sans", enabled and fontWeight.SemiBold or fontWeight.Medium)
                entry.iconGrad.Enabled = enabled
                entry.icon.ImageColor3 = enabled and Color3.new(1, 1, 1) or theme.TextSub
            end
            helper55(argument2, value100)
            value100 = true
            argument2 = value and value.tab
            if argument2 then
                title.Text, textControl2.Text = argument2.name, argument2.desc
                value86.Image = "rbxassetid://"
                    .. tostring(({
                        swords = 10734975692,
                        users = 10747373426,
                        shield = 10734951847,
                        coins = 10709811110,
                        bell = 10709775704,
                        eye = 10723346959,
                    })[argument2.icon] or 10723415903)
            end
            if argument3 then
                helper52("now")
            end
            if not argument3 then
                title.TextTransparency = 1
                textControl2.TextTransparency = 1
                value86.ImageTransparency = 1
                helper52(6)
                twd(title, 0.4, { TextTransparency = 0 })
                twd(textControl2, 0.4, { TextTransparency = 0 }, 0.05)
                twd(value86, 0.35, { ImageTransparency = 0 })
                if value then
                    if value102 then
                        if value.body.CanvasPosition.Y < 2 then
                            helper47(value.body)
                        end
                    end
                end
            end
        end
        value3.selectTab = selectTab
        value3.page = function(name2, argument2, desc)
            local value = value3.pages[name2]
            if not value then
                local value20, tab =
                    #value3.order + 1,
                    { id = name2, name = argument2 or name2, icon = "info", desc = desc or "" }
                value97[#value97 + 1] = tab
                local frame2 = helper22("Frame", {
                    Name = name2,
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    Visible = false,
                }, value87)
                local body2 = helper22("ScrollingFrame", {
                    Name = "Body",
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ScrollBarThickness = 4,
                    ScrollBarImageColor3 = Color3.fromHex("50505f"),
                    CanvasSize = UDim2.new(),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ScrollingDirection = Enum.ScrollingDirection.Y,
                }, frame2)
                if value5 then
                    helper25(body2, 8, 10, 16, 10)
                else
                    helper25(body2, 12, 18, 24, 18)
                end
                helper26(body2, 10)
                value = { frame = frame2, body = body2, tab = tab }
                value3.pages[name2] = value
                value3.order[value20] = name2
            end
            if desc then
                if desc ~= "" then
                    if not value.tab.descFixed then
                        value.tab.desc = desc
                    end
                end
            end
            return {
                frame = value.frame,
                body = value.body,
                title = title,
                header = header,
                fit = function() end,
                isPinned = function()
                    return false
                end,
                setPinned = function() end,
            }
        end
        value3.menuPage = function(argument2)
            local value = value3.pages[argument2]
            return value and value.frame or nil
        end
        value3.menuButton = function(argument2)
            local value = helper30(argument, {
                Name = "MobileMenuButton",
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 14, 0.35, 0),
                Size = UDim2.fromOffset(52, 52),
                BackgroundColor3 = theme.SurfaceHeader,
                BackgroundTransparency = 0,
                ZIndex = 60,
            })
            helper23(value, radiusLg)
            helper24(value, theme.Hairline, 1)
            local value20 = helper22("CanvasGroup", {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, radiusLg + value10),
                ZIndex = 61,
            }, value)
            helper23(value20, radiusLg)
            uiLibrary.accentGradient(
                helper22("Frame", {
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, value10),
                    ZIndex = 61,
                }, value20),
                0
            )
            local value21, value42 = #value40[1] * 2, #value40 * 2
            value20 = helper22("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(
                    math.floor((52 - value21) / 2),
                    math.floor((52 - value42) / 2) + 1
                ),
                Size = UDim2.fromOffset(value21, value42),
                ZIndex = 61,
            }, value)
            for index2 = 1, #value40, 1 do
                for index3 = 1, #value40[1], 1 do
                    if value40[index2]:sub(index3, index3) == "#" then
                        helper22("Frame", {
                            BackgroundColor3 = theme.AccentB,
                            BorderSizePixel = 0,
                            Position = UDim2.fromOffset((index3 - 1) * 2, (index2 - 1) * 2),
                            Size = UDim2.fromOffset(2, 2),
                            ZIndex = 61,
                        }, value20)
                    end
                end
            end
            helper6(value.MouseEnter, function()
                helper34(value, 0.14, { BackgroundColor3 = theme.SurfaceHover })
            end)
            helper6(value.MouseLeave, function()
                helper34(value, 0.2, { BackgroundColor3 = theme.SurfaceHeader })
            end)
            pressable(value)
            helper6(value.Activated, argument2)
            return value
        end
        for index9, entry4 in ipairs(value97) do
            entry4.descFixed = true
        end
        do
            local value107 = helper22("Frame", {
                AnchorPoint = Vector2.new(0, 1),
                Position = UDim2.new(0, 10, 1, -10),
                Size = UDim2.new(1, -20, 0, 50),
                BackgroundColor3 = theme.SurfaceElement,
                BorderSizePixel = 0,
                Visible = visible,
            }, value22)
            helper23(value107, radiusMd)
            helper24(value107, theme.Hairline, 1)
            local value108 = helper22("ImageLabel", {
                Position = UDim2.fromOffset(9, 9),
                Size = UDim2.fromOffset(32, 32),
                BackgroundColor3 = theme.SurfaceField,
                Image = "",
            }, value107)
            helper23(value108, 16)
            task.spawn(function()
                local success, image = pcall(function()
                    local userId, headShot, size48X48 =
                        localPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48
                    return sharedValue5:GetUserThumbnailAsync(userId, headShot, size48X48)
                end)
                if success then
                    if value108.Parent then
                        value108.Image = image
                    end
                end
            end)
            local textControl10 = helper28(value107, "", 12, theme.TextPrimary, fontWeight.SemiBold, {
                Position = UDim2.fromOffset(50, 8),
                Size = UDim2.new(1, -56, 0, 18),
                TextTruncate = Enum.TextTruncate.AtEnd,
            })
            helper28(
                value107,
                tostring(ver),
                11,
                theme.TextMuted,
                fontWeight.Medium,
                { Position = UDim2.fromOffset(50, 26), Size = UDim2.new(1, -56, 0, 16) }
            )
            local function helper60()
                local value = config.streamer == true
                textControl10.Text = value and tostring(config.streamerNameText or "")
                    or (localPlayer.DisplayName ~= "" and localPlayer.DisplayName or localPlayer.Name)
                value108.ImageTransparency = value and 1 or 0
            end
            helper60()
            task.spawn(function()
                while true do
                    local destroyed = runtimeState.destroyed
                    if not (if destroyed then not destroyed else value107.Parent) then
                        break
                    end
                    task.wait(1)
                    pcall(helper60)
                end
            end)
        end
        local value109 = {}
        local value110 = helper22("Frame", {
            Name = "FlashLayer",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            ZIndex = 19,
        }, value87)
        local function helper61(argument2)
            local value = helper22("Frame", {
                BackgroundColor3 = theme.AccentB,
                BackgroundTransparency = 0.8,
                BorderSizePixel = 0,
                ZIndex = 20,
            }, value110)
            helper23(value, radiusMd)
            local value20 = helper24(value, theme.AccentMid, 1.5)
            local function helper42()
                if not argument2.Parent then
                    return
                end
                local value21 = value31.Scale > 0 and value31.Scale or 1
                local vector2 = (argument2.AbsolutePosition - value110.AbsolutePosition) / value21
                value.Position = UDim2.fromOffset(vector2.X, vector2.Y)
                value.Size =
                    UDim2.fromOffset(argument2.AbsoluteSize.X / value21, argument2.AbsoluteSize.Y / value21)
            end
            helper42()
            local connection = runService.RenderStepped:Connect(helper42)
            helper34(value, 1.2, { BackgroundTransparency = 1 })
            helper34(value20, 1.2, { Transparency = 1 })
            task.delay(1.3, function()
                connection:Disconnect()
                value:Destroy()
            end)
        end
        local function helper62()
            local value, value20 = {}, {}
            for index2, entry in ipairs(value3.order) do
                index2 = value3.pages[entry]
                for index3, descendant in ipairs(index2.body:GetDescendants()) do
                    local label2, frame2
                    if
                        descendant:IsA("Frame")
                        and (
                            descendant.Name == "Row"
                            or descendant.Name == "Slider"
                            or descendant.Name == "RangeSlider"
                            or descendant.Name == "ListInput"
                        )
                    then
                        index3 = descendant:FindFirstChildWhichIsA("TextLabel")
                            or descendant:FindFirstChild("Head")
                                and descendant.Head:FindFirstChildWhichIsA("TextLabel", true)
                        if index3 then
                            if index3.Text ~= "" then
                                local text = index3.Text
                                label2, frame2 = text, descendant
                            end
                        end
                    else
                        if descendant:IsA("TextButton") then
                            if descendant.Name == "Button" then
                                if descendant.Text ~= "" then
                                    local text2 = descendant.Text
                                    label2, frame2 = text2, descendant
                                end
                            end
                        end
                    end
                    if label2 then
                        if frame2 then
                            index3 = entry .. "|" .. label2
                            if not value20[index3] then
                                value20[index3] = true
                                local value21, value42 =
                                    #value + 1,
                                    { label = label2, frame = frame2, page = entry, tab = index2.tab }
                                value42.hint, value[value21] =
                                    context.tipTextOf and context.tipTextOf(frame2) or "", value42
                            end
                        end
                    end
                end
            end
            return value
        end
        local function helper63(argument2)
            helper43()
            textControl3:ReleaseFocus()
            selectTab(argument2.page, true)
            task.defer(function()
                local parent = argument2.frame.Parent
                while parent and parent ~= value3.pages[argument2.page].body do
                    local value = value3.sections[parent]
                    if value then
                        if not (value.isOpen()) then
                            value.setOpen(true)
                        end
                    end
                    parent = parent.Parent
                end
                task.wait(0.4)
                local body2 = value3.pages[argument2.page].body
                if argument2.frame.Parent then
                    local value20 = (argument2.frame.AbsolutePosition.Y - body2.AbsolutePosition.Y) / value33
                        + body2.CanvasPosition.Y
                        - 18
                    helper34(body2, 0.35, { CanvasPosition = Vector2.new(0, math.max(0, value20)) })
                    task.delay(0.3, function()
                        if argument2.frame.Parent then
                            helper61(argument2.frame)
                        end
                    end)
                end
            end)
        end
        local function helper64(argument2)
            for index2, child in ipairs(value59:GetChildren()) do
                if child ~= value60 then
                    child:Destroy()
                end
            end
            local value, value20, value21 =
                string.lower(textControl3.Text):gsub("^%s+", ""):gsub("%s+$", ""), helper62(), {}
            if value == "" then
            else
                for index4, entry2 in ipairs(value20) do
                    index4 = string.lower(entry2.label)
                    local value43 = index4:sub(1, #value) == value and 3
                        or index4:find(value, 1, true) and 2
                        or string.lower(entry2.hint or ""):find(value, 1, true) and 1
                        or 0
                    if value43 > 0 then
                        value21[#value21 + 1] = { e = entry2, s = value43 }
                    end
                end
                table.sort(value21, function(argument3, argument4)
                    if argument3.s ~= argument4.s then
                        return argument3.s > argument4.s
                    end
                    return argument3.e.label < argument4.e.label
                end)
                for index5, entry5 in ipairs(value21) do
                    value21[index5] = entry5.e
                end
            end
            value109 = value21
            value59.Visible = true
            local value44, value45 = helper41(value88.AbsolutePosition), value88.AbsoluteSize.X / value33
            local value46 = helper22("Frame", {
                Position = UDim2.fromOffset(value44.X, value44.Y + 36),
                Size = UDim2.fromOffset(value45, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = theme.SurfaceField,
                BorderSizePixel = 0,
                ZIndex = 51,
            }, value59)
            helper23(value46, radiusMd)
            helper24(value46, theme.Hairline, 1)
            helper25(value46, 4)
            local value47 = helper26(value46, 2)
            if argument2 then
                task.defer(function()
                    if value46.Parent then
                        value46.Visible = false
                        slideTo(value46, value47, 8, true)
                    end
                end)
            end
            value44, value20, argument2, value45 =
                value == "" and "Type to search"
                    or (
                        #value21 == 0 and "Nothing called that."
                        or #value21 .. (#value21 == 1 and " option" or " options")
                    ),
                theme.TextMuted,
                fontWeight.SemiBold,
                { LayoutOrder = 0 }
            value45.Size, value45.ZIndex = UDim2.new(1, 0, 0, 20), 52
            helper28(value46, value44, 10, value20, argument2, value45)
            for index10 = 1, math.min(#value21, value5 and 6 or 8), 1 do
                local value48 = value21[index10]
                local value49 = helper30(value46, {
                    LayoutOrder = index10,
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundColor3 = index10 == 1 and theme.SurfaceHover or theme.SurfaceElement,
                    BackgroundTransparency = 0,
                    ZIndex = 52,
                })
                helper23(value49, 4)
                local textControl4 = helper28(
                    value49,
                    value48.label,
                    12,
                    index10 == 1 and theme.AccentMid or theme.TextSub,
                    fontWeight.Medium,
                    {
                        Position = UDim2.fromOffset(10, 0),
                        Size = UDim2.new(1, -120, 1, 0),
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        ZIndex = 53,
                    }
                )
                argument2 = helper22("Frame", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -8, 0.5, 0),
                    Size = UDim2.fromOffset(106, 18),
                    BackgroundTransparency = 1,
                    ZIndex = 53,
                }, value49)
                helper27(argument2, 4, true)
                helper29(argument2, value48.tab.icon, 12, theme.TextMuted, { LayoutOrder = 1, ZIndex = 53 })
                helper28(argument2, value48.tab.name, 11, theme.TextMuted, fontWeight.Medium, {
                    LayoutOrder = 2,
                    Size = UDim2.fromOffset(0, 18),
                    AutomaticSize = Enum.AutomaticSize.X,
                    ZIndex = 53,
                })
                helper6(value49.MouseEnter, function()
                    value49.BackgroundColor3 = theme.SurfaceHover
                    textControl4.TextColor3 = theme.AccentMid
                end)
                helper6(value49.MouseLeave, function()
                    value49.BackgroundColor3 = index10 == 1 and theme.SurfaceHover or theme.SurfaceElement
                    textControl4.TextColor3 = index10 == 1 and theme.AccentMid or theme.TextSub
                end)
                helper6(value49.Activated, function()
                    helper63(value48)
                end)
            end
        end
        helper6(textControl3.Focused, function()
            if not value101 then
                task.defer(function()
                    pcall(function()
                        textControl3:ReleaseFocus()
                    end)
                end)
                return
            end
            value89.Color = theme.AccentMid
            value90.ImageColor3 = theme.AccentMid
            helper64(true)
        end)
        helper6(textControl3.FocusLost, function(argument2)
            value89.Color = theme.Hairline
            value90.ImageColor3 = theme.TextMuted
            if argument2 then
                if value109[1] then
                    helper63(value109[1])
                    return
                end
            end
            task.delay(0.35, function()
                if not (textControl3:IsFocused()) then
                    helper43()
                end
            end)
        end)
        helper6(textControl3:GetPropertyChangedSignal("Text"), function()
            if textControl3:IsFocused() then
                helper64(false)
            end
        end)
        local value111 = helper22("Frame", {
            Name = "HLNotifications",
            AnchorPoint = value5 and Vector2.new(1, 0) or Vector2.new(1, 1),
            Position = value5 and UDim2.new(1, -12, 0, 12) or UDim2.new(1, -16, 1, -16),
            Size = UDim2.fromOffset(312, 520),
            BackgroundTransparency = 1,
            ZIndex = 80,
        }, argument)
        value111:SetAttribute("HLUIMotionOwned", true)
        value38 = helper22("UIScale", { Scale = helper40() }, value111)
        icon = helper26(value111, 8)
        icon.VerticalAlignment, icon.HorizontalAlignment =
            value5 and Enum.VerticalAlignment.Top or Enum.VerticalAlignment.Bottom,
            Enum.HorizontalAlignment.Right
        local value112 = {
            info = { icon = "bell" },
            party = { icon = "users" },
            run = { icon = "swords" },
            sell = {
                icon = "coins",
            },
        }
        value112.success = { icon = "check", color = Color3.fromHex("2FBF71") }
        value112.warning = { icon = "alert-triangle", color = Color3.fromHex("FFB020") }
        value112.error = { icon = "x", color = Color3.fromHex("FF4D4F") }
        value112.drop = { icon = "crown", color = Color3.fromHex("FFA028") }
        value112.dropUltimate = { icon = "crown", color = Color3.fromHex("FF3B3B") }
        local value113, value114 = {}, {}
        local function helper65(argument2)
            if argument2.gone then
                return
            end
            argument2.gone = true
            local card, value = argument2.card, {}
            value.Position, value.GroupTransparency = UDim2.fromOffset(330, 0), 1
            helper34(card, 0.28, value)
            task.delay(0.22, function()
                if argument2.slot.Parent then
                    local slot, value20 = argument2.slot, {}
                    value20.Size = UDim2.fromOffset(300, 0)
                    helper34(slot, 0.2, value20)
                end
            end)
            task.delay(0.5, function()
                argument2.slot:Destroy()
            end)
            for index2, entry in ipairs(value113) do
                if entry == argument2 then
                    table.remove(value113, index2)
                    break
                end
            end
        end
        local function notify(slot, argument2, argument3, argument4, argument5)
            if config.notifications == false then
                return
            elseif runtimeState.destroyed then
                return
            end
            argument2, argument3, argument5 =
                tostring(argument2 or ""),
                tostring(argument3 or ""),
                type(argument5) == "table" and argument5 or {}
            local value = argument2 .. "|" .. argument3
            if not argument5.sticky then
                if value114[value] then
                    if os.clock() - value114[value] < 4 then
                        return
                    end
                end
            end
            value114[value] = os.clock()
            argument4 = argument4 or 5
            local value20, value21, card =
                value112[slot] or value112.info,
                argument5.button and 100 or 66,
                math.floor(os.clock() * 1000) % 2000000000
            slot = helper22("Frame", {
                Name = "Notification",
                Size = UDim2.fromOffset(300, 0),
                BackgroundTransparency = 1,
                LayoutOrder = value5 and -card or card,
            }, value111)
            card = helper22("CanvasGroup", {
                Size = UDim2.fromOffset(300, value21),
                Position = UDim2.fromOffset(330, 0),
                BackgroundColor3 = theme.SurfaceHeader,
                BorderSizePixel = 0,
                GroupTransparency = 1,
            }, slot)
            helper23(card, radiusMd)
            helper24(card, theme.Hairline, 1)
            local textControl4 = helper28(card, argument2, 13, theme.TextPrimary, fontWeight.SemiBold, {
                Position = UDim2.fromOffset(14, 11),
                Size = UDim2.new(1, -72, 0, 18),
                TextTruncate = Enum.TextTruncate.AtEnd,
            })
            local textControl11 = helper28(card, argument3, 11, theme.TextSub, fontWeight.Regular, {
                Position = UDim2.fromOffset(14, 30),
                Size = UDim2.new(1, -72, 0, 28),
                TextWrapped = true,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextTruncate = Enum.TextTruncate.AtEnd,
            })
            value = helper22("Frame", {
                AnchorPoint = argument5.button and Vector2.new(1, 0) or Vector2.new(1, 0.5),
                Position = argument5.button and UDim2.new(1, -12, 0, 12) or UDim2.new(1, -12, 0.5, 1),
                Size = UDim2.fromOffset(34, 34),
                BackgroundColor3 = theme.SurfaceElement,
                BorderSizePixel = 0,
            }, card)
            helper23(value, radiusMd)
            helper24(value, theme.Hairline, 1)
            local value42, value43 =
                helper31(helper29(value, value20.icon, 17, value20.color or theme.AccentMid)),
                helper22("Frame", {
                    AnchorPoint = Vector2.new(0, 1),
                    Position = UDim2.new(0, 0, 1, 0),
                    Size = UDim2.new(1, 0, 0, 2),
                    BackgroundColor3 = value20.color or Color3.new(1, 1, 1),
                    BorderSizePixel = 0,
                }, card)
            if value20.color then
                value42:SetAttribute("HLThemeSkip", true)
                value43:SetAttribute("HLThemeSkip", true)
            else
                uiLibrary.accentGradient(value43, 0)
            end
            local value44, value45 =
                helper30(card, { Size = UDim2.fromScale(1, 1), ZIndex = 5 }), { slot = slot, card = card }
            value45.sticky = argument5.sticky == true
            value113[#value113 + 1] = value45
            while #value113 > 5 do
                value42 = value113[1]
                for index2, entry in ipairs(value113) do
                    if not entry.sticky then
                        value42 = entry
                        break
                    end
                end
                helper65(value42)
            end
            local function button()
                helper65(value45)
            end
            value44.Activated:Connect(button)
            value45.set = function(argument6, argument7)
                if argument6 ~= nil then
                    textControl4.Text = tostring(argument6)
                end
                if argument7 ~= nil then
                    textControl11.Text = tostring(argument7)
                end
            end
            value45.close = function()
                helper65(value45)
            end
            if argument5.button then
                local button2 = argument5.button
                button = uiLibrary.button(card, tostring(button2.text or "OK"), "accent")
                button.Size, button.Position = UDim2.fromOffset(104, 26), UDim2.fromOffset(14, 62)
                button.ZIndex = 6
                value, value20 = button:FindFirstChild("Fill"), button:FindFirstChild("Label")
                if value then
                    value.ZIndex = 6
                end
                if value20 then
                    value20.ZIndex = 7
                    value20.TextSize = 12
                end
                value45.button = button
                local function helper42()
                    if value45.gone then
                        return
                    elseif value45.busy then
                        return
                    end
                    value45.busy = true
                    if type(button2.onClick) == "function" then
                        pcall(button2.onClick, value45)
                    end
                end
                button.MouseButton1Click:Connect(helper42)
            end
            helper34(slot, 0.22, { Size = UDim2.fromOffset(300, value21) })
            helper34(card, 0.38, { Position = UDim2.fromOffset(0, 0), GroupTransparency = 0 })
            if value45.sticky then
                value43.Visible = false
            else
                value20, value21 = TweenInfo.new, Enum.EasingStyle
                value, value44 = value20(argument4, value21.Linear), {}
                value44.Size = UDim2.new(0, 0, 0, 2)
                value2:Create(value43, value, value44):Play()
                task.delay(argument4, function()
                    helper65(value45)
                end)
            end
            return value45
        end
        function context.notify(...)
            return (pcall(notify, ...))
        end
        function context.notifyCard(...)
            local success, value = pcall(notify, ...)
            if success then
                return value
            end
            return nil
        end
        value3.notify = notify
        local parent3
        local value116 = 0
        local function helper67(argument2, argument3)
            value116 += 1
            local value = value116
            if not parent3 then
                parent3 = helper22("CanvasGroup", {
                    Name = "Fader",
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    GroupTransparency = argument2 and 1 or 0,
                }, value30)
                root.Parent = parent3
            end
            value30.Visible = true
            local valueObject = Instance.new("NumberValue")
            local value20 = argument2 and (value37 < 0.999 and value37 or 0.9)
            valueObject.Value = value20 or value37
            value37 = valueObject.Value
            helper39()
            local connection = valueObject.Changed:Connect(function(argument4)
                value37 = argument4
                helper39()
            end)
            local value21, value42 = TweenInfo.new, argument2 and 0.5
            local value43, value44 = value42 or 0.2, argument2 and Enum.EasingStyle.Back
            value20, value42 = value44 or Enum.EasingStyle.Quad, argument2 and Enum.EasingDirection.Out
            local value45, value46 = value21(value43, value20, value42 or Enum.EasingDirection.In), {}
            value46.Value = argument2 and 1 or 0.93
            value2:Create(valueObject, value45, value46):Play()
            value46, value45, value21 = parent3, TweenInfo.new, argument2 and 0.28
            value20, value43 = value21 or 0.18, Enum.EasingStyle
            value44, value21 = value45(value20, value43.Quad), {}
            value21.GroupTransparency = argument2 and 0 or 1
            value2:Create(value46, value44, value21):Play()
            for index2, child in ipairs(value32:GetChildren()) do
                value42, value44 = argument2 and 0.4 or 0.2, {}
                value44.BackgroundTransparency = argument2 and 0.96 or 1
                helper34(child, value42, value44)
            end
            task.delay(argument2 and 0.52 or 0.22, function()
                connection:Disconnect()
                valueObject:Destroy()
                if value ~= value116 then
                    return
                end
                if argument2 then
                    value37 = 1
                    helper39()
                    root.Parent = value30
                    if parent3 then
                        parent3:Destroy()
                        parent3 = nil
                    end
                else
                    value30.Visible = false
                    pcall(function()
                        local value47 = userInputService:GetFocusedTextBox()
                        if value47 then
                            if value30:IsAncestorOf(value47) then
                                value47:ReleaseFocus()
                            end
                        end
                    end)
                end
                if argument3 then
                    argument3()
                end
            end)
        end
        value3.isShown = function()
            local value = value101
            return value
        end
        value3.setShown = function(argument2)
            argument2 = argument2 == true
            if argument2 == value101 then
                return
            end
            value101 = argument2
            if not argument2 then
                helper43()
                pcall(uiLibrary.hideTip)
                pcall(function()
                    local value = userInputService:GetFocusedTextBox()
                    if value then
                        if value30:IsAncestorOf(value) then
                            value:ReleaseFocus()
                        end
                    end
                end)
            end
            helper67(argument2)
            if argument2 then
                if not value99 then
                    selectTab(value3.order[1], true)
                end
                local value20 = value99 and value3.pages[value99]
                if value20 and value102 then
                    if value20.body.CanvasPosition.Y < 2 then
                        task.defer(function()
                            helper47(value20.body)
                        end)
                    end
                end
            end
        end
        value3.finish = function()
            for index2, entry in ipairs(value97) do
                if entry.desc then
                    if entry.desc ~= "" then
                        value96[entry.desc] = true
                    end
                end
            end
            helper54()
            value102 = true
            if not value99 then
                selectTab(value3.order[1], true)
            end
        end
        return value3
    end
end


-- ============================================================
--  VISUALS TAB  (ported from the original script's Visuals tab)
--  Sections: Color theme, Streamer mode, Notifications, Screen, Item cards
-- ============================================================
components.visuals = function(context, shell, gui)
    local uiLibrary = context.UIKit
    local theme = uiLibrary.Theme
    local config = context.CFG
    local runtimeState = context.RT
    local localPlayer = context.LocalPlayer
    local userInputService = context.UserInputService
    local runService = context.RunService
    local sliderConnections = context.sliderConnections
    local pageBody = shell.pages.Visuals.body
    runtimeState.scriptGui = gui

    ----------------------------------------------------------
    -- saved settings (only the Visuals keys)
    ----------------------------------------------------------
    local SAVE_FILE = "EatTheWorld/visuals.json"
    local PERSIST = {
        "notifications", "renderOff", "fpsCap", "fpsCapValue", "fpsUncap",
        "itemStatsAbbrev", "upgradeCountAbbrev", "colorTheme", "colorThemeBase",
        "streamer", "streamerName", "streamerHealth", "streamerBody", "streamerBodyColor",
        "streamerOthers", "streamerLeaderboard", "streamerChat", "streamerLevel", "streamerWealth",
        "streamerNameText", "streamerHealthText", "streamerLevelText",
        "streamerGoldText", "streamerGemsText", "streamerXpText",
        "hud", "minimap", "mapButton", "mapFollow", "minimapSmooth",
        "mapAttackOneColor", "mapAttackRainbow", "mapAttackColor", "mapKey",
    }
    local DEFAULTS = {
        notifications = true, renderOff = false,
        fpsCap = false, fpsCapValue = 60, fpsUncap = false,
        itemStatsAbbrev = true, upgradeCountAbbrev = true,
        streamer = true, streamerName = true, streamerHealth = true, streamerBody = true,
        streamerOthers = false, streamerLeaderboard = false, streamerChat = true,
        streamerLevel = true, streamerWealth = true,
        streamerNameText = "harvard student", streamerHealthText = "999,999",
        streamerLevelText = "999", streamerGoldText = "999,999",
        streamerGemsText = "999,999", streamerXpText = "999,999,999",
        streamerBodyColor = Color3.fromHex("5bff9c"),
        hud = true, minimap = true, mapButton = true, mapFollow = true, minimapSmooth = true,
        mapAttackOneColor = false, mapAttackRainbow = false, mapKey = "M",
        mapAttackColor = Color3.fromRGB(255, 60, 60),
    }
    for key, value in pairs(DEFAULTS) do
        if config[key] == nil then
            config[key] = value
        end
    end
    local httpService = getService("HttpService")
    do
        local ok, raw = pcall(function()
            if type(isfile) == "function" and isfile(SAVE_FILE) then
                return readfile(SAVE_FILE)
            end
        end)
        if ok and type(raw) == "string" and raw ~= "" then
            local ok2, saved = pcall(function()
                return httpService:JSONDecode(raw)
            end)
            if ok2 and type(saved) == "table" then
                for _, key in ipairs(PERSIST) do
                    local value = saved[key]
                    if value ~= nil then
                        if key == "streamerBodyColor" or key == "mapAttackColor" then
                            if type(value) == "string" then
                                local okc, color = pcall(Color3.fromHex, (value:gsub("^#", "")))
                                if okc then
                                    config[key] = color
                                end
                            end
                        elseif type(value) == type(DEFAULTS[key]) or DEFAULTS[key] == nil then
                            config[key] = value
                        end
                    end
                end
            end
        end
    end
    local saveQueued = false
    local function saveConfig()
        if saveQueued then
            return
        end
        saveQueued = true
        task.delay(0.4, function()
            saveQueued = false
            pcall(function()
                local out = {}
                for _, key in ipairs(PERSIST) do
                    local value = config[key]
                    if typeof(value) == "Color3" then
                        value = "#" .. value:ToHex()
                    end
                    out[key] = value
                end
                if type(makefolder) == "function" and type(isfolder) == "function" and not isfolder("EatTheWorld") then
                    makefolder("EatTheWorld")
                end
                writefile(SAVE_FILE, httpService:JSONEncode(out))
            end)
        end)
    end
    context.saveConfig = saveConfig

    -- every widget registers here so a refresh can redraw them all
    local widgets = {}
    local function helper(widget)
        widgets[#widgets + 1] = widget
        return widget
    end
    context.refreshAll = function()
        for _, widget in ipairs(widgets) do
            if type(widget) == "table" and widget.render then
                pcall(widget.render)
            end
        end
    end
    -- toggle bound to a config key
    local function helper15(parent, label, key, order, tip, onChange)
        return helper(uiLibrary.toggle(parent, label, function()
            return config[key]
        end, function(value)
            config[key] = value
            if onChange then
                onChange(value)
            end
            saveConfig()
        end, order, tip))
    end
    local colorSaveQueued = false
    local function helper16()
        if colorSaveQueued then
            return
        end
        colorSaveQueued = true
        task.delay(0.5, function()
            colorSaveQueued = false
            pcall(saveConfig)
        end)
    end

    ----------------------------------------------------------
    -- Streamer mode backend (hides name / health / level / gold, body block, chat)
    ----------------------------------------------------------
    do
        local visualFolder
        local function visualRoot()
            if visualFolder and visualFolder.Parent then
                return visualFolder
            end
            visualFolder = Instance.new("Folder")
            visualFolder.Name = "EatTheWorldVisuals"
            visualFolder.Parent = workspace
            runtimeState.visualRoot = visualFolder
            return visualFolder
        end
        context.visualRoot = visualRoot

        local sharedValue4 = { saved = {}, box = nil, coreChanged = {} }
        sharedValue4.lastApply = -math.huge
        sharedValue4.on = false
        local sharedValue5 = getService("Players")
        local sharedValue6 = getService("StarterGui")
        local visualRoot = context.visualRoot
        local function helper3(argument, argument2, argument3)
            if argument[argument2] == argument3 then
                return
            end
            local value = sharedValue4.saved[argument]
            if not value then
                value = {}
                sharedValue4.saved[argument] = value
            end
            if value[argument2] == nil then
                value[argument2] = argument[argument2]
            end
            argument[argument2] = argument3
        end
        sharedValue4.fakes = sharedValue4.fakes or {}
        local function helper4(argument, text)
            if argument then
                if not (argument:IsA("TextLabel")) then
                    helper3(argument, "Visible", false)
                    return
                end
            else
                helper3(argument, "Visible", false)
                return
            end
            text = tostring(text or "")
            if text == "" then
                helper3(argument, "Visible", false)
                return
            end
            helper3(argument, "TextTransparency", 1)
            helper3(argument, "TextStrokeTransparency", 1)
            local value = sharedValue4.fakes[argument]
            if if value then not value.Parent else not value then
                value = argument:Clone()
                for index, child in ipairs(value:GetChildren()) do
                    if not (child:IsA("UIStroke")) then
                        if not (child:IsA("UICorner")) then
                            if not (child:IsA("UIGradient")) then
                                if not (child:IsA("UITextSizeConstraint")) then
                                    if not (child:IsA("UIPadding")) then
                                        child:Destroy()
                                    end
                                end
                            end
                        end
                    end
                end
                value.Name = "streamerFake"
                value.TextTransparency, value.TextStrokeTransparency = 0, argument.TextStrokeTransparency
                value.Visible = true
                value.ZIndex = argument.ZIndex + 1
                value.Parent = argument.Parent
                sharedValue4.fakes[argument] = value
            end
            if value.Text ~= text then
                value.Text = text
            end
        end
        sharedValue4.plates = sharedValue4.plates or {}
        sharedValue4.plateKeys = sharedValue4.plateKeys
            or { name = true, title = true, vip = true, healthamount = true, level = true }
        local function helper5(argument)
            local value, value2 = sharedValue4.plates[argument]
            if value then
                value2 = value
            else
                for key, plate in pairs(sharedValue4.plates) do
                    local value3 = game
                    if not (key:IsDescendantOf(value3)) then
                        for index, conn in ipairs(plate.conns) do
                            pcall(conn.Disconnect, conn)
                        end
                        sharedValue4.plates[key] = nil
                    end
                end
                value2 = { list = {}, dirty = true, at = 0, conns = {} }
                local function helper6(argument2)
                    if runtimeState.destroyed then
                        for index2, conn2 in ipairs(value2.conns) do
                            pcall(conn2.Disconnect, conn2)
                        end
                        return
                    end
                    if not value2.dirty then
                        if argument2:IsA("GuiObject") then
                            value2.dirty = true
                        end
                    end
                end
                value2.conns[1] = argument.DescendantAdded:Connect(helper6)
                value2.conns[2] = argument.DescendantRemoving:Connect(helper6)
                sharedValue4.plates[argument] = value2
            end
            local now = os.clock()
            if value2.dirty or now - value2.at > 5 then
                value2.dirty = false
                value2.at = now
                local list, plateKeys = {}, sharedValue4.plateKeys
                for index3, descendant in ipairs(argument:GetDescendants()) do
                    if descendant:IsA("GuiObject") then
                        if descendant.Name ~= "streamerFake" then
                            index3 = string.lower(descendant.Name)
                            if plateKeys[index3] then
                                list[#list + 1] = descendant
                                list[#list + 1] = index3
                            end
                        end
                    end
                end
                value2.list = list
            end
            return value2.list
        end
        local function helper7(argument, argument2)
            if not argument then
                return
            end
            local value = helper5(argument)
            for index = 1, #value, 2 do
                local value2, value3 = value[index], value[index + 1]
                if value3 == "name" then
                    if argument2 then
                        if config.streamerName then
                            helper4(value2, config.streamerNameText)
                        end
                    else
                        helper3(value2, "Visible", false)
                    end
                elseif value3 == "title" or value3 == "vip" then
                    if argument2 then
                        if config.streamerName then
                            helper3(value2, "Visible", false)
                        end
                    else
                        helper3(value2, "Visible", false)
                    end
                end
                if argument2 then
                    if value3 == "healthamount" then
                        if config.streamerHealth then
                            helper4(value2, config.streamerHealthText)
                        end
                    end
                end
                if
                    argument2
                    and value3 == "level"
                    and config.streamerLevel
                    and (config.streamerLevelText or "") ~= ""
                then
                    helper4(value2, config.streamerLevelText)
                elseif value3 == "level" and config.streamerLevel then
                    argument = value2
                    for index2 = 1, 2, 1 do
                        index2 = argument.Parent
                        if index2 then
                            if index2:IsA("GuiObject") then
                                if index2.Parent then
                                    if not (index2.Parent:IsA("GuiObject")) then
                                        break
                                    end
                                else
                                    break
                                end
                            else
                                break
                            end
                        else
                            break
                        end
                        argument = index2
                    end
                    helper3(argument, "Visible", false)
                end
            end
        end
        local function helper8(char)
            local body, body2 = sharedValue4.body
            if if body then body.char ~= char else not body then
                if body then
                    for index, conn in ipairs(body.conns) do
                        pcall(conn.Disconnect, conn)
                    end
                end
                body2 = { char = char, dirty = true, list = {}, conns = {} }
                local function helper6(argument)
                    if runtimeState.destroyed then
                        for index2, conn2 in ipairs(body2.conns) do
                            pcall(conn2.Disconnect, conn2)
                        end
                        return
                    end
                    if body2.dirty then
                        return
                    end
                    if argument:IsA("BasePart") then
                        body2.dirty = true
                    elseif argument:IsA("Decal") then
                        body2.dirty = true
                    elseif argument:IsA("Texture") then
                        body2.dirty = true
                    elseif argument:IsA("ParticleEmitter") then
                        body2.dirty = true
                    elseif argument:IsA("Trail") then
                        body2.dirty = true
                    elseif argument:IsA("Beam") then
                        body2.dirty = true
                    end
                end
                body2.conns[1] = char.DescendantAdded:Connect(helper6)
                body2.conns[2] = char.DescendantRemoving:Connect(helper6)
                sharedValue4.body = body2
            else
                body2 = body
            end
            if body2.dirty then
                body2.dirty = false
                local list = {}
                for index3, descendant in ipairs(char:GetDescendants()) do
                    if descendant:IsA("BasePart") then
                        list[#list + 1] = descendant
                        list[#list + 1] = 1
                    elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
                        list[#list + 1] = descendant
                        list[#list + 1] = 2
                    elseif
                        descendant:IsA("ParticleEmitter")
                        or descendant:IsA("Trail")
                        or descendant:IsA("Beam")
                    then
                        list[#list + 1] = descendant
                        list[#list + 1] = 3
                    end
                end
                body2.list = list
            end
            return body2.list
        end
        local function helper9(streamer)
            local rootPart, value = streamer:FindFirstChild("HumanoidRootPart"), helper8(streamer)
            for index = 1, #value, 2 do
                local value2, value3 = value[index], value[index + 1]
                if value3 == 1 then
                    if value2 ~= rootPart then
                        helper3(value2, "Transparency", 1)
                        helper3(value2, "CastShadow", false)
                    end
                elseif value3 == 2 then
                    helper3(value2, "Transparency", 1)
                else
                    helper3(value2, "Enabled", false)
                end
            end
            if rootPart then
                streamer = sharedValue4.box
                if if streamer then not streamer.Parent else not streamer then
                    streamer = Instance.new("Part")
                    streamer.Name = "streamer"
                    streamer.Anchored = true
                    streamer.CanCollide = false
                    streamer.CanQuery = false
                    streamer.CanTouch = false
                    streamer.CastShadow = false
                    streamer.Material, streamer.Color, streamer.Size =
                        Enum.Material.SmoothPlastic,
                        config.streamerBodyColor or Color3.new(0, 0, 0),
                        Vector3.new(2, 5, 2)
                    streamer.Parent = visualRoot()
                    sharedValue4.box = streamer
                end
                streamer.CFrame = rootPart.CFrame
                if config.streamerBodyColor then
                    if streamer.Color ~= config.streamerBodyColor then
                        streamer.Color = config.streamerBodyColor
                    end
                end
            end
        end
        local function helper10()
            local playerGui = localPlayer:FindFirstChild("PlayerGui")
            if not playerGui then
                return
            end
            local value = playerGui:FindFirstChild("playerStatus")
            value = value and (value:FindFirstChild("Frame"))
            if value then
                local value2, healthFrame =
                    value:FindFirstChild("playerName"), value:FindFirstChild("healthFrame")
                if value2 then
                    if config.streamerName then
                        helper4(value2, config.streamerNameText)
                    end
                end
                if healthFrame then
                    if config.streamerHealth then
                        value2 = healthFrame:FindFirstChild("health")
                        if (config.streamerHealthText or "") ~= "" then
                            if value2 then
                                helper4(value2, config.streamerHealthText)
                            else
                                helper3(healthFrame, "Visible", false)
                            end
                        else
                            helper3(healthFrame, "Visible", false)
                        end
                    end
                end
            end
            if value then
                if config.streamerLevel then
                    local value3 = value:FindFirstChild("portraitBorder")
                    local value4, value5 =
                        value3 and (value3:FindFirstChild("portrait")),
                        context.customLogo and context.customLogo() or nil
                    if value3 then
                        if value5 then
                            if value4 then
                                helper3(value4, "Image", value5)
                                helper3(value4, "ImageColor3", Color3.new(1, 1, 1))
                                helper3(value4, "ScaleType", Enum.ScaleType.Crop)
                            else
                                helper3(value3, "Visible", false)
                            end
                        else
                            helper3(value3, "Visible", false)
                        end
                    end
                    value3 = value:FindFirstChild("levelBorder")
                    value5 = value3 and (value3:FindFirstChild("level"))
                    if (config.streamerLevelText or "") ~= "" then
                        if value5 then
                            helper4(value5, config.streamerLevelText)
                        elseif value3 then
                            helper3(value3, "Visible", false)
                        end
                    elseif value3 then
                        helper3(value3, "Visible", false)
                    end
                end
                if config.streamerWealth then
                    local moneyMain, xpFrame = value:FindFirstChild("moneyMain"), value:FindFirstChild("xpFrame")
                    local value6, value7, value8 =
                        moneyMain and (moneyMain:FindFirstChild("TextLabel")),
                        moneyMain and (moneyMain:FindFirstChild("GemsText")),
                        xpFrame and (xpFrame:FindFirstChild("xp"))
                    if moneyMain then
                        if
                            ((config.streamerGoldText or "") ~= "" or (config.streamerGemsText or "") ~= "")
                            and value6
                        then
                            if value7 then
                                helper4(value6, config.streamerGoldText)
                                helper4(value7, config.streamerGemsText)
                            else
                                helper3(moneyMain, "Visible", false)
                            end
                        else
                            helper3(moneyMain, "Visible", false)
                        end
                    end
                    if xpFrame then
                        if (config.streamerXpText or "") ~= "" and value8 then
                            helper4(value8, config.streamerXpText)
                        else
                            helper3(xpFrame, "Visible", false)
                        end
                    end
                end
            end
            if config.streamerName then
                local value9 = playerGui:FindFirstChild("Cmdr")
                local value10 = value9 and (value9:FindFirstChild("Frame"))
                value10 = value10 and (value10:FindFirstChild("Entry"))
                value9 = value10 and (value10:FindFirstChildWhichIsA("TextLabel"))
                if value9 then
                    helper3(value9, "Visible", false)
                end
            end
            local value11, value12 =
                playerGui:FindFirstChild("playerStatsLeaderboard"),
                context.isAlt1186 ~= nil and context.isAlt1186()
            if value11 and (config.streamerLeaderboard or value12) then
                helper3(value11, "Enabled", false)
            end
            if config.streamerLeaderboard or value12 then
                value11 = playerGui:FindFirstChild("playerStatus")
                local value13 = value11
                    and value11:FindFirstChild("Frame")
                    and value11.Frame:FindFirstChild("teammateHolder")
                if value13 then
                    helper3(value13, "Visible", false)
                end
                value13 = playerGui:FindFirstChild("leaderboard")
                if value13 then
                    if value13:IsA("ScreenGui") then
                        helper3(value13, "Enabled", false)
                    end
                end
            end
        end
        local function helper11(argument, argument2)
            local success, value = pcall(sharedValue6.GetCoreGuiEnabled, sharedValue6, argument)
            if not success then
                return
            end
            if argument2 then
                if value then
                    sharedValue4.coreChanged[argument] = true
                    pcall(sharedValue6.SetCoreGuiEnabled, sharedValue6, argument, false)
                end
            elseif sharedValue4.coreChanged[argument] then
                sharedValue4.coreChanged[argument] = nil
                pcall(sharedValue6.SetCoreGuiEnabled, sharedValue6, argument, true)
            end
        end
        local function helper12()
            for key, entry in pairs(sharedValue4.saved) do
                for key2, entry2 in pairs(entry) do
                    pcall(function()
                        key[key2] = entry2
                    end)
                end
            end
            table.clear(sharedValue4.saved)
            for key3, entry3 in pairs(sharedValue4.fakes or {}) do
                pcall(function()
                    entry3:Destroy()
                end)
            end
            sharedValue4.fakes = {}
            for key4, entry4 in pairs(sharedValue4.plates or {}) do
                for index, conn in ipairs(entry4.conns) do
                    pcall(conn.Disconnect, conn)
                end
            end
            sharedValue4.plates = {}
            if sharedValue4.body then
                for index2, conn2 in ipairs(sharedValue4.body.conns) do
                    pcall(conn2.Disconnect, conn2)
                end
                sharedValue4.body = nil
            end
            if sharedValue4.box then
                sharedValue4.box:Destroy()
                sharedValue4.box = nil
            end
            helper11(Enum.CoreGuiType.PlayerList, false)
            helper11(Enum.CoreGuiType.Chat, false)
            sharedValue4.on = false
        end
        local function helper13(lastApply)
            if not config.streamer then
                if sharedValue4.on then
                    helper12()
                end
                return
            end
            sharedValue4.on = true
            local value = localPlayer.Character
            local value2 = value and (value:FindFirstChild("HumanoidRootPart"))
            if sharedValue4.box then
                if sharedValue4.box.Parent then
                    if value2 then
                        sharedValue4.box.CFrame = value2.CFrame
                    end
                end
            end
            if lastApply - sharedValue4.lastApply < 0.5 then
                return
            end
            sharedValue4.lastApply = lastApply
            for entry in pairs(sharedValue4.saved) do
                if not entry.Parent then
                    sharedValue4.saved[entry] = nil
                end
            end
            if value then
                if config.streamerBody then
                    helper9(value)
                elseif sharedValue4.box then
                    sharedValue4.box:Destroy()
                    sharedValue4.box = nil
                end
                helper7(value:FindFirstChild("playerNameplate"), true)
            end
            helper10()
            value = context.isAlt1186 ~= nil and context.isAlt1186()
            if config.streamerOthers or value then
                for index, entry2 in ipairs(sharedValue5:GetPlayers()) do
                    if entry2 ~= localPlayer then
                        if entry2.Character then
                            helper7(entry2.Character:FindFirstChild("playerNameplate"), false)
                        end
                    end
                end
            end
            helper11(Enum.CoreGuiType.PlayerList, config.streamerLeaderboard == true or value)
            helper11(Enum.CoreGuiType.Chat, config.streamerChat == true)
        end
        context.streamerRefresh = function()
            helper12()
            sharedValue4.lastApply = -math.huge
        end

        -- drive it every frame (the box follows you; the rest is throttled to twice a second)
        sliderConnections[#sliderConnections + 1] = runService.Heartbeat:Connect(function()
            if runtimeState.destroyed then
                return
            end
            pcall(helper13, os.clock())
        end)
    end

    ----------------------------------------------------------
    -- Screen: FPS cap / uncap / world rendering
    ----------------------------------------------------------
    local function applyFps()
        if type(setfpscap) ~= "function" then
            return
        end
        if config.fpsCap == true then
            pcall(setfpscap, tonumber(config.fpsCapValue) or 60)
        elseif config.fpsUncap == true then
            pcall(setfpscap, 999)
        else
            pcall(setfpscap, 60)
        end
    end
    local function applyRender()
        pcall(function()
            runService:Set3dRenderingEnabled(config.renderOff ~= true)
        end)
    end
    context.applyRender = applyRender
    if config.fpsCap == true or config.fpsUncap == true then
        applyFps()
    end
    if config.renderOff == true then
        applyRender()
    end
    -- the game / executor can reset the cap, so re-apply it now and then while it is in use
    task.spawn(function()
        while not runtimeState.destroyed do
            task.wait(3)
            if config.fpsCap == true or config.fpsUncap == true then
                applyFps()
            end
            if config.renderOff == true then
                applyRender()
            end
        end
    end)

    ----------------------------------------------------------
    -- Item cards: short numbers on the inventory item cards
    ----------------------------------------------------------
    local refreshItemCards
    do
        local function sig3(value)
            local magnitude = math.abs(value)
            if magnitude >= 100 then
                return ("%.0f"):format(value)
            elseif magnitude >= 10 then
                return ("%.1f"):format(value)
            end
            return ("%.2f"):format(value)
        end
        local function abbreviate(value)
            value = tonumber(value) or 0
            local magnitude = value < 0 and -value or value
            if magnitude >= 999500000000 then
                return sig3(value / 1000000000000) .. "t"
            elseif magnitude >= 999500000 then
                return sig3(value / 1000000000) .. "b"
            elseif magnitude >= 999500 then
                return sig3(value / 1000000) .. "m"
            elseif magnitude >= 999.5 then
                return sig3(value / 1000) .. "k"
            end
            return tostring(math.floor(value + 0.5))
        end
        local function numbersIn(text)
            local list = {}
            for digits in tostring(text):gmatch("[%d,]+") do
                local number = tonumber((digits:gsub(",", "")))
                if number then
                    list[#list + 1] = number
                end
            end
            return list
        end
        local weak = { __mode = "k" }
        local records = setmetatable({}, weak)
        local tracked = setmetatable({}, weak)
        local statNames = { "physicalDamage", "physicalPower", "spellPower", "health" }

        -- label: a TextLabel on an item card; kind: "stat" or "upgrades"
        local function handleLabel(label, kind)
            if not label:IsA("TextLabel") then
                return
            end
            local text = tostring(label.Text)
            local record = records[label]
            if not (record and text == record.wrote) then
                local numbers = numbersIn(text)
                if #numbers == 0 then
                    return
                end
                if kind == "upgrades" and #numbers ~= 2 then
                    return
                end
                if kind == "stat" and #numbers > 2 then
                    return
                end
                record = { raw = text, numbers = numbers }
                records[label] = record
            end
            local enabled
            if kind == "upgrades" then
                enabled = config.upgradeCountAbbrev ~= false
            else
                enabled = config.itemStatsAbbrev ~= false
            end
            local wanted = record.raw
            if enabled then
                local n = record.numbers
                if kind == "upgrades" then
                    wanted = ("%s / %s"):format(abbreviate(n[1]), abbreviate(n[2]))
                elseif #n == 2 then
                    wanted = ("%s (%s)"):format(abbreviate(n[1]), abbreviate(n[2]))
                else
                    wanted = abbreviate(n[1])
                end
            end
            if text ~= wanted then
                label.Text = wanted
            end
            record.wrote = wanted
        end
        local function processCard(card)
            for _, name in ipairs(statNames) do
                local label = card:FindFirstChild(name)
                if label then
                    pcall(handleLabel, label, "stat")
                end
            end
            local upgrades = card:FindFirstChild("upgrades")
            if upgrades then
                pcall(handleLabel, upgrades, "upgrades")
            end
        end
        local function trackCard(card)
            if tracked[card] or not card:IsA("GuiObject") then
                return
            end
            tracked[card] = true
            local function run()
                if not runtimeState.destroyed then
                    processCard(card)
                end
            end
            for _, name in ipairs({ "physicalDamage", "physicalPower", "spellPower", "health", "upgrades" }) do
                local child = card:FindFirstChild(name)
                if child then
                    sliderConnections[#sliderConnections + 1] = child:GetPropertyChangedSignal("Text"):Connect(run)
                end
            end
            sliderConnections[#sliderConnections + 1] = card:GetPropertyChangedSignal("Visible"):Connect(run)
            run()
        end
        local cardNames = { "armorMain", "weaponMain", "petMain" }
        local function trackFrame(frame)
            for _, name in ipairs(cardNames) do
                local card = frame:FindFirstChild(name)
                if card then
                    trackCard(card)
                end
            end
        end
        local function hookGui(playerGui)
            for _, descendant in ipairs(playerGui:GetDescendants()) do
                if descendant.Name == "itemStatFrame" then
                    trackFrame(descendant)
                end
            end
            sliderConnections[#sliderConnections + 1] = playerGui.DescendantAdded:Connect(function(added)
                if runtimeState.destroyed then
                    return
                end
                if added.Name == "itemStatFrame" then
                    task.defer(trackFrame, added)
                elseif added.Parent and added.Parent.Name == "itemStatFrame" then
                    for _, name in ipairs(cardNames) do
                        if added.Name == name then
                            task.defer(trackCard, added)
                            break
                        end
                    end
                end
            end)
        end
        refreshItemCards = function()
            for card in pairs(tracked) do
                if card.Parent then
                    processCard(card)
                end
            end
        end
        task.spawn(function()
            local playerGui = localPlayer:WaitForChild("PlayerGui", 30)
            if playerGui then
                pcall(hookGui, playerGui)
            end
        end)
    end

    ----------------------------------------------------------
    -- Color theme (animated accent colors for this menu)
    ----------------------------------------------------------

    function context.initColorThemes(gradient)
        local value9, value10 = getService("RunService"), getService("HttpService")
        local scriptGui = runtimeState.scriptGui
        local function helper6(argument, argument2, argument3)
            return Color3.fromRGB(argument, argument2, argument3)
        end
        local function helper23(argument, argument2, argument3)
            return Color3.fromHSV(argument % 1, math.clamp(argument2, 0, 1), math.clamp(argument3, 0, 1))
        end
        local list = {}
        local function helper45(name2, tint, anim, tintAnim)
            list[#list + 1] = {
                cat = "ANIMATED",
                name = name2,
                tint = tint,
                anim = anim,
                tintAnim = tintAnim,
                accent = anim(0),
            }
        end
        local function parent(argument, argument2, argument3)
            helper45(argument, helper6(44, 44, 44), function(argument4)
                local value = 0.5 + 0.5 * math.sin(argument4 * 1.3)
                return argument2:Lerp(argument3, value)
            end)
        end
        parent("Crimson", helper6(213, 0, 0), helper6(244, 49, 32))
        parent("Ember", helper6(232, 97, 0), helper6(255, 138, 42))
        parent("Gold", helper6(230, 176, 0), helper6(255, 213, 74))
        parent("Emerald", helper6(18, 179, 86), helper6(62, 227, 132))
        parent("Azure", helper6(26, 108, 240), helper6(74, 149, 255))
        parent("Violet", helper6(128, 67, 238), helper6(174, 123, 255))
        parent("Rose", helper6(230, 64, 143), helper6(255, 116, 186))
        helper45("Chroma", helper6(24, 24, 30), function(argument)
            return helper23(argument * 0.08, 0.4, 1)
        end)
        list[#list].spatial = function(argument, argument2, argument3)
            return helper23(argument * 0.08 + argument2 / 600 + argument3 / 1200, 0.4, 1)
        end
        local value11 = 1
        do
            local value12, value13 = config.colorTheme
            if value12 == "Chrome" then
                value12 = "Chroma"
                value13 = value12
            else
                value13 = value12
            end
            if value13 == nil or value13 == "Crimson" then
                pcall(function()
                    if isfile then
                        if isfile("hl_theme.json") then
                            value13 = value10:JSONDecode(readfile("hl_theme.json")).theme
                        end
                    end
                end)
            end
            for index, entry in ipairs(list) do
                if entry.name == value13 then
                    value11 = index
                end
            end
        end
        local function helper46(attackRainbowTheme)
            local value, value2 = attackRainbowTheme == "Rainbow" or attackRainbowTheme == "Chroma", false
            if value and config.attackRainbowTheme ~= attackRainbowTheme then
                config.attackRainbowTheme = attackRainbowTheme
                if config.mapAttackRainbow ~= true then
                    config.mapAttackRainbow = true
                    config.attackRainbowAuto = true
                end
                value2 = true
            else
                if not value then
                    if config.attackRainbowTheme ~= nil then
                        config.attackRainbowTheme = nil
                        if config.attackRainbowAuto == true then
                            config.mapAttackRainbow = false
                            config.attackRainbowAuto = nil
                        end
                        value2 = true
                    end
                end
            end
            if value2 then
                if context.refreshAll then
                    pcall(context.refreshAll)
                end
            end
            return value2
        end
        if helper46(list[value11].name) then
            pcall(saveConfig)
        end
        parent = getgenv and getgenv() or _G
        if parent.__HLThemes then
            pcall(parent.__HLThemes.destroy)
        end
        local value14, value15 = { identity = true }
        local function helper47(argument)
            if not (value15 and value15.Parent) then
                value15 = scriptGui and scriptGui:FindFirstChild("HLMenu")
            end
            if value15 then
                local value = value15
                if argument:IsDescendantOf(value) then
                    local value2 = value15
                    return value2.AbsolutePosition
                end
            end
            return Vector2.zero
        end
        local function helper48(argument)
            return (argument.R * 0.299 + argument.G * 0.587 + argument.B * 0.114) * 255
        end
        local function helper49(argument)
            local value, value2, value16 = argument:ToHSV()
            return value2 > 0.45 and (value < 0.07 or value > 0.93) and value16 > 0.3
        end
        local function helper50(argument)
            if value14.identity then
                return argument
            end
            local value, value2, value16 = argument:ToHSV()
            if value2 > 0.45 and (value < 0.07 or value > 0.93) then
                if value16 > 0.3 then
                    local value31, value32, value33 = value14.accent:ToHSV()
                    return Color3.fromHSV(value31, value32, math.clamp(value16 / 0.835 * value33, 0, 1))
                end
            end
            if value2 > 0.35 then
                return argument
            end
            value = helper48(argument)
            if value <= 1 then
                return argument
            elseif value >= 250 then
                return argument
            end
            argument, value16, value2 = value14.tint:ToHSV()
            if value14.light then
                return Color3.fromHSV(
                    argument,
                    value16 * (value < 90 and 1 or 0.15),
                    math.clamp(1 - value / 255 * 0.9, 0, 1)
                )
            end
            if value < 90 then
                return Color3.fromHSV(
                    argument,
                    value16,
                    math.clamp(value / 255 * (value2 / 0.17254901960784313), 0, 1)
                )
            end
            if value < 200 then
                return Color3.fromHSV(argument, math.min(value16, 0.25) * 0.6, value / 255)
            end
            return Color3.fromHSV(argument, math.min(value16, 0.25) * 0.12, value / 255)
        end
        value14.same = function(argument, argument2)
            if argument == argument2 then
                return true
            end
            local value16 = typeof(argument)
            if value16 ~= typeof(argument2) then
                return false
            end
            if value16 == "Color3" then
                return math.abs(argument.R - argument2.R) < 0.002
                    and math.abs(argument.G - argument2.G) < 0.002
                    and math.abs(argument.B - argument2.B) < 0.002
            end
            if value16 == "ColorSequence" then
                local keypoints, keypoints2 = argument.Keypoints, argument2.Keypoints
                if #keypoints ~= #keypoints2 then
                    return false
                end
                for index2 = 1, #keypoints, 1 do
                    local value, value2 = keypoints[index2].Value, keypoints2[index2].Value
                    if math.abs(keypoints[index2].Time - keypoints2[index2].Time) > 0.002 then
                        return false
                    elseif math.abs(value.R - value2.R) >= 0.002 then
                        return false
                    elseif math.abs(value.G - value2.G) >= 0.002 then
                        return false
                    elseif math.abs(value.B - value2.B) >= 0.002 then
                        return false
                    end
                end
                return true
            end
            return false
        end
        local function helper51(argument, argument2)
            if argument.tint == nil then
                if not argument.anim then
                    value14.identity = true
                    return
                end
            end
            value14.identity = false
            local value, value2
            if argument.anim then
                value, value2 = argument.anim(argument2 or os.clock())
            end
            value14.accent, value14.tint, value14.light =
                value or argument.accent, value2 or argument.tint, argument.light == true
            value14.spatial = argument.spatial
        end
        local value34, weakKeys2, value35 =
            {
                { "GuiObject", { "BackgroundColor3" } },
                { "TextLabel", { "TextColor3" } },
                { "TextButton", { "TextColor3" } },
                { "TextBox", { "TextColor3", "PlaceholderColor3" } },
                { "ImageLabel", { "ImageColor3" } },
                { "ImageButton", { "ImageColor3" } },
                { "ScrollingFrame", { "ScrollBarImageColor3" } },
                { "UIStroke", { "Color" } },
                { "UIGradient", { "Color" } },
            }, { __mode = "k" }, {}
        local value36 = setmetatable({}, weakKeys2)
        local value37 = setmetatable({}, weakKeys2)
        local value38 = setmetatable({}, weakKeys2)
        local value39 = setmetatable({}, weakKeys2)
        local value40 = setmetatable({}, weakKeys2)
        local value41 = setmetatable({}, weakKeys2)
        local function helper52(argument)
            if argument:GetAttribute("HLThemeSkip") ~= nil then
                return true
            elseif argument.Name == "HLMinimap" then
                return true
            elseif argument.Name == "HLThemeSwatches" then
                return true
            elseif argument:FindFirstAncestor("HLMinimap") ~= nil then
                return true
            elseif argument:FindFirstAncestor("HLThemeSwatches") ~= nil then
                return true
            end
            local value = argument
            while value and value ~= scriptGui do
                if value:GetAttribute("HLThemeSkipTree") ~= nil then
                    return true
                end
                value = value.Parent
            end
            return false
        end
        local function helper53(argument)
            if typeof(argument) == "Color3" then
                return helper49(argument)
            end
            if typeof(argument) == "ColorSequence" then
                for index2, keypoint in ipairs(argument.Keypoints) do
                    if helper49(keypoint.Value) then
                        return true
                    end
                end
            end
            return false
        end
        local function helper54(argument)
            if typeof(argument) == "Color3" then
                return helper50(argument)
            end
            if typeof(argument) == "ColorSequence" then
                local value = {}
                for index2, keypoint in ipairs(argument.Keypoints) do
                    value[index2] = ColorSequenceKeypoint.new(keypoint.Time, helper50(keypoint.Value))
                end
                return ColorSequence.new(value)
            end
            return argument
        end
        value14.CH = setmetatable({}, weakKeys2)
        value14.chromaSeq = function(argument, argument2, argument3, argument4)
            local value = {}
            for index2 = 0, 6, 1 do
                value[#value + 1] = ColorSequenceKeypoint.new(
                    index2 / 6,
                    value14.spatial(argument4, argument + argument2 * index2 / 6, argument3)
                )
            end
            return ColorSequence.new(value)
        end
        value14.chroma = function(parent2, argument)
            local value = parent2:IsA("UIStroke") and parent2.Parent or parent2
            if value then
                if not (value:IsA("GuiObject")) then
                    return false
                end
            else
                return false
            end
            local hlChroma = value14.CH[parent2]
            if not (hlChroma and hlChroma.Parent == parent2) then
                for index2, child in ipairs(parent2:GetChildren()) do
                    if child:IsA("UIGradient") then
                        return false
                    end
                end
                hlChroma = Instance.new("UIGradient")
                hlChroma.Name = "HLChroma"
                hlChroma:SetAttribute("HLThemeSkip", true)
                hlChroma.Parent = parent2
                value14.CH[parent2] = hlChroma
            end
            local vector, absoluteSize = value.AbsolutePosition - helper47(value), value.AbsoluteSize
            hlChroma.Color = value14.chromaSeq(
                vector.X,
                math.max(absoluteSize.X, 1),
                vector.Y + absoluteSize.Y * 0.5,
                argument
            )
            return true
        end
        local function helper55(argument)
            local value = value36[argument]
            if not value then
                return
            end
            local value2 = value14.spatial ~= nil and not value14.identity and value38[argument] == true
            if value14.CH[argument] then
                if not value2 then
                    pcall(function()
                        value14.CH[argument]:Destroy()
                    end)
                    value14.CH[argument] = nil
                end
            end
            if value2 then
                local now = os.clock()
                if argument:IsA("UIGradient") then
                    local parent2 = argument.Parent
                    if parent2 and (parent2:IsA("GuiObject")) then
                        local value16, absoluteSize =
                            parent2.AbsolutePosition - helper47(parent2), parent2.AbsoluteSize
                        local color = value14.chromaSeq(
                            value16.X,
                            math.max(absoluteSize.X, 1),
                            value16.Y + absoluteSize.Y * 0.5,
                            now
                        )
                        value16 = value37[argument]
                        if not value16 then
                            value16 = {}
                            value37[argument] = value16
                        end
                        value16.Color = color
                        pcall(function()
                            argument.Color = color
                        end)
                        return
                    end
                elseif value14.chroma(argument, now) then
                    value14.accent = Color3.new(1, 1, 1)
                else
                    local value31 = argument:IsA("GuiObject") and argument
                        or argument.Parent and argument.Parent:IsA("GuiObject") and argument.Parent
                    if value31 then
                        local vector, absoluteSize2 =
                            value31.AbsolutePosition - helper47(value31), value31.AbsoluteSize
                        value14.accent = value14.spatial(
                            now,
                            vector.X + absoluteSize2.X * 0.5,
                            vector.Y + absoluteSize2.Y * 0.5
                        )
                    end
                end
            end
            value2 = value37[argument]
            if not value2 then
                value2 = {}
                value37[argument] = value2
            end
            for key, entry2 in pairs(value) do
                local value32 = helper54(entry2)
                if key == "BackgroundColor3" and value40[argument] and typeof(value32) == "Color3" then
                    value32 = value32:Lerp(Color3.new(0, 0, 0), value40[argument])
                end
                value2[key] = value32
                pcall(function()
                    argument[key] = value32
                end)
            end
        end
        local function helper56(argument)
            local value = false
            for key, entry2 in pairs(value36[argument]) do
                value = if helper53(entry2) then true else value
            end
            value38[argument] = value or nil
        end
        local function helper57(argument)
            if value36[argument] then
                return
            elseif helper52(argument) then
                return
            end
            local value = {}
            for index2, entry2 in ipairs(value34) do
                if argument:IsA(entry2[1]) then
                    for index3, entry3 in ipairs(entry2[2]) do
                        value[#value + 1] = entry3
                    end
                end
            end
            if #value == 0 then
                return
            end
            local value2 = {}
            value36[argument] = value2
            local success = argument
            while success and success.Parent ~= scriptGui do
                success = success.Parent
            end
            if success then
                if success:IsA("GuiObject") then
                    value39[argument] = success
                end
            end
            for index4, entry4 in ipairs(value) do
                success, index4 = pcall(function()
                    return argument[entry4]
                end)
                if success then
                    value2[entry4] = index4
                    value35[#value35 + 1] = argument:GetPropertyChangedSignal(entry4):Connect(function()
                        local value16, value31 = argument[entry4], value37[argument]
                        if value31 then
                            if value14.same(value31[entry4], value16) then
                                return
                            end
                        end
                        value2[entry4] = value16
                        helper56(argument)
                        helper55(argument)
                    end)
                end
            end
            if
                argument:IsA("GuiButton")
                and argument.AutoButtonColor
                and value2.BackgroundColor3 ~= nil
            then
                pcall(function()
                    argument.AutoButtonColor = false
                end)
                value41[argument] = true
                local function helper58(argument2)
                    value40[argument] = argument2
                    helper55(argument)
                end
                value35[#value35 + 1] = argument.MouseEnter:Connect(function()
                    helper58(0.2)
                end)
                value35[#value35 + 1] = argument.MouseLeave:Connect(function()
                    helper58(nil)
                end)
                value35[#value35 + 1] = argument.MouseButton1Down:Connect(function()
                    helper58(0.35)
                end)
                value35[#value35 + 1] = argument.MouseButton1Up:Connect(function()
                    helper58(0.2)
                end)
            end
            helper56(argument)
            helper55(argument)
        end
        local value42, connection2 = false
        local function helper59()
            if value42 then
                return
            elseif runtimeState.destroyed then
                return
            end
            value42 = true
            for index2, descendant in ipairs(scriptGui:GetDescendants()) do
                helper57(descendant)
            end
            connection2 = scriptGui.DescendantAdded:Connect(function(argument)
                task.defer(function()
                    if value42 then
                        if argument.Parent then
                            helper57(argument)
                        end
                    end
                end)
            end)
            sliderConnections[#sliderConnections + 1] = connection2
        end
        local function helper60()
            for entry2 in pairs(value36) do
                if entry2.Parent then
                    helper55(entry2)
                end
            end
        end
        local function helper61()
            if not value42 then
                return
            end
            helper60()
            value42 = false
            if connection2 then
                connection2:Disconnect()
                connection2 = nil
            end
            for index2, entry2 in ipairs(value35) do
                entry2:Disconnect()
            end
            table.clear(value35)
            for entry3 in pairs(value41) do
                pcall(function()
                    entry3.AutoButtonColor = true
                end)
            end
            local value = { value36, value37, value38, value39, value40, value41 }
            for index3, entry4 in ipairs(value) do
                for entry5 in pairs(entry4) do
                    entry4[entry5] = nil
                end
            end
        end
        local value43, value44, value45, value46 =
            uiLibrary.section(
                gradient,
                "Color theme",
                -2,
                "Seven colors, every one animated. Chroma runs a rainbow through all of it instead."
            ),
            getService("TweenService"),
            0
        for index5, entry6 in ipairs(list) do
            if entry6.spatial then
                value46 = index5
            else
                value45 += 1
            end
        end
        local colorBar = Instance.new("Frame")
        colorBar.Name, colorBar.BackgroundColor3, colorBar.BorderSizePixel, colorBar.Size =
            "ColorBar", theme.SurfaceElement, 0, UDim2.new(1, 0, 0, 54)
        colorBar.LayoutOrder = 1
        colorBar.Parent = value43.content
        uiLibrary.corner(colorBar, theme.RadiusMd)
        uiLibrary.stroke(colorBar, theme.Hairline, 1)
        parent = uiLibrary.label(colorBar, "Color", "rowLabel", 1)
        parent.Position, parent.Size = UDim2.fromOffset(12, 5), UDim2.new(1, -170, 0, 18)
        local textControl7 = uiLibrary.label(colorBar, "", "rowLabel", 2)
        textControl7.AnchorPoint, textControl7.Position, textControl7.Size, textControl7.TextXAlignment =
            Vector2.new(1, 0),
            UDim2.new(1, -12, 0, 5),
            UDim2.fromOffset(160, 18),
            Enum.TextXAlignment.Right
        textControl7.TextColor3 = theme.AccentMid
        uiLibrary.setFont(textControl7, "sans", Enum.FontWeight.SemiBold)
        local colorTrack = Instance.new("Frame")
        colorTrack.Name, colorTrack.BackgroundColor3 = "ColorTrack", theme.SurfaceField
        colorTrack.BorderSizePixel = 0
        colorTrack.Active = true
        colorTrack.Position, colorTrack.Size = UDim2.fromOffset(12, 28), UDim2.new(1, -24, 0, 18)
        colorTrack:SetAttribute("HLThemeSkipTree", true)
        colorTrack.Parent = colorBar
        uiLibrary.corner(colorTrack, theme.RadiusSm)
        uiLibrary.stroke(colorTrack, theme.Hairline, 1)
        local value47 = {}
        for index6 = 1, value45, 1 do
            parent = Instance.new("Frame")
            parent.BackgroundColor3 = Color3.new(1, 1, 1)
            parent.BorderSizePixel = 0
            parent.Position, parent.Size =
                UDim2.new((index6 - 1) / value45, 2, 0, 3), UDim2.new(1 / value45, -4, 1, -6)
            parent.Parent = colorTrack
            uiLibrary.corner(parent, 3)
            gradient = Instance.new("UIGradient")
            gradient.Color = ColorSequence.new(list[index6].accent)
            gradient.Parent = parent
            value47[index6] = { g = gradient, th = list[index6] }
        end
        local barKnob = Instance.new("Frame")
        barKnob.Name, barKnob.AnchorPoint, barKnob.Size, barKnob.BackgroundColor3 =
            "BarKnob", Vector2.new(0.5, 0.5), UDim2.fromOffset(10, 26), theme.TextPrimary
        barKnob.BorderSizePixel = 0
        barKnob.ZIndex = 4
        barKnob.Parent = colorTrack
        uiLibrary.corner(barKnob, 3)
        local value48 = uiLibrary.stroke(barKnob, theme.Hairline, 1)
        local set
        local function helper62()
            if not list[value11].spatial then
                local value = value11
                return value
            end
            for index2 = 1, value45, 1 do
                if list[index2].name == config.colorThemeBase then
                    return index2
                end
            end
            return 1
        end
        local function helper63(argument)
            local value = helper62()
            local position = UDim2.fromScale((value - 0.5) / value45, 0.5)
            barKnob.BackgroundTransparency = 0
            value48.Transparency = 0
            if argument then
                value44
                    :Create(barKnob, TweenInfo.new(0.09, Enum.EasingStyle.Quint), { Position = position })
                    :Play()
            else
                barKnob.Position = position
            end
            textControl7.Text = list[value11].spatial and "Chroma - " .. list[value].name
                or list[value].name
        end
        local value49 = false
        local function helper64(argument)
            if colorTrack.AbsoluteSize.X <= 0 then
                return
            end
            local value = math.clamp(
                (argument - colorTrack.AbsolutePosition.X) / colorTrack.AbsoluteSize.X,
                0,
                0.9999
            )
            argument = math.floor(value * value45) + 1
            if argument ~= value11 then
                value = list[value11].spatial ~= nil
                set(argument)
                if value then
                    if context.refreshAll then
                        pcall(context.refreshAll)
                    end
                end
            end
            helper63(true)
        end
        colorTrack.InputBegan:Connect(function(input)
            if
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            then
                if context.pressOnTop(colorTrack, input) then
                    value49 = true
                    helper64(input.Position.X)
                end
            end
        end)
        sliderConnections[#sliderConnections + 1] = userInputService.InputChanged:Connect(function(input)
            local value = value49
                and (
                    input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch
                )
            if value then
                helper64(input.Position.X)
            end
        end)
        sliderConnections[#sliderConnections + 1] = userInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                value49 = false
            elseif input.UserInputType == Enum.UserInputType.Touch then
                value49 = false
            end
        end)
        uiLibrary.tip(
            colorBar,
            "Slide along the bar: it snaps to each color and the menu takes it on. Every color is animated. Crimson is the original look."
        )
        set = function(argument)
            value11 = argument
            config.colorTheme = list[argument].name
            helper46(list[argument].name)
            pcall(saveConfig)
            helper51(list[argument], os.clock())
            if value14.identity then
                helper61()
            else
                helper59()
                helper60()
            end
            helper63()
            if context.MM then
                if context.MM.setAccent then
                    pcall(context.MM.setAccent, list[argument].accent)
                end
            end
        end
        if value46 then
            helper(
                uiLibrary.toggle(
                    value43.content,
                    "Chroma",
                    function()
                        local spatial = list[value11].spatial
                        return spatial ~= nil
                    end,
                    function(argument)
                        if argument then
                            if not list[value11].spatial then
                                config.colorThemeBase = list[value11].name
                            end
                            set(value46)
                        else
                            set(helper62())
                        end
                    end,
                    2,
                    "A rainbow through every accent part of the menu, drifting across it - the knob above glides along the colors while it is on. Picking a color stops it there."
                )
            )
        end
        value43.setOpen(true)
        helper63()
        local value50, value51, value52, value53, value54, value55, value56 =
            { list = {}, pos = 1, built = 0, sig = "", due = 0 }, 0, {}, 1, 0, ""
        local function helper65(argument)
            local value = value39[argument]
            return value == nil or value.Visible
        end
        sliderConnections[#sliderConnections + 1] = value9.Heartbeat:Connect(function(argument)
            if next(value40) then
                local vector = userInputService:GetMouseLocation()
                for entry2 in pairs(value40) do
                    local absolutePosition, absoluteSize = entry2.AbsolutePosition, entry2.AbsoluteSize
                    if
                        not (
                            entry2.Parent
                            and entry2.Visible
                            and vector.X >= absolutePosition.X
                            and vector.X <= absolutePosition.X + absoluteSize.X
                            and vector.Y >= absolutePosition.Y
                            and vector.Y <= absolutePosition.Y + absoluteSize.Y
                        )
                    then
                        value40[entry2] = nil
                        if entry2.Parent then
                            helper55(entry2)
                        end
                    end
                end
            end
            local value, value2 = colorBar.Parent ~= nil, colorBar
            while value and value2 and value2 ~= scriptGui do
                value, value2 =
                    if value2:IsA("GuiObject") then if value2.Visible then value else false else value,
                    value2.Parent
            end
            if value then
                value51 += argument
                if value51 >= 0.06666666666666667 then
                    value51 = 0
                    local now = os.clock()
                    for index2, entry3 in ipairs(value47) do
                        index2 = entry3.th.anim and entry3.th.anim(now) or entry3.th.accent
                        local value16, value31 = index2:Lerp(Color3.new(1, 1, 1), 0.18), {}
                        for index3 = 0, 4, 1 do
                            local value32 = index3 / 4
                            value31[#value31 + 1] = ColorSequenceKeypoint.new(
                                value32,
                                index2:Lerp(
                                    value16,
                                    0.5 + 0.5 * math.cos((value32 - now * 0.2) * 3.141592653589793 * 2)
                                )
                            )
                        end
                        entry3.g.Color = ColorSequence.new(value31)
                    end
                end
            end
            if value and list[value11].spatial and not value49 then
                local value33 = value45
                local value57 = os.clock() / (tonumber(config.chromaKnobLoop) or value33) % 1
                barKnob.Position = UDim2.fromScale((0.5 + value57 * (value33 - 1)) / value33, 0.5)
                local value58 = math.clamp(math.min(value57, 1 - value57) / 0.05, 0, 1)
                barKnob.BackgroundTransparency, value48.Transparency = 1 - value58, 1 - value58
                value58 = math.floor(value57 * (value33 - 1) + 0.5) + 1
                if value58 ~= value56 then
                    value56 = value58
                    textControl7.Text = "Chroma - " .. list[value58].name
                end
            elseif value56 then
                value56 = nil
                barKnob.BackgroundTransparency = 0
                value48.Transparency = 0
            end
            local value59 = list[value11]
            if value42 then
                if not value59.anim then
                    return
                end
            else
                return
            end
            helper51(value59, os.clock())
            if value59.tintAnim then
                local value60 = ""
                for index4, child in ipairs(scriptGui:GetChildren()) do
                    value60 = if child:IsA("GuiObject")
                        then if child.Visible then value60 .. child.Name .. "|" else value60
                        else value60
                end
                if value60 ~= value55 or os.clock() - value54 > 2 or #value52 == 0 then
                    value55 = value60
                    table.clear(value52)
                    for entry4 in pairs(value36) do
                        if entry4.Parent then
                            if helper65(entry4) then
                                value52[#value52 + 1] = entry4
                            end
                        end
                    end
                    value54, value53 = os.clock(), 1
                end
                local value61 = #value52
                local value62 = math.min(80, value61)
                for index7 = 1, value62, 1 do
                    if value53 > value61 then
                        value53 = 1
                    end
                    index7 = value52[value53]
                    value53 += 1
                    if index7 then
                        if index7.Parent then
                            helper55(index7)
                        end
                    end
                end
            else
                local sig = ""
                for index8, child2 in ipairs(scriptGui:GetChildren()) do
                    sig = if child2:IsA("GuiObject")
                        then if child2.Visible then sig .. child2.Name .. "|" else sig
                        else sig
                end
                if sig ~= value50.sig or os.clock() - value50.built > 1 or #value50.list == 0 then
                    value50.sig = sig
                    table.clear(value50.list)
                    for entry5 in pairs(value38) do
                        if entry5.Parent then
                            if helper65(entry5) then
                                value50.list[#value50.list + 1] = entry5
                            end
                        end
                    end
                    value50.built = os.clock()
                    value50.pos = 1
                end
                local value63 = #value50.list
                if value63 == 0 then
                    return
                end
                value50.due =
                    math.min(value50.due + value63 * argument * (value14.spatial and 10 or 30), value63)
                local value64 = math.floor(value50.due)
                value50.due = value50.due - value64
                for index9 = 1, value64, 1 do
                    if value50.pos > value63 then
                        value50.pos = 1
                    end
                    index9 = value50.list[value50.pos]
                    value50.pos = value50.pos + 1
                    if index9 then
                        if index9.Parent then
                            if value38[index9] then
                                helper55(index9)
                            end
                        end
                    end
                end
            end
        end)
        if list[value11].tint ~= nil or list[value11].anim then
            task.delay(1, function()
                if runtimeState.destroyed then
                    return
                end
                helper51(list[value11], os.clock())
                helper59()
            end)
        end
        context.colorThemes = {
            list = list,
            set = set,
            current = function()
                local value = list[value11]
                return value.name
            end,
        }
        function context.themeAccent()
            local value = list[value11]
            return value.accent
        end
        function context.themeLive(argument)
            local value = list[value11]
            if value.spatial then
                return nil, value.spatial
            end
            if value.anim then
                return (value.anim(argument or os.clock()))
            end
            return value.accent
        end
        if context.MM then
            if context.MM.setAccent then
                pcall(context.MM.setAccent, list[value11].accent)
            end
        end
    end

    context.initColorThemes(pageBody)

    ----------------------------------------------------------
    -- Streamer mode section
    ----------------------------------------------------------
    do
        local section = uiLibrary.section(
            pageBody,
            "Streamer mode",
            -1,
            "Hide anything on screen that says who is playing."
        )
        local function refreshStreamer()
            if context.streamerRefresh then
                context.streamerRefresh()
            end
        end
        helper15(
            section.content,
            "Streamer mode",
            "streamer",
            1,
            "Hide or replace everything below. Off puts it all back.",
            refreshStreamer
        )
        local function textRow(label, key, order, tip)
            helper(uiLibrary.textInput(section.content, label, function()
                return config[key]
            end, function(value)
                config[key] = tostring(value or "")
                refreshStreamer()
                saveConfig()
            end, order, tip))
        end
        textRow("Name", "streamerNameText", 2, "Shown instead of your name. Empty hides it.")
        textRow("Health", "streamerHealthText", 3, "Shown instead of your health. Empty hides it.")
        textRow("Level", "streamerLevelText", 4, "Shown instead of your level. Empty hides it.")
        textRow("Gold", "streamerGoldText", 5, "Shown instead of your gold. Empty hides the row.")
        textRow("Gems", "streamerGemsText", 6, "Shown instead of your gems. Empty hides the row.")
        textRow("XP", "streamerXpText", 7, "Shown instead of your XP. Empty hides the bar.")
        helper15(
            section.content,
            "Hitbox as body",
            "streamerBody",
            8,
            "Draw the character as a plain block in the color below.",
            refreshStreamer
        )
        helper(
            uiLibrary.colorWheel(
                section.content,
                "Hitbox color",
                function()
                    return typeof(config.streamerBodyColor) == "Color3" and config.streamerBodyColor
                        or Color3.fromHex("5bff9c")
                end,
                function(color)
                    config.streamerBodyColor = color
                    helper16()
                end,
                9,
                "The color of the block drawn in place of your character. Click to open the wheel: hue round it, paler to the middle, brightness on the bar."
            )
        )
        helper15(section.content, "Hide other players' names", "streamerOthers", 10, "Other players' nameplates.", refreshStreamer)
        helper15(section.content, "Hide the player lists", "streamerLeaderboard", 11, "The game's and Roblox's player lists.", refreshStreamer)
        helper15(section.content, "Hide the chat", "streamerChat", 12, "The Roblox chat window.", refreshStreamer)
    end

    ----------------------------------------------------------
    -- Notifications section
    ----------------------------------------------------------
    do
        local section = uiLibrary.section(
            pageBody,
            "Notifications",
            0,
            "A card in the bottom right whenever the script has something to tell you."
        )
        helper(
            uiLibrary.toggle(
                section.content,
                "Notifications",
                function()
                    return config.notifications ~= false
                end,
                function(value)
                    config.notifications = value
                    saveConfig()
                end,
                1,
                "Show a card in the bottom right of the screen for everything the script does. Off: none."
            )
        )
    end

    ----------------------------------------------------------
    -- Screen section
    ----------------------------------------------------------
    do
        local section = uiLibrary.section(
            pageBody,
            "Screen",
            1,
            "How much the game draws: the FPS cap, and the world not drawn at all."
        )
        helper15(
            section.content,
            "Show the HUD",
            "hud",
            0.5,
            "The panel in the bottom left: playtime, FPS, ping and enemies near you.",
            function()
                if context.hudApply then
                    pcall(context.hudApply)
                end
            end
        )
        helper15(
            section.content,
            "Cap FPS",
            "fpsCap",
            1,
            "Limit the game to the FPS below. Saves CPU and GPU. Off: Uncap FPS decides.",
            applyFps
        )
        helper(
            uiLibrary.slider(section.content, "FPS limit", "fps", 15, 240, false, function()
                return tonumber(config.fpsCapValue) or 60
            end, function(value)
                config.fpsCapValue = value
                helper16()
                if config.fpsCap == true then
                    applyFps()
                end
            end, 1.1, "With Cap FPS on: the FPS the game is held to.", 5)
        )
        helper15(
            section.content,
            "Uncap FPS",
            "fpsUncap",
            1.3,
            "Only while Cap FPS is off: lifts Roblox's 60 FPS cap. Off puts the 60 cap back.",
            applyFps
        )
        helper15(
            section.content,
            "Ultimate low quality",
            "renderOff",
            2,
            "Stops the game drawing the world at all - the screen goes blank but this menu stays where it is. It is the biggest saving there is on a weak machine. Off brings the picture back.",
            applyRender
        )
        section.setOpen(true)
    end

    ----------------------------------------------------------
    -- Item cards section
    ----------------------------------------------------------
    do
        local section = uiLibrary.section(pageBody, "Item cards", 4, "How the game's item cards show their numbers.")
        helper15(
            section.content,
            "Abbreviate item stats",
            "itemStatsAbbrev",
            1,
            "Show inventory item stats short (9.76k, 11.0b - three figures) instead of the full number. On by default.",
            function()
                if refreshItemCards then
                    refreshItemCards()
                end
            end
        )
        helper15(
            section.content,
            "Abbreviate the upgrade count",
            "upgradeCountAbbrev",
            2,
            "The item card's upgrade line as well - short on, the game's own text off. On by default.",
            function()
                if refreshItemCards then
                    refreshItemCards()
                end
            end
        )
    end

    ----------------------------------------------------------
    -- Minimap section (ported from the original) + HUD
    ----------------------------------------------------------
    local uiSettings = {}
    do
        local section = uiLibrary.section(
            pageBody,
            "Minimap",
            3,
            "The minimap in the top right, the MAP VIEW it opens and the key for it."
        )
        local content = section.content
        local function mmApply()
            if context.MM and context.MM.apply then
                pcall(context.MM.apply)
            end
        end
        helper15(content, "Show the minimap", "minimap", 1,
            "A map of every mob, player and enemy attack round you, north up. Click it for the MAP VIEW - the red X in its corner closes that. Scroll over it to zoom; middle-drag to move it.",
            mmApply)
        helper15(content, "Map button", "mapButton", 1.2,
            "A MINIMAP button right under the small map - it opens the MAP VIEW, the same as the map key.",
            mmApply)
        helper15(content, "Follow player", "mapFollow", 1.5,
            "On: the map keeps you in the middle. Off: it stays where it is and you move across it - middle-drag the MAP VIEW to move it, middle-click to put it on you again. Each place keeps its own spot.",
            function(on)
                if context.MM and context.MM.onFollow then
                    pcall(context.MM.onFollow, on)
                end
            end)
        helper15(content, "Smooth 2D map", "minimapSmooth", 1.8,
            "The classic 2D map redraws every frame instead of 10-20 times a second, so everything on it moves smoothly. Off if it costs you frames.")
        helper15(content, "Custom attack color", "mapAttackOneColor", 2,
            "Every enemy attack in the color below - on the map, and the attacks themselves in the world, every part of them. Off puts their own colors back.")
        helper15(content, "Rainbow attacks", "mapAttackRainbow", 2,
            "Every enemy attack cycles through the rainbow - on the map, the attack zones and the attacks themselves in the world. Takes over from the color below while it is on. Picking the Rainbow or Chroma theme turns it on; switching to another theme turns it back off, unless you set it here yourself.",
            function()
                config.attackRainbowAuto = nil
            end)
        helper(
            uiLibrary.colorWheel(
                content,
                "Attack color",
                function()
                    return typeof(config.mapAttackColor) == "Color3" and config.mapAttackColor
                        or Color3.fromRGB(255, 60, 60)
                end,
                function(color)
                    config.mapAttackColor = color
                    helper16()
                end,
                3,
                'The color of every enemy attack while "Custom attack color" is on. Click to open the wheel: hue round it, paler to the middle, brightness on the bar.'
            )
        )
        uiSettings.mapKeyButton = uiLibrary.button(
            content,
            "Map key: " .. tostring(config.mapKey) .. " (click, then press a key)",
            "accent",
            function()
                runtimeState.mapKeyCapture = true
                if uiSettings.mapKeyButton then
                    uiSettings.mapKeyButton.Text = "Press the new key... (Escape cancels)"
                end
            end,
            4,
            "The key that opens and closes the MAP VIEW - M to begin with. Click, then press the new key; Escape keeps the old one."
        )
        section.setOpen(true)
    end

    -- map key: capture a new one, or open/close the MAP VIEW
    sliderConnections[#sliderConnections + 1] = userInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end
        if runtimeState.mapKeyCapture and input.UserInputType == Enum.UserInputType.Keyboard then
            runtimeState.mapKeyCapture = false
            local keyCode = input.KeyCode
            if keyCode ~= Enum.KeyCode.Escape and keyCode ~= Enum.KeyCode.Unknown then
                config.mapKey = keyCode.Name
                saveConfig()
            end
            if uiSettings.mapKeyButton then
                uiSettings.mapKeyButton.Text = "Map key: " .. tostring(config.mapKey) .. " (click, then press a key)"
            end
            return
        end
        if input.KeyCode.Name == config.mapKey and context.MM and context.MM.toggle then
            pcall(context.MM.toggle)
        end
    end)

    -- things the minimap expects from the original script
    local workspaceService = workspace
    local sharedValue5 = getService("Players")
    local hazardReader = { enemies = {} }
    context.RD = hazardReader
    context.log = context.log or function() end
    context.hudShown = function()
        return config.hud ~= false
    end
    context.attackColourNow = function()
        if config.mapAttackRainbow == true then
            local t = math.floor(workspaceService:GetServerTimeNow() * (config.attackRainbowSpeed or 0.08) % 1 * 90) / 90
            return Color3.fromHSV(t, config.attackRainbowSat or 0.9, 1)
        end
        if config.mapAttackOneColor == true and typeof(config.mapAttackColor) == "Color3" then
            return config.mapAttackColor
        end
        return nil
    end
    local helper18, green, band2, index5, index8, index11, index23, hlBugReport

    -- enemy list for the map (the original gets this from its fight reader)
    task.spawn(function()
        local playersService = getService("Players")
        while not runtimeState.destroyed do
            local list, char = {}, localPlayer.Character
            local function scan(root, depth)
                for _, child in ipairs(root:GetChildren()) do
                    if child:IsA("Model") then
                        if child ~= char then
                            local hum = child:FindFirstChildOfClass("Humanoid")
                            local r = child:FindFirstChild("HumanoidRootPart") or child.PrimaryPart
                            if hum and r and hum.Health > 0 and not playersService:GetPlayerFromCharacter(child) then
                                local style = child:FindFirstChild("enemyStyle")
                                local p = r.Position
                                list[#list + 1] = {
                                    model = child, root = r, humanoid = hum,
                                    x = p.X, y = p.Y, z = p.Z, vx = 0, vz = 0,
                                    isBoss = style ~= nil and type(style.Value) == "string"
                                        and string.find(string.lower(style.Value), "boss", 1, true) ~= nil,
                                    extent = math.max(r.Size.X, r.Size.Z) * 0.5,
                                }
                            end
                        end
                    elseif depth < 2 and child:IsA("Folder") then
                        scan(child, depth + 1)
                    end
                end
            end
            pcall(scan, workspaceService, 0)
            hazardReader.enemies = list
            task.wait(0.15)
        end
    end)

    -- the minimap itself (original code)
    do
        local ok, err = xpcall(function()
    do
        local zone = {}
        zone.big = config.mapViewOpen == true
        zone.zoomS = tonumber(config.mapZoomS) or 1
        zone.zoomB = tonumber(config.mapZoomB) or 1
        zone.lastAt = 0
        zone.panX = 0
        zone.panZ = 0
        zone.statsAt = 0
        zone.frames = 0
        zone.fpsAt = os.clock()
        zone.fps = 0
        context.MM = zone
        if config.renderOff == true then
            if not zone.big then
                zone.big = true
                zone.ultOpened = true
            end
        end
        zone.blank = function()
            return zone.big == true and config.mapBlankScreen == true
        end
        local sharedValue40, theme2 = config.minimapSize or 220, {}
        theme2.Bg = Color3.fromRGB(9, 10, 13)
        theme2.Panel = Color3.fromRGB(16, 18, 23)
        theme2.Raised = Color3.fromRGB(24, 27, 34)
        theme2.Stroke = Color3.fromRGB(40, 44, 54)
        theme2.StrokeSoft = Color3.fromRGB(31, 34, 42)
        theme2.Text = Color3.fromRGB(236, 238, 243)
        theme2.Muted = Color3.fromRGB(140, 146, 160)
        theme2.Faint = Color3.fromRGB(92, 98, 112)
        theme2.Green = Color3.fromRGB(74, 222, 128)
        theme2.Red = Color3.fromRGB(248, 92, 100)
        theme2.Purple = Color3.fromRGB(178, 112, 255)
        theme2.Pink = Color3.fromRGB(236, 110, 200)
        theme2.Blue = Color3.fromRGB(112, 140, 255)
        theme2.White = Color3.fromRGB(245, 246, 250)
        zone.theme = theme2
        theme2.Orb = theme2.Green
        helper18, green = pcall(function()
            return context.themeAccent and context.themeAccent()
        end)
        if helper18 then
            if typeof(green) == "Color3" then
                theme2.Green = green
            end
        end
        local sharedValue41 = {}
        pcall(function()
            sharedValue41.Regular, sharedValue41.Medium =
                Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Regular),
                Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium)
            sharedValue41.Semi, sharedValue41.Bold =
                Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.SemiBold),
                Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
            sharedValue41.Mono = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Medium)
        end)
        local sharedValue42, sharedValue43, sharedValue44, sharedValue45 = 360, 16, 16, 64
        local sharedValue46 = getService("TweenService")
        local function helper154(argument, argument2, argument3)
            pcall(function()
                sharedValue46
                    :Create(
                        argument,
                        TweenInfo.new(argument2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                        argument3
                    )
                    :Play()
            end)
        end
        local function helper155(argument, argument2, parent)
            local value = Instance.new(argument)
            if value:IsA("GuiObject") then
                value.BorderSizePixel = 0
            end
            for key, entry in pairs(argument2) do
                value[key] = entry
            end
            if parent then
                value.Parent = parent
            end
            return value
        end
        local function helper156(argument, argument2)
            return helper155("UICorner", { CornerRadius = UDim.new(0, argument2) }, argument)
        end
        local function helper157(argument, argument2, argument3)
            return helper155("UIStroke", {
                Color = argument2 or theme2.Stroke,
                Transparency = argument3 or 0,
                Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            }, argument)
        end
        local function helper158(argument, argument2, argument3, argument4, argument5)
            argument3, argument4 = argument3 or argument2, argument4 or argument2
            argument5 = argument5 or argument3
            return helper155("UIPadding", {
                PaddingTop = UDim.new(0, argument2),
                PaddingRight = UDim.new(0, argument3),
                PaddingBottom = UDim.new(0, argument4),
                PaddingLeft = UDim.new(0, argument5),
            }, argument)
        end
        local function helper159(argument, argument2, argument3, argument4)
            return helper155("UIListLayout", {
                FillDirection = argument2 and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
                Padding = UDim.new(0, argument3),
                HorizontalAlignment = argument4 or Enum.HorizontalAlignment.Left,
                VerticalAlignment = argument2 and Enum.VerticalAlignment.Center or Enum.VerticalAlignment.Top,
                SortOrder = Enum.SortOrder.LayoutOrder,
            }, argument)
        end
        local function helper160(parent, argument)
            local value = helper155("TextLabel", {
                BackgroundTransparency = 1,
                TextColor3 = theme2.Text,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                AutomaticSize = Enum.AutomaticSize.XY,
                Size = UDim2.fromOffset(0, 0),
            }, nil)
            local fontFace = argument.FontFace or sharedValue41.Medium
            for key, entry in pairs(argument) do
                if key ~= "FontFace" then
                    value[key] = entry
                end
            end
            if fontFace then
                pcall(function()
                    value.FontFace = fontFace
                end)
            end
            value.Parent = parent
            return value
        end
        local function helper161(argument, backgroundColor3, argument2, argument3)
            local value = helper155("Frame", {
                Size = UDim2.fromOffset(argument2, argument2),
                BackgroundColor3 = backgroundColor3,
                LayoutOrder = argument3 or 1,
            }, argument)
            helper156(value, math.floor(argument2 / 2))
            return value
        end
        local function helper162(argument, rotation)
            local new = NumberSequenceKeypoint.new
            return helper155("UIGradient", {
                Rotation = rotation,
                Transparency = NumberSequence.new({ new(0, 0), new(0.55, 0.2), new(1, 1) }),
            }, argument)
        end
        local hlMinimap = Instance.new("Frame")
        hlMinimap.Name = "HLMinimap"
        hlMinimap.BackgroundTransparency = 1
        hlMinimap.BorderSizePixel = 0
        hlMinimap.ZIndex = 1
        hlMinimap.Parent = runtimeState.scriptGui
        local backdrop = Instance.new("TextButton")
        backdrop.Name = "Backdrop"
        backdrop.Text = ""
        backdrop.AutoButtonColor = false
        backdrop.BorderSizePixel = 0
        backdrop.BackgroundColor3, backdrop.BackgroundTransparency, backdrop.Size =
            theme2.Bg, 0, UDim2.fromScale(1, 1)
        backdrop.ZIndex = 1
        backdrop.Visible = false
        backdrop.Parent = hlMinimap
        local sharedValue47 = {}
        for index23 = 1, 4, 1 do
            band2 = Instance.new("TextButton")
            band2.Name = "Band"
            band2.Text = ""
            band2.AutoButtonColor = false
            band2.BorderSizePixel = 0
            band2.BackgroundColor3 = theme2.Bg
            band2.BackgroundTransparency = 0
            band2.ZIndex = 1
            band2.Visible = false
            band2.Parent = hlMinimap
            sharedValue47[index23] = band2
        end
        local view = Instance.new("Frame")
        view.Name, view.BackgroundColor3 = "View", theme2.Panel
        view.BorderSizePixel = 0
        view.ClipsDescendants = true
        view.ZIndex = 2
        view.Parent = hlMinimap
        local corner = Instance.new("UICorner")
        corner.Parent = view
        local stroke2 = Instance.new("UIStroke")
        stroke2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke2.Parent = view
        local sharedValue48 = helper155("Frame", {
            Name = "Header",
            BackgroundColor3 = theme2.Panel,
            Size = UDim2.new(1, 0, 0, 132),
            ZIndex = 30,
            Visible = false,
        }, view)
        helper162(sharedValue48, 90)
        local sharedValue49 = helper155("Frame", {
            Name = "Footer",
            BackgroundColor3 = theme2.Panel,
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 64),
            ZIndex = 30,
            Visible = false,
        }, view)
        helper162(sharedValue49, -90)
        local sharedValue50 = helper155("Frame", {
            Name = "Title",
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.XY,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 18, 0, 27),
            ZIndex = 45,
        }, view)
        helper159(sharedValue50, true, 8)
        helper161(sharedValue50, theme2.Green, 8, 1)
        helper160(
            sharedValue50,
            { Text = "Map view", FontFace = sharedValue41.Bold, TextSize = 18, LayoutOrder = 2 }
        )
        helper160(sharedValue50, { Text = "Live", TextSize = 13, TextColor3 = theme2.Muted, LayoutOrder = 3 })
        local sharedValue51 = helper155("Frame", {
            Name = "Hints",
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.XY,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 18, 1, -21),
            ZIndex = 45,
        }, view)
        helper159(sharedValue51, true, 18)
        hlBugReport =
            { { "Scroll", "zoom" }, { "Middle-drag", "look around" }, { "Middle-click", "follow you" } }
        for index24, entry26 in ipairs(hlBugReport) do
            helper162 = helper155(
                "Frame",
                { BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.XY, LayoutOrder = index24 },
                sharedValue51
            )
            helper159(helper162, true, 7)
            index24 = helper155("Frame", {
                AutomaticSize = Enum.AutomaticSize.X,
                Size = UDim2.fromOffset(0, 22),
                BackgroundColor3 = theme2.Raised,
                LayoutOrder = 1,
            }, helper162)
            helper156(index24, 6)
            helper157(index24)
            helper158(index24, 0, 7)
            helper160(index24, {
                Text = entry26[1],
                FontFace = sharedValue41.Semi,
                TextSize = 12,
                Size = UDim2.fromScale(0, 1),
                AutomaticSize = Enum.AutomaticSize.X,
            })
            helper160(
                helper162,
                { Text = entry26[2], TextSize = 13, TextColor3 = theme2.Muted, LayoutOrder = 2 }
            )
        end
        local sharedValue52 = helper155("Frame", {
            Name = "Legend",
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.XY,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -18, 1, -21),
            ZIndex = 45,
        }, view)
        helper159(sharedValue52, true, 16)
        local viewBox, hit =
            ipairs, {
                { theme2.Red, "Mob" },
                { theme2.Purple, "Boss" },
                { theme2.Blue, "Player" },
                { theme2.White, "You" },
                { theme2.Orb, "Orb" },
            }
        for key8, entry27 in viewBox(hit) do
            helper162 = helper155(
                "Frame",
                { BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.XY, LayoutOrder = key8 },
                sharedValue52
            )
            helper159(helper162, true, 6)
            helper161(helper162, entry27[1], 8, 1)
            helper160(
                helper162,
                { Text = entry27[2], TextSize = 13, TextColor3 = theme2.Muted, LayoutOrder = 2 }
            )
        end
        hit = Instance.new("TextButton")
        hit.Name, hit.BackgroundTransparency, hit.Text, hit.AutoButtonColor, hit.Size =
            "Hit", 1, "", false, UDim2.fromScale(1, 1)
        hit.ZIndex = 40
        hit.Parent = view
        zone.overMenu = function()
            local scriptGui = runtimeState.scriptGui
            if not scriptGui then
                return false
            end
            local vector, value =
                userInputService:GetMouseLocation() - getService("GuiService"):GetGuiInset(),
                workspaceService.CurrentCamera
            local value2 = value and value.ViewportSize.X or 1000000000
            for index, child in ipairs(scriptGui:GetChildren()) do
                value = child.Name == "HLMenu"
                if
                    child ~= hlMinimap
                    and child:IsA("GuiObject")
                    and child.Visible
                    and (child.Active or value)
                then
                    local absolutePosition, absoluteSize = child.AbsolutePosition, child.AbsoluteSize
                    if value or absoluteSize.X < value2 - 2 then
                        if vector.X >= absolutePosition.X then
                            if vector.X <= absolutePosition.X + absoluteSize.X then
                                if vector.Y >= absolutePosition.Y then
                                    if vector.Y <= absolutePosition.Y + absoluteSize.Y then
                                        return true
                                    end
                                end
                            end
                        end
                    end
                end
            end
            return false
        end
        zone.mapBtn = helper155("TextButton", {
            Name = "MapButton",
            Text = "",
            AutoButtonColor = false,
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 1, 10),
            Size = UDim2.fromOffset(150, 26),
            ZIndex = 5,
            Visible = false,
        }, hlMinimap)
        zone.mapBtnStroke = helper157(zone.mapBtn)
        zone.mapBtnCorner = helper156(zone.mapBtn, 8)
        viewBox, helper162 =
            zone.mapBtn, function()
                if zone.overMenu() then
                    return
                end
                if zone.setBig then
                    zone.setBig(true)
                end
            end
        viewBox.Activated:Connect(helper162)
        local sharedValue53 = helper155("TextButton", {
            Name = "Close",
            Text = "",
            AutoButtonColor = false,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -18, 0, 18),
            Size = UDim2.fromOffset(32, 32),
            BackgroundColor3 = theme2.Raised,
            ZIndex = 50,
            Visible = false,
        }, view)
        helper156(sharedValue53, 8)
        local sharedValue54 = helper157(sharedValue53)
        local sharedValue55 = uiLibrary.icon(sharedValue53, "x", 16, theme2.Muted, 51)
        sharedValue55.AnchorPoint, sharedValue55.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
        local function helper163()
            helper154(sharedValue53, 0.15, { BackgroundColor3 = theme2.Red })
            helper154(sharedValue54, 0.15, { Color = theme2.Red })
            helper154(sharedValue55, 0.15, { ImageColor3 = theme2.White })
        end
        sharedValue53.MouseEnter:Connect(helper163)
        local function helper164()
            helper154(sharedValue53, 0.15, { BackgroundColor3 = theme2.Raised })
            helper154(sharedValue54, 0.15, { Color = theme2.Stroke })
            helper154(sharedValue55, 0.15, { ImageColor3 = theme2.Muted })
        end
        sharedValue53.MouseLeave:Connect(helper164)
        local sharedValue56 = helper155("Frame", {
            Name = "Options",
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.XY,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -234, 0, 27),
            ZIndex = 45,
        }, view)
        helper159(sharedValue56, true, 6)
        sharedValue53.AnchorPoint, sharedValue53.Position = Vector2.new(1, 0.5), UDim2.new(1, -18, 0, 27)
        local sharedValue57 = {}
        local function helper165(argument, argument2)
            if argument == "mapBg3D" and config.renderOff == true then
                config.mapBg3D = true
                config.renderOff = false
                zone.ultOpened = nil
                if context.applyRender then
                    pcall(context.applyRender, true)
                end
                if context.refreshAll then
                    pcall(context.refreshAll)
                end
            elseif argument2 then
                config[argument] = config[argument] == false
            else
                config[argument] = config[argument] ~= true
            end
            pcall(helper16)
        end
        local function helper166(layoutOrder, text, argument, argument2, argument3)
            local value = helper155("TextButton", {
                Name = "Chip",
                Text = "",
                AutoButtonColor = false,
                AutomaticSize = Enum.AutomaticSize.X,
                Size = UDim2.fromOffset(0, 28),
                BackgroundColor3 = theme2.Green,
                BackgroundTransparency = 1,
                LayoutOrder = layoutOrder,
                ZIndex = 46,
            }, sharedValue56)
            helper156(value, 14)
            helper158(value, 0, 12, 0, 10)
            helper159(value, true, 7)
            local value2 = helper157(value)
            local value3 = helper161(value, theme2.Faint, 6, 1)
            local value4 = helper160(value, { Text = text, TextSize = 13, LayoutOrder = 2 })
            local function helper6()
                if argument2 then
                    return config[argument] ~= false
                end
                return config[argument] == true
            end
            local function render(argument4)
                local value5 = helper6() and not (argument == "mapBg3D" and config.renderOff == true)
                argument4 = argument4 or 0
                helper154(value, argument4, { BackgroundTransparency = value5 and 0.88 or 1 })
                helper154(
                    value2,
                    argument4,
                    { Color = value5 and theme2.Green or theme2.Stroke, Transparency = value5 and 0.5 or 0 }
                )
                helper154(value3, argument4, { BackgroundColor3 = value5 and theme2.Green or theme2.Faint })
                helper154(value4, argument4, { TextColor3 = value5 and theme2.Text or theme2.Muted })
            end
            local function helper22()
                if not (helper6()) then
                    helper154(value4, 0.15, { TextColor3 = theme2.Text })
                end
            end
            value.MouseEnter:Connect(helper22)
            local function helper23()
                render(0.15)
            end
            value.MouseLeave:Connect(helper23)
            local function helper24()
                if zone.overMenu() then
                    return
                end
                helper165(argument, argument2)
                render(0.18)
                if zone.apply then
                    zone.apply()
                end
            end
            value.Activated:Connect(helper24)
            uiLibrary.tip(value, argument3)
            render(0)
            sharedValue57[argument] = { b = value, render = render }
        end
        viewBox = {
            {
                2,
                "Health bars",
                "mapHealthBars",
                true,
                "A small health bar under every mob, boss and player.",
            },
            {
                3,
                "Names",
                "mapNames",
                true,
                "Every mob's, boss's and player's name beside them (\"YOU\" for this account; no player names in streamer mode).",
            },
        }
        for index25, entry28 in ipairs(viewBox) do
            helper166(entry28[1], entry28[2], entry28[3], entry28[4], entry28[5])
        end
        zone.VIEW_W = 168
        zone.VIEW_H = 28
        zone.viewMode = function()
            if config.mapBlankScreen == true then
                return "blank"
            end
            if config.mapBg3D ~= false then
                if config.renderOff ~= true then
                    return "3d"
                end
            end
            return "2d"
        end
        zone.setView = function(argument)
            if argument == "3d" then
                if config.renderOff == true then
                    config.renderOff = false
                    zone.ultOpened = nil
                    if context.applyRender then
                        pcall(context.applyRender, true)
                    end
                end
                config.mapBg3D = true
                config.mapBlankScreen = false
            elseif argument == "2d" then
                config.mapBg3D = false
                config.mapBlankScreen = false
            else
                config.mapBlankScreen = true
            end
            pcall(helper16)
            if context.refreshAll then
                pcall(context.refreshAll)
            end
            zone.apply()
        end
        zone.viewSpot = function()
            local vector, vector2, value =
                workspaceService.CurrentCamera and workspaceService.CurrentCamera.ViewportSize or Vector2.new(
                    1920,
                    1080
                ),
                getService("GuiService"):GetGuiInset(),
                zone.big and config.mapStatsHidden == true and 10 or sharedValue42 + sharedValue43
            return Vector2.new(
                vector.X - sharedValue44 - value - 58 - zone.VIEW_W,
                sharedValue45 - vector2.Y + 27 - zone.VIEW_H / 2
            ),
                Vector2.new(zone.VIEW_W, zone.VIEW_H)
        end
        viewBox = helper155("Frame", {
            Name = "ViewSwitch",
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -58, 0, 27),
            Size = UDim2.fromOffset(zone.VIEW_W, zone.VIEW_H),
            BackgroundColor3 = theme2.Raised,
            ZIndex = 46,
            Visible = false,
        }, view)
        helper156(viewBox, 14)
        helper157(viewBox)
        helper158(viewBox, 2)
        helper159(viewBox, true, 2)
        zone.viewSegs = {}
        helper162 = {
            {
                "2d",
                "2D",
                48,
                "The flat map - the walls, the attacks, every mob and player as a dot, with names and health bars. The world is not drawn meanwhile (as with Ultimate low quality) - the most FPS there is.",
            },
            {
                "3d",
                "3D",
                48,
                "The world itself from straight above - greyed, every height and attack as it really is. Turns Ultimate low quality off (the world has to be drawn for it).",
            },
            {
                "blank",
                "Blank",
                64,
                "Nothing drawn - no map, no stats - only this switch stays, to bring the map back. With Ultimate low quality on it is the least there is to draw.",
            },
        }
        for index26, entry29 in ipairs(helper162) do
            helper164 = helper155("TextButton", {
                Name = entry29[1],
                Text = "",
                AutoButtonColor = false,
                Size = UDim2.new(0, entry29[3], 1, 0),
                BackgroundColor3 = theme2.Green,
                BackgroundTransparency = 1,
                LayoutOrder = index26,
                ZIndex = 47,
            }, viewBox)
            helper156(helper164, 12)
            local sharedValue58 = helper160(helper164, {
                Text = entry29[2],
                FontFace = sharedValue41.Semi,
                TextSize = 13,
                TextColor3 = theme2.Muted,
                TextXAlignment = Enum.TextXAlignment.Center,
                Size = UDim2.fromScale(1, 1),
                AutomaticSize = Enum.AutomaticSize.None,
                ZIndex = 48,
            })
            local function helper167()
                if zone.viewMode() ~= entry29[1] then
                    helper154(sharedValue58, 0.15, { TextColor3 = theme2.Text })
                end
            end
            helper164.MouseEnter:Connect(helper167)
            local function helper168()
                zone.paintView(0.15)
            end
            helper164.MouseLeave:Connect(helper168)
            local function helper169()
                if zone.overMenu() then
                    return
                end
                zone.setView(entry29[1])
            end
            helper164.Activated:Connect(helper169)
            uiLibrary.tip(helper164, entry29[4])
            zone.viewSegs[entry29[1]] = { b = helper164, l = sharedValue58 }
        end
        zone.paintView = function(argument)
            local value = zone.viewMode()
            for key, viewSeg in pairs(zone.viewSegs) do
                local value2, value3, value4 = viewSeg.b, argument or 0, {}
                value4.BackgroundTransparency = key == value and 0.78 or 1
                helper154(value2, value3, value4)
                value4, value2, value3 = viewSeg.l, argument or 0, {}
                value3.TextColor3 = key == value and theme2.Text or theme2.Muted
                helper154(value4, value2, value3)
            end
        end
        zone.viewBox = viewBox
        zone.CAM_VIEWS = {
            { name = "TOP", pitch = 89.5 },
            { name = "TILT", pitch = 68 },
            { name = "3D", pitch = 52 },
            { name = "ISO", pitch = 35, yaw = 45 },
            { name = "LOW", pitch = 22 },
            { name = "CHASE", pitch = 30, heading = true },
            { name = "ORBIT", pitch = 45, spin = 18 },
            { name = "FREE", free = true },
            { name = "AUTO", auto = true },
        }
        zone.camIndex = function()
            for index, view2 in ipairs(zone.CAM_VIEWS) do
                if view2.name == config.map3DView then
                    return index
                end
            end
            return 1
        end
        zone.camShot = function(argument)
            local value = zone.CAM_VIEWS[zone.camIndex()]
            local value2 = value.auto == true
            if value2 then
                local autoView = zone.autoView
                if (if autoView then not zone.autoAt else not autoView) or argument >= zone.autoAt then
                    local value3 = {}
                    for index, view2 in ipairs(zone.CAM_VIEWS) do
                        if not view2.auto then
                            if not view2.free then
                                if view2 ~= zone.autoView then
                                    value3[#value3 + 1] = view2
                                end
                            end
                        end
                    end
                    zone.autoView = value3[math.random(1, #value3)]
                    zone.autoAt = argument
                        + math.clamp(tonumber(config.map3DSwitch) or 4, 1.5, 15)
                            * (0.75 + math.random() * 0.5)
                    zone.autoYaw = math.random() * 360
                end
                value = zone.autoView
            end
            local value4, value5 = value.pitch or 55, value.yaw or 0
            if value.free then
                value4, value5 = tonumber(config.map3DFreePitch) or 55, tonumber(config.map3DFreeYaw) or 0
            end
            value5 = if value2
                then if value.yaw == nil
                    then if value.heading
                        then value5
                        else if value.spin
                            then value5
                            else if value.name ~= "TOP" then zone.autoYaw or 0 else value5
                    else value5
                else value5
            if value.heading then
                value2 = localPlayer.Character
                local value6 = value2 and (value2:FindFirstChild("HumanoidRootPart"))
                if value6 then
                    local lookVector = value6.CFrame.LookVector
                    value5 = if lookVector.X * lookVector.X + lookVector.Z * lookVector.Z > 0.01
                        then math.deg(math.atan2(-lookVector.X, -lookVector.Z))
                        else value5
                end
            end
            return value4, if value.spin then argument * value.spin % 360 else value5
        end
        do
            local camBox = helper155("Frame", {
                Name = "Camera3D",
                AnchorPoint = Vector2.new(1, 1),
                Position = UDim2.new(1, -18, 1, -12),
                Size = UDim2.fromOffset(240, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = theme2.Raised,
                BackgroundTransparency = 0.06,
                ZIndex = 46,
                Visible = false,
            }, view)
            helper156(camBox, 12)
            helper157(camBox)
            helper158(camBox, 8, 10)
            helper159(camBox, false, 6)
            helper163 = helper155("TextButton", {
                Name = "View",
                Text = "",
                AutoButtonColor = false,
                Size = UDim2.new(1, 0, 0, 26),
                BackgroundColor3 = theme2.Panel,
                LayoutOrder = 1,
                ZIndex = 47,
            }, camBox)
            helper156(helper163, 8)
            local sharedValue59 = helper157(helper163)
            local textControl27, sharedValue60 =
                helper160(helper163, {
                    Text = "",
                    FontFace = sharedValue41.Semi,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    Size = UDim2.fromScale(1, 1),
                    AutomaticSize = Enum.AutomaticSize.None,
                    ZIndex = 48,
                }), { "chevron-left", "chevron-right" }
            for index27, entry30 in ipairs(sharedValue60) do
                helper166 = uiLibrary.icon(helper163, entry30, 14, theme2.Muted, 48)
                helper166.AnchorPoint = Vector2.new(index27 == 1 and 0 or 1, 0.5)
                helper166.Position = UDim2.new(index27 == 1 and 0 or 1, index27 == 1 and 8 or -8, 0.5, 0)
            end
            local function helper170()
                helper154(sharedValue59, 0.15, { Color = theme2.Green })
            end
            helper163.MouseEnter:Connect(helper170)
            local function helper171()
                helper154(sharedValue59, 0.15, { Color = theme2.Stroke })
            end
            helper163.MouseLeave:Connect(helper171)
            local function helper172(layoutOrder, argument, argument2, argument3, name2, argument4, argument5)
                local value = helper155("TextButton", {
                    Name = name2,
                    Text = "",
                    AutoButtonColor = false,
                    Size = UDim2.new(1, 0, 0, 20),
                    BackgroundTransparency = 1,
                    LayoutOrder = layoutOrder,
                    ZIndex = 47,
                }, camBox)
                local textControl = helper160(value, {
                    Text = "",
                    FontFace = sharedValue41.Mono,
                    TextSize = 12,
                    TextColor3 = theme2.Muted,
                    Size = UDim2.new(0, 94, 1, 0),
                    AutomaticSize = Enum.AutomaticSize.None,
                    ZIndex = 48,
                })
                local value2 = helper155("Frame", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, 98, 0.5, 0),
                    Size = UDim2.new(1, -104, 0, 4),
                    BackgroundColor3 = theme2.Stroke,
                    ZIndex = 48,
                }, value)
                helper156(value2, 2)
                local value3 = helper155(
                    "Frame",
                    { Size = UDim2.fromScale(0, 1), BackgroundColor3 = theme2.Green, ZIndex = 49 },
                    value2
                )
                helper156(value3, 2)
                local value4 = helper155("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0, 0.5),
                    Size = UDim2.fromOffset(10, 10),
                    BackgroundColor3 = theme2.White,
                    ZIndex = 50,
                }, value2)
                helper156(value4, 5)
                local function helper6()
                    return math.clamp(tonumber(config[name2]) or argument4, argument, argument2)
                end
                local function helper22()
                    local value5 = (helper6() - argument) / (argument2 - argument)
                    value3.Size, value4.Position, textControl.Text =
                        UDim2.fromScale(value5, 1), UDim2.fromScale(value5, 0.5), argument5(helper6())
                end
                local value6 = false
                local function helper23(argument6)
                    local value5 = math.clamp(
                        (argument6 - value2.AbsolutePosition.X) / math.max(1, value2.AbsoluteSize.X),
                        0,
                        1
                    )
                    config[name2] = math.clamp(
                        math.floor((argument + (argument2 - argument) * value5) / argument3 + 0.5) * argument3,
                        argument,
                        argument2
                    )
                    helper22()
                end
                value.InputBegan:Connect(function(input)
                    if zone.overMenu() then
                        return
                    end
                    if
                        input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch
                    then
                        value6 = true
                        helper23(input.Position.X)
                    end
                end)
                sliderConnections[#sliderConnections + 1] = userInputService.InputChanged:Connect(
                    function(input)
                        local value5 = value6
                            and (
                                input.UserInputType == Enum.UserInputType.MouseMovement
                                or input.UserInputType == Enum.UserInputType.Touch
                            )
                        if value5 then
                            helper23(input.Position.X)
                        end
                    end
                )
                sliderConnections[#sliderConnections + 1] = userInputService.InputEnded:Connect(
                    function(input)
                        if value6 then
                            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                value6 = false
                                pcall(helper16)
                            elseif input.UserInputType == Enum.UserInputType.Touch then
                                value6 = false
                                pcall(helper16)
                            end
                        end
                    end
                )
                helper22()
                return value, helper22
            end
            local WP, sharedValue61 = helper172(2, 0.2, 6, 0.1, "map3DZoom", 1, function(argument)
                return ("ZOOM x%.1f"):format(argument)
            end)
            local sharedValue62, sharedValue63 = helper172(
                3,
                1.5,
                15,
                0.5,
                "map3DSwitch",
                4,
                function(argument)
                    return ("SWITCH %.1fs"):format(argument)
                end
            )
            uiLibrary.tip(
                sharedValue62,
                "AUTO: about how long each view is held before it glides to another."
            )
            zone.paintCam = function()
                local value = zone.CAM_VIEWS[zone.camIndex()]
                textControl27.Text = "Camera: " .. value.name
                sharedValue62.Visible = value.auto == true
                sharedValue61()
                sharedValue63()
            end
            local function helper173(argument)
                config.map3DView = zone.CAM_VIEWS[(zone.camIndex() - 1 + argument) % #zone.CAM_VIEWS + 1].name
                zone.autoAt = nil
                pcall(helper16)
                zone.paintCam()
            end
            local function helper174()
                if zone.overMenu() then
                    return
                end
                helper173(1)
            end
            helper163.MouseButton1Click:Connect(helper174)
            local function helper175()
                if zone.overMenu() then
                    return
                end
                helper173(-1)
            end
            helper163.MouseButton2Click:Connect(helper175)
            uiLibrary.tip(
                helper163,
                "The 3D view's camera: TOP (straight down), TILT, 3D, ISO, LOW, CHASE (behind you), ORBIT, FREE (right-drag the map) or AUTO. Left-click for the next, right-click for the one before."
            )
            local function helper176(camCur)
                if camCur.UserInputType ~= Enum.UserInputType.MouseButton2 then
                    return
                elseif zone.cam3On then
                    if zone.overMenu() then
                        return
                    end
                else
                    return
                end
                zone.orbitAt = { x = camCur.Position.X, y = camCur.Position.Y }
                if config.map3DView ~= "FREE" then
                    camCur = zone.camCur
                    config.map3DFreePitch = camCur and math.clamp(camCur.p, 8, 89.5) or 55
                    config.map3DFreeYaw = camCur and camCur.y or 0
                    config.map3DView = "FREE"
                    zone.paintCam()
                end
            end
            hit.InputBegan:Connect(helper176)
            sliderConnections[#sliderConnections + 1] = userInputService.InputChanged:Connect(function(input)
                local orbitAt = zone.orbitAt
                if orbitAt then
                    if input.UserInputType ~= Enum.UserInputType.MouseMovement then
                        return
                    end
                else
                    return
                end
                local value, value2 = input.Position.X - orbitAt.x, input.Position.Y - orbitAt.y
                orbitAt.x, orbitAt.y = input.Position.X, input.Position.Y
                config.map3DFreeYaw = ((tonumber(config.map3DFreeYaw) or 0) - value * 0.35) % 360
                config.map3DFreePitch =
                    math.clamp((tonumber(config.map3DFreePitch) or 55) + value2 * 0.3, 8, 89.5)
            end)
            sliderConnections[#sliderConnections + 1] = userInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton2 then
                    if zone.orbitAt then
                        zone.orbitAt = nil
                        pcall(helper16)
                    end
                end
            end)
            zone.camBox = camBox
            zone.paintCam()
        end
        zone.setAccent = function(argument)
            if typeof(argument) ~= "Color3" then
                return
            end
            local green2 = theme2.Green
            theme2.Green = argument
            local function helper6(argument2)
                return argument2
                    and math.abs(argument2.R - green2.R)
                            + math.abs(argument2.G - green2.G)
                            + math.abs(argument2.B - green2.B)
                        < 0.012
            end
            for index, descendant in ipairs(hlMinimap:GetDescendants()) do
                if not (descendant:IsDescendantOf(sharedValue52)) then
                    if descendant:IsA("GuiObject") then
                        if helper6(descendant.BackgroundColor3) then
                            descendant.BackgroundColor3 = argument
                        end
                    end
                    if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
                        if helper6(descendant.TextColor3) then
                            descendant.TextColor3 = argument
                        end
                    end
                    if descendant:IsA("UIStroke") then
                        if helper6(descendant.Color) then
                            descendant.Color = argument
                        end
                    end
                end
            end
            if zone.apply then
                pcall(zone.apply)
            end
        end
        zone.opacity = function()
            return 100
        end
        zone.opaque = function()
            return true
        end
        local statsFrame = helper155("Frame", {
            Name = "Stats",
            BackgroundColor3 = theme2.Panel,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -16, 0, sharedValue45),
            Size = UDim2.new(0, sharedValue42, 1, -80),
            ZIndex = 2,
            Visible = false,
        }, hlMinimap)
        helper156(statsFrame, 14)
        helper157(statsFrame)
        helper160(statsFrame, {
            Text = "Stats",
            FontFace = sharedValue41.Bold,
            TextSize = 18,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 18, 0, 27),
        })
        helper155("Frame", {
            Position = UDim2.fromOffset(0, 55),
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = theme2.StrokeSoft,
        }, statsFrame)
        zone.statsFrame = statsFrame
        zone.viewFrame = view
        do
            local statsArrow = helper155("TextButton", {
                Name = "StatsArrow",
                Text = ">",
                AutoButtonColor = false,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -378, 0.5, 0),
                Size = UDim2.fromOffset(14, 48),
                BackgroundColor3 = theme2.Raised,
                TextColor3 = theme2.Muted,
                FontFace = sharedValue41.Bold,
                TextSize = 14,
                ZIndex = 6,
                Visible = false,
            }, hlMinimap)
            helper156(statsArrow, 7)
            local sharedValue64 = helper157(statsArrow)
            local function helper177()
                helper154(statsArrow, 0.15, { TextColor3 = theme2.Text })
                helper154(sharedValue64, 0.15, { Color = theme2.Purple })
            end
            statsArrow.MouseEnter:Connect(helper177)
            local function helper178()
                helper154(statsArrow, 0.15, { TextColor3 = theme2.Muted })
                helper154(sharedValue64, 0.15, { Color = theme2.Stroke })
            end
            statsArrow.MouseLeave:Connect(helper178)
            local function helper179()
                if zone.overMenu() then
                    return
                end
                config.mapStatsHidden = config.mapStatsHidden ~= true
                pcall(helper16)
                if zone.apply then
                    zone.apply()
                end
            end
            statsArrow.Activated:Connect(helper179)
            uiLibrary.tip(
                statsArrow,
                "Fold the Stats sidebar away (the map takes the whole width) - click again to bring it back."
            )
            zone.statsArrow = statsArrow
        end
        local sharedValue65 = helper155("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(18, 76),
            Size = UDim2.new(1, -40, 0, 76),
        }, statsFrame)
        helper155("UIGridLayout", {
            CellSize = UDim2.new(0.5, -8, 1, 0),
            CellPadding = UDim2.fromOffset(16, 0),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, sharedValue65)
        local function helper180(layoutOrder, text)
            local value = helper155(
                "Frame",
                { BackgroundColor3 = theme2.Raised, LayoutOrder = layoutOrder },
                sharedValue65
            )
            helper156(value, 10)
            helper157(value, theme2.StrokeSoft)
            helper158(value, 12, 14)
            layoutOrder = helper160(
                value,
                { Text = "-", FontFace = sharedValue41.Bold, TextSize = 30, TextColor3 = theme2.Green }
            )
            helper160(value, {
                Text = text,
                TextSize = 12,
                TextColor3 = theme2.Muted,
                AnchorPoint = Vector2.new(0, 1),
                Position = UDim2.fromScale(0, 1),
            })
            return layoutOrder
        end
        local textControl28 = helper180(1, "Session wins")
        local textControl29 = helper180(2, "Win rate")
        local sharedValue66 = helper155("ScrollingFrame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(18, 176),
            Size = UDim2.new(1, -26, 1, -190),
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = theme2.Stroke,
        }, statsFrame)
        helper159(sharedValue66, false, 18)
        helper158(sharedValue66, 0, 14, 0, 0)
        local sharedValue67, layoutOrder2 = {}, 0
        local function weakKeys5(argument, argument2)
            layoutOrder2 += 1
            local value = helper155("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                LayoutOrder = layoutOrder2,
            }, sharedValue66)
            helper159(value, false, 0)
            local value2 = helper155(
                "Frame",
                { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = 0 },
                value
            )
            helper160(value2, {
                Text = string.upper(argument),
                FontFace = sharedValue41.Semi,
                TextSize = 11,
                TextColor3 = theme2.Faint,
                Size = UDim2.fromOffset(0, 16),
            })
            helper155("Frame", {
                AnchorPoint = Vector2.new(0, 1),
                Position = UDim2.new(0, 0, 1, -2),
                Size = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = theme2.StrokeSoft,
            }, value2)
            for index, entry in ipairs(argument2) do
                local text, value3, value4 =
                    entry[1],
                    entry[2],
                    helper155(
                        "Frame",
                        { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = index },
                        value
                    )
                helper160(value4, {
                    Text = text,
                    TextColor3 = theme2.Muted,
                    Size = UDim2.fromScale(0, 1),
                    AutomaticSize = Enum.AutomaticSize.X,
                })
                index = nil
                if value3 then
                    argument = helper155("Frame", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        Position = UDim2.fromScale(1, 0.5),
                        AutomaticSize = Enum.AutomaticSize.X,
                        Size = UDim2.fromOffset(0, 20),
                        BackgroundColor3 = theme2.Green,
                        BackgroundTransparency = 0.86,
                    }, value4)
                    helper156(argument, 10)
                    helper158(argument, 0, 9)
                    index = helper160(argument, {
                        Text = "-",
                        FontFace = sharedValue41.Semi,
                        TextSize = 13,
                        TextColor3 = theme2.Green,
                        Size = UDim2.fromScale(0, 1),
                        AutomaticSize = Enum.AutomaticSize.X,
                    })
                else
                    index = helper160(value4, {
                        Text = "-",
                        FontFace = sharedValue41.Semi,
                        TextXAlignment = Enum.TextXAlignment.Right,
                        AnchorPoint = Vector2.new(1, 0.5),
                        Position = UDim2.fromScale(1, 0.5),
                        Size = UDim2.new(0.64, 0, 1, 0),
                        AutomaticSize = Enum.AutomaticSize.None,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                    })
                end
                sharedValue67[text] = index
            end
        end
        local sharedValue68 = helper155("Frame", {
            Name = "BossHud",
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 76),
            Size = UDim2.fromOffset(config.mapBossBarW or 400, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            ZIndex = 55,
        }, view)
        helper159(sharedValue68, false, 10, Enum.HorizontalAlignment.Center)
        local sharedValue69 = helper155("Frame", {
            Name = "Timer",
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.fromOffset(0, 32),
            BackgroundColor3 = theme2.Raised,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0, 27),
            ZIndex = 55,
            Visible = false,
        }, view)
        helper156(sharedValue69, 8)
        helper157(sharedValue69)
        helper158(sharedValue69, 0, 14)
        local textControl30 = helper160(sharedValue69, {
            Text = "00:00",
            FontFace = sharedValue41.Mono,
            TextSize = 16,
            Size = UDim2.fromScale(0, 1),
            AutomaticSize = Enum.AutomaticSize.X,
        })
        local sharedValue70 = helper155("Frame", {
            Name = "BossBar",
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = theme2.Raised,
            BackgroundTransparency = 0.08,
            LayoutOrder = 2,
            Visible = false,
        }, sharedValue68)
        helper156(sharedValue70, 10)
        helper157(sharedValue70)
        helper158(sharedValue70, 12, 14, 14, 14)
        helper159(sharedValue70, false, 8)
        viewBox = helper155(
            "Frame",
            { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, LayoutOrder = 1 },
            sharedValue70
        )
        helper163 = helper155(
            "Frame",
            { BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromScale(0, 1) },
            viewBox
        )
        helper159(helper163, true, 8)
        helper161(helper163, theme2.Purple, 8, 1)
        local textControl31 =
            helper160(helper163, { Text = "", FontFace = sharedValue41.Semi, TextSize = 14, LayoutOrder = 2 })
        local textControl32 = helper160(viewBox, {
            Text = "",
            FontFace = sharedValue41.Mono,
            TextSize = 13,
            TextColor3 = theme2.Muted,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.fromScale(1, 0.5),
            TextXAlignment = Enum.TextXAlignment.Right,
        })
        helper162 = helper155(
            "Frame",
            { Size = UDim2.new(1, 0, 0, 6), BackgroundColor3 = theme2.Bg, LayoutOrder = 2 },
            sharedValue70
        )
        helper156(helper162, 3)
        local sharedValue71 =
            helper155("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = theme2.White }, helper162)
        helper156(sharedValue71, 3)
        helper155("UIGradient", { Color = ColorSequence.new(theme2.Purple, theme2.Pink) }, sharedValue71)
        local sharedValue72 = { on = false, want = {}, conns = {} }
        local function helper181(argument)
            if argument:IsA("ScreenGui") then
                if argument == runtimeState.scriptGui then
                    return
                end
            else
                return
            end
            if sharedValue72.want[argument] == nil then
                sharedValue72.want[argument] = argument.Enabled
                sharedValue72.conns[#sharedValue72.conns + 1] = argument
                    :GetPropertyChangedSignal("Enabled")
                    :Connect(function()
                        if sharedValue72.on then
                            if argument.Enabled then
                                sharedValue72.want[argument] = true
                                pcall(function()
                                    argument.Enabled = false
                                end)
                            end
                        end
                    end)
            end
            if argument.Enabled then
                pcall(function()
                    argument.Enabled = false
                end)
            end
        end
        sharedValue72.bossBarDone = function()
            local success, value = pcall(function()
                local value2 = require(localPlayer.PlayerScripts.Ui.bossHealth)
                if type(value2) ~= "table" then
                    return false
                elseif type(value2.ConnectBoss) ~= "function" then
                    return false
                end
                local value3 = value2.ConnectedBoss
                value2 = type(value3) == "table" and value3.boss or nil
                if typeof(value2) == "Instance" then
                    value3 = workspace
                    if not (value2:IsDescendantOf(value3)) then
                        return true
                    end
                else
                    return true
                end
                value3 = value2:FindFirstChildOfClass("Humanoid")
                return not (value3 and value3.Health > 0)
            end)
            return success and value == true
        end
        sharedValue72.set = function(argument)
            if argument == sharedValue72.on then
                return
            end
            sharedValue72.on = argument
            if argument then
                local playerGui = localPlayer:FindFirstChildOfClass("PlayerGui")
                if playerGui then
                    for index, child in ipairs(playerGui:GetChildren()) do
                        pcall(helper181, child)
                    end
                    sharedValue72.conns[#sharedValue72.conns + 1] = playerGui.ChildAdded:Connect(
                        function(argument2)
                            task.defer(function()
                                if sharedValue72.on then
                                    pcall(helper181, argument2)
                                end
                            end)
                        end
                    )
                end
            else
                for index2, conn in ipairs(sharedValue72.conns) do
                    pcall(conn.Disconnect, conn)
                end
                sharedValue72.conns = {}
                for key, entry in pairs(sharedValue72.want) do
                    if entry and key.Name == "bossHealth" and sharedValue72.bossBarDone() then
                        entry = false
                    end
                    pcall(function()
                        if key.Parent then
                            key.Enabled = entry
                        end
                    end)
                end
                sharedValue72.want = {}
            end
        end
        zone.GH = sharedValue72
        zone.stopGui = function()
            sharedValue72.set(false)
        end
        if not zone.big then
            pcall(function()
                local bossHealth = localPlayer.PlayerGui:FindFirstChild("bossHealth")
                if bossHealth then
                    if bossHealth:IsA("ScreenGui") then
                        if bossHealth.Enabled then
                            if sharedValue72.bossBarDone() then
                                bossHealth.Enabled = false
                            end
                        end
                    end
                end
            end)
        end
        zone.drawTimer = function()
            local value = localPlayer:FindFirstChildOfClass("PlayerGui")
            local value2 = value and (value:FindFirstChild("timeLeftGui"))
            value = value2 and (value2:FindFirstChild("Frame"))
            local textControl, text = value and (value:FindFirstChild("time"))
            if value2 and (value2.Enabled or sharedValue72.want[value2] == true) then
                if value then
                    if value:IsA("GuiObject") then
                        if value.Visible then
                            if textControl then
                                if textControl:IsA("TextLabel") then
                                    if textControl.Visible then
                                        local value3 = tostring(textControl.Text)
                                        text = if value3:match("%d+:%d%d") then value3 else text
                                    end
                                end
                            end
                        end
                    end
                end
            end
            if not text then
                if sharedValue69.Visible then
                    sharedValue69.Visible = false
                end
                return
            end
            if textControl30.Text ~= text then
                textControl30.Text = text
            end
            value2 = {}
            for entry in text:gmatch("%d+") do
                value2[#value2 + 1] = tonumber(entry)
            end
            value = 0
            for index, entry2 in ipairs(value2) do
                value = value * 60 + entry2
            end
            textControl30.TextColor3 = value < 60 and theme2.Red or theme2.Text
            if zone.big then
                if not (zone.blank()) then
                    if not sharedValue69.Visible then
                        sharedValue69.Visible = true
                    end
                end
            end
        end
        zone.drawBoss = function()
            local value, humanoid
            local value2, value3 = math.huge, hazardReader.rodinRig
            if value3 then
                if value3.Parent then
                    local humanoid2 = value3:FindFirstChildOfClass("Humanoid")
                    if humanoid2 then
                        if humanoid2.Health > 0 then
                            value, humanoid = value3, humanoid2
                        end
                    end
                end
            end
            if not value then
                value3 = localPlayer.Character
                local value4 = value3 and (value3:FindFirstChild("HumanoidRootPart"))
                for index, entry in ipairs(hazardReader.enemies or {}) do
                    if entry.isBoss then
                        if entry.model then
                            if entry.model.Parent then
                                if entry.humanoid then
                                    if entry.humanoid.Health > 0 then
                                        index = value4
                                                and (entry.x - value4.Position.X) ^ 2 + (entry.z - value4.Position.Z) ^ 2
                                            or 0
                                        if index < value2 then
                                            local model, humanoid3 = entry.model, entry.humanoid
                                            value2, value, humanoid = index, model, humanoid3
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            if not (value and humanoid and humanoid.MaxHealth > 0) then
                if sharedValue70.Visible then
                    sharedValue70.Visible = false
                end
                return
            end
            value2 = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            textControl31.Text = value.Name
            textControl32.Text = ("%.1f%%"):format(value2 * 100)
            sharedValue71.Size = UDim2.fromScale(value2, 1)
            if not sharedValue70.Visible then
                sharedValue70.Visible = true
            end
        end
        viewBox = {
            { "Session", { { "Runs lost" }, { "Mob kills" }, { "Boss kills" } } },
            { "This run", { { "Dungeon" }, { "Run time" }, { "Deaths" }, { "Kills" } } },
            { "Around you", { { "Mobs" }, { "Bosses" }, { "Enemy attacks" }, { "Players" } } },
            { "You", { { "Level" }, { "Gold" }, { "Gems" }, { "Ping" }, { "FPS" } } },
            { "Bot", { { "Doing", true }, { "Queue" }, { "Mod detection" } } },
        }
        for index28, entry31 in ipairs(viewBox) do
            weakKeys5(entry31[1], entry31[2])
        end
        local function helper182(argument)
            argument = tonumber(argument) or 0
            local value = math.abs(argument)
            if value >= 1000000000000 then
                return ("%.2fT"):format(argument / 1000000000000)
            end
            if value >= 1000000000 then
                return ("%.2fB"):format(argument / 1000000000)
            end
            if value >= 1000000 then
                return ("%.2fM"):format(argument / 1000000)
            end
            if value >= 1000 then
                return ("%.1fK"):format(argument / 1000)
            end
            return tostring(math.floor(argument))
        end
        local function helper183(argument)
            argument = math.max(math.floor(argument), 0)
            local value = math.floor(argument / 60)
            return ("%d:%02d"):format(value, argument % 60)
        end
        local sharedValue73 = getService("Stats")
        zone.drawStats = function()
            local value, w, value2 = context.WH, context.ST, context.MD
            local text, value3 = value and value.wins or 0, value and value.losses or 0
            textControl28.Text = tostring(text)
            textControl29.Text = text + value3 > 0
                    and ("%d%%"):format(math.floor(text / (text + value3) * 100 + 0.5))
                or "-"
            sharedValue67["Runs lost"].Text = tostring(value3)
            text = value and value.run
            local value4, text2 =
                sharedValue67.Dungeon,
                text and tostring(text.dungeon or "?") .. ", " .. tostring(text.difficulty or "?")
                    or (context.LB and context.LB.place == "Lobby" and "in the lobby" or "-")
            value4.Text = text2
            sharedValue67["Run time"].Text = text and text.at and helper183(value.runSecs(text)) or "-"
            sharedValue67.Deaths.Text = text and tostring(text.deaths or 0) or "-"
            text2, value4 = value and value.mobKills or 0, value and value.bossKills or 0
            sharedValue67["Mob kills"].Text = tostring(text2)
            sharedValue67["Boss kills"].Text = tostring(value4)
            if text then
                value, value3 =
                    math.max(text2 - (text.killM or text2), 0), math.max(value4 - (text.killB or value4), 0)
                sharedValue67.Kills.Text = ("%d mob%s, %d boss%s"):format(
                    value,
                    value == 1 and "" or "s",
                    value3,
                    value3 == 1 and "" or "es"
                )
            else
                sharedValue67.Kills.Text = "-"
            end
            text = nil
            value4, value = 0, 0
            for index, entry in ipairs(hazardReader.enemies or {}) do
                if entry.isBoss then
                    value4 = value4 + 1
                else
                    value = value + 1
                end
            end
            text2 = hazardReader.rodinRig
            if text2 then
                if text2.Parent then
                    value3 = text2:FindFirstChildOfClass("Humanoid")
                    text = if value3
                        then if value3.MaxHealth > 0
                            then math.floor(value3.Health / value3.MaxHealth * 100 + 0.5)
                            else text
                        else text
                end
            end
            sharedValue67.Mobs.Text = tostring(value)
            sharedValue67.Bosses.Text = tostring(value4) .. (text and " - Rodin " .. text .. "%" or "")
            value4, value3 = context.DG and context.DG.now or os.clock(), 0
            for index2, entry2 in ipairs(context.DG and context.DG.boxes or {}) do
                value3 = if entry2.attack
                    then if entry2.untilAt
                        then if value4 <= entry2.untilAt then value3 + 1 else value3
                        else value3
                    else value3
            end
            sharedValue67["Enemy attacks"].Text = tostring(value3)
            sharedValue67.Players.Text = tostring(#sharedValue5:GetPlayers())
            local leaderstats = localPlayer:FindFirstChild("leaderstats")
            local function helper6(argument)
                local valueObject = leaderstats and (leaderstats:FindFirstChild(argument))
                return valueObject and valueObject.Value
            end
            sharedValue67.Level.Text = tostring(helper6("Level") or "-")
            sharedValue67.Gold.Text = helper6("Gold") and helper182((helper6("Gold"))) or "-"
            sharedValue67.Gems.Text = helper6("Gems") and helper182((helper6("Gems"))) or "-"
            local value5
            pcall(function()
                value5 = sharedValue73.Network.ServerStatsItem["Data Ping"]:GetValue()
            end)
            sharedValue67.Ping.Text = value5 and ("%d ms"):format(math.floor(value5 + 0.5)) or "-"
            sharedValue67.FPS.Text = tostring(zone.fps or 0)
            sharedValue67.Doing.Text = os.clock() - (zone.movedAt or -math.huge) < 0.6 and "cooking"
                or "chilling"
            sharedValue67.Queue.Text = tostring(context.LB and context.LB.status or "-")
            text = if config.modDetect == true
                then if value2
                    then value2.hold and value2.left and value2.left() > 0 and "resting, " .. helper183(
                        value2.left()
                    ) .. " left" or "watching"
                    else "off"
                else "off"
            sharedValue67["Mod detection"].Text = text
        end
        local sharedValue74, setMetatable2, sharedValue75 = {}, setmetatable, { __mode = "k" }
        local sharedValue76 = setMetatable2({}, sharedValue75)
        local function helper184(argument, make)
            sharedValue74[argument] = { items = {}, n = 0, make = make }
        end
        helper184("round", function()
            local parent = Instance.new("Frame")
            parent.BorderSizePixel, parent.AnchorPoint = 0, Vector2.new(0.5, 0.5)
            parent.Visible = false
            local value = Instance.new("UICorner")
            value.CornerRadius = UDim.new(1, 0)
            value.Parent = parent
            value = Instance.new("UIStroke")
            value.Enabled = false
            value.Parent = parent
            sharedValue76[parent] = value
            parent.Parent = view
            return parent
        end)
        helper184("rect", function()
            local frame = Instance.new("Frame")
            frame.BorderSizePixel, frame.AnchorPoint = 0, Vector2.new(0.5, 0.5)
            frame.Visible = false
            frame.Parent = view
            return frame
        end)
        helper184("label", function()
            local label = Instance.new("TextLabel")
            label.BackgroundTransparency, label.AnchorPoint, label.Size =
                1, Vector2.new(0, 0.5), UDim2.fromOffset(200, 14)
            label.Visible = false
            label.TextSize, label.TextStrokeTransparency, label.ZIndex, label.TextXAlignment =
                12, 0.35, 9, Enum.TextXAlignment.Left
            uiLibrary.setFont(label, "sans", Enum.FontWeight.Medium)
            if sharedValue41.Medium then
                pcall(function()
                    label.FontFace = sharedValue41.Medium
                end)
            end
            label.Parent = view
            return label
        end)
        helper184("fuse", function()
            local label = Instance.new("TextLabel")
            label.BackgroundTransparency, label.AnchorPoint, label.Size =
                1, Vector2.new(0.5, 1), UDim2.fromOffset(40, 14)
            label.Visible = false
            label.TextSize, label.TextStrokeTransparency, label.ZIndex, label.TextXAlignment =
                13, 0.2, 10, Enum.TextXAlignment.Center
            uiLibrary.setFont(label, "sans", Enum.FontWeight.Bold)
            label.Parent = view
            return label
        end)
        sharedValue75, weakKeys5 = setmetatable, { __mode = "k" }
        local sharedValue77, setMetatable3, weakKeys6 =
            sharedValue75({}, weakKeys5), setmetatable, { __mode = "k" }
        local sharedValue78 = setMetatable3({}, weakKeys6)
        helper184("arc", function()
            local parent = Instance.new("Frame")
            parent.BorderSizePixel, parent.AnchorPoint = 0, Vector2.new(0.5, 0.5)
            parent.Visible = false
            parent.BackgroundTransparency = 1
            local parent2 = Instance.new("UICorner")
            parent2.CornerRadius = UDim.new(1, 0)
            parent2.Parent = parent
            parent2 = Instance.new("UIStroke")
            parent2.Parent = parent
            local gradient = Instance.new("UIGradient")
            gradient.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.499, 1),
                NumberSequenceKeypoint.new(0.5, 0),
                NumberSequenceKeypoint.new(1, 0),
            })
            gradient.Parent = parent2
            sharedValue76[parent] = parent2
            sharedValue77[parent] = gradient
            parent.Parent = view
            return parent
        end)
        helper184("bar", function()
            local parent = Instance.new("Frame")
            parent.BorderSizePixel, parent.AnchorPoint = 0, Vector2.new(0.5, 0)
            parent.Visible = false
            parent.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
            parent.BackgroundTransparency = 0.3
            local fill = Instance.new("Frame")
            fill.Name, fill.BorderSizePixel, fill.Size = "Fill", 0, UDim2.fromScale(1, 1)
            fill.Parent = parent
            sharedValue78[parent] = fill
            parent.Parent = view
            return parent
        end)
        local function helper185(argument)
            local value = sharedValue74[argument]
            value.n = value.n + 1
            argument = value.items[value.n]
            if not argument then
                argument = value.make()
                value.items[value.n] = argument
            end
            return argument
        end
        local function helper186()
            for key, entry in pairs(sharedValue74) do
                key = entry.items
                for index = 1, #key, 1 do
                    local visible = index <= entry.n
                    if key[index].Visible ~= visible then
                        key[index].Visible = visible
                    end
                end
                entry.n = 0
            end
        end
        local sharedValue79, sharedValue80, sharedValue81, sharedValue82, sharedValue83 = 0, 0, 0, 0, 1
        local function helper187(argument, argument2)
            local value, value2, value3 =
                sharedValue79 * 0.5 + (argument - sharedValue81) * sharedValue83,
                sharedValue80 * 0.5,
                (argument2 - sharedValue82) * sharedValue83
            return value, value2 + value3
        end
        local function helper188(argument, argument2, argument3)
            local value = argument + argument3 >= 0
                and argument - argument3 <= sharedValue79
                and argument2 + argument3 >= 0
                and argument2 - argument3 <= sharedValue80
            return value
        end
        local function helper189(argument, argument2, argument3, argument4, argument5, zIndex, thickness)
            local value, value2 = helper187(argument, argument2)
            if not (helper188(value, value2, argument3)) then
                return
            end
            argument = helper185("round")
            argument.Position, argument.Size =
                UDim2.fromOffset(value, value2), UDim2.fromOffset(argument3 * 2, argument3 * 2)
            argument.ZIndex = zIndex
            argument2 = sharedValue76[argument]
            if thickness then
                argument.BackgroundTransparency = 1
                argument2.Enabled = true
                argument2.Color = argument4
                argument2.Thickness = thickness
                argument2.Transparency = argument5
            else
                argument.BackgroundColor3 = argument4
                argument.BackgroundTransparency = argument5
                if argument2.Enabled then
                    argument2.Enabled = false
                end
            end
        end
        local function helper190(
            argument,
            argument2,
            argument3,
            argument4,
            argument5,
            backgroundColor3,
            backgroundTransparency,
            zIndex
        )
            local value, value2 = helper187(argument, argument2)
            argument2, argument =
                math.max(argument3 * 2 * sharedValue83, 1), math.max(argument4 * 2 * sharedValue83, 1)
            if not (helper188(value, value2, math.max(argument2, argument))) then
                return
            end
            argument4 = helper185("rect")
            argument4.Position, argument4.Size, argument4.Rotation =
                UDim2.fromOffset(value, value2), UDim2.fromOffset(argument2, argument), math.deg(argument5)
            argument4.ZIndex = zIndex
            argument4.BackgroundColor3 = backgroundColor3
            argument4.BackgroundTransparency = backgroundTransparency
        end
        local function helper191(argument, argument2, text, textColor3, argument3)
            local value, value2 = helper187(argument, argument2)
            if not (helper188(value, value2, 80)) then
                return
            end
            argument2 = helper185("label")
            argument2.Position = UDim2.fromOffset(value + argument3 + 4, value2)
            argument2.Text = text
            argument2.TextColor3 = textColor3
        end
        local red = theme2.Red
        local purple = theme2.Purple
        local white = theme2.White
        local blue = theme2.Blue
        local orb = theme2.Orb
        local color2 = Color3.fromRGB(110, 116, 132)
        local function helper192()
            local value = localPlayer.Character
            local value2 = value and (value:FindFirstChild("HumanoidRootPart"))
            if value2 then
                zone.cx, zone.cy, zone.cz = value2.Position.X, value2.Position.Y, value2.Position.Z
            end
            if not zone.cx then
                return false
            end
            value2 = view.AbsoluteSize
            if config.mapFollow == false then
                local value3, value4, value5 = zone.anchor(), value2.X, value2.Y
                local value6, value7 = value3.x, value3.z
                sharedValue79, sharedValue80, sharedValue81, sharedValue82 = value4, value5, value6, value7
            else
                local value8, value9, value10 = zone.big and zone.freeAt or nil, value2.X, value2.Y
                local value11, value12 = value8 and value8.x or zone.cx, value8 and value8.z or zone.cz
                sharedValue79, sharedValue80, sharedValue81, sharedValue82 = value9, value10, value11, value12
            end
            value = zone.big and (config.minimapBigRange or 160) or (config.minimapRange or 110)
            sharedValue83 = math.min(sharedValue79, sharedValue80)
                * 0.5
                / value
                * (zone.big and zone.zoomB or zone.zoomS)
            value2 = sharedValue83
            return value2 > 0
        end
        local function helper193(argument, argument2, argument3, argument4)
            local transform, size, value = argument.CFrame, argument.Size, argument:IsA("Part")
            local value2 = value and argument.Shape or nil
            if value2 == Enum.PartType.Ball then
                helper189(
                    transform.X,
                    transform.Z,
                    math.max(size.X * 0.5 * sharedValue83, 2),
                    argument2,
                    argument3,
                    argument4
                )
                return
            end
            local rightVector, upVector, lookVector =
                transform.RightVector, transform.UpVector, transform.LookVector
            if value2 == Enum.PartType.Cylinder then
                if math.abs(rightVector.Y) > 0.7 then
                    helper189(
                        transform.X,
                        transform.Z,
                        math.max(math.min(size.Y, size.Z) * 0.5 * sharedValue83, 2),
                        argument2,
                        argument3,
                        argument4
                    )
                else
                    helper190(
                        transform.X,
                        transform.Z,
                        size.X * 0.5,
                        math.min(size.Y, size.Z) * 0.5,
                        math.atan2(rightVector.Z, rightVector.X),
                        argument2,
                        argument3,
                        argument4
                    )
                end
                return
            end
            local value3, value4, value5 =
                math.abs(rightVector.Y), math.abs(upVector.Y), math.abs(lookVector.Y)
            local value6, value7, value8
            if value4 >= value3 and value4 >= value5 then
                value6, value7, value8 = rightVector, size.X * 0.5, size.Z * 0.5
            else
                if value3 >= value5 then
                    value6, value7, value8 = upVector, size.Y * 0.5, size.Z * 0.5
                else
                    value6, value7, value8 = rightVector, size.X * 0.5, size.Y * 0.5
                end
            end
            if if value then argument:FindFirstChildOfClass("SpecialMesh") ~= nil else not value then
                if value7 > 1 then
                    if value8 > 1 then
                        if math.abs(value7 - value8) <= math.max(value7, value8) * 0.1 then
                            helper189(
                                transform.X,
                                transform.Z,
                                math.max(value7, value8) * sharedValue83,
                                argument2,
                                argument3,
                                argument4
                            )
                            return
                        end
                    end
                end
            end
            helper190(
                transform.X,
                transform.Z,
                value7,
                value8,
                math.atan2(value6.Z, value6.X),
                argument2,
                argument3,
                argument4
            )
        end
        local function helper194(
            argument,
            argument2,
            argument3,
            argument4,
            argument5,
            color,
            transparency,
            zIndex
        )
            local value, value2 = helper187(argument, argument2)
            if not (helper188(value, value2, argument3 * sharedValue83)) then
                return
            end
            argument2, argument = math.max((argument3 - argument4) * sharedValue83, 1), helper185("arc")
            argument.Position, argument.Size =
                UDim2.fromOffset(value, value2), UDim2.fromOffset(argument2 * 2, argument2 * 2)
            argument.ZIndex = zIndex
            value2 = sharedValue76[argument]
            value2.Color, value2.Thickness = color, math.max(argument4 * sharedValue83, 1)
            value2.Transparency = transparency
            sharedValue77[argument].Rotation = math.deg(argument5)
        end
        zone.clearMarks = function()
            for key, entry in pairs(sharedValue74) do
                entry.n = 0
            end
            helper186()
        end
        zone.fuse3 = {}
        zone.drawFuse3D = function(argument)
            local value, camera = 0, workspaceService.CurrentCamera
            if argument then
                if config.orbFuseLabels ~= false then
                    if hazardReader.orbScan then
                        if camera then
                            local absolutePosition, value2, now, value3 =
                                view.AbsolutePosition, {}, os.clock(), value
                            for index, entry in ipairs(hazardReader.orbScan) do
                                index = entry.part
                                entry = index and hazardReader.parts[index]
                                if index then
                                    if index.Parent then
                                        if entry then
                                            if entry.spawn then
                                                if not value2[index] then
                                                    value2[index] = true
                                                    local vector, value4 = camera:WorldToScreenPoint(
                                                        index.Position + Vector3.new(0, 3.5, 0)
                                                    )
                                                    if value4 then
                                                        local value5 = value3 + 1
                                                        local hlFuse3D = zone.fuse3[value5]
                                                        if not hlFuse3D then
                                                            hlFuse3D = Instance.new("TextLabel")
                                                            hlFuse3D.Name = "HLFuse3D"
                                                            hlFuse3D.BackgroundTransparency, hlFuse3D.AnchorPoint, hlFuse3D.Size =
                                                                1,
                                                                Vector2.new(0.5, 1),
                                                                UDim2.fromOffset(44, 16)
                                                            hlFuse3D.TextSize = 15
                                                            hlFuse3D.TextStrokeTransparency = 0.15
                                                            hlFuse3D.ZIndex = 12
                                                            hlFuse3D.Font = Enum.Font.GothamBold
                                                            hlFuse3D.Parent = view
                                                            zone.fuse3[value5] = hlFuse3D
                                                        end
                                                        local value6, value7 =
                                                            math.max(
                                                                (config.orbFuse or 20) - (now - entry.spawn),
                                                                0
                                                            ),
                                                            string.lower(index.Name)
                                                        hlFuse3D.TextColor3 = value7:find("red", 1, true)
                                                                and Color3.fromRGB(255, 90, 90)
                                                            or value7:find("green", 1, true) and Color3.fromRGB(
                                                                90,
                                                                255,
                                                                90
                                                            )
                                                            or value7:find("yellow", 1, true) and Color3.fromRGB(
                                                                255,
                                                                235,
                                                                60
                                                            )
                                                            or Color3.new(1, 1, 1)
                                                        hlFuse3D.Text = value6 < 5 and ("%.1f"):format(value6)
                                                            or ("%.0f"):format(value6)
                                                        hlFuse3D.Position = UDim2.fromOffset(
                                                            vector.X - absolutePosition.X,
                                                            vector.Y - absolutePosition.Y
                                                        )
                                                        if not hlFuse3D.Visible then
                                                            hlFuse3D.Visible = true
                                                        end
                                                        value3 = value5
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                            value = value3
                        end
                    end
                end
            end
            for index2 = value + 1, #zone.fuse3, 1 do
                if zone.fuse3[index2].Visible then
                    zone.fuse3[index2].Visible = false
                end
            end
        end
        local function helper195(
            argument,
            argument2,
            argument3,
            argument4,
            backgroundColor3,
            argument5,
            zIndex
        )
            local value, value2 = helper187(argument, argument2)
            if not (helper188(value, value2, argument5)) then
                return
            end
            argument = helper185("bar")
            argument.Position, argument.Size =
                UDim2.fromOffset(value, value2 + argument3 + 3), UDim2.fromOffset(argument5, 3)
            argument.ZIndex = zIndex
            value2 = sharedValue78[argument]
            value2.Size = UDim2.fromScale(math.clamp(argument4, 0, 1), 1)
            value2.BackgroundColor3 = backgroundColor3
            value2.ZIndex = zIndex
        end
        zone.draw = function()
            if not (helper192()) then
                helper186()
                return
            end
            local value, value2 = zone.use3D(), context.DG
            local value3, value4, value5 =
                value2 and value2.now or os.clock(), context.WALLS and context.WALLS.parts, zone.cy or 0
            if value4 and not value then
                for index = 1, math.min(#value4, 400), 1 do
                    local value6 = value4[index]
                    if value6 then
                        if value6.Parent then
                            local transform, size = value6.CFrame, value6.Size
                            index = size.Y * 0.5
                            if math.abs(transform.UpVector.Y) > 0.7 then
                                if transform.Y + index > value5 - 1 then
                                    if transform.Y - index < value5 + 4 then
                                        local rightVector = transform.RightVector
                                        helper190(
                                            transform.X,
                                            transform.Z,
                                            size.X * 0.5,
                                            size.Z * 0.5,
                                            math.atan2(rightVector.Z, rightVector.X),
                                            color2,
                                            0.35,
                                            2
                                        )
                                    end
                                end
                            end
                        end
                    end
                end
            end
            value4 = hazardReader.rodinRig
            if value then
            elseif value4 then
                if value4.Parent then
                    if hazardReader.arenaCentre then
                        value5 = hazardReader.arenaCentre
                        helper189(
                            value5.X,
                            value5.Z,
                            (config.rodinSweepArenaR or 100) * sharedValue83,
                            color2,
                            0.3,
                            2,
                            2
                        )
                    end
                end
            end
            value4 = not value
            if if value then value4 else config.mapCrystals ~= false then
                value5 = workspaceService:FindFirstChild("secondBossCrystals")
                if value5 then
                    local iterateArray, value7 = ipairs, argumentHelpers[108](value5:GetChildren())
                    for key, entry in iterateArray(argumentHelpers:unpackValues(value7)) do
                        key = string.lower(entry.Name)
                        local value8 = key == "red" and Color3.fromRGB(255, 60, 60)
                            or key == "green" and Color3.fromRGB(60, 255, 60)
                            or key == "yellow" and Color3.fromRGB(255, 235, 40)
                        if value8 then
                            if entry:IsA("BasePart") then
                                key = math.max(entry.Size.X * 0.5 * sharedValue83, 6)
                                helper189(entry.Position.X, entry.Position.Z, key, value8, 0.15, 6)
                                helper189(entry.Position.X, entry.Position.Z, key + 3, value8, 0.2, 6, 2)
                            end
                        end
                    end
                end
            end
            if (if value then value4 else config.mapOrbLinks ~= false) and hazardReader.orbScan then
                local function helper6(
                    argument,
                    argument2,
                    argument3,
                    argument4,
                    argument5,
                    argument6,
                    argument7
                )
                    local value9, value10 = argument3 - argument, argument4 - argument2
                    local value11 = math.sqrt(value9 * value9 + value10 * value10)
                    if value11 < 1 then
                        return
                    end
                    helper190(
                        (argument + argument3) * 0.5,
                        (argument2 + argument4) * 0.5,
                        value11 * 0.5,
                        argument6 * 0.5 / math.max(sharedValue83, 0.01),
                        math.atan2(value10, value9),
                        argument5,
                        argument7,
                        4
                    )
                end
                value5 = localPlayer.Character
                local value12, value13, value14 =
                    value5 and (value5:FindFirstChild("HumanoidRootPart")),
                    context.otherRoots and context.otherRoots() or {},
                    {}
                for index2, entry2 in ipairs(hazardReader.orbScan) do
                    index2 = entry2.part
                    local value15 = index2 and hazardReader.parts[index2]
                    if index2 and index2.Parent and value15 and not value14[index2] then
                        value14[index2] = true
                        local position, value16 = index2.Position, entry2.colour
                        local value17 = value16 == "red" and Color3.fromRGB(255, 60, 60)
                            or value16 == "green" and Color3.fromRGB(60, 255, 60)
                            or value16 == "yellow" and Color3.fromRGB(255, 235, 40)
                            or Color3.new(1, 1, 1)
                        if entry2.mine and value12 then
                            value16 = hazardReader.orbNear and hazardReader.orbNear.part == index2
                            helper6(
                                value12.Position.X,
                                value12.Position.Z,
                                position.X,
                                position.Z,
                                value17,
                                value16 and 3 or 2,
                                value16 and 0.05 or 0.35
                            )
                        elseif (value15.stick == "other" or value15.owner == "other") and #value13 > 0 then
                            local value18, value19 = math.huge
                            for index3, entry3 in ipairs(value13) do
                                index3 = (entry3.Position.X - position.X) ^ 2
                                    + (entry3.Position.Z - position.Z) ^ 2
                                if index3 < value18 then
                                    value18, value19 = index3, entry3
                                end
                            end
                            value19 = if value15.lineRoot
                                then if value15.lineRoot.Parent then value15.lineRoot else value19
                                else value19
                            if value19 then
                                helper6(
                                    value19.Position.X,
                                    value19.Position.Z,
                                    position.X,
                                    position.Z,
                                    Color3.fromRGB(150, 155, 170),
                                    1,
                                    0.45
                                )
                            end
                        end
                    end
                end
            end
            if (if value then value4 else config.orbFuseLabels ~= false) and hazardReader.orbScan then
                local value20, now, iterateArray2, orbScan = {}, os.clock(), ipairs, hazardReader.orbScan
                for key2, entry4 in iterateArray2(orbScan) do
                    value5 = entry4.part
                    key2 = value5 and hazardReader.parts[value5]
                    if value5 then
                        if value5.Parent then
                            if key2 then
                                if key2.spawn then
                                    if not value20[value5] then
                                        value20[value5] = true
                                        local value21, value22, value23 =
                                            math.max((config.orbFuse or 20) - (now - key2.spawn), 0),
                                            helper187(value5.Position.X, value5.Position.Z)
                                        if helper188(value22, value23, 20) then
                                            entry4 = string.lower(value5.Name)
                                            local textColor3, textControl =
                                                entry4:find("red", 1, true) and Color3.fromRGB(255, 90, 90)
                                                    or entry4:find("green", 1, true) and Color3.fromRGB(
                                                        90,
                                                        255,
                                                        90
                                                    )
                                                    or entry4:find("yellow", 1, true) and Color3.fromRGB(
                                                        255,
                                                        235,
                                                        60
                                                    )
                                                    or Color3.new(1, 1, 1),
                                                helper185("fuse")
                                            textControl.Position = UDim2.fromOffset(
                                                value22,
                                                value23 - math.max(3 * sharedValue83, 5) - 3
                                            )
                                            textControl.Text = value21 < 5 and ("%.1f"):format(value21)
                                                or ("%.0f"):format(value21)
                                            textControl.TextColor3 = textColor3
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            if
                value
                and config.orbFuseLabels ~= false
                and hazardReader.orbScan
                and workspaceService.CurrentCamera
            then
                local camera, absolutePosition, value24, now2 =
                    workspaceService.CurrentCamera, view.AbsolutePosition, {}, os.clock()
                for index4, entry5 in ipairs(hazardReader.orbScan) do
                    value5 = entry5.part
                    index4 = value5 and hazardReader.parts[value5]
                    if value5 then
                        if value5.Parent then
                            if index4 then
                                if index4.spawn then
                                    if not value24[value5] then
                                        value24[value5] = true
                                        local vector, value25 = camera:WorldToScreenPoint(
                                            value5.Position + Vector3.new(0, 3.5, 0)
                                        )
                                        if value25 then
                                            local value26, value27 =
                                                math.max((config.orbFuse or 20) - (now2 - index4.spawn), 0),
                                                string.lower(value5.Name)
                                            local textColor32, textControl2 =
                                                value27:find("red", 1, true) and Color3.fromRGB(255, 90, 90)
                                                    or value27:find("green", 1, true) and Color3.fromRGB(
                                                        90,
                                                        255,
                                                        90
                                                    )
                                                    or value27:find("yellow", 1, true) and Color3.fromRGB(
                                                        255,
                                                        235,
                                                        60
                                                    )
                                                    or Color3.new(1, 1, 1),
                                                helper185("fuse")
                                            textControl2.Position = UDim2.fromOffset(
                                                vector.X - absolutePosition.X,
                                                vector.Y - absolutePosition.Y
                                            )
                                            textControl2.Text = value26 < 5 and ("%.1f"):format(value26)
                                                or ("%.0f"):format(value26)
                                            textControl2.TextColor3 = textColor32
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            local value28, value29, value30 =
                config.colorLive or Color3.fromRGB(255, 50, 50),
                config.colorSoon or Color3.fromRGB(255, 220, 40),
                context.attackColourNow()
            if value30 then
                value28, value29 = value30, value30
            end
            if not value then
                local value31, value32, value33, value34, value35 =
                    0.4, 0.6, 0.35, value2 and value2.boxes or {}, config.minimapMaxAttacks or 250
                value30, value5 = #value34, 0
                for index5 = 1, value30, 1 do
                    if value5 >= value35 then
                        break
                    end
                    local zone2 = value34[index5]
                    if zone2.attack then
                        if zone2.untilAt then
                            if value3 <= zone2.untilAt then
                                if not zone2.gsNoDraw then
                                    local value36, src = value5 + 1, zone2.src
                                    if src and src.Parent and src:IsA("BasePart") then
                                        local value37, value38 =
                                            zone2.moving or value3 >= (zone2.from or value3),
                                            string.lower(src.Name)
                                        index5 = if value38:find("secondboss", 1, true)
                                                and value38:find("orb", 1, true)
                                            then value38:find("red", 1, true) and Color3.fromRGB(255, 60, 60)
                                                or value38:find("green", 1, true) and Color3.fromRGB(
                                                    60,
                                                    255,
                                                    60
                                                )
                                                or value38:find("yellow", 1, true) and Color3.fromRGB(
                                                    255,
                                                    235,
                                                    40
                                                )
                                                or nil
                                            else if value38:find("bouncingorbbad", 1, true)
                                                then if config.mapRodinRedOrb ~= false
                                                    then Color3.fromRGB(255, 30, 30)
                                                    else nil
                                                else nil
                                        helper193(
                                            src,
                                            index5 or (value37 and value28 or value29),
                                            index5 and 0.1
                                                or (
                                                    zone2.moving and value33
                                                    or (value37 and value31 or value32)
                                                ),
                                            value37 and 4 or 3
                                        )
                                    elseif zone2.moving then
                                        local value39 = (zone2.offset or 0)
                                            + (zone2.speed or 0)
                                                * math.max(value3 - (zone2.pathStart or value3), 0)
                                        value39 = if zone2.endAlong
                                            then if value39 > zone2.endAlong then zone2.endAlong else value39
                                            else value39
                                        local value40, value41, value42 =
                                            zone2.ox + zone2.dx * value39,
                                            zone2.oz + zone2.dz * value39,
                                            string.lower(tostring(zone2.name or ""))
                                        local value43 = if value42:find("secondboss", 1, true)
                                            then if value42:find("orb", 1, true)
                                                then value42:find("red", 1, true) and Color3.fromRGB(
                                                    255,
                                                    60,
                                                    60
                                                ) or value42:find(
                                                    "green",
                                                    1,
                                                    true
                                                ) and Color3.fromRGB(
                                                    60,
                                                    255,
                                                    60
                                                ) or value42:find(
                                                    "yellow",
                                                    1,
                                                    true
                                                ) and Color3.fromRGB(
                                                    255,
                                                    235,
                                                    40
                                                ) or nil
                                                else nil
                                            else nil
                                        if value43 then
                                            helper189(
                                                value40,
                                                value41,
                                                math.max((zone2.r or 3) * sharedValue83, 5),
                                                value43,
                                                0,
                                                7
                                            )
                                            helper189(
                                                value40,
                                                value41,
                                                math.max((zone2.r or 3) * sharedValue83, 5) + 2,
                                                Color3.new(1, 1, 1),
                                                0.3,
                                                7,
                                                1
                                            )
                                        else
                                            local value44 = (
                                                value42:find("bouncingorbbad", 1, true)
                                                or value42:find("red orb", 1, true)
                                            )
                                                    and config.mapRodinRedOrb ~= false
                                                    and Color3.fromRGB(255, 30, 30)
                                                or value28
                                            if zone2.r then
                                                helper189(
                                                    value40,
                                                    value41,
                                                    math.max(zone2.r * sharedValue83, 2),
                                                    value44,
                                                    value33,
                                                    4
                                                )
                                            else
                                                helper190(
                                                    value40,
                                                    value41,
                                                    zone2.halfL or 1,
                                                    zone2.halfW or 1,
                                                    math.atan2(zone2.dz, zone2.dx),
                                                    value44,
                                                    value33,
                                                    4
                                                )
                                            end
                                        end
                                    elseif zone2.cx then
                                        local value45 = value3 >= (zone2.from or value3)
                                        local value46, value47 =
                                            value45 and value28 or value29, value45 and value31 or value32
                                        if zone2.r then
                                            if zone2.ring then
                                                helper189(
                                                    zone2.cx,
                                                    zone2.cz,
                                                    (zone2.r + zone2.ring) * 0.5 * sharedValue83,
                                                    value46,
                                                    value47,
                                                    3,
                                                    math.max((zone2.r - zone2.ring) * sharedValue83, 1)
                                                )
                                            else
                                                helper189(
                                                    zone2.cx,
                                                    zone2.cz,
                                                    math.max(zone2.r * sharedValue83, 2),
                                                    value46,
                                                    value47,
                                                    3
                                                )
                                            end
                                        elseif zone2.ha then
                                            helper190(
                                                zone2.cx,
                                                zone2.cz,
                                                zone2.ha,
                                                zone2.hb,
                                                math.atan2(zone2.az, zone2.ax),
                                                value46,
                                                value47,
                                                3
                                            )
                                        end
                                    end
                                    value5 = value36
                                end
                            end
                        end
                    end
                end
                if config.mapPkZones ~= false and context.PK and context.isEvent and context.isEvent() then
                    value33 = #value34
                    for index6 = 1, value33, 1 do
                        value35 = value34[index6]
                        index6 = value35.name
                        if value35.kind == "zone" then
                            if type(index6) == "string" then
                                if index6:sub(1, 3) == "pk " then
                                    if index6 ~= "pk border" then
                                        if value35.untilAt then
                                            if value3 <= value35.untilAt then
                                                if value35.cx then
                                                    local value48 = value3 >= (value35.from or value3)
                                                    local value49, value50 =
                                                        value48 and value28 or value29,
                                                        value48 and value31 or value32
                                                    if value35.r then
                                                        if value35.ring then
                                                            helper189(
                                                                value35.cx,
                                                                value35.cz,
                                                                (value35.r + value35.ring)
                                                                    * 0.5
                                                                    * sharedValue83,
                                                                value49,
                                                                value50,
                                                                3,
                                                                math.max(
                                                                    (value35.r - value35.ring) * sharedValue83,
                                                                    1
                                                                )
                                                            )
                                                        else
                                                            helper189(
                                                                value35.cx,
                                                                value35.cz,
                                                                math.max(value35.r * sharedValue83, 2),
                                                                value49,
                                                                value50,
                                                                3
                                                            )
                                                        end
                                                    elseif value35.ha then
                                                        helper190(
                                                            value35.cx,
                                                            value35.cz,
                                                            value35.ha,
                                                            value35.hb,
                                                            math.atan2(value35.az, value35.ax),
                                                            value49,
                                                            value50,
                                                            3
                                                        )
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    local value51 = workspaceService:FindFirstChild("BossBarriers")
                    if value51 then
                        for index7, child in ipairs(value51:GetChildren()) do
                            if child:IsA("BasePart") then
                                helper193(child, color2, 0.05, 2)
                            end
                        end
                    end
                    value51 = context.PK.arena and context.PK.arena()
                    local value52 = value51 and context.PK.thornDepth and context.PK.thornDepth() or 0
                    if value51 then
                        if value52 > 0 then
                            local value53, value54, value55, value56 =
                                value51.x0, value51.x1, value51.z0, value51.z1
                            local value57, value58, value59, value60 =
                                (value53 + value54) * 0.5,
                                (value55 + value56) * 0.5,
                                (value54 - value53) * 0.5,
                                (value56 - value55) * 0.5
                            helper190(
                                value53 + value52 * 0.5,
                                value58,
                                value52 * 0.5,
                                value60,
                                0,
                                value28,
                                value31,
                                3
                            )
                            helper190(
                                value54 - value52 * 0.5,
                                value58,
                                value52 * 0.5,
                                value60,
                                0,
                                value28,
                                value31,
                                3
                            )
                            helper190(
                                value57,
                                value55 + value52 * 0.5,
                                value59,
                                value52 * 0.5,
                                0,
                                value28,
                                value31,
                                3
                            )
                            helper190(
                                value57,
                                value56 - value52 * 0.5,
                                value59,
                                value52 * 0.5,
                                0,
                                value28,
                                value31,
                                3
                            )
                        end
                    end
                end
                value35 = hazardReader.spikePaths
                if value35 and config.mapSpikePaths ~= false then
                    local now3, value61, value62 = os.clock(), #value35, 0
                    for index8 = value61, 1, -1 do
                        value33 = value35[index8]
                        if now3 <= value33.t1 then
                            if value62 < (config.mapSpikePathMax or 24) then
                                index8 = math.clamp(value33.speed * (now3 - value33.t0), 0, value33.len)
                                value34 = value33.len - index8
                                if value34 > 2 then
                                    local value63, value64, value65, value66, value67 =
                                        value62 + 1,
                                        value33.ox + value33.dx * index8,
                                        value33.oz + value33.dz * index8,
                                        math.atan2(value33.dz, value33.dx),
                                        math.max(1.2 / sharedValue83, 0.6)
                                    helper190(
                                        value64 + value33.dx * value34 * 0.5,
                                        value65 + value33.dz * value34 * 0.5,
                                        value34 * 0.5,
                                        value67,
                                        value66,
                                        value28,
                                        0.6,
                                        3
                                    )
                                    local value68 = config.mapSpikeArrowEvery or 30
                                    local value69 = value68 - index8 % value68
                                    while value69 < value34 - 4 do
                                        local value70, value71, value72 =
                                            value64 + value33.dx * value69,
                                            value65 + value33.dz * value69,
                                            { 1, -1 }
                                        for index9, entry6 in ipairs(value72) do
                                            index9 = value66 + 3.141592653589793 + entry6 * 0.6
                                            helper190(
                                                value70 + math.cos(index9) * 2.5,
                                                value71 + math.sin(index9) * 2.5,
                                                2.5,
                                                value67,
                                                index9,
                                                value28,
                                                0.3,
                                                3
                                            )
                                        end
                                        value69 += value68
                                    end
                                    value62 = value63
                                end
                            end
                        end
                    end
                end
                if workspaceService:FindFirstChild("thirdBossMultiRings") then
                    value35, value34 = ipairs, argumentHelpers[108](workspaceService:GetChildren())
                    for key3, entry7 in value35(argumentHelpers:unpackValues(value34)) do
                        if entry7.Name == "thirdBossMultiRings" then
                            key3, value33 = ipairs, argumentHelpers[108](entry7:GetChildren())
                            for key4, entry8 in key3(argumentHelpers:unpackValues(value33)) do
                                if entry8:IsA("BasePart") then
                                    if entry8.Transparency < 0.95 then
                                        key4 = string.lower(entry8.Name)
                                        if key4 == "ring" and entry8.Size.X > 20 then
                                            local lookVector = entry8.CFrame.LookVector
                                            local value73 = math.sqrt(
                                                lookVector.X * lookVector.X + lookVector.Z * lookVector.Z
                                            )
                                            if value73 > 0.01 then
                                                local value74, value75, position2, value76 =
                                                    lookVector.X / value73,
                                                    lookVector.Z / value73,
                                                    entry8.Position,
                                                    math.max(entry8.Size.X, entry8.Size.Z) * 0.5
                                                local value77 = config.mapRingW
                                                    or (
                                                        value76 >= 100
                                                            and (config.ringThicknessOuter or 17.5)
                                                        or (config.ringThickness or 12.5)
                                                    )
                                                helper194(
                                                    position2.X - value74 * entry8.Size.X * 0.25,
                                                    position2.Z - value75 * entry8.Size.X * 0.25,
                                                    entry8.Size.X * 0.5,
                                                    value77,
                                                    math.atan2(value75, value74),
                                                    value28,
                                                    value31,
                                                    3
                                                )
                                            end
                                        elseif key4 == "center" then
                                            local position3 = entry8.Position
                                            helper189(
                                                position3.X,
                                                position3.Z,
                                                math.max(
                                                    math.max(entry8.Size.Y, entry8.Size.Z)
                                                        * 0.5
                                                        * sharedValue83,
                                                    2
                                                ),
                                                value28,
                                                value31,
                                                3
                                            )
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                value34 = workspaceService:FindFirstChild("bonusBossSweepingFlames")
                if value34 then
                    for index10, child2 in ipairs(value34:GetChildren()) do
                        value35 = child2:FindFirstChild("precast")
                        if value35 then
                            if value35:IsA("BasePart") then
                                if value35.Transparency < 0.9 then
                                    child2 = value35.Transparency < 0.5
                                    helper193(
                                        value35,
                                        child2 and value28 or value29,
                                        child2 and value31 or value32,
                                        child2 and 4 or 3
                                    )
                                end
                            end
                        end
                    end
                end
            end
            value = hazardReader.rodinGoodOrbs
            if value and value4 then
                for entry9 in pairs(value) do
                    if typeof(entry9) == "Instance" then
                        if entry9.Parent then
                            if entry9:IsA("BasePart") then
                                value5, value2 =
                                    entry9.Position, math.max(entry9.Size.X * 0.5 * sharedValue83, 3)
                                helper189(value5.X, value5.Z, value2, orb, 0.15, 5)
                            end
                        end
                    end
                end
            end
            value3, value2, value4 =
                zone.big and config.mapNames ~= false,
                zone.big and config.mapHealthBars ~= false,
                hazardReader.enemies or {}
            value30 = math.min(#value4, 150)
            for index11 = 1, value30, 1 do
                value = value4[index11]
                value5, index11 = value.x, value.z
                if value.root then
                    if value.root.Parent then
                        local position4 = value.root.Position
                        local value78, value79 = position4.X, position4.Z
                        value5, index11 = value78, value79
                    end
                end
                if value5 then
                    if index11 then
                        local value80, value81 =
                            value.isBoss and purple or red,
                            value.isBoss and math.max((value.extent or 3) * sharedValue83, 6) or math.max(
                                (value.extent or 1.5) * sharedValue83,
                                3
                            )
                        helper189(value5, index11, value81, value80, value.isBoss and 0.05 or 0.1, 6)
                        if value3 then
                            if value.model then
                                helper191(value5, index11, value.model.Name, value80, value81)
                            end
                        end
                        local humanoid = value.humanoid
                        if value2 then
                            if humanoid then
                                if humanoid.MaxHealth > 0 then
                                    helper195(
                                        value5,
                                        index11,
                                        value81,
                                        humanoid.Health / humanoid.MaxHealth,
                                        value80,
                                        value.isBoss and 34 or 18,
                                        6
                                    )
                                end
                            end
                        end
                    end
                end
            end
            value4, value5 = ipairs, argumentHelpers[108](sharedValue5:GetPlayers())
            for key5, entry10 in value4(argumentHelpers:unpackValues(value5)) do
                value30 = entry10.Character
                value = value30 and (value30:FindFirstChild("HumanoidRootPart"))
                if value then
                    local position5, humanoid2 = value.Position, value30:FindFirstChildOfClass("Humanoid")
                    if entry10 == localPlayer then
                        key5 = value.CFrame.LookVector
                        local value82 = math.sqrt(key5.X * key5.X + key5.Z * key5.Z)
                        if value82 > 0.1 then
                            local value83 = math.max(10 / sharedValue83, 4)
                            helper190(
                                position5.X + key5.X / value82 * value83 * 0.5,
                                position5.Z + key5.Z / value82 * value83 * 0.5,
                                value83 * 0.5,
                                1 / sharedValue83,
                                math.atan2(key5.Z, key5.X),
                                white,
                                0,
                                8
                            )
                        end
                        helper189(position5.X, position5.Z, 5, white, 0, 8)
                        if value3 then
                            helper191(position5.X, position5.Z, "YOU", white, 5)
                        end
                        if value2 then
                            if humanoid2 then
                                if humanoid2.MaxHealth > 0 then
                                    helper195(
                                        position5.X,
                                        position5.Z,
                                        5,
                                        humanoid2.Health / humanoid2.MaxHealth,
                                        white,
                                        26,
                                        8
                                    )
                                end
                            end
                        end
                    else
                        helper189(position5.X, position5.Z, 4.5, blue, 0, 7)
                        if value3 then
                            if config.streamer ~= true then
                                helper191(position5.X, position5.Z, entry10.Name, blue, 4.5)
                            end
                        end
                        if value2 then
                            if humanoid2 then
                                if humanoid2.MaxHealth > 0 then
                                    helper195(
                                        position5.X,
                                        position5.Z,
                                        4.5,
                                        humanoid2.Health / humanoid2.MaxHealth,
                                        blue,
                                        18,
                                        7
                                    )
                                end
                            end
                        end
                    end
                end
            end
            helper186()
        end
        zone.use3D = function()
            return zone.big == true
                and config.mapBg3D ~= false
                and config.renderOff ~= true
                and not zone.blank()
                and not runtimeState.destroyed
        end
        local sharedValue84, sharedValue85, sharedValue86, sharedValue87 =
            { on = false, orig = {}, conns = {}, gen = 0 }, {
                dungeon = true,
                Map = true,
                map = true,
                Lobby = true,
                lobby = true,
                stairRamps = true,
                thirdBossBounceWalls = true,
                secondBossCrystals = true,
                bossRoomRunes = true,
            }, { NorthernWall = true }, {
                "Grass",
                "Slate",
                "Concrete",
                "Brick",
                "Sand",
                "WoodPlanks",
                "Rock",
                "Glacier",
                "Snow",
                "Sandstone",
                "Mud",
                "Basalt",
                "Ground",
                "CrackedLava",
                "Asphalt",
                "Cobblestone",
                "Ice",
                "LeafyGrass",
                "Salt",
                "Limestone",
                "Pavement",
            }
        local function helper196(argument, argument2, argument3)
            local value = sharedValue84.orig[argument]
            if not value then
                value = {}
                sharedValue84.orig[argument] = value
            end
            if value[argument2] == nil then
                local success, value2 = pcall(function()
                    return argument[argument2]
                end)
                if success then
                    if value2 == nil then
                        return
                    end
                else
                    return
                end
                value[argument2] = value2
            end
            pcall(function()
                argument[argument2] = argument3
            end)
        end
        local function helper197(argument)
            if argument:IsA("BasePart") then
                if argument.Transparency >= 0.98 then
                    return
                end
                helper196(
                    argument,
                    "Color",
                    typeof(config.map3DGrey) == "Color3" and config.map3DGrey or Color3.fromRGB(96, 104, 122)
                )
                helper196(argument, "Material", Enum.Material.SmoothPlastic)
                if argument:IsA("MeshPart") then
                    helper196(argument, "TextureID", "")
                end
                if argument:IsA("UnionOperation") then
                    helper196(argument, "UsePartColor", true)
                end
            elseif argument:IsA("Decal") then
                helper196(argument, "Transparency", 1)
            elseif argument:IsA("Texture") then
                helper196(argument, "Transparency", 1)
            elseif argument:IsA("SpecialMesh") then
                helper196(argument, "TextureId", "")
            elseif argument:IsA("SurfaceAppearance") then
                helper196(argument, "Parent", nil)
            end
        end
        local function helper198(argument)
            local value = (argument:FindFirstAncestorOfClass("Model"))
            while value do
                if value:FindFirstChildOfClass("Humanoid") then
                    return true
                end
                value = (value:FindFirstAncestorOfClass("Model"))
            end
            return false
        end
        local function helper199(argument, argument2)
            for index, child in ipairs(argument:GetChildren()) do
                if not (child:IsA("Model") and child:FindFirstChildOfClass("Humanoid")) then
                    argument2[#argument2 + 1] = child
                    helper199(child, argument2)
                end
            end
        end
        sharedValue84.set = function(argument)
            if argument == sharedValue84.on then
                return
            end
            sharedValue84.on = argument
            sharedValue84.gen = sharedValue84.gen + 1
            for index, conn in ipairs(sharedValue84.conns) do
                pcall(conn.Disconnect, conn)
            end
            sharedValue84.conns = {}
            if argument then
                local gen, value = sharedValue84.gen, {}
                for index2, child in ipairs(workspaceService:GetChildren()) do
                    if sharedValue85[child.Name] then
                        helper199(child, value)
                    elseif sharedValue86[child.Name] then
                        if child:IsA("BasePart") then
                            value[#value + 1] = child
                        end
                    end
                end
                local value2 = typeof(config.map3DGrey) == "Color3" and config.map3DGrey
                    or Color3.fromRGB(96, 104, 122)
                local terrain = workspaceService:FindFirstChildOfClass("Terrain")
                if terrain then
                    sharedValue84.tcol = {}
                    for index3, entry in ipairs(sharedValue87) do
                        pcall(function()
                            local value3 = Enum.Material[entry]
                            sharedValue84.tcol[entry] = terrain:GetMaterialColor(value3)
                            terrain:SetMaterialColor(value3, value2)
                        end)
                    end
                end
                for index4, child2 in ipairs(getService("Lighting"):GetChildren()) do
                    if child2:IsA("Atmosphere") then
                        helper196(child2, "Density", config.map3DHaze or 0.12)
                    elseif child2:IsA("DepthOfFieldEffect") then
                        helper196(child2, "Enabled", false)
                    elseif child2:IsA("BlurEffect") then
                        helper196(child2, "Enabled", false)
                    end
                end
                task.spawn(function()
                    for index5 = 1, #value, 1 do
                        if sharedValue84.gen ~= gen then
                            return
                        end
                        pcall(helper197, value[index5])
                        if index5 % 400 == 0 then
                            task.wait()
                        end
                    end
                end)
                for index6, child3 in ipairs(workspaceService:GetChildren()) do
                    if sharedValue85[child3.Name] then
                        sharedValue84.conns[#sharedValue84.conns + 1] = child3.DescendantAdded:Connect(
                            function(argument2)
                                task.defer(function()
                                    if sharedValue84.on then
                                        if sharedValue84.gen == gen then
                                            if argument2.Parent then
                                                if not (helper198(argument2)) then
                                                    pcall(helper197, argument2)
                                                end
                                            end
                                        end
                                    end
                                end)
                            end
                        )
                    end
                end
                sharedValue84.conns[#sharedValue84.conns + 1] = workspaceService.ChildAdded:Connect(
                    function(argument2)
                        if sharedValue86[argument2.Name] then
                            task.defer(function()
                                if sharedValue84.on then
                                    if sharedValue84.gen == gen then
                                        if argument2:IsA("BasePart") then
                                            pcall(helper197, argument2)
                                        end
                                    end
                                end
                            end)
                        end
                    end
                )
            else
                for key, entry2 in pairs(sharedValue84.orig) do
                    for key2, entry3 in pairs(entry2) do
                        pcall(function()
                            key[key2] = entry3
                        end)
                    end
                end
                sharedValue84.orig = {}
                local terrain2 = workspaceService:FindFirstChildOfClass("Terrain")
                if terrain2 and sharedValue84.tcol then
                    for key3, entry4 in pairs(sharedValue84.tcol) do
                        pcall(function()
                            terrain2:SetMaterialColor(Enum.Material[key3], entry4)
                        end)
                    end
                end
                sharedValue84.tcol = nil
            end
        end
        local see, setMetatable4, weakKeys7 = {}, setmetatable, { __mode = "k" }
        see.a = setMetatable4({}, weakKeys7)
        see.t = 0
        see.hit = nil
        see.ray = nil
        see.geo = function(argument)
            if argument:IsA("Terrain") then
                return false
            elseif argument.Anchored then
                if argument.CanCollide then
                    if not (argument.Transparency < 0.95) then
                        return false
                    end
                else
                    return false
                end
            else
                return false
            end
            local value = argument
            while value and value ~= workspaceService do
                argument = string.lower(value.Name)
                if argument:find("hitbox", 1, true) then
                    return false
                elseif argument:find("precast", 1, true) then
                    return false
                elseif argument:find("telegraph", 1, true) then
                    return false
                elseif argument:find("warning", 1, true) then
                    return false
                elseif argument:find("safespot", 1, true) then
                    return false
                elseif argument:find("safezone", 1, true) then
                    return false
                elseif argument == "abilities" then
                    return false
                elseif argument == "enemyprojectiles" then
                    return false
                elseif argument == "projectiles" then
                    return false
                elseif argument == "vfxpool" then
                    return false
                elseif argument == "enemypool" then
                    return false
                elseif argument == "sfxpool" then
                    return false
                elseif argument == "enemies" then
                    return false
                elseif argument == "enemyfolder" then
                    return false
                end
                if value:IsA("Model") then
                    if value:FindFirstChildOfClass("Humanoid") then
                        return false
                    end
                end
                value = value.Parent
            end
            return true
        end
        see.clear = function()
            for entry in pairs(see.a) do
                pcall(function()
                    entry.LocalTransparencyModifier = 0
                end)
                see.a[entry] = nil
            end
            see.hit = nil
        end
        see.step = function(argument, argument2, argument3)
            see.t = see.t + argument
            if see.t >= 0.05 or not see.hit then
                see.t = 0
                local hit2 = {}
                see.ray = see.ray or RaycastParams.new()
                see.ray.FilterType = Enum.RaycastFilterType.Exclude
                see.ray.FilterDescendantsInstances = { localPlayer.Character }
                local position, value, value2 = argument2.CFrame.Position, {}, { 2, 0, -1.5 }
                for index, entry in ipairs(value2) do
                    value[#value + 1] = (argument3 + Vector3.new(0, entry, 0) - position).Unit
                end
                local value3, value4 =
                    view.AbsolutePosition + getService("GuiService"):GetGuiInset(), view.AbsoluteSize
                for index2 = 0, 7, 1 do
                    for index3 = 0, 4, 1 do
                        value[#value + 1] = argument2:ViewportPointToRay(
                            value3.X + value4.X * (index2 + 0.5) / 8,
                            value3.Y + value4.Y * (index3 + 0.5) / 5
                        ).Direction.Unit
                    end
                end
                value2 = (argument3 - position).Magnitude + 3
                for index4, entry2 in ipairs(value) do
                    index4, value3 = position, value2
                    for index5 = 1, 5, 1 do
                        index5 = workspaceService:Raycast(index4, entry2 * value3, see.ray)
                        if not index5 then
                            break
                        end
                        value4 = index5.Instance
                        if value4:IsA("Terrain") then
                            break
                        end
                        if see.geo(value4) then
                            if index5.Normal.Y > 0.7 then
                                if index5.Position.Y < argument3.Y + 4 then
                                    break
                                elseif math.min(value4.Size.X, value4.Size.Z) < 10 then
                                    break
                                end
                            end
                            hit2[value4] = true
                        end
                        value3 -= (index5.Position - index4).Magnitude + 0.05
                        if value3 <= 0 then
                            break
                        end
                        index4 = index5.Position + entry2 * 0.05
                    end
                end
                for index6, entry3 in ipairs(workspaceService:GetPartBoundsInRadius(position, 1)) do
                    if see.geo(entry3) then
                        hit2[entry3] = true
                    end
                end
                see.hit = hit2
            end
            for entry4 in pairs(see.hit) do
                if not see.a[entry4] then
                    see.a[entry4] = 0
                end
            end
            argument3 = math.min(1, argument * 8)
            for key, entry5 in pairs(see.a) do
                argument = see.hit[key] and (config.map3DSeeAlpha or 0.72) or 0
                entry5 += (argument - entry5) * argument3
                if argument == 0 and entry5 < 0.02 then
                    see.a[key] = nil
                    pcall(function()
                        key.LocalTransparencyModifier = 0
                    end)
                else
                    see.a[key] = entry5
                    pcall(function()
                        key.LocalTransparencyModifier = entry5
                    end)
                end
            end
        end
        zone.see = see
        local sharedValue88 = { on = false, fov = 70 }
        local function helper200(argument)
            if not sharedValue88.on then
                return
            end
            local camera = workspaceService.CurrentCamera
            if camera then
                if not (helper192()) then
                    return
                end
            else
                return
            end
            local viewportSize, camCur = camera.ViewportSize, config.map3DFov or 50
            local value, value2 =
                viewportSize.Y * 0.5 / math.tan(math.rad(camCur) * 0.5), config.map3DMaxH or 1200
            local value3, value4 = value / sharedValue83 * math.clamp(tonumber(config.map3DZoom) or 1, 0.2, 6)
            if value3 > value2 then
                value3, value4 =
                    value2,
                    math.min(math.deg(2 * math.atan(math.tan(math.rad(camCur) * 0.5) * value3 / value2)), 110)
            else
                value4 = camCur
            end
            value, value2 = zone.camShot(os.clock())
            camCur = zone.camCur
            if not camCur then
                camCur = { p = value, y = value2, d = value3, f = value4 }
                zone.camCur = camCur
            end
            local value5 = 1 - math.exp(-(tonumber(argument) or 0.016) * 5)
            camCur.p = camCur.p + (value - camCur.p) * value5
            camCur.y = (camCur.y + ((value2 - camCur.y + 180) % 360 - 180) * value5) % 360
            camCur.d = camCur.d + (value3 - camCur.d) * math.min(1, value5 * 2)
            camCur.f = camCur.f + (value4 - camCur.f) * math.min(1, value5 * 2)
            value, value5 =
                view.AbsolutePosition + getService("GuiService"):GetGuiInset(),
                camCur.d * math.tan(math.rad(camCur.f) * 0.5) / math.max(viewportSize.Y * 0.5, 1)
            local value6, value7, value8, value9 =
                (value.X + sharedValue79 * 0.5 - viewportSize.X * 0.5) * value5,
                (value.Y + sharedValue80 * 0.5 - viewportSize.Y * 0.5) * value5,
                math.rad(camCur.y),
                sharedValue81
            value2, value5 = value9 - math.cos(value8) * value6 - math.sin(value8) * value7, sharedValue82
            local value10, value11 =
                value5 + math.sin(value8) * value6 - math.cos(value8) * value7,
                (zone.cy or 0) - (config.map3DGroundDrop or 3)
            if camera.CameraType ~= Enum.CameraType.Scriptable then
                camera.CameraType = Enum.CameraType.Scriptable
            end
            if math.abs(camera.FieldOfView - camCur.f) > 0.01 then
                camera.FieldOfView = camCur.f
            end
            value7 = Vector3.new(value2, value11, value10)
            if camCur.p >= 89.4 then
                camera.CFrame = CFrame.lookAt(
                    value7 + Vector3.new(0, camCur.d, 0),
                    value7,
                    Vector3.new(-math.sin(value8), 0, -math.cos(value8))
                )
            else
                value10, value2 =
                    math.rad(math.clamp(camCur.p, 5, 89.4)),
                    Vector3.new(sharedValue81, zone.cy or value11, sharedValue82)
                local transform, value12, value13, value14 =
                    CFrame.lookAt(
                        value2
                            + Vector3.new(
                                    math.sin(value8) * math.cos(value10),
                                    math.sin(value10),
                                    math.cos(value8) * math.cos(value10)
                                )
                                * camCur.d,
                        value2
                    ),
                    camCur.d / (viewportSize.Y * 0.5 / math.tan(math.rad(camCur.f) * 0.5)),
                    value.X + sharedValue79 * 0.5 - viewportSize.X * 0.5,
                    value.Y + sharedValue80 * 0.5 - viewportSize.Y * 0.5
                camera.CFrame = transform
                    - transform.RightVector * (value13 * value12)
                    + transform.UpVector * (value14 * value12)
            end
            if config.map3DSeeThrough ~= false then
                pcall(
                    see.step,
                    tonumber(argument) or 0.016,
                    camera,
                    Vector3.new(sharedValue81, zone.cy or value11, sharedValue82)
                )
            elseif next(see.a) then
                see.clear()
            end
        end
        zone.sync3D = function()
            local cam3On = zone.use3D()
            if cam3On == sharedValue88.on then
                return
            end
            sharedValue88.on = cam3On
            zone.cam3On = cam3On
            local camera = workspaceService.CurrentCamera
            if cam3On then
                zone.camCur = nil
                sharedValue88.fov = camera and camera.FieldOfView or 70
                pcall(function()
                    runService:UnbindFromRenderStep("HLMap3D")
                end)
                pcall(function()
                    runService:BindToRenderStep("HLMap3D", Enum.RenderPriority.Last.Value + 1, helper200)
                end)
                sharedValue84.set(true)
            else
                pcall(function()
                    runService:UnbindFromRenderStep("HLMap3D")
                end)
                sharedValue84.set(false)
                pcall(see.clear)
                if camera then
                    pcall(function()
                        camera.FieldOfView = sharedValue88.fov or 70
                        if config.birdsEyeCam ~= true then
                            camera.CameraType = Enum.CameraType.Custom
                        end
                    end)
                end
            end
        end
        zone.stop3D = function()
            zone.sync3D()
        end
        local function placeBands()
            local value, absoluteSize, value2 =
                view.AbsolutePosition, view.AbsoluteSize, hlMinimap.AbsolutePosition
            local value3, value4 = value.X - value2.X, value.Y - value2.Y
            value2, value = value3 + absoluteSize.X, value4 + absoluteSize.Y
            sharedValue47[1].Position, sharedValue47[1].Size =
                UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, math.max(value4, 0))
            sharedValue47[2].Position, sharedValue47[2].Size =
                UDim2.fromOffset(0, value), UDim2.new(1, 0, 1, -value)
            sharedValue47[3].Position, sharedValue47[3].Size =
                UDim2.fromOffset(0, value4), UDim2.fromOffset(math.max(value3, 0), absoluteSize.Y)
            sharedValue47[4].Position, sharedValue47[4].Size =
                UDim2.fromOffset(value2, value4), UDim2.new(1, -value2, 0, absoluteSize.Y)
        end
        zone.placeBands = placeBands
        local function helper201(argument)
            local value, value2 =
                type(config.mapAnchors) == "table" and config.mapAnchors or {}, tostring(game.PlaceId)
            local value3 = value[value2]
            if argument or type(value3) ~= "table" or not tonumber(value3.x) or not tonumber(value3.z) then
                local mapAnchors = localPlayer.Character
                local value4 = mapAnchors and (mapAnchors:FindFirstChild("HumanoidRootPart"))
                mapAnchors = value4 and value4.Position
                value3 = {
                    x = mapAnchors and mapAnchors.X or zone.cx or 0,
                    z = mapAnchors and mapAnchors.Z or zone.cz or 0,
                }
                mapAnchors = {}
                for key, entry in pairs(value) do
                    mapAnchors[key] = entry
                end
                mapAnchors[value2] = value3
                config.mapAnchors = mapAnchors
                pcall(helper16)
            end
            return value3
        end
        zone.anchor = function()
            return helper201(false)
        end
        zone.onFollow = function(argument)
            if not argument then
                helper201(true)
            end
            zone.panX = 0
            zone.panZ = 0
            zone.lastAt = 0
        end
        zone.apply = function()
            hlMinimap.Visible = config.minimap ~= false or zone.big
            if zone.big then
                hlMinimap.AnchorPoint, hlMinimap.Position, hlMinimap.Size =
                    Vector2.new(0, 0), UDim2.fromScale(0, 0), UDim2.fromScale(1, 1)
                zone.statsAt = 0
                backdrop.BackgroundTransparency = 0
                view.AnchorPoint, view.Position =
                    Vector2.new(0, 0), UDim2.fromOffset(sharedValue44, sharedValue45)
                local value = config.mapStatsHidden == true
                view.Size = value
                        and UDim2.new(1, -(2 * sharedValue44 + 10), 1, -(sharedValue45 + sharedValue44))
                    or UDim2.new(
                        1,
                        -(2 * sharedValue44 + sharedValue42 + sharedValue43),
                        1,
                        -(sharedValue45 + sharedValue44)
                    )
                statsFrame.Visible = not value
                if zone.statsArrow then
                    zone.statsArrow.Text = value and "<" or ">"
                    zone.statsArrow.Position = value and UDim2.new(1, -4, 0.5, 0)
                        or UDim2.new(1, -(sharedValue44 + sharedValue42 + 2), 0.5, 0)
                end
                corner.CornerRadius, view.BackgroundColor3 = UDim.new(0, 14), theme2.Panel
                view.BackgroundTransparency = 0
                stroke2.Color = theme2.Stroke
                stroke2.Thickness = 1
                stroke2.Transparency = 0
                pcall(function()
                    stroke2.LineJoinMode = Enum.LineJoinMode.Round
                end)
                backdrop.BackgroundColor3 = theme2.Bg
                for index, entry in ipairs(sharedValue47) do
                    entry.BackgroundColor3 = theme2.Bg
                end
            else
                local vector, value2, value3 =
                    workspaceService.CurrentCamera and workspaceService.CurrentCamera.ViewportSize
                        or Vector2.new(1920, 1080),
                    tonumber(config.minimapX) or -1,
                    tonumber(config.minimapY) or -1
                if value2 >= 0 and value3 >= 0 then
                    hlMinimap.AnchorPoint = Vector2.new(0, 0)
                    hlMinimap.Position = UDim2.fromOffset(
                        math.clamp(value2, 0, math.max(vector.X - sharedValue40, 0)),
                        math.clamp(value3, 0, math.max(vector.Y - sharedValue40, 0))
                    )
                else
                    hlMinimap.AnchorPoint, hlMinimap.Position =
                        Vector2.new(1, 0), UDim2.new(1, -16, 0, config.minimapTop or 64)
                end
                hlMinimap.Size = UDim2.fromOffset(sharedValue40, sharedValue40)
                view.AnchorPoint, view.Position, view.Size =
                    Vector2.new(0, 0), UDim2.fromScale(0, 0), UDim2.fromScale(1, 1)
                statsFrame.Visible = false
                sharedValue70.Visible = false
                sharedValue69.Visible = false
                corner.CornerRadius, view.BackgroundColor3 = UDim.new(0, 14), theme2.Panel
                view.BackgroundTransparency = 0.1
                stroke2.Color = theme2.Stroke
                stroke2.Thickness = 1
                stroke2.Transparency = 0
                pcall(function()
                    stroke2.LineJoinMode = Enum.LineJoinMode.Round
                end)
            end
            local value4 = zone.blank()
            local visible = zone.big and not value4
            backdrop.Visible = zone.big
            sharedValue50.Visible = visible
            sharedValue51.Visible = visible
            sharedValue48.Visible = visible
            sharedValue49.Visible = visible
            sharedValue53.Visible = visible
            sharedValue68.Visible = visible
            if zone.statsArrow then
                zone.statsArrow.Visible = visible
            end
            if not visible then
                sharedValue69.Visible = false
            end
            view.Visible = true
            if value4 then
                statsFrame.Visible = false
                sharedValue52.Visible = false
                view.BackgroundTransparency = 1
                stroke2.Transparency = 1
                if zone.clearMarks then
                    zone.clearMarks()
                end
            end
            local value5 = zone.use3D()
            if zone.big then
                if value5 then
                    backdrop.Visible = false
                    view.BackgroundTransparency = 1
                    placeBands()
                    if zone.clearMarks then
                        zone.clearMarks()
                    end
                end
            end
            sharedValue52.Visible = visible and not value5
            for index2, entry2 in ipairs(sharedValue47) do
                entry2.Visible = zone.big and value5
            end
            for key, entry3 in pairs(sharedValue57) do
                entry3.render()
                entry3.b.Visible = if value4
                    then not value4
                    else not (value5 and (key == "mapHealthBars" or key == "mapNames"))
            end
            sharedValue56.Visible = zone.big
            zone.viewBox.Visible = zone.big == true
            zone.paintView()
            if zone.camBox then
                zone.camBox.Visible = zone.use3D() == true
                if zone.camBox.Visible then
                    if zone.paintCam then
                        zone.paintCam()
                    end
                end
            end
            zone.sync3D()
            sharedValue72.set(zone.big == true)
            visible = runtimeState.scriptGui and runtimeState.scriptGui:FindFirstChild("HUD")
            if visible then
                value4 = zone.big
                local value6, visible2 = not value4
                if value4 then
                    visible2 = value6
                else
                    value5 = context.hudShown
                    visible2 = if value5 then context.hudShown() else not value5
                end
                visible.Visible = visible2
            end
            do
                local mapBtn = zone.mapBtn
                local mapBtnStroke = zone.mapBtnStroke
                value5 = zone.big
                mapBtn.Visible = if value5 then not value5 else config.mapButton ~= false
                mapBtn.Text = "MINIMAP [" .. tostring(config.mapKey or "M") .. "]"
                pcall(function()
                    mapBtn.FontFace = sharedValue41.Semi
                end)
                mapBtn.TextSize, mapBtn.TextColor3, mapBtn.BackgroundColor3 = 13, theme2.Text, theme2.Raised
                mapBtn.BackgroundTransparency = 0
                mapBtnStroke.Color = theme2.Stroke
                mapBtnStroke.Thickness = 1
                mapBtnStroke.Transparency = 0
                pcall(function()
                    mapBtnStroke.LineJoinMode = Enum.LineJoinMode.Round
                end)
                zone.mapBtnCorner.CornerRadius = UDim.new(0, 8)
            end
            zone.lastAt = 0
        end
        zone.setBig = function(argument, argument2)
            argument = argument == true
            if not argument2 then
                zone.ultOpened = nil
                config.mapViewOpen = argument
                pcall(helper16)
            end
            if zone.big ~= argument then
                zone.big = argument
                zone.panX = 0
                zone.panZ = 0
                zone.freeAt = nil
            end
            zone.apply()
        end
        zone.toggle = function()
            zone.setBig(not zone.big)
        end
        zone.onUltimate = function(argument)
            if argument and not zone.big then
                zone.setBig(true, true)
                zone.ultOpened = true
            elseif argument then
                zone.apply()
            elseif zone.ultOpened then
                zone.ultOpened = nil
                zone.setBig(false, true)
            else
                zone.apply()
            end
        end
        zone.apply()
        local function helper202()
            if zone.big then
                return
            end
            if zone.overMenu() then
                return
            end
            zone.setBig(true)
        end
        hit.Activated:Connect(helper202)
        local function helper203()
            if zone.overMenu() then
                return
            end
            zone.setBig(false)
        end
        sharedValue53.Activated:Connect(helper203)
        local sharedValue89 = getService("GuiService")
        local function helper204(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton3 then
                return
            elseif zone.overMenu() then
                return
            end
            local absolutePosition, anchor, freeAt =
                hlMinimap.AbsolutePosition,
                zone.big and config.mapFollow == false and zone.anchor() or nil,
                zone.freeAt
            zone.drag = {
                mode = zone.big and "pan" or "move",
                sx = input.Position.X,
                sy = input.Position.Y,
                moved = false,
                ax = absolutePosition.X,
                ay = absolutePosition.Y + sharedValue89:GetGuiInset().Y,
                px = anchor and anchor.x or (freeAt and freeAt.x or zone.cx or 0),
                pz = anchor and anchor.z or (freeAt and freeAt.z or zone.cz or 0),
                anchor = anchor,
            }
        end
        hit.InputBegan:Connect(helper204)
        sliderConnections[#sliderConnections + 1] = userInputService.InputChanged:Connect(function(argument)
            local drag = zone.drag
            if drag then
                if argument.UserInputType ~= Enum.UserInputType.MouseMovement then
                    return
                end
            else
                return
            end
            local value, value2 = argument.Position.X - drag.sx, argument.Position.Y - drag.sy
            if not drag.moved then
                if value * value + value2 * value2 < 9 then
                    return
                end
            end
            drag.moved = true
            if drag.mode == "move" then
                argument = workspaceService.CurrentCamera and workspaceService.CurrentCamera.ViewportSize
                    or Vector2.new(1920, 1080)
                config.minimapX =
                    math.floor(math.clamp(drag.ax + value, 0, math.max(argument.X - sharedValue40, 0)))
                config.minimapY =
                    math.floor(math.clamp(drag.ay + value2, 0, math.max(argument.Y - sharedValue40, 0)))
                hlMinimap.AnchorPoint, hlMinimap.Position =
                    Vector2.new(0, 0), UDim2.fromOffset(config.minimapX, config.minimapY)
            elseif drag.anchor then
                drag.anchor.x, drag.anchor.z =
                    drag.px - value / sharedValue83, drag.pz - value2 / sharedValue83
                zone.lastAt = 0
            else
                zone.freeAt = { x = drag.px - value / sharedValue83, z = drag.pz - value2 / sharedValue83 }
                zone.lastAt = 0
            end
        end)
        sliderConnections[#sliderConnections + 1] = userInputService.InputEnded:Connect(function(input)
            local drag = zone.drag
            if drag then
                if input.UserInputType ~= Enum.UserInputType.MouseButton3 then
                    return
                end
            else
                return
            end
            zone.drag = nil
            if drag.mode == "move" then
                if not drag.moved then
                    config.minimapX = -1
                    config.minimapY = -1
                    zone.apply()
                end
                pcall(helper16)
            elseif drag.anchor then
                if not drag.moved then
                    helper201(true)
                end
                pcall(helper16)
                zone.lastAt = 0
            elseif not drag.moved then
                zone.panX = 0
                zone.panZ = 0
                zone.freeAt = nil
                zone.lastAt = 0
            end
        end)
        local function helper205()
            if zone.overMenu() then
                return
            end
            if zone.big then
                zone.zoomB = math.min(zone.zoomB * 1.15, 6)
            else
                zone.zoomS = math.min(zone.zoomS * 1.15, 6)
            end
            config.mapZoomS, config.mapZoomB = zone.zoomS, zone.zoomB
            pcall(helper16)
            zone.lastAt = 0
        end
        hit.MouseWheelForward:Connect(helper205)
        local function helper206()
            if zone.overMenu() then
                return
            end
            if zone.big then
                zone.zoomB = math.max(zone.zoomB / 1.15, 0.25)
            else
                zone.zoomS = math.max(zone.zoomS / 1.15, 0.25)
            end
            config.mapZoomS, config.mapZoomB = zone.zoomS, zone.zoomB
            pcall(helper16)
            zone.lastAt = 0
        end
        hit.MouseWheelBackward:Connect(helper206)
        sliderConnections[#sliderConnections + 1] = runService.Heartbeat:Connect(function()
            if runtimeState.destroyed then
                return
            end
            local value = zone.big == true and zone.viewMode() == "2d"
            if value ~= (context.fps2D == true) then
                context.fps2D = value
                if context.applyRender then
                    pcall(context.applyRender)
                end
            end
            value = zone.cam3On == true
            if value ~= sharedValue84.on then
                sharedValue84.set(value)
            end
            if config.minimap == false then
                if not zone.big then
                    return
                end
            end
            value = os.clock()
            if zone.use3D() ~= (zone.cam3On == true) then
                zone.apply()
            end
            if zone.cam3On then
                placeBands()
            end
            local success = localPlayer.Character
            local value2 = success and (success:FindFirstChild("HumanoidRootPart"))
            if value2 then
                success = value2.AssemblyLinearVelocity
                if success.X * success.X + success.Z * success.Z > 4 then
                    zone.movedAt = value
                end
            end
            zone.frames = zone.frames + 1
            if value - zone.fpsAt >= 1 then
                zone.fps = math.floor(zone.frames / (value - zone.fpsAt) + 0.5)
                zone.frames = 0
                zone.fpsAt = value
            end
            if zone.blank() then
                return
            end
            if zone.big then
                if value - (zone.bossAt or 0) >= 0.25 then
                    zone.bossAt = value
                    pcall(zone.drawBoss)
                    pcall(zone.drawTimer)
                end
            end
            if zone.big then
                if statsFrame.Visible then
                    if value - zone.statsAt >= 0.5 then
                        zone.statsAt = value
                        success, value2 = pcall(zone.drawStats)
                        if not success then
                            if not zone.statsErrAt then
                                zone.statsErrAt = value
                                context.log("Minimap", "stats failed: " .. tostring(value2))
                            end
                        end
                    end
                end
            end
            pcall(zone.drawFuse3D, zone.cam3On == true and config.mapFuse3D == true)
            if zone.cam3On then
                return
            end
            value2 = config.minimapSmooth ~= false and zone.viewMode() == "2d"
            if not value2 then
                if
                    value - zone.lastAt
                    < (zone.big and (config.minimapBigEvery or 0.05) or (config.minimapEvery or 0.1))
                then
                    return
                end
            end
            if value2 then
                if config.perfMemo ~= false then
                    if value - zone.lastAt < 1 / (config.minimapSmoothHz or 30) then
                        return
                    end
                end
            end
            zone.lastAt = value
            success, value2 = pcall(zone.draw)
            if not success then
                if not zone.errAt then
                    zone.errAt = value
                    context.log("Minimap", "draw failed: " .. tostring(value2))
                end
            end
        end)
    end
        end, __tb)
        if not ok then
            warn("[Minimap] " .. tostring(err))
            if context.notify then
                context.notify("error", "Minimap failed", tostring(err):sub(1, 160))
            end
        end
    end

    -- HUD: playtime, FPS, ping, enemies
    do
        local statsService = getService("Stats")
        local hud, rows
        local startAt = os.clock()
        local function build()
            if hud and hud.Parent then
                return
            end
            hud = Instance.new("Frame")
            hud.Name = "HUD"
            hud.BackgroundColor3 = theme.SurfaceHeader
            hud.BackgroundTransparency = 0.12
            hud.BorderSizePixel = 0
            hud.AnchorPoint = Vector2.new(0, 1)
            hud.Position = UDim2.new(0, 20, 1, -20)
            hud.Size = UDim2.fromOffset(190, 92)
            hud.ZIndex = 2
            hud.Parent = gui
            uiLibrary.corner(hud, theme.RadiusLg)
            uiLibrary.stroke(hud, theme.Hairline, 1)
            uiLibrary.pad(hud, 8, 10, 8, 10)
            uiLibrary.vlist(hud, 2)
            rows = {}
            for i, name in ipairs({ "Playtime", "FPS", "Ping", "Enemies" }) do
                local row = uiLibrary.label(hud, name, "rowLabel", i)
                row.Size = UDim2.new(1, 0, 0, 18)
                row.TextXAlignment = Enum.TextXAlignment.Left
                rows[name] = row
            end
        end
        local frames, lastAt, fps = 0, os.clock(), 0
        sliderConnections[#sliderConnections + 1] = runService.Heartbeat:Connect(function()
            frames += 1
        end)
        local function update()
            local show = config.hud ~= false and not (context.MM and context.MM.big)
            if not show then
                if hud then
                    hud.Visible = false
                end
                return
            end
            build()
            hud.Visible = true
            local now = os.clock()
            if now - lastAt >= 0.5 then
                fps = frames / (now - lastAt)
                frames, lastAt = 0, now
            end
            local t = math.floor(now - startAt)
            rows.Playtime.Text = ("Playtime  %02d:%02d:%02d"):format(t // 3600, t % 3600 // 60, t % 60)
            rows.FPS.Text = ("FPS  %d"):format(math.floor(fps + 0.5))
            local ping = "-"
            pcall(function()
                ping = ("%d ms"):format(math.floor(statsService.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5))
            end)
            rows.Ping.Text = "Ping  " .. ping
            rows.Enemies.Text = "Enemies  " .. tostring(#hazardReader.enemies)
        end
        context.hudApply = update
        task.spawn(function()
            while not runtimeState.destroyed do
                pcall(update)
                task.wait(0.5)
            end
        end)
    end
end



-- ============================================================
--  PUBLIC API
-- ============================================================
local context = {}
do
    local ok, err = xpcall(function()
        components.coreSettings(context)
        context.loadConfig()
        components.uiLibrary(context)
    end, __tb)
    if not ok then
        __report("setup (coreSettings/uiLibrary)", err)
        error("GUI setup failed", 0)
    end
end

local Library = {}

local function fire(callback, ...)
    if not callback then return end
    local args = table.pack(...)
    task.spawn(function()
        local ok, err = xpcall(function()
            callback(table.unpack(args, 1, args.n))
        end, __tb)
        if not ok then
            warn("[GUI callback error] " .. tostring(err))
            if context.notify then
                context.notify("error", "Callback error", tostring(err):sub(1, 160))
            end
        end
    end)
end

local function makeContainer(parent, startOrder)
    local uiLibrary = context.UIKit
    local order = startOrder or 0
    local function nextOrder()
        order += 1
        return order
    end
    local C = {}

    function C:Label(text)
        return uiLibrary.caption(parent, text, nextOrder())
    end

    function C:Toggle(label, default, callback, tip)
        local state = default == true
        local control
        control = uiLibrary.toggle(parent, label, function()
            return state
        end, function(value)
            state = value and true or false
            if callback then
                fire(callback, state)
            end
        end, nextOrder(), tip)
        return {
            Get = function() return state end,
            Set = function(_, value)
                state = value and true or false
                if control and control.render then pcall(control.render) end
                if callback then fire(callback, state) end
            end,
        }
    end

    -- opts: { decimals = true } for 0.1 steps, { step = 0.05 } for a custom step, { tip = "..." }
    function C:Slider(label, min, max, default, callback, opts)
        opts = opts or {}
        local value = default or min
        local control
        control = uiLibrary.slider(parent, label, opts.subtitle, min, max, opts.decimals == true, function()
            return value
        end, function(v)
            value = v
            if callback then fire(callback, v) end
        end, nextOrder(), opts.tip, opts.step)
        return {
            Get = function() return value end,
            Set = function(_, v)
                value = v
                if type(control) == "table" and control.render then pcall(control.render) end
                if callback then fire(callback, v) end
            end,
        }
    end

    -- options: { "A", "B" } or { {value = "a", label = "A"}, ... }
    -- returns { Get(), Refresh(self, newOptions, current) }
    function C:Dropdown(label, options, default, callback, tip)
        local function toList(opts)
            local list = {}
            for _, o in ipairs(opts or {}) do
                if type(o) == "table" then
                    list[#list + 1] = o
                else
                    list[#list + 1] = { value = o, label = tostring(o) }
                end
            end
            return list
        end
        local list = toList(options)
        local value = default or (list[1] and list[1].value)
        local myOrder = nextOrder()
        local control
        local function build()
            control = uiLibrary.dropdown(parent, label, list, function()
                return value
            end, function(v)
                value = v
                if callback then fire(callback, v) end
            end, myOrder, tip)
        end
        build()
        return {
            Get = function() return value end,
            Refresh = function(_, newOptions, current)
                if control and control.holder then
                    control.holder:Destroy()
                end
                list = toList(newOptions)
                value = current or (list[1] and list[1].value)
                build()
            end,
        }
    end

    -- multi-select grid: getSet() returns { [name] = true }, onToggle(name) flips one
    function C:MultiDropdown(label, options, getSet, onToggle, tip)
        local list = {}
        for _, o in ipairs(options or {}) do list[#list + 1] = o end
        local control = uiLibrary.multiDropdown(parent, label, list, getSet, onToggle, nextOrder(), tip)
        return { render = function() if control and control.render then pcall(control.render) end end }
    end

    -- kind: nil (normal), "accent" or "danger"
    function C:Button(label, callback, kind, tip)
        return uiLibrary.button(parent, label, kind, function()
            if callback then fire(callback) end
        end, nextOrder(), tip)
    end

    function C:Input(label, default, callback, placeholder, tip)
        local value = default or ""
        uiLibrary.textInput(parent, label, function()
            return value
        end, function(v)
            value = v
            if callback then fire(callback, v) end
        end, nextOrder(), tip, placeholder)
        return { Get = function() return value end }
    end

    return C, nextOrder
end

-- opts = {
--   title   = "My Hub",
--   version = "v1.0",
--   key     = Enum.KeyCode.RightShift,
--   tabs = {
--     { id = "Main", name = "Main", icon = "swords", desc = "Main features" },
--     { id = "Misc", name = "Misc", icon = "eye",    desc = "Other stuff"   },
--   },
-- }
-- icons: swords, users, shield, coins, bell, eye (anything else shows a default icon)
local function buildWindow(opts)
    opts = opts or {}
    local uiLibrary = context.UIKit
    context.shellTitle = opts.title or "My GUI"
    context.shellVersion = opts.version or ""
    context.shellTabs = opts.tabs or { { id = "Main", name = "Main", icon = "swords", desc = "" } }
    components.shellKit(context)

    local gui = Instance.new("ScreenGui")
    gui.Name = opts.name or "LibraryGui"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 100
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local parented = false
    if type(gethui) == "function" then
        parented = pcall(function() gui.Parent = gethui() end)
    end
    if not parented then
        parented = pcall(function() gui.Parent = game:GetService("CoreGui") end)
    end
    if not parented then
        gui.Parent = context.LocalPlayer:WaitForChild("PlayerGui")
    end
    uiLibrary.ensureTip(gui)

    local shell = context.buildShell(gui)
    local shown = false
    local Window = { Gui = gui, Shell = shell, Tabs = {} }

    function Window:SetShown(value)
        shown = value and true or false
        shell.setShown(shown)
    end
    function Window:Toggle()
        Window:SetShown(not shown)
    end
    function Window:Destroy()
        gui:Destroy()
    end

    for _, tab in ipairs(context.shellTabs) do
        local page = shell.pages[tab.id]
        local container, nextOrder = makeContainer(page.body, 0)
        function container:Section(title, desc)
            local section = uiLibrary.section(page.body, title, nextOrder(), desc)
            return (makeContainer(section.content, 0))
        end
        Window.Tabs[tab.id] = container
        Window[tab.id] = container
    end

    function Window:Tab(id)
        return Window.Tabs[id]
    end

    shell.onClose = function()
        Window:SetShown(false)
    end
    shell.menuButton(function()
        Window:Toggle()
    end)
    local key = opts.key or Enum.KeyCode.RightShift
    context.UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == key then
            Window:Toggle()
        end
    end)

    -- runs after your code has added its controls
    task.defer(function()
        shell.finish()
        Window:SetShown(true)
    end)

    return Window
end

function Library.new(opts)
    local ok, result = xpcall(buildWindow, __tb, opts)
    if not ok then
        __report("Library.new", result)
        error("GUI build failed", 0)
    end
    return result
end

-- kind: "info", "success", "warning", "error", "drop", "run", "party"
function Library.Notify(kind, title, text)
    if context.notify then
        context.notify(kind or "info", title or "", text or "")
    end
end

-- ============================================================
--  MAIN TAB  (Welcome card only)
-- ============================================================
components.mainTab = function(context, shell)
    local uiLibrary = context.UIKit
    local theme = uiLibrary.Theme
    local localPlayer = context.LocalPlayer
    local runtimeState = context.RT
    local playersService = getService("Players")
    local fontWeight = Enum.FontWeight
    local VERSION_TEXT = "v3.0 c84b"

    local page = shell.pages.Main
    if not page then
        return
    end
    local body = page.body

    local function make(className, props, parent)
        local inst = Instance.new(className)
        for key, value in pairs(props or {}) do
            inst[key] = value
        end
        if parent then
            inst.Parent = parent
        end
        return inst
    end

    local function text(parent, str, size, color, weight, props)
        local lbl = make("TextLabel", {
            BackgroundTransparency = 1,
            Text = str,
            TextSize = size,
            TextColor3 = color,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            Size = UDim2.new(1, 0, 0, size + 6),
        }, parent)
        uiLibrary.setFont(lbl, "sans", weight or fontWeight.Regular)
        for key, value in pairs(props or {}) do
            lbl[key] = value
        end
        return lbl
    end

    local function row(parent, order, height)
        local frame = make("Frame", {
            LayoutOrder = order,
            Size = UDim2.new(1, 0, 0, height),
            BackgroundTransparency = 1,
        }, parent)
        uiLibrary.hlist(frame, 0)
        return frame
    end

    local function inline(parent, order, str, size, color)
        return text(parent, str, size, color, fontWeight.Medium, {
            LayoutOrder = order,
            Size = UDim2.fromOffset(0, size + 8),
            AutomaticSize = Enum.AutomaticSize.X,
        })
    end

    -- outer wrapper + card
    local wrapper = make("Frame", {
        Name = "Welcome",
        LayoutOrder = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, body)
    local card = make("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = theme.SurfaceElement,
        BorderSizePixel = 0,
    }, wrapper)
    uiLibrary.corner(card, theme.RadiusMd)
    uiLibrary.stroke(card, theme.Hairline, 1)
    uiLibrary.pad(card, 12, 14, 14, 14)
    uiLibrary.vlist(card, 8)

    -- "Welcome, <name>."
    local titleRow = row(card, 1, 32)
    inline(titleRow, 1, "Welcome, ", 24, theme.TextPrimary)
    local nameLabel = inline(titleRow, 2, "", 24, theme.AccentMid)
    inline(titleRow, 3, ".", 24, theme.TextPrimary)

    -- "Version: x   Level: y"
    local infoRow = row(card, 2, 20)
    inline(infoRow, 1, "Version: ", 14, theme.TextPrimary)
    inline(infoRow, 2, VERSION_TEXT, 14, theme.AccentMid)
    inline(infoRow, 3, "      Level: ", 14, theme.TextPrimary)
    local levelLabel = inline(infoRow, 4, "-", 14, theme.AccentMid)

    -- divider
    make("Frame", {
        LayoutOrder = 3,
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = theme.Hairline,
        BorderSizePixel = 0,
    }, card)

    -- avatar + details
    local AVATAR = 72
    local profile = make("Frame", {
        LayoutOrder = 4,
        Size = UDim2.new(1, 0, 0, AVATAR),
        BackgroundTransparency = 1,
    }, card)
    local avatar = make("ImageLabel", {
        Size = UDim2.fromOffset(AVATAR, AVATAR),
        BackgroundColor3 = theme.SurfaceField,
        Image = "",
    }, profile)
    uiLibrary.corner(avatar, theme.RadiusMd)
    uiLibrary.stroke(avatar, theme.Hairline, 1)

    task.spawn(function()
        local ok, image = pcall(function()
            return playersService:GetUserThumbnailAsync(
                localPlayer.UserId,
                Enum.ThumbnailType.HeadShot,
                Enum.ThumbnailSize.Size150x150
            )
        end)
        if ok and avatar.Parent then
            avatar.Image = image
        end
    end)

    local details = make("Frame", {
        Position = UDim2.fromOffset(AVATAR + 16, 6),
        Size = UDim2.new(1, -(AVATAR + 16), 1, -6),
        BackgroundTransparency = 1,
    }, profile)
    uiLibrary.vlist(details, 2)
    local userLabel = text(details, "", 15, theme.AccentMid, fontWeight.SemiBold, { LayoutOrder = 1 })
    local goldLabel = text(details, "", 13, theme.TextPrimary, fontWeight.Medium, { LayoutOrder = 2 })

    local function stat(name)
        local value
        pcall(function()
            value = localPlayer.leaderstats[name].Value
        end)
        return value
    end

    local function commas(n)
        local str, count = tostring(math.floor((tonumber(n) or 0) + 0.5)), 1
        while count > 0 do
            str, count = str:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
        end
        return str
    end

    local function refresh()
        -- always shows the real name / avatar (streamer mode is not applied here)
        local shown = localPlayer.DisplayName ~= "" and localPlayer.DisplayName or localPlayer.Name
        nameLabel.Text = shown
        userLabel.Text = "@" .. localPlayer.Name
        local level, gold = stat("Level"), stat("Gold")
        levelLabel.Text = tostring(level or "-")
        goldLabel.Text = "Gold: " .. (gold and commas(gold) or "-")
    end

    refresh()
    task.spawn(function()
        while not runtimeState.destroyed and wrapper.Parent do
            task.wait(1)
            pcall(refresh)
        end
    end)
end


-- ============================================================
--  HYZE HUB  (Voxle Hub loader ported to the Hyze GUI)
-- ============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalPlayer = Players.LocalPlayer

-- GAME CHECK SWITCH
--   true  = the farm tabs only load in the game below (original behaviour)
--   false = the farm tabs load in ANY game
local REQUIRE_GAME_ID = false
local GAME_ID = 4934471106

-- tabs each supported game needs (taken from the loader)
local HYZE_TABS = {
    [4934471106] = { "Autofarm", "Misc", "Blacklist" },
}

local TAB_ICONS = {
    Main = "swords", Misc = "coins", Teleports = "users", Teleport = "users",
    Settings = "shield", ["Local Player"] = "bell", ESP = "eye", Autofarm = "swords", Blacklist = "shield",
}
local function tabId(name)
    if name == "Welcome" then return "Main" end -- the Main (welcome) page
    if name == "Main" then return "Farm" end
    return (name:gsub("%W", ""))
end
local function tabName(name)
    if name == "Main" then return "Farming" end
    return name
end

local shellTabs = { { id = "Main", name = "Main", icon = "users", desc = "Welcome." } }
for _, name in ipairs(HYZE_TABS[REQUIRE_GAME_ID and game.PlaceId or GAME_ID] or {}) do
    shellTabs[#shellTabs + 1] = {
        id = tabId(name), name = tabName(name),
        icon = TAB_ICONS[name] or "info", desc = "",
    }
end
shellTabs[#shellTabs + 1] = { id = "Visuals", name = "Visuals", icon = "eye", desc = "Theme, notifications, screen, item cards, streamer mode." }

local Win = Library.new({
    title = "Hyze",
    version = "",
    tabs = shellTabs,
})

-- Main tab
do
    local ok, err = xpcall(components.mainTab, __tb, context, Win.Shell)
    if not ok then
        __report("Main tab", err)
    end
end

-- Visuals tab
do
    local ok, err = xpcall(components.visuals, __tb, context, Win.Shell, Win.Gui)
    if not ok then
        __report("Visuals tab", err)
    end
end

-- ============================================================
--  Rayfield-style layer: lets the loader's Rayfield calls build this GUI.
--  Every toggle / slider / dropdown is saved to Hyze/<PlaceId>.json and
--  toggles that were on are turned back on when you rejoin.
-- ============================================================
local HyzeRayfield = {}
do
    local SAVE_FILE = "Hyze/" .. tostring(game.PlaceId) .. ".json"
    local Saved = {}
    do
        local ok, raw = pcall(function()
            if type(isfile) == "function" and isfile(SAVE_FILE) then
                return readfile(SAVE_FILE)
            end
        end)
        if ok and type(raw) == "string" and raw ~= "" then
            local ok2, data = pcall(function()
                return HttpService:JSONDecode(raw)
            end)
            if ok2 and type(data) == "table" then
                Saved = data
            end
        end
    end
    local saveQueued = false
    local function save()
        if saveQueued then return end
        saveQueued = true
        task.delay(0.4, function()
            saveQueued = false
            pcall(function()
                if type(makefolder) == "function" and type(isfolder) == "function" and not isfolder("Hyze") then
                    makefolder("Hyze")
                end
                writefile(SAVE_FILE, HttpService:JSONEncode(Saved))
            end)
        end)
    end
    local function safeRun(cb, ...)
        local args = table.pack(...)
        task.spawn(function()
            local ok, err = xpcall(function()
                cb(table.unpack(args, 1, args.n))
            end, __tb)
            if not ok then
                warn("[Hyze callback error] " .. tostring(err))
                Library.Notify("error", "Callback error", tostring(err):sub(1, 160))
            end
        end)
    end

    local function wrapTab(name)
        local id = tabId(name)
        local base = Win[id]
        if not base then
            error("No GUI tab for '" .. tostring(name) .. "'")
        end
        local cur = base
        local function key(n)
            return id .. ":" .. tostring(n)
        end
        local Tab = {}

        function Tab:CreateSection(title)
            cur = base:Section(title)
            return {}
        end
        function Tab:CreateLabel(text)
            return cur:Label(text)
        end
        function Tab:CreateButton(o)
            cur:Button(o.Name, o.Callback)
            return {}
        end
        function Tab:CreateToggle(o)
            local k = key(o.Name)
            local cb = o.Callback
            local initial = Saved[k]
            if type(initial) ~= "boolean" then
                initial = o.CurrentValue == true
            end
            cur:Toggle(o.Name, initial, function(v)
                Saved[k] = v
                save()
                Library.Notify("info", o.Name, v and "Started" or "Stopped")
                if cb then cb(v) end
            end)
            -- the saved state is only pushed to the callback when it is ON, so a toggle that DEFAULTS to on but was saved OFF
            -- showed "off" while the script still behaved as "on". o.SyncInitial pushes the saved value either way.
            if cb and (initial or o.SyncInitial) then
                task.delay(1, function()
                    safeRun(cb, initial)
                end)
            end
            return {}
        end
        function Tab:CreateInput(o)
            local k = key(o.Name)
            local cb = o.Callback
            local initial = Saved[k]
            if type(initial) ~= "string" then
                initial = o.CurrentValue or ""
            end
            cur:Input(o.Name, initial, function(v)
                Saved[k] = v
                save()
                if cb then cb(v) end
            end, o.Placeholder)
            if cb then safeRun(cb, initial) end
            return {}
        end
        function Tab:CreateSlider(o)
            local k = key(o.Name)
            local cb = o.Callback
            local min, max = o.Range[1], o.Range[2]
            local inc = o.Increment or 1
            local initial = tonumber(Saved[k]) or o.CurrentValue or min
            cur:Slider(o.Name, min, max, initial, function(v)
                Saved[k] = v
                save()
                if cb then cb(v) end
            end, {
                decimals = (inc % 1 ~= 0),
                step = (inc ~= 1) and inc or nil,
                subtitle = o.Suffix,
            })
            if cb then safeRun(cb, initial) end
            return {}
        end
        function Tab:CreateMultiDropdown(o)
            local control = cur:MultiDropdown(o.Name, o.Options or {}, o.GetSet, o.Callback)
            local obj = {}
            function obj:Render() control.render() end
            return obj
        end
        function Tab:CreateDropdown(o)
            local k = key(o.Name)
            local cb = o.Callback
            local options = o.Options or {}
            local savedValue = Saved[k]
            local valid = false
            for _, opt in ipairs(options) do
                if opt == savedValue then valid = true end
            end
            local control = cur:Dropdown(o.Name, options, valid and savedValue or o.CurrentOption, function(v)
                Saved[k] = v
                save()
                if cb then cb(v) end
            end)
            if valid and cb then
                task.delay(0.5, function()
                    safeRun(cb, savedValue)
                end)
            end
            local obj = {}
            function obj:Refresh(newOptions, current)
                control:Refresh(newOptions, current)
            end
            return obj
        end
        return Tab
    end

    function HyzeRayfield:CreateWindow(_)
        local W = {}
        function W:CreateTab(name)
            return wrapTab(name)
        end
        return W
    end
    function HyzeRayfield:Notify(o)
        Library.Notify("info", o.Title or "", o.Content or "")
    end
    function HyzeRayfield:LoadConfiguration() end
end

-- ============================================================
--  KAIJU FUNCTIONS (Readme script)  -  running inside the bare Hyze GUI
--  Tabs: Main (Hyze) / Autofarm / Misc / Blacklist / Visuals (Hyze)
--  Toggles are saved by the Hyze config system (Hyze/<PlaceId>.json)
-- ============================================================
do
    local ok, err = xpcall(function()
    local Rayfield = HyzeRayfield
    _G.HyzePing.onChange = function(paused, ping)
        local ms = math.floor((ping or 0) + 0.5)
        if paused then
            Library.Notify("warning", "Ping", ms .. " ms - everything frozen until ping is stable")
        else
            Library.Notify("info", "Ping", "Ping stable - continuing where it left off")
        end
    end
    local Window = Rayfield:CreateWindow({})

    local function getPart()
        local char = LocalPlayer.Character
        return char and char:FindFirstChild("HumanoidRootPart")
    end


    -- what is switched on (shown by the debug overlay, "ON: ...")
    local states = {}

    -- ============================================================
    --  DEBUG + CRASH LOG
    --  * Live overlay (Visuals > Crash Debug, or the Spawn Debug toggle): everything that is going on
    --  * Crash log: written to Hyze/crashlog.txt twice a second. The log of the last 3 sessions is kept
    --    (Hyze/previous_1.txt ...), so after a crash you can open "View previous session" and read what
    --    the game was doing right before it died.
    -- ============================================================
    local dbg = { touches = 0, lastTouches = 0, rate = 0, last = "-", collectors = {}, lines = {}, fcache = {},
        startAt = _G.HyzePing.clock(), overlay = false, urgent = false, snap = "", fps = 60 }
    local LogService = game:GetService("LogService")
    local StatsService = game:GetService("Stats")
    local GuiService = game:GetService("GuiService")
    local LOG_FILE = "Hyze/crashlog.txt"

    local function dlog(msg)
        local line = string.format("[%7.1f] %s", _G.HyzePing.clock() - dbg.startAt, tostring(msg))
        local l = dbg.lines
        l[#l + 1] = line
        if #l > 200 then table.remove(l, 1) end
    end
    dbg.log = dlog

    pcall(function()
        if type(makefolder) == "function" and type(isfolder) == "function" and not isfolder("Hyze") then makefolder("Hyze") end
    end)
    -- rotate the old logs: crashlog -> previous_1 -> previous_2 -> previous_3
    pcall(function()
        if type(isfile) ~= "function" or type(readfile) ~= "function" or type(writefile) ~= "function" then return end
        local prev = isfile(LOG_FILE) and readfile(LOG_FILE) or nil
        if prev and prev ~= "" then
            for i = 3, 2, -1 do
                local f = "Hyze/previous_" .. (i - 1) .. ".txt"
                if isfile(f) then writefile("Hyze/previous_" .. i .. ".txt", readfile(f)) end
            end
            writefile("Hyze/previous_1.txt", prev)
            dbg.hadPrevious = true
        end
    end)

    local function parentGui(g)
        local ok = type(gethui) == "function" and pcall(function() g.Parent = gethui() end)
        if not ok then ok = pcall(function() g.Parent = game:GetService("CoreGui") end) end
        if not ok or not g.Parent then g.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    end

    -- FPS (own smoothing, independent from the collector's)
    game:GetService("RunService").Heartbeat:Connect(function(dt)
        if dt > 0 then dbg.fps = dbg.fps * 0.9 + (1 / dt) * 0.1 end
    end)

    -- everything the game / other scripts print as warning or error
    local lastMsg, lastLine, repeatN = nil, nil, 1
    pcall(function()
        LogService.MessageOut:Connect(function(message, mtype)
            local prefix
            if mtype == Enum.MessageType.MessageError then prefix = "ERROR "
            elseif mtype == Enum.MessageType.MessageWarning then prefix = "WARN  " end
            if not prefix then return end
            local text = tostring(message)
            local m = prefix .. text:match("^[^\n]*"):sub(1, 140)
            local scr, ln = text:match("Script '([^']+)', Line (%d+)")
            if scr then m = m .. "  @ " .. scr:match("[^%.]+$") .. ":" .. ln end
            local l = dbg.lines
            if m == lastMsg and l[#l] == lastLine then
                repeatN += 1 -- same error again and again: one line with a counter
                local line = string.format("[%7.1f] %s (x%d)", _G.HyzePing.clock() - dbg.startAt, m, repeatN)
                l[#l] = line
                lastLine = line
            else
                dlog(m)
                lastMsg, lastLine, repeatN = m, l[#l], 1
            end
        end)
    end)
    -- Roblox's own disconnect / kick message (tells a kick apart from a real crash)
    pcall(function()
        GuiService.ErrorMessageChanged:Connect(function()
            dlog("ROBLOX ERROR MESSAGE: " .. tostring(GuiService:GetErrorMessage()))
            dbg.urgent = true
        end)
    end)
    pcall(function()
        LocalPlayer.OnTeleport:Connect(function(state)
            dlog("TELEPORT state: " .. tostring(state))
            dbg.urgent = true
        end)
    end)
    LocalPlayer.CharacterAdded:Connect(function() dlog("character respawned") end)

    local function countOf(name)
        local c = dbg.fcache[name]
        if not c or _G.HyzePing.clock() - c.t > 3 then
            local f = Workspace:FindFirstChild(name)
            c = { t = _G.HyzePing.clock(), n = f and #f:GetChildren() or -1 }
            dbg.fcache[name] = c
        end
        return c.n
    end
    dbg.countOf = countOf

    local function buildSnapshot()
        local out = {}
        local hrp = getPart()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local mem, inst, prims, ping = 0, 0, 0, "-"
        pcall(function() mem = StatsService:GetTotalMemoryUsageMb() end)
        pcall(function() inst = StatsService.InstanceCount end)
        pcall(function() prims = StatsService.PrimitivesCount end)
        pcall(function() ping = math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5) .. " ms" end)
        local streaming = false
        pcall(function() streaming = Workspace.StreamingEnabled end)
        out[#out + 1] = string.format("== HYZE DEBUG  %s  up %ds  place %s ==", os.date("%H:%M:%S"), math.floor(_G.HyzePing.clock() - dbg.startAt), tostring(game.PlaceId))
        out[#out + 1] = string.format("FPS %d  ping %s  mem %d MB  lua %d MB", math.floor(dbg.fps + 0.5), ping, math.floor(mem), math.floor(collectgarbage("count") / 1024))
        out[#out + 1] = string.format("instances %s  prims %s  streaming %s", tostring(inst), tostring(prims), tostring(streaming))
        if hrp then
            out[#out + 1] = string.format("pos %d, %d, %d  hp %s", math.floor(hrp.Position.X), math.floor(hrp.Position.Y), math.floor(hrp.Position.Z), hum and math.floor(hum.Health) or "?")
        else
            out[#out + 1] = "pos: NO CHARACTER"
        end
        out[#out + 1] = string.format("actions/s %d  total %d", math.floor(dbg.rate), dbg.touches)
        
        for _, fn in pairs(dbg.collectors) do
            local ok, s = pcall(fn)
            if ok then out[#out + 1] = s end
        end
        local active = {}
        for k, v in pairs(states) do if v == true then active[#active + 1] = k end end
        table.sort(active)
        out[#out + 1] = "ON: " .. (#active > 0 and table.concat(active, ", ") or "-")
        out[#out + 1] = "last action: " .. tostring(dbg.last)
        if dbg.scan and dbg.scan.on then out[#out + 1] = dbg.scan.text end
        return table.concat(out, "\n")
    end

    local overlayLabel
    local function refreshOverlay()
        if not dbg.overlay then
            if overlayLabel and overlayLabel.Parent then overlayLabel.Parent:Destroy() end
            overlayLabel = nil
            return
        end
        if not overlayLabel or not overlayLabel.Parent then
            local g = Instance.new("ScreenGui")
            g.Name, g.ResetOnSpawn, g.DisplayOrder, g.IgnoreGuiInset = "HyzeDebugOverlay", false, 9999, true
            parentGui(g)
            local t = Instance.new("TextLabel")
            t.Size, t.Position = UDim2.new(0.66, 0, 0.74, 0), UDim2.new(0, 6, 0.12, 0)
            t.BackgroundColor3, t.BackgroundTransparency = Color3.new(0, 0, 0), 0.3
            t.TextColor3, t.TextXAlignment, t.TextYAlignment = Color3.fromRGB(255, 235, 140), Enum.TextXAlignment.Left, Enum.TextYAlignment.Top
            t.TextSize, t.Font, t.TextWrapped, t.ClipsDescendants = 11, Enum.Font.Code, true, true
            t.Active, t.Selectable = false, false
            t.Parent = g
            overlayLabel = t
        end
        local l, shown = dbg.lines, {}
        for i = math.max(1, #l - 13), #l do shown[#shown + 1] = l[i] end
        overlayLabel.Text = dbg.snap .. "\n-- events --\n" .. table.concat(shown, "\n")
    end
    function dbg.setOverlay(on)
        dbg.overlay = on and true or false
        refreshOverlay()
    end

    local function fullLog()
        return dbg.snap .. "\n\n--- events (oldest first) ---\n" .. table.concat(dbg.lines, "\n")
    end
    dbg.fullLog = fullLog

    function dbg.showText(title, text)
        pcall(function()
            local old = (type(gethui) == "function" and gethui() or game:GetService("CoreGui")):FindFirstChild("HyzeLogView")
            if old then old:Destroy() end
        end)
        if #text > 15000 then text = "(cut, showing the end)\n" .. text:sub(-15000) end
        local g = Instance.new("ScreenGui")
        g.Name, g.ResetOnSpawn, g.DisplayOrder, g.IgnoreGuiInset = "HyzeLogView", false, 10001, true
        parentGui(g)
        local f = Instance.new("Frame")
        f.Size, f.Position = UDim2.new(0.94, 0, 0.82, 0), UDim2.new(0.03, 0, 0.09, 0)
        f.BackgroundColor3, f.BorderSizePixel = Color3.fromRGB(14, 14, 20), 0
        f.Parent = g
        local head = Instance.new("TextLabel")
        head.Size, head.BackgroundTransparency, head.Text = UDim2.new(1, -170, 0, 30), 1, "  " .. title
        head.TextColor3, head.TextXAlignment, head.TextSize, head.Font = Color3.new(1, 1, 1), Enum.TextXAlignment.Left, 14, Enum.Font.GothamBold
        head.Parent = f
        local function btn(txt, x, cb)
            local b = Instance.new("TextButton")
            b.Size, b.Position, b.Text = UDim2.new(0, 76, 0, 24), UDim2.new(1, x, 0, 3), txt
            b.BackgroundColor3, b.TextColor3, b.TextSize, b.Font = Color3.fromRGB(45, 45, 60), Color3.new(1, 1, 1), 12, Enum.Font.GothamBold
            b.BorderSizePixel = 0
            b.Parent = f
            b.MouseButton1Click:Connect(cb)
        end
        btn("Close", -82, function() g:Destroy() end)
        btn("Copy", -162, function()
            if type(setclipboard) == "function" then
                pcall(setclipboard, text)
                Library.Notify("success", "Debug", "Log copied")
            else
                Library.Notify("warning", "Debug", "Your executor has no clipboard")
            end
        end)
        local sf = Instance.new("ScrollingFrame")
        sf.Size, sf.Position = UDim2.new(1, -8, 1, -38), UDim2.new(0, 4, 0, 34)
        sf.BackgroundTransparency, sf.BorderSizePixel = 1, 0
        sf.AutomaticCanvasSize, sf.CanvasSize, sf.ScrollBarThickness = Enum.AutomaticSize.Y, UDim2.new(), 6
        sf.Parent = f
        local tl = Instance.new("TextLabel")
        tl.Size, tl.AutomaticSize, tl.BackgroundTransparency = UDim2.new(1, -8, 0, 0), Enum.AutomaticSize.Y, 1
        tl.Text, tl.TextWrapped, tl.TextSize, tl.Font = text, true, 11, Enum.Font.Code
        tl.TextColor3, tl.TextXAlignment, tl.TextYAlignment = Color3.fromRGB(230, 230, 235), Enum.TextXAlignment.Left, Enum.TextYAlignment.Top
        tl.Parent = sf
    end

    function dbg.readPrevious(n)
        local f = "Hyze/previous_" .. n .. ".txt"
        local ok, s = pcall(function()
            if type(isfile) == "function" and isfile(f) then return readfile(f) end
        end)
        return ok and s or nil
    end

    -- main loop: rate, snapshot, file, overlay
    task.spawn(function()
        local lastAt, lastSnapLine, lastWrite = _G.HyzePing.clock(), 0, 0
        while true do
            _G.HyzePing.wait(0.5)
            if not (dbg.overlay or (dbg.scan and dbg.scan.on)) then
                -- debug is off: no snapshot, no log file, nothing to slow the farm down
                lastAt, dbg.lastTouches = _G.HyzePing.clock(), dbg.touches
                _G.HyzePing.wait(1)
                continue
            end
            local now = _G.HyzePing.clock()
            dbg.rate = (dbg.touches - dbg.lastTouches) / math.max(now - lastAt, 0.1)
            dbg.lastTouches, lastAt = dbg.touches, now
            -- performance: the heavy part (snapshot + file write) only runs every 3s, or right away when the overlay is open / something urgent happened
            local due = dbg.overlay or dbg.urgent or (dbg.scan and dbg.scan.on) or (now - lastWrite >= 3)
            if due then
                local ok, snap = pcall(buildSnapshot)
                if ok then dbg.snap = snap end
            end
            -- a short history line so the file shows the trend before a crash (fps / memory / touches)
            local anyOn = false
            for _, v in pairs(states) do if v == true then anyOn = true break end end
            if now - lastSnapLine >= (anyOn and 1 or 5) then
                lastSnapLine = now
                local mem = 0
                pcall(function() mem = StatsService:GetTotalMemoryUsageMb() end)
                dlog(string.format("fps %d mem %d inst %s act/s %d | %s", math.floor(dbg.fps + 0.5), math.floor(mem),
                    tostring((pcall(function() return StatsService.InstanceCount end) and StatsService.InstanceCount) or "?"),
                    math.floor(dbg.rate), tostring(dbg.last)))
            end
            if due then
                lastWrite = now
                pcall(function()
                    if type(writefile) == "function" then writefile(LOG_FILE, fullLog()) end
                end)
            end
            dbg.urgent = false
            pcall(refreshOverlay)
        end
    end)

    dlog("session start | executor: " .. tostring((type(identifyexecutor) == "function" and identifyexecutor()) or "?")
        .. " | firetouchinterest: " .. type(firetouchinterest) .. " | writefile: " .. type(writefile))
    if dbg.hadPrevious then
        Library.Notify("info", "Crash Debug", "Previous session log saved (Visuals > Crash Debug)")
    end

    -- ============================================================
    --  NEARBY SCANNER
    --  Lists everything within <radius> studs (default 300) of the location you set, once per second:
    --  which folders/models are there, how many parts and items, and how far the nearest one is.
        --  Uses a spatial query (GetPartBoundsInRadius), so it does not walk the whole map.
    -- ============================================================
    local scan = { on = false, radius = 300, center = nil, text = "scan: off" }
    dbg.scan = scan
    local CLOVER_FOLDERS = {} -- (no game specific folders in this build)

    local function itemPos(o)
        if o:IsA("BasePart") then return o.Position end
        if o:IsA("Model") then
            local ok, cf = pcall(function() return o:GetPivot() end)
            if ok then return cf.Position end
        end
        local p = o:FindFirstChildWhichIsA("BasePart", true)
        return p and p.Position or nil
    end

    local lastCloverScan, cloverLines = 0, {}
    local function scanClovers(me, center)
        -- nearest clover per folder (walks the folder, so only every 2s, and in chunks)
        if _G.HyzePing.clock() - lastCloverScan < 2 then return end
        lastCloverScan = _G.HyzePing.clock()
        local lines = {}
        for _, name in ipairs(CLOVER_FOLDERS) do
            local f = Workspace:FindFirstChild(name)
            if not f then
                lines[#lines + 1] = string.format("%s: not in the workspace", name)
            else
                local kids = f:GetChildren()
                local nearest, nearestPlayer, within = math.huge, math.huge, 0
                for i, o in ipairs(kids) do
                    if i % 250 == 0 then _G.HyzePing.wait() end
                    local pos = itemPos(o)
                    if pos then
                        if me then nearestPlayer = math.min(nearestPlayer, (pos - me).Magnitude) end
                        local d = (pos - center).Magnitude
                        nearest = math.min(nearest, d)
                        if d <= scan.radius then within += 1 end
                    end
                end
                lines[#lines + 1] = string.format("%s: %d items | nearest to YOU %s | %d within %d of the location",
                    name, #kids, nearestPlayer < math.huge and (math.floor(nearestPlayer) .. " studs") or "-", within, scan.radius)
            end
        end
        cloverLines = lines
    end

    local function runScan()
        local root = getPart()
        local me = root and root.Position
        local center = scan.center or me
        if not center then scan.text = "scan: no character / no location" return end
        local params = OverlapParams.new()
        params.MaxParts = 2000
        local char = LocalPlayer.Character
        if char then
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = { char }
        end
        local parts = Workspace:GetPartBoundsInRadius(center, scan.radius, params)
        local groups = {}
        for _, p in ipairs(parts) do
            local top, item = p, p
            while top.Parent and top.Parent ~= Workspace do
                item = top
                top = top.Parent
            end
            if top.Parent == Workspace then
                if top == p then item = p end
                local g = groups[top]
                if not g then g = { name = top.Name, class = top.ClassName, parts = 0, items = {}, nItems = 0, nearest = math.huge } groups[top] = g end
                g.parts += 1
                if not g.items[item] then g.items[item] = true g.nItems += 1 end
                local d = (p.Position - center).Magnitude
                if d < g.nearest then g.nearest = d end
            end
        end
        local list = {}
        for _, g in pairs(groups) do list[#list + 1] = g end
        table.sort(list, function(a, b) return a.parts > b.parts end)
        local out = {}
        out[#out + 1] = string.format("NEARBY: radius %d around %d, %d, %d%s | %d parts%s", scan.radius,
            math.floor(center.X), math.floor(center.Y), math.floor(center.Z), scan.center and " (set)" or " (you)", #parts,
            #parts >= 2000 and " (capped)" or "")
        if scan.center and me then
            out[#out + 1] = string.format("you are %d studs from the set location", math.floor((me - scan.center).Magnitude))
        end
        for i = 1, math.min(#list, 12) do
            local g = list[i]
            out[#out + 1] = string.format("  %s [%s]: %d parts, %d items, nearest %d", g.name, g.class, g.parts, g.nItems, math.floor(g.nearest))
        end
        if #list == 0 then out[#out + 1] = "  (nothing within range)" end
        pcall(scanClovers, me, center)
        for _, l in ipairs(cloverLines) do out[#out + 1] = l end
        scan.text = table.concat(out, "\n")
    end

    task.spawn(function()
        while true do
            _G.HyzePing.wait(1)
            if scan.on then
                local ok, err = pcall(runScan)
                if not ok then scan.text = "scan error: " .. tostring(err):sub(1, 120) end
            end
        end
    end)

    -- ============================================================
    --  KAIJU FUNCTIONS  (taken from the Readme script, its own GUI removed)
    --  The functions run unchanged in spirit; the controls now live in the Hyze tabs:
    --  Autofarm / Misc / Blacklist.   Original script: made with love by studly <3
    --  Notes:
    --   * the old "branding check" (the script shut itself down when its title text was changed) is gone with the GUI
    --   * remotes / folders are looked up when needed, so the GUI still loads in other games
    -- ============================================================
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local TeleportService = game:GetService("TeleportService")
    local UserInputService = game:GetService("UserInputService")
    local httpRequest = (syn and syn.request) or http_request or request or (fluxus and fluxus.request)
    local function pwait(t) return _G.HyzePing.wait(t) end

    -- settings (same numbers as the Readme script)
    local FOLLOW_TWEEN         = 0.01  -- Player / Beam: how fast you glide to the target
    local FOLLOW_DELAY         = 0.01  -- pause between follow updates
    local BUILDING_TWEEN       = 0.08  -- Building autofarm: glide time between buildings
    local KEY_DELAY            = 0.1   -- pause between skill key presses
    local MAX_RESPAWN_ATTEMPTS = 15    -- after this many failed attempts a target is ignored
    local BEAM_RESPAWN_EVERY   = 10    -- seconds between respawns in Beam autofarm
    local SPEED_MIN, SPEED_MAX, SPEED_DEFAULT = 0, 250, 100
    local FARM_MODES = { "Player Autofarm", "Beam Autofarm", "Building Autofarm" }
    local PRIORITIES = { "Lowest Level", "Highest Level", "Random", "Closest" }
    local AUTO_TARGET = "Auto (by priority)"
    local FREE_KAIJUS = { "Anguirus", "Anguirus 1955", "Gojira 1955", "Suko", "Junior Godzilla", "Kamata Kun" }
    local blacklist = {
        ["Showa Ghidorah"] = true, ["Showa Mothra"] = true, ["Showa Rodan"] = true,
        ["Destoroyah Flying Form"] = true, ["Male Muto"] = true,
    }
    -- accounts that kick you out when they join the server (admin detector from the Readme script)
    local ADMIN_IDS = {
        [300706958] = true, [166836030] = true, [2978243874] = true, [3492084409] = true, [5085976766] = true,
        [4044751953] = true, [5029625673] = true, [10513578353] = true, [776897744] = true, [8473591060] = true,
        [5076589580] = true, [1324414468] = true, [3441625467] = true, [1783277662] = true, [2210363838] = true,
        [4190983061] = true, [8341047313] = true,
    }

    local K = {
        enabled = false, mode = FARM_MODES[1], priority = PRIORITIES[1],
        studsUnder = -1, selectedName = "", target = nil,
        ignored = {}, respawnTries = {},
        keyLoop = false, followLoop = false, beamLoop = false, playerLoop = false,
        infiniteHealth = false, respawnDebounce = false,
        buildIndex = 0, buildName = nil, buildGoal = nil,
        sessionStart = 0, cellsTotal = 0, cellsBase = 0, cellsObj = nil, cellsConn = nil, lsConn = nil,
        skill = { Regen = false, Strength = false, Health = false, Speed = false },
        fly = false, noclip = false, noclipOriginal = {},
        speedOn = false, speedValue = SPEED_DEFAULT,
        removePick = nil, newKaiju = "",
    }

    -- labels (created below in the Autofarm tab)
    local lblStatus, lblTarget, lblCells, lblSession, lblBlack
    local function setText(lbl, txt) if lbl and lbl.Parent then lbl.Text = txt end end

    -- ===== basic lookups =====
    local function liveFolder() return Workspace:FindFirstChild("Live") end
    local function liveChar()
        local l = liveFolder()
        return l and l:FindFirstChild(LocalPlayer.Name)
    end
    local function remote(name)
        local r = ReplicatedStorage:FindFirstChild("Remotes")
        return r and r:FindFirstChild(name)
    end
    local function fireRemote(name, ...)
        local r = remote(name)
        if not r then return false end
        local a = table.pack(...)
        dbg.touches += 1
        dbg.last = "remote " .. name .. " " .. tostring(a[1])
        return pcall(function() r:FireServer(table.unpack(a, 1, a.n)) end)
    end
    local function kaijuOf(player)
        local ls = player and player:FindFirstChild("leaderstats")
        local k = ls and ls:FindFirstChild("Kaiju")
        return k and k.Value or nil
    end
    local function myKaiju() return kaijuOf(LocalPlayer) end
    local function myRoot()
        local c = LocalPlayer.Character
        return c and c:FindFirstChild("HumanoidRootPart")
    end
    local function toNum(v)
        if typeof(v) == "number" then return v end
        if typeof(v) == "string" then return tonumber((v:gsub(",", ""))) or 0 end
        return tonumber(tostring(v)) or 0
    end
    local function commas(n)
        local s = tostring(math.floor(n))
        repeat
            local r, c = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
            s = r
        until c == 0
        return s
    end
    local function setState(name, v)
        states[name] = v and true or false
    end

    -- ===== level of a player (read from the overhead GUI) =====
    local function levelOf(player)
        local live = liveFolder()
        local ch = live and live:FindFirstChild(player.Name)
        local overhead = ch and ch:FindFirstChild("Overhead")
        local frame = overhead and overhead:FindFirstChildOfClass("Frame")
        local level = frame and frame:FindFirstChild("Level")
        local lbl = level and level:FindFirstChildOfClass("TextLabel")
        return lbl and tonumber(string.match(lbl.Text, "%d+")) or nil
    end

    -- ===== target selection =====
    local function validTarget(p)
        if not p or K.ignored[p.Name] then return false end
        local kj = kaijuOf(p)
        if kj ~= nil and blacklist[kj] == true then return false end
        local c = p.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        local r = c and c:FindFirstChild("HumanoidRootPart")
        return h ~= nil and h.Health > 0 and r ~= nil
    end
    local function candidates()
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and validTarget(p) then list[#list + 1] = p end
        end
        return list
    end
    local function closestTarget()
        local me = myRoot()
        if not me then return nil end
        local best, bestD = nil, math.huge
        for _, p in ipairs(candidates()) do
            local d = (me.Position - p.Character.HumanoidRootPart.Position).Magnitude
            if d < bestD then best, bestD = p, d end
        end
        return best
    end
    local function randomTarget()
        local l = candidates()
        return #l > 0 and l[math.random(1, #l)] or nil
    end
    local function levelList()
        local list = {}
        for _, p in ipairs(candidates()) do
            local lv = levelOf(p)
            if lv then list[#list + 1] = { player = p, level = lv } end
        end
        table.sort(list, function(a, b)
            if a.level ~= b.level then return a.level < b.level end
            return a.player.Name < b.player.Name
        end)
        return list
    end
    local function pickTarget()
        local pr = K.priority
        if pr == "Highest Level" then
            local l = levelList()
            return (l[#l] and l[#l].player) or closestTarget()
        elseif pr == "Random" then
            return randomTarget() or closestTarget()
        elseif pr == "Closest" then
            local v = closestTarget()
            if not v then
                local l = levelList()
                v = l[1] and l[1].player
            end
            return v
        end
        local l = levelList()
        return (l[1] and l[1].player) or closestTarget()
    end
    local function selectedTarget()
        if K.selectedName ~= "" then
            local p = Players:FindFirstChild(K.selectedName)
            if p then return p end
            for _, pl in ipairs(Players:GetPlayers()) do
                if pl.Name:lower():find(K.selectedName:lower(), 1, true) then return pl end
            end
        end
        return nil
    end
    -- ignored targets stay ignored while they are alive; once dead / gone they are released
    local function cleanIgnored()
        for name in pairs(K.ignored) do
            local p = Players:FindFirstChild(name)
            local c = p and p.Character
            local h = c and c:FindFirstChildOfClass("Humanoid")
            local r = c and c:FindFirstChild("HumanoidRootPart")
            if not (h and h.Health > 0 and r) then
                K.ignored[name] = nil
                K.respawnTries[name] = nil
            end
        end
    end

    -- ===== building autofarm =====
    local function basePart(inst)
        if not inst or #inst:GetChildren() == 0 then return nil end
        if inst:IsA("Model") and inst.PrimaryPart then return inst.PrimaryPart end
        if not inst:IsA("BasePart") then return inst:FindFirstChildWhichIsA("BasePart", true) end
        return inst
    end
    local function buildings()
        local map = Workspace:FindFirstChild("Map")
        local city = map and map:FindFirstChild("CityFolder")
        local list = {}
        if not city then return list end
        for _, c in ipairs(city:GetChildren()) do
            if basePart(c) then list[#list + 1] = c end
        end
        return list
    end
    local function glideTo(cf, t)
        local root = myRoot()
        if not root then return false end
        TweenService:Create(root, TweenInfo.new(t, Enum.EasingStyle.Linear), { CFrame = cf }):Play()
        return true
    end
    local function stepBuilding(root)
        local list = buildings()
        if not root or #list == 0 then
            K.buildIndex, K.buildName, K.buildGoal = 0, nil, nil
            return
        end
        table.sort(list, function(a, b) return a.Name < b.Name end)
        if K.buildIndex < 1 or #list < K.buildIndex then K.buildIndex = 1 end
        local b = list[K.buildIndex]
        local part = basePart(b)
        if not b or not part then
            K.buildIndex = math.clamp(K.buildIndex + 1, 1, #list)
            return
        end
        local cf = part.CFrame * CFrame.new(0, -K.studsUnder, 0)
        K.buildName, K.buildGoal = b.Name, cf.Position
        glideTo(cf, BUILDING_TWEEN)
        K.buildIndex = K.buildIndex % #list + 1
    end

    -- ===== keys / skills =====
    local KC = Enum.KeyCode
    local function sendKey(key)
        VirtualInputManager:SendKeyEvent(true, key, false, game)
        pwait(0.02)
        VirtualInputManager:SendKeyEvent(false, key, false, game)
        dbg.touches += 1
        dbg.last = "key " .. tostring(key.Name)
    end
    local function keysFor(mode, amount)
        if mode == "Biollante" then
            if amount >= 15 and amount <= 25 then return { KC.Two, KC.Three } end
            return nil
        elseif mode == "Kong 2017" or mode == "Titan X" or mode == "Space Godzilla" then
            return { KC.One, KC.Two, KC.Three, KC.Four, KC.Five }
        elseif mode == "Kong 2021" then return { KC.One, KC.Two, KC.Four, KC.Five }
        elseif mode == "Godzilla 2021" or mode == "Monster Zero" or mode == "Shimo" then
            return { KC.One, KC.Two, KC.Three, KC.Five }
        elseif mode == "Godzilla 2019" then return { KC.One, KC.Two, KC.Four }
        elseif mode == "Mecha Godzilla 2021" or mode == "Thermonuclear Godzilla" or mode == "Frostbite Godzilla" then
            return { KC.One, KC.Two, KC.Three, KC.Four }
        end
        return nil
    end
    local function skillKeys()
        local list = { KC.One, KC.Two, KC.Three }
        local mode = myKaiju()
        if mode then
            local v = keysFor(mode, K.studsUnder)
            if v then return v end
            if mode == "Godzilla Minus One" then
                local c = LocalPlayer.Character
                local h = c and c:FindFirstChildOfClass("Humanoid")
                if h and h.MaxHealth > 0 and h.Health / h.MaxHealth <= 0.3 then
                    table.insert(list, KC.Four)
                    table.insert(list, KC.Four)
                    table.insert(list, KC.Four)
                    return list
                end
            elseif mode == "Shin Godzilla" then
                table.insert(list, KC.Five)
            end
        end
        return list
    end
    -- Beam autofarm: aim at the target, fire the beam remote 3x, press 4
    local function beamAim()
        local t = K.target or pickTarget()
        if t and t.Character then
            local hrp = t.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local pos = hrp.Position
                pcall(function()
                    local cam = Workspace.CurrentCamera
                    local sp, onScreen = cam:WorldToScreenPoint(pos)
                    if onScreen then VirtualInputManager:SendMouseMoveEvent(sp.X, sp.Y, game) end
                end)
                for _ = 1, 3 do fireRemote("BeamRemote", pos) end
            end
        end
        sendKey(KC.Four)
    end

    -- ===== labels / status =====
    local function updateCellsText() setText(lblCells, "Cells earned: " .. commas(K.cellsTotal)) end
    local function updateSessionText()
        if not K.enabled or not (K.sessionStart > 0) then
            setText(lblSession, "Session time: 0s")
            return
        end
        local s = math.max(0, math.floor(_G.HyzePing.clock() - K.sessionStart))
        local m = math.floor(s / 60)
        setText(lblSession, "Session time: " .. (m > 0 and string.format("%dm %ds", m, s % 60) or string.format("%ds", s)))
    end
    local function updateText()
        updateCellsText()
        updateSessionText()
        cleanIgnored()
        if K.mode == "Building Autofarm" then
            setText(lblTarget, "Target: " .. (K.buildName and ("Bldg: " .. K.buildName) or "Building: ready"))
            return
        end
        local sel = selectedTarget()
        if validTarget(sel) then
            K.target = sel
        elseif not validTarget(K.target) then
            K.target = pickTarget()
        end
        if not K.target then
            setText(lblTarget, "Target: none")
            return
        end
        local lv = levelOf(K.target)
        local pre = K.mode == "Beam Autofarm" and "Beam: " or ""
        setText(lblTarget, "Target: " .. pre .. K.target.Name .. (lv and (" Lv." .. lv) or ""))
    end

    -- ===== cells earned (session counter) =====
    local function dropCells()
        if K.cellsConn then K.cellsConn:Disconnect() K.cellsConn = nil end
        if K.lsConn then K.lsConn:Disconnect() K.lsConn = nil end
        K.cellsObj = nil
    end
    local function hookCells()
        if K.cellsConn then K.cellsConn:Disconnect() K.cellsConn = nil end
        local ls = LocalPlayer:FindFirstChild("leaderstats")
        K.cellsObj = ls and ls:FindFirstChild("Cells")
        if not K.cellsObj then return end
        K.cellsBase = toNum(K.cellsObj.Value)
        K.cellsConn = K.cellsObj:GetPropertyChangedSignal("Value"):Connect(function()
            local now = toNum(K.cellsObj.Value)
            local gain = now - K.cellsBase
            if K.enabled and gain > 0 then K.cellsTotal += gain end
            K.cellsBase = now
            updateCellsText()
        end)
    end
    local function startCells()
        K.cellsTotal = 0
        updateCellsText()
        hookCells()
        local ls = LocalPlayer:FindFirstChild("leaderstats")
        if not ls then return end
        if K.lsConn then K.lsConn:Disconnect() end
        K.lsConn = ls.ChildAdded:Connect(function(c)
            if c.Name == "Cells" and K.enabled then hookCells() end
        end)
    end

    -- ===== respawn (used by Beam autofarm and Player autofarm with infinite health) =====
    local function respawnAs(kaiju)
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local lc = liveChar()
        local lroot = lc and lc:FindFirstChild("HumanoidRootPart")
        local saved = lroot and lroot.CFrame or root.CFrame
        fireRemote("CombatRemote", "Death")
        pwait(3)
        fireRemote("FireServer", "Spawn", kaiju, "Desert")
        local t0 = os.clock()
        local char2
        while true do
            pwait(0.05)
            char2 = LocalPlayer.Character
            if (not char2 or char2 == char) and not (os.clock() - t0 > 10) then continue end
            break
        end
        if char2 and char2 ~= char then
            local limit = os.clock() + 10
            local lc2
            repeat
                pwait(0.05)
                lc2 = liveChar()
            until lc2 or os.clock() > limit
            if lc2 then
                local hrp = lc2:WaitForChild("HumanoidRootPart", 10)
                if hrp then
                    pwait(0.1)
                    hrp.CFrame = saved
                end
            end
        end
    end
    -- Player autofarm without infinite health: respawn after dying (5s), and give up on a target we can't kill
    local function onDied()
        if K.respawnDebounce or not K.enabled or (K.mode == "Player Autofarm" and K.infiniteHealth) then return end
        K.respawnDebounce = true
        task.delay(5, function()
            if not K.enabled then K.respawnDebounce = false return end
            local t = K.target
            if t and t.Parent then
                local c = t.Character
                local h = c and c:FindFirstChildOfClass("Humanoid")
                local r = c and c:FindFirstChild("HumanoidRootPart")
                if h and h.Health > 0 and r then
                    local n = t.Name
                    K.respawnTries[n] = (K.respawnTries[n] or 0) + 1
                    if K.respawnTries[n] >= MAX_RESPAWN_ATTEMPTS then
                        K.ignored[n] = true
                        K.respawnTries[n] = nil
                        if K.selectedName == n then K.selectedName = "" end
                        K.target = nil
                    end
                end
            end
            local kj = myKaiju()
            if kj then fireRemote("FireServer", "Spawn", kj, "Tokyo") end
            K.respawnDebounce = false
            updateText()
        end)
    end

    -- ===== the autofarm loops =====
    local function farmInput()
        local c = LocalPlayer.Character
        if not c or not c:FindFirstChild("HumanoidRootPart") then return end
        if K.mode == "Beam Autofarm" then beamAim() return end
        if K.mode == "Building Autofarm" then
            sendKey(KC.One) sendKey(KC.Two) sendKey(KC.Three)
            return
        end
        if not K.target then
            local t = pickTarget()
            if t then K.target = t end
        end
        for _, key in ipairs(skillKeys()) do sendKey(key) end
    end
    local function startKeyLoop()
        if K.keyLoop then return end
        K.keyLoop = true
        task.spawn(function()
            while K.enabled do
                pcall(farmInput)
                if K.mode ~= "Beam Autofarm" then pwait(KEY_DELAY) else pwait(0.03) end
            end
            K.keyLoop = false
        end)
    end
    local function startFollowLoop()
        if K.followLoop then return end
        K.followLoop = true
        task.spawn(function()
            while K.enabled do
                pcall(function()
                    local root = myRoot()
                    if K.mode ~= "Building Autofarm" then
                        updateText()
                        local t = K.target
                        if t and t.Character and root then
                            local hrp = t.Character:FindFirstChild("HumanoidRootPart")
                            if hrp then glideTo(hrp.CFrame * CFrame.new(0, -K.studsUnder, 0), FOLLOW_TWEEN) end
                        end
                    else
                        stepBuilding(root)
                    end
                    updateText()
                end)
                pwait(K.mode == "Building Autofarm" and BUILDING_TWEEN or FOLLOW_DELAY)
            end
            K.followLoop = false
        end)
    end
    local function startBeamRespawnLoop()
        if K.mode ~= "Beam Autofarm" or K.beamLoop then return end
        K.beamLoop = true
        task.spawn(function()
            while K.enabled and K.mode == "Beam Autofarm" do
                local waited = 0
                while waited < BEAM_RESPAWN_EVERY and K.enabled and K.mode == "Beam Autofarm" do
                    pwait(0.1)
                    waited += 0.1
                end
                if not K.enabled or K.mode ~= "Beam Autofarm" then break end
                local kj = myKaiju()
                if kj then
                    respawnAs(kj)
                    continue
                end
                pwait(0.5)
            end
            K.beamLoop = false
        end)
    end
    local function startPlayerRespawnLoop()
        if K.mode ~= "Player Autofarm" or K.playerLoop then return end
        K.playerLoop = true
        task.spawn(function()
            while K.enabled and K.mode == "Player Autofarm" do
                local waited = 0
                while waited < 10 and K.enabled and K.mode == "Player Autofarm" and K.infiniteHealth do
                    pwait(0.1)
                    waited += 0.1
                end
                if not K.enabled or K.mode ~= "Player Autofarm" then break end
                if K.infiniteHealth then
                    local kj = myKaiju()
                    if kj then
                        respawnAs(kj)
                        continue
                    end
                end
                pwait(0.5)
            end
            K.playerLoop = false
        end)
    end
    local function startModeLoops()
        startBeamRespawnLoop()
        startPlayerRespawnLoop()
    end
    local function setAutofarm(on)
        K.enabled = on and true or false
        setState("Autofarm", K.enabled)
        K.respawnTries, K.ignored = {}, {}
        K.buildIndex, K.buildName, K.buildGoal = 0, nil, nil
        if not K.enabled then
            K.target = nil
            K.sessionStart = 0
            dropCells()
            K.cellsTotal = 0
            updateCellsText()
            updateSessionText()
            setText(lblStatus, "Status: OFFLINE  -  turn Autofarm on to begin")
            return
        end
        K.sessionStart = _G.HyzePing.clock()
        startCells()
        setText(lblStatus, "Status: ACTIVE  -  farming enabled")
        startKeyLoop()
        startFollowLoop()
        startModeLoops()
        updateText()
    end

    -- ===== fly / noclip / server speed =====
    local function ensureAttrs(inst)
        if not inst then return nil end
        if inst:GetAttribute("IsFlying") == nil then inst:SetAttribute("IsFlying", false) end
        if inst:GetAttribute("UseServerSpeed") == nil then inst:SetAttribute("UseServerSpeed", false) end
        if inst:GetAttribute("ServerSpeed") == nil then inst:SetAttribute("ServerSpeed", SPEED_DEFAULT) end
        return inst
    end
    local function enforceSpeed()
        if not K.speedOn then return end
        local inst = ensureAttrs(liveChar())
        if not inst then return end
        if inst:GetAttribute("UseServerSpeed") ~= true then inst:SetAttribute("UseServerSpeed", true) end
        if tonumber(inst:GetAttribute("ServerSpeed")) ~= K.speedValue then inst:SetAttribute("ServerSpeed", K.speedValue) end
    end
    local function setNoclipParts(on)
        local c = liveChar()
        if not c then return end
        for _, d in ipairs(c:GetDescendants()) do
            if d:IsA("BasePart") then
                if on then
                    if K.noclipOriginal[d] == nil then K.noclipOriginal[d] = d.CanCollide end
                    d.CanCollide = false
                elseif K.noclipOriginal[d] ~= nil then
                    d.CanCollide = K.noclipOriginal[d]
                    K.noclipOriginal[d] = nil
                end
            end
        end
    end
    local function setFly(on)
        K.fly = on and true or false
        setState("Fly", K.fly)
        local inst = ensureAttrs(liveChar())
        if inst then inst:SetAttribute("IsFlying", K.fly) end
    end
    local function setNoclip(on)
        K.noclip = on and true or false
        setState("Noclip", K.noclip)
        setNoclipParts(K.noclip)
    end
    local function setServerSpeed(on)
        K.speedOn = on and true or false
        setState("ServerSpeed", K.speedOn)
        local inst = ensureAttrs(liveChar())
        if inst then
            inst:SetAttribute("UseServerSpeed", K.speedOn)
            if K.speedOn then inst:SetAttribute("ServerSpeed", K.speedValue) end
        end
        if K.speedOn then enforceSpeed() end
    end
    task.spawn(function()
        while true do
            pwait(0.05)
            if K.speedOn then pcall(enforceSpeed) end
            if K.noclip then pcall(setNoclipParts, true) end
        end
    end)

    -- ===== misc buttons =====
    local function buyFreeKaijus()
        for _, name in ipairs(FREE_KAIJUS) do
            fireRemote("FireServer", "Buy", name)
            pwait(0.08)
        end
    end
    -- finds a public server of this game that is not full and not the current one
    local function findServerId()
        if typeof(httpRequest) ~= "function" then return nil end
        local cursor = ""
        for _ = 1, 8 do
            local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
            if cursor ~= "" then url = url .. "&cursor=" .. HttpService:UrlEncode(cursor) end
            local ok, res = pcall(function() return httpRequest({ Url = url, Method = "GET" }) end)
            if not ok or not res or not res.Body then break end
            local ok2, body = pcall(function() return HttpService:JSONDecode(res.Body) end)
            if not ok2 or typeof(body) ~= "table" then break end
            for _, s in ipairs(body.data or {}) do
                if s.id ~= game.JobId and tonumber(s.playing) and tonumber(s.maxPlayers) and s.playing < s.maxPlayers then
                    return s.id
                end
            end
            cursor = body.nextPageCursor or ""
            if cursor == "" then break end
        end
        return nil
    end
    -- ===== random server hop (only servers with HOP_MIN_PLAYERS-HOP_MAX_PLAYERS players, never one already visited) =====
    local HOP_EVERY = 300      -- seconds between hops (5 minutes)
    local HOP_RETRY = 30       -- no suitable server found / teleport failed: try again after this many seconds
    local HOP_PAGES = 10       -- how many pages (100 servers each) of the server list are looked through
    local HOP_MIN_PLAYERS = 14 -- only servers with at least this many players
    local HOP_MAX_PLAYERS = 17 -- ...and at most this many
    local HOP_SEEN_MAX = 40    -- remembered servers; when the list gets this long it is cleared (current server is kept)
    local hop = { on = false, nextAt = 0, busy = false }
    local lblHop
    local function hopSeen()
        local g = (type(getgenv) == "function" and getgenv()) or _G
        g.HyzeHopSeen = g.HyzeHopSeen or {}
        local n = 0
        for _ in pairs(g.HyzeHopSeen) do n += 1 end
        if n >= HOP_SEEN_MAX then
            g.HyzeHopSeen = {} -- start over so the list never runs dry
        end
        return g.HyzeHopSeen
    end
    -- all public servers that are not full, not this one, never visited before, and have 14-17 players
    local function pickHopServer()
        if typeof(httpRequest) ~= "function" then return nil, "your executor has no request function" end
        local seen = hopSeen()
        seen[game.JobId] = true -- always remember where we are right now
        local pool, poolFresh = {}, {}
        local cursor = ""
        for _ = 1, HOP_PAGES do
            local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
            if cursor ~= "" then url = url .. "&cursor=" .. HttpService:UrlEncode(cursor) end
            local ok, res = pcall(function() return httpRequest({ Url = url, Method = "GET" }) end)
            if not ok or not res or not res.Body then break end
            local ok2, body = pcall(function() return HttpService:JSONDecode(res.Body) end)
            if not ok2 or typeof(body) ~= "table" then break end
            for _, sv in ipairs(body.data or {}) do
                local playing, maxP = tonumber(sv.playing), tonumber(sv.maxPlayers)
                if sv.id ~= game.JobId and playing and maxP
                    and playing >= HOP_MIN_PLAYERS and playing <= HOP_MAX_PLAYERS and playing < maxP then
                    if not seen[sv.id] then poolFresh[#poolFresh + 1] = sv.id end
                end
            end
            cursor = body.nextPageCursor or ""
            if cursor == "" then break end
            task.wait(0.4)
        end
        local use = poolFresh -- never fall back to a server we already visited
        if #use == 0 then return nil, "no new server with " .. HOP_MIN_PLAYERS .. "-" .. HOP_MAX_PLAYERS .. " players found" end
        return use[math.random(1, #use)]
    end
    local function doHop()
        if hop.busy then return end
        hop.busy = true
        local id, why = pickHopServer()
        if id then
            local seen = hopSeen()
            seen[game.JobId] = true
            seen[id] = true
            Library.Notify("info", "Server hop", "Hopping to a random server...")
            pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, id, LocalPlayer) end)
            task.wait(20) -- still here after 20s: the teleport failed
            hop.nextAt = os.clock() + HOP_RETRY
        else
            Library.Notify("warning", "Server hop", tostring(why) .. " - trying again in " .. HOP_RETRY .. "s")
            hop.nextAt = os.clock() + HOP_RETRY
        end
        hop.busy = false
    end
    task.spawn(function()
        while true do
            task.wait(1)
            if hop.on then
                local left = hop.nextAt - os.clock()
                if left <= 0 and not hop.busy then
                    task.spawn(doHop)
                end
                setText(lblHop, hop.busy and "Server hop: looking for a server..."
                    or string.format("Server hop: next in %d:%02d", math.floor(math.max(left, 0) / 60), math.floor(math.max(left, 0) % 60)))
            else
                setText(lblHop, "Server hop: off")
            end
        end
    end)

    -- Auto Regen / Strength / Health / Speed: raise the stat every 0.8s (needs level 5)
    task.spawn(function()
        while true do
            for stat, on in pairs(K.skill) do
                if on then
                    local kj = myKaiju()
                    if kj and (levelOf(LocalPlayer) or 0) >= 5 then
                        fireRemote("FireServer", "UpdateStat", kj, stat, "Increase")
                    end
                end
            end
            pwait(0.8)
        end
    end)

    -- ===== blacklist helpers =====
    local blDrop
    local function blacklistNames()
        local list = {}
        for name, on in pairs(blacklist) do if on then list[#list + 1] = name end end
        table.sort(list)
        return list
    end
    local function refreshBlacklist()
        local names = blacklistNames()
        setText(lblBlack, #names > 0 and ("Blacklisted: " .. table.concat(names, ", ")) or "No blacklisted kaijus")
        if blDrop then
            K.removePick = names[1]
            blDrop:Refresh(#names > 0 and names or { "(empty)" }, names[1] or "(empty)")
        end
    end

    -- ===== player list (target dropdown) =====
    local playerDrop
    local function refreshPlayers()
        if not playerDrop then return end
        local opts = { AUTO_TARGET }
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then opts[#opts + 1] = p.Name end
        end
        local cur = AUTO_TARGET
        if K.selectedName ~= "" and Players:FindFirstChild(K.selectedName) then cur = K.selectedName end
        playerDrop:Refresh(opts, cur)
    end

    -- ===== events =====
    local function kickIfAdmin(p)
        if p ~= LocalPlayer and p and ADMIN_IDS[p.UserId] == true then
            LocalPlayer:Kick("uh oh admin joined")
            return true
        end
        return false
    end
    Players.PlayerAdded:Connect(function(p)
        if kickIfAdmin(p) then return end
        task.wait(0.2)
        refreshPlayers()
        updateText()
    end)
    Players.PlayerRemoving:Connect(function()
        task.wait(0.2)
        if K.target and not Players:FindFirstChild(K.target.Name) then K.target = nil end
        refreshPlayers()
        updateText()
    end)
    for _, p in ipairs(Players:GetPlayers()) do
        if kickIfAdmin(p) then break end
    end
    task.spawn(function()
        local live = Workspace:WaitForChild("Live", 30)
        if not live then return end
        live.ChildAdded:Connect(function(child)
            if child.Name ~= LocalPlayer.Name then return end
            task.wait(0.2)
            -- the new character starts with default attributes: put the chosen fly / speed / noclip back
            if K.noclip then setNoclipParts(true) end
            local inst = ensureAttrs(liveChar())
            if inst then inst:SetAttribute("IsFlying", K.fly) end
            if K.speedOn then enforceSpeed() end
        end)
    end)
    local function hookDeath(char)
        local hum = char:WaitForChild("Humanoid", 10)
        if hum then hum.Died:Connect(onDied) end
    end
    LocalPlayer.CharacterAdded:Connect(function(char)
        hookDeath(char)
        task.wait(1)
        updateText()
    end)
    if LocalPlayer.Character then task.spawn(hookDeath, LocalPlayer.Character) end
    task.spawn(function()
        while true do
            if K.enabled and K.sessionStart > 0 then updateSessionText() end
            pwait(1)
        end
    end)

    -- ============================================================
    --  TABS
    -- ============================================================
    -- ----- Autofarm -----
    local AF = Window:CreateTab("Autofarm")
    AF:CreateSection("Autofarm")
    lblStatus = AF:CreateLabel("Status: OFFLINE  -  turn Autofarm on to begin")
    AF:CreateToggle({
        Name = "Autofarm",
        CurrentValue = false,
        Callback = function(v) setAutofarm(v) end,
    })
    AF:CreateDropdown({
        Name = "Farm mode",
        Options = FARM_MODES,
        CurrentOption = FARM_MODES[1],
        Callback = function(v)
            K.mode = v
            K.target = nil
            if K.enabled then startModeLoops() end
            updateText()
        end,
    })
    AF:CreateToggle({
        Name = "Infinite health (Player autofarm)",
        CurrentValue = false,
        Callback = function(v)
            K.infiniteHealth = v
            setState("InfiniteHealth", v)
            if K.enabled then startPlayerRespawnLoop() end
        end,
    })
    AF:CreateSection("Target priority")
    AF:CreateDropdown({
        Name = "Priority",
        Options = PRIORITIES,
        CurrentOption = PRIORITIES[1],
        Callback = function(v)
            K.priority = v
            K.target = nil
            updateText()
        end,
    })
    AF:CreateSection("Targeting")
    AF:CreateInput({
        Name = "Studs under (-1 = right under the target)",
        CurrentValue = "-1",
        Placeholder = "-1",
        Callback = function(v) K.studsUnder = tonumber(v) or -1 end,
    })
    playerDrop = AF:CreateDropdown({
        Name = "Select player",
        Options = { AUTO_TARGET },
        CurrentOption = AUTO_TARGET,
        Callback = function(v)
            if v == AUTO_TARGET then
                K.selectedName = ""
            else
                K.ignored[v] = nil
                K.respawnTries[v] = nil
                K.selectedName = v
                K.target = Players:FindFirstChild(v)
            end
            updateText()
        end,
    })
    AF:CreateButton({ Name = "Refresh player list", Callback = function() refreshPlayers() end })
    AF:CreateSection("Session")
    lblCells = AF:CreateLabel("Cells earned: 0")
    lblSession = AF:CreateLabel("Session time: 0s")
    lblTarget = AF:CreateLabel("Target: -")
    AF:CreateLabel("Functions by studly (Kaiju Hub)")

    -- ----- Misc -----
    local MS = Window:CreateTab("Misc")
    MS:CreateSection("Auto stats (needs level 5)")
    for _, stat in ipairs({ "Regen", "Strength", "Health", "Speed" }) do
        MS:CreateToggle({
            Name = "Auto " .. stat:upper(),
            CurrentValue = false,
            Callback = function(v)
                K.skill[stat] = v
                setState("Auto" .. stat, v)
            end,
        })
    end
    MS:CreateSection("Movement")
    MS:CreateToggle({ Name = "Fly", CurrentValue = false, Callback = function(v) setFly(v) end })
    MS:CreateToggle({ Name = "Noclip", CurrentValue = false, Callback = function(v) setNoclip(v) end })
    MS:CreateToggle({ Name = "Server speed", CurrentValue = false, Callback = function(v) setServerSpeed(v) end })
    MS:CreateSlider({
        Name = "Server speed value",
        Range = { SPEED_MIN, SPEED_MAX },
        Increment = 1,
        CurrentValue = SPEED_DEFAULT,
        Callback = function(v)
            K.speedValue = math.clamp(math.floor((tonumber(v) or SPEED_DEFAULT) + 0.5), SPEED_MIN, SPEED_MAX)
            local inst = ensureAttrs(liveChar())
            if inst then inst:SetAttribute("ServerSpeed", K.speedValue) end
            if K.speedOn then enforceSpeed() end
        end,
    })
    MS:CreateSection("Extras")
    MS:CreateButton({ Name = "Buy all FREE kaijus", Callback = function()
        buyFreeKaijus()
        Library.Notify("success", "Kaijus", "Sent a buy request for every free kaiju")
    end })
    MS:CreateButton({ Name = "Commit suicide", Callback = function() fireRemote("CombatRemote", "Death") end })
    MS:CreateButton({ Name = "Low server finder", Callback = function()
        Library.Notify("info", "Servers", "Searching for a server...")
        local id = findServerId()
        if id then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, id, LocalPlayer)
        else
            Library.Notify("warning", "Servers", "No server found (or your executor has no request function)")
        end
    end })

    MS:CreateSection("Server hop")
    lblHop = MS:CreateLabel("Server hop: off")
    MS:CreateToggle({
        Name = "Auto server hop (every 5 min)",
        CurrentValue = false,
        Callback = function(v)
            hop.on = v
            setState("ServerHop", v)
            if v then hop.nextAt = os.clock() + HOP_EVERY end
        end,
    })
    MS:CreateButton({ Name = "Hop now (random, 14-17 players)", Callback = function()
        task.spawn(doHop)
    end })

    -- ----- Blacklist -----
    local BL = Window:CreateTab("Blacklist")
    BL:CreateSection("Blacklisted kaijus (never targeted)")
    lblBlack = BL:CreateLabel("")
    BL:CreateInput({
        Name = "Kaiju name",
        CurrentValue = "",
        Placeholder = "Kaiju name...",
        Callback = function(v) K.newKaiju = tostring(v or "") end,
    })
    BL:CreateButton({ Name = "Add to blacklist", Callback = function()
        local name = K.newKaiju:gsub("^%s+", ""):gsub("%s+$", "")
        if name == "" then return end
        blacklist[name] = true
        K.newKaiju = ""
        refreshBlacklist()
        Library.Notify("success", "Blacklist", name .. " added")
    end })
    blDrop = BL:CreateDropdown({
        Name = "Remove a kaiju",
        Options = { "(empty)" },
        CurrentOption = "(empty)",
        Callback = function(v) K.removePick = v end,
    })
    BL:CreateButton({ Name = "Remove selected kaiju", Callback = function()
        if K.removePick and blacklist[K.removePick] then
            local n = K.removePick
            blacklist[n] = nil
            refreshBlacklist()
            Library.Notify("info", "Blacklist", n .. " removed")
        end
    end })

    refreshBlacklist()
    refreshPlayers()
    updateText()


    local VTab = Window:CreateTab("Visuals")
    local vBody = Win.Shell.pages and Win.Shell.pages.Visuals and Win.Shell.pages.Visuals.body
    local before = {}
    if vBody then
        for _, c in ipairs(vBody:GetChildren()) do before[c] = true end
    end
    VTab:CreateSection("Auto Hide")
    if vBody then
        for _, c in ipairs(vBody:GetChildren()) do
            if not before[c] and c:IsA("GuiObject") then
                c.LayoutOrder = -10 -- show this section at the top of the Visuals page
            end
        end
    end
    local guiLoadedAt = tick()
    VTab:CreateToggle({
        Name = "Auto Hide GUI",
        CurrentValue = false,
        Callback = function(Value)
            getgenv().HyzeAutoHide = Value
            -- only counts as "joining" when it switches on during startup (saved state coming back);
            -- flipping it by hand later does not hide the window under your finger
            if Value and tick() - guiLoadedAt < 8 then
                task.delay(math.max(0, 3 - (tick() - guiLoadedAt)), function()
                    if getgenv().HyzeAutoHide then
                        Win:SetShown(false)
                    end
                end)
            end
        end,
    })
    VTab:CreateSection("Debug")
    VTab:CreateToggle({
        Name = "Spawn Debug (on-screen log)",
        CurrentValue = false,
        Callback = function(Value)
            getgenv().HyzeDebugOn = Value
            dbg.setOverlay(Value)
            if not Value then pcall(function() local g = (type(gethui) == "function" and gethui() or game:GetService("CoreGui")):FindFirstChild("HyzeDebug"); if g then g:Destroy() end end) end
        end,
    })

    -- ===== Virtual phone fix: solid colors instead of UIGradient =====
    -- The menu paints almost everything as a WHITE frame with a UIGradient on top (window body, switched-on toggles,
    -- slider fills, accent bars, icons). Some virtual phones / cloud phones cannot draw UIGradient, so those parts
    -- come out see-through or colorless. This switch gives every such part its middle gradient color as a plain
    -- color and turns the gradient off. It also follows later changes (toggling a switch, changing the color theme).
    -- Turning it off again puts the gradients back.
    VTab:CreateSection("Virtual phone")
    local solid = { on = false, conns = {}, items = {} }
    local function solidColorAt(g, t)
        local ks = g.Color.Keypoints
        if #ks == 0 then return Color3.new(1, 1, 1) end
        if t <= ks[1].Time then return ks[1].Value end
        for i = 1, #ks - 1 do
            local a, b = ks[i], ks[i + 1]
            if t <= b.Time then
                return a.Value:Lerp(b.Value, (t - a.Time) / math.max(b.Time - a.Time, 1e-6))
            end
        end
        return ks[#ks].Value
    end
    local function solidProp(p)
        if p:IsA("UIStroke") then return "Color" end
        if p:IsA("TextLabel") or p:IsA("TextButton") or p:IsA("TextBox") then return "TextColor3" end
        if p:IsA("ImageLabel") or p:IsA("ImageButton") then return "ImageColor3" end
        return "BackgroundColor3"
    end
    local function solidHandle(g)
        if not solid.on then return end
        local p = g.Parent
        if not (p and (p:IsA("GuiObject") or p:IsA("UIStroke"))) or solid.items[g] then return end
        local prop = solidProp(p)
        local item = { g = g, p = p, prop = prop, intent = g.Enabled, busy = false }
        solid.items[g] = item
        local function paint()
            if item.busy or not solid.on then return end
            item.busy = true
            if item.intent then
                pcall(function()
                    p[prop] = solidColorAt(g, 0.5)
                    g.Enabled = false
                end)
            end
            item.busy = false
        end
        table.insert(solid.conns, g:GetPropertyChangedSignal("Enabled"):Connect(function()
            if item.busy then return end
            item.intent = g.Enabled -- what the menu wants: gradient on / off
            paint()
        end))
        table.insert(solid.conns, g:GetPropertyChangedSignal("Color"):Connect(paint))
        table.insert(solid.conns, p:GetPropertyChangedSignal(prop):Connect(function()
            if item.busy or not item.intent then return end
            if p[prop] == Color3.new(1, 1, 1) then paint() end -- the menu painted it white for the gradient
        end))
        paint()
    end
    local function solidSet(on, gui)
        if on == solid.on then return end
        solid.on = on
        if on then
            if not gui then solid.on = false return end
            for _, d in ipairs(gui:GetDescendants()) do
                if d:IsA("UIGradient") then solidHandle(d) end
            end
            table.insert(solid.conns, gui.DescendantAdded:Connect(function(d)
                if d:IsA("UIGradient") then task.defer(solidHandle, d) end
            end))
        else
            for _, c in ipairs(solid.conns) do c:Disconnect() end
            solid.conns = {}
            for _, it in pairs(solid.items) do
                pcall(function()
                    if it.g.Parent then
                        if it.intent then it.p[it.prop] = Color3.new(1, 1, 1) end
                        it.g.Enabled = it.intent
                    end
                end)
            end
            solid.items = {}
        end
    end
    local function hubGui()
        local g = (Win and Win.Gui) or (Window and Window.Gui)
        if g and g.Parent then return g end
        local roots = {}
        if type(gethui) == "function" then pcall(function() roots[#roots + 1] = gethui() end) end
        roots[#roots + 1] = game:GetService("CoreGui")
        roots[#roots + 1] = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
        for _, root in ipairs(roots) do
            for _, c in ipairs(root:GetChildren()) do
                if c:IsA("ScreenGui") and c:FindFirstChild("HLMenu", true) then return c end
            end
        end
        return nil
    end
    VTab:CreateToggle({
        Name = "Solid colors (fix see-through window / colorless toggles)",
        CurrentValue = false,
        Callback = function(Value)
            solidSet(Value, hubGui())
            pcall(function() Library.Notify("info", "Hyze", Value and "Solid colors on" or "Solid colors off") end)
        end,
    })

    VTab:CreateSection("Crash Debug")
    VTab:CreateToggle({
        Name = "Live debug overlay (show everything)",
        CurrentValue = false,
        Callback = function(Value) dbg.setOverlay(Value) end,
    })
    VTab:CreateSection("Nearby Scanner")
    VTab:CreateButton({ Name = "Set scan location (where I stand now)", Callback = function()
        local root = getPart()
        if not root then Library.Notify("warning", "Scanner", "No character") return end
        dbg.scan.center = root.Position
        local txt = string.format("%d, %d, %d", math.floor(root.Position.X + 0.5), math.floor(root.Position.Y + 0.5), math.floor(root.Position.Z + 0.5))
        if type(setclipboard) == "function" then pcall(setclipboard, txt) end
        dlog("scan location set: " .. txt)
        Library.Notify("success", "Scanner", "Location set: " .. txt .. " (copied)")
    end })
    VTab:CreateButton({ Name = "Use my live position (follow me)", Callback = function()
        dbg.scan.center = nil
        Library.Notify("info", "Scanner", "Scanning around you")
    end })
    VTab:CreateSlider({
        Name = "Scan radius (studs)",
        Range = { 50, 1000 }, Increment = 50, CurrentValue = 300,
        Callback = function(v) dbg.scan.radius = v end,
    })
    VTab:CreateToggle({
        Name = "Nearby scanner (every 1s)",
        CurrentValue = false,
        Callback = function(Value)
            dbg.scan.on = Value
            if not Value then dbg.scan.text = "scan: off" end
            if Value then dbg.setOverlay(true) end
        end,
    })
    VTab:CreateSection("Debug Logs")
    VTab:CreateButton({ Name = "View current log", Callback = function() dbg.showText("Current session log", dbg.fullLog()) end })
    VTab:CreateButton({ Name = "View previous session (last crash)", Callback = function()
        local s = dbg.readPrevious(1)
        dbg.showText("Previous session log", s or "No previous log yet (or your executor has no file access).")
    end })
    VTab:CreateButton({ Name = "View 2 sessions ago", Callback = function()
        local s = dbg.readPrevious(2)
        dbg.showText("Log from 2 sessions ago", s or "No log.")
    end })
    VTab:CreateButton({ Name = "Copy current log", Callback = function()
        if type(setclipboard) == "function" then setclipboard(dbg.fullLog()) Library.Notify("success", "Debug", "Log copied")
        else Library.Notify("warning", "Debug", "No clipboard in your executor") end
    end })

    end, __tb)
    if not ok then
        __report("Kaiju", err)
    end
end

Library.Notify("info", "Hyze", "Tap the GUI button to hide/show")
print("[Hyze] GUI loaded")