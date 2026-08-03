-- ZeroGrappleCD client — no periodic FindAllOf (that stuttered)
return {
    -- tiny non-zero so UI bar finishes instead of sitting on "0"
    cool_down_time = 0.05,
    use_debug_flag = true,
    -- 0 = never loop-scan (stutter fix)
    hold_patch_ms = 0,
    verbose = true,
}
