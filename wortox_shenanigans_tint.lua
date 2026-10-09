-- Shared colouring for Wortox's shadows, used by the Codex Umbra minions and
-- the panflute troupe. Imported once by modmain; features reach it through
-- the wortox_shenanigans_tint table below.

-- Look of Wortox's shadows: Maxwell's flat silhouette, coloured by Wortox's
-- skill tree. The black multiply is Maxwell's own (it erases every skin and
-- tool detail, alpha .5 is his translucency) and the add colour fills the
-- silhouette. The anim shader weights the add by the texel's alpha, so only
-- the shape is coloured, never the empty space around it.
local MINION_MULT = { 0, 0, 0, .5 }

-- The lean sets the base: Neutral is crimson, Nice a pinkish red, Naughty a
-- deep blood red toward Maxwell's black. The allegiance tints it: Shadow
-- darkens every lean toward wine and violet (Naughty is the darkest colour),
-- Lunar turns it into the cyan of a gestalt. Darks stay saturated on purpose:
-- a red-black reads against brown terrain, a grey-black melts into it, and the
-- shader caps each channel at the shadow's alpha, which washes out pastels.
-- Index 0 on the network means "not Wortox's" and leaves the vanilla look alone.
local PALETTE =
{
    --  no allegiance                lunar                      shadow
    { 0xFF6F91 --[[Rose]],        0x7FE8FF --[[Moonbeam]],  0xA0206A --[[Dusk Rose]] }, -- nice
    { 0xDC143C --[[Crimson]],     0x2FD0F0 --[[Gestalt]],   0x7A0A3A --[[Wine]]    },   -- neutral
    { 0x8A0A22 --[[Blood]],       0x1580B0 --[[Deep Moon]], 0x4E0418 --[[Void Red]] },  -- naughty
}
-- Per allegiance. The anim shader lights a pixel by max(world light, light
-- override), so the override keeps the colour readable at night. Lunar glows
-- through the bloom pass the way gestalts do.
local ALLEGIANCE_GLOW =
{
    { light = .3 },               -- no allegiance
    { light = .55, bloom = true }, -- lunar
    { light = .3 },               -- shadow
}
local LEAN_ROW = { nice = 1, neutral = 2, naughty = 3 }
local ALLEGIANCE_COLUMN = { none = 1, lunar = 2, shadow = 3 }
local BLOOM_SHADER = "shaders/anim.ksh"

-- Flattened row by row to indices 1..9 so one small network byte carries
-- the tint. Half strength: with alpha .5 the add shows the full colour.
local TINTS = {}
for _, row in ipairs(PALETTE) do
    for column, hex in ipairs(row) do
        table.insert(TINTS, {
            r = math.floor(hex / 0x10000) % 0x100 / 255 * .5,
            g = math.floor(hex / 0x100) % 0x100 / 255 * .5,
            b = hex % 0x100 / 255 * .5,
            light = ALLEGIANCE_GLOW[column].light,
            bloom = ALLEGIANCE_GLOW[column].bloom,
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

-- Set every time, so a respec from Lunar to another allegiance drops the bloom.
local function ApplyGlow(inst, tint)
    inst.AnimState:SetLightOverride(tint.light)
    if tint.bloom then
        inst.AnimState:SetBloomEffectHandle(BLOOM_SHADER)
    else
        inst.AnimState:ClearBloomEffectHandle()
    end
end

local function ApplyMinionTint(inst, tint)
    inst.AnimState:SetMultColour(MINION_MULT[1], MINION_MULT[2], MINION_MULT[3], MINION_MULT[4])
    inst.AnimState:SetAddColour(tint.r, tint.g, tint.b, 0)
    ApplyGlow(inst, tint)
end

-- The despawn smoke art is near black, so a multiply cannot colour it; the
-- add does, and the fx keep their vanilla multiply.
local function ApplyFxTint(inst, tint)
    inst.AnimState:SetAddColour(tint.r, tint.g, tint.b, 0)
    ApplyGlow(inst, tint)
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
            local tint = TINTS[GetTint(inst_)]
            if tint ~= nil then
                apply(inst_, tint)
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
    apply(inst, TINTS[index])
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
