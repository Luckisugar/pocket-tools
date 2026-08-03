-- SendHome config
return {
    -- F8 avoids inventory eating letter keys (Y often never reaches UE4SS).
    -- Change to "Y" after F8 works if you want the old bind.
    key = "F8",
    modifier = "NONE",   -- NONE | ALT | CTRL | SHIFT  (RegisterKeyBind path only)
    -- active = currently out / battle slot
    -- selected = game selected otomo id (1-5 / wheel)
    -- first = first filled party slot
    target = "active",
    verbose = true,
    -- also poll IsKeyDown every 50ms (works better with UI open than RegisterKeyBind alone)
    use_poll = true,
}
