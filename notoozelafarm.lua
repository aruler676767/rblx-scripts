-- made by arealer
-- took like 3 days to make btw but it works well enough
-- time for one run if successfully completed: ~4-7 mins

if not game:IsLoaded() then game.Loaded:Wait() end

getgenv, firesignal, replicatesignal, hookmetamethod, getnamecallmethod, getscriptthread, readfile, queueonteleport = getgenv, firesignal, replicatesignal, hookmetamethod, getnamecallmethod, getscriptthread, readfile, queueonteleport

local devtesting = false
if not devtesting and not getgenv().gl5ry98t47tut983wyg and queueonteleport then
    getgenv().gl5ry98t47tut983wyg = true
    local success, content = pcall(readfile, "notoozelafarm.lua")
    queueonteleport(success and content or [[loadstring(game:HttpGet("https://raw.githubusercontent.com/aruler676767/rblx-scripts/refs/heads/main/notoozelafarm.lua", true))()]])
end

if game.PlaceId ~= 6537140247 then return end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local Rep_RS_Package = ReplicatedStorage:WaitForChild("RS_Package")
local Rep_Remotes = Rep_RS_Package:WaitForChild("Remotes")
local Rep_Assets = Rep_RS_Package:WaitForChild("Assets")
local StartInteraction = Rep_Remotes:WaitForChild("StartInteraction")
local CompleteInteraction = Rep_Remotes:WaitForChild("CompleteInteraction")
local CancelInteraction = Rep_Remotes:WaitForChild("CancelInteraction")
local UseSimonSays = Rep_Remotes:WaitForChild("UseSimonSays")
local VoteReset = Rep_Remotes:WaitForChild("VoteReset")
local UseKeypad = Rep_Remotes:WaitForChild("UseKeypad")
local SnitchRemote = Rep_Remotes:WaitForChild("SnitchRemote")
local LookVector = Rep_Remotes:WaitForChild("LookVector")
local PlayerReady = Rep_Remotes:WaitForChild("PlayerReady")
local Rep_AssetRemotes = Rep_Assets:WaitForChild("Remotes")
local HitObject = Rep_AssetRemotes:WaitForChild("HitObject")
local MaskOn = Rep_AssetRemotes:WaitForChild("MaskOn")

local __inst = getgenv().ozelafarminst or 0
__inst += 1
getgenv().ozelafarminst = __inst
local running = true
--if true then return print("quick exited") end

local function getRoot(char)
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char.PrimaryPart)
end

if not LocalPlayer:GetAttribute("CharacterSpawned") then
    task.wait(2)
    PlayerReady:FireServer("Class 1", true)
end
while not LocalPlayer:GetAttribute("CharacterSpawned") do task.wait() end
if getgenv().ozelafarminst ~= __inst then return end

pcall(function()
    local snitcher = LocalPlayer.PlayerScripts.SPS_Package.SnitchSystem
    local success = false
    if getscriptthread then
        local thread = getscriptthread(snitcher)
        if thread then coroutine.close(thread); success = true end
    end; if hookmetamethod then
        if getgenv().ghr384gou3t848t0958 then hookmetamethod(game, "__namcall", getgenv().ghr384gou3t848t0958) end
        local old; old = hookmetamethod(game, "__namecall", function(...)
            local namecall = getnamecallmethod()
            if namecall == "FireServer" and (...) == SnitchRemote then
                return
            end
            return old(...)
        end)
        getgenv().ghr384gou3t848t0958 = old
        success = true
    end
    if not success then
        warn("couldnt disable snitch system")
    end
end)

local lchar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
task.wait(3)
local lroot = getRoot(lchar)
local origin = lroot.CFrame
local tplocation = origin

task.spawn(function()
    while getgenv().ozelafarminst == __inst and running and task.wait() do
        lroot.CFrame = tplocation * CFrame.Angles(0, 0, math.rad(180)) + Vector3.new(0, (math.random() - 0.5) / 4, 0)
        lroot.Velocity = Vector3.zero
        if math.random(1, 50) == 1 then
            LookVector:FireServer(lroot.Position + (Vector3.new(math.random() * 2 - 1, math.random() * 2 - 1, math.random() * 2 - 1) * 120))
        end
        if ReplicatedStorage.PointOfNoReturn:GetAttribute("Active") then
            VoteReset:FireServer()
            return
        end
    end
end)

