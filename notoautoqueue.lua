local args = {...}
local Lobby = args[1]
local key = args[2]
local inst = args[3]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

while not Workspace:GetAttribute("ChallengesLoaded") do task.wait() end
task.wait(1)
local lobby = ReplicatedStorage.MakeLobby:InvokeServer(
    Lobby.Mission,
    Lobby.Difficulty,
    3,
    Lobby.Public and "EVERYONE" or "FRIENDS ONLY",
    Lobby.Tactic,
    true,
    false,
    Lobby.Size,
    false,
    false,
    {},
    true
)
while task.wait(0.4) do
    local canstart = true
    if not lobby or not lobby:IsDescendantOf(game) then return end
    local validplayersinlobby = {}
    for _, v1 in pairs(lobby.Members:GetChildren()) do
        if not v1.Value then continue end
        if table.find(Lobby.Players, v1.Value.Name) or table.find(Lobby.Players, v1.Value.UserId) then
            if not v1.Ready.Value and v1.Value ~= LocalPlayer then
                canstart = false
            end
            table.insert(validplayersinlobby, v1.Value.Name)
            table.insert(validplayersinlobby, v1.Value.UserId)
        else
            ReplicatedStorage.KickFromLobby:FireServer(lobby, tonumber(v1.Name))
        end
    end
    for _, v1 in pairs(Lobby.Players) do
        if not table.find(validplayersinlobby, v1) then
            canstart = false
        end
    end
    if key and inst and getgenv()[key] ~= inst then
        ReplicatedStorage.LeaveLobby:FireServer(lobby)
        return
    end
    if canstart then
        break
    end
end
ReplicatedStorage.StartGame:FireServer(lobby)
