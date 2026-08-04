--[[
  Too Many Pals (Pal Pra Poha) — SERVER half
  Drop folder name for UE4SS: SendHomeServer
  DEDICATED SERVER ONLY (Steam PalServer Win64 / UE4SS)

  Listens for fixed signal:  SENDHOME <slot>
  Authority deposit for THAT player only (Executor / Controller / PlayerState).

  CRITICAL: otomo holder is on PalPlayerController, NOT the pawn.

  No admin gate. No HTTP. No file IPC. No mass ForEachUObject dumps.
  Pair with client mod SendHome (F8).
]]

local TAG = "[SendHomeServer] "
local DEBOUNCE_S = 1

local last = { t = 0, key = "" }

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

local function fstr(v)
    if v == nil then return "" end
    if type(v) == "string" then return v end
    local s = nil
    pcall(function()
        if v.ToString then s = v:ToString() end
    end)
    if type(s) == "string" and s ~= "" and not string.find(s, "FString:", 1, true) then
        return s
    end
    local raw = tostring(v)
    if string.find(raw, "FString:", 1, true) then return "" end
    return raw
end

local function safeName(obj)
    local n = "?"
    pcall(function()
        if obj and obj.GetFullName then n = obj:GetFullName() end
    end)
    return tostring(n)
end

--- Parse fixed signal only: "SENDHOME <slot>"  (optional leading / ! .)
--- returns slot number, "default", or nil
local function parseSendHome(text)
    local s = fstr(text)
    if s == "" then return nil end
    s = string.gsub(s, "^[%s/!%.]+", "")
    s = string.gsub(s, "%s+$", "")
    local word, rest = string.match(s, "^(%S+)%s*(.*)$")
    if not word then return nil end
    if string.upper(word) ~= "SENDHOME" then return nil end
    rest = string.gsub(tostring(rest or ""), "^%s+", "")
    if rest == "" then return "default" end
    local n = tonumber(string.match(rest, "^(%d+)"))
    if n ~= nil then return n end
    return "default"
end

