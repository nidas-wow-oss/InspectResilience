--------------------------------------------------------------
-- Inspect Stats Panel v2.8 - WoW 3.3.5a
-- v2.8: Wider arrow, stable position, lower on frame
--------------------------------------------------------------

local ADDON_NAME = "InspectResilience"
local EQUIP_SLOTS = { 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18 }

--------------------------------------------------------------
-- STAT PATTERNS
--------------------------------------------------------------
local STAT_PATTERNS = {
    { "%+(%d+) Stamina",             "STA" },
    { "^(%d+) Stamina",              "STA" },
    { "%+(%d+) Strength",            "STR" },
    { "^(%d+) Strength",             "STR" },
    { "%+(%d+) Agility",             "AGI" },
    { "^(%d+) Agility",              "AGI" },
    { "%+(%d+) Intellect",           "INT" },
    { "^(%d+) Intellect",            "INT" },
    { "%+(%d+) Spirit",              "SPI" },
    { "^(%d+) Spirit",               "SPI" },
    { "^(%d+) Armor",                "ARMOR" },
    { "%+(%d+) [Rr]esilience [Rr]ating", "RESILIENCE" },
    { "[Rr]esilience [Rr]ating by (%d+)", "RESILIENCE" },
    { "%+(%d+) [Rr]esilience",            "RESILIENCE" },
    { "temple en (%d+)",                   "RESILIENCE" },
    { "%+(%d+) de temple",                 "RESILIENCE" },
    { "%+(%d+) temple",                    "RESILIENCE" },
    { "[Aa]ttack [Pp]ower by (%d+)",  "AP" },
    { "%+(%d+) [Aa]ttack [Pp]ower",   "AP" },
    { "[Ss]pell [Pp]ower by (%d+)",   "SP" },
    { "%+(%d+) [Ss]pell [Pp]ower",    "SP" },
    { "[Cc]ritical [Ss]trike [Rr]ating by (%d+)", "CRIT" },
    { "%+(%d+) [Cc]ritical [Ss]trike [Rr]ating",  "CRIT" },
    { "%+(%d+) [Cc]rit [Rr]ating",                "CRIT" },
    { "[Hh]it [Rr]ating by (%d+)",    "HIT" },
    { "%+(%d+) [Hh]it [Rr]ating",     "HIT" },
    { "[Hh]aste [Rr]ating by (%d+)",  "HASTE" },
    { "%+(%d+) [Hh]aste [Rr]ating",   "HASTE" },
    { "[Aa]rmor [Pp]enetration [Rr]ating by (%d+)", "ARPEN" },
    { "%+(%d+) [Aa]rmor [Pp]enetration [Rr]ating",  "ARPEN" },
    { "[Ee]xpertise [Rr]ating by (%d+)", "EXPERTISE" },
    { "%+(%d+) [Ee]xpertise [Rr]ating",  "EXPERTISE" },
    { "[Dd]efense [Rr]ating by (%d+)", "DEFENSE" },
    { "%+(%d+) [Dd]efense [Rr]ating",  "DEFENSE" },
    { "[Dd]odge [Rr]ating by (%d+)",   "DODGE" },
    { "%+(%d+) [Dd]odge [Rr]ating",    "DODGE" },
    { "[Pp]arry [Rr]ating by (%d+)",   "PARRY" },
    { "%+(%d+) [Pp]arry [Rr]ating",    "PARRY" },
    { "[Bb]lock [Rr]ating by (%d+)",   "BLOCKRATING" },
    { "%+(%d+) [Bb]lock [Rr]ating",    "BLOCKRATING" },
    { "[Bb]lock [Vv]alue .+ by (%d+)", "BLOCKVALUE" },
    { "^(%d+) Block",                   "BLOCKVALUE" },
    { "(%d+) [Mm]ana [Pp]er 5",        "MP5" },
    { "(%d+) [Mm]ana every 5",         "MP5" },
    { "(%d+) [Hh]ealth [Pp]er 5",      "HP5" },
    { "(%d+) [Hh]ealth every 5",       "HP5" },
    { "[Ss]pell [Pp]enetration by (%d+)", "SPELLPEN" },
    { "%+(%d+) [Ss]pell [Pp]enetration",  "SPELLPEN" },
}

