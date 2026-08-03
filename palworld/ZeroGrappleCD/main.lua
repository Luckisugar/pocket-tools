--[[
  ZeroGrappleCD — client UE4SS
  Sets CoolDownTime / NearCoolTimeRate on all grappling gun CDOs + live instances.
  Pair with PalSchema ZeroGrappleCD on the dedicated server for authority.
]]

local cfg = require("config")

local function log(m)
    if cfg.verbose then
        print("[ZeroGrappleCD] " .. tostring(m))
    end
end

local CLASSES = {
    "BP_GrapplingGun_C",
    "BP_GrapplingGun_2_C",
    "BP_GrapplingGun_3_C",
    "BP_GrapplingGun_4_C",
}

local function patchObj(obj)
    if not obj or not obj:IsValid() then return false end
    local ok = false
    local t = cfg.cool_down_time
    if t == nil then t = 0.0 end
    local r = cfg.near_cool_time_rate
    if r == nil then r = 0.0 end
    pcall(function()
        if obj.CoolDownTime ~= nil then
            obj.CoolDownTime = t
            ok = true
        end
    end)
    pcall(function()
        if obj.NearCoolTimeRate ~= nil then
            obj.NearCoolTimeRate = r
        end
    end)
    return ok
end

local function patchCDO(className)
    local paths = {
        "/Game/Pal/Blueprint/Weapon/" .. className:gsub("_C$", "") .. ".Default__" .. className,
        "/Script/Pal.Default__" .. className,
    }
    -- also bare Default via StaticFindObject class default
    for _, p in ipairs(paths) do
        local ok, obj = pcall(function() return StaticFindObject(p) end)
        if ok and obj and obj:IsValid() and patchObj(obj) then
            log("CDO " .. className .. " via " .. p)
            return true
        end
    end
    local ok, cls = pcall(function() return StaticFindObject("/Game/Pal/Blueprint/Weapon/" .. className:gsub("_C$", "") .. "." .. className) end)
    if ok and cls and cls:IsValid() then
        local cdo = nil
        pcall(function() cdo = cls:GetCDO() end)
        if cdo and cdo:IsValid() and patchObj(cdo) then
            log("CDO " .. className .. " via GetCDO")
            return true
        end
    end
    return false
end

local function patchAllInstances(className)
    local n = 0
    local ok, arr = pcall(function() return FindAllOf(className) end)
    if ok and arr then
        for _, obj in pairs(arr) do
            if patchObj(obj) then n = n + 1 end
        end
    end
    return n
end

local function runPatch()
    local cdoHit, instHit = 0, 0
    for _, name in ipairs(CLASSES) do
        if patchCDO(name) then cdoHit = cdoHit + 1 end
        instHit = instHit + patchAllInstances(name)
    end
    -- catch any future subclass still named *Grappling*
    local ok, any = pcall(function() return FindAllOf("BP_GrapplingGun_C") end)
    if ok and any then
        for _, obj in pairs(any) do
            patchObj(obj)
        end
    end
    log("patch cdo_classes=" .. tostring(cdoHit) .. " instances=" .. tostring(instHit)
        .. " cd=" .. tostring(cfg.cool_down_time))
end

-- patch when a gun spawns
for _, name in ipairs(CLASSES) do
    local path = "/Game/Pal/Blueprint/Weapon/" .. name:gsub("_C$", "") .. "." .. name
    pcall(function()
        NotifyOnNewObject(path, function(obj)
            pcall(function()
                if ExecuteInGameThread then
                    ExecuteInGameThread(function() patchObj(obj) end)
                else
                    patchObj(obj)
                end
            end)
        end)
    end)
    pcall(function()
        NotifyOnNewObject(name, function(obj)
            pcall(function() patchObj(obj) end)
        end)
    end)
end

-- delayed + periodic (guns already equipped)
local function schedule()
    pcall(function()
        ExecuteWithDelay(3000, function()
            pcall(runPatch)
        end)
    end)
    local ms = cfg.rescan_ms or 2000
    if LoopAsync and ms > 0 then
        pcall(function()
            LoopAsync(ms, function()
                pcall(function()
                    if ExecuteInGameThread then
                        ExecuteInGameThread(runPatch)
                    else
                        runPatch()
                    end
                end)
                return false
            end)
        end)
    end
end

schedule()
log("ready — CoolDownTime=" .. tostring(cfg.cool_down_time or 0)
    .. " (client patch; use PalSchema ZeroGrappleCD on server too)")
