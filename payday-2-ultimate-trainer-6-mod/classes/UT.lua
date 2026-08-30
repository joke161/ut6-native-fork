UT = {}

UT.maxInteger = math.huge

UT.rootPath = nil
UT.modPath = nil
UT.environment = nil
UT.initialEnvironment = nil
UT.enableNoClip = false
UT.noClipSpeed = nil
UT.playerUnitAliveEventTriggered = false
UT.carryVerifyDisabled = false

UT.bunnyhopAirAccelerate = nil
UT.bunnyhopMaxAirSpeed = nil
UT.bunnyhopSpeedCap = nil

UT.slowMotionWorldSpeed = nil
UT.slowMotionPlayerSpeed = nil

UT.xrayEnemyColor = Vector3(1, 0, 0)
UT.xrayCivilianColor = Vector3(0, 1, 0)
UT.xrayCameraColor = Vector3(0, 0, 1)

UT.xRayEnabled = false
UT.preventAlarmTriggeringEnabled = false
UT.invisiblePlayerEnabled = false
UT.noClipEnabled = false
UT.bunnyhopEnabled = false
UT.noMeleeDamageEnabled = false
UT.disableAIEnabled = false
UT.removeTeamAIEnabled = false
UT.suspendPointOfNoReturnTimerEnabled = false
UT.unlimitedPagersEnabled = false
UT.instantDrillingEnabled = false
UT.noCivilianKillPenaltyEnabled = false
UT.slowMotionEnabled = false
UT.unlimitedConversionEnabled = false
UT.dodgeChanceBonus = 0
UT.instantInteractionEnabled = false
UT.interactionSpeedMultiplier = 1.0

UT.settings = {}
UT.backup = {}
UT.spawnedVehicleUnits = {}
UT.invisibleWalls = {}
UT.interactions = {}
UT.vehicles = {}
UT.trophies = {}
UT.steamAchievements = {}
UT.blackMarketMasks = {}
UT.blackMarketMaterials = {}
UT.blackMarketTextures = {}
UT.blackMarketColors = {}
UT.blackMarketWeaponMods = {}

UT.addons = {}
UT.nativeKeybinds = {}

function UT:init()
    UT:loadSettings()
    UT:loadAddons()

    local content = UT.Utility:readFile(UT.modPath .. "/data/invisible-walls.json")
    if content then
        UT.invisibleWalls = UT.Utility:jsonDecode(content)
    end

    local content = UT.Utility:readFile(UT.modPath .. "/data/interactions.json")
    if content then
        UT.interactions = UT.Utility:jsonDecode(content)
    end

    local content = UT.Utility:readFile(UT.modPath .. "/data/vehicles.json")
    if content then
        UT.vehicles = UT.Utility:jsonDecode(content)
    end

    local content = UT.Utility:readFile(UT.modPath .. "/data/trophies.json")
    if content then
        UT.trophies = UT.Utility:jsonDecode(content)
    end

    local content = UT.Utility:readFile(UT.modPath .. "/data/steam-achievements.json")
    if content then
        UT.steamAchievements = UT.Utility:jsonDecode(content)
    end

    local content = UT.Utility:readFile(UT.modPath .. "/data/masks.json")
    if content then
        UT.blackMarketMasks = UT.Utility:jsonDecode(content)
    end

    local content = UT.Utility:readFile(UT.modPath .. "/data/materials.json")
    if content then
        UT.blackMarketMaterials = UT.Utility:jsonDecode(content)
    end

    local content = UT.Utility:readFile(UT.modPath .. "/data/textures.json")
    if content then
        UT.blackMarketTextures = UT.Utility:jsonDecode(content)
    end

    local content = UT.Utility:readFile(UT.modPath .. "/data/colors.json")
    if content then
        UT.blackMarketColors = UT.Utility:jsonDecode(content)
    end

    local content = UT.Utility:readFile(UT.modPath .. "/data/weapon-mods.json")
    if content then
        UT.blackMarketWeaponMods = UT.Utility:jsonDecode(content)
    end

    UT:loadNativeKeybinds()

    UTMenu:_registerCustomTextures()
end

function UT:loadNativeKeybinds()
    local content = UT.Utility:readFile(UT.rootPath .. "/native-keybinds.json")
    if content then
        UT.nativeKeybinds = UT.Utility:jsonDecode(content) or {}
    end

    for index, bind in pairs(UT.nativeKeybinds) do
        if bind.target == "flip" then
            bind.target = "on"
        end
    end
end

function UT:saveNativeKeybinds()
    UT.Utility:writeFile(UT.rootPath .. "/native-keybinds.json", UT.Utility:jsonEncode(UT.nativeKeybinds))
end

function UT:addNativeKeybind(bind)
    table.insert(UT.nativeKeybinds, bind)
    UT:saveNativeKeybinds()
end

function UT:updateNativeKeybind(id, fields)
    for index, bind in pairs(UT.nativeKeybinds) do
        if bind.id == id then
            for key, value in pairs(fields) do
                bind[key] = value
            end
            break
        end
    end
    UT:saveNativeKeybinds()
end

function UT:removeNativeKeybind(id)
    for index, bind in pairs(UT.nativeKeybinds) do
        if bind.id == id then
            table.remove(UT.nativeKeybinds, index)
            break
        end
    end
    UT:saveNativeKeybinds()
end

function UT:update()
    if UT.GameUtility:isInGame() then
        if UT.GameUtility:isInHeist() then
            if UT.GameUtility:isPlayerUnitAlive() then
                if not UT.playerUnitAliveEventTriggered then
                    UT:playerUnitAliveEvent()
                end

                if UT.enableNoClip then
                    UT:updateNoClip(UT.noClipSpeed)
                end
            end

            if UT.environment then
                if UT:getEnvironment() ~= UT.environment then
                    UT:setEnvironment(UT.environment)
                end
            end

            if UT.enableDisableAI then
                UT:disableAI()
            end

            if UT.Build.pickedUnit then
                UT.Build:drawPickedUnit()
            end
        end
    end

    UTMenu:update()

    local addons = UT:getPersistAddons()
    for index, addon in pairs(addons) do
        if addon.enable and addon.code then
            UT.Utility:evaluateCode(addon.code)
        end
    end
end

function UT:loadSettings()
    local content = UT.Utility:readFile(UT.rootPath .. "/settings.json")
    if content then
        UT.settings = UT.Utility:jsonDecode(content)
    end
end

function UT:getSetting(name)
    return UT.settings[name]
end

function UT:setSetting(name, value)
    UT.settings[name] = value
    UT.Utility:writeFile(UT.rootPath .. "/settings.json", UT.Utility:jsonEncode(UT.settings))
end

function UT:hideModsList()
    function MenuCallbackHandler:is_modded_client()
        return false
    end

    function MenuCallbackHandler:is_not_modded_client()
        return true
    end

    function MenuCallbackHandler:build_mods_list()
        return {}
    end
end

function UT:pauseStatsPublishing()
    if NetworkAccountEPIC then
        function NetworkAccountEPIC:publish_statistics() end
    end

    if NetworkAccountSTEAM then
        function NetworkAccountSTEAM:publish_statistics() end
    end
end

function UT:loadAddons()
    local content = UT.Utility:readFile(UT.rootPath .. "/addons.json")
    if content then
        local data = UT.Utility:jsonDecode(content)
        UT.addons = data.addons
    end
end

function UT:getAddonsByType(type)
    local addons = {}
    for index, addon in pairs(UT.addons) do
        if addon.type == type then
            UT.Utility:tableInsert(addons, addon)
        end
    end
    return addons
end

function UT:getKeybindAddons()
    return UT:getAddonsByType("keybind")
end

function UT:getHookAddons()
    return UT:getAddonsByType("hook")
end

function UT:getPersistAddons()
    return UT:getAddonsByType("persist")
end

function UT:getKeybindAddon(addonId)
    local addons = UT:getKeybindAddons()
    for index, addon in pairs(addons) do
        if addon.id == addonId then
            return addon
        end
    end
    return nil
end

