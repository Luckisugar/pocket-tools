--[[
  BaseRing2x — client-only blue palbox ring scale
  Matches CGR BaseCampAreaRange 7000 (2x of 3500).
]]

local config = require("config")

local SCALE = config.target_radius_cm / config.vanilla_radius_cm
local XY = config.vanilla_xy * SCALE
local Z = config.vanilla_z * SCALE
local XY1 = config.vanilla_xy1 * SCALE
local Z1 = config.vanilla_z1 * SCALE

local PALBOX_PATH =
    "/Game/Pal/Blueprint/MapObject/BuildObject/BP_BuildObject_PalBoxV2.BP_BuildObject_PalBoxV2_C"
local CDO_AREA = PALBOX_PATH .. ":AreaRange_GEN_VARIABLE"
local CDO_AREA1 = PALBOX_PATH .. ":AreaRange1_GEN_VARIABLE"

local function log(msg)
    if config.verbose then
        print("[BaseRing2x] " .. tostring(msg))
    end
end

local function set_scale(comp, x, y, z)
    if not comp or not comp:IsValid() then
        return false
    end
    local ok = pcall(function()
        comp.RelativeScale3D = { X = x, Y = y, Z = z }
    end)
    return ok
end

local function scale_cdo_templates()
    local a = StaticFindObject(CDO_AREA)
    local a1 = StaticFindObject(CDO_AREA1)
    set_scale(a, XY, XY, Z)
    set_scale(a1, XY1, XY1, Z1)
    log(string.format("CDO templates XY=%.2f Z=%.2f", XY, Z))
end

local function scale_instance(actor)
    if not actor or not actor:IsValid() then return end
    pcall(function()
        if actor.AreaRange and type(actor.AreaRange) ~= "number" then
            set_scale(actor.AreaRange, XY, XY, Z)
        end
        if actor.AreaRange1 and type(actor.AreaRange1) ~= "number" then
            set_scale(actor.AreaRange1, XY1, XY1, Z1)
        end
    end)
end

local function scale_all_existing()
    local boxes = FindAllOf("BP_BuildObject_PalBoxV2_C")
    if not boxes then return end
    local n = 0
    for _, box in pairs(boxes) do
        if box and box:IsValid() then
            scale_instance(box)
            n = n + 1
        end
    end
    if n > 0 then log("scaled " .. tostring(n) .. " palbox(es)") end
end

local function apply_all()
    scale_cdo_templates()
    scale_all_existing()
end

local function delayed_apply()
    ExecuteWithDelay(config.apply_delay_ms or 2000, function()
        apply_all()
    end)
end

NotifyOnNewObject("/Script/Pal.PalBaseCampModel", function()
    delayed_apply()
end)

NotifyOnNewObject("/Script/Pal.PalBuildObjectBaseCampPoint", function()
    delayed_apply()
end)

NotifyOnNewObject(PALBOX_PATH, function(palbox)
    ExecuteWithDelay(config.apply_delay_ms or 2000, function()
        scale_cdo_templates()
        scale_instance(palbox)
        scale_all_existing()
    end)
end)

RegisterHook(
    "/Script/Engine.PlayerController:ServerAcknowledgePossession",
    function()
        ExecuteWithDelay(3000, function()
            apply_all()
        end)
    end
)

-- reapply_interval_ms <= 0 means NO periodic loop
local interval = tonumber(config.reapply_interval_ms) or 0
if interval > 0 then
    local function schedule_loop()
        ExecuteWithDelay(interval, function()
            apply_all()
            schedule_loop()
        end)
    end
    ExecuteWithDelay(5000, function()
        apply_all()
        schedule_loop()
    end)
else
    ExecuteWithDelay(5000, function()
        apply_all()
    end)
end

log(string.format("loaded target=%.0fcm (no reapply loop)", config.target_radius_cm))