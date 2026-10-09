local tint = wortox_shenanigans_tint

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
        tint.SetTint(pet, tint.GetTintIndex(inst), tint.ApplyMinionTint)
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
    local index = tint.GetTintIndex(inst)
    for _, pet in pairs(inst.components.petleash:GetPets()) do
        if pet:HasTag("shadowminion") then
            tint.SetTint(pet, index, tint.ApplyMinionTint)
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

-- Lines per language (LOC code), English otherwise. Speech is resolved
-- on the server and broadcast as text, so the host's language is what every
-- player hears. Each translation follows the official one for Wortox's laugh
-- ("huehue" in Portuguese, "哼哼" in Chinese) and DST's names for the Codex
-- (暗影秘典) and its shadows.
local LINES =
{
    en =
    {
        no_max_sanity = "No room, no room! My head's too full of gloom!",
        codex = "His shadowy tricks are mine to mix, hyuyu!",
        codex_needsfuel = "Empty of dread, the book plays dead.",
        shadow_mine = "My shadow, my double, my partner in trouble!",
        shadow_other = "Another imp's shade! What mischief we've made!",
        shadow_maxwell = "That imp has been rifling through my notes.",
        shadow_generic = "That shadow has a devilish tint.",
    },
    pt =
    {
        no_max_sanity = "Chega, chega! Minha mente já não sossega!",
        codex = "Magia de sombra, que delícia! Agora é minha essa malícia, huehue!",
        codex_needsfuel = "Sem medo pra comer, o livro finge morrer.",
        shadow_mine = "Minha sombra, meu par, parceira pra aprontar!",
        shadow_other = "Outro diabinho e sua sombra! Que travessura nessa penumbra!",
        shadow_maxwell = "Aquele diabrete andou mexendo nas minhas anotações.",
        shadow_generic = "Essa sombra tem um tom diabólico.",
    },
    zh =
    {
        no_max_sanity = "不行不行！我的脑袋里塞满了阴影！",
        codex = "他的暗影戏法，现在由我来耍，哼哼！",
        codex_needsfuel = "没了恐惧当饭吃，这本书就装死。",
        shadow_mine = "我的影子我的伴，一起捣蛋一起干！",
        shadow_other = "又一个小恶魔的影，咱们闹得真起劲！",
        shadow_maxwell = "那个小恶魔一直在翻我的笔记。",
        shadow_generic = "这个影子透着一股魔鬼般的颜色。",
    },
}
-- The WeGame (Rail) release reports Simplified Chinese as "zhr".
local LANGUAGE_ALIASES = { zhr = "zh" }
-- The "language" option can force one; "auto" (or no option) uses the
-- server's game language.
local function GetLanguage()
    local forced = GetModConfigData("language")
    if forced ~= nil and LINES[forced] ~= nil then
        return forced
    end
    local code = GLOBAL.LOC ~= nil and GLOBAL.LOC.GetLocaleCode() or "en"
    return LANGUAGE_ALIASES[code] or code
end
local lines = LINES[GetLanguage()] or LINES.en

-- Vanilla speech_wortox.lua already defines these tables; NO_MAX_SANITY and
-- NEEDSFUEL otherwise fall back to Wilson's "only_used_by_waxwell".
local wortox_speech = GLOBAL.STRINGS.CHARACTERS.WORTOX
wortox_speech.ACTIONFAIL.CASTAOE.NO_MAX_SANITY = lines.no_max_sanity
wortox_speech.DESCRIBE.WAXWELLJOURNAL.GENERIC = lines.codex
wortox_speech.DESCRIBE.WAXWELLJOURNAL.NEEDSFUEL = lines.codex_needsfuel

local function SetShadowDescription(character, status, line)
    local describe = GLOBAL.STRINGS.CHARACTERS[character].DESCRIBE
    if type(describe.SHADOWWAXWELL) ~= "table" then
        describe.SHADOWWAXWELL = { GENERIC = describe.SHADOWWAXWELL }
    end
    describe.SHADOWWAXWELL[status] = line
end

SetShadowDescription("WORTOX", "WORTOX_MINE", lines.shadow_mine)
SetShadowDescription("WORTOX", "WORTOX_OTHER", lines.shadow_other)
SetShadowDescription("WAXWELL", "WORTOX_OTHER", lines.shadow_maxwell)
-- Everyone else falls back to the generic (Wilson) table.
SetShadowDescription("GENERIC", "WORTOX_OTHER", lines.shadow_generic)

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