local __tp_offset = CFrame.new(0, 0, 3)
local function settppos(pos, dontuseoffset)
    local offset = (not pos or dontuseoffset) and CFrame.identity or __tp_offset
    pos = pos or lroot.CFrame + Vector3.new(0, -10, 0)
    if typeof(pos) == "Vector3" then
        tplocation = CFrame.new(pos) * offset
    elseif typeof(pos) == "vector" then
        tplocation = CFrame.new(pos.x, pos.y, pos.z) * offset
    elseif typeof(pos) == "CFrame" then
        tplocation = pos * offset
    end
    task.wait(1.4)
end

local function getCurrentWeapon()
    local weapon = lchar:FindFirstChildWhichIsA("Tool")
    if not weapon or not weapon:GetAttribute("Damage") then return end
    return weapon
end

local function damageTarget(target)
    local hitpart = target:FindFirstChild("Head") or target:FindFirstChild("Torso")
    local weapon = getCurrentWeapon()
    local isMelee = weapon:FindFirstChild("Melee") and true or false
    if isMelee then
        HitObject:FireServer(weapon, hitpart, true, nil, nil, nil, weapon:GetAttribute("Damage"))
    else
        HitObject:FireServer(weapon, hitpart, false, nil, nil, hitpart.Position, weapon:GetAttribute("Damage"), hitpart.Position)
    end
end

local function keypress(isPressed, keycode)
    VirtualInputManager:SendKeyEvent(isPressed, keycode, false, nil)
end
local function keytap(keycode)
    keypress(true, keycode)
    keypress(false, keycode)
end

local __interacting = false
local function interact(prompt: ProximityPrompt, waittime, async, ignoredistance)
    waittime = (waittime or 0) + 0.4
    while __interacting do task.wait() end
    __interacting = true
    StartInteraction:FireServer(prompt)

    local running = true
    if not ignoredistance then
        task.spawn(function()
            while running and RunService.PreRender:Wait() do
                local lchar = LocalPlayer.Character
                local lroot = getRoot(lchar)
                local promptposition = nil
                if prompt.Parent then
                    if prompt.Parent:IsA("BasePart") then
                        promptposition = prompt.Parent.Position
                    end
                end
                if promptposition and (promptposition - lroot.Position).Magnitude >= prompt.MaxActivationDistance + 2 then
                    CancelInteraction:FireServer(prompt)
                    running = false
                end
            end
        end)
    end

    local function trigger()
        if not running then
            __interacting = false
            error("interaction failed")
        end
        CompleteInteraction:FireServer(prompt)
        task.wait(0.1)
        running = false
        __interacting = false
    end
    if async then
        task.delay(waittime, trigger)
    else
        task.wait(waittime)
        trigger()
    end
end

local globals = {}

local function rfid()
    local cardreader = Workspace.prop_stadium_cardReader
    do
        if cardreader:FindFirstChild("rfid_faceplate") then
            local _part = cardreader.rfid_faceplate.Backplate
            settppos(_part.CFrame * CFrame.new(-3, 0, 0), true)
            interact(_part.ProximityPrompt, 0.5)

            settppos()
            task.wait(7)
        end
    end

    local needed_serial = cardreader.main.serial.SurfaceGui.TextLabel.Text

    local possible_colors = {}
    for _, v1 in pairs(Workspace.Blueprints.prop_stadium_blueprintTableRNG.prop_stadium_blueprint:GetChildren()) do
        if not tonumber(v1.Name) then continue end
        local serial = v1.serial.SurfaceGui.TextLabel.Text
        local colors = ""
        for _, v2 in pairs(v1.colors:GetChildren()) do
            colors ..= v2.SurfaceGui.TextLabel.Text
        end
        print("possible color", serial, colors)
        possible_colors[serial] = colors
    end

    local color_boxes = {}
    for _, v1 in pairs(Workspace:GetChildren()) do
        if v1.name ~= "colorBoxRNG" then continue end
        local serial = v1.serial.SurfaceGui.TextLabel.Text
        print("matched color", serial, possible_colors[serial])
        color_boxes[serial] = {possible_colors[serial], v1}
    end

    local needed_color, needed_colorbox = table.unpack(color_boxes[needed_serial])
    print(needed_serial, needed_color, needed_colorbox)

    UseSimonSays:FireServer(needed_colorbox, needed_color)
    task.wait(3)

    if LocalPlayer.PlayerGui.SG_Package.MainGui.Objective.text_objectiveMain.Text == "Gain access to the underground level" then
        error("rfid reader couldnt open")
    end
end

