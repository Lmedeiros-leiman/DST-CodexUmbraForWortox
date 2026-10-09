-- Lua 5.1 harness for the Codex Umbra for Wortox features.
-- Run from the mod root: lua5.1 test/test_mod.lua

local mod_root = arg[0]:match("^(.*)/test/test_mod%.lua$")
if mod_root == nil or mod_root == "" then
    mod_root = "."
end

local count = 0
local failures = 0

local function assert_eq(actual, expected, label)
    count = count + 1
    if actual ~= expected then
        failures = failures + 1
        io.stderr:write(string.format("FAIL: %s (expected %s, got %s)\n",
            label, tostring(expected), tostring(actual)))
    end
end

local function assert_true(value, label)
    assert_eq(value == true and true or false, true, label)
end

local function assert_near(actual, expected, label)
    count = count + 1
    if type(actual) ~= "number" or math.abs(actual - expected) > 1e-9 then
        failures = failures + 1
        io.stderr:write(string.format("FAIL: %s (expected ~%s, got %s)\n",
            label, tostring(expected), tostring(actual)))
    end
end

local function load_mod(config, ismastersim, locale)
    local env =
    {
        MODROOT = mod_root .. "/",
        config = config,
        postinits = {},
        sg_postinits = {},
        imports = {},
        spawn_fx_calls = 0,
        entities_by_guid = {},
        next_guid = 0,
        GLOBAL =
        {
            TheWorld = { ismastersim = ismastersim },
            TUNING =
            {
                SHADOWWAXWELL_SANITY_PENALTY =
                {
                    SHADOWWORKER = .15,
                    SHADOWPROTECTOR = .2,
                },
            },
            STRINGS =
            {
                CHARACTERS =
                {
                    -- Mirrors the tables vanilla speech_wortox.lua defines.
                    WORTOX =
                    {
                        ACTIONFAIL = { CASTAOE = {} },
                        DESCRIBE = { WAXWELLJOURNAL = {} },
                    },
                    WAXWELL = { DESCRIBE = {} },
                    GENERIC = { DESCRIBE = {} },
                },
            },
        },
        -- Same Lua globals DST's CreateEnvironment (mods.lua) exposes to mods.
        pairs = pairs,
        ipairs = ipairs,
        print = print,
        math = math,
        table = table,
        type = type,
        string = string,
        tostring = tostring,
        require = require,
    }
    env.env = env

    env.GLOBAL.SpawnPrefab = function()
        env.spawn_fx_calls = env.spawn_fx_calls + 1
        return
        {
            Transform =
            {
                SetPosition = function() end,
            },
        }
    end

    env.register_entity = function(inst)
        env.next_guid = env.next_guid + 1
        inst.GUID = env.next_guid
        env.entities_by_guid[inst.GUID] = inst
    end

    env.GLOBAL.net_smallbyte = function(guid, name, dirty_event)
        local netvar = { guid = guid, name = name, dirty_event = dirty_event, current = 0 }
        function netvar:set(value)
            if self.current ~= value then
                self.current = value
                local inst = env.entities_by_guid[self.guid]
                if inst ~= nil then
                    inst:PushEvent(self.dirty_event)
                end
            end
        end
        function netvar:value()
            return self.current
        end
        return netvar
    end

    if locale ~= nil then
        env.GLOBAL.LOC = { GetLocaleCode = function() return locale end }
    end

    env.GetModConfigData = function(name)
        return env.config[name]
    end

    env.AddPrefabPostInit = function(prefab, fn)
        table.insert(env.postinits, { prefab = prefab, fn = fn })
    end

    env.AddStategraphPostInit = function(name, fn)
        table.insert(env.sg_postinits, { name = name, fn = fn })
    end

    env.initialize_prefab = function(prefab, inst)
        for _, postinit in ipairs(env.postinits) do
            if postinit.prefab == prefab then
                postinit.fn(inst)
            end
        end
    end

    env.modimport = function(modulename)
        if string.sub(modulename, #modulename - 3, #modulename) ~= ".lua" then
            modulename = modulename .. ".lua"
        end
        table.insert(env.imports, modulename)
        local chunk, err = loadfile(env.MODROOT .. modulename)
        assert(chunk ~= nil, err)
        setfenv(chunk, env)
        chunk()
    end

    local chunk, err = loadfile(mod_root .. "/modmain.lua")
    assert(chunk ~= nil, err)
    setfenv(chunk, env)
    chunk()
    return env
end

local function add_event_api(inst)
    inst._listeners = {}

    function inst:ListenForEvent(event, callback, source)
        local target = source or self
        target._listeners = target._listeners or {}
        target._listeners[event] = target._listeners[event] or {}
        table.insert(target._listeners[event], callback)
    end

    function inst:RemoveEventCallback(event, callback, source)
        local target = source or self
        local listeners = target._listeners and target._listeners[event]
        if listeners == nil then
            return
        end
        for i = #listeners, 1, -1 do
            if listeners[i] == callback then
                table.remove(listeners, i)
            end
        end
    end

    function inst:PushEvent(event, data)
        local listeners = self._listeners and self._listeners[event]
        if listeners == nil then
            return
        end
        local snapshot = {}
        for i, callback in ipairs(listeners) do
            snapshot[i] = callback
        end
        for _, callback in ipairs(snapshot) do
            callback(self, data)
        end
    end

    function inst:DoTaskInTime(_, callback, ...)
        local task = { cancelled = false }
        function task:Cancel()
            self.cancelled = true
        end
        if not task.cancelled then
            callback(self, ...)
        end
        return task
    end

    function inst:AddTag(tag)
        self.tags[tag] = true
    end

    function inst:HasTag(tag)
        return self.tags[tag] == true
    end

    function inst:RemoveTag(tag)
        self.tags[tag] = nil
    end
end

local function new_health()
    local health =
    {
        dead = false,
        kill_count = 0,
        invincible = false,
    }
    function health:IsDead()
        return self.dead
    end
    function health:IsInvincible()
        return self.invincible
    end
    function health:Kill()
        self.dead = true
        self.kill_count = self.kill_count + 1
    end
    return health
end

local function new_anim_state()
    return
    {
        colour_calls = {},
        symbol_colour_calls = {},
        add_colour_calls = {},
        symbol_add_colour_calls = {},
        SetMultColour = function(self, r, g, b, a)
            table.insert(self.colour_calls, { r, g, b, a })
        end,
        SetSymbolMultColour = function(self, symbol, r, g, b, a)
            table.insert(self.symbol_colour_calls, { symbol, r, g, b, a })
        end,
        SetAddColour = function(self, r, g, b, a)
            table.insert(self.add_colour_calls, { r, g, b, a })
        end,
        SetSymbolAddColour = function(self, symbol, r, g, b, a)
            table.insert(self.symbol_add_colour_calls, { symbol, r, g, b, a })
        end,
        SetLightOverride = function(self, light)
            self.light_override = light
        end,
        SetBloomEffectHandle = function(self, shader)
            self.bloom = shader
        end,
        ClearBloomEffectHandle = function(self)
            self.bloom = nil
            self.bloom_cleared = true
        end,
    }
end

-- Mirrors SpawnPrefab: post inits run synchronously while the fx is created.
local function spawn_fx(prefab, env)
    local fx = { prefab = prefab, AnimState = new_anim_state() }
    add_event_api(fx)
    env.register_entity(fx)
    env.initialize_prefab(prefab, fx)
    return fx
end

-- Palette hex scaled by an alpha: the add colour the mod sends.
local function tint_add(hex, alpha)
    return {
        math.floor(hex / 0x10000) % 0x100 / 255 * alpha,
        math.floor(hex / 0x100) % 0x100 / 255 * alpha,
        hex % 0x100 / 255 * alpha,
    }
end

local CRIMSON = 0xDC143C
local FX_ALPHA = .5

-- Allegiance style per palette colour: opacity, light override, gestalt bloom.
local STYLE =
{
    [0xFF6F91] = { .65, .3 }, [0xDC143C] = { .65, .3 }, [0x8A0A22] = { .65, .3 },
    [0x7FE8FF] = { .5, .55, true }, [0x2FD0F0] = { .5, .55, true }, [0x2A9ED4] = { .5, .55, true },
    [0xA0206A] = { .75, .3 }, [0x7A0A3A] = { .75, .3 }, [0x4E0418] = { .75, .3 },
}

local function assert_glow(anim, hex, label)
    local style = STYLE[hex]
    assert_eq(anim.light_override, style[2], label .. " light override")
    if style[3] then
        assert_eq(anim.bloom, "shaders/anim.ksh", label .. " blooms like a gestalt")
    else
        assert_eq(anim.bloom, nil, label .. " has no bloom")
        assert_true(anim.bloom_cleared, label .. " clears any previous bloom")
    end
end

local function assert_add(calls, hex, alpha, label)
    local add = calls[#calls] or {}
    local expected = tint_add(hex, alpha)
    assert_near(add[1], expected[1], label .. " red")
    assert_near(add[2], expected[2], label .. " green")
    assert_near(add[3], expected[3], label .. " blue")
    assert_eq(add[4], 0, label .. " add alpha")
end

local function assert_minion_tint(anim, hex, label)
    local alpha = STYLE[hex][1]
    local mult = anim.colour_calls[#anim.colour_calls] or {}
    assert_true(mult[1] == 0 and mult[2] == 0 and mult[3] == 0 and mult[4] == alpha,
        label .. " uses a black silhouette multiply at its allegiance opacity")
    assert_add(anim.add_colour_calls, hex, alpha, label .. " fill")
    assert_glow(anim, hex, label)
    assert_eq(#anim.symbol_colour_calls + #anim.symbol_add_colour_calls, 0,
        label .. " leaves tools in the same silhouette")
end

local function new_pet(prefab, env)
    local pet =
    {
        prefab = prefab,
        tags = {},
        removed = false,
        components =
        {
            health = new_health(),
            inventory =
            {
                drop_count = 0,
                DropEverything = function(self)
                    self.drop_count = self.drop_count + 1
                end,
            },
            skinner =
            {
                copy_count = 0,
                CopySkinsFromPlayer = function(self, player)
                    self.copy_count = self.copy_count + 1
                    self.last_player = player
                end,
            },
        },
        sg =
        {
            states = {},
            GoToState = function(self, state)
                self.states[state] = (self.states[state] or 0) + 1
            end,
        },
        Transform =
        {
            GetWorldPosition = function()
                return 1, 2, 3
            end,
        },
        AnimState = new_anim_state(),
    }
    add_event_api(pet)
    if env ~= nil then
        env.register_entity(pet)
    end
    pet:AddTag("shadowminion")

    function pet:AddComponent(name)
        self.components[name] = {}
    end

    function pet:Remove()
        if not self.removed then
            self:PushEvent("onremove")
            self.removed = true
        end
    end

    function pet:IsValid()
        return not self.removed
    end

    return pet
end

local function new_critter(prefab, env)
    local pet = new_pet(prefab, env)
    pet:RemoveTag("shadowminion")
    return pet
end

local function new_player(env)
    local inst =
    {
        tags = {},
        components = {},
        is_snapshot_user_session = false,
        original_spawn_calls = 0,
        original_despawn_calls = 0,
        original_load_args = nil,
    }
    add_event_api(inst)
    inst._test_env = env
    if env ~= nil then
        env.register_entity(inst)
    end

    function inst:IsValid()
        return true
    end

    inst.components.health = new_health()
    inst.components.skilltreeupdater = { active = {} }
    function inst.components.skilltreeupdater:IsActivated(skill)
        return self.active[skill] == true
    end
    inst.components.sanity =
    {
        penalties = {},
        add_count = 0,
        remove_count = 0,
    }
    function inst.components.sanity:AddSanityPenalty(pet, amount)
        self.penalties[pet] = amount
        self.add_count = self.add_count + 1
    end
    function inst.components.sanity:RemoveSanityPenalty(pet)
        self.penalties[pet] = nil
        self.remove_count = self.remove_count + 1
    end
    function inst.components.sanity:GetPenaltyPercent()
        local total = 0
        for _, amount in pairs(self.penalties) do
            total = total + amount
        end
        return total
    end
    inst.components.skinner = {}

    local petleash =
    {
        owner = inst,
        maxpets = 1,
        pets = {},
        despawned = {},
    }
    petleash.onspawnfn = function(owner, pet)
        owner.original_spawn_calls = owner.original_spawn_calls + 1
        owner.last_original_spawn_pet = pet
    end
    petleash.ondespawnfn = function(owner, pet)
        owner.original_despawn_calls = owner.original_despawn_calls + 1
        owner.last_original_despawn_pet = pet
    end
    function petleash:GetMaxPets()
        return self.maxpets
    end
    function petleash:SetMaxPets(value)
        self.maxpets = value
    end
    function petleash:SetOnSpawnFn(callback)
        self.onspawnfn = callback
    end
    function petleash:SetOnDespawnFn(callback)
        self.ondespawnfn = callback
    end
    function petleash:GetPets()
        return self.pets
    end
    function petleash:SpawnPetAt(_, _, _, prefab)
        local pet = prefab == "critter"
            and new_critter(prefab, self.owner._test_env)
            or new_pet(prefab, self.owner._test_env)
        if self.owner._test_env ~= nil then
            self.owner._test_env.initialize_prefab(prefab, pet)
        end
        local owner = self.owner
        pet.components.follower = { GetLeader = function() return owner end }
        table.insert(self.pets, pet)
        self.onspawnfn(self.owner, pet)
        return pet
    end
    function petleash:DespawnPet(pet)
        table.insert(self.despawned, pet)
        self.ondespawnfn(self.owner, pet)
        for i = #self.pets, 1, -1 do
            if self.pets[i] == pet then
                table.remove(self.pets, i)
            end
        end
    end
    inst.components.petleash = petleash

    inst.OnLoad = function(owner, data, extra)
        owner.original_load_args = { owner, data, extra }
    end
    inst._OnDespawn = function(owner, migrationdata)
        owner.original_despawn_migrationdata = migrationdata
    end

    return inst
end

local function get_postinit(env)
    for _, postinit in ipairs(env.postinits) do
        if postinit.prefab == "wortox" then
            return postinit.fn
        end
    end
end

local function get_prefab_postinit(env, prefab)
    for _, postinit in ipairs(env.postinits) do
        if postinit.prefab == prefab then
            return postinit.fn
        end
    end
end

-- The configuration switches decide which modules load.
do
    local env = load_mod({ codex_umbra = false, panflute_troupe = false }, true)
    assert_eq(#env.imports, 0, "all features off imports nothing")
    assert_eq(#env.postinits, 0, "all features off registers no post init")

    env = load_mod({ codex_umbra = false }, true)
    assert_eq(table.concat(env.imports, ","), "wortox_shenanigans_tint.lua,wortox_shenanigans_panflute.lua",
        "troupe alone loads the shared tint and the panflute module")
    assert_eq(get_postinit(env), nil, "troupe alone leaves Wortox's prefab alone")

    env = load_mod({ panflute_troupe = false }, true)
    assert_eq(table.concat(env.imports, ","), "wortox_shenanigans_tint.lua,wortox_shenanigans_codex.lua",
        "Codex alone loads the shared tint and the Codex module")
    assert_eq(get_prefab_postinit(env, "panflute"), nil, "Codex alone leaves the panflute alone")
end

-- The tag is available to clients, while all server-only behavior stays out.
do
    local env = load_mod({ codex_umbra = true }, false)
    local inst = new_player(env)
    local original_spawn = inst.components.petleash.onspawnfn
    get_postinit(env)(inst)
    assert_true(inst:HasTag("shadowmagic"), "client Wortox gets the shadowmagic tag")
    assert_eq(inst.components.petleash:GetMaxPets(), 1, "client pet leash max remains unchanged")
    assert_eq(inst.components.petleash.onspawnfn, original_spawn, "client pet leash callback remains unchanged")
end

-- Server behavior chains the built-in pet callbacks and manages shadow minions.
do
    local env = load_mod({ codex_umbra = true }, true)
    local inst = new_player(env)
    get_postinit(env)(inst)

    assert_true(inst:HasTag("shadowmagic"), "server Wortox gets the shadowmagic tag")
    assert_eq(inst:HasTag("reader"), false, "Wortox does not get the reader tag")
    assert_eq(inst:HasTag("magician"), false, "Wortox does not get the magician tag")
    assert_eq(inst.components.petleash:GetMaxPets(), 7, "server pet leash max increases from 1 to 7")

    local critter = inst.components.petleash:SpawnPetAt(0, 0, 0, "critter")
    assert_eq(inst.original_spawn_calls, 1, "original spawn callback handles non-shadow pets")
    assert_eq(inst.last_original_spawn_pet, critter, "original spawn callback receives the critter")
    inst.components.petleash:DespawnPet(critter)
    assert_eq(inst.original_despawn_calls, 1, "original despawn callback handles non-shadow pets")
    assert_eq(inst.last_original_despawn_pet, critter, "original despawn callback receives the critter")

    local worker = inst.components.petleash:SpawnPetAt(0, 0, 0, "shadowworker")
    assert_near(inst.components.sanity.penalties[worker], .15, "shadowworker adds its sanity penalty")
    assert_eq(worker.components.skinner.last_player, inst, "shadowworker copies the Wortox skins")
    assert_true(worker._wortoxshen_tint ~= nil, "shadowworker has a tint network variable")
    if worker._wortoxshen_tint ~= nil then
        assert_eq(worker._wortoxshen_tint:value(), 4, "fresh Wortox sends the neutral, no-allegiance index")
    end
    assert_minion_tint(worker.AnimState, CRIMSON, "server shadowworker")

    local inspectable = worker.components.inspectable
    assert_true(inspectable ~= nil and inspectable.getstatus ~= nil, "Wortox's shadow can be inspected")
    if inspectable ~= nil and inspectable.getstatus ~= nil then
        assert_eq(inspectable.getstatus(worker, inst), "WORTOX_MINE", "owner sees the WORTOX_MINE status")
        assert_eq(inspectable.getstatus(worker, { prefab = "wortox" }), "WORTOX_OTHER",
            "another Wortox sees the WORTOX_OTHER status")
        worker.components.follower = nil
        assert_eq(inspectable.getstatus(worker, inst), "WORTOX_OTHER", "leaderless shadow reads as someone else's")
    end
    local critter_inspect = critter.components.inspectable
    assert_eq(critter_inspect, nil, "non-shadow pets do not become inspectable")
    worker:PushEvent("onremove")
    assert_eq(inst.components.sanity.penalties[worker], nil, "removed shadowworker loses its sanity penalty")

    local death_worker = inst.components.petleash:SpawnPetAt(0, 0, 0, "shadowworker")
    inst:PushEvent("death")
    assert_true(death_worker.components.health.dead, "death event schedules shadow minion death")

    local protector = inst.components.petleash:SpawnPetAt(0, 0, 0, "shadowprotector")
    assert_near(inst.components.sanity.penalties[protector], .2, "shadowprotector adds its sanity penalty")
    inst:PushEvent("ms_becameghost")
    assert_eq(inst.components.sanity.penalties[protector], nil, "ghost transition removes the shadow penalty")
    assert_true(protector.components.health.dead, "ghost transition schedules shadow minion death")
    assert_eq(#(protector._listeners.onremove or {}), 0, "ghost transition removes the penalty callback")

    inst:PushEvent("ms_playerreroll")
    assert_true(#inst.components.petleash.despawned >= 1, "reroll despawns shadow minions through the pet leash")

    local migrating = inst.components.petleash:SpawnPetAt(0, 0, 0, "shadowworker")
    local migrationdata = { shard = "caves" }
    inst:_OnDespawn(migrationdata)
    assert_true(inst.is_despawning, "migration marks the player as despawning")
    assert_eq(inst.original_despawn_migrationdata, migrationdata, "migration calls the original despawn hook")
    assert_eq(inst.components.petleash.despawned[#inst.components.petleash.despawned], migrating,
        "migration despawns shadow minions")

    local loaded = inst.components.petleash:SpawnPetAt(0, 0, 0, "shadowworker")
    local data = { freehops = 3 }
    inst:OnLoad(data, "extra argument")
    assert_eq(inst.original_load_args[2], data, "OnLoad passes the save data through")
    assert_eq(inst.original_load_args[3], "extra argument", "OnLoad passes all arguments through")
    assert_eq(loaded.components.skinner.last_player, inst, "OnLoad reskins shadow minions")
    assert_eq(env.spawn_fx_calls, 0, "OnLoad reskinning uses no visual effect")

    inst:PushEvent("onskinschanged", { nofx = true })
    assert_true(loaded.components.skinner.copy_count >= 3, "skin changes reskin shadow minions")

    assert_eq(env.GLOBAL.STRINGS.CHARACTERS.WORTOX.ACTIONFAIL.CASTAOE.NO_MAX_SANITY,
        "No room, no room! My head's too full of gloom!", "Wortox max sanity string is set")
    assert_eq(env.GLOBAL.STRINGS.CHARACTERS.WORTOX.DESCRIBE.WAXWELLJOURNAL.GENERIC,
        "His shadowy tricks are mine to mix, hyuyu!", "Wortox Codex description is set")
    local chars = env.GLOBAL.STRINGS.CHARACTERS
    assert_eq(chars.WORTOX.DESCRIBE.SHADOWWAXWELL.WORTOX_MINE,
        "My shadow, my double, my partner in trouble!", "Wortox line for his own shadow")
    assert_eq(chars.WORTOX.DESCRIBE.SHADOWWAXWELL.WORTOX_OTHER,
        "Another imp's shade! What mischief we've made!", "Wortox line for another imp's shadow")
    assert_eq(chars.WORTOX.DESCRIBE.SHADOWWAXWELL.GENERIC, nil, "Wortox has no line for Maxwell's shadows")
    assert_eq(chars.WAXWELL.DESCRIBE.SHADOWWAXWELL.WORTOX_OTHER,
        "That imp has been rifling through my notes.", "Maxwell line for Wortox's shadow")
    assert_eq(chars.GENERIC.DESCRIBE.SHADOWWAXWELL.WORTOX_OTHER,
        "That shadow has a devilish tint.", "generic line for Wortox's shadow")

    assert_eq(env.GLOBAL.STRINGS.CHARACTERS.WORTOX.DESCRIBE.WAXWELLJOURNAL.NEEDSFUEL,
        "Empty of dread, the book plays dead.", "Wortox Codex fuel description is set")
end

-- The tint netvar is registered for every minion prefab, dancers included.
do
    local env = load_mod({ codex_umbra = true }, true)
    local expected =
    {
        shadowworker = true,
        shadowprotector = true,
        shadowduelist = true,
        shadowlumber = true,
        shadowminer = true,
        shadowdigger = true,
        shadowdancer = true,
    }
    local registered = {}
    for _, postinit in ipairs(env.postinits) do
        if expected[postinit.prefab] then
            registered[postinit.prefab] = true
        end
    end
    for prefab in pairs(expected) do
        assert_true(registered[prefab], prefab .. " has a tint post init")
    end
end

-- Clients apply the tint after the network dirty event.
do
    local env = load_mod({ codex_umbra = true }, false)
    local pet = new_pet("shadowworker", env)
    local postinit = get_prefab_postinit(env, "shadowworker")
    assert_true(postinit ~= nil, "client shadowworker post init is registered")
    if postinit ~= nil then
        postinit(pet)
    end
    assert_eq(#pet.AnimState.colour_calls, 0, "client minion starts with its default tint")
    assert_true(pet._wortoxshen_tint ~= nil, "client minion has a tint network variable")
    if pet._wortoxshen_tint ~= nil then
        pet._wortoxshen_tint:set(4)
        assert_minion_tint(pet.AnimState, CRIMSON, "client shadowworker")
    end
end

-- Another player's minion remains untinted unless Wortox's petleash spawns it.
do
    local env = load_mod({ codex_umbra = true }, true)
    local pet = new_pet("shadowworker", env)
    local postinit = get_prefab_postinit(env, "shadowworker")
    assert_true(postinit ~= nil, "shadowworker post init is registered for other spawners")
    if postinit ~= nil then
        postinit(pet)
    end
    assert_eq(#pet.AnimState.colour_calls, 0, "minion post init alone does not tint it")
    assert_eq(#pet.AnimState.symbol_colour_calls, 0, "minion post init alone keeps its tool colour")
    assert_eq(pet.components.inspectable, nil, "minion post init alone does not make it inspectable")
    assert_true(pet._wortoxshen_tint ~= nil, "minion post init creates its tint network variable")
    if pet._wortoxshen_tint ~= nil then
        assert_eq(pet._wortoxshen_tint:value(), 0, "minion post init leaves its tint at 0")
    end
end

-- Despawn fx take the colour of the minion whose stategraph spawned them.
do
    local env = load_mod({ codex_umbra = true }, true)
    assert_eq(#env.sg_postinits, 1, "one stategraph post init is registered")
    local sg_postinit = env.sg_postinits[1] or {}
    assert_eq(sg_postinit.name, "shadowmaxwell", "post init targets the shadowmaxwell stategraph")

    -- Stand-ins for SGshadowwaxwell's handlers: both call DoDespawnFX.
    local spawned = {}
    local function despawn_fx()
        table.insert(spawned, spawn_fx("shadow_despawn", env))
        table.insert(spawned, spawn_fx("shadow_glob_fx", env))
    end
    local sg =
    {
        states =
        {
            quickdespawn = { onenter = despawn_fx },
            death = { events = { animover = { fn = despawn_fx } } },
        },
    }
    sg_postinit.fn(sg)

    local inst = new_player(env)
    get_postinit(env)(inst)
    local minion = inst.components.petleash:SpawnPetAt(0, 0, 0, "shadowworker")

    sg.states.quickdespawn.onenter(minion)
    sg.states.death.events.animover.fn(minion)
    assert_eq(#spawned, 4, "both despawn handlers spawned their fx")
    for i, fx in ipairs(spawned) do
        local label = fx.prefab .. " #" .. i
        assert_eq(fx._wortoxshen_tint ~= nil and fx._wortoxshen_tint:value(), 4,
            label .. " carries the minion's tint index for clients")
        assert_add(fx.AnimState.add_colour_calls, CRIMSON, FX_ALPHA, label .. " add colour")
        assert_glow(fx.AnimState, CRIMSON, label)
        assert_eq(#fx.AnimState.colour_calls, 0, label .. " keeps its vanilla multiply")
    end

    local after = spawn_fx("shadow_despawn", env)
    assert_eq(#after.AnimState.add_colour_calls, 0, "fx spawned after the handler stays untinted")

    -- Maxwell's minion: post init only, never spawned by Wortox.
    local maxwell_minion = new_pet("shadowworker", env)
    env.initialize_prefab("shadowworker", maxwell_minion)
    spawned = {}
    sg.states.quickdespawn.onenter(maxwell_minion)
    for _, fx in ipairs(spawned) do
        assert_eq(#fx.AnimState.add_colour_calls, 0, "Maxwell's minion fx stay black")
        assert_eq(fx._wortoxshen_tint:value(), 0, "Maxwell's minion fx are not tinted")
    end

    -- A game update that renames states must not break the post init.
    sg_postinit.fn({ states = {} })
    sg_postinit.fn({ states = { death = {} } })
    assert_true(true, "missing states are skipped without errors")
end

-- Clients tint despawn fx from the network flag.
do
    local env = load_mod({ codex_umbra = true }, false)
    local fx = spawn_fx("shadow_glob_fx", env)
    assert_eq(#fx.AnimState.add_colour_calls, 0, "client fx starts untinted")
    fx._wortoxshen_tint:set(4)
    assert_eq(#fx.AnimState.add_colour_calls, 1, "client fx tints when the flag arrives")
end

-- Every lean/allegiance pair picks its palette cell, and skill changes
-- recolour shadows that are already out.
do
    local expected =
    {
        { nil, nil, 0xDC143C }, { "nice", nil, 0xFF6F91 }, { "naughty", nil, 0x8A0A22 },
        { nil, "lunar", 0x2FD0F0 }, { "nice", "lunar", 0x7FE8FF }, { "naughty", "lunar", 0x2A9ED4 },
        { nil, "shadow", 0x7A0A3A }, { "nice", "shadow", 0xA0206A }, { "naughty", "shadow", 0x4E0418 },
    }
    for _, case in ipairs(expected) do
        local lean, allegiance, hex = case[1], case[2], case[3]
        local label = (lean or "neutral") .. "/" .. (allegiance or "none")
        local env = load_mod({ codex_umbra = true }, true)
        local inst = new_player(env)
        get_postinit(env)(inst)
        inst.wortox_inclination = lean
        if allegiance ~= nil then
            inst.components.skilltreeupdater.active["wortox_allegiance_" .. allegiance] = true
        end
        local pet = inst.components.petleash:SpawnPetAt(0, 0, 0, "shadowprotector")
        assert_minion_tint(pet.AnimState, hex, label)
    end

    local env = load_mod({ codex_umbra = true }, true)
    local inst = new_player(env)
    get_postinit(env)(inst)
    local pet = inst.components.petleash:SpawnPetAt(0, 0, 0, "shadowworker")
    assert_minion_tint(pet.AnimState, 0xDC143C, "before respec")

    inst.wortox_inclination = "naughty"
    inst:PushEvent("wortox_inclination_changed")
    assert_minion_tint(pet.AnimState, 0x8A0A22, "after turning naughty")

    inst.components.skilltreeupdater.active.wortox_allegiance_shadow = true
    inst:PushEvent("onactivateskill_server", { skill = "wortox_allegiance_shadow" })
    assert_minion_tint(pet.AnimState, 0x4E0418, "after joining the shadow")
    assert_eq(pet._wortoxshen_tint:value(), 9, "naughty shadow is the last palette cell")

    inst.components.skilltreeupdater.active.wortox_allegiance_shadow = nil
    inst:PushEvent("ondeactivateskill_server", { skill = "wortox_allegiance_shadow" })
    assert_minion_tint(pet.AnimState, 0x8A0A22, "after a respec drops the allegiance")

    inst.components.skilltreeupdater.active.wortox_allegiance_lunar = true
    inst:PushEvent("onactivateskill_server", { skill = "wortox_allegiance_lunar" })
    assert_minion_tint(pet.AnimState, 0x2A9ED4, "after joining the moon")
    inst.components.skilltreeupdater.active.wortox_allegiance_lunar = nil
    inst:PushEvent("ondeactivateskill_server", { skill = "wortox_allegiance_lunar" })
    assert_eq(pet.AnimState.bloom, nil, "leaving the moon drops the gestalt bloom")

    inst.wortox_inclination = "nice"
    inst:PushEvent("ms_skilltreeinitialized")
    assert_minion_tint(pet.AnimState, 0xFF6F91, "after the skill tree loads")

    local critter = inst.components.petleash:SpawnPetAt(0, 0, 0, "critter")
    inst:PushEvent("ms_skilltreeinitialized")
    assert_eq(#critter.AnimState.add_colour_calls, 0, "retinting skips non-shadow pets")
end

-- Panflute troupe: Wortox playing a flute brings three tinted shadow dancers.
local function new_troupe_env(ismastersim)
    local env = load_mod({}, ismastersim)
    env.dancers = {}
    env.offsets = 0
    env.GLOBAL.FindWalkableOffset = function()
        env.offsets = env.offsets + 1
        if env.no_room_for ~= nil and env.offsets == env.no_room_for then
            return nil
        end
        return { x = 1, y = 0, z = 2 }
    end
    local spawn_fx = env.GLOBAL.SpawnPrefab
    env.GLOBAL.SpawnPrefab = function(prefab)
        if prefab ~= "shadowdancer" then
            return spawn_fx(prefab)
        end
        local dancer = new_pet(prefab, env)
        dancer:AddTag("scarytoprey") -- MakeMinion adds it to every minion
        dancer.tasks = {}
        -- Deferred, unlike the harness default, so the dance timer can be checked.
        function dancer:DoTaskInTime(delay, fn, ...)
            table.insert(self.tasks, { delay = delay, fn = fn, args = { ... } })
            return { Cancel = function() end }
        end
        dancer.Transform.SetPosition = function(_, x, y, z)
            dancer.position = { x, y, z }
        end
        dancer.dance_count = 0
        dancer:ListenForEvent("dance", function(d) d.dance_count = d.dance_count + 1 end)
        env.initialize_prefab(prefab, dancer)
        table.insert(env.dancers, dancer)
        return dancer
    end
    return env
end

local function new_flute(env)
    local flute = { components = {}, played_with = {} }
    flute.components.instrument =
    {
        onplayed = function(inst, musician) table.insert(inst.played_with, musician) end,
        SetOnPlayedFn = function(self, fn) self.onplayed = fn end,
    }
    flute.vanilla_onplayed = flute.components.instrument.onplayed
    env.initialize_prefab("panflute", flute)
    return flute
end

local function new_musician(env, prefab, carried)
    local inst = new_player(env)
    inst.prefab = prefab
    function inst:GetPosition()
        return { x = 10, y = 0, z = 20 }
    end
    -- Stands in for Inventory:FindItem (slots, cursor and open backpack).
    inst.carried = carried or { { prefab = "waxwelljournal" } }
    inst.components.inventory =
    {
        FindItem = function(_, fn)
            for _, item in ipairs(inst.carried) do
                if fn(item) then
                    return item
                end
            end
        end,
    }
    return inst
end

do
    local env = new_troupe_env(true)
    local flute = new_flute(env)
    local wortox = new_musician(env, "wortox")
    flute.components.instrument.onplayed(flute, wortox)

    assert_true(flute.components.instrument.onplayed ~= flute.vanilla_onplayed, "server panflute callback is wrapped")
    assert_eq(flute.played_with[1], wortox, "the vanilla panflute callback still runs")
    assert_eq(#env.dancers, 3, "Wortox's tune brings three dancers")
    for i, dancer in ipairs(env.dancers) do
        local label = "dancer " .. i
        assert_eq(dancer.persists, false, label .. " is never saved")
        assert_eq(dancer:HasTag("scarytoprey"), false, label .. " does not scare wildlife")
        assert_eq(dancer.components.skinner.last_player, wortox, label .. " wears Wortox's skin")
        assert_eq(dancer._wortoxshen_tint:value(), 4, label .. " carries Wortox's palette index")
        assert_minion_tint(dancer.AnimState, CRIMSON, label)
        assert_true(dancer.position[1] == 11 and dancer.position[3] == 22, label .. " stands at the walkable offset")
        dancer:PushEvent("newstate", { statename = "spawn" })
        assert_eq(dancer.dance_count, 0, label .. " does not dance while spawning")
        dancer:PushEvent("newstate", { statename = "idle" })
        assert_eq(dancer.dance_count, 1, label .. " starts dancing once idle")
        local exit = dancer.tasks[1]
        assert_true(exit ~= nil and exit.delay >= 10 and exit.delay <= 10.5, label .. " leaves after about ten seconds")
    end
    assert_eq(env.dancers[1].sg.states.quickdespawn, nil, "dancers stay until their timer")

    local first = env.dancers
    env.dancers = {}
    flute.components.instrument.onplayed(flute, wortox)
    assert_eq(#env.dancers, 3, "playing again brings a new troupe")
    for i, dancer in ipairs(first) do
        assert_eq(dancer.sg.states.quickdespawn, 1, "previous dancer " .. i .. " leaves when replaced")
    end

    local timed = env.dancers[1]
    timed.tasks[1].fn(timed)
    assert_eq(timed.sg.states.quickdespawn, 1, "the dance timer sends the dancer away")
    timed.removed = true
    timed.tasks[1].fn(timed)
    assert_eq(timed.sg.states.quickdespawn, 1, "a dancer already gone is left alone")

    env.dancers = {}
    local wilson = new_musician(env, "wilson")
    flute.components.instrument.onplayed(flute, wilson)
    assert_eq(#env.dancers, 0, "other characters get no troupe")
    assert_eq(flute.played_with[#flute.played_with], wilson, "other characters still play the flute normally")
end

-- The troupe needs the Codex Umbra on Wortox; any other item does not count.
do
    local env = new_troupe_env(true)
    local flute = new_flute(env)
    local bookless = new_musician(env, "wortox", { { prefab = "book_sleep" }, { prefab = "panflute" } })
    flute.components.instrument.onplayed(flute, bookless)
    assert_eq(#env.dancers, 0, "Wortox without the Codex gets no troupe")
    assert_eq(flute.played_with[1], bookless, "the flute still plays normally without the Codex")

    local reader = new_musician(env, "wortox", { { prefab = "panflute" }, { prefab = "waxwelljournal" } })
    flute.components.instrument.onplayed(flute, reader)
    assert_eq(#env.dancers, 3, "the Codex anywhere Wortox carries it brings the troupe")

    env.dancers = {}
    local inventoryless = new_musician(env, "wortox")
    inventoryless.components.inventory = nil
    flute.components.instrument.onplayed(flute, inventoryless)
    assert_eq(#env.dancers, 0, "a musician without an inventory gets no troupe")
end

-- The troupe follows Wortox's palette and skips spots with no walkable ground.
do
    local env = new_troupe_env(true)
    env.no_room_for = 2
    local flute = new_flute(env)
    local wortox = new_musician(env, "wortox")
    wortox.wortox_inclination = "naughty"
    wortox.components.skilltreeupdater.active.wortox_allegiance_lunar = true
    flute.components.instrument.onplayed(flute, wortox)
    assert_eq(#env.dancers, 2, "a spot without walkable ground gets no dancer")
    for i, dancer in ipairs(env.dancers) do
        assert_minion_tint(dancer.AnimState, 0x2A9ED4, "naughty lunar dancer " .. i)
    end
end

-- Clients never touch the flute; the server owns the troupe.
do
    local env = new_troupe_env(false)
    local flute = new_flute(env)
    assert_eq(flute.components.instrument.onplayed, flute.vanilla_onplayed, "client panflute keeps its callback")
    local wortox = new_musician(env, "wortox")
    flute.components.instrument.onplayed(flute, wortox)
    assert_eq(#env.dancers, 0, "clients spawn no dancers")
end

-- Wortox's lines follow the game language, English otherwise.
do
    local function lines_for(locale, forced)
        local chars = load_mod({ language = forced }, true, locale).GLOBAL.STRINGS.CHARACTERS
        return {
            chars.WORTOX.ACTIONFAIL.CASTAOE.NO_MAX_SANITY,
            chars.WORTOX.DESCRIBE.WAXWELLJOURNAL.GENERIC,
            chars.WORTOX.DESCRIBE.WAXWELLJOURNAL.NEEDSFUEL,
            chars.WORTOX.DESCRIBE.SHADOWWAXWELL.WORTOX_MINE,
            chars.WORTOX.DESCRIBE.SHADOWWAXWELL.WORTOX_OTHER,
            chars.WAXWELL.DESCRIBE.SHADOWWAXWELL.WORTOX_OTHER,
            chars.GENERIC.DESCRIBE.SHADOWWAXWELL.WORTOX_OTHER,
        }
    end
    local en, pt, fr, none = lines_for("en"), lines_for("pt"), lines_for("fr"), lines_for(nil)
    assert_eq(pt[1], "Não cabe mais nada! Minha mente já está assombrada, huehue!", "Portuguese max sanity line")
    assert_eq(pt[2], "Os truques do mágico agora são meus, huehue!", "Portuguese Codex line")
    assert_eq(pt[4], "Minha sombra, meu par, parceira pra aprontar!", "Portuguese own-shadow line")
    for i = 1, #en do
        assert_true(type(pt[i]) == "string" and pt[i] ~= en[i], "line " .. i .. " has its own Portuguese text")
        assert_eq(fr[i], en[i], "line " .. i .. " falls back to English for other languages")
        assert_eq(none[i], en[i], "line " .. i .. " is English when the game reports no locale")
    end

    -- The language option overrides the server's game language.
    -- Simplified Chinese, on Steam ("zh") and on WeGame ("zhr").
    local zh, zhr, zht = lines_for("zh"), lines_for("zhr"), lines_for("zht")
    assert_eq(zh[1], "脑中没空位，暗影挤成堆！", "Chinese max sanity line")
    assert_eq(zh[2], "他的暗影戏法，如今归我耍，哼哼！", "Chinese Codex line in Wortox's official laugh")
    for i = 1, #en do
        assert_true(type(zh[i]) == "string" and zh[i] ~= en[i] and zh[i] ~= pt[i], "line " .. i .. " has its own Chinese text")
        assert_eq(zhr[i], zh[i], "line " .. i .. " uses Chinese on the WeGame release")
        assert_eq(zht[i], en[i], "line " .. i .. " stays English for Traditional Chinese")
        assert_eq(lines_for("en", "zh")[i], zh[i], "line " .. i .. " forced to Chinese")
    end

    -- Russian.
    local ru = lines_for("ru")
    assert_eq(ru[2], "Теперь его теневые фокусы — мои, хо-хо!", "Russian Codex line in Wortox's official laugh")
    assert_eq(ru[4], "Моя тень, мой двойник, мой напарник-озорник!", "Russian own-shadow line")
    for i = 1, #en do
        assert_true(type(ru[i]) == "string" and ru[i] ~= en[i] and ru[i] ~= pt[i] and ru[i] ~= zh[i],
            "line " .. i .. " has its own Russian text")
        assert_eq(lines_for("en", "ru")[i], ru[i], "line " .. i .. " forced to Russian")
    end

    local forced_pt, forced_en = lines_for("en", "pt"), lines_for("pt", "en")
    local auto_pt, unknown = lines_for("pt", "auto"), lines_for("pt", "klingon")
    for i = 1, #en do
        assert_eq(forced_pt[i], pt[i], "line " .. i .. " forced to Portuguese on an English server")
        assert_eq(forced_en[i], en[i], "line " .. i .. " forced to English on a Portuguese server")
        assert_eq(auto_pt[i], pt[i], "line " .. i .. " on auto follows the server language")
        assert_eq(unknown[i], pt[i], "line " .. i .. " ignores an unknown option value")
    end
end

-- The mod list text follows the locale DST hands to modinfo.
do
    local function modinfo_for(locale)
        local env = { locale = locale }
        local chunk = assert(loadfile(mod_root .. "/modinfo.lua"))
        setfenv(chunk, env)
        chunk()
        return env
    end
    local en, pt, zh = modinfo_for("en"), modinfo_for("pt"), modinfo_for("zh")
    assert_eq(zh.name, "沃拓克斯的暗影秘典", "Chinese mod name uses the official Codex name")
    assert_eq(modinfo_for("zhr").name, zh.name, "WeGame Chinese gets the Chinese mod text")
    assert_eq(modinfo_for("zht").name, en.name, "Traditional Chinese falls back to English")
    assert_eq(zh.configuration_options[1].options[1].description, "启用", "Chinese on label")
    local ru = modinfo_for("ru")
    assert_eq(ru.name, "Кодекс Умбра для Вортокса", "Russian mod name uses the official Codex name")
    assert_eq(ru.configuration_options[1].options[1].description, "Включено", "Russian on label")
    assert_eq(ru.configuration_options[2].label, "Труппа флейты", "Russian troupe label")
    assert_true(ru.description ~= en.description, "description is in Russian")
    assert_true(zh.description ~= en.description and zh.description ~= pt.description, "description is in Chinese")
    assert_eq(en.name, "Codex Umbra for Wortox", "English mod name")
    assert_eq(pt.name, "Codex Umbra para o Wortox", "Portuguese mod name")
    assert_eq(modinfo_for(nil).name, en.name, "no locale falls back to English")
    assert_true(en.description ~= pt.description, "description is translated")
    for i, option in ipairs(en.configuration_options) do
        local pt_option = pt.configuration_options[i]
        assert_eq(pt_option.name, option.name, option.name .. " keeps its config key in both languages")
        assert_true(pt_option.hover ~= option.hover, option.name .. " hover is translated")
        if type(option.default) == "boolean" then
            assert_eq(option.options[1].description, "Enabled", option.name .. " English on label")
            assert_eq(pt_option.options[1].description, "Ativado", option.name .. " Portuguese on label")
        end
    end
    assert_eq(pt.configuration_options[2].label, "Trupe da Flauta", "Portuguese troupe label")
    assert_eq(en.icon_atlas, "modicon.xml", "modinfo points at the icon atlas")
    local language
    for _, option in ipairs(en.configuration_options) do
        if option.name == "language" then
            language = option
        end
    end
    assert_true(language ~= nil, "modinfo has a language option")
    if language ~= nil then
        assert_eq(language.default, "auto", "language defaults to auto")
        local values = {}
        for _, choice in ipairs(language.options) do
            table.insert(values, tostring(choice.data))
        end
        assert_eq(table.concat(values, ","), "auto,en,pt,zh,ru", "language offers auto, English, Portuguese, Chinese and Russian")
    end
end

if failures > 0 then
    io.stderr:write(string.format("%d/%d tests failed\n", failures, count))
    os.exit(1)
end

print(string.format("%d/%d tests passed", count, count))
