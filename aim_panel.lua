-- LocalScript -> StarterPlayer > StarterPlayerScripts
-- UI bisa diperkecil/diperbesar: tombol A- / A+ (skala), pegangan sudut kanan-bawah (ubah ukuran), tombol – (minimize)
-- RightShift = sembunyikan/tampilkan panel

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local S = {
	Aim = true, Mode = "Hold", Part = "Head", FOV = 140, Smooth = 0.35, Prediction = 0.06,
	ShowFOV = true, AimTeam = true, WallCheck = true, Sticky = true,
	ESP = true, Names = true, Health = true, Dist = true, Tracers = false,
	ESPTeam = true, MaxDist = 1500,
}

local C = {
	bg = Color3.fromRGB(18, 18, 24), card = Color3.fromRGB(30, 30, 40),
	accent = Color3.fromRGB(110, 90, 255), text = Color3.fromRGB(235, 235, 245),
	dim = Color3.fromRGB(150, 150, 170), off = Color3.fromRGB(60, 60, 75),
}

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end
local function round(o, r) new("UICorner", {CornerRadius = UDim.new(0, r or 8)}, o) end
local function isPress(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end
local function isMove(i) return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch end

---------------------------------------------------------------- GUI
local PG = LP:WaitForChild("PlayerGui")
local gui = new("ScreenGui", {Name = "AimPanel", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 50}, PG)
local espFolder = new("Folder", {Name = "ESPObjects"}, PG)
local tracerLayer = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 1}, gui)

local fovCircle = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	BackgroundTransparency = 1, ZIndex = 2}, gui)
new("UICorner", {CornerRadius = UDim.new(1, 0)}, fovCircle)
local fovStroke = new("UIStroke", {Color = Color3.new(1, 1, 1), Thickness = 1.5, Transparency = 0.3}, fovCircle)

local winSize = Vector2.new(250, 380)
local MIN_W, MAX_W, MIN_H, MAX_H = 210, 520, 220, 700

local main = new("Frame", {Size = UDim2.fromOffset(winSize.X, winSize.Y), Position = UDim2.fromOffset(20, 90),
	BackgroundColor3 = C.bg, BorderSizePixel = 0, ZIndex = 10, Active = true}, gui)
round(main, 12)
new("UIStroke", {Color = C.accent, Thickness = 1.2, Transparency = 0.4}, main)
local uiScale = new("UIScale", {Scale = 1}, main)

local bar = new("Frame", {Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1}, main)
new("TextLabel", {Text = "  ◎ AIM PANEL", Size = UDim2.new(1, -110, 1, 0), BackgroundTransparency = 1,
	TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left}, bar)

local function barBtn(text, xOff)
	local b = new("TextButton", {Text = text, Size = UDim2.fromOffset(28, 24), Position = UDim2.new(1, xOff, 0, 5),
		BackgroundColor3 = C.card, TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 13, AutoButtonColor = false}, bar)
	round(b, 6)
	return b
end
local minBtn = barBtn("–", -34)
local plusBtn = barBtn("A+", -66)
local minusBtn = barBtn("A-", -98)

-- geser jendela (delta dibagi skala supaya pas)
local dragging, dragStart, startPos
bar.InputBegan:Connect(function(i)
	if isPress(i) then dragging, dragStart, startPos = true, i.Position, main.Position end
end)
UIS.InputChanged:Connect(function(i)
	if dragging and isMove(i) then
		local d = (i.Position - dragStart) / uiScale.Scale
		main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end
end)
UIS.InputEnded:Connect(function(i) if isPress(i) then dragging = false end end)

local tabs = new("Frame", {Position = UDim2.fromOffset(8, 38), Size = UDim2.new(1, -16, 0, 28), BackgroundTransparency = 1}, main)
local content = new("Frame", {Position = UDim2.fromOffset(8, 72), Size = UDim2.new(1, -16, 1, -98),
	BackgroundTransparency = 1, ClipsDescendants = true}, main)
