--[[
  SendHome — deposit one party pal into Palbox (not chests).

  Party menu click opens skill UI (not "select"). Sidebar wheel / 1-5 set
  game selected slot. Default target = currently out pal, else selected, else first.

  Default key F8 (letter keys often eaten by inventory; RegisterKeyBind alone is flaky).
]]

local cfg = require("config")

local function log(m)
    -- always print so UE4SS.log shows something even if verbose false mid-debug
    print("[SendHome] " .. tostring(m))
end

local function unwrap(v)
    if v and type(v) == "userdata" and v.get then
        local ok, u = pcall(function() return v:get() end)
        if ok and u then return u end
    end
    return v
end

local function getUtil()
    local ok, u = pcall(function() return StaticFindObject("/Script/Pal.Default__PalUtility") end)
    if ok and u and u:IsValid() then return u end
    return nil
end

local function getPlayer()
    local util = getUtil()
    if util then
        local ok, p = pcall(function() return util:GetPlayerCharacter(nil) end)
        if ok and p and p:IsValid() then return p end
    end
    local ok, p = pcall(function() return FindFirstOf("PalPlayerCharacter") end)
    if ok and p and p:IsValid() then return p end
    return nil
end

local function getPlayerState()
    local p = getPlayer()
    if p then
        local ok, ps = pcall(function() return unwrap(p.PlayerState) end)
        if ok and ps and ps:IsValid() then return ps end
    end
    local ok, ps = pcall(function() return FindFirstOf("PalPlayerState") end)
    if ok and ps and ps:IsValid() then return ps end
    return nil
end

local function getOtomo()
    local p = getPlayer()
    if p then
        local ok, c = pcall(function()
            return p:GetComponentByClass(StaticFindObject("/Script/Pal.PalOtomoHolderComponentBase"))
        end)
        if ok and c and c:IsValid() then return c end
    end
    for _, name in ipairs({
        "BP_OtomoPalHolderComponent_C",
        "PalOtomoHolderComponentBase",
    }) do
        local ok, c = pcall(function() return FindFirstOf(name) end)
        if ok and c and c:IsValid() then return c end
    end
    return nil
end

local function getNetContainer()
    local ps = getPlayerState()
    if ps then
        for _, name in ipairs({ "NetworkCharacterContainerComponent", "NetworkCharacterContainer" }) do
            local ok, c = pcall(function() return unwrap(ps[name]) end)
            if ok and c and c:IsValid() then return c end
        end
    end
    local ok, c = pcall(function() return FindFirstOf("PalNetworkCharacterContainerComponent") end)
    if ok and c and c:IsValid() then return c end
    return nil
end

local function getNetCharacter()
    local ps = getPlayerState()
    if ps then
        local ok, c = pcall(function() return unwrap(ps.NetworkCharacterComponent) end)
        if ok and c and c:IsValid() then return c end
    end
    local ok, c = pcall(function() return FindFirstOf("PalNetworkCharacterComponent") end)
    if ok and c and c:IsValid() then return c end
    return nil
end

local function getPalStorage()
    local util = getUtil()
    if util then
        local ok, s = pcall(function() return util:GetLocalPalStorageData(nil) end)
        if ok and s and s:IsValid() then return s end
    end
    local ps = getPlayerState()
    if ps then
        local ok, s = pcall(function() return unwrap(ps:GetPalStorage()) end)
        if ok and s and s:IsValid() then return s end
    end
    return nil
end

local function maxSlots(otomo)
    local n = 5
    pcall(function() n = otomo:GetMaxOtomoNum() or 5 end)
    if type(n) ~= "number" or n < 1 then n = 5 end
    return n
end

local function getSlotHandle(otomo, slotIndex)
    local h = nil
    pcall(function() h = otomo:GetOtomoIndividualHandle(slotIndex) end)
    if h and h:IsValid() then return h end
    pcall(function()
        local slot = otomo:GetOtomoIndividualCharacterSlot(slotIndex)
        if slot and slot:IsValid() then
            local empty = false
            pcall(function() empty = slot:IsEmpty() end)
            if not empty then
                h = slot:GetHandle()
            end
        end
    end)
    if h and h:IsValid() then return h end
    return nil
end

local function getInstanceId(handle)
    if not handle then return nil end
    local id = nil
    pcall(function() id = handle:GetIndividualID() end)
    if id then return id end
    pcall(function() id = handle.ID end)
    if id then return id end
    pcall(function() id = handle.IndividualId end)
    return id