function UT:runKeybindAddon(addonId)
    local addon = UT:getKeybindAddon(addonId)
    if addon and addon.enable and addon.code then
        UT.Utility:evaluateCode(addon.code)
    end
end

function UT:runHookAddons(hookId)
    local addons = UT:getHookAddons()
    for index, addon in pairs(addons) do
        if UT.Utility:toLowerCase(addon.hookId) == UT.Utility:toLowerCase(hookId) and addon.enable and addon.code then
            UT.Utility:evaluateCode(addon.code)
        end
    end
end

function UT:heistEnterEvent()
    UT.initialEnvironment = UT:getEnvironment()
end

function UT:playerUnitAliveEvent()
    UT.playerUnitAliveEventTriggered = true

    if UT.xRayEnabled then
        UT:setXRay(true)
        UT:syncXRayColors()
    end

    if UT:getSetting("enable-god-mode") then
        UT:setGodMode(true)
    else
        if UT.GameUtility:getPlayerUnit():character_damage():god_mode() then
            UT:setGodMode(false)
        end
    end
    if UT:getSetting("enable-no-fall-damage") then
        UT:setNoFallDamage(true)
    end
    if UT:getSetting("enable-infinite-stamina") then
        UT:setInfiniteStamina(true)
    end
    if UT:getSetting("enable-can-run-directional") then
        UT:setCanRunDirectional(true)
    end
    if UT:getSetting("enable-can-run-with-any-bag") then
        UT:setCanRunDirectional(true)
    end
    if UT:getSetting("enable-instant-mask-on") then
        UT:setInstantMaskOn(true)
    end
    if UT:getSetting("enable-no-carry-cooldown") then
        UT:setNoCarryCooldown(true)
    end
    if UT:getSetting("enable-no-flashbangs") then
        UT:setNoFlashbangs(true)
    end
    if UT:getSetting("enable-instant-interaction") then
        UT:setInstantInteraction(true)
    end
    if UT:getSetting("enable-instant-deployment") then
        UT:setInstantDeployment(true)
    end
    if UT:getSetting("enable-unlimited-equipment") then
        UT:setUnlimitedEquipment(true)
    end
    if UT:getSetting("enable-instant-weapon-swap") then
        UT:setInstantWeaponSwap(true)
    end
    if UT:getSetting("enable-instant-weapon-reload") then
        UT:setInstantWeaponReload(true)
    end
    if UT:getSetting("enable-no-weapon-recoil") then
        UT:setNoWeaponRecoil(true)
    end
    if UT:getSetting("enable-no-weapon-spread") then
        UT:setNoWeaponSpread(true)
    end
    if UT:getSetting("enable-shoot-through-walls") then
        UT:setShootThroughWalls(true)
    end
    if UT:getSetting("enable-unlimited-ammo") then
        UT:setUnlimitedAmmo(true)
    end
    if UT:getSetting("enable-no-slow-motion") then
        UT:setNoSlowMotion(true)
    end
    if UT:getSetting("enable-move-speed-multiplier") and UT:getSetting("move-speed-multiplier") then
        UT:setMoveSpeedMultiplier(true, UT:getSetting("move-speed-multiplier"))
    end
    if UT:getSetting("enable-throw-distance-multiplier") and UT:getSetting("throw-distance-multiplier") then
        UT:setThrowDistanceMultiplier(true, UT:getSetting("throw-distance-multiplier"))
    end
    if UT:getSetting("enable-fire-rate-multiplier") and UT:getSetting("fire-rate-multiplier") then
        UT:setFireRateMultiplier(true, UT:getSetting("fire-rate-multiplier"))
    end
    if UT:getSetting("enable-damage-multiplier") and UT:getSetting("damage-multiplier") then
        UT:setDamageMultiplier(true, UT:getSetting("damage-multiplier"))
    end
    if UT:getSetting("enable-melee-damage-multiplier") and UT:getSetting("melee-damage-multiplier") then
        UT:setMeleeDamageMultiplier(true, UT:getSetting("melee-damage-multiplier"))
    end
    if UT:getSetting("enable-dodge-chance-bonus") and UT:getSetting("dodge-chance-bonus") then
        UT:setDodgeChanceBonus(true, UT:getSetting("dodge-chance-bonus"))
    end
    if UT:getSetting("enable-detection-range-multiplier") and UT:getSetting("detection-range-multiplier") then
        UT:setDetectionRangeMultiplier(true, UT:getSetting("detection-range-multiplier"))
    end
    if UT:getSetting("enable-max-health-multiplier") and UT:getSetting("max-health-multiplier") then
        UT:setMaxHealthMultiplier(true, UT:getSetting("max-health-multiplier"))
    end
    if UT:getSetting("enable-max-armor-multiplier") and UT:getSetting("max-armor-multiplier") then
        UT:setMaxArmorMultiplier(true, UT:getSetting("max-armor-multiplier"))
    end
    if UT:getSetting("enable-reload-speed-multiplier") and UT:getSetting("reload-speed-multiplier") then
        UT:setReloadSpeedMultiplier(true, UT:getSetting("reload-speed-multiplier"))
    end
    if UT:getSetting("enable-ammo-pickup-multiplier") and UT:getSetting("ammo-pickup-multiplier") then
        UT:setAmmoPickupMultiplier(true, UT:getSetting("ammo-pickup-multiplier"))
    end
    if UT:getSetting("enable-interaction-speed-percent") and UT:getSetting("interaction-speed-percent") then
        UT:setInteractionSpeedMultiplier(true, UT:getSetting("interaction-speed-percent") / 100)
    end
end

function UT:_applyPlayerUpgradeValueOverride()
    UT.Utility:cloneClass(PlayerManager)
    function PlayerManager:upgrade_value(category, upgrade, default)
        if category == "player" then
            if upgrade == "convert_enemies" and UT.unlimitedConversionEnabled then
                return true
            elseif upgrade == "convert_enemies_max_minions" and UT.unlimitedConversionEnabled then
                return UT.maxInteger
            elseif upgrade == "passive_dodge_chance" and UT.dodgeChanceBonus and UT.dodgeChanceBonus > 0 then
                return PlayerManager.orig.upgrade_value(self, category, upgrade, default) + UT.dodgeChanceBonus
            end
        end
        return PlayerManager.orig.upgrade_value(self, category, upgrade, default)
    end
end

function UT:setUnlimitedConversion(enabled)
    UT.unlimitedConversionEnabled = enabled
    UT:_applyPlayerUpgradeValueOverride()
end

function UT:setDodgeChanceBonus(enabled, bonus)
    if not UT.GameUtility:isInHeist() then
        return
    end
    UT.dodgeChanceBonus = enabled and bonus or 0
    UT:_applyPlayerUpgradeValueOverride()
end

function UT:setDetectionRangeMultiplier(enabled, multiplier)
    if not UT.GameUtility:isInHeist() then
        return
    end

    local playerUnit = UT.GameUtility:getPlayerUnit()
    if not playerUnit then
        return
    end

    UT.Utility:cloneClass(PlayerBase)
    UT.detectionRangeMultiplier = enabled and multiplier or 1.0

    if enabled then
        function PlayerBase:set_detection_multiplier(reason, mul)
            PlayerBase.orig.set_detection_multiplier(self, reason, mul)
            self._detection_settings.range_mul = self._detection_settings.range_mul * UT.detectionRangeMultiplier
        end
    else
        PlayerBase.set_detection_multiplier = PlayerBase.orig.set_detection_multiplier
    end

    local base = playerUnit:base()
    if base and base.set_detection_multiplier then
        base:set_detection_multiplier("ut_trainer_range", 1)
    end
end

function UT:setUnlimitedGagePackages(enabled)
    UT.Utility:cloneClass(GageAssignmentTweakData)
    if enabled then
        function GageAssignmentTweakData:get_num_assignment_units()
            return UT.maxInteger
        end
    else
        GageAssignmentTweakData.get_num_assignment_units = GageAssignmentTweakData.orig.get_num_assignment_units
    end
end

function UT:disableSentryGunPickup()
    UT.Utility:cloneClass(SentryGunBase)
    function SentryGunBase.on_picked_up() end
