--[[
  Too Many Pals (Pal Pra Poha) — CLIENT half
  Drop folder name for UE4SS: SendHome

  F8 → resolve party slot → one stock RequestMoveToPalBox try (AS-IS) →
  signal server "SENDHOME <slot>" → verify party empty after ~900ms.

  Pair with SendHomeServer on the dedicated. No HTTP. No file IPC.
  Pure Lua only. F8 is the only player UX.
]]

local TAG = "[SendHome] "
local VERIFY_MS = 900
local DEBOUNCE_S = 1.0

local lastPress = 0

local function log(msg)
    print(TAG .. tostring(msg))
end

local function unwrap(v)
    if v and type(v) == "userdata" and v.get then
        local ok, u = pcall(function() return v:get() end)
        if ok and u then return u end
    end
    return v
end

local function isValid(obj)
    if obj == nil then return false end
    local ok, v = pcall(function() return obj:IsValid() end)
    return ok and v == true
end

local function safeName(obj)
    local n = "?"
    pcall(function()
        if obj and obj.GetFullName then n = obj:GetFullName() end
    end)
    return tostring(n)
end

local function localController()
    local ok, list = pcall(function() return FindAllOf("PlayerController") end)
    if ok and list then
        for _, pc in pairs(list) do
            if isValid(pc) then
                local localOk = false
                pcall(function()
                    if pc.IsLocalPlayerController and pc:IsLocalPlayerController() then
                        localOk = true
                    elseif pc.IsPlayerController and pc:IsPlayerController() then
                        localOk = true
                    end
                end)
                if localOk then return pc end
            end
        end
        for _, pc in pairs(list) do
            if isValid(pc) then return pc end
        end
    end
    local ok2, one = pcall(function() return FindFirstOf("PalPlayerController") end)
    if ok2 and isValid(one) then return one end
    ok2, one = pcall(function() return FindFirstOf("PlayerController") end)
    if ok2 and isValid(one) then return one end
    return nil
end

local function playerStateOf(pc)
    if not isValid(pc) then return nil end
    local ps = nil
    pcall(function() ps = unwrap(pc.PlayerState) end)
    if isValid(ps) then return ps end
    return nil
end

--- Otomo holder: prefer CONTROLLER, then pawn (client can see both).
local function otomoOf(pc)
    if not isValid(pc) then return nil end

    local classPaths = {
        "/Script/Pal.PalOtomoHolderComponentBase",
    }
    local classNames = {
        "BP_OtomoPalHolderComponent_C",
        "PalOtomoHolderComponentBase",
        "BP_OtomoPalHolder",
        "PalOtomoHolder",
        "OtomoPalHolder",
    }

    local function fromActor(actor)
        if not isValid(actor) then return nil end
        for _, path in ipairs(classPaths) do
            local ok, c = pcall(function()
                local cls = StaticFindObject(path)
                if cls then return actor:GetComponentByClass(cls) end
            end)
            if ok and isValid(c) then return c end
        end
        for _, name in ipairs(classNames) do
            local ok, c = pcall(function()
                local cls = StaticFindObject("/Script/Pal." .. name)
                if not cls then cls = StaticFindObject(name) end
                if cls then return actor:GetComponentByClass(cls) end
            end)
            if ok and isValid(c) then return c end
        end
        return nil
    end

    local c = fromActor(pc)
    if c then return c end

    local pawn = nil
    pcall(function()
        pawn = unwrap(pc.Pawn) or unwrap(pc.AcknowledgedPawn) or unwrap(pc.Character)
    end)
    c = fromActor(pawn)
    if c then return c end

    -- last resort: any holder owned by this controller / its pawn (never steal first-of globally without check)
    for _, name in ipairs(classNames) do
        local ok, all = pcall(function() return FindAllOf(name) end)
        if ok and all then
            for _, h in pairs(all) do
                if isValid(h) then
                    local owner = nil
                    pcall(function() owner = unwrap(h.GetOwner and h:GetOwner() or h.Owner) end)
                    if owner == pc or owner == pawn then return h end
                end
            end
        end
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
    if isValid(h) then return h end
    pcall(function()
        local slot = otomo:GetOtomoIndividualCharacterSlot(slotIndex)
        if isValid(slot) then
            local empty = false
            pcall(function() empty = slot:IsEmpty() end)
            if not empty then h = slot:GetHandle() end
        end
    end)
    if isValid(h) then return h end
    return nil
