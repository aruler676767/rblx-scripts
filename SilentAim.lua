-- init
if not game:IsLoaded() then 
    game.Loaded:Wait()
end

if not syn or not protectgui then
    getgenv().protectgui = function() end
end

local SilentAimSettings = {
    Enabled = false,
    
    ClassName = "Universal Silent Aim - Averiias, Stefanuk12, xaxa",
    ToggleKey = "LeftControl",
    ToggleGUIKey = "Return",
    GUIVisible = true,
    EnableWatermark = false,
    
    TeamCheck = false,
    VisibleCheck = false, 
    TargetPart = "HumanoidRootPart",
    SilentAimMethod = "Raycast",
    
    FOVRadius = 1000,
    FOVVisible = false,
    FOVColor = {54, 57, 241},
    ShowSilentAimTarget = false,
    MouseVisualizeColor = {54, 57, 241},
    Targetline = false,
    TargetlineVisualizeColor = {54, 57, 241},
    TargetlineWidth = false,
    
    MouseHitPrediction = false,
    MouseHitPredictionAmount = 0.165,
    HitChance = 100
}

-- variables
getgenv().SilentAimSettings = SilentAimSettings
local MainFileName = "UniversalSilentAim"
local  FileToSave = ""

local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local GetChildren = game.GetChildren
local GetPlayers = Players.GetPlayers
local WorldToScreen = Camera.WorldToScreenPoint
local WorldToViewportPoint = Camera.WorldToViewportPoint
local GetPartsObscuringTarget = Camera.GetPartsObscuringTarget
local FindFirstChild = game.FindFirstChild
local RenderStepped = RunService.RenderStepped
local GuiInset = GuiService.GetGuiInset
local GetMouseLocation = UserInputService.GetMouseLocation

local resume = coroutine.resume 
local create = coroutine.create

local ValidTargetParts = {"Head", "HumanoidRootPart"}
local PredictionAmount = 0.165

local CurrentHit = nil

local mouse_box = Drawing.new("Square")
mouse_box.Visible = false
mouse_box.ZIndex = 999
mouse_box.Color = Color3.fromRGB(unpack(SilentAimSettings.MouseVisualizeColor))
mouse_box.Thickness = 10
mouse_box.Position = Vector2.new(-1000, -1000)
mouse_box.Size = Vector2.new(10, 10)
mouse_box.Filled = true

local mouse_line = Drawing.new("Line")
mouse_line.Visible = false
mouse_line.ZIndex = 999
mouse_line.Color = Color3.fromRGB(unpack(SilentAimSettings.TargetlineVisualizeColor))
mouse_line.Thickness = 0.5

local fov_circle = Drawing.new("Circle")
fov_circle.Thickness = 1
fov_circle.NumSides = 100
fov_circle.Radius = 180
fov_circle.Filled = false
fov_circle.Visible = false
fov_circle.ZIndex = 999
fov_circle.Transparency = 1
fov_circle.Color = Color3.fromRGB(unpack(SilentAimSettings.FOVColor))

local ExpectedArguments = {
    FindPartOnRayWithIgnoreList = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Ray", "table", "boolean", "boolean"
        }
    },
    FindPartOnRayWithWhitelist = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Ray", "table", "boolean"
        }
    },
    FindPartOnRay = {
        ArgCountRequired = 2,
        Args = {
            "Instance", "Ray", "Instance", "boolean", "boolean"
        }
    },
    Raycast = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Vector3", "Vector3", "RaycastParams"
        }
    }
}
local ToggleKeybind = {
    Type = "KeyPicker",
    Value = SilentAimSettings.ToggleGUIKey
}

function CalculateChance(Percentage)
    -- // Floor the percentage
    Percentage = math.floor(Percentage)

    -- // Get the chance
    local chance = math.floor(Random.new().NextNumber(Random.new(), 0, 1) * 100) / 100

    -- // Return
    return chance <= Percentage / 100
end


--[[file handling]] do 
    if not isfolder(MainFileName) then 
        makefolder(MainFileName);
    end
    
    if not isfolder(string.format("%s/%s", MainFileName, tostring(game.PlaceId))) then 
        makefolder(string.format("%s/%s", MainFileName, tostring(game.PlaceId)))
    end
end

local Files = listfiles(string.format("%s/%s", MainFileName, tostring(game.PlaceId)))