local footer = new("TextLabel", {Text = "RightShift = sembunyikan panel", Position = UDim2.new(0, 8, 1, -22),
	Size = UDim2.new(1, -40, 0, 18), BackgroundTransparency = 1, TextColor3 = C.dim,
	Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd}, main)

-- pegangan ubah ukuran (sudut kanan-bawah)
local grip = new("TextButton", {Text = "◢", Size = UDim2.fromOffset(22, 22), Position = UDim2.new(1, -22, 1, -22),
	BackgroundTransparency = 1, TextColor3 = C.accent, Font = Enum.Font.GothamBold, TextSize = 16, ZIndex = 12,
	AutoButtonColor = false}, main)

local resizing, rStart, rSize = false, nil, nil
grip.InputBegan:Connect(function(i)
	if isPress(i) then resizing, rStart, rSize = true, i.Position, winSize end
end)
UIS.InputChanged:Connect(function(i)
	if resizing and isMove(i) then
		local d = (i.Position - rStart) / uiScale.Scale
		winSize = Vector2.new(
			math.clamp(rSize.X + d.X, MIN_W, MAX_W),
			math.clamp(rSize.Y + d.Y, MIN_H, MAX_H)
		)
		main.Size = UDim2.fromOffset(winSize.X, winSize.Y)
	end
end)
UIS.InputEnded:Connect(function(i) if isPress(i) then resizing = false end end)

-- skala keseluruhan UI
local function setScale(v)
	uiScale.Scale = math.clamp(math.round(v * 10) / 10, 0.6, 1.6)
end
plusBtn.MouseButton1Click:Connect(function() setScale(uiScale.Scale + 0.1) end)
minusBtn.MouseButton1Click:Connect(function() setScale(uiScale.Scale - 0.1) end)

local pages, tabBtns = {}, {}
local function show(name)
	for n, pg in pairs(pages) do pg.Visible = (n == name) end
	for n, b in pairs(tabBtns) do
		b.BackgroundColor3 = (n == name) and C.accent or C.card
		b.TextColor3 = (n == name) and Color3.new(1, 1, 1) or C.dim
	end
