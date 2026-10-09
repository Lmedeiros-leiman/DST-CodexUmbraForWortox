-- Look of Wortox's shadows: Maxwell's flat silhouette, in crimson. The
-- black multiply is Maxwell's own (it erases every skin and tool detail,
-- alpha .5 is his translucency) and the add colour fills the silhouette with
-- crimson. Tools are part of the same silhouette, as with Maxwell's shadows.
-- The anim shader weights the add by the texel's alpha, so only the shape
-- turns red, never the empty space around it.
local MINION_MULT = { 0, 0, 0, .5 }
local MINION_ADD = { .45, .02, .1, 0 }
-- The despawn smoke art is near black, so a multiply cannot redden it. The
-- add colour is weighted by alpha, so the transparent parts stay clear.
local FX_ADD = { .4, 0, .07, 0 }

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

local function ApplyMinionCrimson(inst)
    inst.AnimState:SetMultColour(MINION_MULT[1], MINION_MULT[2], MINION_MULT[3], MINION_MULT[4])
    inst.AnimState:SetAddColour(MINION_ADD[1], MINION_ADD[2], MINION_ADD[3], MINION_ADD[4])
end

local function ApplyFxCrimson(inst)
    inst.AnimState:SetAddColour(FX_ADD[1], FX_ADD[2], FX_ADD[3], FX_ADD[4])
end

local function IsCrimson(inst)
    return inst._wortoxshen_crimson ~= nil and inst._wortoxshen_crimson:value()
end

-- AnimState colours are not networked, so the server flags the entity and
-- each client applies the tint itself.
local function SetupCrimson(inst, apply)
    inst._wortoxshen_crimson = GLOBAL.net_bool(
        inst.GUID, "wortoxshen.crimson", "wortoxshen_crimsondirty")

    if not GLOBAL.TheWorld.ismastersim then
        local function OnCrimsonDirty(inst_)
            if IsCrimson(inst_) then
                apply(inst_)
            end
        end
        inst:ListenForEvent("wortoxshen_crimsondirty", OnCrimsonDirty)
        -- Entities already crimson when they enter view carry the value in their initial state.
        inst:DoTaskInTime(0, OnCrimsonDirty)
    end
end

local function MakeCrimson(inst, apply)
    if inst._wortoxshen_crimson ~= nil then
        inst._wortoxshen_crimson:set(true)
    end
    -- Also applied on the server, which renders for a listen-server host.
    apply(inst)
end

for _, prefab in ipairs(SHADOW_MINION_PREFABS) do
    AddPrefabPostInit(prefab, function(inst)
        SetupCrimson(inst, ApplyMinionCrimson)
    end)
end

-- True while a crimson minion runs the stategraph code that spawns its
-- despawn fx. Prefab post inits run inside SpawnPrefab, so those fx see it.
local crimson_fx_pending = false

for _, prefab in ipairs(SHADOW_FX_PREFABS) do
    AddPrefabPostInit(prefab, function(inst)
        SetupCrimson(inst, ApplyFxCrimson)
        if crimson_fx_pending and GLOBAL.TheWorld.ismastersim then
            MakeCrimson(inst, ApplyFxCrimson)
        end
    end)
end

local function WithCrimsonFx(fn)
    return function(inst, ...)
        crimson_fx_pending = IsCrimson(inst)
        fn(inst, ...)
        crimson_fx_pending = false
    end
end

-- Registered as "shadowmaxwell" in SGshadowwaxwell.lua. Both handlers call
-- DoDespawnFX right before removing the minion. Each lookup is guarded so a
-- game update that renames a state only loses the crimson fx.
AddStategraphPostInit("shadowmaxwell", function(sg)
    local quickdespawn = sg.states.quickdespawn
    if quickdespawn ~= nil and quickdespawn.onenter ~= nil then
        quickdespawn.onenter = WithCrimsonFx(quickdespawn.onenter)
    end

    local death = sg.states.death
    local animover = death ~= nil and death.events ~= nil and death.events.animover or nil
    if animover ~= nil and animover.fn ~= nil then
        animover.fn = WithCrimsonFx(animover.fn)
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
        MakeCrimson(pet, ApplyMinionCrimson)
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
