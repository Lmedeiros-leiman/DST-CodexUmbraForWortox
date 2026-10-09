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

local SHADOW_MINION_PREFABS =
{
    "shadowworker",
    "shadowprotector",
    "shadowduelist",
    "shadowlumber",
    "shadowminer",
    "shadowdigger",
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

-- Vanilla shadow minions have no inspectable component, so nobody can examine
-- them. Wortox's can: the leader sees WORTOX_MINE, everyone else (another
-- Wortox included) sees WORTOX_OTHER. The strings live under the minions'
-- name override, SHADOWWAXWELL, and only use these statuses, so Maxwell's
-- shadows never pick up these lines.
local function GetShadowStatus(inst, viewer)
    local leader = inst.components.follower ~= nil and inst.components.follower:GetLeader() or nil
    return leader ~= nil and leader == viewer and "WORTOX_MINE" or "WORTOX_OTHER"
end

local function MakeInspectable(pet)
    if pet.components.inspectable == nil then
        pet:AddComponent("inspectable")
    end
    pet.components.inspectable.getstatus = GetShadowStatus
end

local function KillPet(pet)
    if pet.components.health:IsInvincible() then
        pet._killtask = pet:DoTaskInTime(.5, KillPet)
    else
        pet.components.health:Kill()
    end
end

local function OnSpawnPet(inst, pet)
    if pet:HasTag("shadowminion") then
        SetTint(pet, GetTintIndex(inst), ApplyMinionTint)
        MakeInspectable(pet)
        if not (inst.components.health:IsDead() or inst:HasTag("playerghost")) then
            inst.components.sanity:AddSanityPenalty(pet,
                GLOBAL.TUNING.SHADOWWAXWELL_SANITY_PENALTY[string.upper(pet.prefab)])
            inst:ListenForEvent("onremove", inst._onpetlost, pet)
            pet.components.skinner:CopySkinsFromPlayer(inst)
        elseif pet._killtask == nil then
            pet._killtask = pet:DoTaskInTime(math.random(), KillPet)
        end
    elseif inst._wortoxshen_onspawnpet ~= nil then
        inst._wortoxshen_onspawnpet(inst, pet)
    end
end

local function OnDespawnPet(inst, pet)
    if pet:HasTag("shadowminion") then
        if not inst.is_snapshot_user_session and not inst.is_despawning then
            if pet.components.inventory then
                pet.components.inventory:DropEverything()
            end
        end
        if not inst.is_snapshot_user_session and pet.sg ~= nil then
            pet.sg:GoToState("quickdespawn")
        else
            pet:Remove()
        end
    elseif inst._wortoxshen_ondespawnpet ~= nil then
        inst._wortoxshen_ondespawnpet(inst, pet)
    end
end

local function ReskinPet(pet, player, nofx)
    pet._dressuptask = nil
    if player:IsValid() then
        if not nofx then
            local x, y, z = pet.Transform:GetWorldPosition()
            local fx = GLOBAL.SpawnPrefab("slurper_respawn")
            fx.Transform:SetPosition(x, y, z)
        end
        pet.components.skinner:CopySkinsFromPlayer(player)
    end
end

local function OnSkinsChanged(inst, data)
    for _, pet in pairs(inst.components.petleash:GetPets()) do
        if pet:HasTag("shadowminion") then
            if pet._dressuptask ~= nil then
                pet._dressuptask:Cancel()
                pet._dressuptask = nil
            end
            if data and data.nofx then
                ReskinPet(pet, inst, data.nofx)
            else
                pet._dressuptask = pet:DoTaskInTime(math.random() * .5 + .25, ReskinPet, inst)
            end
        end
    end
end

local function OnDeath(inst)
    for _, pet in pairs(inst.components.petleash:GetPets()) do
        if pet:HasTag("shadowminion") and pet._killtask == nil then
            pet._killtask = pet:DoTaskInTime(math.random(), KillPet)
        end
    end
end

local function OnBecameGhost(inst)
    for _, pet in pairs(inst.components.petleash:GetPets()) do
        if pet:HasTag("shadowminion") then
            inst:RemoveEventCallback("onremove", inst._onpetlost, pet)
            inst.components.sanity:RemoveSanityPenalty(pet)
            if pet._killtask == nil then
                pet._killtask = pet:DoTaskInTime(math.random(), KillPet)
            end
        end
    end
end

