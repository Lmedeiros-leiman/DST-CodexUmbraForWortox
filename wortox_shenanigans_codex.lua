local tint = wortox_shenanigans_tint

-- Shadow casters (Wortox here, everyone else through the Codex Umbra for
-- Everyone add-on) carry a config set by EnableShadowCaster:
--   tint(caster)  -> palette index from wortox_shenanigans_tint (0 = vanilla)
--   mine, other   -> examine statuses for the caster's own shadow and for
--                    anyone else looking at it; other may also be a function
--                    (pet, viewer, leader) -> status, e.g. to vary the line
--                    with the shadow owner's gender
-- Wortox uses WORTOX_MINE / WORTOX_OTHER, the add-on CODEX_MINE / CODEX_OTHER.

-- Vanilla shadow minions have no inspectable component, so nobody can examine
-- them. A caster's shadows can: the leader sees the "mine" status, everyone
-- else the "other" one. The strings live under the minions' name override,
-- SHADOWWAXWELL, and only use these statuses, so Maxwell's shadows never pick
-- up these lines.
local function MakeInspectable(pet, config)
    if pet.components.inspectable == nil then
        pet:AddComponent("inspectable")
    end
    pet.components.inspectable.getstatus = function(inst, viewer)
        local leader = inst.components.follower ~= nil and inst.components.follower:GetLeader() or nil
        if leader ~= nil and leader == viewer then
            return config.mine
        elseif type(config.other) == "function" then
            return config.other(inst, viewer, leader)
        end
        return config.other
    end
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
        local config = inst._codexumbra
        tint.SetTint(pet, config.tint(inst), tint.ApplyMinionTint)
        MakeInspectable(pet, config)
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
    local index = inst._codexumbra.tint(inst)
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
-- ("huehue" in Portuguese, "哼哼" in Chinese, "хо-хо" in Russian), for "imp"
-- (diabrete, 恶魔, бес) and for the Codex and its shadows.
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
        no_max_sanity = "Não cabe mais nada! Minha mente já está assombrada, huehue!",
        codex = "Os truques do mágico agora são meus, huehue!",
        codex_needsfuel = "Acabou o pesadelo, e o livro se faz de morto.",
        shadow_mine = "Minha sombra, meu par, parceira pra aprontar!",
        shadow_other = "A sombra de outro diabrete! Vamos aprontar juntos?",
        shadow_maxwell = "Aquele diabrete andou fuçando nas minhas anotações.",
        shadow_generic = "Essa sombra tem um tom diabólico.",
    },
    zh =
    {
        no_max_sanity = "脑中没空位，暗影挤成堆！",
        codex = "他的暗影戏法，如今归我耍，哼哼！",
        codex_needsfuel = "没有恐惧可吃，这本书干脆装死。",
        shadow_mine = "我的影子我的伴，一起捣蛋一起玩！",
        shadow_other = "另一个恶魔的影子！我们一起捣蛋吧？",
        shadow_maxwell = "那个恶魔偷偷翻过我的笔记。",
        shadow_generic = "这影子，连颜色都透着邪气。",
    },
    ru =
    {
        no_max_sanity = "Нет места, нет места! В голове от теней тесно!",
        codex = "Теперь его теневые фокусы — мои, хо-хо!",
        codex_needsfuel = "Кошмары кончились, и книга притворилась мёртвой.",
        shadow_mine = "Моя тень, мой двойник, мой напарник-озорник!",
        shadow_other = "Тень другого беса! Пошалим вместе?",
        shadow_maxwell = "Этот бес, похоже, рылся в моих записях.",
        shadow_generic = "У этой тени какой-то бесовский оттенок.",
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

-- Shadow types the Codex spells summon, each with its own pet limit. Kept
-- apart from the shared pet pool so critters, Woby, Wormwood's plants and
-- WX-78's drones keep their own limits. The 90% max sanity cap allows six
-- shadows in total anyway.
local SHADOW_PET_LIMITS =
{
    shadowworker = 6,
    shadowprotector = 6,
}

-- Lets a character craft and use the Codex Umbra like Maxwell. Runs on both
-- sides: the tag unlocks crafting and the spellbook on clients too. Calling
-- it twice on one character does nothing the second time.
local function EnableShadowCaster(inst, config)
    inst:AddTag("shadowmagic")

    if not GLOBAL.TheWorld.ismastersim or inst._codexumbra ~= nil then
        return
    end
    inst._codexumbra = config

    local petleash = inst.components.petleash
    if petleash == nil then
        inst:AddComponent("petleash")
        petleash = inst.components.petleash
        petleash:SetMaxPets(0)
    else
        inst._wortoxshen_onspawnpet = petleash.onspawnfn
        inst._wortoxshen_ondespawnpet = petleash.ondespawnfn
    end
    for prefab, limit in pairs(SHADOW_PET_LIMITS) do
        petleash:SetMaxPetsForPrefab(prefab, limit)
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
end

AddPrefabPostInit("wortox", function(inst)
    EnableShadowCaster(inst, {
        tint = tint.GetTintIndex,
        mine = "WORTOX_MINE",
        other = "WORTOX_OTHER",
    })
    if GLOBAL.TheWorld.ismastersim then
        inst:ListenForEvent("wortox_inclination_changed", RetintShadowMinions)
    end
end)

-- Public API for the Codex Umbra for Everyone add-on. Declared through
-- strict.lua's global() so the assignment is legal from mod code; readers
-- should use rawget(GLOBAL, "CodexUmbraForWortox") in case this mod is off.
GLOBAL.global("CodexUmbraForWortox")
GLOBAL.CodexUmbraForWortox =
{
    -- 2: config.other may be a function.
    version = 2,
    EnableShadowCaster = EnableShadowCaster,
    SetShadowDescription = SetShadowDescription,
    TINT_NONE = tint.TINT_NONE,
    TINT_GESTALT = tint.TINT_GESTALT,
    TINT_VOID_VIOLET = tint.TINT_VOID_VIOLET,
}
