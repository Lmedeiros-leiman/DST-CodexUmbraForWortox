-- Codex Umbra for Wortox
-- Adds approved feature modules to Wortox without replacing vanilla behavior.

local codex_umbra = GetModConfigData("codex_umbra") ~= false
local panflute_troupe = GetModConfigData("panflute_troupe") ~= false

-- Shared shadow colouring, needed by both features.
if codex_umbra or panflute_troupe then
    modimport("wortox_shenanigans_tint.lua")
end

if codex_umbra then
    modimport("wortox_shenanigans_codex.lua")
end

if panflute_troupe then
    modimport("wortox_shenanigans_panflute.lua")
end

-- Add future feature imports below this line.
