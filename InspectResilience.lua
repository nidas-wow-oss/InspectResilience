local ADDON_NAME = "InspectResilience"
local EQUIP_SLOTS = { 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18 }

local L = {
    TITLE = "Inspect Stats", RESILIENCE = "Resilience", ITEMS = "items",
    PARTIAL = "(partial)", HIDE = "Hide Stats", SHOW = "Show Stats",
    RES_DETAIL = "Resilience Detail", GEAR_TOTAL = "Gear Total", SET_BONUS = "Set Bonus",
    OFFENSE = "Offense", DEFENSE = "Defense", REGEN = "Regen",
    AP = "Attack Power", SP = "Spell Power", CRIT = "Crit Rating", HIT = "Hit Rating",
    HASTE = "Haste Rating", ARPEN = "Armor Pen", EXPERTISE = "Expertise", SPELLPEN = "Spell Pen",
    ARMOR = "Armor", DEFENSE_R = "Defense Rating", DODGE = "Dodge Rating", PARRY = "Parry Rating",
    BLOCKRATING = "Block Rating", BLOCKVALUE = "Block Value", MP5 = "MP5", HP5 = "HP5",
    STR = "STR", AGI = "AGI", STA = "STA", INT = "INT", SPI = "SPI",
}
do
    local loc = GetLocale()
    if loc == "esES" or loc == "esMX" then
        L.TITLE = "Estadísticas"; L.RESILIENCE = "Temple"; L.ITEMS = "objetos"
        L.PARTIAL = "(parcial)"; L.HIDE = "Ocultar"; L.SHOW = "Mostrar"
        L.RES_DETAIL = "Detalle de temple"; L.GEAR_TOTAL = "Total equipo"; L.SET_BONUS = "Bonus de conjunto"
        L.OFFENSE = "Ataque"; L.DEFENSE = "Defensa"; L.REGEN = "Regeneración"
        L.AP = "Poder de ataque"; L.SP = "Poder con hechizos"; L.CRIT = "Crítico"; L.HIT = "Golpe"
        L.HASTE = "Celeridad"; L.ARPEN = "Penetr. armadura"; L.EXPERTISE = "Pericia"; L.SPELLPEN = "Penetr. hechizos"
        L.ARMOR = "Armadura"; L.DEFENSE_R = "Defensa"; L.DODGE = "Esquivar"; L.PARRY = "Parada"
        L.BLOCKRATING = "Bloqueo"; L.BLOCKVALUE = "Valor de bloqueo"
        L.STR = "FUE"; L.AGI = "AGI"; L.STA = "AGU"; L.INT = "INT"; L.SPI = "ESP"
    end
end

local function Lower(s)
    s = s:lower()
    return (s:gsub("\195([\128-\158])", function(c)
        return "\195" .. string.char(c:byte() + 32)
    end))
end

local function FormatToPattern(fmt)
    local p = Lower(fmt)
    p = p:gsub("%%c", "\1"):gsub("%%%d?%$?[ds]", "\2")
    p = p:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%0")
    p = p:gsub("\1", "[%%+%%-]?"):gsub("\2", "(%%d+)")
    if p:find("%(%%d%+%)") then return p end
end

