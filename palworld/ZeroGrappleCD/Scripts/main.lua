--[[
  ZeroGrappleCD client v2 — works without stutter

  REMOVED: 1s LoopAsync FindAllOf (caused crazy hitching)
  KEEP: debug flag once, CDO patch once, NotifyOnNewObject, StartCoolDown hook
  CoolDownTime = 0.05 so UI doesn't freeze on "0" for ages
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
    return n:find("GrapplingGun", 1, true) ~= nil
end

local function patchWeapon(obj)
    if not isValid(obj) or not isGrappleWeapon(obj) then return false end
    local t = tonumber(cfg.cool_down_time)
    if t == nil then t = 0.05 end
    if t <= 0 then t = 0.05 end -- avoid UI stuck at 0
    local ok = false
    pcall(function()
        obj.CoolDownTime = t
        ok = true
    end)
    pcall(function()
        if obj.NearCoolTimeRate ~= nil then obj.NearCoolTimeRate = 0.0 end
    end)
    return ok
end

local function setDebugFlagOnce()
    if cfg.use_debug_flag == false then return end
    local ok, obj = pcall(function()
        return StaticFindObject("/Script/Pal.Default__PalDebugSetting")
    end)
    if ok and isValid(obj) then
        pcall(function() obj.bDisableGrapplingCoolDown = true end)
        log("debug flag on Default__PalDebugSetting")
        return
    end
    ok, obj = pcall(function() return FindFirstOf("PalDebugSetting") end)
    if ok and isValid(obj) then
        pcall(function() obj.bDisableGrapplingCoolDown = true end)
        log("debug flag on PalDebugSetting instance")
    end
end

local function patchCDOs()
    local classes = {
        "BP_GrapplingGun_C",
        "BP_GrapplingGun_2_C",
        "BP_GrapplingGun_3_C",
        "BP_GrapplingGun_4_C",
    }
    local hit = 0
    for _, cn in ipairs(classes) do
        local base = cn:gsub("_C$", "")
        local p = "/Game/Pal/Blueprint/Weapon/" .. base .. ".Default__" .. cn
        local ok, obj = pcall(function() return StaticFindObject(p) end)
        if ok and isValid(obj) and patchWeapon(obj) then
            hit = hit + 1
        end
    end
    return hit
end

local function patchInstancesOnce()
    local names = {
        "BP_GrapplingGun_C",
        "BP_GrapplingGun_2_C",
        "BP_GrapplingGun_3_C",
        "BP_GrapplingGun_4_C",
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

for _, cn in ipairs({
    "BP_GrapplingGun_C", "BP_GrapplingGun_2_C",
    "BP_GrapplingGun_3_C", "BP_GrapplingGun_4_C",
}) do
    local base = cn:gsub("_C$", "")
    local path = "/Game/Pal/Blueprint/Weapon/" .. base .. "." .. cn
    pcall(function()
        NotifyOnNewObject(path, function(obj)
            pcall(function() patchWeapon(obj) end)
        end)
    end)
    pcall(function()
        NotifyOnNewObject(cn, function(obj)
            pcall(function() patchWeapon(obj) end)
        end)
    end)
end

pcall(function()
    RegisterHook("/Script/Pal.PalWeaponBase:StartCoolDown", function(Context, Rate)
        local ok, weapon = pcall(function() return Context:get() end)
        if ok and isGrappleWeapon(weapon) then
            pcall(function()
                weapon.CoolDownTime = tonumber(cfg.cool_down_time) or 0.05
            end)
            pcall(function()
                if Rate and Rate.set then Rate:set(0.0) end
            end)
        end
    end)
    log("hooked StartCoolDown")
end)

-- ONE boot pass only (no repeating FindAllOf loop)
pcall(function()
    ExecuteWithDelay(10000, function()
        pcall(function()
            local function run()
                setDebugFlagOnce()
                local c = patchCDOs()
                local i = patchInstancesOnce()
                log("boot once cdo=" .. tostring(c) .. " inst=" .. tostring(i))
            end
            if ExecuteInGameThread then
                ExecuteInGameThread(run)
            else
                run()
            end
        end)
    end)
end)

-- hold_patch_ms must stay 0 — intentional, do not re-enable loops
log("ready v2 — no scan loop, CoolDownTime=" .. tostring(cfg.cool_down_time or 0.05))