local STAT_DISPLAY = {
    { key = "AP",         name = "Attack Power",     cat = "O" },
    { key = "SP",         name = "Spell Power",      cat = "O" },
    { key = "CRIT",       name = "Crit Rating",      cat = "O" },
    { key = "HIT",        name = "Hit Rating",       cat = "O" },
    { key = "HASTE",      name = "Haste Rating",     cat = "O" },
    { key = "ARPEN",      name = "Armor Pen",        cat = "O" },
    { key = "EXPERTISE",  name = "Expertise",        cat = "O" },
    { key = "SPELLPEN",   name = "Spell Pen",        cat = "O" },
    { key = "ARMOR",      name = "Armor",            cat = "D" },
    { key = "DEFENSE",    name = "Defense Rating",   cat = "D" },
    { key = "DODGE",      name = "Dodge Rating",     cat = "D" },
    { key = "PARRY",      name = "Parry Rating",     cat = "D" },
    { key = "BLOCKRATING",name = "Block Rating",     cat = "D" },
    { key = "BLOCKVALUE", name = "Block Value",      cat = "D" },
    { key = "MP5",        name = "MP5",              cat = "R" },
    { key = "HP5",        name = "HP5",              cat = "R" },
}

local BASE_STATS = {
    { key = "STR", name = "STR" },
    { key = "AGI", name = "AGI" },
    { key = "STA", name = "STA" },
    { key = "INT", name = "INT" },
    { key = "SPI", name = "SPI" },
}

local RATING_BASE_80 = {
    RESILIENCE = 81.97, CRIT = 45.91, HIT = 32.79, HASTE = 32.79,
    EXPERTISE = 8.20, DEFENSE = 4.92, DODGE = 39.35, PARRY = 39.35,
    BLOCKRATING = 16.39, ARPEN = 13.99,
}

local function RatingPct(key, val)
    local b = RATING_BASE_80[key]
    if b and val and val > 0 then return val / b end
end

--------------------------------------------------------------
-- Hidden tooltip
--------------------------------------------------------------
local scanTip = CreateFrame("GameTooltip", "ISPScanTip", UIParent, "GameTooltipTemplate")
scanTip:SetOwner(UIParent, "ANCHOR_NONE")

local scannedSetBonuses = {}

local function ScanLineForAllStats(line, stats)
    local matched = {}
    for _, pat in ipairs(STAT_PATTERNS) do
        local val = line:match(pat[1])
        if val then
            local key = pat[2]
            if not matched[key] then
                matched[key] = true
                stats[key] = (stats[key] or 0) + tonumber(val)
            end
        end
    end
end

local function ScanSlotStats(unit, slot, stats)
    scanTip:ClearLines()
    scanTip:SetOwner(UIParent, "ANCHOR_NONE")
    scanTip:SetInventoryItem(unit, slot)
    local n = scanTip:NumLines()
    if not n or n == 0 then return end

    -- PRIMERA PASADA: encontrar a que CONJUNTO pertenece la pieza.
    --
    -- Hace falta para deduplicar bien los bonus. La linea del encabezado es
    -- del estilo "Wrathful Gladiator's Investiture (2/5)" y viene en gris,
    -- asi que se busca aparte del bucle de stats (que descarta el gris).
    local setName
    for i = 2, n do
        local obj = _G["ISPScanTipTextLeft" .. i]
        local line = obj and obj:GetText()
        if line then
            local nm = line:match("^(.+) %(%d+/%d+%)%s*$")
            if nm then setName = nm; break end
        end
    end

    for i = 2, n do
        local obj = _G["ISPScanTipTextLeft" .. i]
        if obj then
            local line = obj:GetText()
            if line then
                local r, g, b = obj:GetTextColor()
                r, g, b = math.ceil(r * 255), math.ceil(g * 255), math.ceil(b * 255)
                local isGray = (r == 128 and g == 128 and b == 128)
                if not isGray and not line:find("^Use:") then
                    if line:find("^Set:") then
                        -- LA CLAVE INCLUYE EL NOMBRE DEL CONJUNTO.
                        --
                        -- Antes se deduplicaba por el texto de la linea sola.
                        -- Varias clases tienen DOS conjuntos de arena del
                        -- mismo tier (el sacerdote uno con critico y otro con
                        -- espiritu; el chaman uno con critico y otro con mp5)
                        -- y los dos otorgan la misma linea literal:
                        --     "Set: +100 resilience rating."
                        -- Con la clave por texto, el segundo conjunto se
                        -- descartaba como repetido y faltaban 100 de temple.
                        -- Con el nombre adelante, cada conjunto cuenta el suyo.
                        local key = (setName or "?") .. "|" .. line
                        if not scannedSetBonuses[key] then
                            scannedSetBonuses[key] = true
                            ScanLineForAllStats(line, stats)
                        end
                    else
                        ScanLineForAllStats(line, stats)
                    end
                end
            end
        end
    end