local STAT_DEFS = {
    { key = "STA",  global = "ITEM_MOD_STAMINA",   fbShort = "stamina" },
    { key = "STR",  global = "ITEM_MOD_STRENGTH",  fbShort = "strength" },
    { key = "AGI",  global = "ITEM_MOD_AGILITY",   fbShort = "agility" },
    { key = "INT",  global = "ITEM_MOD_INTELLECT", fbShort = "intellect" },
    { key = "SPI",  global = "ITEM_MOD_SPIRIT",    fbShort = "spirit" },
    { key = "RESILIENCE", global = "ITEM_MOD_RESILIENCE_RATING", fbLong = "resilience rating by (%d+)", fbShort = "resilience rating" },
    { key = "AP",   global = "ITEM_MOD_ATTACK_POWER", fbLong = "increases attack power by (%d+)", fbShort = "attack power" },
    { key = "SP",   global = "ITEM_MOD_SPELL_POWER",  fbLong = "increases spell power by (%d+)",  fbShort = "spell power" },
    { key = "CRIT", global = "ITEM_MOD_CRIT_RATING",  fbLong = "critical strike rating by (%d+)", fbShort = "critical strike rating" },
    { key = "HIT",  global = "ITEM_MOD_HIT_RATING",   fbLong = "hit rating by (%d+)",   fbShort = "hit rating" },
    { key = "HASTE", global = "ITEM_MOD_HASTE_RATING", fbLong = "haste rating by (%d+)", fbShort = "haste rating" },
    { key = "ARPEN", global = "ITEM_MOD_ARMOR_PENETRATION_RATING", fbLong = "armor penetration rating by (%d+)", fbShort = "armor penetration rating" },
    { key = "EXPERTISE", global = "ITEM_MOD_EXPERTISE_RATING", fbLong = "expertise rating by (%d+)", fbShort = "expertise rating" },
    { key = "DEFENSE", global = "ITEM_MOD_DEFENSE_SKILL_RATING", fbLong = "defense rating by (%d+)", fbShort = "defense rating" },
    { key = "DODGE", global = "ITEM_MOD_DODGE_RATING", fbLong = "dodge rating by (%d+)", fbShort = "dodge rating" },
    { key = "PARRY", global = "ITEM_MOD_PARRY_RATING", fbLong = "parry rating by (%d+)", fbShort = "parry rating" },
    { key = "BLOCKRATING", global = "ITEM_MOD_BLOCK_RATING", fbLong = "block rating by (%d+)", fbShort = "block rating" },
    { key = "BLOCKVALUE", global = "ITEM_MOD_BLOCK_VALUE", fbLong = "block value of your shield by (%d+)", fbShort = "block value" },
    { key = "MP5",  global = "ITEM_MOD_MANA_REGENERATION", fbLong = "(%d+) mana per 5", fbShort = "mana per 5 sec" },
    { key = "HP5",  global = "ITEM_MOD_HEALTH_REGEN", fbLong = "(%d+) health per 5", fbShort = "health per 5 sec" },
    { key = "SPELLPEN", global = "ITEM_MOD_SPELL_PENETRATION", fbLong = "spell penetration by (%d+)", fbShort = "spell penetration" },
}

local EXTRA_PATTERNS = {

    { "%+(%d+) resilience",        "RESILIENCE" },
    { "%+(%d+) crit rating",       "CRIT" },
    { "%+(%d+) critical strike",   "CRIT" },
    { "%+(%d+) haste",             "HASTE" },
    { "%+(%d+) mana every 5",      "MP5" },
    { "(%d+) mana every 5",        "MP5" },
    { "(%d+) health every 5",      "HP5" },

    { "(%d+) de maná cada 5",      "MP5" },
    { "(%d+) maná cada 5",         "MP5" },
    { "(%d+) de salud cada 5",     "HP5" },
    { "(%d+) salud cada 5",        "HP5" },
    { "%+(%d+) índice de temple",  "RESILIENCE" },
    { "%+(%d+) de temple",         "RESILIENCE" },
    { "%+(%d+) temple",            "RESILIENCE" },
    { "temple en (%d+)",           "RESILIENCE" },
    { "%+(%d+) de poder de ataque",    "AP" },
    { "%+(%d+) poder de ataque",       "AP" },
    { "%+(%d+) de poder con hechizos", "SP" },
    { "%+(%d+) poder con hechizos",    "SP" },
    { "%+(%d+) índice de golpe crítico", "CRIT" },
    { "%+(%d+) de golpe crítico",      "CRIT" },
    { "%+(%d+) índice de golpe",       "HIT" },
    { "%+(%d+) índice de celeridad",   "HASTE" },
    { "%+(%d+) de celeridad",          "HASTE" },
    { "%+(%d+) índice de penetración de armadura", "ARPEN" },
    { "%+(%d+) índice de pericia",     "EXPERTISE" },
    { "%+(%d+) índice de defensa",     "DEFENSE" },
    { "%+(%d+) índice de esquivar",    "DODGE" },
    { "%+(%d+) índice de parada",      "PARRY" },
    { "%+(%d+) índice de bloqueo",     "BLOCKRATING" },
    { "%+(%d+) de aguante",            "STA" },
    { "%+(%d+) aguante",               "STA" },
    { "%+(%d+) de fuerza",             "STR" },
    { "%+(%d+) fuerza",                "STR" },
    { "%+(%d+) de agilidad",           "AGI" },
    { "%+(%d+) agilidad",              "AGI" },
    { "%+(%d+) de intelecto",          "INT" },
    { "%+(%d+) intelecto",             "INT" },
    { "%+(%d+) de espíritu",           "SPI" },
    { "%+(%d+) espíritu",              "SPI" },
}

