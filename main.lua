-- Ds Hub | MEMBRO v2
-- Só funciona se a pessoa aceitar o aviso. Os comandos do admin são FIXOS (lista ACTIONS).
local DB = "https://site-0ds-default-rtdb.firebaseio.com"
local BG_URL = "https://i.postimg.cc/50Wf56pX/e288c5a05c52f160f09a367703e89231.jpg"
local ICON_URL = "https://i.postimg.cc/R0HMnc77/85b8ac8bcf9f322d967a6ed4b5e8bf6b.jpg" -- foto do botão flutuante
local FOLDER = "MeuHub"

-- Scripts que aparecem no menu: { "Nome", "link do script" }
local SCRIPTS = {
	{ "Emotes", "https://api.rubis.app/v2/scrap/qehrlb7Oh8oLOgu3/raw" },
	{ "VR", "https://rawscripts.net/raw/Natural-Disaster-Survival-FE-Fake-VR-Natural-Disaster-Keyless-241098" },
	{ "Brookhaven", "https://rawscripts.net/raw/Brookhaven-RP-Slayer-Hub-246319" },
}

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local lp = Players.LocalPlayer
local req = request or http_request or (syn and syn.request)

-- ===== HTTP (mostra o erro real) =====
local lastErr = ""
local function http(method, path, body)
	if not req then lastErr = "executor sem request()"; return nil end
	local ok, res = pcall(req, {
		Url = DB .. path, Method = method,
		Headers = { ["Content-Type"] = "application/json" },
		Body = body and HttpService:JSONEncode(body) or nil,
	})
	if not ok then lastErr = tostring(res):sub(1, 60); return nil end
	local code = res.StatusCode or 0
	if res.Success or code == 200 then lastErr = ""; return res.Body or "" end
	lastErr = "HTTP " .. tostring(code) .. " " .. tostring(res.Body or ""):sub(1, 50)
	return nil
end

-- ===== UI helpers =====
local RED = Color3.fromRGB(220, 30, 40)
local PANEL = Color3.fromRGB(22, 5, 7)
local WHITE = Color3.new(1, 1, 1)
local function mk(class, props, par)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = par
	return o
end
local function round(o, r) mk("UICorner", { CornerRadius = UDim.new(0, r or 8) }, o) end
local function stroke(o, th, col)
	mk("UIStroke", { Thickness = th or 1.5, Color = col or RED, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o)
end
local function fetchAsset(url, name)
	local ok, res = pcall(function()
		if not isfolder(FOLDER) then makefolder(FOLDER) end
		local path = FOLDER .. "/" .. name
		if not isfile(path) then writefile(path, game:HttpGet(url)) end
		return getcustomasset(path)
	end)
	return ok and res or nil
end

local parent = (gethui and gethui()) or game:GetService("CoreGui")
local old = parent:FindFirstChild("MeuHubMembro")
if old then old:Destroy() end
local gui = mk("ScreenGui", { Name = "MeuHubMembro", ResetOnSpawn = false }, parent)

local function isPress(i)
	return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end
local function isMove(i)
	return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch
end

-- arrasta "target" segurando "handle"; se só tocar (sem arrastar) chama onTap
local conns = {}
local function makeDraggable(handle, target, onTap)
	local dragging, moved, startPos, startInput = false, false, nil, nil
	handle.InputBegan:Connect(function(i)
		if isPress(i) then
			dragging, moved = true, false
			startPos, startInput = target.Position, i.Position
		end
	end)
	table.insert(conns, UIS.InputChanged:Connect(function(i)
		if dragging and isMove(i) then
			local d = i.Position - startInput
			if d.Magnitude > 6 then moved = true end
			if moved then
				target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end
		end
	end))
	table.insert(conns, UIS.InputEnded:Connect(function(i)
		if dragging and isPress(i) then
			dragging = false
			if not moved and onTap then onTap() end
		end
	end))
end

local function panel(w, h, pos)
	local f = mk("Frame", {
		Size = UDim2.fromOffset(w, h), Position = pos,
		BackgroundColor3 = Color3.fromRGB(8, 2, 3), ClipsDescendants = true,
	}, gui)
	round(f, 14); stroke(f, 2)
	local img = mk("ImageLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Crop, ImageTransparency = 0.4,
	}, f)
	round(img, 14)
	task.spawn(function() local a = fetchAsset(BG_URL, "bg.jpg"); if a then img.Image = a end end)
	return f
end
local function bigBtn(par, text, pos, size, filled)
	local b = mk("TextButton", {
		Text = text, Position = pos, Size = size,
		BackgroundColor3 = filled and RED or PANEL, BackgroundTransparency = filled and 0 or 0.1,
		TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 14,
	}, par)
	round(b, 10); stroke(b, 1.5)
	return b
end