end

local function ScanGearStats(unit)
    local stats = {}
    local itemCount, iLvlTotal, iLvlCount = 0, 0, 0
    wipe(scannedSetBonuses)

    for _, slot in ipairs(EQUIP_SLOTS) do
        local link = GetInventoryItemLink(unit, slot)
        if link then
            itemCount = itemCount + 1
            ScanSlotStats(unit, slot, stats)
            local _, _, _, iLvl = GetItemInfo(link)
            if iLvl then
                if slot == 16 and not GetInventoryItemLink(unit, 17) then
                    iLvlTotal = iLvlTotal + (iLvl * 2); iLvlCount = iLvlCount + 2
                else
                    iLvlTotal = iLvlTotal + iLvl; iLvlCount = iLvlCount + 1
                end
            end
        end
    end
    return stats, itemCount, iLvlCount > 0 and (iLvlTotal / 16) or 0
end

local function ScanSlotResilience(unit, slot)
    local total = 0
    scanTip:ClearLines()
    scanTip:SetOwner(UIParent, "ANCHOR_NONE")
    scanTip:SetInventoryItem(unit, slot)
    local n = scanTip:NumLines()
    if not n or n == 0 then return 0 end
    for i = 2, n do
        local obj = _G["ISPScanTipTextLeft" .. i]
        if obj then
            local line = obj:GetText()
            if line then
                local r, g, b = obj:GetTextColor()
                r, g, b = math.ceil(r * 255), math.ceil(g * 255), math.ceil(b * 255)
                if not (r == 128 and g == 128 and b == 128) and not line:find("^Use:") and not line:find("^Set:") then
                    for _, pat in ipairs(STAT_PATTERNS) do
                        if pat[2] == "RESILIENCE" then
                            local val = line:match(pat[1])
                            if val then total = total + tonumber(val) end
                        end
                    end
                end
            end
        end
    end
    return total
end

