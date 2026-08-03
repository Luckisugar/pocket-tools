--[[
  ZeroGrappleCD (client) — why server-only failed:
  CoolDownTime / grapple CD UI run on the *client* weapon + PalDebugSetting.
  Server PalSchema still useful; client must also zero CD.

  Safe: no FindAllOf spam every 2s. Uses:
    1) bDisableGrapplingCoolDown on PalDebugSetting
    2) CoolDownTime = 0 on grapple CDOs + new gun instances
    3) Hook StartCoolDown → force Rate 0 for grapple
    4) Optional 1s patch only on currently held weapon if grapple
]]

local cfg = require("config")

local function log(m)
    if cfg.verbose then
        print("[ZeroGrappleCD] " .. tostring(m))
    end
end

local function isValid(obj)
    if obj == nil then return false end
    local ok, v = pcall(function() return obj:IsValid() end)
    return ok and v == true
end

local function className(obj)
    if not isValid(obj) then return "" end
    local n = ""
    pcall(function()
        local c = obj:GetClass()
        if c and c.GetFName then n = c:GetFName():ToString()
        elseif c and c.GetName then n = c:GetName() end
    end)
    if n == "" then pcall(function() n = obj:GetFullName() end) end
    return tostring(n or "")
end

local function isGrappleWeapon(obj)
    local n = className(obj)
    return n:find("GrapplingGun", 1, true) ~= nil or n:find("Grappling", 1, true) ~= nil
end

local function patchWeapon(obj)
    if not isValid(obj) then return false end
    if not isGrappleWeapon(obj) then return false end
    local t = cfg.cool_down_time
    if t == nil then t = 0.0 end
    local ok = false
    pcall(function()
        obj.CoolDownTime = t
        ok = true
    end)
    pcall(function()
        if obj.NearCoolTimeRate ~= nil then obj.NearCoolTimeRate = 0.0 end
    end)
    -- if currently cooling, try restart CD at 0 rate
    pcall(function()
        if obj.IsCoolDown and obj:IsCoolDown() and obj.StartCoolDown then
            obj:StartCoolDown(0.0)
        end
    end)
    return ok
end

local function setDebugFlag()
    if cfg.use_debug_flag == false then return end
    local names = {
        "PalDebugSetting",
        "BP_PalDebugSetting_C",
        "Default__PalDebugSetting",
    }
    for _, n in ipairs(names) do
        local ok, obj = pcall(function() return FindFirstOf(n) end)
        if ok and isValid(obj) then
            local set = false
            pcall(function()
                obj.bDisableGrapplingCoolDown = true
                set = true
            end)
            if set then
                log("bDisableGrapplingCoolDown=true on " .. n)
                return true
            end
        end
        ok, obj = pcall(function()
            return StaticFindObject("/Script/Pal.Default__PalDebugSetting")
        end)
        if ok and isValid(obj) then
            pcall(function() obj.bDisableGrapplingCoolDown = true end)
            log("bDisableGrapplingCoolDown on Default__PalDebugSetting")
            return true
        end
    end
    -- all instances light touch once
    local okA, arr = pcall(function() return FindAllOf("PalDebugSetting") end)
    if okA and arr then
        local n = 0
        for _, obj in pairs(arr) do
            if isValid(obj) then
                pcall(function()
                    obj.bDisableGrapplingCoolDown = true
                    n = n + 1
                end)
            end
        end
        if n > 0 then
            log("bDisableGrapplingCoolDown on " .. tostring(n) .. " PalDebugSetting instance(s)")
            return true
        end
    end
    log("debug flag not found (ok if shipping strips it)")
    return false
end

local function patchCDOs()
    local classes = {
        "BP_GrapplingGun_C",
        "BP_GrapplingGun_2_C",
        "BP_GrapplingGun_3_C",
        "BP_GrapplingGun_4_C",
        "BP_AirGrapplingGun_C",
    }
    local hit = 0
    for _, cn in ipairs(classes) do
        local base = cn:gsub("_C$", "")
        local paths = {
            "/Game/Pal/Blueprint/Weapon/" .. base .. ".Default__" .. cn,
            "/Game/Pal/Blueprint/Weapon/" .. base .. "." .. cn,
        }
        for _, p in ipairs(paths) do
            local ok, obj = pcall(function() return StaticFindObject(p) end)
            if ok and isValid(obj) and patchWeapon(obj) then
                hit = hit + 1
                log("CDO " .. cn)
                break
            end
        end
    end
    return hit