end

function UT:disableCarryVerify()
    UT.Utility:cloneClass(PlayerManager)
    function PlayerManager:verify_carry()
        return true
    end

    UT.carryVerifyDisabled = true
end

-- Career

function UT:setLevel(level)
    local rank = managers.experience:current_rank()
    managers.experience:reset()
    managers.experience:_set_current_level(level)
    managers.experience:set_current_rank(rank)
end

function UT:setInfamyRank(infamyRank)
    managers.experience:set_current_rank(infamyRank)
end

function UT:addSpendingMoney(amount)
    managers.money:add_to_spending(amount)
end

function UT:addOffshoreMoney(amount)
    managers.money:add_to_offshore(amount)
end

function UT:resetMoney()
    managers.money:reset()
end

function UT:addContinentalCoins(amount)
    managers.custom_safehouse:add_coins(amount)
end

function UT:resetContinentalCoins()
    Global.custom_safehouse_manager.total = 0
    Global.custom_safehouse_manager.total_collected = 0
end

function UT:addPerkPoints(amount)
    local stars = managers.experience:level_to_stars()
    local conversion = tweak_data.skilltree.specialization_convertion_rate[stars] or 1000

    managers.skilltree:give_specialization_points(amount * conversion)
end

function UT:resetPerkDecks()
    Global.skilltree_manager.specializations.total_points = 0
    managers.skilltree:reset_specializations()
end

function UT:getBlackMarketItem(blackMarketCategory, itemId)
    if not tweak_data.blackmarket[blackMarketCategory] then
        return
    end
    return tweak_data.blackmarket[blackMarketCategory][itemId]
end

function UT:getBlackMarketItemGlobalValue(item)
    local globalValue = "normal"
    if item.global_value then
        globalValue = item.global_value
    elseif item.infamous then
        globalValue = "infamous"
    elseif item.dlc then
        globalValue = item.dlc
    end
    return globalValue
end

function UT:addItemsToBlackMarket(blackMarketCategory, itemIds)
    for index, itemId in pairs(itemIds) do
        local item = UT:getBlackMarketItem(blackMarketCategory, itemId)
        if not item then
            goto continue
        end
        local globalValue = UT:getBlackMarketItemGlobalValue(item)
        managers.blackmarket:add_to_inventory(globalValue, blackMarketCategory, itemId, false)
        ::continue::
    end
end

function UT:removeItemsFromBlackMarket(blackMarketCategory, itemIds)
    for index, itemId in pairs(itemIds) do
        local item = UT:getBlackMarketItem(blackMarketCategory, itemId)
        if not item then
            goto continue
        end
        local globalValue = UT:getBlackMarketItemGlobalValue(item)
        if not Global.blackmarket_manager.inventory[globalValue]
            or not Global.blackmarket_manager.inventory[globalValue][blackMarketCategory] then
            goto continue
        end
        Global.blackmarket_manager.inventory[globalValue][blackMarketCategory][itemId] = nil
        ::continue::
    end
end

function UT:setBlackMarketSlotsLock(value)
    for i = 1, 160 do
        Global.blackmarket_manager.unlocked_weapon_slots.primaries[i] = value
        Global.blackmarket_manager.unlocked_weapon_slots.secondaries[i] = value
        Global.blackmarket_manager.unlocked_mask_slots[i] = value
    end
end

function UT:removeBlackMarketExclamationMarks()
    Global.blackmarket_manager.new_drops = {}
end

function UT:getTrophy(trophyId)
    local trophies = Global.custom_safehouse_manager.trophies
    for index, trophy in pairs(trophies) do
        if trophy.id == trophyId then
            return trophy
        end
    end
end

function UT:unlockTrophies(trophyIds)
    for index, trophyId in pairs(trophyIds) do
        local trophy = UT:getTrophy(trophyId)
        if not trophy then
            goto continue
        end
        trophy.completed = true
        ::continue::
    end
end

function UT:lockTrophies(trophyIds)
    for index, trophyId in pairs(trophyIds) do
        local trophy = UT:getTrophy(trophyId)
        if not trophy then
            goto continue
        end
        trophy.completed = false
        ::continue::
    end
end

function UT:unlockSteamAchievements(steamAchievementIds)
    for index, achievementId in pairs(steamAchievementIds) do
        managers.achievment:award(achievementId)
    end
end

function UT:lockSteamAchievements(steamAchievementIds)
    for index, achievementId in pairs(steamAchievementIds) do
        managers.achievment:clear_steam(achievementId)
    end
end

-- Environment

function UT:getEnvironment()
    return managers.viewport:first_active_viewport():get_environment_path()
end

function UT:setEnvironment(environment)
    managers.viewport:first_active_viewport():set_environment(environment)
    UT.environment = environment
end

function UT:setInitialEnvironment()
    UT:setEnvironment(UT.initialEnvironment)
end

-- Cheats

function UT:setGodMode(enabled)
    local playerUnit = UT.GameUtility:getPlayerUnit()
    if not playerUnit then
        return
    end
    playerUnit:character_damage():set_god_mode(enabled)
end

function UT:setNoFallDamage(enabled)
    if not UT.GameUtility:isInHeist() then
        return
    end
    UT.Utility:cloneClass(PlayerDamage)
    if enabled or UT.enableNoClip then
        function PlayerDamage:damage_fall() end
    else
        PlayerDamage.damage_fall = PlayerDamage.orig.damage_fall
    end
end

function UT:setNoMeleeDamage(enabled)
    UT.Utility:cloneClass(PlayerDamage)
    if enabled then
        function PlayerDamage:damage_melee() end
    else
        PlayerDamage.damage_melee = PlayerDamage.orig.damage_melee
    end
    UT.noMeleeDamageEnabled = enabled
end

function UT:setInfiniteStamina(enabled)
    if not UT.GameUtility:isInHeist() then
        return
    end
    UT.Utility:cloneClass(PlayerMovement)
    if enabled then
        function PlayerMovement:_change_stamina() end

        function PlayerMovement:is_stamina_drained() return false end
    else
        PlayerMovement._change_stamina = PlayerMovement.orig._change_stamina
        PlayerMovement.is_stamina_drained = PlayerMovement.orig.is_stamina_drained
    end
end

function UT:setCanRunDirectional(enabled)
    if not UT.GameUtility:isInHeist() then
        return
    end
    UT.Utility:cloneClass(PlayerStandard)
    if enabled then
        function PlayerStandard:_can_run_directional() return true end
    else
        PlayerStandard._can_run_directional = PlayerStandard.orig._can_run_directional
    end
end

function UT:setCanRunWithAnyBag(enabled)
    UT.backup.tweakDataCarryTypes = UT.backup.tweakDataCarryTypes or UT.Utility:deepClone(tweak_data.carry.types)
    if enabled then
        for type, data in pairs(tweak_data.carry.types) do
            tweak_data.carry.types[type].can_run = true
        end
    else
        for type, data in pairs(UT.backup.tweakDataCarryTypes) do
            tweak_data.carry.types[type].can_run = data.can_run
        end
    end
end

function UT:setInstantMaskOn(enabled)
    if not UT.GameUtility:isInHeist() then
        return
    end
    UT.backup.tweakDataPlayerPutOnMaskTime = UT.backup.tweakDataPlayerPutOnMaskTime or tweak_data.player.put_on_mask_time
    if enabled then
        tweak_data.player.put_on_mask_time = 0
    else
        tweak_data.player.put_on_mask_time = UT.backup.tweakDataPlayerPutOnMaskTime
    end
end

function UT:setNoCarryCooldown(enabled)
    if not UT.GameUtility:isInHeist() then
        return
    end
    UT.Utility:cloneClass(PlayerManager)
    if enabled then
        function PlayerManager:carry_blocked_by_cooldown() return false end
    else
        PlayerManager.carry_blocked_by_cooldown = PlayerManager.orig.carry_blocked_by_cooldown
    end
end