-- functions
local function GetFiles() -- credits to the linoria lib for this function, listfiles returns the files full path and its annoying
local out = {}
Files = listfiles(string.format("%s/%s", MainFileName, tostring(game.PlaceId)))
for i = 1, #Files do
local file = Files[i]
if file:sub(-4) == '.lua' then
-- i hate this but it has to be done ...

local pos = file:find('.lua', 1, true)
local start = pos

local char = file:sub(pos, pos)
while char ~= '/' and char ~= '\\' and char ~= '' do
pos = pos - 1
char = file:sub(pos, pos)
end

if char == '/' or char == '\\' then
table.insert(out, file:sub(pos + 1, start - 1))
end
end
end

return out
end

local function UpdateFile(FileName)
    assert(FileName or FileName == "string", "oopsies");
    writefile(string.format("%s/%s/%s.lua", MainFileName, tostring(game.PlaceId), FileName), HttpService:JSONEncode(SilentAimSettings))
end

local function LoadFile(FileName)
    assert(FileName or FileName == "string", "oopsies");
    
    local File = string.format("%s/%s/%s.lua", MainFileName, tostring(game.PlaceId), FileName)
    local ConfigData = HttpService:JSONDecode(readfile(File))
    table.clear(SilentAimSettings)
    for Index, Value in next, ConfigData do
        SilentAimSettings[Index] = Value
    end
end

local function getPositionOnScreen(Vector)
    local Vec3, OnScreen = WorldToScreen(Camera, Vector)
    return Vector2.new(Vec3.X, Vec3.Y), OnScreen
end

local function ValidateArguments(Args, RayMethod)
    local Matches = 0
    if #Args < RayMethod.ArgCountRequired then
        return false
    end
    for Pos, Argument in next, Args do
        if typeof(Argument) == RayMethod.Args[Pos] then
            Matches = Matches + 1
        end
    end
    return Matches >= RayMethod.ArgCountRequired
end

local function getDirection(Origin, Position)
    return (Position - Origin).Unit * 1000
end

local function getMousePosition()
    return GetMouseLocation(UserInputService)
end

local function IsPlayerVisible(Player)
    local PlayerCharacter = Player.Character
    local LocalPlayerCharacter = LocalPlayer.Character
    
    if not (PlayerCharacter or LocalPlayerCharacter) then return end 
    
    local PlayerRoot = FindFirstChild(PlayerCharacter, Options.TargetPart.Value) or FindFirstChild(PlayerCharacter, "HumanoidRootPart")
    
    if not PlayerRoot then return end 
    
    local CastPoints, IgnoreList = {PlayerRoot.Position, LocalPlayerCharacter, PlayerCharacter}, {LocalPlayerCharacter, PlayerCharacter}
    local ObscuringObjects = #GetPartsObscuringTarget(Camera, CastPoints, IgnoreList)
    
    return ((ObscuringObjects == 0 and true) or (ObscuringObjects > 0 and false))
end