local STAT_PATTERNS = {}
do
    local shorts = {}
    for _, d in ipairs(STAT_DEFS) do
        local long = _G[d.global]
        local p = type(long) == "string" and FormatToPattern(long) or d.fbLong
        if p then STAT_PATTERNS[#STAT_PATTERNS + 1] = { p, d.key } end
        local short = _G[d.global .. "_SHORT"]
        short = type(short) == "string" and Lower(short) or d.fbShort
        if short then
            local esc = short:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%0")
            shorts[#shorts + 1] = { "%+(%d+) " .. esc, d.key }
        end
    end
    for _, e in ipairs(EXTRA_PATTERNS) do shorts[#shorts + 1] = e end
    table.sort(shorts, function(a, b) return #a[1] > #b[1] end)
    for _, s in ipairs(shorts) do STAT_PATTERNS[#STAT_PATTERNS + 1] = s end

    local armor = type(ARMOR_TEMPLATE) == "string" and FormatToPattern(ARMOR_TEMPLATE)
    STAT_PATTERNS[#STAT_PATTERNS + 1] = { "^" .. (armor or "(%d+) armor") .. "$", "ARMOR" }
    local block = type(SHIELD_BLOCK_TEMPLATE) == "string" and FormatToPattern(SHIELD_BLOCK_TEMPLATE)
    STAT_PATTERNS[#STAT_PATTERNS + 1] = { "^" .. (block or "(%d+) block") .. "$", "BLOCKVALUE" }
end

local USE_PREFIX = Lower(type(ITEM_SPELL_TRIGGER_ONUSE) == "string" and ITEM_SPELL_TRIGGER_ONUSE or "Use:")
local SET_PREFIX = Lower((type(ITEM_SET_BONUS) == "string" and ITEM_SET_BONUS:match("^(.-)%s*%%s")) or "Set:")

local function StartsWith(s, prefix)
    return s:sub(1, #prefix) == prefix
end

local STAT_DISPLAY = {
    { key = "AP",         name = L.AP,          cat = "O" },
    { key = "SP",         name = L.SP,          cat = "O" },
    { key = "CRIT",       name = L.CRIT,        cat = "O" },
    { key = "HIT",        name = L.HIT,         cat = "O" },
    { key = "HASTE",      name = L.HASTE,       cat = "O" },
    { key = "ARPEN",      name = L.ARPEN,       cat = "O" },
    { key = "EXPERTISE",  name = L.EXPERTISE,   cat = "O" },
    { key = "SPELLPEN",   name = L.SPELLPEN,    cat = "O" },
    { key = "ARMOR",      name = L.ARMOR,       cat = "D" },
    { key = "DEFENSE",    name = L.DEFENSE_R,   cat = "D" },
    { key = "DODGE",      name = L.DODGE,       cat = "D" },
    { key = "PARRY",      name = L.PARRY,       cat = "D" },
    { key = "BLOCKRATING",name = L.BLOCKRATING, cat = "D" },
    { key = "BLOCKVALUE", name = L.BLOCKVALUE,  cat = "D" },
    { key = "MP5",        name = L.MP5,         cat = "R" },
    { key = "HP5",        name = L.HP5,         cat = "R" },
}

local CHAT_NAMES = {
    AP = "Attack Power", SP = "Spell Power", CRIT = "Crit Rating", HIT = "Hit Rating",
    HASTE = "Haste Rating", ARPEN = "Armor Pen", EXPERTISE = "Expertise", SPELLPEN = "Spell Pen",
    ARMOR = "Armor", DEFENSE = "Defense Rating", DODGE = "Dodge Rating", PARRY = "Parry Rating",
    BLOCKRATING = "Block Rating", BLOCKVALUE = "Block Value", MP5 = "MP5", HP5 = "HP5",
}

local BASE_STATS = {
    { key = "STR", name = L.STR, chat = "STR" },
    { key = "AGI", name = L.AGI, chat = "AGI" },
    { key = "STA", name = L.STA, chat = "STA" },
    { key = "INT", name = L.INT, chat = "INT" },
    { key = "SPI", name = L.SPI, chat = "SPI" },
}

local RATING_BASE_80 = {
    RESILIENCE = 94.27, CRIT = 45.91, HIT = 32.79, HASTE = 32.79,
    EXPERTISE = 8.20, DEFENSE = 4.92, DODGE = 39.35, PARRY = 39.35,
    BLOCKRATING = 16.39, ARPEN = 13.99,
}

local resCalibrated = false
local function CalibrateResilience()
    if resCalibrated or UnitLevel("player") ~= 80 or not GetCombatRatingBonus then return end
    local id = CR_CRIT_TAKEN_MELEE or 15
    local rating, bonus = GetCombatRating(id), GetCombatRatingBonus(id)
    if rating and rating > 0 and bonus and bonus > 0 then
        RATING_BASE_80.RESILIENCE = rating / bonus
        resCalibrated = true
    end
end

local ILVL_SLOTS = 17

local function SlotItemLevel(unit, slot, link)
    local _, _, _, iLvl, _, _, _, _, equipLoc = GetItemInfo(link)
    if not iLvl then return nil end

    if slot == 16 and equipLoc == "INVTYPE_2HWEAPON" and not GetInventoryItemLink(unit, 17) then
        return iLvl * 2
    end
    return iLvl
end

local function RatingPct(key, val)
    local b = RATING_BASE_80[key]
    if b and val and val > 0 then return val / b end
end

local scanTip = CreateFrame("GameTooltip", "ISPScanTip", UIParent, "GameTooltipTemplate")
scanTip:SetOwner(UIParent, "ANCHOR_NONE")

local scannedSetBonuses = {}

local function IsGray(r, g, b)
    return r > 0.45 and r < 0.55 and math.abs(r - g) < 0.02 and math.abs(r - b) < 0.02
end

local function ScanLineForAllStats(line, stats, onlyKey)
    line = Lower(line)
    for i = 1, #STAT_PATTERNS do
        local pat, key = STAT_PATTERNS[i][1], STAT_PATTERNS[i][2]
        local s, e, val = line:find(pat)
        while s do
            if not onlyKey or onlyKey == key then
                stats[key] = (stats[key] or 0) + tonumber(val)
            end
            line = line:sub(1, s - 1) .. "|" .. line:sub(e + 1)
            s, e, val = line:find(pat)
        end
    end
end

local function SkipLine(obj, lower)
    return IsGray(obj:GetTextColor()) or StartsWith(lower, USE_PREFIX)
end

local function ScanSlotStats(unit, slot, stats)
    scanTip:ClearLines()
    scanTip:SetOwner(UIParent, "ANCHOR_NONE")
    scanTip:SetInventoryItem(unit, slot)
    local n = scanTip:NumLines()
    if not n or n == 0 then return end

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
                local lower = Lower(line)
                if not SkipLine(obj, lower) then
                    if StartsWith(lower, SET_PREFIX) then

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

local scanStats = {}
local function ScanGearStats(unit)
    local stats = scanStats
    wipe(stats)
    local itemCount, iLvlTotal = 0, 0
    local incomplete = false
    wipe(scannedSetBonuses)

    for _, slot in ipairs(EQUIP_SLOTS) do
        local link = GetInventoryItemLink(unit, slot)
        if link then
            itemCount = itemCount + 1
            ScanSlotStats(unit, slot, stats)
            local lvl = SlotItemLevel(unit, slot, link)
            if lvl then
                iLvlTotal = iLvlTotal + lvl
            else

                incomplete = true
            end
        end
    end

    return stats, itemCount, iLvlTotal / ILVL_SLOTS, incomplete
end

local resTmp = {}
local function ScanSlotResilience(unit, slot)
    wipe(resTmp)
    scanTip:ClearLines()
    scanTip:SetOwner(UIParent, "ANCHOR_NONE")
    scanTip:SetInventoryItem(unit, slot)
    local n = scanTip:NumLines()
    if not n or n == 0 then return 0 end
    for i = 2, n do
        local obj = _G["ISPScanTipTextLeft" .. i]
        local line = obj and obj:GetText()
        if line then
            local lower = Lower(line)
            if not SkipLine(obj, lower) and not StartsWith(lower, SET_PREFIX) then
                ScanLineForAllStats(line, resTmp, "RESILIENCE")
            end
        end
    end
    return resTmp.RESILIENCE or 0
end

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
    local iT, iN = 0, 0
    for _, slot in ipairs(EQUIP_SLOTS) do
        local link = GetInventoryItemLink("player", slot)
        if link then
            iN = iN + 1
            iT = iT + (SlotItemLevel("player", slot, link) or 0)
        end
    end
    return stats, iN, iT / ILVL_SLOTS
end

local lastStats = {}
local lastUnit = nil
local panelShown = true
local chatPrintsEnabled = false
local inspectReady = false
local retries = 0
local MAX_RETRIES = 3

local timerFrame = CreateFrame("Frame")
local timerLeft, timerFunc = 0, nil
timerFrame:Hide()
timerFrame:SetScript("OnUpdate", function(self, dt)
    timerLeft = timerLeft - dt
    if timerLeft <= 0 then
        self:Hide()
        local fn = timerFunc
        timerFunc = nil
        if fn then fn() end
    end
end)

local function Schedule(delay, fn)
    timerLeft, timerFunc = delay, fn
    timerFrame:Show()
end

local function CancelSchedule()
    timerFunc = nil
    timerFrame:Hide()
end

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

local titleText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
titleText:SetPoint("TOP", 0, -10)
titleText:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
titleText:SetText("|cff00ff99" .. L.TITLE .. "|r")

local nameText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
nameText:SetPoint("TOP", titleText, "BOTTOM", 0, -2)
nameText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")

local ilvlText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
ilvlText:SetPoint("TOP", nameText, "BOTTOM", 0, -2)
ilvlText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")

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
resBg:EnableMouse(true)

local resIcon = resBg:CreateTexture(nil, "ARTWORK")
resIcon:SetSize(26, 26); resIcon:SetPoint("LEFT", 8, -4)
resIcon:SetTexture("Interface\\PaperDollInfoFrame\\SpellSchoolIcon7")

local resLabel = resBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
resLabel:SetPoint("TOPLEFT", resBg, "TOPLEFT", 42, -6)
resLabel:SetText("|cff9482c9" .. L.RESILIENCE .. "|r")
resLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "")

local resValue = resBg:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
resValue:SetPoint("TOPLEFT", resBg, "TOPLEFT", 42, -20)
resValue:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")

local resPct = resBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
resPct:SetPoint("RIGHT", resBg, "RIGHT", -8, 0)
resPct:SetFont("Fonts\\FRIZQT__.TTF", 11, "")

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

local arrowBtn = CreateFrame("Button", "ISP_ArrowTab", UIParent)
arrowBtn:SetWidth(25); arrowBtn:SetHeight(50)
arrowBtn:SetFrameStrata("HIGH"); arrowBtn:EnableMouse(true); arrowBtn:Hide()
arrowBtn:SetMovable(false)

local arrowTex = arrowBtn:CreateTexture(nil, "OVERLAY")
arrowTex:SetAllPoints(arrowBtn)

local arrowLeft, arrowRight = 1, 0.5
if not arrowTex:SetTexture("Interface\\AddOns\\Nidhaus_UnitFrames\\Media\\RaidPanel-Toggle") then
    arrowTex:SetTexture("Interface\\BUTTONS\\UI-SpellbookIcon-NextPage-Up")
    arrowLeft, arrowRight = 1, 0
end

local function UpdateArrowVisual()

    arrowTex:SetTexCoord(arrowLeft, arrowRight, 0, 1)
end

arrowBtn:SetScript("OnClick", function()
    panelShown = not panelShown
    if panelShown then panel:Show() else panel:Hide() end
    UpdateArrowVisual()

end)
arrowBtn:SetScript("OnEnter", function(self)
    arrowTex:SetVertexColor(1, 0.8, 0.2, 1)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(panelShown and L.HIDE or L.SHOW, 1, 0.82, 0)
    GameTooltip:Show()
end)
arrowBtn:SetScript("OnLeave", function(self)
    arrowTex:SetVertexColor(1, 1, 1, 1)
    GameTooltip:Hide()
end)

local arrowPositioned = false

local function PositionArrow()
    if not InspectFrame then return end
    arrowBtn:ClearAllPoints()
    arrowBtn:SetParent(InspectFrame)

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
end

local function HidePanel()
    panel:Hide(); arrowBtn:Hide()
end

local function GetInspectUnit()
    if InspectFrame and InspectFrame.unit and UnitExists(InspectFrame.unit) then
        return InspectFrame.unit
    end
    if UnitExists("target") and UnitIsPlayer("target") then return "target" end
    return nil
end

local CAT_HEADERS = {
    O = "|cff4fc3f7--- " .. L.OFFENSE .. " ---|r",
    D = "|cffFFD700--- " .. L.DEFENSE .. " ---|r",
    R = "|cff66bb6a--- " .. L.REGEN .. " ---|r",
}

local function PopulatePanel(stats, itemCount, avgILvl, unit, final)
    lastStats = stats
    lastUnit = unit
    CalibrateResilience()

    local name = UnitName(unit) or "???"
    local _, classToken = UnitClass(unit)
    local cc = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[classToken]
    if cc then
        nameText:SetText(string.format("|cff%.2x%.2x%.2x%s|r", cc.r * 255, cc.g * 255, cc.b * 255, name))
    else nameText:SetText(name) end

    ilvlText:SetText(string.format("|cffaaaaaa%d %s | iLvl: |cffffff00%.1f|r%s", itemCount, L.ITEMS, avgILvl,
        inspectReady and "" or (" |cffff6666" .. L.PARTIAL .. "|r")))

    local res = stats.RESILIENCE or 0
    resValue:SetText(tostring(res))
    resPct:SetText(string.format("|cff9482c9-%.1f%%|r", res / RATING_BASE_80.RESILIENCE))
    if res >= 1000 then resValue:SetTextColor(1, 0.5, 0)
    elseif res >= 600 then resValue:SetTextColor(1, 1, 0)
    elseif res >= 300 then resValue:SetTextColor(0, 1, 0)
    elseif res > 0 then resValue:SetTextColor(1, 1, 1)
    else resValue:SetTextColor(0.5, 0.5, 0.5) end

    for _, bs in ipairs(baseLabels) do
        local v = stats[bs.key] or 0
        bs.val:SetText(v > 0 and tostring(v) or "|cff444444-|r")
    end

    local n, lastCat = 0, nil
    for _, si in ipairs(STAT_DISPLAY) do
        local v = stats[si.key] or 0
        if v > 0 then
            if si.cat ~= lastCat then
                lastCat = si.cat
                n = n + 1
                local line = statLines[n]
                if line then
                    line.left:SetText(CAT_HEADERS[si.cat]); line.right:SetText("")
                    line:Show()
                end
            end
            n = n + 1
            local line = statLines[n]
            if line then
                line.left:SetText("  " .. si.name); line.left:SetTextColor(0.85, 0.85, 0.85)
                local pct = RatingPct(si.key, v)
                if pct then
                    line.right:SetFormattedText("|cffffff00%d|r |cff888888(%.1f%%)|r", v, pct)
                else
                    line.right:SetFormattedText("|cffffff00%d|r", v)
                end
                line:Show()
            end
        end
    end
    for i = n + 1, MAX_LINES do statLines[i]:Hide() end

    local numLines = math.min(n, MAX_LINES)
    local h = 10 + 16 + 14 + 12 + 5 + 56 + 4 + 22 + 5 + (numLines * LINE_H) + 10
    panel:SetHeight(math.max(h, 200))

    PositionAll()
    arrowBtn:Show()
    if panelShown then panel:Show() end
    UpdateArrowVisual()

    if chatPrintsEnabled and final then
        DEFAULT_CHAT_FRAME:AddMessage(string.format(
            "|cff00ff99[InspectStats]|r %s: |cff9482c9%d|r res | iLvl: |cffffff00%.1f|r | %d items",
            name, res, avgILvl, itemCount))
    end
end

local UpdatePanel
UpdatePanel = function()
    if not InspectFrame or not InspectFrame:IsShown() then HidePanel(); return end
    local unit = GetInspectUnit()
    if not unit then HidePanel(); return end

    local stats, itemCount, avgILvl, incomplete = ScanGearStats(unit)

    local final = true
    if (itemCount == 0 or incomplete or not inspectReady) and retries < MAX_RETRIES then
        retries = retries + 1
        final = false
        Schedule(1.0, UpdatePanel)
    end
    if itemCount > 0 then PopulatePanel(stats, itemCount, avgILvl, unit, final) end
end

local function BeginInspect()
    inspectReady = false
    retries = 0
    Schedule(1.5, UpdatePanel)
end

resBg:SetScript("OnEnter", function(self)
    if not lastUnit or not UnitExists(lastUnit) then return end
    GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
    GameTooltip:SetText(L.RES_DETAIL, 0.58, 0.51, 0.79)
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
        GameTooltip:AddDoubleLine(L.GEAR_TOTAL, string.format("|cff9482c9%d|r", totalTip), 0.8, 0.8, 0.2)
    end
    local setBonus = (lastStats.RESILIENCE or 0) - totalTip
    if setBonus > 0 then
        GameTooltip:AddDoubleLine(L.SET_BONUS, string.format("|cffa335ee+%d|r", setBonus), 0.8, 0.8, 0.2)
    end
    GameTooltip:Show()
end)
resBg:SetScript("OnLeave", function() GameTooltip:Hide() end)

local hooked = false
local function HookInspectFrame()
    if not InspectFrame or hooked then return end
    hooked = true

    InspectFrame:HookScript("OnShow", BeginInspect)
    InspectFrame:HookScript("OnHide", function()
        CancelSchedule()
        HidePanel()
        arrowPositioned = false
    end)
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")

ev:RegisterEvent("INSPECT_TALENT_READY")
ev:RegisterEvent("PLAYER_TARGET_CHANGED")

ev:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON_NAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff99[InspectStats v2.9]|r Loaded. /isp chat = toggle prints")
        end
        HookInspectFrame()
        if hooked then self:UnregisterEvent("ADDON_LOADED") end
    elseif event == "INSPECT_TALENT_READY" then

        if InspectFrame and InspectFrame:IsShown() then
            HookInspectFrame()
            inspectReady = true
            retries = 0
            Schedule(0.2, UpdatePanel)
        end
    elseif event == "PLAYER_TARGET_CHANGED" then

        if InspectFrame and InspectFrame:IsShown() and InspectFrame.unit == "target" then
            HidePanel()
            BeginInspect()
        end
    end
end)

HookInspectFrame()

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
        CalibrateResilience()
        DEFAULT_CHAT_FRAME:AddMessage(string.format("  |cff9482c9Resilience|r: |cffffffff%d|r (%.1f%% reduction)", res, res / RATING_BASE_80.RESILIENCE))
        for _, si in ipairs(STAT_DISPLAY) do
            local v = stats[si.key] or 0
            if v > 0 and si.key ~= "RESILIENCE" then
                local p = ""; local pct = RatingPct(si.key, v)
                if pct then p = string.format(" (%.1f%%)", pct) end
                DEFAULT_CHAT_FRAME:AddMessage(string.format("  |cffffffff%s|r: |cff00ff00%d|r%s", CHAT_NAMES[si.key] or si.key, v, p))
            end
        end
        local b = "  Base: "
        for _, bs in ipairs(BASE_STATS) do
            local v = stats[bs.key] or 0
            if v > 0 then b = b .. string.format("%s:|cffffffff%d|r  ", bs.chat, v) end
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