end

local function getSlotId(otomo, slotIndex)
    local slotId = nil
    pcall(function()
        local slot = otomo:GetOtomoIndividualCharacterSlot(slotIndex)
        if slot and slot:IsValid() then
            slotId = slot:GetSlotId()
        end
    end)
    return slotId
end

local function getBoxContainerId(storage)
    if not storage then return nil end
    local cid = nil
    pcall(function()
        local container = unwrap(storage.TargetContainer)
        if container and container:IsValid() then
            cid = container:GetId()
        end
    end)
    if cid then return cid end
    pcall(function()
        local container = unwrap(storage.TargetContainer)
        if container and container:IsValid() then
            cid = container.Id
        end
    end)
    return cid
end

local function selectedSlotIndex(otomo)
    local idx = nil
    pcall(function() idx = otomo:GetSelectedOtomoID() end)
    if type(idx) == "number" then return idx end
    pcall(function() idx = otomo.SelectedOtomoSlotID end)
    if type(idx) == "number" then return idx end
    pcall(function() idx = otomo:GetSelectOtomoID() end)
    if type(idx) == "number" then return idx end
    return nil
end

local function activeSlotIndex(otomo)
    -- currently out / battle-ready slot (names vary by build)
    local idx = nil
    for _, fn in ipairs({
        "GetActiveOtomoID",
        "GetActivatedOtomoID",
        "GetSpawnedOtomoID",
        "GetCurrentOtomoID",
        "GetControlledOtomoID",
    }) do
        pcall(function()
            if otomo[fn] then idx = otomo[fn](otomo) end
        end)
        if type(idx) == "number" then return idx end
    end
    for _, prop in ipairs({
        "ActiveOtomoSlotID",
        "ActivatedOtomoSlotID",
        "CurrentOtomoSlotID",
    }) do
        pcall(function() idx = otomo[prop] end)
        if type(idx) == "number" then return idx end
    end
    -- actor that is out in world
    pcall(function()
        local actor = otomo:GetOtomoActor()
        if actor and actor:IsValid() then
            for i = 0, maxSlots(otomo) - 1 do
                local a = nil
                pcall(function() a = otomo:GetOtomoActorBySlotIndex(i) end)
                if a and a:IsValid() and a == actor then
                    idx = i
                end
            end
        end
    end)
    if type(idx) == "number" then return idx end
    return nil
end

local function firstFilledSlot(otomo)
    for i = 0, maxSlots(otomo) - 1 do
        if getSlotHandle(otomo, i) then return i end
    end
    return nil
end

local function resolveSlot(otomo)
    local mode = (cfg.target or "active"):lower()
    local idx = nil
    if mode == "selected" then
        idx = selectedSlotIndex(otomo)
    elseif mode == "first" then
        idx = firstFilledSlot(otomo)
    else
        -- active: out pal → selected → first filled
        idx = activeSlotIndex(otomo)
        if idx == nil or not getSlotHandle(otomo, idx) then
            idx = selectedSlotIndex(otomo)
        end
        if idx == nil or not getSlotHandle(otomo, idx) then
            idx = firstFilledSlot(otomo)
        end
    end
    return idx
end

local function collectPartyInstanceIds(otomo, excludeSlot)
    local ids = {}
    for i = 0, maxSlots(otomo) - 1 do
        if i ~= excludeSlot then
            local h = getSlotHandle(otomo, i)
            if h then
                local id = getInstanceId(h)
                if id then table.insert(ids, id) end
            end
        end
    end
    return ids
end

local busy = false

