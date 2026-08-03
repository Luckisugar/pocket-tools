-- ZeroGrappleCD client — cooldown is largely CLIENT-side for guns
return {
    cool_down_time = 0.0,
    -- game debug flag (PalDebugSetting.bDisableGrapplingCoolDown)
    use_debug_flag = true,
    -- light re-apply while holding a grapple (ms). 0 = off. Keep >= 1000 to avoid stutter.
    hold_patch_ms = 1000,
    verbose = true,
}