end
local function addTab(name, idx)
	local pg = new("ScrollingFrame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 3, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false}, content)
	new("UIListLayout", {Padding = UDim.new(0, 6)}, pg)
	pages[name] = pg
	local b = new("TextButton", {Text = name, Size = UDim2.new(0.5, -3, 1, 0), Position = UDim2.new((idx - 1) * 0.5, (idx - 1) * 3, 0, 0),
		BackgroundColor3 = C.card, TextColor3 = C.dim, Font = Enum.Font.GothamBold, TextSize = 13, AutoButtonColor = false}, tabs)
	round(b, 8)
	tabBtns[name] = b
	b.MouseButton1Click:Connect(function() show(name) end)
	return pg
end

local function label(parent, text, pos, size, color, font, align)
	return new("TextLabel", {Text = text, Position = pos, Size = size, BackgroundTransparency = 1,
		TextColor3 = color or C.text, Font = font or Enum.Font.Gotham, TextSize = 13,
		TextXAlignment = align or Enum.TextXAlignment.Left}, parent)
end

local function toggle(pg, text, key)
	local r = new("TextButton", {Text = "", Size = UDim2.new(1, -6, 0, 32), BackgroundColor3 = C.card, AutoButtonColor = false}, pg)
	round(r, 8)
	label(r, text, UDim2.fromOffset(10, 0), UDim2.new(1, -60, 1, 0))
	local pill = new("Frame", {Size = UDim2.fromOffset(36, 18), Position = UDim2.new(1, -46, 0.5, -9), BackgroundColor3 = C.off}, r)
	round(pill, 9)
	local knob = new("Frame", {Size = UDim2.fromOffset(14, 14), Position = UDim2.fromOffset(2, 2), BackgroundColor3 = Color3.new(1, 1, 1)}, pill)
	round(knob, 7)
	local function paint()
		local on = S[key]
		TweenService:Create(pill, TweenInfo.new(0.15), {BackgroundColor3 = on and C.accent or C.off}):Play()
		TweenService:Create(knob, TweenInfo.new(0.15), {Position = on and UDim2.fromOffset(20, 2) or UDim2.fromOffset(2, 2)}):Play()
	end
	paint()
	r.MouseButton1Click:Connect(function() S[key] = not S[key]; paint() end)
end

local function selector(pg, text, key, opts)
	local r = new("Frame", {Size = UDim2.new(1, -6, 0, 58), BackgroundColor3 = C.card}, pg)
	round(r, 8)
	label(r, text, UDim2.fromOffset(10, 4), UDim2.new(1, -20, 0, 16))
	local holder = new("Frame", {Position = UDim2.fromOffset(8, 26), Size = UDim2.new(1, -16, 0, 26), BackgroundTransparency = 1}, r)
	local btns, n = {}, #opts
	local function paint()
		for o, b in pairs(btns) do
			b.BackgroundColor3 = (S[key] == o) and C.accent or C.off
			b.TextColor3 = (S[key] == o) and Color3.new(1, 1, 1) or C.dim
		end
	end
	for i, o in ipairs(opts) do
		local b = new("TextButton", {Text = o, Size = UDim2.new(1 / n, -4, 1, 0), Position = UDim2.new((i - 1) / n, 2, 0, 0),
			BackgroundColor3 = C.off, TextColor3 = C.dim, Font = Enum.Font.GothamBold, TextSize = 12, AutoButtonColor = false}, holder)
		round(b, 6)
		btns[o] = b
		b.MouseButton1Click:Connect(function() S[key] = o; paint() end)
	end
	paint()
end

local function slider(pg, text, key, min, max, step)
	local r = new("Frame", {Size = UDim2.new(1, -6, 0, 46), BackgroundColor3 = C.card, Active = true}, pg)
	round(r, 8)
	label(r, text, UDim2.fromOffset(10, 4), UDim2.new(1, -70, 0, 16))
	local val = label(r, "", UDim2.new(1, -60, 0, 4), UDim2.fromOffset(50, 16), C.accent, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
	local track = new("Frame", {Position = UDim2.fromOffset(10, 29), Size = UDim2.new(1, -20, 0, 8), BackgroundColor3 = C.off}, r)
	round(track, 4)
	local fill = new("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.accent}, track)
	round(fill, 4)
	local function set(v)
		v = math.clamp(math.round(v / step) * step, min, max)
		S[key] = v
		fill.Size = UDim2.fromScale((v - min) / (max - min), 1)
		val.Text = tostring(math.round(v * 1000) / 1000)
	end
	set(S[key])
	local drag = false
	local function upd(x) set(min + (max - min) * math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)) end
	r.InputBegan:Connect(function(i) if isPress(i) then drag = true; upd(i.Position.X) end end)
	UIS.InputChanged:Connect(function(i) if drag and isMove(i) then upd(i.Position.X) end end)
	UIS.InputEnded:Connect(function(i) if isPress(i) then drag = false end end)
end

local aimPage = addTab("AIM", 1)
toggle(aimPage, "Aim Assist", "Aim")
selector(aimPage, "Mode (klik kanan)", "Mode", {"Hold", "Always"})
selector(aimPage, "Target", "Part", {"Head", "Neck", "Body"})
slider(aimPage, "FOV", "FOV", 30, 500, 5)
slider(aimPage, "Kecepatan", "Smooth", 0.05, 1, 0.01)
slider(aimPage, "Prediksi", "Prediction", 0, 0.3, 0.005)
toggle(aimPage, "Tampilkan Lingkaran FOV", "ShowFOV")
toggle(aimPage, "Abaikan Satu Tim", "AimTeam")
toggle(aimPage, "Wall Check", "WallCheck")
toggle(aimPage, "Sticky Lock", "Sticky")

local espPage = addTab("ESP", 2)
toggle(espPage, "ESP", "ESP")
toggle(espPage, "Nama", "Names")
toggle(espPage, "Health Bar", "Health")
toggle(espPage, "Jarak", "Dist")
toggle(espPage, "Tracer", "Tracers")
toggle(espPage, "Sembunyikan Satu Tim", "ESPTeam")
slider(espPage, "Jarak Maks", "MaxDist", 100, 3000, 50)
show("AIM")

local minimized = false
minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	tabs.Visible, content.Visible, footer.Visible, grip.Visible = not minimized, not minimized, not minimized, not minimized
	main.Size = minimized and UDim2.fromOffset(winSize.X, 34) or UDim2.fromOffset(winSize.X, winSize.Y)
	minBtn.Text = minimized and "+" or "–"
end)
UIS.InputBegan:Connect(function(i, gp)
	if not gp and i.KeyCode == Enum.KeyCode.RightShift then main.Visible = not main.Visible end
end)

---------------------------------------------------------------- ESP
local esp = {}
local ENEMY, ALLY = Color3.fromRGB(255, 70, 70), Color3.fromRGB(70, 255, 120)

local function sameTeam(p) return LP.Team ~= nil and p.Team == LP.Team end

local function removeESP(p)
	local e = esp[p]
	if not e then return end
	for _, o in ipairs(e.objs) do pcall(function() o:Destroy() end) end
	esp[p] = nil
end

local function buildESP(p, char)
	local head = char:FindFirstChild("Head")
	if not head then return end
	local hl = new("Highlight", {FillTransparency = 0.55, OutlineTransparency = 0,
		DepthMode = Enum.HighlightDepthMode.AlwaysOnTop, FillColor = ENEMY, OutlineColor = Color3.new(1, 1, 1)}, char)
	local bb = new("BillboardGui", {Adornee = head, Size = UDim2.fromOffset(140, 42), StudsOffset = Vector3.new(0, 2.8, 0),
		AlwaysOnTop = true}, espFolder)
	local nameL = new("TextLabel", {Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, TextColor3 = Color3.new(1, 1, 1),
		TextStrokeTransparency = 0, Font = Enum.Font.GothamBold, TextSize = 13, Text = p.DisplayName}, bb)
	local hpBack = new("Frame", {Position = UDim2.new(0.5, -35, 0, 19), Size = UDim2.fromOffset(70, 5),
		BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0}, bb)
	local hpFill = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = ALLY, BorderSizePixel = 0}, hpBack)
	local info = new("TextLabel", {Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1,
		TextColor3 = C.dim, TextStrokeTransparency = 0.3, Font = Enum.Font.Gotham, TextSize = 11, Text = ""}, bb)
	local tracer = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, BackgroundColor3 = ENEMY, Visible = false}, tracerLayer)
	esp[p] = {char = char, hl = hl, bb = bb, name = nameL, hpBack = hpBack, hpFill = hpFill, info = info,
		tracer = tracer, objs = {hl, bb, tracer}}