-- Skill changes recolour shadows that are already out. Wortox's own
-- listeners run first, so wortox_inclination is current by then.
local function RetintShadowMinions(inst)
    local index = GetTintIndex(inst)
    for _, pet in pairs(inst.components.petleash:GetPets()) do
        if pet:HasTag("shadowminion") then
            SetTint(pet, index, ApplyMinionTint)
        end
    end
end

local function ForceDespawnShadowMinions(inst)
    local todespawn = {}
    for _, pet in pairs(inst.components.petleash:GetPets()) do
        if pet:HasTag("shadowminion") then
            table.insert(todespawn, pet)
        end
    end
    for _, pet in ipairs(todespawn) do
        inst.components.petleash:DespawnPet(pet)
    end
end

local function OnDespawn(inst, migrationdata)
    inst.is_despawning = true
    if migrationdata ~= nil then
        ForceDespawnShadowMinions(inst)
    end
end

local function OnLoad(inst, original, ...)
    if original ~= nil then
        original(inst, ...)
    end
    OnSkinsChanged(inst, { nofx = true })
end

-- Vanilla speech_wortox.lua already defines these tables; NO_MAX_SANITY and
-- NEEDSFUEL otherwise fall back to Wilson's "only_used_by_waxwell".
local wortox_speech = GLOBAL.STRINGS.CHARACTERS.WORTOX
wortox_speech.ACTIONFAIL.CASTAOE.NO_MAX_SANITY =
    "No room, no room! My head's too full of gloom!"
wortox_speech.DESCRIBE.WAXWELLJOURNAL.GENERIC =
    "His shadowy tricks are mine to mix, hyuyu!"
wortox_speech.DESCRIBE.WAXWELLJOURNAL.NEEDSFUEL =
    "Empty of dread, the book plays dead."

local function SetShadowDescription(character, status, line)
    local describe = GLOBAL.STRINGS.CHARACTERS[character].DESCRIBE
    if type(describe.SHADOWWAXWELL) ~= "table" then
        describe.SHADOWWAXWELL = { GENERIC = describe.SHADOWWAXWELL }
    end
    describe.SHADOWWAXWELL[status] = line
end

SetShadowDescription("WORTOX", "WORTOX_MINE", "My shadow, my double, my partner in trouble!")
SetShadowDescription("WORTOX", "WORTOX_OTHER", "Another imp's shade! What mischief we've made!")
SetShadowDescription("WAXWELL", "WORTOX_OTHER", "That imp has been rifling through my notes.")
-- Everyone else falls back to the generic (Wilson) table.
SetShadowDescription("GENERIC", "WORTOX_OTHER", "That shadow has a devilish tint.")

AddPrefabPostInit("wortox", function(inst)
    inst:AddTag("shadowmagic")

    if not GLOBAL.TheWorld.ismastersim then
        return
    end

    local petleash = inst.components.petleash
    if petleash == nil then
        inst:AddComponent("petleash")
        petleash = inst.components.petleash
        petleash:SetMaxPets(6)
    else
        inst._wortoxshen_onspawnpet = petleash.onspawnfn
        inst._wortoxshen_ondespawnpet = petleash.ondespawnfn
        petleash:SetMaxPets(petleash:GetMaxPets() + 6)
    end

    if inst._onpetlost == nil then
        inst._onpetlost = function(pet)
            inst.components.sanity:RemoveSanityPenalty(pet)
        end
    end

    petleash:SetOnSpawnFn(OnSpawnPet)
    petleash:SetOnDespawnFn(OnDespawnPet)

    inst:ListenForEvent("death", OnDeath)
    inst:ListenForEvent("ms_becameghost", OnBecameGhost)
    inst:ListenForEvent("ms_playerreroll", ForceDespawnShadowMinions)
    inst:ListenForEvent("onskinschanged", OnSkinsChanged)
    inst:ListenForEvent("wortox_inclination_changed", RetintShadowMinions)
    inst:ListenForEvent("onactivateskill_server", RetintShadowMinions)
    inst:ListenForEvent("ondeactivateskill_server", RetintShadowMinions)
    inst:ListenForEvent("ms_skilltreeinitialized", RetintShadowMinions)

    local original_ondespawn = inst._OnDespawn
    inst._OnDespawn = function(inst_, ...)
        local migrationdata = ...
        OnDespawn(inst_, migrationdata)
        if original_ondespawn ~= nil then
            return original_ondespawn(inst_, ...)
        end
    end

    local original_onload = inst.OnLoad
    inst.OnLoad = function(inst_, ...)
        return OnLoad(inst_, original_onload, ...)
    end
end)
