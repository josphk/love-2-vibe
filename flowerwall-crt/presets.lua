-- 6 CRT presets matching the original Flowerwall CRT shader.
-- Each preset is a complete parameter table.

local defaults = {
    enable_slotmask = 0, enable_gridmask = 0,
    mask_strength = 0.35, pixel_size = 3,
    enable_grain = 1, grain_strength = 0.15,
    enable_curving = 0, curve_power = 1.02,
    enable_scanlines = 1, scanlines_interval = 3,
    scanlines_opacity = 0.30, scanlines_thickness = 1,
    enable_smearing = 0, smearing_strength = 0.2,
    enable_wiggle = 0, wiggle = 0.04,
    blur_radius = 2,
    bloom_threshold = 0.30, bloom_intensity = 0.8,
}

local function preset(name, overrides)
    local p = {}
    for k, v in pairs(defaults) do p[k] = v end
    for k, v in pairs(overrides) do p[k] = v end
    return { name = name, params = p }
end

return {
    preset("3x3 Slot", {
        enable_slotmask = 1,
        pixel_size = 3,
        mask_strength = 0.35,
        enable_scanlines = 1,
        scanlines_opacity = 0.30,
        scanlines_thickness = 1,
        enable_grain = 1,
        grain_strength = 0.15,
        blur_radius = 2,
        bloom_threshold = 0.30,
        bloom_intensity = 0.8,
    }),

    preset("3x3 Grid", {
        enable_gridmask = 1,
        pixel_size = 3,
        mask_strength = 0.35,
        enable_scanlines = 1,
        scanlines_opacity = 0.30,
        scanlines_thickness = 1,
        enable_grain = 1,
        grain_strength = 0.15,
        blur_radius = 2,
        bloom_threshold = 0.30,
        bloom_intensity = 0.8,
    }),

    preset("4x4 Slot", {
        enable_slotmask = 1,
        pixel_size = 4,
        mask_strength = 0.40,
        enable_scanlines = 1,
        scanlines_opacity = 0.35,
        scanlines_thickness = 1,
        enable_grain = 1,
        grain_strength = 0.12,
        blur_radius = 3,
        bloom_threshold = 0.25,
        bloom_intensity = 0.9,
    }),

    preset("4x4 Grid", {
        enable_gridmask = 1,
        pixel_size = 4,
        mask_strength = 0.40,
        enable_scanlines = 1,
        scanlines_opacity = 0.35,
        scanlines_thickness = 1,
        enable_grain = 1,
        grain_strength = 0.12,
        blur_radius = 3,
        bloom_threshold = 0.25,
        bloom_intensity = 0.9,
    }),

    preset("VHS", {
        enable_slotmask = 0,
        enable_gridmask = 0,
        mask_strength = 0,
        enable_scanlines = 1,
        scanlines_interval = 4,
        scanlines_opacity = 0.15,
        scanlines_thickness = 1,
        enable_grain = 1,
        grain_strength = 0.30,
        enable_curving = 1,
        curve_power = 1.025,
        enable_smearing = 1,
        smearing_strength = 0.6,
        enable_wiggle = 1,
        wiggle = 0.08,
        blur_radius = 4,
        bloom_threshold = 0.35,
        bloom_intensity = 0.6,
    }),

    preset("Disabled", {
        enable_slotmask = 0,
        enable_gridmask = 0,
        mask_strength = 0,
        enable_scanlines = 0,
        scanlines_opacity = 0,
        enable_grain = 0,
        grain_strength = 0,
        enable_curving = 0,
        enable_smearing = 0,
        smearing_strength = 0,
        enable_wiggle = 0,
        wiggle = 0,
        blur_radius = 0,
        bloom_threshold = 1.0,
        bloom_intensity = 0,
    }),
}
