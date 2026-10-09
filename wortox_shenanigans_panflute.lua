-- Panflute troupe: when Wortox plays a panflute while carrying the Codex
-- Umbra, a few shadow dancers in his colours appear around him, dance for a
-- while and vanish. Purely visual: they are not pets, cost no sanity and are
-- never saved.
local tint = wortox_shenanigans_tint

local TROUPE_SIZE = 3
local TROUPE_RADIUS = 2.5
local DANCE_TIME = 10

-- Same exit the stage play uses for its shadowdancer. quickdespawn spawns
-- the despawn fx, which pick up the dancer's tint.
local function DespawnDancer(dancer)
    if dancer:IsValid() then
        if dancer.sg ~= nil then
            dancer.sg:GoToState("quickdespawn")
        else
            dancer:Remove()
        end
    end
end

-- The minion stategraph starts in its tinted "spawn" animation and ignores
-- "dance" while busy, so the dance starts once it settles into idle.
local function StartDancing(dancer, data)
    if data ~= nil and data.statename == "idle" then
        dancer:PushEvent("dance")
    end
end

local function DismissTroupe(wortox)
    local troupe = wortox._wortoxshen_troupe
    wortox._wortoxshen_troupe = nil
    if troupe ~= nil then
        for _, dancer in ipairs(troupe) do
            DespawnDancer(dancer)
        end
    end
end

local function SpawnTroupe(wortox)
    -- Playing again replaces the troupe instead of stacking dancers.
    DismissTroupe(wortox)

    local pos = wortox:GetPosition()
    local index = tint.GetTintIndex(wortox)
    local start_angle = math.random() * 2 * math.pi
    local troupe = {}
    for i = 1, TROUPE_SIZE do
        local angle = start_angle + (i - 1) * 2 * math.pi / TROUPE_SIZE
        local offset = GLOBAL.FindWalkableOffset(pos, angle, TROUPE_RADIUS, 8, true, false)
        if offset ~= nil then
            local dancer = GLOBAL.SpawnPrefab("shadowdancer")
            dancer.persists = false
            -- MakeMinion tags every minion scarytoprey, which sends rabbits
            -- running and birds flying; a visual troupe should not.
            dancer:RemoveTag("scarytoprey")
            dancer.Transform:SetPosition(pos.x + offset.x, 0, pos.z + offset.z)
            dancer.components.skinner:CopySkinsFromPlayer(wortox)
            tint.SetTint(dancer, index, tint.ApplyMinionTint)
            dancer:ListenForEvent("newstate", StartDancing)
            -- Each dancer owns its exit, so it still leaves if Wortox does first.
            dancer:DoTaskInTime(DANCE_TIME + math.random() * .5, DespawnDancer)
            table.insert(troupe, dancer)
        end
    end
    wortox._wortoxshen_troupe = troupe
end

local function IsCodex(item)
    return item.prefab == "waxwelljournal"
end

-- FindItem covers the inventory slots, the item on the cursor and an open
-- backpack, so the book counts anywhere Wortox is carrying it.
local function CarriesCodex(musician)
    local inventory = musician.components.inventory
    return inventory ~= nil and inventory:FindItem(IsCodex) ~= nil
end

AddPrefabPostInit("panflute", function(inst)
    if not GLOBAL.TheWorld.ismastersim then
        return
    end

    local instrument = inst.components.instrument
    if instrument == nil then
        return
    end

    -- Runs before the flute puts listeners to sleep; dancers lack the
    -- sleeper, player and plant tags it looks for, so they keep dancing.
    local onplayed = instrument.onplayed
    instrument:SetOnPlayedFn(function(flute, musician, ...)
        if onplayed ~= nil then
            onplayed(flute, musician, ...)
        end
        if musician ~= nil and musician.prefab == "wortox" and musician:IsValid() and CarriesCodex(musician) then
            SpawnTroupe(musician)
        end
    end)
end)