-- janela com menu lateral (estilo hub): abas à esquerda, conteúdo à direita
local function buildWindow(w, h, title, sub, tabNames, onClose)
	local win = panel(w, h, UDim2.new(0.5, -w / 2, 0.5, -h / 2))
	local top = mk("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1 }, win)
	mk("TextLabel", {
		Text = title .. '  <font size="11" color="rgb(210,150,150)">' .. sub .. '</font>', RichText = true,
		Size = UDim2.new(1, -90, 1, 0), Position = UDim2.fromOffset(16, 0), BackgroundTransparency = 1,
		TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left,
	}, top)
	local minBtn = mk("TextButton", {
		Text = "–", Size = UDim2.fromOffset(30, 26), Position = UDim2.new(1, onClose and -68 or -36, 0, 5), BackgroundTransparency = 1,
		TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 20,
	}, top)
	minBtn.MouseButton1Click:Connect(function() win.Visible = false end)
	if onClose then
		local xBtn = mk("TextButton", {
			Text = "X", Size = UDim2.fromOffset(30, 26), Position = UDim2.new(1, -36, 0, 5), BackgroundTransparency = 1,
			TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 16,
		}, top)
		xBtn.MouseButton1Click:Connect(onClose)
	end
	makeDraggable(top, win)

	local statusLbl = mk("TextLabel", {
		Position = UDim2.new(0, 144, 1, -24), Size = UDim2.new(1, -156, 0, 20), BackgroundTransparency = 1,
		Text = "", TextColor3 = Color3.fromRGB(240, 210, 210), Font = Enum.Font.Gotham,
		TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
	}, win)

	local side = mk("ScrollingFrame", {
		Position = UDim2.fromOffset(8, 40), Size = UDim2.new(0, 128, 1, -50), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 2, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
	}, win)
	mk("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, side)
	mk("UIPadding", { PaddingTop = UDim.new(0, 2), PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }, side)

	local pages, tabBtns, bars = {}, {}, {}
	local function selectTab(name)
		for n, p in pairs(pages) do p.Visible = (n == name) end
		for n, b in pairs(tabBtns) do
			b.BackgroundColor3 = (n == name) and Color3.fromRGB(80, 12, 16) or PANEL
			bars[n].Visible = (n == name)
		end
	end
	for _, name in ipairs(tabNames) do
		local b = mk("TextButton", {
			Text = "   " .. name, Size = UDim2.new(1, 0, 0, 36),
			BackgroundColor3 = PANEL, BackgroundTransparency = 0.1, TextColor3 = WHITE,
			Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
		}, side)
		round(b, 10); stroke(b, 1.5)
		local bar = mk("Frame", { Size = UDim2.fromOffset(4, 16), Position = UDim2.new(0, 3, 0.5, -8), BackgroundColor3 = RED, Visible = false }, b)
		round(bar, 2)
		local p = mk("ScrollingFrame", {
			Position = UDim2.fromOffset(144, 40), Size = UDim2.new(1, -152, 1, -68), BackgroundTransparency = 1,
			BorderSizePixel = 0, ScrollBarThickness = 3, AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(), Visible = false,
		}, win)
		mk("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, p)
		mk("UIPadding", { PaddingTop = UDim.new(0, 2), PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }, p)
		pages[name], tabBtns[name], bars[name] = p, b, bar
		b.MouseButton1Click:Connect(function() selectTab(name) end)
	end
	selectTab(tabNames[1])
	return win, pages, function(t) statusLbl.Text = t end
end

-- botão flutuante pequeno (clica = abre/minimiza o menu)
local function floatButton(onTap)
	local b = mk("ImageButton", {
		Size = UDim2.fromOffset(46, 46), Position = UDim2.fromOffset(10, 8),
		BackgroundColor3 = PANEL, AutoButtonColor = false, ScaleType = Enum.ScaleType.Crop, Image = "",
	}, gui)
	round(b, 12); stroke(b, 2, Color3.fromRGB(70, 150, 255))
	local fallback = mk("TextLabel", {
		Text = "M", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 22,
	}, b)
	if ICON_URL:find("^http") then
		task.spawn(function()
			local a = fetchAsset(ICON_URL, "icon.png")
			if a then b.Image = a; fallback.Visible = false end
		end)
	end
	makeDraggable(b, b, onTap)
	return b
end

-- linhas / seções das páginas
local function section(par, text)
	mk("TextLabel", {
		Text = text, Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, TextColor3 = WHITE,
		Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
	}, par)
end
local function rowBtn(par, text, cb)
	local b = mk("TextButton", { Text = "", Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = PANEL, BackgroundTransparency = 0.15 }, par)
	round(b, 10); stroke(b, 1.5)
	mk("TextLabel", {
		Text = text, Size = UDim2.new(1, -44, 1, 0), Position = UDim2.fromOffset(12, 0), BackgroundTransparency = 1,
		TextColor3 = WHITE, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
	}, b)
	mk("TextLabel", {
		Text = ">", Size = UDim2.fromOffset(30, 38), Position = UDim2.new(1, -34, 0, 0), BackgroundTransparency = 1,
		TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 16,
	}, b)
	b.MouseButton1Click:Connect(cb)
	return b
end
local DARK = Color3.fromRGB(40, 8, 10)
local function toggleRow(par, text, desc, onChange)
	if type(desc) == "function" then onChange, desc = desc, nil end
	local state = false
	local b = mk("TextButton", { Text = "", Size = UDim2.new(1, 0, 0, desc and 46 or 38), BackgroundColor3 = PANEL, BackgroundTransparency = 0.15 }, par)
	round(b, 10); stroke(b, 1.5)
	mk("TextLabel", {
		Text = text, Size = UDim2.new(1, -76, 0, desc and 24 or 38), Position = UDim2.fromOffset(12, desc and 3 or 0), BackgroundTransparency = 1,
		TextColor3 = WHITE, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
	}, b)
	if desc then
		mk("TextLabel", {
			Text = desc, Size = UDim2.new(1, -76, 0, 16), Position = UDim2.fromOffset(12, 26), BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(220, 140, 140), Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
		}, b)
	end
	local sw = mk("Frame", { Size = UDim2.fromOffset(44, 22), Position = UDim2.new(1, -54, 0.5, -11), BackgroundColor3 = DARK }, b)
	round(sw, 11); stroke(sw, 1.5)
	local knob = mk("Frame", { Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = RED }, sw)
	round(knob, 8)
	b.MouseButton1Click:Connect(function()
		state = not state
		knob.Position = state and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3)
		knob.BackgroundColor3 = state and WHITE or RED
		sw.BackgroundColor3 = state and RED or DARK
		pcall(onChange, state)
	end)
	return b
end
local function sliderRow(par, text, desc, minV, maxV, defV, onChange)
	local b = mk("Frame", { Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = PANEL, BackgroundTransparency = 0.15 }, par)
	round(b, 10); stroke(b, 1.5)
	mk("TextLabel", {
		Text = text, Size = UDim2.new(0.5, -12, 0, 24), Position = UDim2.fromOffset(12, 3), BackgroundTransparency = 1,
		TextColor3 = WHITE, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
	}, b)
	mk("TextLabel", {
		Text = desc, Size = UDim2.new(0.5, -12, 0, 16), Position = UDim2.fromOffset(12, 26), BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(220, 140, 140), Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
	}, b)
	local val = mk("TextLabel", {
		Text = tostring(defV), Size = UDim2.fromOffset(30, 46), Position = UDim2.new(0.5, 0, 0, 0), BackgroundTransparency = 1,
		TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 13,
	}, b)
	local hit = mk("Frame", { Size = UDim2.new(0.5, -48, 0, 28), Position = UDim2.new(0.5, 34, 0.5, -14), BackgroundTransparency = 1 }, b)
	local bar = mk("Frame", { Size = UDim2.new(1, 0, 0, 8), Position = UDim2.new(0, 0, 0.5, -4), BackgroundColor3 = DARK }, hit)
	round(bar, 4); stroke(bar, 1.5)
	local fill = mk("Frame", { Size = UDim2.new((defV - minV) / (maxV - minV), 0, 1, 0), BackgroundColor3 = RED }, bar)
	round(fill, 4)
	local dragging = false
	local function setFromX(x)
		local rel = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
		local v = math.floor(minV + (maxV - minV) * rel + 0.5)
		fill.Size = UDim2.new(rel, 0, 1, 0)
		val.Text = tostring(v)
		pcall(onChange, v)
	end
	hit.InputBegan:Connect(function(i)
		if isPress(i) then dragging = true; setFromX(i.Position.X) end
	end)
	table.insert(conns, UIS.InputChanged:Connect(function(i)
		if dragging and isMove(i) then setFromX(i.Position.X) end
	end))
	table.insert(conns, UIS.InputEnded:Connect(function(i)
		if isPress(i) then dragging = false end
	end))
	return b
end

local function buildCredits(page)
	local function lbl(text, size, bold, col, h)
		mk("TextLabel", {
			Text = text, Size = UDim2.new(1, 0, 0, h or 24), BackgroundTransparency = 1,
			TextColor3 = col or WHITE, Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham, TextSize = size,
			TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		}, page)
	end
	section(page, "Créditos")
	lbl("Feito por 0Ds", 15, true)
	lbl("Nick: elitefroster", 13, false)
	lbl("", 8, false, WHITE, 10)
	lbl("⚠ Aviso: o hub não está 100% pronto e o andar sobre a água não funciona.", 12, true, Color3.fromRGB(255, 190, 120), 44)
end

local function buildMods(page, say)
	local alive = true
	local uid = tostring(lp.UserId)
	local mine = { ids = {}, headless = false }
	local cache = {}

	local function publish()
		if #mine.ids == 0 and not mine.headless then
			http("DELETE", "/mods/" .. uid .. ".json")
		else
			http("PUT", "/mods/" .. uid .. ".json", {
				name = lp.Name, ids = table.concat(mine.ids, ","), headless = mine.headless,
			})
		end
	end

	-- carrega o item pelo ID e remove qualquer script de dentro (só visual)
	local function loadAsset(id)
		if cache[id] ~= nil then return cache[id] or nil end
		local objs
		local ok, res = pcall(function() return game:GetObjects("rbxassetid://" .. id) end)
		if ok and type(res) == "table" then
			objs = res
		else
			local ok2, m = pcall(function() return game:GetService("InsertService"):LoadAsset(id) end)
			if ok2 and m then objs = m:GetChildren() end
		end
		if objs then
			for _, o in ipairs(objs) do
				for _, d in ipairs(o:GetDescendants()) do
					if d:IsA("LuaSourceContainer") then d:Destroy() end
				end
			end
		end
		cache[id] = objs or false
		return objs
	end

	local function limb(char, mp)
		if mp:FindFirstAncestorOfClass("Accessory") then return end
		local t = char:FindFirstChild(mp.Name)
		if not (t and t:IsA("BasePart")) or t:GetAttribute("DsMod") then return end
		local c = mp:Clone()
		c:ClearAllChildren()
		c.Anchored = false; c.CanCollide = false; c.Massless = true
		c.CFrame = t.CFrame
		c:SetAttribute("DsMod", true)
		c.Parent = char
		local w = Instance.new("WeldConstraint")
		w.Part0 = c; w.Part1 = t; w.Parent = c
		t.Transparency = 1
		t:SetAttribute("DsHidLimb", true)
	end

	local function applyOne(char, id)
		local objs = loadAsset(id)
		if not objs then return end
		local hm = char:FindFirstChildOfClass("Humanoid")
		for _, o in ipairs(objs) do
			if o:IsA("Accessory") and hm then
				local c = o:Clone()
				c:SetAttribute("DsMod", true)
				hm:AddAccessory(c)
			end
			if o:IsA("MeshPart") then limb(char, o) end
			for _, d in ipairs(o:GetDescendants()) do
				if d:IsA("MeshPart") then limb(char, d) end
			end
		end
	end

	local function clearMods(char)
		for _, o in ipairs(char:GetDescendants()) do
			if o:GetAttribute("DsMod") then
				o:Destroy()
			elseif o:GetAttribute("DsHidLimb") then
				o.Transparency = 0; o:SetAttribute("DsHidLimb", nil)
			elseif o:GetAttribute("DsHidDecal") then
				o.Transparency = 0; o:SetAttribute("DsHidDecal", nil)
			end
		end
	end

	local function headless(char)
		local head = char:FindFirstChild("Head")
		if not head then return end
		head.Transparency = 1; head:SetAttribute("DsHidLimb", true)
		for _, d in ipairs(head:GetChildren()) do
			if d:IsA("Decal") then d.Transparency = 1; d:SetAttribute("DsHidDecal", true) end
		end
	end

	-- aplica (só visualmente, no seu aparelho) os mods de todo mundo que está com o hub ativo
	local function sync()
		local body = http("GET", "/mods.json")
		if body == nil then return end
		local data = {}
		if body ~= "null" and body ~= "" then
			local ok, d = pcall(HttpService.JSONDecode, HttpService, body)
			if ok and type(d) == "table" then data = d end
		end
		for _, pl in ipairs(Players:GetPlayers()) do
			local char = pl.Character
			if char and char:FindFirstChildOfClass("Humanoid") and char:FindFirstChild("HumanoidRootPart") then
				local d = data[tostring(pl.UserId)]
				local want = d and (tostring(d.ids or "") .. "|" .. tostring(d.headless == true)) or nil
				if char:GetAttribute("DsSig") ~= want then
					clearMods(char)
					if d then
						if d.headless == true then headless(char) end
						local n = 0
						for id in tostring(d.ids or ""):gmatch("%d+") do
							n = n + 1
							if n > 8 then break end
							pcall(applyOne, char, tonumber(id))
						end
					end
					char:SetAttribute("DsSig", want)
				end
			end
		end
	end
	task.spawn(function()
		while alive do pcall(sync); task.wait(3) end
	end)

	-- UI da aba Mod
	section(page, "Mod personalizado")
	mk("TextLabel", {
		Text = "Cole o ID do acessório ou pacote (o número no link do item no catálogo). Só quem está com o hub ativo vê.",
		Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(240, 210, 210),
		Font = Enum.Font.Gotham, TextSize = 11, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
	}, page)
	toggleRow(page, "Sem cabeça (headless)", "Esconde a sua cabeça", function(v)
		mine.headless = v
		publish()
		say(v and "Headless ligado." or "Headless desligado.")
	end)
	local idRow = mk("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = PANEL, BackgroundTransparency = 0.15 }, page)
	round(idRow, 10); stroke(idRow, 1.5)
	local idBox = mk("TextBox", {
		Size = UDim2.new(1, -20, 1, -8), Position = UDim2.fromOffset(10, 4), BackgroundTransparency = 1,
		Text = "", PlaceholderText = "ID do item (só números)", PlaceholderColor3 = Color3.fromRGB(170, 130, 130),
		TextColor3 = WHITE, Font = Enum.Font.Code, TextSize = 12, ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left, ClipsDescendants = true,
	}, idRow)
	local listLbl = mk("TextLabel", {
		Text = "IDs ativos: nenhum", Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1,
		TextColor3 = WHITE, Font = Enum.Font.Gotham, TextSize = 11, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
	}, page)
	local function refreshList()
		listLbl.Text = "IDs ativos: " .. (#mine.ids > 0 and table.concat(mine.ids, ", ") or "nenhum")
	end
	rowBtn(page, "Adicionar ID", function()
		local n = idBox.Text:match("%d+")
		if not n then say("Digite o ID (só números)."); return end
		if #mine.ids >= 8 then say("Máximo de 8 IDs."); return end
		table.insert(mine.ids, n)
		idBox.Text = ""
		refreshList()
		publish()
		say("ID " .. n .. " adicionado.")
	end)
	rowBtn(page, "Limpar IDs", function()
		mine.ids = {}
		refreshList()
		publish()
		say("IDs removidos.")
	end)

	return function()
		alive = false
		http("DELETE", "/mods/" .. uid .. ".json")
	end
end

-- ===== recursos locais (só afetam VOCÊ) =====
local function hrp() return lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") end
local function hum() return lp.Character and lp.Character:FindFirstChildOfClass("Humanoid") end

local selfCleanup
local function buildSelf(pages, say)
	-- aba Scripts
	local sp = pages["Scripts"]
	local function runUrl(name, url)
		say("Executando " .. name .. "...")
		local ok, err = pcall(function() loadstring(game:HttpGet(url))() end)
		say(ok and (name .. " executado.") or ("Erro: " .. tostring(err):sub(1, 60)))
	end
	section(sp, "Scripts")
	if #SCRIPTS == 0 then
		mk("TextLabel", {
			Text = "Nenhum script na lista. Edite a tabela SCRIPTS no topo do arquivo ou cole um link abaixo.",
			Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(240, 210, 210),
			Font = Enum.Font.Gotham, TextSize = 12, TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		}, sp)
	end
	local function scriptCard(par, name, cb)
		local c = mk("Frame", { Size = UDim2.new(1, 0, 0, 80), BackgroundColor3 = PANEL, BackgroundTransparency = 0.15 }, par)
		round(c, 10); stroke(c, 1.5)
		mk("TextLabel", {
			Text = name, Size = UDim2.new(1, -24, 0, 26), Position = UDim2.fromOffset(12, 4), BackgroundTransparency = 1,
			TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
		}, c)
		local b = mk("TextButton", {
			Text = "Executar", Size = UDim2.new(1, -24, 0, 34), Position = UDim2.fromOffset(12, 36),
			BackgroundColor3 = RED, TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 13,
		}, c)
		round(b, 8); stroke(b, 1.5)
		b.MouseButton1Click:Connect(cb)
	end
	for _, s in ipairs(SCRIPTS) do
		scriptCard(sp, s[1], function() runUrl(s[1], s[2]) end)
	end
	section(sp, "Executar por link")
	local boxRow = mk("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = PANEL, BackgroundTransparency = 0.15 }, sp)
	round(boxRow, 10); stroke(boxRow, 1.5)
	local urlBox = mk("TextBox", {
		Size = UDim2.new(1, -20, 1, -8), Position = UDim2.fromOffset(10, 4), BackgroundTransparency = 1,
		Text = "", PlaceholderText = "Cole o link do script aqui", PlaceholderColor3 = Color3.fromRGB(170, 130, 130),
		TextColor3 = WHITE, Font = Enum.Font.Code, TextSize = 11, ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left, ClipsDescendants = true,
	}, boxRow)
	rowBtn(sp, "Executar link", function()
		local u = urlBox.Text
		if not u:find("^http") then say("Cole um link que comece com http."); return end
		runUrl("link", u)
	end)

	-- aba Natural Disaster
	local dp = pages["Natural Disaster"]
	local S = { fly = false, speed = false, jump = false, noclip = false, infjump = false, nofall = false, waterwalk = false, antifling = false, speedVal = 50, flyVal = 50 }
	local selfBV, wwPart
	local function stopSelfFly() if selfBV then selfBV:Destroy(); selfBV = nil end end

	local loopConn = RunService.Stepped:Connect(function()
		local c, h, r = lp.Character, hum(), hrp()
		if not (c and h and r) then return end
		if S.noclip then
			for _, p in ipairs(c:GetDescendants()) do
				if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
			end
		end
		if S.speed then h.WalkSpeed = S.speedVal end
		if S.jump then h.UseJumpPower = true; h.JumpPower = 90 end
		if S.nofall then
			local v = r.AssemblyLinearVelocity
			if v.Y < -55 then r.AssemblyLinearVelocity = Vector3.new(v.X, -30, v.Z) end
		end
		if S.antifling then
			for _, pl in ipairs(Players:GetPlayers()) do
				if pl ~= lp and pl.Character then
					for _, p in ipairs(pl.Character:GetDescendants()) do
						if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
					end
				end
			end
			if r.AssemblyAngularVelocity.Magnitude > 40 then r.AssemblyAngularVelocity = Vector3.zero end
			local v = r.AssemblyLinearVelocity
			if Vector3.new(v.X, 0, v.Z).Magnitude > 200 or (v.Y > 150 and not S.fly) then
				r.AssemblyLinearVelocity = Vector3.zero
			end
		end
		if S.waterwalk then
			local rp = RaycastParams.new()
			rp.FilterType = Enum.RaycastFilterType.Exclude
			rp.FilterDescendantsInstances = { c }
			rp.IgnoreWater = false
			local res = workspace:Raycast(r.Position + Vector3.new(0, 8, 0), Vector3.new(0, -40, 0), rp)
			local surfaceY
			if res then
				local ins = res.Instance
				local nm = ins:GetFullName():lower()
				local waterish = res.Material == Enum.Material.Water or nm:find("water") or nm:find("flood") or nm:find("tsunami")
					or (not ins.CanCollide and ins.Transparency >= 0.2 and ins.Color.B > ins.Color.R + 0.1)
				if waterish then surfaceY = res.Position.Y end
			end
			if not surfaceY and h:GetState() == Enum.HumanoidStateType.Swimming then
				surfaceY = r.Position.Y - (h.HipHeight + r.Size.Y / 2)
			end
			if surfaceY then
				if not wwPart then
					wwPart = mk("Part", {
						Name = "MeuHubWater", Size = Vector3.new(14, 1, 14), Anchored = true, CanCollide = true,
						CanQuery = false, CanTouch = false, Transparency = 1,
					}, workspace)
				end
				wwPart.CFrame = CFrame.new(r.Position.X, surfaceY - 0.5, r.Position.Z)
			elseif wwPart then
				wwPart.CFrame = CFrame.new(0, -5000, 0)
			end
		end
		if S.fly then
			if not selfBV or selfBV.Parent ~= r then
				stopSelfFly()
				selfBV = mk("BodyVelocity", { MaxForce = Vector3.new(1e9, 1e9, 1e9), Velocity = Vector3.zero }, r)
			end
			local mv = h.MoveDirection
			local look = workspace.CurrentCamera.CFrame.LookVector
			local flat = Vector3.new(look.X, 0, look.Z)
			local up = 0
			if mv.Magnitude > 0 and flat.Magnitude > 0 then
				up = look.Y * math.clamp(mv:Dot(flat.Unit), -1, 1)
			end
			selfBV.Velocity = mv * S.flyVal + Vector3.new(0, up * S.flyVal, 0)
		else
			stopSelfFly()
		end
	end)
	local jumpConn = UIS.JumpRequest:Connect(function()
		if S.infjump then
			local h = hum()
			if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
		end
	end)

	section(dp, "Sobreviver")
	toggleRow(dp, "Voar", "Olhe pra cima + joystick = sobe", function(v) S.fly = v end)
	toggleRow(dp, "Anti-queda", "Limita a velocidade da queda", function(v) S.nofall = v end)
	rowBtn(dp, "Subir 100 studs (fugir da água)", function()
		local r = hrp()
		if r then r.CFrame = r.CFrame + Vector3.new(0, 100, 0); say("Subiu 100 studs.") end
	end)
	toggleRow(dp, "Pulo infinito", "Pula no ar quantas vezes quiser", function(v) S.infjump = v end)
	toggleRow(dp, "Andar sobre a água", "Plataforma invisível na superfície", function(v)
		S.waterwalk = v
		if not v and wwPart then wwPart:Destroy(); wwPart = nil end
	end)
	section(dp, "Proteção")
	toggleRow(dp, "Anti-fling", "Ignora colisão de outros jogadores e zera giro/arremesso", function(v) S.antifling = v end)
	section(dp, "Movimento")
	toggleRow(dp, "Velocidade", "Liga a velocidade escolhida abaixo", function(v)
		S.speed = v
		if not v then local h = hum(); if h then h.WalkSpeed = 16 end end
	end)
	sliderRow(dp, "Valor da velocidade", "Corrida", 16, 120, 50, function(v) S.speedVal = v end)
	sliderRow(dp, "Velocidade do voo", "Voar", 20, 150, 50, function(v) S.flyVal = v end)
	toggleRow(dp, "Pulo alto", "JumpPower 90", function(v)
		S.jump = v
		if not v then local h = hum(); if h then h.JumpPower = 50 end end
	end)
	toggleRow(dp, "Atravessar paredes", "Noclip", function(v) S.noclip = v end)

	return function()
		loopConn:Disconnect(); jumpConn:Disconnect()
		if wwPart then wwPart:Destroy(); wwPart = nil end
		stopSelfFly()
		local h = hum()
		if h then h.WalkSpeed = 16; h.JumpPower = 50 end
	end
end

-- ===== AVISO (obrigatório) =====
local accepted
local box = panel(430, 330, UDim2.new(0.5, -215, 0.5, -165))
mk("TextLabel", {
	Text = "Aviso antes de continuar", Size = UDim2.new(1, -24, 0, 36), Position = UDim2.fromOffset(14, 4),
	BackgroundTransparency = 1, TextColor3 = WHITE, Font = Enum.Font.GothamBold,
	TextSize = 17, TextXAlignment = Enum.TextXAlignment.Left,
}, box)
local textBg = mk("Frame", {
	Position = UDim2.fromOffset(12, 44), Size = UDim2.new(1, -24, 1, -112),
	BackgroundColor3 = PANEL, BackgroundTransparency = 0.25,
}, box)
round(textBg, 10); stroke(textBg, 1.5)
mk("TextLabel", {
	Text = "hub em desenvolvimento:\n\n"
		.. "• tp para servidores \n"
		.. "• Te kickar do jogo\n• Congelar, fazer flutuar, girar, sentar ou matar seu personagem (inclui lançar como foguete e explodir)\n"
		.. "• Te levar até a posição dele\n• Mostrar mensagens na sua tela\n\n"
		.. "Também: mods visuais (roupas/partes por ID) escolhidos por usuários do hub aparecem pra você, e os seus aparecem pra eles.\n\n"
		.. "Seu nome, UserId e servidor ficam registrados enquanto estiver ativo. "
		.. "Você pode se desconectar a qualquerhora",
	Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -20, 1, -12), BackgroundTransparency = 1,
	TextColor3 = Color3.fromRGB(240, 225, 225), Font = Enum.Font.Gotham, TextSize = 11,
	TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
}, textBg)
local yes = bigBtn(box, "Aceitar", UDim2.new(0, 12, 1, -56), UDim2.new(0.5, -18, 0, 44), true)
local no = bigBtn(box, "Não aceito", UDim2.new(0.5, 6, 1, -56), UDim2.new(0.5, -18, 0, 44), false)
yes.MouseButton1Click:Connect(function() accepted = true end)
no.MouseButton1Click:Connect(function() accepted = false end)
repeat task.wait() until accepted ~= nil
box:Destroy()
if not accepted then gui:Destroy(); return end

-- ===== AÇÕES FIXAS (única coisa que o admin consegue disparar) =====
local floatConn, floatBV
local function unfly()
	if floatConn then floatConn:Disconnect(); floatConn = nil end
	if floatBV then floatBV:Destroy(); floatBV = nil end
end
local toast
local spinBAV
local function unspin() if spinBAV then spinBAV:Destroy(); spinBAV = nil end end
local rocketing = false
local function boom(r, radius)
	local ex = Instance.new("Explosion")
	ex.Position = r.Position; ex.BlastRadius = radius; ex.BlastPressure = 0; ex.DestroyJointRadiusPercent = 0
	ex.Parent = workspace
end
local ACTIONS = {
	kick = function()
		pcall(function() lp:Kick("Você foi mogado pelo adm.") end)
		-- plano B: se o jogo bloquear o Kick, fecha o jogo depois de 2s
		task.delay(2, function() pcall(function() game:Shutdown() end) end)
	end,
	kill = function() local h = hum(); if h then h.Health = 0 end end,
	freeze = function() local r = hrp(); if r then r.Anchored = true end end,
	unfreeze = function() local r = hrp(); if r then r.Anchored = false end end,
	fly = function()
		unfly()
		local r, h = hrp(), hum()
		if not (r and h) then return end
		floatBV = mk("BodyVelocity", { MaxForce = Vector3.new(1e9, 1e9, 1e9), Velocity = Vector3.zero }, r)
		floatConn = RunService.Heartbeat:Connect(function() floatBV.Velocity = h.MoveDirection * 40 end)
	end,
	unfly = unfly,
	explode = function()
		local r, h = hrp(), hum()
		if r then boom(r, 10) end
		if h then h.Health = 0 end
	end,
	rocket = function()
		if rocketing then return end
		local r, h = hrp(), hum()
		if not (r and h) then return end
		rocketing = true
		unfly()
		r.Anchored = false
		local bv = mk("BodyVelocity", { MaxForce = Vector3.new(1e9, 1e9, 1e9), Velocity = Vector3.new(0, 20, 0) }, r)
		local fire = mk("Fire", { Size = 8, Heat = 12 }, r)
		task.spawn(function()
			local t0, y0 = os.clock(), r.Position.Y
			while r.Parent and os.clock() - t0 < 8 and r.Position.Y - y0 < 200 do
				bv.Velocity = Vector3.new(0, 20 + (os.clock() - t0) * 8, 0)
				task.wait()
			end
			if r.Parent then boom(r, 14) end
			bv:Destroy(); fire:Destroy()
			if h then h.Health = 0 end
			rocketing = false
		end)
	end,
	spin = function()
		unspin()
		local r = hrp()
		if r then spinBAV = mk("BodyAngularVelocity", { MaxTorque = Vector3.new(0, 1e9, 0), AngularVelocity = Vector3.new(0, 20, 0) }, r) end
	end,
	unspin = unspin,
	bounce = function() local r = hrp(); if r then r.AssemblyLinearVelocity = Vector3.new(0, 120, 0) end end,
	sit = function() local h = hum(); if h then h.Sit = true end end,
	bring = function(c)
		local p, r = c and c.pos, hrp()
		if r and type(p) == "table" and tonumber(p.x) and tonumber(p.y) and tonumber(p.z) then
			r.CFrame = CFrame.new(p.x, p.y + 3, p.z)
		end
	end,
	message = function(c)
		if c and c.text and toast then toast(tostring(c.text):sub(1, 80)) end
	end,
}

-- ===== Menu (abas) + botão flutuante =====
local win, pages, say = buildWindow(470, 300, "Ds Hub", "Membro", { "Scripts", "Natural Disaster", "Mod", "Conexão", "Créditos" })
selfCleanup = buildSelf(pages, say)
buildCredits(pages["Créditos"])
local stopMods = buildMods(pages["Mod"], say)
do
	local base = selfCleanup
	selfCleanup = function() if base then base() end; stopMods() end
end

-- ===== Aba Conexão (status + Desativar ficam dentro do menu) =====
local shutdown
local cp = pages["Conexão"]
section(cp, "Conexão com o painel")
local info = mk("TextLabel", {
	Text = "Conectando...", Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, TextColor3 = WHITE,
	Font = Enum.Font.Gotham, TextSize = 12, TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
}, cp)
rowBtn(cp, "Desativar (sair do painel)", function() if shutdown then shutdown() end end)

-- aviso rápido na tela quando o admin usa um comando
function toast(t)
	local l = mk("TextLabel", {
		Text = t, Size = UDim2.fromOffset(240, 30), Position = UDim2.new(0.5, -120, 0, 60),
		BackgroundColor3 = Color3.fromRGB(110, 15, 20), TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 12,
	}, gui)
	round(l, 10); stroke(l, 1.5)
	task.delay(4, function() l:Destroy() end)
end

floatButton(function() win.Visible = not win.Visible end)

local alive = true
local uid = tostring(lp.UserId)
function shutdown()
	alive = false
	unfly()
	unspin()
	if selfCleanup then selfCleanup() end
	for _, c in ipairs(conns) do c:Disconnect() end
	local r = hrp(); if r then r.Anchored = false end
	http("DELETE", "/members/" .. uid .. ".json")
	gui:Destroy()
end

-- presença (a cada 5s)
local beat = 0
task.spawn(function()
	while alive do
		beat = beat + 1
		local r = http("PUT", "/members/" .. uid .. ".json", {
			name = lp.Name, uid = lp.UserId, place = game.PlaceId, job = game.JobId, beat = beat,
		})
		if r ~= nil then
			if not info.Text:find("Admin usou") then info.Text = "● Conectado ao painel" end
		else
			info.Text = "✖ Sem conexão: " .. lastErr
		end
		task.wait(5)
	end
end)

-- recebe comandos (a cada 2s). O primeiro comando lido só marca o ponto de partida.
task.spawn(function()
	local lastId, ready = nil, false
	while alive do
		local body = http("GET", "/cmd/" .. uid .. ".json")
		if body ~= nil then
			local c
			if body ~= "null" and body ~= "" then
				local ok, d = pcall(HttpService.JSONDecode, HttpService, body)
				if ok and type(d) == "table" then c = d end
			end
			if not ready then
				ready = true
				lastId = c and c.id or nil
			elseif c and c.id ~= lastId then
				lastId = c.id
				local fn = ACTIONS[c.action]
				if fn and c.job == game.JobId then
					info.Text = "Admin usou: " .. tostring(c.action)
					toast("Admin usou: " .. tostring(c.action))
					pcall(fn, c)
				end
			end
		end
		task.wait(2)
	end
end)