local function getClosestPlayer()
    if not Options.TargetPart.Value then return end
    local Closest
    local DistanceToMouse
    for _, Player in next, GetPlayers(Players) do
        if Player == LocalPlayer then continue end
        if getgenv().Toggles.TeamCheck.Value and Player.Team == LocalPlayer.Team then continue end

        local Character = Player.Character
        if not Character then continue end
        
        if getgenv().Toggles.VisibleCheck.Value and not IsPlayerVisible(Player) then continue end

        local HumanoidRootPart = FindFirstChild(Character, "HumanoidRootPart")
        local Humanoid = FindFirstChild(Character, "Humanoid")
        if not HumanoidRootPart or not Humanoid or Humanoid and Humanoid.Health <= 0 then continue end

        local ScreenPosition, OnScreen = getPositionOnScreen(HumanoidRootPart.Position)
        if not OnScreen then continue end

        local Distance = (getMousePosition() - ScreenPosition).Magnitude
        if Distance <= (DistanceToMouse or Options.Radius.Value or 2000) then
            Closest = ((Options.TargetPart.Value == "Random" and FindFirstChild(Character, ValidTargetParts[math.random(1, #ValidTargetParts)])) or FindFirstChild(Character, Options.TargetPart.Value) or HumanoidRootPart)
            DistanceToMouse = Distance
        end
    end
    CurrentHit = Closest
    return Closest
end

-- ui creating & handling
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
Library:SetWatermark("github.com/Averiias")
Library:SetWatermarkVisibility(SilentAimSettings.EnableWatermark)
Library.ToggleKeybind = ToggleKeybind

local Window = Library:CreateWindow("Universal Silent Aim, by Averiias, xaxa, and Stefanuk12")
if not SilentAimSettings.GUIVisible then
    Library:Toggle()
end
local GeneralTab = Window:AddTab("General")
local MainBOX = GeneralTab:AddLeftTabbox("Main") do
    local Main = MainBOX:AddTab("Main")
    
    Main:AddToggle("aim_Enabled", {Text = "Enabled"}):AddKeyPicker("aim_Enabled_KeyPicker", {Default = SilentAimSettings.ToggleKey, SyncToggleState = true, Mode = "Toggle", Text = "Enabled", NoUI = false});
    SilentAimSettings.ToggleKey = {SilentAimSettings.ToggleKey, Options.aim_Enabled_KeyPicker.Mode}
    getgenv().Toggles.aim_Enabled:OnChanged(function()
        SilentAimSettings.Enabled = getgenv().Toggles.aim_Enabled.Value
        
        mouse_box.Visible = SilentAimSettings.Enabled
    end)
    Options.aim_Enabled_KeyPicker:OnChanged(function()
        SilentAimSettings.ToggleKey[1] = Options.aim_Enabled_KeyPicker.Value
    end)
    
    Main:AddToggle("TeamCheck", {Text = "Team Check", Default = SilentAimSettings.TeamCheck}):OnChanged(function()
        SilentAimSettings.TeamCheck = getgenv().Toggles.TeamCheck.Value
    end)
    Main:AddToggle("VisibleCheck", {Text = "Visible Check", Default = SilentAimSettings.VisibleCheck}):OnChanged(function()
        SilentAimSettings.VisibleCheck = getgenv().Toggles.VisibleCheck.Value
    end)
    Main:AddDropdown("TargetPart", {Text = "Target Part", Default = SilentAimSettings.TargetPart, Values = {"Head", "HumanoidRootPart", "Random"}}):OnChanged(function()
        SilentAimSettings.TargetPart = Options.TargetPart.Value
    end)
    Main:AddDropdown("Method", {Text = "Silent Aim Method", Default = SilentAimSettings.SilentAimMethod, Values = {
        "Raycast","FindPartOnRay",
        "FindPartOnRayWithWhitelist",
        "FindPartOnRayWithIgnoreList",
        "Mouse.Hit/Target"
    }}):OnChanged(function() 
        SilentAimSettings.SilentAimMethod = Options.Method.Value 
    end)
    Main:AddSlider('HitChance', {
        Text = 'Hit chance',
        Default = 100,
        Min = 0,
        Max = 100,
        Rounding = 1,
    
        Compact = false,
    })
    Options.HitChance:OnChanged(function()
        SilentAimSettings.HitChance = Options.HitChance.Value
    end)
end

local MiscellaneousBOX = GeneralTab:AddLeftTabbox("Miscellaneous")
local FieldOfViewBOX = GeneralTab:AddLeftTabbox("Field Of View") do
    local Main = FieldOfViewBOX:AddTab("Visuals")
    
    Main:AddToggle("FOVVisible", {Text = "Show FOV Circle"}):AddColorPicker("FOVColor", {Default = Color3.fromRGB(unpack(SilentAimSettings.FOVColor))})
    getgenv().Toggles.FOVVisible:OnChanged(function()
        fov_circle.Visible = getgenv().Toggles.FOVVisible.Value
        SilentAimSettings.FOVVisible = getgenv().Toggles.FOVVisible.Value
    end)
    Options.FOVColor:OnChanged(function()
        fov_circle.Color = Options.FOVColor.Value
        SilentAimSettings.FOVColor = {Options.FOVColor.Value.R * 255, Options.FOVColor.Value.G * 255, Options.FOVColor.Value.B * 255}
    end)
    Main:AddSlider("Radius", {Text = "FOV Circle Radius", Min = 0, Max = 1000, Default = 130, Rounding = 0})
    Options.Radius:OnChanged(function()
        fov_circle.Radius = Options.Radius.Value
        SilentAimSettings.FOVRadius = Options.Radius.Value
    end)
    Main:AddToggle("MousePosition", {Text = "Show Silent Aim Target"}):AddColorPicker("MouseVisualizeColor", {Default = Color3.fromRGB(unpack(SilentAimSettings.MouseVisualizeColor))})
    getgenv().Toggles.MousePosition:OnChanged(function()
        SilentAimSettings.ShowSilentAimTarget = getgenv().Toggles.MousePosition.Value
        mouse_box.Visible = getgenv().Toggles.MousePosition.Value
    end)
    Options.MouseVisualizeColor:OnChanged(function()
        mouse_box.Color = Options.MouseVisualizeColor.Value
        SilentAimSettings.MouseVisualizeColor = {Options.MouseVisualizeColor.Value.R * 255, Options.MouseVisualizeColor.Value.G * 255, Options.MouseVisualizeColor.Value.B * 255}
    end)
    Main:AddToggle("Targetline", {Text = "Targetline"}):AddColorPicker("TargetLineVisualizeColor", {Default = Color3.fromRGB(unpack(SilentAimSettings.TargetlineVisualizeColor))})
    getgenv().Toggles.Targetline:OnChanged(function()
        mouse_line.Visible = getgenv().Toggles.Targetline.Value
        SilentAimSettings.Targetline = getgenv().Toggles.Targetline.Value
    end)
    Options.TargetLineVisualizeColor:OnChanged(function()
        mouse_line.Color = Options.TargetLineVisualizeColor.Value
        SilentAimSettings.TargetlineVisualizeColor = {Options.MouseVisualizeColor.Value.R * 255, Options.MouseVisualizeColor.Value.G * 255, Options.MouseVisualizeColor.Value.B * 255}
    end)
    Main:AddSlider("TargetlineWidth", {Text = "Targetline Width", Min = 0, Max = 3, Default = 0.5, Rounding = 3})
    Options.TargetlineWidth:OnChanged(function()
        mouse_line.Thickness = Options.TargetlineWidth.Value
        SilentAimSettings.TargetlineWidth = Options.TargetlineWidth.Value
    end)
    local PredictionTab = MiscellaneousBOX:AddTab("Prediction")
    PredictionTab:AddToggle("Prediction", {Text = "Mouse.Hit/Target Prediction"})
    getgenv().Toggles.Prediction:OnChanged(function()
        SilentAimSettings.MouseHitPrediction = getgenv().Toggles.Prediction.Value
    end)
    PredictionTab:AddSlider("Amount", {Text = "Prediction Amount", Min = 0.165, Max = 1, Default = 0.165, Rounding = 3})
    Options.Amount:OnChanged(function()
        PredictionAmount = Options.Amount.Value
        SilentAimSettings.MouseHitPredictionAmount = Options.Amount.Value
    end)
end

local config1, config2
local CreateConfigurationBOX = GeneralTab:AddRightTabbox("Configurations") do 
    local Main = CreateConfigurationBOX:AddTab("Configurations")
    
    Main:AddInput("CreateConfigTextBox", {Default = "", Numeric = false, Finished = false, Text = "Create Configuration to Create", Tooltip = "Creates a configuration file containing settings you can save and load", Placeholder = "File Name here"}):OnChanged(function()
        if Options.CreateConfigTextBox.Value and string.len(Options.CreateConfigTextBox.Value) ~= "" then 
            FileToSave = Options.CreateConfigTextBox.Value
        end
    end)
    
    Main:AddButton("Create Configuration File", function()
        if FileToSave ~= "" or FileToSave ~= nil then 
            UpdateFile(FileToSave)
            config1.Values = GetFiles()
            config2.Values = config1.Values
            config1:SetValues()
            config2:SetValues()
        end
    end)

    config1 = Main:AddDropdown("SaveConfigurationDropdown", {Values = GetFiles() or {}, Text = "Choose Configuration to Save", AllowNull = true})
    Main:AddButton("Save Configuration", function()
        if Options.SaveConfigurationDropdown.Value then 
            UpdateFile(Options.SaveConfigurationDropdown.Value)
        end
    end)

    config2 = Main:AddDropdown("LoadConfigurationDropdown", {Values = GetFiles() or {}, Text = "Choose Configuration to Load", AllowNull = true})
    Main:AddButton("Load Configuration", function()
        if table.find(GetFiles() or {}, Options.LoadConfigurationDropdown.Value) then
            LoadFile(Options.LoadConfigurationDropdown.Value)

            print(SilentAimSettings.FOVVisible, SilentAimSettings.ShowSilentAimTarget, SilentAimSettings.Targetline)
            
            getgenv().Toggles.aim_Enabled:SetValue(SilentAimSettings.Enabled)
            Options.aim_Enabled_KeyPicker:SetValue(SilentAimSettings.ToggleKey)
            getgenv().Toggles.TeamCheck:SetValue(SilentAimSettings.TeamCheck)
            getgenv().Toggles.VisibleCheck:SetValue(SilentAimSettings.VisibleCheck)
            Options.TargetPart:SetValue(SilentAimSettings.TargetPart)
            Options.Method:SetValue(SilentAimSettings.SilentAimMethod)
            getgenv().Toggles.FOVVisible:SetValue(SilentAimSettings.FOVVisible)
            Options.FOVColor:SetValueRGB(Color3.fromRGB(unpack(SilentAimSettings.FOVColor)))
            Options.Radius:SetValue(SilentAimSettings.FOVRadius)
            getgenv().Toggles.MousePosition:SetValue(SilentAimSettings.ShowSilentAimTarget)
            Options.MouseVisualizeColor:SetValueRGB(Color3.fromRGB(unpack(SilentAimSettings.MouseVisualizeColor)))
            getgenv().Toggles.Targetline:SetValue(SilentAimSettings.Targetline)
            Options.TargetLineVisualizeColor:SetValueRGB(Color3.fromRGB(unpack(SilentAimSettings.TargetlineVisualizeColor)))
            Options.TargetlineWidth:SetValue(SilentAimSettings.TargetlineWidth)
            getgenv().Toggles.Prediction:SetValue(SilentAimSettings.MouseHitPrediction)
            Options.Amount:SetValue(SilentAimSettings.MouseHitPredictionAmount)
            Options.HitChance:SetValue(SilentAimSettings.HitChance)
            ToggleKeybind.Value = SilentAimSettings.ToggleGUIKey
            Library.ToggleKeybind = ToggleKeybind
            getgenv().Toggles.watermark_enabled:SetValue(SilentAimSettings.EnableWatermark)
        end
    end)

    Main:AddButton("Update Configurations", function()
        config1.Values = GetFiles()
        config2.Values = config1.Values
        config1:SetValues()
        config2:SetValues()
    end)
end

local MenuSettings = GeneralTab:AddRightTabbox("Menu Settings") do 
    local Main = MenuSettings:AddTab("Menu Settings")
    
    Main:AddToggle("menu_bind", {Default = SilentAimSettings.GUIVisible, Text = "Menu Bind"}):AddKeyPicker("menu_bind_KeyPicker", {Default = SilentAimSettings.ToggleGUIKey, SyncToggleState = true, Mode = "Toggle", Text = "Menu Bind", NoUI = false});
    Options.menu_bind_KeyPicker:OnChanged(function()
        ToggleKeybind.Value = Options.menu_bind_KeyPicker.Value
        Library.ToggleKeybind = ToggleKeybind
    end)
    getgenv().Toggles.menu_bind:OnChanged(function()
        Library:Toggle()
    end)

    Main:AddToggle("watermark_enabled", {Text = "Enable Watermark", Default = SilentAimSettings.EnableWatermark}):OnChanged(function()
        SilentAimSettings.EnableWatermark = getgenv().Toggles.watermark_enabled.Value

        Library:SetWatermarkVisibility(SilentAimSettings.EnableWatermark)
    end)
end

--resume(create(function()
    RenderStepped:Connect(function()
        local Closest = getClosestPlayer()
        local Root = (Closest and Closest.Parent and Closest.Parent.PrimaryPart) or Closest
        local RootToViewportPoint, IsOnScreen
        local MousePos = getMousePosition()
        local MouseX, MouseY = MousePos.X, MousePos.Y--= Mouse.X, Mouse.Y + 35

        if Closest then 
            RootToViewportPoint, IsOnScreen = WorldToViewportPoint(Camera, Root.Position);
            -- using PrimaryPart instead because if your Target Part is "Random" it will flicker the square between the Target's Head and HumanoidRootPart (its annoying)
        end

        if getgenv().Toggles.MousePosition.Value and getgenv().Toggles.aim_Enabled.Value then
            if Closest then 
                mouse_box.Visible = IsOnScreen
                mouse_box.Position = Vector2.new(RootToViewportPoint.X, RootToViewportPoint.Y) + Vector2.new(-mouse_box.Size.X/2, -mouse_box.Size.Y/2)
            else 
                mouse_box.Visible = false
                mouse_box.Position = Vector2.new(-100000000, -100000000)
            end
        else
            mouse_box.Visible = false
            mouse_box.Position = Vector2.new(-100000000, -100000000)
        end
        if getgenv().Toggles.Targetline.Value and getgenv().Toggles.aim_Enabled.Value then
            if Closest then 
                mouse_line.Visible = IsOnScreen
                mouse_line.To = Vector2.new(RootToViewportPoint.X, RootToViewportPoint.Y)
                mouse_line.From = MousePos
            else
                mouse_line.Visible = false
            end
        else
            mouse_line.Visible = false
        end
        
        if getgenv().Toggles.FOVVisible.Value then 
            fov_circle.Visible = getgenv().Toggles.FOVVisible.Value
            fov_circle.Color = Options.FOVColor.Value
            fov_circle.Position = MousePos
        else
            fov_circle.Visible = false
        end
    end)
--end))

-- hooks
local oldNamecall = nil
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
    local Method = getnamecallmethod()
    local Arguments = {...}
    local self = Arguments[1]
    if getgenv().Toggles.aim_Enabled.Value and self == workspace and not checkcaller() and CalculateChance(SilentAimSettings.HitChance) == true then
        if Method == "FindPartOnRayWithIgnoreList" and Options.Method.Value == Method then
            if ValidateArguments(Arguments, ExpectedArguments[Method]) then
                local A_Ray = Arguments[2]

                local HitPart = CurrentHit
                if HitPart then
                    local Origin = A_Ray.Origin
                    local Direction = getDirection(Origin, HitPart.Position)
                    Arguments[2] = Ray.new(Origin, Direction)

                    return oldNamecall(unpack(Arguments))
                end
            end
        elseif Method == "FindPartOnRayWithWhitelist" and Options.Method.Value == Method then
            if ValidateArguments(Arguments, ExpectedArguments[Method]) then
                local A_Ray = Arguments[2]

                local HitPart = CurrentHit
                if HitPart then
                    local Origin = A_Ray.Origin
                    local Direction = getDirection(Origin, HitPart.Position)
                    Arguments[2] = Ray.new(Origin, Direction)

                    return oldNamecall(unpack(Arguments))
                end
            end
        elseif (Method == "FindPartOnRay" or Method == "findPartOnRay") and Options.Method.Value:lower() == Method:lower() then
            if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRay) then
                local A_Ray = Arguments[2]

                local HitPart = CurrentHit
                if HitPart then
                    local Origin = A_Ray.Origin
                    local Direction = getDirection(Origin, HitPart.Position)
                    Arguments[2] = Ray.new(Origin, Direction)

                    return oldNamecall(unpack(Arguments))
                end
            end
        elseif Method == "Raycast" and Options.Method.Value == Method then
            if ValidateArguments(Arguments, ExpectedArguments[Method]) then
                local A_Origin = Arguments[2]

                local HitPart = CurrentHit
                if HitPart then
                    Arguments[3] = getDirection(A_Origin, HitPart.Position)

                    return oldNamecall(unpack(Arguments))
                end
            end
        end
    end
    return oldNamecall(...)
end))

local oldIndex = nil 
oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, Index)
    if self == Mouse and not checkcaller() and getgenv().Toggles.aim_Enabled.Value and Options.Method.Value == "Mouse.Hit/Target" and CurrentHit then
        local HitPart = CurrentHit
        
        if Index == "Target" or Index == "target" then
            return HitPart
        elseif Index == "Hit" or Index == "hit" then
            return ((getgenv().Toggles.Prediction.Value and (HitPart.CFrame + (HitPart.Velocity * PredictionAmount))) or (not getgenv().Toggles.Prediction.Value and HitPart.CFrame))
        elseif Index == "X" or Index == "x" then
            return self.X 
        elseif Index == "Y" or Index == "y" then
            return self.Y 
        elseif Index == "UnitRay" then
            return Ray.new(self.Origin, (self.Hit - self.Origin).Unit)
        end

        return oldIndex(self, Index)
    end

    return oldIndex(self, Index)
end))