function UT:setNoFlashbangs(enabled)
    if not UT.GameUtility:isInHeist() then
        return
    end
    UT.Utility:cloneClass(CoreEnvironmentControllerManager)
    if enabled then
        function CoreEnvironmentControllerManager:set_flashbang() end
    else
        CoreEnvironmentControllerManager.set_flashbang = CoreEnvironmentControllerManager.orig.set_flashbang
    end
end

function UT:_applyInteractionTimerOverride()
    UT.Utility:cloneClass(BaseInteractionExt)
    function BaseInteractionExt:_get_timer()
        if UT.instantInteractionEnabled then
            return 0.001
        end
        local base = BaseInteractionExt.orig._get_timer(self)
        if UT.interactionSpeedMultiplier and UT.interactionSpeedMultiplier ~= 1.0 then
            return base / UT.interactionSpeedMultiplier
        end
        return base
    end
end

function UT:setInstantInteraction(enabled)
    if not UT.GameUtility:isInHeist() then
        return
    end
    UT.instantInteractionEnabled = enabled
    UT:_applyInteractionTimerOverride()
end

function UT:setInteractionSpeedMultiplier(enabled, multiplier)
    if not UT.GameUtility:isInHeist() then
        return
    end
    UT.interactionSpeedMultiplier = enabled and multiplier or 1.0
    UT:_applyInteractionTimerOverride()
end

function UT:setInstantDeployment(enabled)
    if not UT.GameUtility:isInHeist() then
        return
    end
    UT.Utility:cloneClass(PlayerManager)
    if enabled then
        function PlayerManager:selected_equipment_deploy_timer() return 0.001 end
    else
        PlayerManager.selected_equipment_deploy_timer = PlayerManager.orig.selected_equipment_deploy_timer
    end
end

function UT:setUnlimitedEquipment(enabled)
    if not UT.GameUtility:isInHeist() then
        return
    end
    UT.Utility:cloneClass(BaseInteractionExt)
    UT.Utility:cloneClass(PlayerManager)
    if enabled then
        function BaseInteractionExt:_has_required_upgrade() return true end

        function BaseInteractionExt:_has_required_deployable() return true end

        function BaseInteractionExt:can_interact() return true end

        function PlayerManager:on_used_body_bag() end

        function PlayerManager:remove_equipment() end

        function PlayerManager:remove_special() end

        function PlayerManager:add_grenade_amount(amount, sync)
            if amount < 0 then
                return
            end

            PlayerManager.orig.add_grenade_amount(self, amount, sync)
        end
    else
        BaseInteractionExt._has_required_upgrade = BaseInteractionExt.orig._has_required_upgrade
        BaseInteractionExt._has_required_deployable = BaseInteractionExt.orig._has_required_deployable
        BaseInteractionExt.can_interact = BaseInteractionExt.orig.can_interact
        PlayerManager.on_used_body_bag = PlayerManager.orig.on_used_body_bag
        PlayerManager.remove_equipment = PlayerManager.orig.remove_equipment
        PlayerManager.remove_special = PlayerManager.orig.remove_special
        PlayerManager.add_grenade_amount = PlayerManager.orig.add_grenade_amount
    end
end

function UT:setInstantWeaponSwap(enabled)
    if not UT.GameUtility:isInHeist() then
        return
    end
    UT.Utility:cloneClass(PlayerStandard)
    if enabled then
        function PlayerStandard:_get_swap_speed_multiplier() return 1000 end
    else
        PlayerStandard._get_swap_speed_multiplier = PlayerStandard.orig._get_swap_speed_multiplier
    end
end

function UT:setInstantWeaponReload(enabled)
    if not UT.GameUtility:isInHeist() then
        return
    end
    UT.Utility:cloneClass(RaycastWeaponBase)
    if enabled then
        function RaycastWeaponBase:can_reload()
            self:on_reload()
            managers.hud:set_ammo_amount(self:selection_index(), self:ammo_info())
            return false
        end
    else
        RaycastWeaponBase.can_reload = RaycastWeaponBase.orig.can_reload
    end
end

function UT:setNoWeaponRecoil(enabled)
    if not UT.GameUtility:isInHeist() then
        return
    end
    UT.Utility:cloneClass(NewRaycastWeaponBase)
    if enabled then
        function NewRaycastWeaponBase:recoil_multiplier() return 0 end
    else
        NewRaycastWeaponBase.recoil_multiplier = NewRaycastWeaponBase.orig.recoil_multiplier
    end
end

function UT:setNoWeaponSpread(enabled)
    if not UT.GameUtility:isInHeist() then
        return
    end
    UT.Utility:cloneClass(NewRaycastWeaponBase)
    if enabled then
        function NewRaycastWeaponBase:spread_multiplier() return 0 end
    else
        NewRaycastWeaponBase.spread_multiplier = NewRaycastWeaponBase.orig.spread_multiplier
    end
end

function UT:setShootThroughWalls(enabled)
    local playerUnit = UT.GameUtility:getPlayerUnit()
    if not playerUnit or not UT.GameUtility:isPlayerUnitAlive() then
        return
    end

    UT.Utility:cloneClass(RaycastWeaponBase)
    UT.Utility:cloneClass(NewRaycastWeaponBase)

    if enabled then
        RaycastWeaponBase._can_shoot_through_shield = true
        RaycastWeaponBase._can_shoot_through_wall = true
        NewRaycastWeaponBase._can_shoot_through_shield = true
        NewRaycastWeaponBase._can_shoot_through_wall = true
    else
        RaycastWeaponBase._can_shoot_through_shield = RaycastWeaponBase.orig._can_shoot_through_shield
        RaycastWeaponBase._can_shoot_through_wall = RaycastWeaponBase.orig._can_shoot_through_wall
        NewRaycastWeaponBase._can_shoot_through_shield = NewRaycastWeaponBase.orig._can_shoot_through_shield
        NewRaycastWeaponBase._can_shoot_through_wall = NewRaycastWeaponBase.orig._can_shoot_through_wall
    end

    for _, selection in pairs(playerUnit:inventory()._available_selections) do
        if selection.unit then
            local unitBase = selection.unit:base()
            if enabled then
                unitBase._bullet_slotmask_old = unitBase._bullet_slotmask
                unitBase._bullet_slotmask = World:make_slot_mask(7, 11, 12, 14, 16, 17, 18, 21, 22, 25, 26, 33, 34, 35)
            else
                if unitBase._bullet_slotmask_old then
                    unitBase._bullet_slotmask = unitBase._bullet_slotmask_old
                    unitBase._bullet_slotmask_old = nil
                end
            end
        end
    end
end

function UT:setUnlimitedAmmo(enabled)
    if not UT.GameUtility:isInHeist() then
        return
    end
    UT.Utility:cloneClass(RaycastWeaponBase)
    UT.Utility:cloneClass(SawWeaponBase)
    if enabled then
        function RaycastWeaponBase:clip_empty()
            self:set_ammo_total(self:get_ammo_max())
            return self:get_ammo_remaining_in_clip() == 0
        end

        function SawWeaponBase:clip_empty()
            self:set_ammo_total(self:get_ammo_max())
            return self:get_ammo_remaining_in_clip() == 0
        end
    else
        RaycastWeaponBase.clip_empty = RaycastWeaponBase.orig.clip_empty
        SawWeaponBase.clip_empty = SawWeaponBase.orig.clip_empty
    end
end

function UT:setNoSlowMotion(enabled)
    if not UT.GameUtility:isInHeist() then
        return
    end
    UT.Utility:cloneClass(TimeSpeedManager)
    if enabled then
        function TimeSpeedManager:play_effect() end
    else
        TimeSpeedManager.play_effect = TimeSpeedManager.orig.play_effect
    end
end

function UT:setMoveSpeedMultiplier(enabled, multiplier)
    if not UT.GameUtility:isInHeist() then
        return
    end
    UT.Utility:cloneClass(PlayerManager)
    if enabled then
        function PlayerManager:movement_speed_multiplier() return multiplier end
    else
        PlayerManager.movement_speed_multiplier = PlayerManager.orig.movement_speed_multiplier
    end
end

