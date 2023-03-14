--[[
    PenTool.lua
    eliphant
    Created on 03/13/2023 @ 02:56

    Description:
        No description provided.

    Documentation:
        No documentation provided.
--]]

--= Root =--
local PenTool = { }

--= Roblox Services =--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--= Dependencies =--

--= Object References =--

--= Constants =--

--= Variables =--

--= Internal Functions =--
local function CatmullRom(p0, p1, p2, p3)
	return p1, 0.5*(p2 - p0), p0 - 2.5*p1 + 2*p2 - 0.5*p3, 1.5*(p1 - p2) + 0.5*(p3 - p0)
end

--= API Functions =--
function PenTool:UpdateCurve()
    local CurvesFolder = workspace.Curves
    local CurvePaths = CurvesFolder:GetChildren()

    for _, CurvePath in ipairs(CurvePaths) do
        local Curve = CurvePath.Path
        local ControlPoints = self._ControlPoints[CurvePath]

        if ControlPoints and #ControlPoints >= 4 then
            local Points = {}

            -- Add first curve segment
            local p0, p1, p2, p3 = ControlPoints[1].Position, ControlPoints[1].Position, ControlPoints[2].Position, ControlPoints[3].Position
            local a, b, c, d = CatmullRom(p0, p1, p2, p3)
            for t = 0, 1, 0.01 do
                local Point = a + b * t + c * t^2 + d * t^3
                table.insert(Points, Point)
            end

            -- Add middle curve segments
            for i = 2, #ControlPoints - 3 do
                p0, p1, p2, p3 = ControlPoints[i-1].Position, ControlPoints[i].Position, ControlPoints[i+1].Position, ControlPoints[i+2].Position
                a, b, c, d = CatmullRom(p0, p1, p2, p3)
                for t = 0, 1, 0.01 do
                    local Point = a + b * t + c * t^2 + d * t^3
                    table.insert(Points, Point)
                end
            end

            -- Add second to last curve segment
            p0, p1, p2, p3 = ControlPoints[#ControlPoints-3].Position, ControlPoints[#ControlPoints-2].Position, ControlPoints[#ControlPoints-1].Position, ControlPoints[#ControlPoints].Position
            a, b, c, d = CatmullRom(p0, p1, p2, p3)
            for t = 0, 1, 0.01 do
                local Point = a + b * t + c * t^2 + d * t^3
                table.insert(Points, Point)
            end

            -- Add last curve segment
            p0, p1, p2, p3 = ControlPoints[#ControlPoints-2].Position, ControlPoints[#ControlPoints-1].Position, ControlPoints[#ControlPoints].Position, ControlPoints[#ControlPoints].Position
            a, b, c, d = CatmullRom(p0, p1, p2, p3)
            for t = 0, 1, 0.01 do
                local Point = a + b * t + c * t^2 + d * t^3
                table.insert(Points, Point)
            end

            Curve:ClearAllChildren()

            local StartPoint = Points[1]
            for i = 2, #Points do
                local Point = Points[i]
                local Line = Instance.new("Part")
                Line.Anchored = true
                Line.CanCollide = false
                Line.BrickColor = BrickColor.new("Toothpaste")
                Line.Material = Enum.Material.Neon
                Line.Size = Vector3.new(0.1, 0.1, (StartPoint - Point).Magnitude)
                Line.CFrame = CFrame.lookAt(StartPoint, Point) * CFrame.new(0, 0, -(StartPoint - Point).Magnitude / 2)
                Line.Parent = Curve
                Line.Shape = Enum.PartType.Block
                StartPoint = Point
            end
        end
    end
end

--= Initializers =--
function PenTool:Init()
    self._ControlPoints = {}
    self._lastPositions = {}

    local CurvesFolder = workspace.Curves
    local CurvePaths = CurvesFolder:GetChildren()

    table.sort(CurvePaths, function(a, b)
        return tonumber(a.Name) < tonumber(b.Name)
    end)

    for _, CurvePath in ipairs(CurvePaths) do
        self._ControlPoints[CurvePath] = {}
        local ControlPoints = CurvePath:GetChildren()
        table.sort(ControlPoints, function(a, b)
            local aNum = tonumber(a.Name)
            local bNum = tonumber(b.Name)
            if aNum and bNum then
                return aNum < bNum
            elseif aNum == nil and bNum == nil then
                return a.Name < b.Name
            elseif aNum then
                return true
            else
                return false
            end
        end)
        for _, ControlPoint in ipairs(ControlPoints) do
            print(ControlPoint.Name)
            if ControlPoint:IsA("BasePart") then
                table.insert(self._ControlPoints[CurvePath], ControlPoint)
                self._lastPositions[ControlPoint] = ControlPoint.Position
                RunService.Heartbeat:Connect(function()
                    local CurrentPosition = ControlPoint.Position
                    local Difference = self._lastPositions[ControlPoint] - CurrentPosition
                    self._lastPositions[ControlPoint] = CurrentPosition
                    if Difference.Magnitude > 0.1 then
                        self:UpdateCurve()
                    end
                end)
            end
        end
    end

    self:UpdateCurve()
end

--= Return Module =--
return PenTool