local function sendHomeSelected()
    if busy then return end
    busy = true
    log("key fired — resolving party slot…")

    local ok, err = pcall(function()
        local otomo = getOtomo()
        if not otomo then
            log("FAIL: no otomo holder (not in world / no player?)")
            return
        end

        local slotIndex = resolveSlot(otomo)
        log("slot=" .. tostring(slotIndex)
            .. " selected=" .. tostring(selectedSlotIndex(otomo))
            .. " active=" .. tostring(activeSlotIndex(otomo)))

        if slotIndex == nil then
            log("FAIL: no party pals found")
            return
        end

        local handle = getSlotHandle(otomo, slotIndex)
        if not handle then
            log("FAIL: empty party slot " .. tostring(slotIndex))
            return
        end

        local storage = getPalStorage()
        if storage then
            pcall(function() storage.bIsForceSyncAllSlot = true end)
        end

        local netC = getNetContainer()
        local slotId = getSlotId(otomo, slotIndex)
        local containerId = getBoxContainerId(storage)
        local page = 0
        if storage then
            pcall(function()
                page = storage:GetPageIndexExistEmptySlot(0) or 0
            end)
        end

        log("netC=" .. tostring(netC ~= nil)
            .. " slotId=" .. tostring(slotId ~= nil)
            .. " boxId=" .. tostring(containerId ~= nil)
            .. " page=" .. tostring(page))

        -- Path A: move-to-palbox RPC
        if netC and slotId and containerId then
            local okA, errA = pcall(function()
                netC:RequestMoveToPalBox_ToServer_Rep(slotId, containerId, page)
            end)
            log("PathA RequestMoveToPalBox ok=" .. tostring(okA) .. " err=" .. tostring(errA))
            if okA then return end
            local okB, errB = pcall(function()
                netC:RequestMove_ToServer_Rep(slotId, containerId)
            end)
            log("PathA RequestMove ok=" .. tostring(okB) .. " err=" .. tostring(errB))
            if okB then return end
        else
            log("PathA skipped (missing net/slot/box id)")
        end

        -- Path B: re-apply loadout without this pal
        local netChar = getNetCharacter()
        local ps = getPlayerState()
        local uid = nil
        if ps then
            pcall(function() uid = ps.DebugPlayerUId end)
            if not uid then pcall(function() uid = ps.PlayerUId end) end
        end
        local keepIds = collectPartyInstanceIds(otomo, slotIndex)
        if netChar and uid then
            local okC, errC = pcall(function()
                netChar:RequestApplyPalLoadoutData_ToServer(uid, keepIds)
            end)
            log("PathB loadout exclude ok=" .. tostring(okC)
                .. " err=" .. tostring(errC)
                .. " keep=" .. tostring(#keepIds))
            if okC then return end
        else
            log("PathB skipped (netChar=" .. tostring(netChar ~= nil) .. " uid=" .. tostring(uid ~= nil) .. ")")
        end

        log("FAIL: all deposit paths failed")
    end)

    if not ok then
        log("EXCEPTION: " .. tostring(err))
    end
    busy = false
end

local function resolveKey()
    local name = (cfg.key or "F8"):upper()
    if Key and Key[name] then return Key[name], name end
    -- common fallbacks
    local map = {
        Y = 0x59, H = 0x48, G = 0x47,
        F6 = 0x75, F7 = 0x76, F8 = 0x77, F9 = 0x78,
    }
    return map[name] or Key.F8 or 0x77, name
end

local function resolveModifier()
    local m = (cfg.modifier or "NONE"):upper()
    if m == "ALT" then return ModifierKey.ALT end
    if m == "CTRL" then return ModifierKey.CONTROL end
    if m == "SHIFT" then return ModifierKey.SHIFT end
    return nil
end

local keyCode, keyName = resolveKey()
local mod = resolveModifier()

local function onKey()
    if ExecuteInGameThread then
        pcall(ExecuteInGameThread, sendHomeSelected)
    else
        sendHomeSelected()
    end
end

-- Path 1: RegisterKeyBind (works in open world; often dead inside inventory)
local rbOk, rbErr = pcall(function()
    if mod then
        RegisterKeyBind(keyCode, mod, onKey)
    else
        RegisterKeyBind(keyCode, onKey)
    end
end)
log("RegisterKeyBind " .. tostring(keyName) .. " ok=" .. tostring(rbOk) .. " err=" .. tostring(rbErr))

-- Path 2: poll IsKeyDown (better chance with UI open)
if cfg.use_poll ~= false and IsKeyDown and LoopAsync then
    local held = false
    local pollOk, pollErr = pcall(function()
        LoopAsync(50, function()
            local down = false
            pcall(function() down = IsKeyDown(keyCode) end)
            if down then
                if not held then
                    held = true
                    onKey()
                end
            else
                held = false
            end
            return false -- keep looping
        end)
    end)
    log("poll IsKeyDown ok=" .. tostring(pollOk) .. " err=" .. tostring(pollErr))
else
    log("poll disabled or IsKeyDown/LoopAsync missing")
end

log("ready — press " .. tostring(keyName)
    .. " (target=" .. tostring(cfg.target or "active")
    .. "). Party menu click = skills, not select. Spawn a pal or use 1-5/wheel, then key.")