end

local function patchAllGrappleInstances()
    local names = {
        "BP_GrapplingGun_C",
        "BP_GrapplingGun_2_C",
        "BP_GrapplingGun_3_C",
        "BP_GrapplingGun_4_C",
        "BP_AirGrapplingGun_C",
    }
    local n = 0
    for _, cn in ipairs(names) do
        local ok, arr = pcall(function() return FindAllOf(cn) end)
        if ok and arr then
            for _, obj in pairs(arr) do
                if patchWeapon(obj) then n = n + 1 end
            end
        end
    end
    return n
end

-- Notify when a gun is created/equipped path
local notifyPaths = {
    "/Game/Pal/Blueprint/Weapon/BP_GrapplingGun.BP_GrapplingGun_C",
    "/Game/Pal/Blueprint/Weapon/BP_GrapplingGun_2.BP_GrapplingGun_2_C",
    "/Game/Pal/Blueprint/Weapon/BP_GrapplingGun_3.BP_GrapplingGun_3_C",
    "/Game/Pal/Blueprint/Weapon/BP_GrapplingGun_4.BP_GrapplingGun_4_C",
}
for _, path in ipairs(notifyPaths) do
    pcall(function()
        NotifyOnNewObject(path, function(obj)
            pcall(function() patchWeapon(obj) end)
        end)
    end)
end
for _, cn in ipairs({
    "BP_GrapplingGun_C", "BP_GrapplingGun_2_C", "BP_GrapplingGun_3_C", "BP_GrapplingGun_4_C",
}) do
    pcall(function()
        NotifyOnNewObject(cn, function(obj)
            pcall(function() patchWeapon(obj) end)
        end)
    end)
end

-- Hook StartCoolDown: force 0 rate for grapple (native may still run; CoolDownTime=0 helps)
pcall(function()
    RegisterHook("/Script/Pal.PalWeaponBase:StartCoolDown", function(Context, Rate)
        local ok, weapon = pcall(function() return Context:get() end)
        if ok and isGrappleWeapon(weapon) then
            pcall(function() weapon.CoolDownTime = cfg.cool_down_time or 0.0 end)
            -- try set rate out-param if binding supports it
            pcall(function()
                if Rate and Rate.set then Rate:set(0.0) end
            end)
        end
    end)
    log("hooked PalWeaponBase:StartCoolDown")
end)

-- One-shot after load
pcall(function()
    ExecuteWithDelay(8000, function()
        pcall(function()
            if ExecuteInGameThread then
                ExecuteInGameThread(function()
                    setDebugFlag()
                    local c = patchCDOs()
                    local i = patchAllGrappleInstances()
                    log("boot patch cdo=" .. tostring(c) .. " inst=" .. tostring(i))
                end)
            else
                setDebugFlag()
                patchCDOs()
                patchAllGrappleInstances()
            end
        end)
    end)
end)

-- Light hold patch: only FindAllOf 5 grapple classes once per second (small set)
local hold = tonumber(cfg.hold_patch_ms) or 1000
if hold > 0 and hold < 500 then hold = 500 end
if hold > 0 and LoopAsync then
    pcall(function()
        LoopAsync(hold, function()
            pcall(function()
                if ExecuteInGameThread then
                    ExecuteInGameThread(function()
                        setDebugFlag()
                        -- only instances that already exist (few)
                        patchAllGrappleInstances()
                    end)
                else
                    setDebugFlag()
                    patchAllGrappleInstances()
                end
            end)
            return false
        end)
    end)
    log("hold_patch every " .. tostring(hold) .. "ms (grapple classes only)")
end

log("ready CLIENT ZeroGrappleCD — keep server PalSchema ZeroGrappleCD too")