--------------------------------------------------------------
-- Player real stats via API (for /isp test)
--------------------------------------------------------------
local function GetPlayerRealStats()
    local stats = {}
    local _, str = UnitStat("player", 1); stats.STR = str or 0
    local _, agi = UnitStat("player", 2); stats.AGI = agi or 0
    local _, sta = UnitStat("player", 3); stats.STA = sta or 0
    local _, int = UnitStat("player", 4); stats.INT = int or 0
    local _, spi = UnitStat("player", 5); stats.SPI = spi or 0
    local _, armor = UnitArmor("player"); stats.ARMOR = armor or 0
    stats.RESILIENCE = GetCombatRating(16) or 0
    stats.CRIT = GetCombatRating(9) or 0
    stats.HIT = GetCombatRating(6) or 0
    stats.HASTE = GetCombatRating(18) or 0
    stats.ARPEN = GetCombatRating(25) or 0
    stats.EXPERTISE = GetCombatRating(24) or 0
    stats.DEFENSE = GetCombatRating(2) or 0
    stats.DODGE = GetCombatRating(3) or 0
    stats.PARRY = GetCombatRating(4) or 0
    stats.BLOCKRATING = GetCombatRating(5) or 0
    local sc = GetCombatRating(11) or 0; if sc > stats.CRIT then stats.CRIT = sc end
    local sh = GetCombatRating(8) or 0; if sh > stats.HIT then stats.HIT = sh end
    local sha = GetCombatRating(20) or 0; if sha > stats.HASTE then stats.HASTE = sha end
    local ab, ap, an = UnitAttackPower("player")
    stats.AP = (ab or 0) + (ap or 0) + (an or 0)
    local maxSP = 0
    for s = 2, 7 do local sp = GetSpellBonusDamage(s); if sp and sp > maxSP then maxSP = sp end end
    stats.SP = maxSP
    local bm = GetManaRegen()
    if bm and bm > 0 then stats.MP5 = math.floor(bm * 5) end
    local bv = GetShieldBlock and GetShieldBlock() or 0
    if bv > 0 then stats.BLOCKVALUE = bv end
    local iT, iC, iN = 0, 0, 0
    for _, slot in ipairs(EQUIP_SLOTS) do
        local link = GetInventoryItemLink("player", slot)
        if link then
            iN = iN + 1; local _, _, _, iLvl = GetItemInfo(link)
            if iLvl then
                if slot == 16 and not GetInventoryItemLink("player", 17) then
                    iT = iT + iLvl * 2; iC = iC + 2
                else iT = iT + iLvl; iC = iC + 1 end
            end
        end
    end
    return stats, iN, iC > 0 and (iT / 16) or 0
end

--------------------------------------------------------------
-- STATE
--------------------------------------------------------------
local lastStats = {}
local lastUnit = nil
local panelShown = true
local chatPrintsEnabled = false  -- toggle with /isp chat

--------------------------------------------------------------
-- PANEL UI (BIGGER)
--------------------------------------------------------------
local panel = CreateFrame("Frame", "InspectStatsPanel", UIParent)
panel:SetWidth(230)
panel:SetHeight(440)
panel:SetFrameStrata("HIGH")
panel:EnableMouse(true); panel:SetClampedToScreen(true)
panel:Hide()
panel:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
panel:SetBackdropColor(0, 0, 0, 0.93)
panel:SetBackdropBorderColor(0.6, 0.2, 0.8, 1)

-- Title
local titleText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
titleText:SetPoint("TOP", 0, -10)
titleText:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
titleText:SetText("|cff00ff99Inspect Stats|r")

-- Player name
local nameText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
nameText:SetPoint("TOP", titleText, "BOTTOM", 0, -2)
nameText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")

-- iLvl
local ilvlText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
ilvlText:SetPoint("TOP", nameText, "BOTTOM", 0, -2)
ilvlText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")

--------------------------------------------------------------
-- RESILIENCE BOX - NOW WITH TOOLTIP (only here)
--------------------------------------------------------------
local resBg = CreateFrame("Frame", nil, panel)
resBg:SetWidth(210); resBg:SetHeight(56)
resBg:SetPoint("TOP", ilvlText, "BOTTOM", 0, -5)
resBg:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
})
resBg:SetBackdropColor(0.15, 0.08, 0.25, 0.9)
resBg:SetBackdropBorderColor(0.58, 0.35, 0.85, 0.8)
resBg:EnableMouse(true)  -- Enable mouse for tooltip on resilience box ONLY

local resIcon = resBg:CreateTexture(nil, "ARTWORK")
resIcon:SetSize(26, 26); resIcon:SetPoint("LEFT", 8, -4)
resIcon:SetTexture("Interface\\PaperDollInfoFrame\\SpellSchoolIcon7")

local resLabel = resBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
resLabel:SetPoint("TOPLEFT", resBg, "TOPLEFT", 42, -6)
resLabel:SetText("|cff9482c9Resilience|r")
resLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "")

local resValue = resBg:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
resValue:SetPoint("TOPLEFT", resBg, "TOPLEFT", 42, -20)
resValue:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")

local resPct = resBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
resPct:SetPoint("RIGHT", resBg, "RIGHT", -8, 0)
resPct:SetFont("Fonts\\FRIZQT__.TTF", 11, "")

