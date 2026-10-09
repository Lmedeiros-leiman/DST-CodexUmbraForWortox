-- Shared colouring for Wortox's shadows, used by the Codex Umbra minions and
-- the panflute troupe. Imported once by modmain; features reach it through
-- the wortox_shenanigans_tint table below.

-- Look of Wortox's shadows: Maxwell's flat silhouette, coloured by Wortox's
-- skill tree. The black multiply is Maxwell's own (it erases every skin and
-- tool detail, alpha .5 is his translucency) and the add colour fills the
-- silhouette. The anim shader weights the add by the texel's alpha, so only
-- the shape is coloured, never the empty space around it.
local MINION_MULT = { 0, 0, 0, .5 }

-- Colours come from Wortox's skin portraits: no allegiance uses his own fur,
-- Lunar the Lunar skin's slate, Shadow the Shadow skin's reds pushed toward
-- maroon. Nice is lighter, Naughty darker. Index 0 on the network means
-- "not Wortox's" and leaves the vanilla look alone.
local PALETTE =
{
    --  no allegiance              lunar                      shadow
    { 0xB36955 --[[Clay Rose]], 0x6B8DA6 --[[Moonmist]], 0x8C2F3C --[[Rosewood]] }, -- nice
    { 0xA04636 --[[Imp Brick]], 0x456478 --[[Slate]],    0x6B1F2A --[[Oxblood]] },  -- neutral
    { 0x7F3428 --[[Rust]],      0x253341 --[[Midnight]], 0x3D1016 --[[Abyss]] },    -- naughty
}
local LEAN_ROW = { nice = 1, neutral = 2, naughty = 3 }
local ALLEGIANCE_COLUMN = { none = 1, lunar = 2, shadow = 3 }

-- Flattened row by row to indices 1..9 so one small network byte carries
-- the colour. Half strength: with alpha .5 the add shows the full colour.
local TINT_COLOURS = {}
for _, row in ipairs(PALETTE) do
    for _, hex in ipairs(row) do
        table.insert(TINT_COLOURS, {
            math.floor(hex / 0x10000) % 0x100 / 255 * .5,
            math.floor(hex / 0x100) % 0x100 / 255 * .5,
            hex % 0x100 / 255 * .5,
        })
    end
end

-- wortox_inclination is "nice", "naughty" or nil (balanced), kept up to date
-- by Wortox's own skill tree listeners.
local function GetTintIndex(wortox)
    local skills = wortox.components.skilltreeupdater
    local allegiance =
        (skills ~= nil and skills:IsActivated("wortox_allegiance_lunar") and "lunar") or
        (skills ~= nil and skills:IsActivated("wortox_allegiance_shadow") and "shadow") or
        "none"
    local row = LEAN_ROW[wortox.wortox_inclination] or LEAN_ROW.neutral
    return (row - 1) * #PALETTE[row] + ALLEGIANCE_COLUMN[allegiance]
end

-- Every minion built by SGshadowwaxwell's MakeMinion: Codex spells spawn
-- workers and protectors (the rest are deprecated but still spawnable) and
-- the panflute troupe uses dancers. Index 0 keeps Maxwell's look.
local SHADOW_MINION_PREFABS =
{
    "shadowworker",
    "shadowprotector",
    "shadowduelist",
    "shadowlumber",
    "shadowminer",
    "shadowdigger",
    "shadowdancer",
}
-- Spawned by the minion stategraph's DoDespawnFX. The quickspawn and reskin
-- puffs are fx.lua proxies whose visuals only exist on clients, so they keep
-- their vanilla black.
local SHADOW_FX_PREFABS =
{
    "shadow_despawn",
    "shadow_glob_fx",
}

local function ApplyMinionTint(inst, colour)
    inst.AnimState:SetMultColour(MINION_MULT[1], MINION_MULT[2], MINION_MULT[3], MINION_MULT[4])
    inst.AnimState:SetAddColour(colour[1], colour[2], colour[3], 0)
end

-- The despawn smoke art is near black, so a multiply cannot colour it; the
-- add does, and the fx keep their vanilla multiply.
local function ApplyFxTint(inst, colour)
    inst.AnimState:SetAddColour(colour[1], colour[2], colour[3], 0)
end

local function GetTint(inst)
    return inst._wortoxshen_tint ~= nil and inst._wortoxshen_tint:value() or 0
end

-- AnimState colours are not networked, so the server stores the palette
-- index on the entity and each client applies the colour itself.
local function SetupTint(inst, apply)
    inst._wortoxshen_tint = GLOBAL.net_smallbyte(
        inst.GUID, "wortoxshen.tint", "wortoxshen_tintdirty")

    if not GLOBAL.TheWorld.ismastersim then
        local function OnTintDirty(inst_)
            local colour = TINT_COLOURS[GetTint(inst_)]
            if colour ~= nil then
                apply(inst_, colour)
            end
        end
        inst:ListenForEvent("wortoxshen_tintdirty", OnTintDirty)
        -- Entities already tinted when they enter view carry the value in their initial state.
        inst:DoTaskInTime(0, OnTintDirty)
    end
end

local function SetTint(inst, index, apply)
    if inst._wortoxshen_tint ~= nil then
        inst._wortoxshen_tint:set(index)
    end
    -- Also applied on the server, which renders for a listen-server host.
    apply(inst, TINT_COLOURS[index])
end

for _, prefab in ipairs(SHADOW_MINION_PREFABS) do
    AddPrefabPostInit(prefab, function(inst)
        SetupTint(inst, ApplyMinionTint)
    end)
end

-- Palette index of the minion running the stategraph code that spawns its
-- despawn fx. Prefab post inits run inside SpawnPrefab, so those fx see it.
local pending_fx_tint = 0

for _, prefab in ipairs(SHADOW_FX_PREFABS) do
    AddPrefabPostInit(prefab, function(inst)
        SetupTint(inst, ApplyFxTint)
        if pending_fx_tint ~= 0 and GLOBAL.TheWorld.ismastersim then
            SetTint(inst, pending_fx_tint, ApplyFxTint)
        end
    end)
end

local function WithTintedFx(fn)
    return function(inst, ...)
        pending_fx_tint = GetTint(inst)
        fn(inst, ...)
        pending_fx_tint = 0
    end
end

-- Registered as "shadowmaxwell" in SGshadowwaxwell.lua. Both handlers call
-- DoDespawnFX right before removing the minion. Each lookup is guarded so a
-- game update that renames a state only loses the tinted fx.
AddStategraphPostInit("shadowmaxwell", function(sg)
    local quickdespawn = sg.states.quickdespawn
    if quickdespawn ~= nil and quickdespawn.onenter ~= nil then
        quickdespawn.onenter = WithTintedFx(quickdespawn.onenter)
    end

    local death = sg.states.death
    local animover = death ~= nil and death.events ~= nil and death.events.animover or nil
    if animover ~= nil and animover.fn ~= nil then
        animover.fn = WithTintedFx(animover.fn)
    end
end)

wortox_shenanigans_tint =
{
    GetTintIndex = GetTintIndex,
    SetTint = SetTint,
    ApplyMinionTint = ApplyMinionTint,
}