end

local function slotFilled(otomo, slotIndex)
    return getSlotHandle(otomo, slotIndex) ~= nil
end

local function selectedSlotIndex(otomo)
    local idx = nil
    pcall(function() idx = otomo:GetSelectedOtomoID() end)
    if type(idx) == "number" and idx >= 0 then return idx end
    pcall(function() idx = otomo.SelectedOtomoSlotID end)
    if type(idx) == "number" and idx >= 0 then return idx end
    return nil
end

local function activeSlotIndex(otomo)
    local idx = nil
    for _, fn in ipairs({
        "GetActiveOtomoID", "GetActivatedOtomoID", "GetSpawnedOtomoID",
        "GetCurrentOtomoID", "GetControlledOtomoID",
    }) do
        pcall(function()
            if otomo[fn] then idx = otomo[fn](otomo) end
        end)
        if type(idx) == "number" and idx >= 0 then return idx end
    end
    return nil
end

local function firstFilledSlot(otomo)
    for i = 0, maxSlots(otomo) - 1 do
        if getSlotHandle(otomo, i) then return i end
    end
    return nil
end

--- active → selected → first filled (0-based)
local function resolveSlot(otomo)
    local idx = activeSlotIndex(otomo)
    if idx ~= nil and getSlotHandle(otomo, idx) then return idx end
    idx = selectedSlotIndex(otomo)
    if idx ~= nil and getSlotHandle(otomo, idx) then return idx end
    return firstFilledSlot(otomo)
end

local function storageOf(ps)
    if not isValid(ps) then return nil end
    local s = nil
    pcall(function() s = unwrap(ps:GetPalStorage()) end)
    if isValid(s) then return s end
    pcall(function() s = unwrap(ps.PalStorage) end)
    if isValid(s) then return s end
    return nil
end

local function netCOf(ps, pc)
    local netC = nil
    if isValid(ps) then
        for _, name in ipairs({ "NetworkCharacterContainerComponent", "NetworkCharacterContainer" }) do
            pcall(function() netC = unwrap(ps[name]) end)
            if isValid(netC) then return netC end
        end
        pcall(function()
            local cls = StaticFindObject("/Script/Pal.PalNetworkCharacterContainerComponent")
            if cls then netC = ps:GetComponentByClass(cls) end
        end)
        if isValid(netC) then return netC end
    end
    if isValid(pc) then
        pcall(function()
            local cls = StaticFindObject("/Script/Pal.PalNetworkCharacterContainerComponent")
            if cls then netC = pc:GetComponentByClass(cls) end
        end)
        if isValid(netC) then return netC end
    end
    -- proven fallback (prior rewrites that dropped this hit "no netC")
    local ok, c = pcall(function() return FindFirstOf("PalNetworkCharacterContainerComponent") end)
    if ok and isValid(c) then return c end
    return nil
end

--- ONE stock RPC try — Guids/ids AS-IS, no reshape.
local function tryStockRpcOnce(ps, pc, otomo, slotIndex)
    local slotObj = nil
    pcall(function() slotObj = otomo:GetOtomoIndividualCharacterSlot(slotIndex) end)
    if not isValid(slotObj) then
        log("rpc skip: no slotObj")
        return false
    end

    local netC = netCOf(ps, pc)
    if not isValid(netC) then
        log("rpc skip: no netC")
        return false
    end

    local sid, cid, page = nil, nil, 0
    pcall(function() sid = slotObj:GetSlotId() end)
    local storage = storageOf(ps)
    if isValid(storage) then
        pcall(function()
            local c = unwrap(storage.TargetContainer)
            if c and c.GetId then cid = c:GetId() end
        end)
        pcall(function() page = storage:GetPageIndexExistEmptySlot(0) or 0 end)
    end

    if sid == nil or cid == nil then
        log("rpc skip: sid=" .. tostring(sid ~= nil) .. " cid=" .. tostring(cid ~= nil))
        return false
    end

    local ok = pcall(function()
        netC:RequestMoveToPalBox_ToServer_Rep(sid, cid, page)
    end)
    log("rpc try RequestMoveToPalBox_ToServer_Rep ok=" .. tostring(ok)
        .. " page=" .. tostring(page))
    return ok
end