--------------------------------------------------------------
-- BASE STATS ROW
--------------------------------------------------------------
local baseLine = CreateFrame("Frame", nil, panel)
baseLine:SetWidth(210); baseLine:SetHeight(22)
baseLine:SetPoint("TOP", resBg, "BOTTOM", 0, -4)

local baseLabels = {}
for i, st in ipairs(BASE_STATS) do
    local f = CreateFrame("Frame", nil, baseLine)
    f:SetWidth(41); f:SetHeight(22)
    if i == 1 then f:SetPoint("LEFT", baseLine, "LEFT", 1, 0)
    else f:SetPoint("LEFT", baseLabels[i - 1].f, "RIGHT", 1, 0) end
    f.lbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.lbl:SetPoint("TOP", 0, 0); f.lbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    f.lbl:SetText("|cff777777" .. st.name .. "|r")
    f.val = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.val:SetPoint("TOP", f.lbl, "BOTTOM", 0, -1); f.val:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    baseLabels[i] = { f = f, val = f.val, key = st.key }
end

--------------------------------------------------------------
-- STAT LINES (bigger text)
--------------------------------------------------------------
local MAX_LINES = 22
local LINE_H = 15
local statLines = {}
for i = 1, MAX_LINES do
    local line = CreateFrame("Frame", nil, panel)
    line:SetWidth(208); line:SetHeight(LINE_H)
    if i == 1 then line:SetPoint("TOPLEFT", baseLine, "BOTTOMLEFT", 2, -5)
    else line:SetPoint("TOPLEFT", statLines[i - 1], "BOTTOMLEFT") end
    line.left = line:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    line.left:SetPoint("LEFT"); line.left:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    line.right = line:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    line.right:SetPoint("RIGHT"); line.right:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    line:Hide(); statLines[i] = line
end

-- Footer REMOVED (no more "Click: /say | R-Click: party")

--------------------------------------------------------------
-- ARROW TAB - Nidhaus texture, NO border, wide+tall tab
--------------------------------------------------------------
local arrowBtn = CreateFrame("Button", "ISP_ArrowTab", UIParent)
arrowBtn:SetWidth(25); arrowBtn:SetHeight(50)
arrowBtn:SetFrameStrata("HIGH"); arrowBtn:EnableMouse(true); arrowBtn:Hide()
arrowBtn:SetMovable(false)

-- NO backdrop - clean arrow only
local arrowTex = arrowBtn:CreateTexture(nil, "OVERLAY")
arrowTex:SetAllPoints(arrowBtn)
arrowTex:SetTexture("Interface\\AddOns\\Nidhaus_UnitFrames\\Media\\RaidPanel-Toggle")

-- Fallback
local arrowFallbackChecked = false
local function EnsureArrowTexture()
    if arrowFallbackChecked then return end
    arrowFallbackChecked = true
    local checkFrame = CreateFrame("Frame")
    local elapsed = 0
    checkFrame:SetScript("OnUpdate", function(self, dt)
        elapsed = elapsed + dt
        if elapsed >= 0.3 then
            self:SetScript("OnUpdate", nil)
            if not arrowTex:GetTexture() or arrowTex:GetTexture() == "" then
                arrowTex:SetTexture("Interface\\BUTTONS\\UI-SpellbookIcon-NextPage-Up")
            end
        end
    end)
end

local function UpdateArrowVisual()
    -- Mirrored horizontally, always fixed
    arrowTex:SetTexCoord(1, 0.5, 0, 1)
end

arrowBtn:SetScript("OnClick", function()
    panelShown = not panelShown
    if panelShown then panel:Show() else panel:Hide() end
    UpdateArrowVisual()
    -- Do NOT reposition - arrow stays in place
end)
arrowBtn:SetScript("OnEnter", function(self)
    arrowTex:SetVertexColor(1, 0.8, 0.2, 1)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(panelShown and "Hide Stats" or "Show Stats", 1, 0.82, 0)
    GameTooltip:Show()
end)
arrowBtn:SetScript("OnLeave", function(self)
    arrowTex:SetVertexColor(1, 1, 1, 1)
    GameTooltip:Hide()
end)

