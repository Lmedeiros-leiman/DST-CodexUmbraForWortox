local CRIMSON_MULT = { .7, .08, .2, .5 }
local SHADOW_MINION_PREFABS =
{
    "shadowworker",
    "shadowprotector",
    "shadowduelist",
    "shadowlumber",
    "shadowminer",
    "shadowdigger",
}

-- Multiplies Wortox's red build into a dark crimson while keeping the shadows translucent.
local function ApplyCrimson(inst)
    inst.AnimState:SetMultColour(CRIMSON_MULT[1], CRIMSON_MULT[2], CRIMSON_MULT[3], CRIMSON_MULT[4])
end

local function MakeCrimson(pet)
    if pet._wortoxshen_crimson ~= nil then
        pet._wortoxshen_crimson:set(true)
    end
    ApplyCrimson(pet)
end

local function OnCrimsonDirty(inst)
    if inst._wortoxshen_crimson ~= nil and inst._wortoxshen_crimson:value() then
        ApplyCrimson(inst)
    end
end

for _, prefab in ipairs(SHADOW_MINION_PREFABS) do
    AddPrefabPostInit(prefab, function(inst)
        inst._wortoxshen_crimson = GLOBAL.net_bool(
            inst.GUID, "wortoxshen.crimson", "wortoxshen_crimsondirty")

        if not GLOBAL.TheWorld.ismastersim then
            inst:ListenForEvent("wortoxshen_crimsondirty", OnCrimsonDirty)
            -- Minions already crimson when they enter view carry the value in their initial state.
            inst:DoTaskInTime(0, OnCrimsonDirty)
        end
    end)
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
        MakeCrimson(pet)
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

local strings = GLOBAL.STRINGS or {}
GLOBAL.STRINGS = strings
strings.CHARACTERS = strings.CHARACTERS or {}
strings.CHARACTERS.WORTOX = strings.CHARACTERS.WORTOX or {}
strings.CHARACTERS.WORTOX.ACTIONFAIL = strings.CHARACTERS.WORTOX.ACTIONFAIL or {}
strings.CHARACTERS.WORTOX.ACTIONFAIL.CASTAOE = strings.CHARACTERS.WORTOX.ACTIONFAIL.CASTAOE or {}
strings.CHARACTERS.WORTOX.DESCRIBE = strings.CHARACTERS.WORTOX.DESCRIBE or {}
strings.CHARACTERS.WORTOX.DESCRIBE.WAXWELLJOURNAL =
    strings.CHARACTERS.WORTOX.DESCRIBE.WAXWELLJOURNAL or {}

strings.CHARACTERS.WORTOX.ACTIONFAIL.CASTAOE.NO_MAX_SANITY =
    "Hyuyu, my head is too crowded with shadows already!"
strings.CHARACTERS.WORTOX.DESCRIBE.WAXWELLJOURNAL.GENERIC =
    "The old magician's tricks, mine to borrow! Hyuyu!"
strings.CHARACTERS.WORTOX.DESCRIBE.WAXWELLJOURNAL.NEEDSFUEL =
    "It hungers for nightmares, as do I for souls."

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