local function allPlayerStates()
    local list = {}
    local ok, all = pcall(function() return FindAllOf("PalPlayerState") end)
    if ok and all then
        for _, ps in pairs(all) do
            if isValid(ps) then list[#list + 1] = ps end
        end
    end
    if #list == 0 then
        local ok2, one = pcall(function() return FindFirstOf("PalPlayerState") end)
        if ok2 and isValid(one) then list[1] = one end
    end
    return list
end

local function psName(ps)
    local n = ""
    pcall(function() n = fstr(ps:GetPlayerName()) end)
    if n == "" then pcall(function() n = fstr(ps.PlayerNamePrivate) end) end
    return n
end

local function controllerOf(ps)
    if not isValid(ps) then return nil end

    -- Owner is often the controller
    local owner = nil
    pcall(function() owner = unwrap(ps.Owner) end)
    if isValid(owner) then
        local n = safeName(owner)
        if string.find(n, "PlayerController", 1, true) or string.find(n, "Controller", 1, true) then
            return owner
        end
    end

    local names = {
        "PalPlayerController",
        "BP_PalPlayerController_C",
        "PlayerController",
    }
    for _, cn in ipairs(names) do
        local ok, pcs = pcall(function() return FindAllOf(cn) end)
        if ok and pcs then
            for _, pc in pairs(pcs) do
                if isValid(pc) then
                    local pcsPs = nil
                    pcall(function() pcsPs = unwrap(pc.PlayerState) end)
                    if pcsPs == ps then return pc end
                    -- equality via name fallback if userdata identity differs
                    if isValid(pcsPs) and psName(pcsPs) ~= "" and psName(pcsPs) == psName(ps) then
                        return pc
                    end
                end
            end
        end
    end
    return nil
end

local function pawnOf(ps, pc)
    local pawn = nil
    if isValid(pc) then
        pcall(function()
            pawn = unwrap(pc.Pawn) or unwrap(pc.AcknowledgedPawn) or unwrap(pc.Character)
        end)
        if isValid(pawn) then return pawn end
    end
    pcall(function() pawn = unwrap(ps.PawnPrivate) end)
    if isValid(pawn) then return pawn end
    return nil
end

--- CRITICAL: holder lives on CONTROLLER (not pawn-only).
local function otomoOf(pc, pawn)
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
                if cls then return actor:GetComponentByClass(cls) end
            end)
            if ok and isValid(c) then return c end
        end
        -- Name scan on THIS actor only (fixes silent fail of return-inside-pcall)
        local found = nil
        pcall(function()
            if not actor.K2_GetComponentsByClass then return end
            local base = StaticFindObject("/Script/Engine.ActorComponent")
            if not base then return end
            local arr = actor:K2_GetComponentsByClass(base)
            if not arr then return end
            for _, c in pairs(arr) do
                if isValid(c) then
                    local n = safeName(c)
                    if string.find(n, "OtomoPalHolder", 1, true)
                        or string.find(n, "OtomoHolder", 1, true) then
                        found = c
                        break
                    end
                end
            end
        end)
        if isValid(found) then return found end
        return nil
    end

    local c = fromActor(pc)
    if c then return c, "controller" end
    c = fromActor(pawn)
    if c then return c, "pawn" end

    -- owned component match only (never bare FindFirstOf — multiplayer theft risk)
    for _, name in ipairs(classNames) do
        local ok, all = pcall(function() return FindAllOf(name) end)
        if ok and all then
            for _, h in pairs(all) do
                if isValid(h) then
                    local owner = nil
                    pcall(function()
                        if h.GetOwner then owner = h:GetOwner() end
                    end)
                    if not isValid(owner) then
                        pcall(function() owner = unwrap(h.Owner) end)
                    end
                    if owner == pc or owner == pawn then
                        return h, "owned"
                    end
                    -- name match: component outer path contains controller name
                    if isValid(pc) then
                        local hn, pn = safeName(h), safeName(pc)
                        local short = string.match(pn, "([%w_]+)$") or ""
                        if short ~= "" and string.find(hn, short, 1, true) then
                            return h, "owned-name"
                        end
                    end
                end
            end
        end
    end
    return nil, "none"
end

local function storageOf(ps)
    local s = nil
    pcall(function() s = unwrap(ps:GetPalStorage()) end)
    if isValid(s) then return s end
    pcall(function() s = unwrap(ps.PalStorage) end)
    if isValid(s) then return s end
    pcall(function()
        local util = StaticFindObject("/Script/Pal.Default__PalUtility")
        if util and util.GetLocalPalStorageData then
            s = util:GetLocalPalStorageData(ps)
        end
    end)
    if isValid(s) then return s end
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

local function resolveSlot(otomo, want)
    if type(want) == "number" then return want end
    local idx = activeSlotIndex(otomo)
    if idx ~= nil and getSlotHandle(otomo, idx) then return idx end
    idx = selectedSlotIndex(otomo)
    if idx ~= nil and getSlotHandle(otomo, idx) then return idx end
    return firstFilledSlot(otomo)
end

local function slotFilled(otomo, slotIndex)
    return getSlotHandle(otomo, slotIndex) ~= nil
end

local function netCOf(ps, pc)
    local netC = nil
    if isValid(ps) then
        pcall(function() netC = unwrap(ps.NetworkCharacterContainerComponent) end)
        if isValid(netC) then return netC end
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
    return nil
end