--------------------------------------------------------------
-- POSITIONING - Arrow stable, lower, on InspectFrame border
--------------------------------------------------------------
local arrowPositioned = false

local function PositionArrow()
    if not InspectFrame then return end
    arrowBtn:ClearAllPoints()
    arrowBtn:SetParent(InspectFrame)
    -- Pegada al borde derecho del InspectFrame, hacia la izquierda
    arrowBtn:SetPoint("RIGHT", InspectFrame, "RIGHT", -8, -10)
    arrowBtn:SetFrameLevel(InspectFrame:GetFrameLevel() + 10)
    arrowPositioned = true
end

local function PositionPanel()
    if not InspectFrame then return end
    panel:ClearAllPoints()
    panel:SetParent(InspectFrame)
    panel:SetPoint("TOPLEFT", InspectFrame, "TOPRIGHT", 4, 0)
    panel:SetFrameLevel(InspectFrame:GetFrameLevel() + 5)
end

local function PositionAll()
    if not InspectFrame then return end
    if not arrowPositioned then
        PositionArrow()
    end
    PositionPanel()
    EnsureArrowTexture()
end

--------------------------------------------------------------
-- FIND UNIT
--------------------------------------------------------------
local function GetInspectUnit()
    if InspectFrame and InspectFrame.unit and UnitExists(InspectFrame.unit) then
        return InspectFrame.unit
    end
    if UnitExists("target") and UnitIsPlayer("target") then return "target" end
    return nil
end