function UT:setThrowDistanceMultiplier(enabled, multiplier)
    if not UT.GameUtility:isInHeist() then
        return
    end
    UT.backup.tweakDataCarryTypes = UT.backup.tweakDataCarryTypes or UT.Utility:deepClone(tweak_data.carry.types)
    if enabled then
        for type, data in pairs(tweak_data.carry.types) do
            tweak_data.carry.types[type].throw_distance_multiplier = multiplier
        end
    else
        for type, data in pairs(UT.backup.tweakDataCarryTypes) do
            tweak_data.carry.types[type].throw_distance_multiplier = data.throw_distance_multiplier
        end
    end
end

function UT:setFireRateMultiplier(enabled, multiplier)
    if not UT.GameUtility:isInHeist() then
        return
    end
    UT.Utility:cloneClass(NewRaycastWeaponBase)
    if enabled then
        function NewRaycastWeaponBase:fire_rate_multiplier() return multiplier end
    else
        NewRaycastWeaponBase.fire_rate_multiplier = NewRaycastWeaponBase.orig.fire_rate_multiplier
    end
end

function UT:setDamageMultiplier(enabled, multiplier)
    if not UT.GameUtility:isInHeist() then
        return
    end
    UT.Utility:cloneClass(CopDamage)
    if enabled then
        function CopDamage:damage_bullet(attack_data)
            if attack_data.attacker_unit == managers.player:local_player() then
                attack_data.damage = attack_data.damage * multiplier
            end
            return CopDamage.orig.damage_bullet(self, attack_data)
        end
    else
        CopDamage.damage_bullet = CopDamage.orig.damage_bullet
    end
end

function UT:setMeleeDamageMultiplier(enabled, multiplier)
    if not UT.GameUtility:isInHeist() then
        return
    end
    UT.Utility:cloneClass(CopDamage)
    if enabled then
        function CopDamage:damage_melee(attack_data)
            if attack_data.attacker_unit == managers.player:local_player() then
                attack_data.damage = attack_data.damage * multiplier
            end
            return CopDamage.orig.damage_melee(self, attack_data)
        end
    else
        CopDamage.damage_melee = CopDamage.orig.damage_melee
    end
end

function UT:setMaxHealthMultiplier(enabled, multiplier)
    if not UT.GameUtility:isInHeist() then
        return
    end
    UT.Utility:cloneClass(PlayerDamage)
    if enabled then
        function PlayerDamage:_max_health()
            return PlayerDamage.orig._max_health(self) * multiplier
        end
    else
        PlayerDamage._max_health = PlayerDamage.orig._max_health
    end
end

function UT:setMaxArmorMultiplier(enabled, multiplier)
    if not UT.GameUtility:isInHeist() then
        return
    end
    UT.Utility:cloneClass(PlayerDamage)
    if enabled then
        function PlayerDamage:_max_armor()
            return PlayerDamage.orig._max_armor(self) * multiplier
        end
    else
        PlayerDamage._max_armor = PlayerDamage.orig._max_armor
    end
end

function UT:setReloadSpeedMultiplier(enabled, multiplier)
    if not UT.GameUtility:isInHeist() then
        return
    end

    UT.Utility:cloneClass(RaycastWeaponBase)
    UT.Utility:cloneClass(PlayerStandard)
    UT.reloadSpeedMultiplier = enabled and multiplier or 1.0

    if enabled then
        -- Shell-by-shell weapons (e.g. shotguns) consult this directly.
        function RaycastWeaponBase:reload_speed_multiplier()
            return RaycastWeaponBase.orig.reload_speed_multiplier(self) * multiplier
        end

        -- Regular magazine weapons: let the vanilla reload start normally, then
        -- compress the remaining time until it completes.
        function PlayerStandard:_start_action_reload(t, ...)
            local result = PlayerStandard.orig._start_action_reload(self, t, ...)
            if self._state_data.reload_expire_t and UT.reloadSpeedMultiplier and UT.reloadSpeedMultiplier ~= 1.0 then
                local remaining = self._state_data.reload_expire_t - t
                self._state_data.reload_expire_t = t + remaining / UT.reloadSpeedMultiplier
            end
            return result
        end
    else
        RaycastWeaponBase.reload_speed_multiplier = RaycastWeaponBase.orig.reload_speed_multiplier
        PlayerStandard._start_action_reload = PlayerStandard.orig._start_action_reload
    end
end

function UT:setAmmoPickupMultiplier(enabled, multiplier)
    if not UT.GameUtility:isInHeist() then
        return
    end
    UT.Utility:cloneClass(RaycastWeaponBase)
    if enabled then
        function RaycastWeaponBase:add_ammo(ratio, add_amount_override, ...)
            if ratio and not add_amount_override then
                ratio = ratio * multiplier
            end
            return RaycastWeaponBase.orig.add_ammo(self, ratio, add_amount_override, ...)
        end
    else
        RaycastWeaponBase.add_ammo = RaycastWeaponBase.orig.add_ammo
    end
end

-- Mission

function UT:startTheHeist()
    managers.network:session():spawn_players()
end

function UT:restartTheHeist()
    managers.game_play_central:restart_the_game()
end

function UT:finishTheHeist()
    local amountOfAlivePlayers = managers.network:session():amount_of_alive_players()
    managers.network:session():send_to_peers("mission_ended", true, amountOfAlivePlayers)
    game_state_machine:change_state_by_name("victoryscreen", {
        num_winners = amountOfAlivePlayers,
        personal_win = UT.GameUtility:isPlayerUnitAlive()
    })
end

function UT:leaveTheHeist()
    MenuCallbackHandler:_dialog_end_game_yes()
end

function UT:accessCameras()
    game_state_machine:change_state_by_name("ingame_access_camera")
end

function UT:triggerTheAlarm()
    managers.groupai:state():on_police_called("empty")
end

function UT:removeInvisibleWalls()
    local units = World:find_units_quick("all", 1)
    for index, unit in pairs(units) do
        if UT.Utility:inTable(unit:name():key(), UT.invisibleWalls) then
            UT.GameUtility:deleteUnit(unit)
        end
    end
end

function UT:killAllEnemies()
    for key, data in pairs(managers.enemy:all_enemies()) do
        UT.GameUtility:killUnit(data.unit)
    end
end

function UT:killAllCivilians()
    for key, data in pairs(managers.enemy:all_civilians()) do
        UT.GameUtility:killUnit(data.unit)
    end
end

function UT:tieAllCivilians()
    for key, data in pairs(managers.enemy:all_civilians()) do
        local brain = data.unit:brain()

        if brain:is_tied() then
            goto continue
        end

        brain:action_request({
            clamp_to_graph = true,
            variant = "halt",
            body_part = 1,
            type = "act"
        })
        brain._current_logic.on_intimidated(brain._logic_data, UT.maxInteger, UT.GameUtility:getPlayerUnit(), true)
        brain:on_tied(UT.GameUtility:getPlayerUnit())

        ::continue::
    end
end

function UT:convertAllEnemies()
    UT:setUnlimitedConversion(true)

    for key, data in pairs(managers.enemy:all_enemies()) do
        if not UT.GameUtility:isUnitAlive(data.unit) then
            goto continue
        end

        managers.groupai:state():convert_hostage_to_criminal(data.unit)
        managers.groupai:state():sync_converted_enemy(data.unit)
        ::continue::
    end

    UT:setUnlimitedConversion(false)
end

function UT:syncXRayColors()
    if ContourExt._types.ut_xray_enemy then
        mvector3.set(ContourExt._types.ut_xray_enemy.color, UT.xrayEnemyColor)
    end
    if ContourExt._types.ut_xray_civilian then
        mvector3.set(ContourExt._types.ut_xray_civilian.color, UT.xrayCivilianColor)
    end
    if ContourExt._types.ut_xray_camera then
        mvector3.set(ContourExt._types.ut_xray_camera.color, UT.xrayCameraColor)
    end
end

function UT:refreshXRay()
    if UT.xRayEnabled and UT.GameUtility:isInHeist() then
        UT:syncXRayColors()
        UT:setXRay(false)
        UT:setXRay(true)
    end
end

