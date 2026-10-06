local Workspace = game:GetService("Workspace")

local Vertices = {
	{1, 1, -1},   --v1 - top front right
	{1, -1, -1},  --v2 - bottom front right
	{-1, -1, -1}, --v3 - bottom front left
	{-1, 1, -1},  --v4 - top front left
	
	{1, 1, 1},    --v5 - top back right
	{1, -1, 1},   --v6 - bottom back right
	{-1, -1, 1},  --v7 - bottom back left
	{-1, 1, 1}    --v8 - top back left
}

local WedgeVertices = {
	{0.5, -1, -1},--v3 - bottom front left
	{0.5, -1, 1}, --v7 - bottom back left
	{0.5, 1, 1}   --v8 - top back left
}

local function getModelPartPoints(model)
    local mpoints = {}
	for _, v1 in pairs(model:GetChildren()) do
        if not v1:IsA("BasePart") then continue end
        local verts = Vertices
        if v1:IsA("WedgePart") or (v1:IsA("BasePart") and v1.Shape == Enum.PartType.Wedge) then verts = WedgeVertices end

        local ppoints = {}
        local v1half = v1.Size / 2
        for i, vec in pairs(verts) do
            local point = (v1.CFrame * CFrame.new(v1half.X * vec[1], v1half.Y * vec[2], v1half.Z * vec[3])).Position
            table.insert(ppoints, point)
        end
        mpoints[v1] = ppoints
    end
    return mpoints
end

local function getModelBounds(mpoints, model)
    local topfrontleft = Vector3.new(-math.huge, -math.huge, -math.huge)
    local bottombackright = Vector3.new(math.huge, math.huge, math.huge)
	for v1, ppoints in pairs(mpoints) do
	    for _, point in pairs(ppoints) do
            local x1, y1, z1 = topfrontleft.X, topfrontleft.Y, topfrontleft.Z
            local p1changed = false
            if x1 < point.X then
                x1 = point.X
                p1changed = true
            end; if y1 < point.Y then
                y1 = point.Y
                p1changed = true
            end; if z1 < point.Z then
                z1 = point.Z
                p1changed = true
            end
            if p1changed then
                topfrontleft = Vector3.new(x1, y1, z1)
            end

            local x2, y2, z2 = bottombackright.X, bottombackright.Y, bottombackright.Z
            local p2changed = false
            if x2 > point.X then
                x2 = point.X
                p2changed = true
            end; if y2 > point.Y then
                y2 = point.Y
                p2changed = true
            end; if z2 > point.Z then
                z2 = point.Z
                p2changed = true
            end
            if p2changed then
                bottombackright = Vector3.new(x2, y2, z2)
            end
        end
    end
    if topfrontleft.X == -math.huge or topfrontleft.Y == -math.huge or topfrontleft.Z == -math.huge then
        return nil
    end
    if bottombackright.X == math.huge or bottombackright.Y == math.huge or bottombackright.Z == math.huge then
        return nil
    end
    return topfrontleft, bottombackright
end

local regions = {}
for _, v1 in pairs(Workspace.MapZones:GetChildren()) do
	local highestcast = -math.huge
    local mpoints = getModelPartPoints(v1)
	local topfrontleft, bottombackright = getModelBounds(mpoints, v1)
	for v2, points in pairs(mpoints) do
        for _, v3 in pairs(v2:GetChildren()) do
            if v3.Name == "HHHHH" then v3:Destroy() end
        end
        for _, point in pairs(points) do
            local direction = Vector3.new(0, 50, 0)
            local ray = Workspace:Raycast(point, direction)
            if not ray or not ray.Instance then
                ray = Workspace:Spherecast(point, 0.5, direction)
            end
            if not ray or not ray.Instance then
                print("failed", v2, v2:GetFullName())
                local dbg = Instance.new("Part", v2) -- dihhbg
                dbg.Name = "HHHHH"
                dbg.Anchored = true
                dbg.Size = Vector3.new(0.5, 0.5, 0.5)
                dbg.Position = point
                Instance.new("Highlight", dbg)
                continue
            end

            if ray.Position.Y >= highestcast then
                highestcast = ray.Position.Y
            end
        end
	end
	if highestcast == -math.huge then
		highestcast = math.huge
	end
	topfrontleft = Vector3.new(topfrontleft.X, highestcast, topfrontleft.Z)
    regions[v1.Name] = {topfrontleft, bottombackright}
end

print(regions)