--------------------------------------------------------------
-- POPULATE PANEL
--------------------------------------------------------------
local function PopulatePanel(stats, itemCount, avgILvl, unit)
    lastStats = stats
    lastUnit = unit

    local name = UnitName(unit) or "???"
    local _, classToken = UnitClass(unit)
    local cc = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[classToken]
    if cc then
        nameText:SetText(string.format("|cff%.2x%.2x%.2x%s|r", cc.r * 255, cc.g * 255, cc.b * 255, name))
    else nameText:SetText(name) end

    ilvlText:SetText(string.format("|cffaaaaaa%d items | iLvl: |cffffff00%.1f|r", itemCount, avgILvl))

    -- Resilience
    local res = stats.RESILIENCE or 0
    resValue:SetText(tostring(res))
    resPct:SetText(string.format("|cff9482c9-%.1f%%|r", res / 81.97))
    if res >= 1000 then resValue:SetTextColor(1, 0.5, 0)
    elseif res >= 600 then resValue:SetTextColor(1, 1, 0)
    elseif res >= 300 then resValue:SetTextColor(0, 1, 0)
    elseif res > 0 then resValue:SetTextColor(1, 1, 1)
    else resValue:SetTextColor(0.5, 0.5, 0.5) end

    -- Base stats
    for _, bs in ipairs(baseLabels) do
        local v = stats[bs.key] or 0
        bs.val:SetText(v > 0 and tostring(v) or "|cff444444-|r")
    end

    -- Build display
    local data = {}
    local lastCat = nil
    for _, si in ipairs(STAT_DISPLAY) do
        local v = stats[si.key] or 0
        if v > 0 then
            if si.cat ~= lastCat then
                local h = si.cat == "O" and "|cff4fc3f7--- Offense ---|r"
                    or si.cat == "D" and "|cffFFD700--- Defense ---|r"
                    or "|cff66bb6a--- Regen ---|r"
                data[#data + 1] = { hdr = true, text = h }
                lastCat = si.cat
            end
            local pStr = ""
            local pct = RatingPct(si.key, v)
            if pct then pStr = string.format(" |cff888888(%.1f%%)|r", pct) end
            data[#data + 1] = { name = si.name, val = v, pStr = pStr }
        end
    end

    for i = 1, MAX_LINES do
        local line = statLines[i]; local d = data[i]
        if d then
            if d.hdr then line.left:SetText(d.text); line.right:SetText("")
            else
                line.left:SetText("  " .. d.name); line.left:SetTextColor(0.85, 0.85, 0.85)
                line.right:SetText(string.format("|cffffff00%d|r%s", d.val, d.pStr))
            end
            line:Show()
        else line:Hide() end
    end

    -- Dynamic height (reduced bottom padding, no footer)
    local numLines = math.min(#data, MAX_LINES)
    local h = 10 + 16 + 14 + 12 + 5 + 56 + 4 + 22 + 5 + (numLines * LINE_H) + 10
    panel:SetHeight(math.max(h, 200))

    PositionAll()
    arrowBtn:Show()
    if panelShown then panel:Show() end
    UpdateArrowVisual()

    if chatPrintsEnabled then
        DEFAULT_CHAT_FRAME:AddMessage(string.format(
            "|cff00ff99[InspectStats]|r %s: |cff9482c9%d|r res | iLvl: |cffffff00%.1f|r | %d items",
            name, res, avgILvl, itemCount))
    end
end

--------------------------------------------------------------
-- UPDATE PANEL
--------------------------------------------------------------
local function UpdatePanel()
    if not InspectFrame or not InspectFrame:IsShown() then
        panel:Hide(); arrowBtn:Hide(); return
    end
    local unit = GetInspectUnit()
    if not unit then panel:Hide(); arrowBtn:Hide(); return end

    local stats, itemCount, avgILvl = ScanGearStats(unit)
    if itemCount == 0 then
        local elapsed = 0; local f = CreateFrame("Frame")
        f:SetScript("OnUpdate", function(self, dt)
            elapsed = elapsed + dt
            if elapsed >= 1.2 then
                self:SetScript("OnUpdate", nil)
                if InspectFrame and InspectFrame:IsShown() then
                    local u = GetInspectUnit()
                    if u then
                        local s, ic, ai = ScanGearStats(u)
                        if ic > 0 then PopulatePanel(s, ic, ai, u) end
                    end
                end
            end
        end)
        return
    end
    PopulatePanel(stats, itemCount, avgILvl, unit)
end

--------------------------------------------------------------
-- TOOLTIP: per-piece resilience ON RESILIENCE BOX ONLY
--------------------------------------------------------------
resBg:SetScript("OnEnter", function(self)
    if not lastUnit or not UnitExists(lastUnit) then return end
    GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
    GameTooltip:SetText("Resilience Detail", 0.58, 0.51, 0.79)
    GameTooltip:AddLine(" ")
    local totalTip = 0
    for _, slot in ipairs(EQUIP_SLOTS) do
        local link = GetInventoryItemLink(lastUnit, slot)
        if link then
            local r = ScanSlotResilience(lastUnit, slot)
            if r > 0 then
                local n = GetItemInfo(link) or "???"
                GameTooltip:AddDoubleLine(n, string.format("|cff9482c9%d|r", r), 1, 1, 1)
                totalTip = totalTip + r
            end
        end
    end
    if totalTip > 0 then
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("Gear Total", string.format("|cff9482c9%d|r", totalTip), 0.8, 0.8, 0.2)
    end
    local setBonus = (lastStats.RESILIENCE or 0) - totalTip
    if setBonus > 0 then
        GameTooltip:AddDoubleLine("Set Bonus", string.format("|cffa335ee+%d|r", setBonus), 0.8, 0.8, 0.2)
    end
    GameTooltip:Show()
end)
resBg:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- Panel has NO OnEnter/OnLeave (tooltip removed from panel)
-- Panel has NO OnMouseUp (chat report removed)

--------------------------------------------------------------
-- HOOK INSPECT FRAME
--------------------------------------------------------------
local hooked = false
local function HookInspectFrame()
    if not InspectFrame or hooked then return end
    hooked = true
    InspectFrame:HookScript("OnShow", function()
        local e = 0; local f = CreateFrame("Frame")
        f:SetScript("OnUpdate", function(self, dt)
            e = e + dt; if e >= 0.8 then self:SetScript("OnUpdate", nil); UpdatePanel() end
        end)
    end)
    InspectFrame:HookScript("OnHide", function()
        panel:Hide(); arrowBtn:Hide()
        arrowPositioned = false
    end)
end

--------------------------------------------------------------
-- AUTO-INSPECT ON TARGET CHANGE
--------------------------------------------------------------
local function AutoInspectTarget()
    if not UnitExists("target") then
        if InspectFrame and InspectFrame:IsShown() then
            panel:Hide(); arrowBtn:Hide()
        end
        return
    end
    if not UnitIsPlayer("target") then return end
    if UnitIsUnit("target", "player") then return end
    if not CanInspect("target") then return end

    NotifyInspect("target")
    local e = 0; local f = CreateFrame("Frame")
    f:SetScript("OnUpdate", function(self, dt)
        e = e + dt
        if e >= 1.2 then
            self:SetScript("OnUpdate", nil)
            if InspectFrame and InspectFrame:IsShown() then UpdatePanel() end
        end
    end)
end

--------------------------------------------------------------
-- EVENTS
--------------------------------------------------------------
local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("INSPECT_READY")
ev:RegisterEvent("PLAYER_TARGET_CHANGED")

ev:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON_NAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff99[InspectStats v2.8]|r Loaded. /isp chat = toggle prints")
            HookInspectFrame()
        elseif arg1 == "Blizzard_InspectUI" then
            HookInspectFrame()
        end
    elseif event == "INSPECT_READY" then
        local e = 0; local f = CreateFrame("Frame")
        f:SetScript("OnUpdate", function(self, dt)
            e = e + dt
            if e >= 1.0 then self:SetScript("OnUpdate", nil); HookInspectFrame(); UpdatePanel() end
        end)
    elseif event == "PLAYER_TARGET_CHANGED" then
        if InspectFrame and InspectFrame:IsShown() then
            AutoInspectTarget()
        else panel:Hide(); arrowBtn:Hide() end
    end
end)

HookInspectFrame()

--------------------------------------------------------------
-- SLASH COMMANDS
--------------------------------------------------------------
SLASH_INSPECTRES1 = "/ires"
SLASH_INSPECTRES2 = "/isp"
SLASH_INSPECTRES3 = "/inspectstats"
SlashCmdList["INSPECTRES"] = function(msg)
    msg = strtrim(msg or ""):lower()
    if msg == "chat" then
        chatPrintsEnabled = not chatPrintsEnabled
        if chatPrintsEnabled then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff99[InspectStats]|r Chat prints: |cff00ff00ON|r")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff99[InspectStats]|r Chat prints: |cffff0000OFF|r")
        end
    elseif msg == "test" or msg == "self" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff99[InspectStats]|r === Your Stats ===")
        local stats, pieces, avgILvl = GetPlayerRealStats()
        DEFAULT_CHAT_FRAME:AddMessage(string.format("  |cffaaaaaa%d items | iLvl Avg: |cffffff00%.1f|r", pieces, avgILvl))
        local res = stats.RESILIENCE or 0
        DEFAULT_CHAT_FRAME:AddMessage(string.format("  |cff9482c9Resilience|r: |cffffffff%d|r (%.1f%% reduction)", res, res / 81.97))
        for _, si in ipairs(STAT_DISPLAY) do
            local v = stats[si.key] or 0
            if v > 0 and si.key ~= "RESILIENCE" then
                local p = ""; local pct = RatingPct(si.key, v)
                if pct then p = string.format(" (%.1f%%)", pct) end
                DEFAULT_CHAT_FRAME:AddMessage(string.format("  |cffffffff%s|r: |cff00ff00%d|r%s", si.name, v, p))
            end
        end
        local b = "  Base: "
        for _, bs in ipairs(BASE_STATS) do
            local v = stats[bs.key] or 0
            if v > 0 then b = b .. string.format("%s:|cffffffff%d|r  ", bs.name, v) end
        end
        DEFAULT_CHAT_FRAME:AddMessage(b)
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff99[InspectStats]|r Commands:")
        DEFAULT_CHAT_FRAME:AddMessage("  /isp test - Show your detailed stats")
        DEFAULT_CHAT_FRAME:AddMessage("  /isp chat - Toggle inspect prints in chat")
        DEFAULT_CHAT_FRAME:AddMessage("  Inspect a player -> auto-shows stats panel")
        DEFAULT_CHAT_FRAME:AddMessage("  Change target -> auto-re-inspects")
    end
end