function UT:setXRayEnemyColor(color)
    UT.xrayEnemyColor = color
    UT:refreshXRay()
end

function UT:setXRayCivilianColor(color)
    UT.xrayCivilianColor = color
    UT:refreshXRay()
end

function UT:setXRayCameraColor(color)
    UT.xrayCameraColor = color
    UT:refreshXRay()
end

function UT:registerXRayContourTypes()
    if ContourExt._types.ut_xray_enemy then
        return
    end

    local function cloneContourType(baseName, color)
        local newType = {}
        for key, value in pairs(ContourExt._types[baseName]) do
            newType[key] = value
        end
        newType.color = color
        return newType
    end

    ContourExt._types.ut_xray_enemy = cloneContourType("mark_enemy", UT.xrayEnemyColor)
    ContourExt._types.ut_xray_civilian = cloneContourType("mark_enemy", UT.xrayCivilianColor)
    ContourExt._types.ut_xray_camera = cloneContourType("mark_unit", UT.xrayCameraColor)
end

function UT:setXRay(enabled)
    UT.xRayEnabled = enabled

    if not UT.GameUtility:isInHeist() then
        return
    end

    UT.Utility:cloneClass(EnemyManager)
    if enabled then
        UT:registerXRayContourTypes()

        for key, data in pairs(managers.enemy:all_civilians()) do
            data.unit:contour():add("ut_xray_civilian", false, UT.maxInteger)
        end

        for key, data in pairs(managers.enemy:all_enemies()) do
            data.unit:contour():add("ut_xray_enemy", false, UT.maxInteger)
        end

        for key, unit in pairs(SecurityCamera.cameras) do
            unit:contour():add("ut_xray_camera", false, UT.maxInteger)
        end

        function EnemyManager:register_civilian(unit, ...)
            EnemyManager.orig.register_civilian(self, unit, ...)
            unit:contour():add("ut_xray_civilian", false, UT.maxInteger)
        end

        function EnemyManager:register_enemy(unit, ...)
            EnemyManager.orig.register_enemy(self, unit, ...)
            unit:contour():add("ut_xray_enemy", false, UT.maxInteger)
        end

        function EnemyManager:on_civilian_died(unit, ...)
            EnemyManager.orig.on_civilian_died(self, unit, ...)
            unit:contour():remove("ut_xray_civilian", false)
        end

        function EnemyManager:on_enemy_died(unit, ...)
            EnemyManager.orig.on_enemy_died(self, unit, ...)
            unit:contour():remove("ut_xray_enemy", false)
        end
    else
        for key, data in pairs(managers.enemy:all_civilians()) do
            data.unit:contour():remove("ut_xray_civilian", false)
        end

        for key, data in pairs(managers.enemy:all_enemies()) do
            data.unit:contour():remove("ut_xray_enemy", false)
        end

        for key, unit in pairs(SecurityCamera.cameras) do
            unit:contour():remove("ut_xray_camera", false)
        end

        EnemyManager.register_enemy = EnemyManager.orig.register_enemy
        EnemyManager.register_civilian = EnemyManager.orig.register_civilian
        EnemyManager.on_enemy_died = EnemyManager.orig.on_enemy_died
        EnemyManager.on_civilian_died = EnemyManager.orig.on_civilian_died
    end
end

function UT:setPreventAlarmTriggering(enabled)
    UT.Utility:cloneClass(GroupAIStateBase)
    if enabled then
        function GroupAIStateBase:on_police_called() end
    else
        GroupAIStateBase.on_police_called = GroupAIStateBase.orig.on_police_called
    end
    UT.preventAlarmTriggeringEnabled = enabled
end

function UT:setNoClip(enabled, speed)
    UT.noClipSpeed = speed
    UT.enableNoClip = enabled
    UT:setNoFallDamage(enabled or UT:getSetting("enable-no-fall-damage"))
    UT.noClipEnabled = enabled
end

function UT:updateNoClip(speed)
    if UT.GameUtility:isDriving() then
        return
    end

    local keyboard = Input:keyboard()
    local speed = keyboard.down(keyboard, UT.GameUtility:idString("left shift")) and speed * 2 or speed
    local x = keyboard.down(keyboard, UT.GameUtility:idString("w")) and 1 or keyboard.down(keyboard, UT.GameUtility:idString("s")) and -1 or 0
    local y = keyboard.down(keyboard, UT.GameUtility:idString("d")) and 1 or keyboard.down(keyboard, UT.GameUtility:idString("a")) and -1 or 0
    local z = keyboard.down(keyboard, UT.GameUtility:idString("space")) and 1 or keyboard.down(keyboard, UT.GameUtility:idString("left ctrl")) and -1 or 0
    local rotation = UT.GameUtility:getPlayerCameraRotation()
    local direction = rotation:x() * y + rotation:y() * x
    local delta = Vector3(direction.x, direction.y, z) * speed
    local position = UT.GameUtility:getPlayerPosition() + delta
    UT.GameUtility:teleportPlayer(position, rotation)
end

function UT:setBunnyhop(enabled, airAccelerate, maxAirSpeed, speedCap)
    UT.Utility:cloneClass(PlayerStandard)

    UT.bunnyhopAirAccelerate = airAccelerate or UT.bunnyhopAirAccelerate or 1000
    UT.bunnyhopMaxAirSpeed = maxAirSpeed or UT.bunnyhopMaxAirSpeed or 100
    UT.bunnyhopSpeedCap = speedCap or UT.bunnyhopSpeedCap or 3500

    local groundSpeedThreshold = 450

    if enabled then
        function PlayerStandard:_get_input(t, dt, ...)
            local input = PlayerStandard.orig._get_input(self, t, dt, ...)
            if self._controller:get_input_bool("jump") then
                input.btn_jump_press = true
            end
            return input
        end

        function PlayerStandard:_get_max_walk_speed(...)
            local is_standing = self._unit:mover() and self._unit:mover():standing()
            if not self._on_ground and not is_standing and self._state_data.in_air then
                local vel_z = self._unit:mover() and self._unit:mover():velocity().z or 0
                if math.abs(vel_z) > 10 then
                    return 10000
                end
            end
            return PlayerStandard.orig._get_max_walk_speed(self, ...)
        end

        function PlayerStandard:_update_movement(t, dt)
            self._last_frame_velocity = self._last_frame_velocity or Vector3()

            local mover = self._unit:mover()
            if not mover then
                return PlayerStandard.orig._update_movement(self, t, dt)
            end

            local is_jumping = self._controller:get_input_bool("jump")

            local is_really_on_ground = self._on_ground
            if not is_really_on_ground then
                local pos = self._unit:position()
                local ray = World:raycast("ray", pos, pos + Vector3(0, 0, -20), "slot_mask", managers.slot:get_mask("world_geometry"))
                if ray then
                    is_really_on_ground = true
                end
            end

            if not is_jumping and is_really_on_ground then
                local res = PlayerStandard.orig._update_movement(self, t, dt)

                local current_vel = mover:velocity()
                local h_vel = Vector3(current_vel.x, current_vel.y, 0)
                local speed = mvector3.length(h_vel)

                if speed > groundSpeedThreshold + 50 then
                    mvector3.normalize(h_vel)
                    mvector3.multiply(h_vel, groundSpeedThreshold)

                    local clamped_vel = Vector3(h_vel.x, h_vel.y, current_vel.z)
                    mover:set_velocity(clamped_vel)
                    self._last_frame_velocity = clamped_vel
                else
                    self._last_frame_velocity = current_vel
                end

                return res
            end

            if self._on_ground then
                local res = PlayerStandard.orig._update_movement(self, t, dt)

                local current_vel = mover:velocity()

                if is_jumping then
                    local saved_h = Vector3(self._last_frame_velocity.x, self._last_frame_velocity.y, 0)
                    local saved_speed = mvector3.length(saved_h)
                    local current_h = Vector3(current_vel.x, current_vel.y, 0)
                    local current_speed = mvector3.length(current_h)

                    if saved_speed > groundSpeedThreshold + 50 and saved_speed > current_speed then
                        local restored = Vector3(self._last_frame_velocity.x, self._last_frame_velocity.y, current_vel.z)
                        mover:set_velocity(restored)
                        self._last_frame_velocity = restored
                    else
                        self._last_frame_velocity = current_vel
                    end
                else
                    self._last_frame_velocity = current_vel
                end

                return res
            end

            PlayerStandard.orig._update_movement(self, t, dt)

            local current_vel = mover:velocity()
            local new_z = current_vel.z

            local velocity = current_vel

            if is_jumping or math.abs(new_z) > 40 then
                velocity = self._last_frame_velocity
                if mvector3.length(velocity) < 50 then
                    velocity = current_vel
                end
            end

            local move_axis = self._controller:get_input_axis("move")
            local cam_rot = self._ext_camera:rotation()
            local forward = cam_rot:y(); mvector3.set_z(forward, 0); mvector3.normalize(forward)
            local right = cam_rot:x(); mvector3.set_z(right, 0); mvector3.normalize(right)

            local wish_dir = Vector3()
            mvector3.add(wish_dir, forward * move_axis.y)
            mvector3.add(wish_dir, right * move_axis.x)
            mvector3.normalize(wish_dir)

            local wish_speed = UT.bunnyhopMaxAirSpeed
            local current_speed_dot = mvector3.dot(velocity, wish_dir)
            local add_speed = wish_speed - current_speed_dot

            if add_speed > 0 then
                local accel_speed = UT.bunnyhopAirAccelerate * dt * wish_speed
                if accel_speed > add_speed then
                    accel_speed = add_speed
                end
                local acc_vel = wish_dir * accel_speed
                mvector3.add(velocity, acc_vel)
            end

            local h_vel = Vector3(velocity.x, velocity.y, 0)
            if mvector3.length(h_vel) > UT.bunnyhopSpeedCap then
                mvector3.normalize(h_vel)
                mvector3.multiply(h_vel, UT.bunnyhopSpeedCap)
                velocity = Vector3(h_vel.x, h_vel.y, velocity.z)
            end

            local final_vel = Vector3(velocity.x, velocity.y, new_z)
            mover:set_velocity(final_vel)
            self._last_frame_velocity = final_vel
        end
    else
        PlayerStandard._get_input = PlayerStandard.orig._get_input
        PlayerStandard._get_max_walk_speed = PlayerStandard.orig._get_max_walk_speed
        PlayerStandard._update_movement = PlayerStandard.orig._update_movement
    end

    UT.bunnyhopEnabled = enabled