end

local function hideESP(e)
	e.hl.Enabled = false
	e.bb.Enabled = false
	e.tracer.Visible = false
end

local function updateESP(p)
	local char = p.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local head = char and char:FindFirstChild("Head")
	local e = esp[p]
	if e and e.char ~= char then removeESP(p); e = nil end

	local dist = root and (root.Position - Camera.CFrame.Position).Magnitude or math.huge
	local visible = S.ESP and hum and root and head and hum.Health > 0 and dist <= S.MaxDist
		and not (S.ESPTeam and sameTeam(p))
	if not visible then
		if e then hideESP(e) end
		return
	end
	if not e then
		buildESP(p, char)
		e = esp[p]
		if not e then return end
	end

	local col = sameTeam(p) and ALLY or ENEMY
	e.hl.Enabled = true
	e.hl.FillColor = col
	e.bb.Enabled = S.Names or S.Health or S.Dist
	e.name.Visible = S.Names
	e.hpBack.Visible = S.Health
	e.info.Visible = S.Dist
	e.info.Text = string.format("%dm", math.floor(dist))
	local frac = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
	e.hpFill.Size = UDim2.fromScale(frac, 1)
	e.hpFill.BackgroundColor3 = ENEMY:Lerp(ALLY, frac)

	local sp, on = Camera:WorldToViewportPoint(root.Position)
	if S.Tracers and on then
		local vp = Camera.ViewportSize
		local from, to = Vector2.new(vp.X / 2, vp.Y), Vector2.new(sp.X, sp.Y)
		local d = to - from
		e.tracer.Visible = true
		e.tracer.BackgroundColor3 = col
		e.tracer.Size = UDim2.fromOffset(d.Magnitude, 1.5)
		e.tracer.Position = UDim2.fromOffset((from.X + to.X) / 2, (from.Y + to.Y) / 2)
		e.tracer.Rotation = math.deg(math.atan2(d.Y, d.X))
	else
		e.tracer.Visible = false
	end