--- Fixed signal string. Preferred: ConsoleCommand / ProcessConsoleExec.
local function signalServer(pc, slotIndex)
    local cmd = "SENDHOME " .. tostring(slotIndex)
    local notes = {}

    local function try(name, fn)
        local ok = pcall(fn)
        notes[#notes + 1] = name .. "=" .. tostring(ok)
        return ok
    end

    try("ConsoleCommand", function()
        pc:ConsoleCommand(cmd, true)
    end)
    try("ConsoleCommand1", function()
        pc:ConsoleCommand(cmd)
    end)
    try("ProcessConsoleExec", function()
        pc:ProcessConsoleExec(cmd, nil, pc)
    end)
    try("ServerExec", function()
        pc:ServerExec(cmd)
    end)
    pcall(function()
        local kismet = StaticFindObject("/Script/Engine.Default__KismetSystemLibrary")
        if kismet and kismet.ExecuteConsoleCommand then
            local world = nil
            pcall(function() world = pc:GetWorld() end)
            kismet:ExecuteConsoleCommand(world or pc, cmd, pc)
            notes[#notes + 1] = "Kismet=true"
        end
    end)

    log("signal \"" .. cmd .. "\" " .. table.concat(notes, " "))
    return cmd
end

local function playSfxOptional(success)
    -- Optional in-game only; never OS players. Best-effort, silent if missing.
    pcall(function()
        local names = success
            and { "AKE_Player_Sphere_ReturnPal", "ReturnPal" }
            or { "AKE_Player_Sphere_CaptureFail", "CaptureFail" }
        for _, n in ipairs(names) do
            local ok, snd = pcall(function() return FindObject(nil, n) end)
            if ok and isValid(snd) and snd.Play then
                snd:Play()
                return
            end
        end
    end)
end

local function verifyLater(otomo, slotIndex)
    local function check()
        local still = false
        pcall(function()
            if isValid(otomo) then
                still = slotFilled(otomo, slotIndex)
            end
        end)
        if not still then
            log("VERIFY SUCCESS slot=" .. tostring(slotIndex) .. " party empty")
            playSfxOptional(true)
        else
            log("VERIFY FAIL slot=" .. tostring(slotIndex) .. " still in party (need server half + log)")
            playSfxOptional(false)
        end
    end

    if ExecuteWithDelay then
        ExecuteWithDelay(VERIFY_MS, function()
            if ExecuteInGameThread then
                pcall(ExecuteInGameThread, check)
            else
                check()
            end
        end)
    else
        log("VERIFY scheduled without ExecuteWithDelay — check party manually")
    end
end

local function doSendHome()
    local now = os.clock()
    if (now - lastPress) < DEBOUNCE_S then
        log("debounce")
        return
    end
    lastPress = now

    local function run()
        local pc = localController()
        if not isValid(pc) then
            log("FAIL: no local PlayerController")
            return
        end
        local ps = playerStateOf(pc)
        local otomo = otomoOf(pc)
        log("pc=" .. safeName(pc)
            .. " ps=" .. safeName(ps)
            .. " otomo=" .. safeName(otomo))

        if not isValid(otomo) then
            log("FAIL: no otomo holder")
            return
        end

        local slotIndex = resolveSlot(otomo)
        if slotIndex == nil then
            log("FAIL: no party pal")
            return
        end
        log("slot=" .. tostring(slotIndex)
            .. " active=" .. tostring(activeSlotIndex(otomo))
            .. " selected=" .. tostring(selectedSlotIndex(otomo)))

        if not slotFilled(otomo, slotIndex) then
            log("FAIL: party slot empty")
            return
        end

        -- 1) one stock RPC (harmless no-op if server ignores)
        tryStockRpcOnce(ps, pc, otomo, slotIndex)

        -- 2) signal authority
        signalServer(pc, slotIndex)

        -- 3) client-side verify window
        verifyLater(otomo, slotIndex)
    end

    if ExecuteInGameThread then
        pcall(ExecuteInGameThread, run)
    else
        run()
    end
end

-- F8 only player UX
local bound = false
pcall(function()
    RegisterKeyBind(Key.F8, function()
        doSendHome()
    end)
    bound = true
    log("keybind F8 (RegisterKeyBind)")
end)
if not bound then
    pcall(function()
        RegisterKeyBindAsync(Key.F8, {}, function()
            doSendHome()
        end)
        bound = true
        log("keybind F8 (RegisterKeyBindAsync)")
    end)
end
if not bound then
    log("WARN: could not bind F8 — check UE4SS Key API")
end

log("ready — F8 send party pal home (needs SendHomeServer on dedicated)")