end

function UT:setInvisiblePlayer(enabled)
    if not UT.GameUtility:isPlayerUnitAlive() then
        return
    end

    local playerUnitKey = UT.GameUtility:getPlayerUnit():key()
    local groupAIState = managers.groupai:state()

    if enabled then
        UT.backup.playerAttentionObject = groupAIState._attention_objects.all[playerUnitKey]
        groupAIState:unregister_AI_attention_object(playerUnitKey)
    else
        groupAIState._attention_objects.all[playerUnitKey] = UT.backup.playerAttentionObject
        groupAIState:on_AI_attention_changed(playerUnitKey)
    end

    UT.invisiblePlayerEnabled = enabled
end

function UT:setDisableAI(enabled)
    UT.enableDisableAI = enabled
    if not enabled then
        for key, value in pairs(managers.enemy:all_civilians()) do
            value.unit:brain():set_active(true)
        end

        for key, value in pairs(managers.enemy:all_enemies()) do
            value.unit:brain():set_active(true)
        end

        for key, unit in pairs(SecurityCamera.cameras) do
            unit:base()._detection_interval = 0.1
        end

        if managers.groupai:state():turrets() then
            for key, unit in pairs(managers.groupai:state():turrets()) do
                unit:brain():set_active(true)
            end
        end
    end
    UT.disableAIEnabled = enabled
end

function UT:disableAI()
    for key, data in pairs(managers.enemy:all_civilians()) do
        if data.unit:brain():is_active() then
            data.unit:brain():set_active(false)
        end
    end

    for key, data in pairs(managers.enemy:all_enemies()) do
        if data.unit:brain():is_active() then
            data.unit:brain():set_active(false)
        end
    end

    for key, unit in pairs(SecurityCamera.cameras) do
        if unit:base()._detection_interval ~= UT.maxInteger then
            unit:base()._detection_interval = UT.maxInteger
        end
    end

    if managers.groupai:state():turrets() then
        for key, unit in pairs(managers.groupai:state():turrets()) do
            if unit:brain():is_active() then
                unit:brain():set_active(false)
            end
        end
    end
end

function UT:setRemoveTeamAI(enabled)
    if enabled then
        for i = 1, tweak_data.max_players - 1 do
            managers.groupai:state():remove_one_teamAI()
        end
    else
        managers.groupai:state():fill_criminal_team_with_AI()
    end
    UT.removeTeamAIEnabled = enabled
end

function UT:setSuspendPointOfNoReturnTimer(enabled)
    UT.Utility:cloneClass(GroupAIStateBase)
    if enabled then
        function GroupAIStateBase:_update_point_of_no_return() end
    else
        GroupAIStateBase._update_point_of_no_return = GroupAIStateBase.orig._update_point_of_no_return
    end
    UT.suspendPointOfNoReturnTimerEnabled = enabled
end

function UT:setUnlimitedPagers(enabled)
    tweak_data.player.alarm_pager.bluff_success_chance = { 1, 1, 1, 1, enabled and 1 or 0 }
    UT.unlimitedPagersEnabled = enabled
end

function UT:setInstantDrilling(enabled)
    UT.Utility:cloneClass(TimerGui)
    if enabled then
        function TimerGui:_set_jamming_values() end

        function TimerGui:start()
            local timer = 0.01
            self:_start(timer)
            managers.network:session():send_to_peers_synched("start_timer_gui", self._unit, timer)
        end
    else
        TimerGui._set_jamming_values = TimerGui.orig._set_jamming_values
        TimerGui.start = TimerGui.orig.start
    end
    UT.instantDrillingEnabled = enabled
end

function UT:setNoCivilianKillPenalty(enabled)
    UT.Utility:cloneClass(MoneyManager)
    if enabled then
        function MoneyManager:civilian_killed() end
    else
        MoneyManager.civilian_killed = MoneyManager.orig.civilian_killed
    end
    UT.noCivilianKillPenaltyEnabled = enabled
end

function UT:getOutOfCustody()
    IngameWaitingForRespawnState.request_player_spawn()
end

function UT:setPlayerState(state)
    UT.GameUtility:setPlayerState(state)
end

function UT:teleportToPlayer(id)
    local name = managers.criminals:character_name_by_panel_id(id)

    if not name then
        return
    end

    local unit = managers.criminals:character_unit_by_name(name)

    if not unit then
        return
    end

    local position = unit:position()
    local rotation = unit:rotation()
    UT.GameUtility:teleportPlayer(position, rotation)
end

function UT:replenishHealth()
    local playerUnit = UT.GameUtility:getPlayerUnit()
    playerUnit:character_damage():replenish()

    if GameStateFilters.need_revive[UT.GameUtility:getGameState()] then
        UT.GameUtility:setPlayerState("standard")
    end
end

function UT:replenishAmmo()
    local playerUnit = UT.GameUtility:getPlayerUnit()
    for id, weapon in pairs(playerUnit:inventory():available_selections()) do
        if UT.GameUtility:isUnitAlive(weapon.unit) then
            weapon.unit:base():replenish()
            managers.hud:set_ammo_amount(id, weapon.unit:base():ammo_info())
        end
    end
end

function UT:replenishEquipment()
    managers.player._equipment.selections = {}

    local params = {
        slot = 1,
        equipment = managers.player:equipment_in_slot(1)
    }
    managers.player:add_equipment(params)

    if managers.player:has_category_upgrade("player", "second_deployable") then
        local params = {
            slot = 2,
            equipment = managers.player:equipment_in_slot(2)
        }
        managers.player:add_equipment(params)

        managers.player:switch_equipment()
        managers.player:switch_equipment()
    end