local function admin1()
    local fail = false
    local function file(v1)
        local prompt = v1:FindFirstChildWhichIsA("ProximityPrompt", true)
        if v1.Name == "_" then fail = true; return end
        if not prompt then return end
        settppos(prompt.Parent.CFrame * CFrame.new(0, -7, 0), true)
        task.wait(1)
        interact(prompt, 1)
        task.wait(2)
    end
    local loops = 0
    while not fail and task.wait() do
        for _, v1 in pairs(Workspace.PhoneFiles2:GetChildren()) do
            file(v1)
        end

        print(loops)
        if loops >= 2 then
            warn("possible files collection fail")
            break
        end
    end
    task.wait(1)
end

local function admin2()
    local pos1 = { Vector3.new(52.7, 51, -136.5) }
    local pos2 = { Vector3.new(46, 51, -123) }
    settppos(pos2[1], true)
    local manager
    local posindex
    local managerunmovingtick = 0
    local managermoving = true
    while not manager and task.wait() do
        if managermoving then
            managerunmovingtick = tick()
        end
        
        for _, v1 in pairs(Workspace.Citizens:GetChildren()) do
            if not v1:FindFirstChild("HasUSB") then continue end

            managermoving = not (v1:FindFirstChild("Stationary") and v1.Stationary.Value and v1.Humanoid.TargetPoint == Vector3.zero and v1.Humanoid.WalkToPoint == Vector3.zero)

            local passedpos
            for i, p in pairs(pos1) do
                if (v1.PrimaryPart.Position - p).Magnitude <= 5 then passedpos = i end
            end
            if not passedpos and not (v1.Name == "CitizenHostage" or v1.Name == "CitizenTied") then continue end

            manager = v1
            posindex = passedpos
            break
        end

        if not managermoving and tick() - managerunmovingtick >= 10 then
            error("manager is not moving")
        end
    end

    task.wait(1)
    
    settppos(manager.Torso.CFrame)
    task.wait(0.4)

    if manager.Name == "Citizen" then
        interact(manager.Torso.ProximityPrompt)
        task.wait(2)
    end
    if manager.Name == "CitizenHostage" then
        interact(manager.Torso.ProximityPrompt, 2)
        task.wait(1)
    end
    if manager.Name == "CitizenTied" then
        interact(manager.Torso.ProximityPrompt, 1)
        task.wait(1)
    end

    settppos(pos2[posindex])
    interact(manager.Torso.ProximityPrompt, 1, nil, true)
    task.wait(5)
    
    local usb = Workspace.Map.USB.Hitbox
    settppos(usb.CFrame * CFrame.new(0, -5, 0), true)
    interact(usb.ProximityPrompt)
end

local function admin3()
    local computer = Workspace.UseUSBComputer
    settppos(computer.Keyboard.CFrame + Vector3.new(0, -5, 0), true)
    task.wait(2)
    interact(computer.Keyboard.ProximityPrompt, 0.5)
    task.wait(2)
    settppos()
end

local function keycard()
    local keycard = Workspace.Map.KeyCard.InteractionPart
    settppos(keycard.CFrame * CFrame.new(0, -5, 0), true)
    task.wait(5)
    interact(keycard.ProximityPrompt, 0.01)
    task.wait(5)

    local keycardkeypad = Workspace.KeycardKeypad.Hitbox
    settppos(keycardkeypad.CFrame)
    task.wait(5)
    interact(keycardkeypad.ProximityPrompt, 0.25)

    task.wait(1)
    UseKeypad:FireServer(globals.usbcode, keycardkeypad)

    task.wait(10)

    local guitarcasebutton = Workspace.prop_stadium_caseOpener.stadiumDramaticButton.Main
    settppos(guitarcasebutton.Position + Vector3.new(0, -5, 0), true)
    interact(guitarcasebutton.ProximityPrompt)
    task.wait(2)
    settppos()
end

local function pulleyitems()
    local loops = 0
    while task.wait() do
        local found = 0
        for _, v1 in pairs(LocalPlayer.PlayerGui.SG_Package.MainGui.PlayerStats.LocalPlayerStats.info_items.MissionEquipment:GetChildren()) do
            if v1.Name == "Hook" or v1.Name == "Rope" then
                found += 1
            end
        end
        if found == 2 then
            break
        end
        local function process(v1)
            task.wait(0.5)
            local prompt = v1.PrimaryPart.ProximityPrompt
            settppos(v1.PrimaryPart.CFrame + Vector3.new(0, -7, 0), true)
            task.wait(1)
            interact(prompt, 1, nil, true)
            task.wait(0.5)
        end
        for _, v1 in pairs(Workspace.mapEntities.missionItems.Hooks:GetChildren()) do
            process(v1)
        end
        for _, v1 in pairs(Workspace.mapEntities.missionItems.Ropes:GetChildren()) do
            process(v1)
        end

        print(loops)
        if loops >= 2 then
            warn("possible pulley collection fail")
            break
        end
    end
    task.wait(1)
    settppos()
