-- Lua 5.1 harness for the Wortox Codex Umbra feature.
-- Run from the mod root: lua5.1 test/test_codex.lua

local mod_root = arg[0]:match("^(.*)/test/test_codex%.lua$")
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

local function load_mod(config, ismastersim)
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

    env.GLOBAL.net_bool = function(guid, name, dirty_event)
        local netvar = { guid = guid, name = name, dirty_event = dirty_event, current = false }
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

local function assert_minion_crimson(anim, label)
    assert_eq(#anim.colour_calls, 1, label .. " sets its multiply once")
    local mult = anim.colour_calls[1] or {}
    assert_true(mult[1] == 0 and mult[2] == 0 and mult[3] == 0 and mult[4] == .5,
        label .. " uses Maxwell's black silhouette multiply")
    assert_eq(#anim.add_colour_calls, 1, label .. " sets its add colour once")
    local add = anim.add_colour_calls[1] or {}
    assert_true(add[1] == .45 and add[2] == .02 and add[3] == .1 and add[4] == 0,
        label .. " fills the silhouette with crimson")
    local tool = anim.symbol_colour_calls[1] or {}
    assert_eq(tool[1], "swap_object", label .. " tints the tool symbol")
    assert_true(tool[2] == 0 and tool[3] == 0 and tool[4] == 0 and tool[5] == 1,
        label .. " multiplies the tool to black")
    local tool_add = anim.symbol_add_colour_calls[1] or {}
    assert_eq(tool_add[1], "swap_object", label .. " cancels the add on the tool symbol")
    assert_true(tool_add[2] == -add[1] and tool_add[3] == -add[2] and tool_add[4] == -add[3]
        and tool_add[5] == 0, label .. " tool add is the negated crimson")
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

-- The configuration switch must prevent the feature module from loading.
do
    local env = load_mod({ codex_umbra = false }, true)
    assert_eq(#env.imports, 0, "disabled Codex Umbra does not import the feature")
    assert_eq(#env.postinits, 0, "disabled Codex Umbra does not register a post init")
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
    assert_true(worker._wortoxshen_crimson ~= nil, "shadowworker has a crimson network variable")
    if worker._wortoxshen_crimson ~= nil then
        assert_eq(worker._wortoxshen_crimson:value(), true, "shadowworker network tint is enabled")
    end
    assert_minion_crimson(worker.AnimState, "server shadowworker")

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

-- The tint netvar is registered for every shadow minion prefab except shadowdancer.
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
    }
    local registered = {}
    for _, postinit in ipairs(env.postinits) do
        if expected[postinit.prefab] then
            registered[postinit.prefab] = true
        end
        assert_eq(postinit.prefab == "shadowdancer", false, "shadowdancer has no tint post init")
    end
    for prefab in pairs(expected) do
        assert_true(registered[prefab], prefab .. " has a tint post init")
    end
end

-- Clients apply the crimson tint after the network dirty event.
do
    local env = load_mod({ codex_umbra = true }, false)
    local pet = new_pet("shadowworker", env)
    local postinit = get_prefab_postinit(env, "shadowworker")
    assert_true(postinit ~= nil, "client shadowworker post init is registered")
    if postinit ~= nil then
        postinit(pet)
    end
    assert_eq(#pet.AnimState.colour_calls, 0, "client minion starts with its default tint")
    assert_true(pet._wortoxshen_crimson ~= nil, "client minion has a crimson network variable")
    if pet._wortoxshen_crimson ~= nil then
        pet._wortoxshen_crimson:set(true)
        assert_minion_crimson(pet.AnimState, "client shadowworker")
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
    assert_true(pet._wortoxshen_crimson ~= nil, "minion post init creates its crimson network variable")
    if pet._wortoxshen_crimson ~= nil then
        assert_eq(pet._wortoxshen_crimson:value(), false, "minion post init leaves its netvar false")
    end
end

-- Despawn fx spawned by a crimson minion's stategraph turn crimson too.
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
        assert_true(fx._wortoxshen_crimson ~= nil and fx._wortoxshen_crimson:value(),
            label .. " is flagged crimson for clients")
        local add = fx.AnimState.add_colour_calls[1] or {}
        assert_true(add[1] == .4 and add[2] == 0 and add[3] == .07 and add[4] == 0,
            label .. " gets the crimson add colour")
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
        assert_eq(fx._wortoxshen_crimson:value(), false, "Maxwell's minion fx are not flagged")
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
    fx._wortoxshen_crimson:set(true)
    assert_eq(#fx.AnimState.add_colour_calls, 1, "client fx tints when the flag arrives")
end

if failures > 0 then
    io.stderr:write(string.format("%d/%d tests failed\n", failures, count))
    os.exit(1)
end

print(string.format("%d/%d tests passed", count, count))