end

function UT:replenishCableTies()
    local params = {
        name = "cable_tie",
        amount = UT.maxInteger
    }
    managers.player:add_special(params)
end

function UT:replenishThrowables()
    managers.player:add_grenade_amount(UT.maxInteger, true)
end

function UT:replenishBodyBags()
    managers.player:add_body_bags_amount(UT.maxInteger)
end

function UT:throwBag(bagId)
    if not UT.carryVerifyDisabled then
        UT:disableCarryVerify()
    end

    local carryData = tweak_data.carry[bagId]

    if not carryData then
        return
    end

    local position = UT.GameUtility:getPlayerCameraPosition()
    local rotation = UT.GameUtility:getPlayerCameraRotation()
    local forward = UT.GameUtility:getPlayerCameraForward()
    local throwDistanceMultiplierUpgradeLevel = managers.player:upgrade_level("carry", "throw_distance_multiplier", 0)
    local localPeer = managers.network:session():local_peer()

    managers.player:server_drop_carry(bagId, 1, nil, nil, nil, position, rotation, forward, throwDistanceMultiplierUpgradeLevel, nil, localPeer)
end

function UT:addSpecialEquipment(specialEquipmentId)
    local tweakDataEquipmentsSpecials = UT.Utility:deepClone(tweak_data.equipments.specials)

    for _specialEquipmentId, specialEquipment in pairs(tweak_data.equipments.specials) do
        tweak_data.equipments.specials[_specialEquipmentId].max_quantity = UT.maxInteger
        tweak_data.equipments.specials[_specialEquipmentId].transfer_quantity = UT.maxInteger
    end

    local params = {
        name = specialEquipmentId,
        amount = 1,
        transfer = true,
        silent = true
    }
    managers.player:add_special(params)

    for _specialEquipmentId, specialEquipment in pairs(tweakDataEquipmentsSpecials) do
        tweak_data.equipments.specials[_specialEquipmentId].max_quantity = tweakDataEquipmentsSpecials[_specialEquipmentId].max_quantity
        tweak_data.equipments.specials[_specialEquipmentId].transfer_quantity = tweakDataEquipmentsSpecials[_specialEquipmentId].transfer_quantity
    end
end

function UT:openDoors()
    UT.GameUtility:interactFromTable(UT.interactions["open-doors"])
end

function UT:openWindows()
    UT.GameUtility:interactFromTable(UT.interactions["open-windows"])
end

function UT:openDepositBoxes()
    UT.GameUtility:interactFromTable(UT.interactions["open-deposit-boxes"])
end

function UT:cutFences()
    UT.GameUtility:interactFromTable(UT.interactions["cut-fences"])
end

function UT:openContainers()
    UT.GameUtility:interactFromTable(UT.interactions["open-containers"])
end

function UT:hackComputers()
    UT.GameUtility:interactFromTable(UT.interactions["hack-computers"])
end

function UT:placeDrills()
    UT.GameUtility:interactFromTable(UT.interactions["place-drills"])
end

function UT:pickUpPackages()
    UT.GameUtility:interactFromTable(UT.interactions["pick-up-packages"])
end

function UT:openCrates()
    UT:setUnlimitedEquipment(true)
    UT.GameUtility:interactFromTable(UT.interactions["open-crates"])
    UT:setUnlimitedEquipment(UT:getSetting("enable-unlimited-equipment"))
end

function UT:barricadeWindows()
    UT:setUnlimitedEquipment(true)
    UT.GameUtility:interactFromTable(UT.interactions["barricade-windows"])
    UT:setUnlimitedEquipment(UT:getSetting("enable-unlimited-equipment"))
end

function UT:openAtms()
    UT:setUnlimitedEquipment(true)
    UT.GameUtility:interactFromTable(UT.interactions["open-atms"])
    UT:setUnlimitedEquipment(UT:getSetting("enable-unlimited-equipment"))
end

function UT:useKeycards()
    UT:setUnlimitedEquipment(true)
    UT.GameUtility:interactFromTable(UT.interactions["use-keycards"])
    UT:setUnlimitedEquipment(UT:getSetting("enable-unlimited-equipment"))
end

function UT:placeShapedCharges()
    UT:setUnlimitedEquipment(true)
    UT.GameUtility:interactFromTable(UT.interactions["place-shaped-charges"])
    UT:setUnlimitedEquipment(UT:getSetting("enable-unlimited-equipment"))
end

function UT:setSlowMotion(enabled, worldSpeed, playerSpeed)
    managers.time_speed:destroy()

    if enabled then
        if worldSpeed < 1 then
            local effect = {
                fade_in = 0,
                fade_in_delay = 0,
                fade_out = 0,
                speed = worldSpeed,
                sustain = UT.maxInteger,
                timer = "pausable"
            }
            managers.time_speed:play_effect("ut_world_slow_motion", effect)
        end

        if playerSpeed < 1 then
            local effect = {
                fade_in = 0,
                fade_in_delay = 0,
                fade_out = 0,
                speed = playerSpeed,
                sustain = UT.maxInteger,
                timer = "pausable",
                affect_timer = "player"
            }
            managers.time_speed:play_effect("ut_player_slow_motion", effect)
        end
    end
end

-- Driving

function UT:spawnAndDriveVehicle(vehicleId)
    local unitId = UT.vehicles[vehicleId]

    if not unitId then
        return
    end

    local idString = UT.GameUtility:idString(unitId)

    if not UT.GameUtility:isUnitLoaded(idString) then
        return
    end

    if UT.GameUtility:isDriving() then
        UT.GameUtility:setPlayerState("standard")
    end

    if UT.Utility:isEmptyTable(UT.spawnedVehicleUnits) then
        UT.Utility:cloneClass(BaseNetworkSession)
        function BaseNetworkSession:send_to_peers_synched(name, ...)
            if UT.Utility:inTable(name, {
                    "sync_vehicle_driving",
                    "sync_vehicle_set_input",
                    "sync_vehicle_state",
                    "sync_vehicle_player",
                    "sync_ai_vehicle_action",
                    "sync_vehicle_change_stance",
                    "sync_store_loot_in_vehicle",
                    "sync_give_vehicle_loot_to_player",
                    "sync_vehicle_interact_trunk"
                }) then
                return
            end

            self.orig.send_to_peers_synched(self, name, ...)
        end
    end

    local position = UT.GameUtility:getPlayerPosition()
    local rotation = UT.GameUtility:getPlayerCameraYawRotation()
    local vehicleUnit = UT.GameUtility:spawnUnit(idString, position, rotation)

    if not vehicleUnit then
        return
    end

    local localPeerId = UT.GameUtility:getLocalPeerId()
    local playerUnit = UT.GameUtility:getPlayerUnit()

    managers.player:server_enter_vehicle(vehicleUnit, localPeerId, playerUnit, "driver")

    UT.Utility:tableInsert(UT.spawnedVehicleUnits, vehicleUnit)
end

function UT:removeSpawnedVehicles()
    if UT.GameUtility:isDriving() then
        UT.GameUtility:setPlayerState("standard")
    end

    if not UT.Utility:isEmptyTable(UT.spawnedVehicleUnits) then
        BaseNetworkSession.send_to_peers_synched = BaseNetworkSession.orig.send_to_peers_synched
    end

    for index, unit in pairs(UT.spawnedVehicleUnits) do
        UT.GameUtility:deleteUnit(unit)
    end

    UT.spawnedVehicleUnits = {}
end

function UT:teleportToCrosshair()
    if UT.GameUtility:isDriving() then
        return
    end

    if UT.GameUtility:isPlayerUsingZipline() then
        return
    end

    local crosshairRay = UT.GameUtility:getCrosshairRay()

    if not crosshairRay then
        return
    end

    local offset = Vector3()
    mvector3.set(offset, UT.GameUtility:getPlayerCameraForward())
    mvector3.multiply(offset, 150)
    mvector3.add(crosshairRay.hit_position, offset)

    UT.GameUtility:teleportPlayer(crosshairRay.hit_position, UT.GameUtility:getPlayerCameraRotation())
end
