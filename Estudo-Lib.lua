local Lib = {}
Lib._debugMode = false
Lib._autoScroll = true

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "DebugConsole"
gui.ResetOnSpawn = false
gui.Parent = game:GetService("CoreGui")

local frame = Instance.new("Frame")
frame.Name = "ConsoleFrame"
frame.Size = UDim2.new(0, 500, 0, 250)
frame.Position = UDim2.new(0.5, -250, 0.1, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local topBar = Instance.new("Frame", frame)
topBar.Size = UDim2.new(1, 0, 0, 30)
topBar.BackgroundTransparency = 1

local title = Instance.new("TextLabel", topBar)
title.Size = UDim2.new(1, -90, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Debug Console"
title.TextColor3 = Color3.fromRGB(180, 0, 255)
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left

local autoScrollBtn = Instance.new("TextButton", frame)
autoScrollBtn.Size = UDim2.new(0, 120, 0, 25)
autoScrollBtn.Position = UDim2.new(1, -130, 1, -30)
autoScrollBtn.Text = "Auto Scroll: ON"
autoScrollBtn.TextSize = 14
autoScrollBtn.Font = Enum.Font.Gotham
autoScrollBtn.BackgroundColor3 = Color3.fromRGB(40, 0, 70)
autoScrollBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", autoScrollBtn).CornerRadius = UDim.new(0, 4)
autoScrollBtn.ZIndex = 5

local resizeHandle = Instance.new("Frame", frame)
resizeHandle.Size = UDim2.new(0, 20, 0, 20)
resizeHandle.Position = UDim2.new(1, -20, 1, -20)
resizeHandle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
resizeHandle.BorderSizePixel = 0
resizeHandle.ZIndex = 10
resizeHandle.Name = "ResizeHandle"
Instance.new("UICorner", resizeHandle).CornerRadius = UDim.new(0, 4)

local draggingResize = false
local UserInputService = game:GetService("UserInputService")

resizeHandle.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingResize = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingResize = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if draggingResize and input.UserInputType == Enum.UserInputType.MouseMovement then
		local mousePos = input.Position
		local guiInset = game:GetService("GuiService"):GetGuiInset().Y

		local topLeft = frame.AbsolutePosition
		local newWidth = math.clamp(mousePos.X - topLeft.X, 200, 1000)
		local newHeight = math.clamp(mousePos.Y - topLeft.Y - guiInset, 100, 800)

		frame.Size = UDim2.new(0, newWidth, 0, newHeight)
	end
end)


Lib._autoScrollBtn = autoScrollBtn

autoScrollBtn.MouseButton1Click:Connect(function()
    Lib._autoScroll = not Lib._autoScroll
    autoScrollBtn.Text = "Auto Scroll: " .. (Lib._autoScroll and "ON" or "OFF")
end)


-- Buttons
local function createButton(text, position, callback)
    local btn = Instance.new("TextButton", topBar)
    btn.Size = UDim2.new(0, 25, 0, 25)
    btn.Position = position
    btn.Text = text
    btn.TextSize = 16
    btn.Font = Enum.Font.GothamBold
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local minimizedSize = UDim2.new(0, 500, 0, 30)
local normalSize = UDim2.new(0, 500, 0, 250)

local minimizeBtn = createButton("-", UDim2.new(1, -75, 0, 2), function()
    Lib._minimized = not Lib._minimized

    if Lib._minimized then
        frame.Size = minimizedSize
        Lib._scroll.Visible = false
        Lib._autoScrollBtn.Visible = false
        Lib._clearBtn.Visible = false
        minimizeBtn.Text = "+"
    else
        frame.Size = normalSize
        Lib._scroll.Visible = true
        Lib._autoScrollBtn.Visible = true
        Lib._clearBtn.Visible = true
        minimizeBtn.Text = "-"
    end
end)


local clearBtn = createButton("🧹", UDim2.new(1, -50, 0, 2), function()
    for _, child in ipairs(Lib._logFrame:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end
end)


Lib._clearBtn = clearBtn

local closeBtn = createButton("X", UDim2.new(1, -25, 0, 2), function()
    gui:Destroy()
end)

-- Scrolling log
local scroll = Instance.new("ScrollingFrame", frame)
scroll.Position = UDim2.new(0, 0, 0, 30)
scroll.Size = UDim2.new(1, 0, 1, -30)
scroll.BackgroundTransparency = 1
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.ScrollBarThickness = 6
scroll.BorderSizePixel = 0
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Visible = true

Lib._scroll = scroll

Lib._logFrame = scroll

local list = Instance.new("UIListLayout", scroll)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Padding = UDim.new(0, 2)

list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    if Lib._autoScroll then
        task.defer(function()
            scroll.CanvasPosition = Vector2.new(0, scroll.AbsoluteCanvasSize.Y)
        end)
    end
end)


-- Utils
local function getTime()
    local t = os.date("*t")
    return string.format("%02d:%02d:%02d", t.hour, t.min, t.sec)
end

local function addLine(tag, color, message)
    if not Lib._debugMode then return end

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = string.format("[%s] - (%s) - %s", tag, getTime(), message)
    label.TextColor3 = color
    label.TextSize = 14
    label.Font = Enum.Font.Code
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.LayoutOrder = os.time()
    label.Parent = Lib._logFrame
end



-- API

function Lib.SetAutoScroll(state)
    Lib._autoScroll = state and true or false
end

function Lib.DebugMode(state)
    Lib._debugMode = state and true or false
    frame.Visible = Lib._debugMode
end

function Lib.DebugPrint(msg)
    addLine("DEBUG", Color3.fromRGB(255, 255, 0), msg)
end

function Lib.DebugSucess(msg)
    addLine("SUCESS", Color3.fromRGB(0, 255, 0), msg)
end

function Lib.DebugError(msg)
    addLine("ERROR", Color3.fromRGB(255, 50, 50), msg)
end

return Lib