local function forceDeposit(ps, slotWant)
    local pc = controllerOf(ps)
    local pawn = pawnOf(ps, pc)
    local otomo, otomoSrc = otomoOf(pc, pawn)
    local storage = storageOf(ps)
    local netC = netCOf(ps, pc)

    log("player=" .. psName(ps)
        .. " pc=" .. safeName(pc)
        .. " pawn=" .. safeName(pawn)
        .. " otomo=" .. safeName(otomo) .. " (src=" .. tostring(otomoSrc) .. ")"
        .. " storage=" .. safeName(storage)
        .. " netC=" .. safeName(netC))

    if not isValid(otomo) then
        log("FAIL: no otomo")
        return false
    end

    local slotIndex = resolveSlot(otomo, slotWant)
    log("slot=" .. tostring(slotIndex)
        .. " want=" .. tostring(slotWant)
        .. " selected=" .. tostring(selectedSlotIndex(otomo))
        .. " active=" .. tostring(activeSlotIndex(otomo)))

    if slotIndex == nil then
        log("FAIL: no party pal")
        return false
    end

    local handle = getSlotHandle(otomo, slotIndex)
    local slotObj = nil
    pcall(function() slotObj = otomo:GetOtomoIndividualCharacterSlot(slotIndex) end)

    if not isValid(handle) then
        pcall(function()
            if isValid(slotObj) then handle = slotObj:GetHandle() end
        end)
    end
    if not isValid(handle) then
        log("FAIL: party slot empty")
        return false
    end

    local notes = {}
    local function emptied()
        return not slotFilled(otomo, slotIndex)
    end

    -- tryCall: distinguish missing / err / ran / MOVED (pcall-ok alone was useless)
    local function tryCall(label, fn)
        local ok, err = pcall(fn)
        if not ok then
            notes[#notes + 1] = label .. "=err:" .. tostring(err):sub(1, 50)
            return false
        end
        if emptied() then
            notes[#notes + 1] = label .. "=MOVED"
            log("SUCCESS via " .. label)
            log("tries: " .. table.concat(notes, " | "))
            return true
        end
        notes[#notes + 1] = label .. "=ran"
        return false
    end

    local function hasMethod(obj, name)
        if not isValid(obj) then return false end
        local ok, m = pcall(function() return obj[name] end)
        return ok and m ~= nil
    end

    -- a) UObject/int methods on otomo / handle / slot (preferred)
    for _, name in ipairs({
        "RequestReturnOtomoPal", "ReturnOtomoPal", "ReturnOtomoPalToHolder",
        "SendOtomoToPalBox", "RequestSendOtomoToPalBox", "MoveOtomoToPalBox",
        "RemoveOtomo", "RequestRemoveOtomo", "InactivateOtomo", "ReturnOtomo",
    }) do
        if hasMethod(otomo, name) then
            if tryCall("otomo." .. name, function()
                otomo[name](otomo, slotIndex)
            end) then return true end
            if tryCall("otomo." .. name .. "(handle)", function()
                otomo[name](otomo, handle)
            end) then return true end
        end
    end

    if isValid(handle) then
        for _, name in ipairs({ "RequestReturn", "ReturnToPalBox", "SendToPalBox", "Return" }) do
            if hasMethod(handle, name) then
                if tryCall("handle." .. name, function()
                    handle[name](handle)
                end) then return true end
            end
        end
    end

    if isValid(slotObj) then
        for _, name in ipairs({ "RequestMoveToPalBox", "MoveToPalBox", "SendToPalBox" }) do
            if hasMethod(slotObj, name) then
                if tryCall("slot." .. name, function()
                    slotObj[name](slotObj)
                end) then return true end
            end
        end
    end

    -- b) storage / box AddIndividualHandle (simple UObject args)
    local box = nil
    if isValid(storage) then
        pcall(function() box = unwrap(storage.TargetContainer) end)
    end

    if isValid(storage) and isValid(handle) then
        for _, name in ipairs({
            "AddIndividualHandle", "AddCharacterHandle", "PushCharacterHandle",
            "AddPal", "StorePal", "AddHandle", "MoveIn",
        }) do
            if hasMethod(storage, name) then
                if tryCall("storage." .. name, function()
                    storage[name](storage, handle)
                end) then return true end
                if tryCall("storage." .. name .. "+0", function()
                    storage[name](storage, handle, 0)
                end) then return true end
            end
        end
    end

    if isValid(box) and isValid(handle) then
        for _, name in ipairs({ "AddIndividualHandle", "AssignIndividualHandle", "AddCharacterHandle" }) do
            if hasMethod(box, name) then
                if tryCall("box." .. name, function()
                    box[name](box, handle)
                end) then return true end
            end
        end
    end

    local util = nil
    pcall(function() util = StaticFindObject("/Script/Pal.Default__PalUtility") end)
    if util then
        local ctx = pc or pawn or ps
        for _, name in ipairs({
            "SendOtomoToPalStorage", "MoveOtomoToPalBox", "ReturnOtomoToPalBox",
            "RequestMoveOtomoToPalBox", "InactivatePlayerOtomoPal", "ReturnOtomoPal",
        }) do
            if hasMethod(util, name) then
                if tryCall("util." .. name .. "(handle)", function()
                    util[name](util, ctx, handle)
                end) then return true end
                if tryCall("util." .. name .. "(slot)", function()
                    util[name](util, ctx, slotIndex)
                end) then return true end
            end
        end
    end

    -- c) RequestMoveToPalBox / RequestMove AS-IS last resort
    if isValid(netC) and isValid(slotObj) then
        local sid, cid, page = nil, nil, 0
        pcall(function() sid = slotObj:GetSlotId() end)
        if isValid(storage) then
            pcall(function()
                local c = unwrap(storage.TargetContainer)
                if c and c.GetId then cid = c:GetId() end
            end)
            pcall(function() page = storage:GetPageIndexExistEmptySlot(0) or 0 end)
        end
        log("ids slotId=" .. tostring(sid ~= nil)
            .. " boxId=" .. tostring(cid ~= nil)
            .. " page=" .. tostring(page))
        if sid and cid then
            if tryCall("netC.RequestMoveToPalBox_ToServer_Rep", function()
                netC:RequestMoveToPalBox_ToServer_Rep(sid, cid, page)
            end) then return true end
            if hasMethod(netC, "RequestMove_ToServer_Rep") then
                if tryCall("netC.RequestMove_ToServer_Rep", function()
                    netC:RequestMove_ToServer_Rep(sid, cid)
                end) then return true end
            end
            if hasMethod(netC, "RequestMoveToContainer_ToServer") then
                if tryCall("netC.RequestMoveToContainer_ToServer", function()
                    netC:RequestMoveToContainer_ToServer(sid, cid)
                end) then return true end
            end
        else
            notes[#notes + 1] = "netC.ids=false"
        end
    else
        notes[#notes + 1] = "netC.path_skipped"
    end

    log("tries: " .. table.concat(notes, " | "))
    if emptied() then
        log("SUCCESS")
        return true
    end
    log("FAIL: still in party after all methods")
    return false
end

local function psFromContext(context)
    if not isValid(context) then return nil end
    local n = safeName(context)
    if string.find(n, "PlayerState", 1, true) then return context end

    local ps = nil
    pcall(function() ps = unwrap(context.PlayerState) end)
    if isValid(ps) then return ps end

    -- Executor may be controller
    if string.find(n, "Controller", 1, true) then
        pcall(function() ps = unwrap(context.PlayerState) end)
        if isValid(ps) then return ps end
    end

    pcall(function()
        local outer = context.GetOuter and context:GetOuter() or nil
        local guard = 0
        while isValid(outer) and guard < 8 do
            guard = guard + 1
            local try = nil
            pcall(function() try = unwrap(outer.PlayerState) end)
            if isValid(try) then ps = try break end
            local on = safeName(outer)
            if string.find(on, "PlayerState", 1, true) then ps = outer break end
            outer = outer.GetOuter and outer:GetOuter() or nil
        end
    end)
    return ps
end

local function handleSignal(source, text, context)
    local want = parseSendHome(text)
    if want == nil then return end

    local now = os.time()
    local key = tostring(source) .. "|" .. fstr(text) .. "|" .. safeName(context)
    if last.key == key and (now - last.t) < DEBOUNCE_S then return end
    last = { t = now, key = key }

    log("signal source=" .. tostring(source)
        .. " text=" .. fstr(text)
        .. " want=" .. tostring(want)
        .. " ctx=" .. safeName(context))

    local function run()
        local ps = psFromContext(context)
        if not ps then
            local all = allPlayerStates()
            if #all == 1 then
                ps = all[1]
            elseif #all > 1 then
                ps = all[1]
                log("WARN: multi players, weak owner bind — using " .. psName(ps))
            end
        end
        if not ps then
            log("FAIL: no player online")
            return
        end
        forceDeposit(ps, want)
    end

    if ExecuteInGameThread then
        pcall(ExecuteInGameThread, run)
    else
        run()
    end
end

-- Console command registration (host console + routed client cmds)
local function registerConsole(name)
    pcall(function()
        RegisterConsoleCommandHandler(name, function(FullCommand, Parts, Ar)
            local slot = Parts[2] and tonumber(Parts[2]) or "default"
            log("console " .. name .. " " .. tostring(slot))
            local all = allPlayerStates()
            if #all < 1 then
                log("console: no players")
                return true
            end
            local ps = all[1]
            if #all > 1 then
                log("WARN: console multi-player — using " .. psName(ps))
            end
            if ExecuteInGameThread then
                ExecuteInGameThread(function() forceDeposit(ps, slot) end)
            else
                forceDeposit(ps, slot)
            end
            return true
        end)
    end)
    pcall(function()
        RegisterConsoleCommandGlobalHandler(name, function(FullCommand, Parts, Ar)
            local slot = Parts[2] and tonumber(Parts[2]) or "default"
            local all = allPlayerStates()
            if #all >= 1 then
                local ps = all[1]
                if ExecuteInGameThread then
                    ExecuteInGameThread(function() forceDeposit(ps, slot) end)
                else
                    forceDeposit(ps, slot)
                end
            end
            return true
        end)
    end)
end

registerConsole("SENDHOME")
registerConsole("sendhome")

-- Primary path: client ConsoleCommand / ProcessConsoleExec
pcall(function()
    RegisterProcessConsoleExecPreHook(function(Context, Cmd, CommandParts, Ar, Executor)
        local text = fstr(Cmd)
        if parseSendHome(text) ~= nil then
            handleSignal("ProcessConsoleExec", text, Executor or Context)
        end
    end)
    log("hook ProcessConsoleExec ok")
end)

-- Optional chat mirror (debug only — F8 is primary UX).
-- ONLY proven dedicated paths (mass wrong hooks previously caused instability).
local chatHooks = {
    "/Script/Pal.PalPlayerController:EnterChat_Receive",
    "/Script/Pal.PalPlayerState:EnterChat",
}

for _, path in ipairs(chatHooks) do
    pcall(function()
        RegisterHook(path, function(Context, A, B, C, D)
            local okh, errh = pcall(function()
                local ctx = Context
                pcall(function() if Context and Context.get then ctx = Context:get() end end)
                for _, arg in ipairs({ A, B, C, D }) do
                    local v = arg
                    pcall(function() if arg and arg.get then v = arg:get() end end)
                    local text = fstr(v)
                    if parseSendHome(text) ~= nil then
                        handleSignal("chat:" .. path, text, ctx)
                        return
                    end
                end
            end)
            if not okh then log("chat hook err: " .. tostring(errh)) end
        end)
        log("chat hook OK " .. path)
    end)
end

log("ready — signal SENDHOME <slot> (all players, no admin gate)")
log("SERVER ONLY — pair with client SendHome F8")