end

local function assemblemekanism()
    local door = Workspace.Map.ObjectivePickDoor1.Door.DoorOpenPart
    settppos(door.CFrame * CFrame.new(0, -5, 0), true)
    task.wait(1)
    interact(door.ProximityPrompt, 5)
    task.wait(2)

    settppos(Workspace.mapEntities.missionItems.missionItem_laptopHack.Part.CFrame * CFrame.new(0, -5, 0) * CFrame.Angles(0, 0, math.rad(-180)), true)

    local computer = Workspace.mapEntities.missionItems:WaitForChild("StadiumHackLaptop").Keyboard
    settppos(computer.CFrame * CFrame.new(0, -5, 0) * CFrame.Angles(0, 0, math.rad(-180)), true)
    interact(computer.ProximityPrompt, 5)
    task.wait(2)

    if Workspace:FindFirstChild("AssemblePulleyRope") then
        local assemble = Workspace.AssemblePulleyRope.Hitbox
        settppos(assemble.CFrame * CFrame.new(0, 0, -2), true)
        interact(assemble.ProximityPrompt, 3)
        task.wait(1)
    end
    if Workspace:FindFirstChild("AssemblePulleyHook") then
        local assemble = Workspace.AssemblePulleyHook.Hitbox
        settppos(assemble.CFrame * CFrame.new(0, 0, -2), true)
        interact(assemble.ProximityPrompt, 3)
        task.wait(1)
    end

    local activate = Workspace.PulleyLever.Hitbox
    settppos(activate.CFrame * CFrame.new(0, 0, -2), true)
    interact(activate.ProximityPrompt, 1)
    task.wait(1)
    settppos()
    settppos()
    settppos()
end

local function leave()
    task.wait(30)
    local guitar = Workspace.Pulley.GoldGuitar.missionItem_goldGuitar
    settppos(guitar.CFrame * CFrame.new(0, -11, 0), true)
    interact(guitar.ProximityPrompt, 1)
    task.wait(1)
    settppos(origin, true)

    local function checklocker(locker)
        if not locker or not locker:FindFirstChild("Highlight_[]") then return end

        local hitbox = locker.Hitbox
        
        settppos(hitbox.CFrame, true)
        local playerclosetimer = 0
        while not lchar:FindFirstChild("HAS COSTUME") and task.wait() do
            local playersnotclose = false
            for _, v1 in pairs(Players:GetPlayers()) do
                if LocalPlayer:DistanceFromCharacter(v1.Character.PrimaryPart.Position) <= 14 then
                    playersnotclose = true
                end
            end
            if not playersnotclose and playerclosetimer == 0 then
                playerclosetimer = tick()
            elseif not playersnotclose and playerclosetimer ~= 0 and tick() - playerclosetimer >= 10 then
                VoteReset:FireServer()
            end
        end
    end
    while not lchar:FindFirstChild("HAS COSTUME") and task.wait() do
        checklocker(Workspace:WaitForChild("GuardLocker1"))
        checklocker(Workspace:WaitForChild("GuardLocker2"))
    end

    settppos(Workspace.BagSecuredArea.FloorPart.Position + Vector3.new(0, 3, 0), true)
    while not Workspace:GetAttribute("EscapeTimer") or Workspace:GetAttribute("EscapeTimer") >= 0.01 do task.wait() end
end

print("running")

-- auto mask
if not lchar:FindFirstChild("Mask ON") then
    task.wait(3)
    keytap(Enum.KeyCode.G)
    task.wait(2)
    if not lchar:FindFirstChild("Mask ON") then
        MaskOn:FireServer(true, "Secondary")
        MaskOn:FireServer()
        task.wait(2)
    end
end

xpcall(function()
    --// do actions and stuff \\--
    task.wait(10)
    rfid()
    task.wait(25)

    admin1()
    admin2()
    task.wait(5)

    admin3()
    task.wait(20)
    globals.usbcode = (Workspace:FindFirstChild("UseUSBComputer") or Workspace:FindFirstChild("UsedUSBComputer")).Screen.SurfaceGui.TextLabel.Text
    if not tonumber(globals.usbcode) then error("usb code was not found") end
    keycard()
    task.wait(20)
    pulleyitems()
    task.wait(8)

    assemblemekanism()
    leave()
    --\\ do actions and stuff //--]]
end, function(...)
    pcall(warn, ...)
end)

task.wait(1)
CancelInteraction:FireServer()

settppos(origin, true)
print("ended")
print("globals:")
table.foreach(globals, print)
VoteReset:FireServer()
running = false