end

local function trackPlayer(p)
	if p == LP then return end
	p.CharacterRemoving:Connect(function() removeESP(p) end)
end
for _, p in ipairs(Players:GetPlayers()) do trackPlayer(p) end
Players.PlayerAdded:Connect(trackPlayer)
Players.PlayerRemoving:Connect(removeESP)

---------------------------------------------------------------- AIM
local current
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.RespectCanCollide = true

local function aimPoint(char)
	local head = char:FindFirstChild("Head")
	local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
	if S.Part == "Head" then return head and head.Position
	elseif S.Part == "Neck" then
		return head and (head.Position - head.CFrame.UpVector * head.Size.Y * 0.5)
	end
	return torso and torso.Position
end

local function lineClear(pos, char)
	if not S.WallCheck then return true end
	rayParams.FilterDescendantsInstances = {LP.Character, char}
	return workspace:Raycast(Camera.CFrame.Position, pos - Camera.CFrame.Position, rayParams) == nil
end

local function check(p, fov)
	local char = p.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not (hum and root and hum.Health > 0) then return end
	if S.AimTeam and sameTeam(p) then return end
	local pos = aimPoint(char)
	if not pos then return end
	pos = pos + root.AssemblyLinearVelocity * S.Prediction
	local sp, on = Camera:WorldToViewportPoint(pos)
	if not on then return end
	local d = (Vector2.new(sp.X, sp.Y) - Camera.ViewportSize / 2).Magnitude
	if d > fov or not lineClear(pos, char) then return end
	return pos, d
end

local function getTarget()
	if S.Sticky and current then
		local pos = check(current, S.FOV * 1.6)
		if pos then return pos end
		current = nil
	end
	local best, bestPos, bestD = nil, nil, math.huge
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LP then
			local pos, d = check(p, S.FOV)
			if pos and d < bestD then best, bestPos, bestD = p, pos, d end
		end
	end
	current = best
	return bestPos
end

local function holding()
	return S.Mode == "Always" or UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
end

RunService:BindToRenderStep("AimPanelLoop", Enum.RenderPriority.Camera.Value + 1, function(dt)
	Camera = workspace.CurrentCamera
	fovCircle.Visible = S.Aim and S.ShowFOV
	fovCircle.Size = UDim2.fromOffset(S.FOV * 2, S.FOV * 2)

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LP then updateESP(p) end
	end

	local locked = false
	if S.Aim and holding() then
		local pos = getTarget()
		if pos then
			locked = true
			local goal = CFrame.lookAt(Camera.CFrame.Position, pos)
			local alpha = S.Smooth >= 1 and 1 or math.clamp(1 - (1 - S.Smooth) ^ (dt * 60), 0, 1)
			Camera.CFrame = Camera.CFrame:Lerp(goal, alpha)
		end
	else
		current = nil
	end
	fovStroke.Color = locked and ALLY or Color3.new(1, 1, 1)
end)
