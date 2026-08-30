UTMenu = {}

UTMenu.isOpen = false

UTMenu.width = 700
UTMenu.height = 450
UTMenu.sidebarWidth = 150
UTMenu.layer = 10000

UTMenu.tabRowHeight = 40
UTMenu.tabRowStartY = 20
UTMenu.tabMarkerWidth = 2
UTMenu.tabTextOffsetX = 15

UTMenu.footerHeight = 48
UTMenu.avatarSize = 32

UTMenu.subTabPillY = 20
UTMenu.subTabPillHeight = 28
UTMenu.subTabPillGap = 8
UTMenu.subTabUnderlineHeight = 2

UTMenu.contentStartY = 60

UTMenu.toggleWidth = 36
UTMenu.toggleHeight = 18
UTMenu.toggleKnobSize = 14

UTMenu.cardHeight = 30
UTMenu.hotkeyContextRowHeight = 40
UTMenu.cardMargin = 24
UTMenu.cardGap = 12
UTMenu.gearSize = 20

UTMenu.sliderRowHeight = 50
UTMenu.sliderTrackHeight = 4
UTMenu.numberInputRowHeight = 56

UTMenu.popoverWidth = 300
UTMenu.popoverLayer = 50

UTMenu.tabs = { "Player", "Stealth", "Sandbox", "Progress" }
UTMenu.subTabsByTab = {
    Player = { "Movement", "Gunplay", "Survivability", "Stats", "Stats II" },
    Stealth = { "Vision & Stealth", "World Triggers", "AI & Time" },
    Sandbox = { "Entities", "Loot & Bags", "Items", "Weather" },
    Progress = { "Character", "Wallet", "Unlocks" }
}
UTMenu.activeTab = UTMenu.tabs[1]
UTMenu.activeSubTab = UTMenu.subTabsByTab[UTMenu.tabs[1]][1]

UTMenu._mouseId = "ut_menu_mouse"
UTMenu._insertKeyWasDown = false
UTMenu._deleteKeyWasDown = false
UTMenu._tabRows = {}
UTMenu._subTabPills = {}
UTMenu._featureToggles = {}
UTMenu._sliders = {}
UTMenu._actionButtons = {}
UTMenu._numberInputs = {}
UTMenu._numberInputRows = {}
UTMenu._entitiesPositionPills = {}
UTMenu._entitiesPositionType = "on-crosshair"
UTMenu._entitiesConverted = false
UTMenu._draggingSlider = nil
UTMenu._focusedNumberInput = nil
UTMenu._activePopover = nil
UTMenu._activePopoverWidth = nil
UTMenu._popoverSliders = {}
UTMenu._popoverToggles = {}
UTMenu._popoverButtons = {}
UTMenu._popoverHotkeyRows = {}
UTMenu.settingsPopoverHeight = 44
UTMenu.colorPopoverWidth = 300
UTMenu.colorPopoverHeight = 140

UTMenu._capturingKeybind = false
UTMenu._capturingKeybindArmed = false
UTMenu._boundWidgets = {}
UTMenu._activePopoverOrigin = nil
UTMenu._popoverIsKeybindManager = false
UTMenu._keybindEditor = nil
UTMenu._keybindKeysDown = {}
UTMenu._tooltipPanel = nil
UTMenu.keybindPopoverWidth = 260
UTMenu.hotkeysPopoverWidth = 340

UTMenu._textureIds = {}
UTMenu._customTexturesRegistered = false
UTMenu._textureContentRects = {
    toggle_bg = { 16, 8, 96, 48 },
    glow_circle = { 16, 16, 96, 96 }
}

UTMenu.cardBgTextureSize = 32
UTMenu.cardCornerRadius = 10
UTMenu.frameCornerRadius = 20
UTMenu.popoverCornerRadius = 12

function UTMenu:_registerTexture(relativePath)
    if not DB or not DB.create_entry then
        return nil
    end

    local fullPath = UT.modPath .. "/" .. relativePath
    local ok, exists = pcall(function() return file.FileExists(Application:nice_path(fullPath)) end)
    if not ok or not exists then
        return nil
    end

    local textureId = Idstring(fullPath)
    local registered = pcall(function() DB:create_entry(Idstring("texture"), textureId, fullPath) end)
    if not registered then
        return nil
    end

    return textureId
end

function UTMenu:_getTexture(name)
    return self._textureIds[name]
end

function UTMenu:_getTextureRect(name)
    return self._textureContentRects[name]
end

function UTMenu:_registerCustomTextures()
    if self._customTexturesRegistered then
        return
    end
    self._customTexturesRegistered = true

    self._textureIds.toggle_bg = self:_registerTexture("assets/images/ui/toggle_bg.texture")
    self._textureIds.glow_circle = self:_registerTexture("assets/images/ui/glow_circle.texture")
    self._textureIds.card_bg = self:_registerTexture("assets/images/ui/card_bg.texture")
    self._textureIds.settings_icon = self:_registerTexture("assets/images/ui/settings.texture")
end

function UTMenu:draw_rounded_bg(panel, width, height, color, namePrefix, radius)
    local texture = self:_getTexture("card_bg")
    if not texture then
        return nil
    end

    local srcR = self.cardCornerRadius
    radius = math.floor(radius or srcR)
    width = math.floor(width)
    height = math.floor(height)
    if width < radius * 2 or height < radius * 2 then
        return nil
    end

    local t = self.cardBgTextureSize
    namePrefix = namePrefix or "bg"

    local function segment(name, tx, ty, tw, th, x, y, w, h)
        x, y = math.floor(x), math.floor(y)
        w, h = math.ceil(w), math.ceil(h)
        local bmp = panel:bitmap({
            name = namePrefix .. "_" .. name,
            texture = texture,
            texture_rect = { tx, ty, tw, th },
            color = color,
            layer = 0,
            w = w,
            h = h
        })
        bmp:set_shape(x, y, w, h)
        return bmp
    end

    local pieces = {}
    pieces.topLeft = segment("tl", 0, 0, srcR, srcR, 0, 0, radius, radius)
    pieces.topRight = segment("tr", t - srcR, 0, srcR, srcR, width - radius, 0, radius, radius)
    pieces.bottomLeft = segment("bl", 0, t - srcR, srcR, srcR, 0, height - radius, radius, radius)
    pieces.bottomRight = segment("br", t - srcR, t - srcR, srcR, srcR, width - radius, height - radius, radius, radius)
    pieces.top = segment("top", srcR, 0, t - srcR * 2, srcR, radius, 0, width - radius * 2, radius)
    pieces.bottom = segment("bottom", srcR, t - srcR, t - srcR * 2, srcR, radius, height - radius, width - radius * 2, radius)
    pieces.left = segment("left", 0, srcR, srcR, t - srcR * 2, 0, radius, radius, height - radius * 2)
    pieces.right = segment("right", t - srcR, srcR, srcR, t - srcR * 2, width - radius, radius, radius, height - radius * 2)

    local center = panel:rect({ name = namePrefix .. "_center", color = color, layer = 0 })
    center:set_shape(radius, radius, math.ceil(width - radius * 2), math.ceil(height - radius * 2))
    pieces.center = center

    return pieces
end

function UTMenu:draw_gear_icon(parent, size, color)
    local texture = self:_getTexture("settings_icon")
    if texture then
        local icon = parent:bitmap({
            name = "icon",
            texture = texture,
            color = color,
            layer = 1,
            w = size,
            h = size
        })
        icon:set_shape(0, 0, size, size)
        return icon
    end

    local icon = parent:text({
        name = "icon",
        layer = 1,
        font = tweak_data.menu.pd2_small_font,
        font_size = tweak_data.menu.pd2_small_font_size,
        text = "[...]",
        color = color,
        align = "center",
        vertical = "center"
    })
    icon:set_shape(0, 0, size, size)
    return icon
end

function UTMenu:draw_border(panel, color, thickness)
    thickness = thickness or 1
    local w, h = panel:w(), panel:h()

    local top = panel:rect({ name = "border_top", color = color })
    top:set_shape(0, 0, w, thickness)

    local bottom = panel:rect({ name = "border_bottom", color = color })
    bottom:set_shape(0, h - thickness, w, thickness)

    local left = panel:rect({ name = "border_left", color = color })
    left:set_shape(0, 0, thickness, h)

    local right = panel:rect({ name = "border_right", color = color })
    right:set_shape(w - thickness, 0, thickness, h)

    return { top = top, bottom = bottom, left = left, right = right }
end

function UTMenu:_repositionFrame()
    if not alive(self._mainFrame) or not alive(self._rootPanel) then
        return
    end
    local frameX = math.max(0, (self._rootPanel:w() - self.width) / 2)
    local frameY = math.max(0, (self._rootPanel:h() - self.height) / 2)
    self._mainFrame:set_left(frameX)
    self._mainFrame:set_top(frameY)
end

function UTMenu:_build()
    if self._mainFrame or not managers.gui_data then
        return
    end

    self:_registerCustomTextures()

    self._workspace = managers.gui_data:create_fullscreen_workspace()
    self._workspace:connect_keyboard(Input:keyboard())

    self._rootPanel = self._workspace:panel()

    self._mainFrame = self._rootPanel:panel({
        name = "ut_menu_main_frame",
        layer = self.layer,
        visible = false
    })
    self._mainFrame:set_shape(0, 0, self.width, self.height)
    self:_repositionFrame()
    self._mainFrame:key_press(callback(self, self, "_onKeyPress"))

    if not self:draw_rounded_bg(self._mainFrame, self.width, self.height, UTTheme.Background, "background", self.frameCornerRadius) then
        local background = self._mainFrame:rect({
            name = "background",
            color = UTTheme.Background
        })
        background:set_shape(0, 0, self.width, self.height)
        self:draw_border(self._mainFrame, UTTheme.Border)
    end

    self._sidebar = self._mainFrame:panel({ name = "sidebar" })
    self._sidebar:set_shape(0, 0, self.sidebarWidth, self.height)

    self._contentPanel = self._mainFrame:panel({ name = "content" })
    self._contentPanel:set_shape(self.sidebarWidth, 0, self.width - self.sidebarWidth, self.height)

    self:_buildSidebarTabs()
    self:_buildSidebarFooter()
    self:_rebuildSubTabPills()
    self:_buildContent()
end

function UTMenu:_buildSidebarTabs()
    for index, tabName in ipairs(self.tabs) do
        local row = self._sidebar:panel({ name = "tab_row_" .. index })
        row:set_shape(0, self.tabRowStartY + (index - 1) * self.tabRowHeight, self.sidebarWidth, self.tabRowHeight)

        local hover = row:rect({
            name = "hover",
            color = UTTheme.Hover,
            visible = false
        })
        hover:set_shape(0, 0, self.sidebarWidth, self.tabRowHeight)

        local marker = row:rect({
            name = "marker",
            color = UTTheme.Accent,
            visible = false
        })
        marker:set_shape(self.sidebarWidth - self.tabMarkerWidth, 0, self.tabMarkerWidth, self.tabRowHeight)

        local text = row:text({
            name = "label",
            layer = 1,
            font = tweak_data.menu.pd2_medium_font,
            font_size = tweak_data.menu.pd2_medium_font_size,
            text = tabName,
            color = UTTheme.TextSecondary,
            vertical = "center"
        })
        text:set_shape(self.tabTextOffsetX, 0, self.sidebarWidth - self.tabTextOffsetX, self.tabRowHeight)

        self._tabRows[index] = {
            name = tabName,
            panel = row,
            hover = hover,
            marker = marker,
            text = text
        }
    end

    self:_refreshTabStyles()
end

function UTMenu:_buildSidebarFooter()
    local footer = self._sidebar:panel({ name = "footer" })
    footer:set_shape(0, self.height - self.footerHeight, self.sidebarWidth, self.footerHeight)

    local avatarY = (self.footerHeight - self.avatarSize) / 2

    local avatarBackground = footer:rect({ name = "avatar_background", color = UTTheme.Background })
    avatarBackground:set_shape(8, avatarY, self.avatarSize, self.avatarSize)

    self._avatarSlot = footer

    if Distribution then
        pcall(function()
            Distribution:request_user_profile_picture(Distribution.ProfilePictureSize_Large, Distribution:local_user_id(), function(texture)
                if texture and alive(UTMenu._avatarSlot) then
                    local bitmap = UTMenu._avatarSlot:bitmap({ name = "avatar", texture = texture, layer = 1, w = UTMenu.avatarSize, h = UTMenu.avatarSize })
                    bitmap:set_shape(8, avatarY, UTMenu.avatarSize, UTMenu.avatarSize)
                end
            end)
        end)
    end

    local username = "joke161"
    if Steam then
        local ok, result = pcall(function() return Steam:username() end)
        if ok and result and result ~= "" then
            username = result
        end
    end

    local textX = 8 + self.avatarSize + 8
    local textWidth = self.sidebarWidth - textX - self.gearSize - 8

    local usernameText = footer:text({
        name = "username",
        layer = 1,
        font = tweak_data.menu.pd2_medium_font,
        font_size = tweak_data.menu.pd2_medium_font_size,
        text = username,
        color = UTTheme.TextPrimary,
        vertical = "center"
    })
    usernameText:set_shape(textX, 4, textWidth, 18)

    local rankText = footer:text({
        name = "rank",
        layer = 1,
        font = tweak_data.menu.pd2_small_font,
        font_size = tweak_data.menu.pd2_small_font_size,
        text = "Infamy V",
        color = UTTheme.TextSecondary,
        vertical = "center"
    })
    rankText:set_shape(textX, 24, textWidth, 18)

    local settingsGear = footer:panel({ name = "settings_gear" })
    settingsGear:set_shape(self.sidebarWidth - self.gearSize - 8, (self.footerHeight - self.gearSize) / 2, self.gearSize, self.gearSize)

    local gearBackground = settingsGear:rect({ name = "background", color = UTTheme.Background })
    gearBackground:set_shape(0, 0, self.gearSize, self.gearSize)

    self:draw_gear_icon(settingsGear, self.gearSize, UTTheme.TextSecondary)

    self._settingsGear = settingsGear
end

function UTMenu:_rebuildSubTabPills()
    if self._subTabPillsPanel then
        self._contentPanel:remove(self._subTabPillsPanel)
    end

    local contentWidth = self.width - self.sidebarWidth
    local subTabs = self.subTabsByTab[self.activeTab]

    local pillsPanel = self._contentPanel:panel({ name = "sub_tab_pills" })
    pillsPanel:set_shape(self.cardMargin, self.subTabPillY, contentWidth - self.cardMargin * 2, self.subTabPillHeight)

    self:draw_border(pillsPanel, UTTheme.Border)

    self._subTabPills = {}

    local pillWidth = (pillsPanel:w() - self.subTabPillGap * (#subTabs - 1)) / #subTabs

    for index, subTabName in ipairs(subTabs) do
        local pill = pillsPanel:panel({ name = "pill_" .. index })
        pill:set_shape((index - 1) * (pillWidth + self.subTabPillGap), 0, pillWidth, self.subTabPillHeight)

        local pillBackground = pill:rect({ name = "background", color = UTTheme.Panel })
        pillBackground:set_shape(0, 0, pillWidth, self.subTabPillHeight)

        local pillHover = pill:rect({ name = "hover", color = UTTheme.Hover, visible = false })
        pillHover:set_shape(0, 0, pillWidth, self.subTabPillHeight)

        local isActive = subTabName == self.activeSubTab

        local pillText = pill:text({
            name = "label",
            layer = 1,
            font = tweak_data.menu.pd2_medium_font,
            font_size = tweak_data.menu.pd2_medium_font_size,
            text = subTabName,
            color = isActive and UTTheme.Accent or UTTheme.TextSecondary,
            align = "center",
            vertical = "center"
        })
        pillText:set_shape(0, 0, pillWidth, self.subTabPillHeight)

        local underline = pill:rect({ name = "underline", color = UTTheme.Accent, visible = isActive })
        underline:set_shape(0, self.subTabPillHeight - self.subTabUnderlineHeight, pillWidth, self.subTabUnderlineHeight)

        self._subTabPills[index] = { name = subTabName, panel = pill, hover = pillHover, text = pillText, underline = underline }
    end

    self._subTabPillsPanel = pillsPanel
end

function UTMenu:setActiveSubTab(subTabName)
    if subTabName == self.activeSubTab then
        return
    end

    self.activeSubTab = subTabName

    for _, pill in ipairs(self._subTabPills) do
        local isActive = pill.name == self.activeSubTab
        pill.text:set_color(isActive and UTTheme.Accent or UTTheme.TextSecondary)
        pill.underline:set_visible(isActive)
    end

    self:_refreshContentVisibility()
end

function UTMenu:_gridPosition(index, colWidth, columns)
    columns = columns or 2
    local col = (index - 1) % columns
    local row = math.floor((index - 1) / columns)
    local x = self.cardMargin + col * (colWidth + self.cardGap)
    local y = self.contentStartY + row * (self.cardHeight + self.cardGap)
    return x, y
end

function UTMenu:_slugify(value)
    local slug = string.lower(tostring(value))
    slug = string.gsub(slug, "[^%w]+", "-")
    slug = string.gsub(slug, "^%-+", "")
    slug = string.gsub(slug, "%-+$", "")
    return slug
end

function UTMenu:_addToggleGrid(tab, subTab, colWidth, defs, startIndex, columns)
    startIndex = startIndex or 1
    for i, def in ipairs(defs) do
        local index = startIndex + i - 1
        local x, y = self:_gridPosition(index, colWidth, columns)
        local id = def.id or self:_slugify(tab .. "-" .. subTab .. "-" .. def.title)
        local toggle = self:create_feature_toggle(self._contentPanel, x, y, colWidth, def.title, def.initial, def.hasSettings or false, def.onToggle, def.buildPopoverContent, id)
        toggle.tab = tab
        toggle.subTab = subTab
        if def.popoverHeight then
            toggle.popoverHeight = def.popoverHeight
        end
        if def.popoverWidth then
            toggle.popoverWidth = def.popoverWidth
        end
        table.insert(self._featureToggles, toggle)
    end
    return startIndex + #defs
end

function UTMenu:_addActionButtonGrid(tab, subTab, colWidth, defs, startIndex, columns)
    startIndex = startIndex or 1
    for i, def in ipairs(defs) do
        local index = startIndex + i - 1
        local x, y = self:_gridPosition(index, colWidth, columns)
        local id = def.id or self:_slugify(tab .. "-" .. subTab .. "-" .. def.title)
        local btn = self:create_action_button(self._contentPanel, x, y, colWidth, def.title, def.onClick, def.activeTitle, nil, id)
        btn.tab = tab
        btn.subTab = subTab
        table.insert(self._actionButtons, btn)
    end
    return startIndex + #defs
end

function UTMenu:_buildContent()
    local contentWidth = self.width - self.sidebarWidth
    local colWidth = (contentWidth - self.cardMargin * 2 - self.cardGap) / 2

    local movementNextIndex = self:_addToggleGrid("Player", "Movement", colWidth, {
        {
            id = "player-movement-bhop",
            title = "Bhop Engine",
            initial = UT.bunnyhopEnabled,
            hasSettings = true,
            onToggle = function(state)
                UT.bunnyhopEnabled = state
                UTMenu:_applyBunnyhopConfig()
            end,
            buildPopoverContent = function(popoverPanel, popoverWidth)
                UTMenu:_buildBunnyhopPopoverContent(popoverPanel, popoverWidth)
            end,
            popoverHeight = 12 + 3 * self.sliderRowHeight
        },
        {
            id = "player-movement-noclip",
            title = "No Clip",
            initial = UT.noClipEnabled,
            hasSettings = true,
            onToggle = function(state)
                UT:setNoClip(state, UT.noClipSpeed or 10)
            end,
            buildPopoverContent = function(popoverPanel, popoverWidth)
                UTMenu:_buildNoClipPopoverContent(popoverPanel, popoverWidth)
            end,
            popoverHeight = 12 + 1 * self.sliderRowHeight
        },
        { id = "player-movement-infinite-stamina", title = "Infinite Stamina", initial = UT:getSetting("enable-infinite-stamina"), onToggle = function(state) UT:setInfiniteStamina(state) UT:setSetting("enable-infinite-stamina", state) end },
        { id = "player-movement-directional-run", title = "Directional Run", initial = UT:getSetting("enable-can-run-directional"), onToggle = function(state) UT:setCanRunDirectional(state) UT:setSetting("enable-can-run-directional", state) end },
        { id = "player-movement-run-any-bag", title = "Run with Any Bag", initial = UT:getSetting("enable-can-run-with-any-bag"), onToggle = function(state) UT:setCanRunWithAnyBag(state) UT:setSetting("enable-can-run-with-any-bag", state) end },
        { id = "player-movement-no-carry-cooldown", title = "No Carry Cooldown", initial = UT:getSetting("enable-no-carry-cooldown"), onToggle = function(state) UT:setNoCarryCooldown(state) UT:setSetting("enable-no-carry-cooldown", state) end },
        {
            id = "player-movement-carry-stacker",
            title = "Carry Stacker",
            initial = UT.CarryStacker.enabled,
            onToggle = function(state)
                if state then
                    UT.CarryStacker:enable()
                else
                    UT.CarryStacker:disable()
                end
            end
        }
    })

    self:_addActionButtonGrid("Player", "Movement", colWidth, {
        { id = "player-movement-teleport-crosshair", title = "Teleport to Crosshair", onClick = function() UT:teleportToCrosshair() end },
        { id = "player-movement-teleport-ally-1", title = "Teleport to Ally 1", onClick = function() UT:teleportToPlayer(1) end },
        { id = "player-movement-teleport-ally-2", title = "Teleport to Ally 2", onClick = function() UT:teleportToPlayer(2) end },
        { id = "player-movement-teleport-ally-3", title = "Teleport to Ally 3", onClick = function() UT:teleportToPlayer(3) end }
    }, movementNextIndex)

    self:_addToggleGrid("Player", "Gunplay", colWidth, {
        { id = "player-gunplay-no-spread", title = "No Weapon Spread", initial = UT:getSetting("enable-no-weapon-spread"), onToggle = function(state) UT:setNoWeaponSpread(state) UT:setSetting("enable-no-weapon-spread", state) end },
        { id = "player-gunplay-no-recoil", title = "No Recoil", initial = UT:getSetting("enable-no-weapon-recoil"), onToggle = function(state) UT:setNoWeaponRecoil(state) UT:setSetting("enable-no-weapon-recoil", state) end },
        { id = "player-gunplay-instant-reload", title = "Instant Reload", initial = UT:getSetting("enable-instant-weapon-reload"), onToggle = function(state) UT:setInstantWeaponReload(state) UT:setSetting("enable-instant-weapon-reload", state) end },
        { id = "player-gunplay-shoot-through-walls", title = "Shoot Through Walls", initial = UT:getSetting("enable-shoot-through-walls"), onToggle = function(state) UT:setShootThroughWalls(state) UT:setSetting("enable-shoot-through-walls", state) end },
        { id = "player-gunplay-unlimited-ammo", title = "Unlimited Ammo", initial = UT:getSetting("enable-unlimited-ammo"), onToggle = function(state) UT:setUnlimitedAmmo(state) UT:setSetting("enable-unlimited-ammo", state) end },
        { id = "player-gunplay-unlimited-equipment", title = "Unlimited Equipment", initial = UT:getSetting("enable-unlimited-equipment"), onToggle = function(state) UT:setUnlimitedEquipment(state) UT:setSetting("enable-unlimited-equipment", state) end },
        { id = "player-gunplay-instant-weapon-swap", title = "Instant Weapon Swap", initial = UT:getSetting("enable-instant-weapon-swap"), onToggle = function(state) UT:setInstantWeaponSwap(state) UT:setSetting("enable-instant-weapon-swap", state) end },
        { id = "player-gunplay-instant-mask-on", title = "Instant Mask On", initial = UT:getSetting("enable-instant-mask-on"), onToggle = function(state) UT:setInstantMaskOn(state) UT:setSetting("enable-instant-mask-on", state) end }
    })

    local survivabilityNextIndex = self:_addToggleGrid("Player", "Survivability", colWidth, {
        { id = "player-survivability-god-mode", title = "God Mode", initial = UT:getSetting("enable-god-mode"), onToggle = function(state) UT:setGodMode(state) UT:setSetting("enable-god-mode", state) end },
        { id = "player-survivability-no-fall-damage", title = "No Fall Damage", initial = UT:getSetting("enable-no-fall-damage"), onToggle = function(state) UT:setNoFallDamage(state) UT:setSetting("enable-no-fall-damage", state) end },
        { id = "player-survivability-no-flashbangs", title = "No Flashbangs", initial = UT:getSetting("enable-no-flashbangs"), onToggle = function(state) UT:setNoFlashbangs(state) UT:setSetting("enable-no-flashbangs", state) end },
        { id = "player-survivability-no-melee-damage", title = "No Melee Damage", initial = UT.noMeleeDamageEnabled, onToggle = function(state) UT:setNoMeleeDamage(state) end }
    })

    self:_addActionButtonGrid("Player", "Survivability", colWidth, {
        { id = "player-survivability-get-out-of-custody", title = "Get Out of Custody", onClick = function() UT:getOutOfCustody() end },
        { id = "player-survivability-replenish-health", title = "Replenish Health", onClick = function() UT:replenishHealth() end },
        { id = "player-survivability-replenish-ammo", title = "Replenish Ammo", onClick = function() UT:replenishAmmo() end },
        { id = "player-survivability-replenish-equipment", title = "Replenish Equipment", onClick = function() UT:replenishEquipment() end },
        { id = "player-survivability-replenish-cable-ties", title = "Replenish Cable Ties", onClick = function() UT:replenishCableTies() end },
        { id = "player-survivability-replenish-throwables", title = "Replenish Throwables", onClick = function() UT:replenishThrowables() end },
        { id = "player-survivability-replenish-body-bags", title = "Replenish Body Bags", onClick = function() UT:replenishBodyBags() end }
    }, survivabilityNextIndex)

    local visionNextIndex = self:_addToggleGrid("Stealth", "Vision & Stealth", colWidth, {
        {
            title = "Tactical X-Ray",
            initial = UT.xRayEnabled,
            hasSettings = true,
            onToggle = function(state)
                UT:setXRay(state)
            end,
            buildPopoverContent = function(popoverPanel, popoverWidth)
                UTMenu:_buildXRayColorPopoverContent(popoverPanel, popoverWidth)
            end,
            popoverHeight = self.colorPopoverHeight,
            popoverWidth = self.colorPopoverWidth
        },
        { title = "Invisible Player", initial = UT.invisiblePlayerEnabled, onToggle = function(state) UT:setInvisiblePlayer(state) end }
    })

    self:_addActionButtonGrid("Stealth", "Vision & Stealth", colWidth, {
        { title = "Disguise: Civilian", onClick = function() UT:setPlayerState("civilian") end },
        { title = "Disguise: Mask Off", onClick = function() UT:setPlayerState("mask_off") end },
        { title = "Disguise: Standard", onClick = function() UT:setPlayerState("standard") end }
    }, visionNextIndex)

    local worldTriggersColumns = 3
    local worldTriggersColWidth = (contentWidth - self.cardMargin * 2 - self.cardGap * (worldTriggersColumns - 1)) / worldTriggersColumns

    local worldTriggersNextIndex = self:_addToggleGrid("Stealth", "World Triggers", worldTriggersColWidth, {
        { title = "Instant Interaction", initial = UT:getSetting("enable-instant-interaction"), onToggle = function(state) UT:setInstantInteraction(state) UT:setSetting("enable-instant-interaction", state) end },
        { title = "Instant Deployment", initial = UT:getSetting("enable-instant-deployment"), onToggle = function(state) UT:setInstantDeployment(state) UT:setSetting("enable-instant-deployment", state) end },
        { title = "Instant Drilling", initial = UT.instantDrillingEnabled, onToggle = function(state) UT:setInstantDrilling(state) end }
    }, 1, worldTriggersColumns)

    self:_addActionButtonGrid("Stealth", "World Triggers", worldTriggersColWidth, {
        { title = "Open Doors", onClick = function() UT:openDoors() end },
        { title = "Open Windows", onClick = function() UT:openWindows() end },
        { title = "Open Deposit Boxes", onClick = function() UT:openDepositBoxes() end },
        { title = "Cut Fences", onClick = function() UT:cutFences() end },
        { title = "Open Containers", onClick = function() UT:openContainers() end },
        { title = "Hack Computers", onClick = function() UT:hackComputers() end },
        { title = "Place Drills", onClick = function() UT:placeDrills() end },
        { title = "Pick Up Packages", onClick = function() UT:pickUpPackages() end },
        { title = "Open Crates", onClick = function() UT:openCrates() end },
        { title = "Barricade Windows", onClick = function() UT:barricadeWindows() end },
        { title = "Use Keycards", onClick = function() UT:useKeycards() end },
        { title = "Open ATMs", onClick = function() UT:openAtms() end },
        { title = "Place Shaped Charges", onClick = function() UT:placeShapedCharges() end },
        { title = "Access Cameras", onClick = function() UT:accessCameras() end }
    }, worldTriggersNextIndex, worldTriggersColumns)

    self:_buildAiAndTimeContent(contentWidth)

    self:_buildEntitiesContent(contentWidth)

    self:_addActionButtonGrid("Sandbox", "Loot & Bags", colWidth, {
        { title = "Money", onClick = function() UT:throwBag("money") end },
        { title = "Gold", onClick = function() UT:throwBag("gold") end },
        { title = "Meth", onClick = function() UT:throwBag("meth") end },
        { title = "Lost Artifact", onClick = function() UT:throwBag("lost_artifact") end },
        { title = "Artifact Statue", onClick = function() UT:throwBag("artifact_statue") end },
        { title = "Chas Artifact", onClick = function() UT:throwBag("chas_artifact") end },
        { title = "Mus Artifact", onClick = function() UT:throwBag("mus_artifact") end }
    })

    self:_addActionButtonGrid("Sandbox", "Items", colWidth, {
        { title = "Keycard", onClick = function() UT:addSpecialEquipment("help_keycard") end },
        { title = "Crowbar", onClick = function() UT:addSpecialEquipment("crowbar") end },
        { title = "Planks", onClick = function() UT:addSpecialEquipment("planks") end },
        { title = "Acid", onClick = function() UT:addSpecialEquipment("acid") end }
    })

    self:_addActionButtonGrid("Sandbox", "Weather", colWidth, {
        { title = "Default", onClick = function() UT:setInitialEnvironment() end },
        { title = "Early Morning", onClick = function() UT:setEnvironment("environments/pd2_env_hox_02/pd2_env_hox_02") end },
        { title = "Morning", onClick = function() UT:setEnvironment("environments/pd2_env_morning_02/pd2_env_morning_02") end },
        { title = "Mid Day", onClick = function() UT:setEnvironment("environments/pd2_env_mid_day/pd2_env_mid_day") end },
        { title = "Afternoon", onClick = function() UT:setEnvironment("environments/pd2_env_afternoon/pd2_env_afternoon") end },
        { title = "Bright Day", onClick = function() UT:setEnvironment("environments/pd2_env_jry_plane/pd2_env_jry_plane") end },
        { title = "Cloudy Day", onClick = function() UT:setEnvironment("environments/pd2_env_docks/pd2_env_docks") end },
        { title = "Night", onClick = function() UT:setEnvironment("environments/pd2_env_n2/pd2_env_n2") end },
        { title = "Misty Night", onClick = function() UT:setEnvironment("environments/pd2_env_arm_hcm_02/pd2_env_arm_hcm_02") end },
        { title = "Foggy Night", onClick = function() UT:setEnvironment("environments/pd2_env_foggy_bright/pd2_env_foggy_bright") end }
    })

    self:_addNumberInputRow("Progress", "Character", 1, "Level (1-100)", 1, 100, managers.experience and managers.experience:current_level() or 1, "Apply", function(value)
        UT:setLevel(value)
        UTMenu:_refreshProgress()
    end)
    self:_addNumberInputRow("Progress", "Character", 2, "Infamy Rank (0-500)", 0, 500, managers.experience and managers.experience:current_rank() or 0, "Apply", function(value)
        UT:setInfamyRank(value)
        UTMenu:_refreshProgress()
    end)
    self:_addNumberInputRow("Progress", "Character", 3, "Perk Points to Add", 0, 50, 0, "Add", function(value)
        UT:addPerkPoints(value)
        UTMenu:_refreshProgress()
    end)

    local resetPerkDecksBtn = self:create_action_button(self._contentPanel, self.cardMargin, self.contentStartY + 3 * self.numberInputRowHeight, contentWidth - self.cardMargin * 2, "Reset Perk Decks", function()
        UT:resetPerkDecks()
        UTMenu:_refreshProgress()
    end, nil, nil, "progress-character-reset-perk-decks")
    resetPerkDecksBtn.tab = "Progress"
    resetPerkDecksBtn.subTab = "Character"
    table.insert(self._actionButtons, resetPerkDecksBtn)

    self:_addNumberInputRow("Progress", "Wallet", 1, "Cash Amount", 0, 999999999, 0, "Add", function(value)
        UT:addSpendingMoney(value)
        UTMenu:_refreshProgress()
    end)
    self:_addNumberInputRow("Progress", "Wallet", 2, "Offshore Amount", 0, 999999999, 0, "Add", function(value)
        UT:addOffshoreMoney(value)
        UTMenu:_refreshProgress()
    end)
    self:_addNumberInputRow("Progress", "Wallet", 3, "Continental Coins Amount", 0, 999999999, 0, "Add", function(value)
        UT:addContinentalCoins(value)
        UTMenu:_refreshProgress()
    end)

    local walletBtnY = self.contentStartY + 3 * self.numberInputRowHeight
    local walletBtnWidth = (contentWidth - self.cardMargin * 2 - self.cardGap) / 2

    local resetMoneyBtn = self:create_action_button(self._contentPanel, self.cardMargin, walletBtnY, walletBtnWidth, "Reset Money", function()
        UT:resetMoney()
        UTMenu:_refreshProgress()
    end, nil, nil, "progress-wallet-reset-money")
    resetMoneyBtn.tab = "Progress"
    resetMoneyBtn.subTab = "Wallet"
    table.insert(self._actionButtons, resetMoneyBtn)

    local resetCoinsBtn = self:create_action_button(self._contentPanel, self.cardMargin + walletBtnWidth + self.cardGap, walletBtnY, walletBtnWidth, "Reset Coins", function()
        UT:resetContinentalCoins()
        UTMenu:_refreshProgress()
    end, nil, nil, "progress-wallet-reset-coins")
    resetCoinsBtn.tab = "Progress"
    resetCoinsBtn.subTab = "Wallet"
    table.insert(self._actionButtons, resetCoinsBtn)

    local unlocksColumns = 2
    local unlocksColWidth = (contentWidth - self.cardMargin * 2 - self.cardGap * (unlocksColumns - 1)) / unlocksColumns

    self:_addActionButtonGrid("Progress", "Unlocks", unlocksColWidth, {
        { title = "Unlock Masks", activeTitle = "Masks Unlocked", onClick = function() UT:addItemsToBlackMarket("masks", UT.blackMarketMasks) end },
        { title = "Lock Masks", onClick = function() UT:removeItemsFromBlackMarket("masks", UT.blackMarketMasks) end },
        { title = "Unlock Materials", activeTitle = "Materials Unlocked", onClick = function() UT:addItemsToBlackMarket("materials", UT.blackMarketMaterials) end },
        { title = "Lock Materials", onClick = function() UT:removeItemsFromBlackMarket("materials", UT.blackMarketMaterials) end },
        { title = "Unlock Textures", activeTitle = "Textures Unlocked", onClick = function() UT:addItemsToBlackMarket("textures", UT.blackMarketTextures) end },
        { title = "Lock Textures", onClick = function() UT:removeItemsFromBlackMarket("textures", UT.blackMarketTextures) end },
        { title = "Unlock Colors", activeTitle = "Colors Unlocked", onClick = function() UT:addItemsToBlackMarket("colors", UT.blackMarketColors) end },
        { title = "Lock Colors", onClick = function() UT:removeItemsFromBlackMarket("colors", UT.blackMarketColors) end },
        { title = "Unlock Weapon Mods", activeTitle = "Weapon Mods Unlocked", onClick = function() UT:addItemsToBlackMarket("weaponMods", UT.blackMarketWeaponMods) end },
        { title = "Lock Weapon Mods", onClick = function() UT:removeItemsFromBlackMarket("weaponMods", UT.blackMarketWeaponMods) end },
        { title = "Unlock All Trophies", activeTitle = "Trophies Unlocked", onClick = function() UT:unlockTrophies(UT.trophies) end },
        { title = "Lock All Trophies", onClick = function() UT:lockTrophies(UT.trophies) end },
        { title = "Unlock Steam Achievements", activeTitle = "Achievements Unlocked", onClick = function() UT:unlockSteamAchievements(UT.steamAchievements) end },
        { title = "Lock Steam Achievements", onClick = function() UT:lockSteamAchievements(UT.steamAchievements) end },
        { title = "Unlock All Slots", activeTitle = "Slots Unlocked", onClick = function() UT:setBlackMarketSlotsLock(false) end },
        { title = "Lock All Slots", onClick = function() UT:setBlackMarketSlotsLock(true) end },
        { title = "Clear New-Drop Marks", activeTitle = "Marks Cleared", onClick = function() UT:removeBlackMarketExclamationMarks() end }
    }, 1, unlocksColumns)

    local statSliderDefs = {
        { id = "player-stats-speed-multiplier", settingKey = "move-speed-multiplier", title = "Speed Multiplier", min = 1.0, max = 2.5, step = 0.1, default = 1.0, decimals = 1,
          apply = function(newVal) UT:setMoveSpeedMultiplier(newVal ~= 1.0, newVal) end },
        { id = "player-stats-fire-rate-multiplier", settingKey = "fire-rate-multiplier", title = "Fire Rate Multiplier", min = 1.0, max = 10.0, step = 0.1, default = 1.0, decimals = 1,
          apply = function(newVal) UT:setFireRateMultiplier(newVal ~= 1.0, newVal) end },
        { id = "player-stats-damage-multiplier", settingKey = "damage-multiplier", title = "Damage Multiplier", min = 1.0, max = 10.0, step = 0.1, default = 1.0, decimals = 1,
          apply = function(newVal) UT:setDamageMultiplier(newVal ~= 1.0, newVal) end },
        { id = "player-stats-melee-damage-multiplier", settingKey = "melee-damage-multiplier", title = "Melee Damage Multiplier", min = 1.0, max = 10.0, step = 0.1, default = 1.0, decimals = 1,
          apply = function(newVal) UT:setMeleeDamageMultiplier(newVal ~= 1.0, newVal) end },
        { id = "player-stats-throw-distance-multiplier", settingKey = "throw-distance-multiplier", title = "Throw Distance Multiplier", min = 1.0, max = 5.0, step = 0.1, default = 1.0, decimals = 1,
          apply = function(newVal) UT:setThrowDistanceMultiplier(newVal ~= 1.0, newVal) end },
        { id = "player-stats-dodge-chance-bonus", settingKey = "dodge-chance-bonus", title = "Dodge Chance Bonus", min = 0, max = 1.0, step = 0.05, default = 0, decimals = 2,
          apply = function(newVal) UT:setDodgeChanceBonus(newVal > 0, newVal) end,
          liveBaseline = function() return UT.GameUtility:getCurrentDodgeChance() end }
    }

    local statSliderDefsII = {
        { id = "player-stats2-max-health-multiplier", settingKey = "max-health-multiplier", title = "Max Health Multiplier", min = 1.0, max = 10.0, step = 0.5, default = 1.0, decimals = 1,
          apply = function(newVal) UT:setMaxHealthMultiplier(newVal ~= 1.0, newVal) end },
        { id = "player-stats2-max-armor-multiplier", settingKey = "max-armor-multiplier", title = "Max Armor Multiplier", min = 1.0, max = 10.0, step = 0.5, default = 1.0, decimals = 1,
          apply = function(newVal) UT:setMaxArmorMultiplier(newVal ~= 1.0, newVal) end },
        { id = "player-stats2-reload-speed-multiplier", settingKey = "reload-speed-multiplier", title = "Reload Speed Multiplier", min = 1.0, max = 10.0, step = 0.5, default = 1.0, decimals = 1,
          apply = function(newVal) UT:setReloadSpeedMultiplier(newVal ~= 1.0, newVal) end },
        { id = "player-stats2-ammo-pickup-multiplier", settingKey = "ammo-pickup-multiplier", title = "Ammo Pickup Multiplier", min = 1.0, max = 20.0, step = 1.0, default = 1.0, decimals = 1,
          apply = function(newVal) UT:setAmmoPickupMultiplier(newVal ~= 1.0, newVal) end },
        { id = "player-stats2-interaction-speed-percent", settingKey = "interaction-speed-percent", title = "Interaction Speed %", min = 100, max = 500, step = 10, default = 100,
          apply = function(newVal) UT:setInteractionSpeedMultiplier(newVal ~= 100, newVal / 100) end },
        { id = "player-stats2-detection-range-multiplier", settingKey = "detection-range-multiplier", title = "Detection Range Multiplier", min = 0.0, max = 1.0, step = 0.05, default = 1.0, decimals = 2,
          apply = function(newVal) UT:setDetectionRangeMultiplier(newVal ~= 1.0, newVal) end }
    }

    local function buildStatSliders(defs, subTab)
        for index, def in ipairs(defs) do
            local yOffset = self.contentStartY + (index - 1) * self.sliderRowHeight
            local initialValue = UT:getSetting(def.settingKey)
            if initialValue == nil then
                initialValue = def.default
            end
            local enabledKey = "enable-" .. def.settingKey
            local wrappedApply = function(newVal)
                def.apply(newVal)
                UT:setSetting(enabledKey, newVal ~= def.default)
                UT:setSetting(def.settingKey, newVal)
            end
            local slider = self:create_slider(self._contentPanel, contentWidth, yOffset, def.title, def.min, def.max, initialValue, def.step, wrappedApply, def.default, def.decimals, def.id, def.liveBaseline)
            slider.tab = "Player"
            slider.subTab = subTab
            table.insert(self._sliders, slider)
        end
    end

    buildStatSliders(statSliderDefs, "Stats")
    buildStatSliders(statSliderDefsII, "Stats II")

    self:_refreshContentVisibility()
end

function UTMenu:_refreshProgress()
    pcall(function() UT.GameUtility:refreshPlayerProfileGUI() end)
    pcall(function() UT.GameUtility:saveProgress() end)
end

function UTMenu:_applyBunnyhopConfig()
    UT:setBunnyhop(UT.bunnyhopEnabled, UT.bunnyhopAirAccelerate, UT.bunnyhopMaxAirSpeed, UT.bunnyhopSpeedCap)
end

function UTMenu:_buildBunnyhopPopoverContent(popoverPanel, popoverWidth)
    local sliderDefs = {
        { id = "player-movement-bhop-air-accelerate", title = "Air Accelerate", min = 100, max = 2000, step = 10, field = "bunnyhopAirAccelerate", default = 1000 },
        { id = "player-movement-bhop-max-air-speed", title = "Max Air Speed", min = 50, max = 500, step = 10, field = "bunnyhopMaxAirSpeed", default = 100 },
        { id = "player-movement-bhop-speed-cap", title = "Bhop Speed Cap", min = 1000, max = 5000, step = 50, field = "bunnyhopSpeedCap", default = 3500 }
    }

    for index, def in ipairs(sliderDefs) do
        local yOffset = 12 + (index - 1) * self.sliderRowHeight
        local currentVal = UT[def.field] or def.default
        UT[def.field] = currentVal
        local slider = self:create_slider(popoverPanel, popoverWidth, yOffset, def.title, def.min, def.max, currentVal, def.step, function(newVal)
            UT[def.field] = newVal
            UTMenu:_applyBunnyhopConfig()
        end, def.default, nil, def.id)
        slider.tab = "Player"
        slider.subTab = "Movement"
        table.insert(self._popoverSliders, slider)
    end
end

function UTMenu:_buildNoClipPopoverContent(popoverPanel, popoverWidth)
    local currentVal = UT.noClipSpeed or 10
    UT.noClipSpeed = currentVal

    local slider = self:create_slider(popoverPanel, popoverWidth, 12, "Speed", 1, 100, currentVal, 1, function(newVal)
        UT.noClipSpeed = newVal
        UT:setNoClip(UT.noClipEnabled, newVal)
    end, 10, nil, "player-movement-noclip-speed")
    slider.tab = "Player"
    slider.subTab = "Movement"
    table.insert(self._popoverSliders, slider)
end

function UTMenu:_applySlowMotionConfig()
    UT:setSlowMotion(UT.slowMotionEnabled, UT.slowMotionWorldSpeed or 0.2, UT.slowMotionPlayerSpeed or 0.5)
end

function UTMenu:_buildSlowMotionPopoverContent(popoverPanel, popoverWidth)
    local sliderDefs = {
        { id = "stealth-ai-time-slow-motion-world-speed", title = "World Speed", min = 0.1, max = 1, step = 0.05, field = "slowMotionWorldSpeed", default = 0.2, decimals = 2 },
        { id = "stealth-ai-time-slow-motion-player-speed", title = "Player Speed", min = 0.1, max = 1, step = 0.05, field = "slowMotionPlayerSpeed", default = 0.5, decimals = 2 }
    }

    for index, def in ipairs(sliderDefs) do
        local yOffset = 12 + (index - 1) * self.sliderRowHeight
        local currentVal = UT[def.field] or def.default
        UT[def.field] = currentVal
        local slider = self:create_slider(popoverPanel, popoverWidth, yOffset, def.title, def.min, def.max, currentVal, def.step, function(newVal)
            UT[def.field] = newVal
            UTMenu:_applySlowMotionConfig()
        end, def.default, def.decimals, def.id)
        slider.tab = "Stealth"
        slider.subTab = "AI & Time"
        table.insert(self._popoverSliders, slider)
    end
end

function UTMenu:_buildAiAndTimeContent(contentWidth)
    local columns = 2
    local colWidth = (contentWidth - self.cardMargin * 2 - self.cardGap * (columns - 1)) / columns

    local toggleDefs = {
        { title = "Prevent Alarm", initial = UT.preventAlarmTriggeringEnabled, onToggle = function(state) UT:setPreventAlarmTriggering(state) end },
        { title = "Disable Enemy AI", initial = UT.disableAIEnabled, onToggle = function(state) UT:setDisableAI(state) end },
        { title = "Suspend Escape Timer", initial = UT.suspendPointOfNoReturnTimerEnabled, onToggle = function(state) UT:setSuspendPointOfNoReturnTimer(state) end },
        {
            title = "Slow Motion",
            initial = UT.slowMotionEnabled,
            hasSettings = true,
            onToggle = function(state)
                UT.slowMotionEnabled = state
                UTMenu:_applySlowMotionConfig()
            end,
            buildPopoverContent = function(popoverPanel, popoverWidth)
                UTMenu:_buildSlowMotionPopoverContent(popoverPanel, popoverWidth)
            end,
            popoverHeight = 12 + 2 * self.sliderRowHeight
        },
        { title = "No Slow Motion", initial = UT:getSetting("enable-no-slow-motion"), onToggle = function(state) UT:setNoSlowMotion(state) UT:setSetting("enable-no-slow-motion", state) end },
        { title = "Remove Team AI", initial = UT.removeTeamAIEnabled, onToggle = function(state) UT:setRemoveTeamAI(state) end },
        { title = "Unlimited Pagers", initial = UT.unlimitedPagersEnabled, onToggle = function(state) UT:setUnlimitedPagers(state) end },
        { title = "No Civilian Kill Penalty", initial = UT.noCivilianKillPenaltyEnabled, onToggle = function(state) UT:setNoCivilianKillPenalty(state) end }
    }

    local nextIndex = self:_addToggleGrid("Stealth", "AI & Time", colWidth, toggleDefs, 1, columns)

    self:_addActionButtonGrid("Stealth", "AI & Time", colWidth, {
        { title = "Remove Invisible Walls", onClick = function() UT:removeInvisibleWalls() end },
        { title = "Start Heist", onClick = function() UT:startTheHeist() end },
        { title = "Restart Heist", onClick = function() UT:restartTheHeist() end },
        { title = "Finish Heist", onClick = function() UT:finishTheHeist() end },
        { title = "Leave Heist", onClick = function() UT:leaveTheHeist() end },
        { title = "Kill All Enemies", onClick = function() UT:killAllEnemies() end },
        { title = "Kill All Civilians", onClick = function() UT:killAllCivilians() end },
        { title = "Tie All Civilians", onClick = function() UT:tieAllCivilians() end },
        { title = "Convert All Enemies", onClick = function() UT:convertAllEnemies() end },
        { title = "Trigger Alarm", onClick = function() UT:triggerTheAlarm() end }
    }, nextIndex, columns)
end

function UTMenu:_buildEntitiesContent(contentWidth)
    local rowY = self.contentStartY
    local pillsWidth = contentWidth - self.cardMargin * 2
    local pillWidth = (pillsWidth - self.subTabPillGap) / 2

    local positions = { { id = "on-crosshair", label = "Spawn: Crosshair" }, { id = "on-self", label = "Spawn: Self" } }

    for index, pos in ipairs(positions) do
        local pill = self._contentPanel:panel({ name = "entities_position_pill_" .. index })
        pill:set_shape(self.cardMargin + (index - 1) * (pillWidth + self.subTabPillGap), rowY, pillWidth, self.subTabPillHeight)

        local pillBackground = pill:rect({ name = "background", color = UTTheme.Panel })
        pillBackground:set_shape(0, 0, pillWidth, self.subTabPillHeight)

        local pillHover = pill:rect({ name = "hover", color = UTTheme.Hover, visible = false })
        pillHover:set_shape(0, 0, pillWidth, self.subTabPillHeight)

        local pillText = pill:text({
            name = "label",
            layer = 1,
            font = tweak_data.menu.pd2_medium_font,
            font_size = tweak_data.menu.pd2_medium_font_size,
            text = pos.label,
            color = (self._entitiesPositionType == pos.id) and UTTheme.Accent or UTTheme.TextSecondary,
            align = "center",
            vertical = "center"
        })
        pillText:set_shape(0, 0, pillWidth, self.subTabPillHeight)

        table.insert(self._entitiesPositionPills, { id = pos.id, panel = pill, hover = pillHover, text = pillText, tab = "Sandbox", subTab = "Entities" })
    end

    local toggleY = rowY + self.subTabPillHeight + self.cardGap
    local convertedToggle = self:create_feature_toggle(self._contentPanel, self.cardMargin, toggleY, pillsWidth, "Converted (Allies)", self._entitiesConverted, false, function(state)
        UTMenu._entitiesConverted = state
    end, nil, "sandbox-entities-converted-allies")
    convertedToggle.tab = "Sandbox"
    convertedToggle.subTab = "Entities"
    table.insert(self._featureToggles, convertedToggle)

    local gridStartY = toggleY + self.cardHeight + self.cardGap

    local entityDefs = {
        { title = "Cop 1", id = "units/payday2/characters/ene_cop_1/ene_cop_1" },
        { title = "Cop 2", id = "units/payday2/characters/ene_cop_2/ene_cop_2" },
        { title = "Cop 3", id = "units/payday2/characters/ene_cop_3/ene_cop_3" },
        { title = "Cop 4", id = "units/payday2/characters/ene_cop_4/ene_cop_4" },
        { title = "FBI 1", id = "units/payday2/characters/ene_fbi_1/ene_fbi_1" },
        { title = "FBI 2", id = "units/payday2/characters/ene_fbi_2/ene_fbi_2" },
        { title = "FBI 3", id = "units/payday2/characters/ene_fbi_3/ene_fbi_3" },
        { title = "FBI Heavy", id = "units/payday2/characters/ene_fbi_heavy_1/ene_fbi_heavy_1" },
        { title = "SWAT 1", id = "units/payday2/characters/ene_fbi_swat_1/ene_fbi_swat_1" },
        { title = "SWAT 2", id = "units/payday2/characters/ene_fbi_swat_2/ene_fbi_swat_2" },
        { title = "SWAT Heavy", id = "units/payday2/characters/ene_swat_heavy_1/ene_swat_heavy_1" },
        { title = "Shield 1", id = "units/payday2/characters/ene_shield_1/ene_shield_1" },
        { title = "Shield 2", id = "units/payday2/characters/ene_shield_2/ene_shield_2" },
        { title = "Tazer", id = "units/payday2/characters/ene_tazer_1/ene_tazer_1" },
        { title = "Sniper 1", id = "units/payday2/characters/ene_sniper_1/ene_sniper_1" },
        { title = "Sniper 2", id = "units/payday2/characters/ene_sniper_2/ene_sniper_2" },
        { title = "Cloaker", id = "units/payday2/characters/ene_spook_1/ene_spook_1" },
        { title = "Medic", id = "units/payday2/characters/ene_medic_m4/ene_medic_m4" },
        { title = "Dozer 1", id = "units/payday2/characters/ene_bulldozer_1/ene_bulldozer_1" },
        { title = "Dozer 2", id = "units/payday2/characters/ene_bulldozer_2/ene_bulldozer_2" },
        { title = "Dozer 3", id = "units/payday2/characters/ene_bulldozer_3/ene_bulldozer_3" },
        { title = "Dozer Medic", id = "units/pd2_dlc_drm/characters/ene_bulldozer_medic/ene_bulldozer_medic" },
        { title = "Dozer Minigun", id = "units/pd2_dlc_drm/characters/ene_bulldozer_minigun/ene_bulldozer_minigun" }
    }

    local columns = 4
    local colWidth = (pillsWidth - self.cardGap * (columns - 1)) / columns

    for index, def in ipairs(entityDefs) do
        local col = (index - 1) % columns
        local row = math.floor((index - 1) / columns)
        local x = self.cardMargin + col * (colWidth + self.cardGap)
        local y = gridStartY + row * (self.cardHeight + self.cardGap)

        local btn = self:create_action_button(self._contentPanel, x, y, colWidth, def.title, function()
            UT.Spawn:setConfig(def.id, "enemies", UTMenu._entitiesPositionType, UTMenu._entitiesConverted)
            UT.Spawn:spawn()
        end, nil, nil, self:_slugify("sandbox-entities-" .. def.title))
        btn.tab = "Sandbox"
        btn.subTab = "Entities"
        table.insert(self._actionButtons, btn)
    end
end

function UTMenu:_buildXRayColorPopoverContent(popoverPanel, popoverWidth)
    local presetColors = {
        { r = 1, g = 0, b = 0 },
        { r = 0, g = 1, b = 0 },
        { r = 0, g = 0, b = 1 },
        { r = 1, g = 1, b = 0 },
        { r = 1, g = 0, b = 1 },
        { r = 1, g = 1, b = 1 }
    }

    local rows = {
        { label = "Enemy", setColor = function(color) UT:setXRayEnemyColor(color) end },
        { label = "Civilian", setColor = function(color) UT:setXRayCivilianColor(color) end },
        { label = "Camera", setColor = function(color) UT:setXRayCameraColor(color) end }
    }

    local swatchSize = 20
    local swatchGap = 6
    local labelWidth = 70

    for rowIndex, row in ipairs(rows) do
        local rowY = 12 + (rowIndex - 1) * 40

        local label = popoverPanel:text({
            name = "label_" .. rowIndex,
            layer = 1,
            font = tweak_data.menu.pd2_medium_font,
            font_size = tweak_data.menu.pd2_medium_font_size,
            text = row.label,
            color = UTTheme.TextSecondary,
            vertical = "center"
        })
        label:set_shape(12, rowY, labelWidth, swatchSize)

        for colIndex, preset in ipairs(presetColors) do
            local swatchX = 12 + labelWidth + (colIndex - 1) * (swatchSize + swatchGap)
            local swatch = self:create_color_swatch(popoverPanel, swatchX, rowY, swatchSize, Color(1, preset.r, preset.g, preset.b), function()
                row.setColor(Vector3(preset.r, preset.g, preset.b))
            end)
            table.insert(self._popoverButtons, swatch)
        end
    end
end

function UTMenu:create_feature_toggle(parent, x, y, width, title, state, has_settings, onToggle, buildPopoverContent, id)
    local card = parent:panel({ name = "feature_toggle_" .. tostring(#self._featureToggles + 1) })
    card:set_shape(x, y, width, self.cardHeight)

    if not self:draw_rounded_bg(card, width, self.cardHeight, UTTheme.Panel, "background") then
        local cardBackground = card:rect({ name = "background", color = UTTheme.Panel, layer = 0 })
        cardBackground:set_shape(0, 0, width, self.cardHeight)
    end

    local hover = card:panel({ name = "hover", visible = true, layer = 1 })
    hover:set_shape(0, 0, width, self.cardHeight)
    if not self:draw_rounded_bg(hover, width, self.cardHeight, UTTheme.Hover, "hover") then
        local hoverFill = hover:rect({ name = "fill", color = UTTheme.Hover })
        hoverFill:set_shape(0, 0, width, self.cardHeight)
    end
    hover:set_alpha(0)

    local toggleArea = card:panel({ name = "toggle_area", layer = 2 })
    toggleArea:set_shape(0, 0, width, self.cardHeight)

    local gearReserved = has_settings and (self.gearSize + 8) or 0
    local toggleReserved = self.toggleWidth + 8 + gearReserved

    local titleText = toggleArea:text({
        name = "title",
        layer = 1,
        font = tweak_data.menu.pd2_medium_font,
        font_size = tweak_data.menu.pd2_medium_font_size,
        text = title,
        color = UTTheme.TextPrimary,
        vertical = "center"
    })
    titleText:set_shape(0, 0, toggleArea:w() - toggleReserved, self.cardHeight)

    local switchX = toggleArea:w() - self.toggleWidth
    local switchY = (self.cardHeight - self.toggleHeight) / 2
    local knobPadding = 2
    local knobTopY = (self.toggleHeight - self.toggleKnobSize) / 2

    local toggleBgTexture = self:_getTexture("toggle_bg")
    local knobTexture = self:_getTexture("glow_circle")
    local toggleTrack, toggleKnob, knobOffX, knobOnX

    if toggleBgTexture and knobTexture then
        -- knob is a sibling bitmap positioned in toggleArea's coordinate space
        knobOffX = switchX + knobPadding
        knobOnX = switchX + self.toggleWidth - self.toggleKnobSize - knobPadding
        knobTopY = switchY + knobTopY

        toggleTrack = toggleArea:bitmap({
            name = "toggle_track",
            texture = toggleBgTexture,
            texture_rect = self:_getTextureRect("toggle_bg"),
            color = state and UTTheme.Accent or UTTheme.TextSecondary,
            layer = 0,
            w = self.toggleWidth,
            h = self.toggleHeight
        })
        toggleTrack:set_shape(switchX, switchY, self.toggleWidth, self.toggleHeight)

        toggleKnob = toggleArea:bitmap({
            name = "toggle_knob",
            layer = 1,
            texture = knobTexture,
            texture_rect = self:_getTextureRect("glow_circle"),
            color = Color(1, 1, 1, 1),
            w = self.toggleKnobSize,
            h = self.toggleKnobSize
        })
        toggleKnob:set_shape(state and knobOnX or knobOffX, knobTopY, self.toggleKnobSize, self.toggleKnobSize)
    else
        -- knob is a child of switchBorder, positioned relative to it (local 0,0 origin)
        knobOffX = knobPadding
        knobOnX = self.toggleWidth - self.toggleKnobSize - knobPadding

        local switchBorder = toggleArea:panel({ name = "toggle_switch_border" })
        switchBorder:set_shape(switchX, switchY, self.toggleWidth, self.toggleHeight)
        self:draw_border(switchBorder, UTTheme.Border)

        toggleTrack = switchBorder:rect({
            name = "toggle_track",
            color = state and UTTheme.Accent or UTTheme.TextSecondary
        })
        toggleTrack:set_shape(0, 0, self.toggleWidth, self.toggleHeight)

        toggleKnob = switchBorder:rect({
            name = "toggle_knob",
            color = UTTheme.TextPrimary
        })
        toggleKnob:set_shape(state and knobOnX or knobOffX, knobTopY, self.toggleKnobSize, self.toggleKnobSize)
    end

    local gearButton
    if has_settings then
        gearButton = card:panel({ name = "gear", layer = 2 })
        gearButton:set_shape(switchX - 8 - self.gearSize, (self.cardHeight - self.gearSize) / 2, self.gearSize, self.gearSize)

        local gearBackground = gearButton:rect({ name = "background", color = UTTheme.Panel })
        gearBackground:set_shape(0, 0, self.gearSize, self.gearSize)

        self:draw_gear_icon(gearButton, self.gearSize, UTTheme.TextSecondary)
    end

    local indicator = card:rect({ name = "keybind_indicator", color = UTTheme.Accent, visible = false, layer = 3 })
    indicator:set_shape(0, 0, 6, 6)

    local toggle = {
        panel = card,
        hover = hover,
        toggleArea = toggleArea,
        toggleTrack = toggleTrack,
        toggleKnob = toggleKnob,
        knobOffX = knobOffX,
        knobOnX = knobOnX,
        knobTopY = knobTopY,
        knobSize = self.toggleKnobSize,
        gearButton = gearButton,
        indicator = indicator,
        title = title,
        state = state,
        liveState = state,
        onToggle = onToggle,
        buildPopoverContent = buildPopoverContent,
        id = id,
        activeKeybind = nil,
        x = x,
        y = y,
        width = width
    }

    function toggle:setState(newState)
        self.state = newState
        self.liveState = newState

        if alive(self.toggleTrack) then
            self.toggleTrack:set_color(newState and UTTheme.Accent or UTTheme.TextSecondary)
        end
        if alive(self.toggleKnob) then
            self.toggleKnob:set_shape(newState and self.knobOnX or self.knobOffX, self.knobTopY, self.knobSize, self.knobSize)
        end

        if self.onToggle then
            self.onToggle(newState)
        end
    end

    function toggle:applyKeybindValue(bind, value)
        self.activeKeybind = bind
        self.liveState = value
        if alive(self.indicator) then
            self.indicator:set_visible(true)
        end
        if self.onToggle then
            self.onToggle(value)
        end
    end

    function toggle:revertKeybindOverride()
        self.activeKeybind = nil
        self.liveState = self.state
        if alive(self.indicator) then
            self.indicator:set_visible(false)
        end
        if self.onToggle then
            self.onToggle(self.state)
        end
    end

    if id then
        UTMenu._boundWidgets[id] = toggle
    end

    return toggle
end

function UTMenu:create_action_button(parent, x, y, width, title, onClick, activeTitle, initialActive, id)
    local card = parent:panel({ name = "action_button_" .. tostring(#self._actionButtons + #self._popoverButtons + 1) })
    card:set_shape(x, y, width, self.cardHeight)

    local background = card:rect({
        name = "background",
        color = UTTheme.Panel,
        layer = 0
    })
    background:set_shape(0, 0, width, self.cardHeight)

    local hover = card:rect({ name = "hover", color = UTTheme.Hover, visible = false, layer = 1 })
    hover:set_shape(0, 0, width, self.cardHeight)

    local text = card:text({
        name = "title",
        layer = 2,
        font = tweak_data.menu.pd2_medium_font,
        font_size = tweak_data.menu.pd2_medium_font_size,
        text = (initialActive and activeTitle) or title,
        color = initialActive and UTTheme.Accent or UTTheme.TextPrimary,
        align = "center",
        vertical = "center"
    })
    text:set_shape(0, 0, width, self.cardHeight)

    local button = {
        panel = card,
        hover = hover,
        text = text,
        title = title,
        onClick = onClick,
        activeTitle = activeTitle,
        activated = initialActive or false,
        id = id,
        x = x,
        y = y,
        width = width
    }

    function button:click()
        if self.onClick then
            self.onClick()
        end

        if self.activeTitle and not self.activated then
            self.activated = true
            self.text:set_text(self.activeTitle)
            self.text:set_color(UTTheme.Accent)
        end
    end

    if id then
        UTMenu._boundWidgets[id] = button
    end

    return button
end

function UTMenu:create_color_swatch(parent, x, y, size, color, onClick)
    local swatch = parent:panel({ name = "swatch" })
    swatch:set_shape(x, y, size, size)

    local rect = swatch:rect({ name = "color", color = color })
    rect:set_shape(0, 0, size, size)

    local widget = {
        panel = swatch,
        rect = rect,
        onClick = onClick
    }

    function widget:click()
        if self.onClick then
            self.onClick()
        end
    end

    return widget
end

function UTMenu:create_number_input(parent, x, y, width, height, initialValue, minVal, maxVal)
    local box = parent:panel({ name = "number_input_" .. tostring(#self._numberInputs + 1) })
    box:set_shape(x, y, width, height)

    local background = box:rect({ name = "background", color = UTTheme.Panel })
    background:set_shape(0, 0, width, height)

    local hover = box:rect({ name = "hover", color = UTTheme.Hover, visible = false })
    hover:set_shape(0, 0, width, height)

    local text = box:text({
        name = "value",
        layer = 1,
        font = tweak_data.menu.pd2_medium_font,
        font_size = tweak_data.menu.pd2_medium_font_size,
        text = tostring(initialValue),
        color = UTTheme.TextPrimary,
        vertical = "center"
    })
    text:set_shape(8, 0, width - 16, height)

    local input = {
        panel = box,
        hover = hover,
        background = background,
        text = text,
        value = tostring(initialValue),
        minVal = minVal,
        maxVal = maxVal,
        focused = false
    }

    function input:_refreshDisplay()
        self.text:set_text(self.focused and (self.value .. "|") or self.value)
    end

    function input:appendDigit(digit)
        if #self.value >= 9 then
            return
        end
        self.value = self.value .. digit
        self:_refreshDisplay()
    end

    function input:backspace()
        self.value = self.value:sub(1, -2)
        self:_refreshDisplay()
    end

    function input:commit()
        local numeric = math.clamp(tonumber(self.value) or self.minVal, self.minVal, self.maxVal)
        self.value = tostring(numeric)
    end

    function input:setFocused(focused)
        self.focused = focused
        self.background:set_color(focused and UTTheme.Accent or UTTheme.Panel)
        if not focused then
            self:commit()
        end
        self:_refreshDisplay()
    end

    text:enter_text(function(...)
        if UTMenu._focusedNumberInput ~= input then
            return
        end

        local args = { ... }
        local s = args[#args]

        if s and tonumber(s) then
            input:appendDigit(s)
        end
    end)

    return input
end

function UTMenu:_focusNumberInput(input)
    if self._focusedNumberInput == input then
        return
    end

    self:_blurNumberInput()
    self._focusedNumberInput = input
    input:setFocused(true)
end

function UTMenu:_blurNumberInput()
    if self._focusedNumberInput then
        self._focusedNumberInput:setFocused(false)
        self._focusedNumberInput = nil
    end
end

function UTMenu:_addNumberInputRow(tab, subTab, index, title, minVal, maxVal, initialValue, buttonLabel, onApply)
    local contentWidth = self.width - self.sidebarWidth
    local rowWidth = contentWidth - self.cardMargin * 2
    local yOffset = self.contentStartY + (index - 1) * self.numberInputRowHeight

    local row = self._contentPanel:panel({ name = "number_row_" .. tostring(#self._numberInputs + 1) })
    row:set_shape(self.cardMargin, yOffset, rowWidth, self.numberInputRowHeight)

    local titleText = row:text({
        name = "title",
        layer = 1,
        font = tweak_data.menu.pd2_medium_font,
        font_size = tweak_data.menu.pd2_medium_font_size,
        text = title,
        color = UTTheme.TextSecondary,
        vertical = "top"
    })
    titleText:set_shape(0, 0, rowWidth, 18)

    local buttonWidth = 90
    local inputWidth = rowWidth - buttonWidth - 8

    local input = self:create_number_input(row, 0, 22, inputWidth, self.cardHeight, initialValue, minVal, maxVal)
    input.tab = tab
    input.subTab = subTab
    table.insert(self._numberInputs, input)

    local button = self:create_action_button(row, inputWidth + 8, 22, buttonWidth, buttonLabel, function()
        onApply(tonumber(input.value) or minVal)
    end, nil, nil, self:_slugify(tab .. "-" .. subTab .. "-" .. title .. "-" .. buttonLabel))
    button.tab = tab
    button.subTab = subTab
    table.insert(self._actionButtons, button)

    table.insert(self._numberInputRows, { panel = row, tab = tab, subTab = subTab })
end

function UTMenu:_widgetRowHeight(widgetType)
    if widgetType == "slider" then
        return self.sliderRowHeight
    end
    return self.cardHeight
end

function UTMenu:_keybindMenuHeight(widgetType, widgetId)
    local rows = 2 -- New Bind, Hotkeys
    if widgetType == "slider" then
        rows = rows + 1 -- Reset
    end

    for _, bind in ipairs(UT.nativeKeybinds) do
        if bind.widgetId == widgetId then
            rows = rows + 1
        end
    end

    return 8 + rows * (self.cardHeight + 4) + 4
end

function UTMenu:_keybindEditorHeight(widgetType)
    local height = 16 + self.cardHeight + 8

    if widgetType ~= "action" then
        height = height + self.cardHeight + 8
    end

    if widgetType == "toggle" then
        height = height + self.cardHeight + 8
    end

    if widgetType == "slider" then
        height = height + self.sliderRowHeight + 8
    end

    return height + self.cardHeight + 8
end

function UTMenu:_globalHotkeysHeight()
    local count = #UT.nativeKeybinds
    if count == 0 then
        return 16 + 20 + self.cardHeight + 8
    end
    return 16 + 20 + count * (self.hotkeyContextRowHeight + 4) + 8
end

function UTMenu:_openKeybindManager(widget, widgetType, anchorX, anchorY)
    self._keybindEditor = { widget = widget, widgetType = widgetType, step = "menu", anchorX = anchorX, anchorY = anchorY }
    self:_reopenKeybindPopover()
end

function UTMenu:_reopenKeybindPopover()
    local editor = self._keybindEditor
    if not editor then
        return
    end

    self:_hideNewBindPreview()

    local height, width
    if editor.step == "editor" then
        height = self:_keybindEditorHeight(editor.widgetType)
        width = self.keybindPopoverWidth
    elseif editor.step == "global" then
        height = self:_globalHotkeysHeight()
        width = self.hotkeysPopoverWidth
    else
        height = self:_keybindMenuHeight(editor.widgetType, editor.widget.id)
        width = self.keybindPopoverWidth
    end

    self:_openPopover(editor.anchorX, editor.anchorY, width, height, function(popoverPanel, popoverWidth)
        self:_buildKeybindManagerContent(popoverPanel, popoverWidth)
    end)
    self._popoverIsKeybindManager = true
end

function UTMenu:_describeBind(bind)
    local modeLabel = bind.mode == "hold" and "Hold" or (bind.mode == "press" and "Press" or "Toggle")
    local keyLabel = bind.key and string.upper(bind.key) or "Not set"

    if bind.widgetType == "slider" then
        return keyLabel .. " - " .. modeLabel .. " (" .. tostring(bind.value) .. ")"
    elseif bind.widgetType == "toggle" then
        local targetLabel = bind.target == "off" and "Off" or "On"
        return keyLabel .. " - " .. modeLabel .. " (" .. targetLabel .. ")"
    else
        return keyLabel .. " - Press"
    end
end

function UTMenu:_defaultBindFields(widget, widgetType)
    local fields = {
        key = nil,
        mode = (widgetType == "slider" or widgetType == "action") and "press" or "toggle"
    }

    if widgetType == "toggle" then
        fields.target = "on"
    elseif widgetType == "slider" then
        fields.value = widget.value
    end

    return fields
end

function UTMenu:_showPreviewFlyout(triggerKey, lines)
    if self._keybindFlyoutPanel then
        return
    end

    if not self._activePopoverOrigin or not self._activePopoverWidth then
        return
    end

    local flyoutWidth = self.keybindPopoverWidth
    local height = 16 + #lines * 20

    local flyoutX = self._activePopoverOrigin.x + self._activePopoverWidth + 4
    if flyoutX + flyoutWidth > self.width then
        flyoutX = self._activePopoverOrigin.x - flyoutWidth - 4
    end
    flyoutX = math.clamp(flyoutX, 0, math.max(0, self.width - flyoutWidth))
    local flyoutY = math.clamp(self._activePopoverOrigin.y, 0, math.max(0, self.height - height))

    local panel = self._mainFrame:panel({ name = "keybind_flyout", layer = self.popoverLayer })
    panel:set_shape(flyoutX, flyoutY, flyoutWidth, height)

    if not self:draw_rounded_bg(panel, flyoutWidth, height, UTTheme.PopoverBackground, "background", self.popoverCornerRadius) then
        local background = panel:rect({ name = "background", color = UTTheme.PopoverBackground })
        background:set_shape(0, 0, flyoutWidth, height)
        self:draw_border(panel, UTTheme.Border)
    end

    for index, line in ipairs(lines) do
        local text = panel:text({
            name = "line_" .. index,
            layer = 1,
            font = tweak_data.menu.pd2_medium_font,
            font_size = tweak_data.menu.pd2_medium_font_size,
            text = line,
            color = UTTheme.TextSecondary,
            vertical = "center"
        })
        text:set_shape(12, 8 + (index - 1) * 20, flyoutWidth - 24, 20)
    end

    self._keybindFlyoutPanel = panel
    self._keybindFlyoutTrigger = triggerKey
end

function UTMenu:_showHotkeyRowPreview(row)
    if self._keybindFlyoutTrigger ~= row.bind.id then
        self:_hideNewBindPreview()
    end

    local modeLabel = row.bind.mode == "hold" and "Hold" or (row.bind.mode == "press" and "Press" or "Toggle")
    local lines = { "Key: " .. (row.bind.key and string.upper(row.bind.key) or "-"), "Mode: " .. modeLabel }

    if row.bind.widgetType == "toggle" then
        table.insert(lines, "Value: " .. (row.bind.target == "off" and "Off" or "On"))
    elseif row.bind.widgetType == "slider" then
        table.insert(lines, "Value: " .. tostring(row.bind.value))
    end

    self:_showPreviewFlyout(row.bind.id, lines)
end

function UTMenu:_openHotkeyRowEditor(row)
    if not row.widget then
        return
    end

    local editor = self._keybindEditor
    local bind = row.bind

    editor.widget = row.widget
    editor.widgetType = bind.widgetType
    editor.step = "editor"
    editor.editingBindId = bind.id
    editor.key = bind.key
    editor.mode = bind.mode
    editor.target = bind.target
    editor.value = bind.value
    editor.returnStep = row.returnStep or "global"

    self:_reopenKeybindPopover()
end

function UTMenu:_bindRowHeight(showContext)
    return showContext and self.hotkeyContextRowHeight or self.cardHeight
end

function UTMenu:_buildBindRow(parentPanel, x, y, width, bind, boundWidget, showContext, returnStep)
    local rowHeight = self:_bindRowHeight(showContext)

    local row = parentPanel:panel({ name = "hotkey_row" })
    row:set_shape(x, y, width, rowHeight)

    local rowBackground = row:rect({ name = "background", color = UTTheme.Panel, visible = false })
    rowBackground:set_shape(0, 0, width, rowHeight)

    local removeBtn = self:create_action_button(row, width - 36, (rowHeight - self.cardHeight) / 2, 36, "X", function()
        if boundWidget and boundWidget.activeKeybind and boundWidget.activeKeybind.id == bind.id then
            boundWidget:revertKeybindOverride()
        end
        UT:removeNativeKeybind(bind.id)
        UTMenu:_reopenKeybindPopover()
    end)
    table.insert(self._popoverButtons, removeBtn)

    if showContext and boundWidget and boundWidget.tab then
        local context = row:text({
            name = "context",
            layer = 1,
            font = tweak_data.menu.pd2_small_font,
            font_size = tweak_data.menu.pd2_small_font_size,
            text = boundWidget.tab .. " - " .. tostring(boundWidget.subTab),
            color = UTTheme.TextSecondary,
            vertical = "center"
        })
        context:set_shape(8, 0, width - 44, 16)

        local label = row:text({
            name = "label",
            layer = 1,
            font = tweak_data.menu.pd2_medium_font,
            font_size = tweak_data.menu.pd2_medium_font_size,
            text = (boundWidget.title or "?") .. "  " .. self:_describeBind(bind),
            color = UTTheme.TextPrimary,
            vertical = "center"
        })
        label:set_shape(8, 16, width - 44, rowHeight - 16)
    else
        local label = row:text({
            name = "label",
            layer = 1,
            font = tweak_data.menu.pd2_medium_font,
            font_size = tweak_data.menu.pd2_medium_font_size,
            text = self:_describeBind(bind),
            color = UTTheme.TextPrimary,
            vertical = "center"
        })
        label:set_shape(8, 0, width - 44, rowHeight)
    end

    table.insert(self._popoverHotkeyRows, { panel = row, background = rowBackground, bind = bind, widget = boundWidget, returnStep = returnStep })
end

function UTMenu:_hideNewBindPreview()
    if self._keybindFlyoutPanel then
        self._mainFrame:remove(self._keybindFlyoutPanel)
        self._keybindFlyoutPanel = nil
    end
    self._keybindFlyoutTrigger = nil
end

function UTMenu:_buildKeybindManagerContent(popoverPanel, popoverWidth)
    local editor = self._keybindEditor
    if not editor then
        return
    end

    if editor.step == "editor" then
        self:_buildKeybindEditorContent(popoverPanel, popoverWidth)
    elseif editor.step == "global" then
        self:_buildGlobalHotkeysContent(popoverPanel, popoverWidth)
    else
        self:_buildKeybindMenuContent(popoverPanel, popoverWidth)
    end
end

function UTMenu:_buildKeybindMenuContent(popoverPanel, popoverWidth)
    local editor = self._keybindEditor
    local widget = editor.widget
    local y = 8

    for _, bind in ipairs(UT.nativeKeybinds) do
        if bind.widgetId == widget.id then
            self:_buildBindRow(popoverPanel, 12, y, popoverWidth - 24, bind, widget, false, "menu")
            y = y + self.cardHeight + 4
        end
    end

    local newBindBtn = self:create_action_button(popoverPanel, 12, y, popoverWidth - 24, "New Bind", function()
        local fields = self:_defaultBindFields(widget, editor.widgetType)
        fields.id = tostring(UT.Utility:getClock()) .. "-" .. tostring(math.random(100000, 999999))
        fields.widgetId = widget.id
        fields.widgetType = editor.widgetType
        UT:addNativeKeybind(fields)

        editor.step = "editor"
        editor.editingBindId = fields.id
        editor.key = fields.key
        editor.mode = fields.mode
        editor.target = fields.target
        editor.value = fields.value
        editor.returnStep = "menu"

        UTMenu:_reopenKeybindPopover()
    end)
    table.insert(self._popoverButtons, newBindBtn)
    y = y + self.cardHeight + 4

    local hotkeysBtn = self:create_action_button(popoverPanel, 12, y, popoverWidth - 24, "Hotkeys", function()
        editor.step = "global"
        UTMenu:_reopenKeybindPopover()
    end)
    table.insert(self._popoverButtons, hotkeysBtn)
    y = y + self.cardHeight + 4

    if editor.widgetType == "slider" then
        local resetBtn = self:create_action_button(popoverPanel, 12, y, popoverWidth - 24, "Reset", function()
            widget:resetToDefault()
            UTMenu:_closePopover()
        end)
        resetBtn.text:set_color(Color(1, 1, 0.35, 0.35))
        table.insert(self._popoverButtons, resetBtn)
    end
end

function UTMenu:_buildGlobalHotkeysContent(popoverPanel, popoverWidth)
    local editor = self._keybindEditor
    local y = 8

    local header = popoverPanel:text({
        name = "header",
        layer = 1,
        font = tweak_data.menu.pd2_small_font,
        font_size = tweak_data.menu.pd2_small_font_size,
        text = "Hotkeys",
        color = UTTheme.TextSecondary,
        vertical = "top"
    })
    header:set_shape(12, y, popoverWidth - 24, 16)
    y = y + 20

    if #UT.nativeKeybinds == 0 then
        local placeholder = popoverPanel:text({
            name = "placeholder",
            layer = 1,
            font = tweak_data.menu.pd2_small_font,
            font_size = tweak_data.menu.pd2_small_font_size,
            text = "No keybinds yet",
            color = UTTheme.TextSecondary,
            vertical = "top"
        })
        placeholder:set_shape(12, y, popoverWidth - 24, self.cardHeight)
        return
    end

    for _, bind in ipairs(UT.nativeKeybinds) do
        local boundWidget = self:_findKeybindWidget(bind.widgetId)
        self:_buildBindRow(popoverPanel, 12, y, popoverWidth - 24, bind, boundWidget, true, "global")
        y = y + self.hotkeyContextRowHeight + 4
    end
end

function UTMenu:_buildKeybindEditorContent(popoverPanel, popoverWidth)
    local editor = self._keybindEditor
    local widget = editor.widget
    local y = 8

    local keyLabel = popoverPanel:text({
        name = "key_label",
        layer = 1,
        font = tweak_data.menu.pd2_medium_font,
        font_size = tweak_data.menu.pd2_medium_font_size,
        text = "Key: " .. (self._capturingKeybind and "Press any key..." or (editor.key and string.upper(editor.key) or "Not set")),
        color = UTTheme.TextSecondary,
        vertical = "center"
    })
    keyLabel:set_shape(12, y, popoverWidth - 24 - 70, self.cardHeight)

    local setKeyBtn = self:create_action_button(popoverPanel, popoverWidth - 12 - 66, y, 66, "Set Key", function()
        UTMenu._capturingKeybind = true
        UTMenu._capturingKeybindArmed = false
        UTMenu:_reopenKeybindPopover()
    end)
    table.insert(self._popoverButtons, setKeyBtn)
    y = y + self.cardHeight + 8

    if editor.widgetType ~= "action" then
        local modeWidth = (popoverWidth - 24 - 8) / 2
        local pressLabel = editor.widgetType == "slider" and "Press" or "Toggle"
        local pressValue = editor.widgetType == "slider" and "press" or "toggle"

        local toggleModeBtn = self:create_action_button(popoverPanel, 12, y, modeWidth, pressLabel, function()
            editor.mode = pressValue
            UT:updateNativeKeybind(editor.editingBindId, { mode = editor.mode })
            UTMenu:_reopenKeybindPopover()
        end)
        toggleModeBtn.text:set_color(editor.mode == pressValue and UTTheme.Accent or UTTheme.TextPrimary)
        table.insert(self._popoverButtons, toggleModeBtn)

        local holdModeBtn = self:create_action_button(popoverPanel, 12 + modeWidth + 8, y, modeWidth, "Hold", function()
            editor.mode = "hold"
            UT:updateNativeKeybind(editor.editingBindId, { mode = editor.mode })
            UTMenu:_reopenKeybindPopover()
        end)
        holdModeBtn.text:set_color(editor.mode == "hold" and UTTheme.Accent or UTTheme.TextPrimary)
        table.insert(self._popoverButtons, holdModeBtn)

        y = y + self.cardHeight + 8
    end

    if editor.widgetType == "toggle" then
        local targetWidth = (popoverWidth - 24 - 8) / 2
        local targets = { { id = "on", label = "On" }, { id = "off", label = "Off" } }

        for index, t in ipairs(targets) do
            local btn = self:create_action_button(popoverPanel, 12 + (index - 1) * (targetWidth + 8), y, targetWidth, t.label, function()
                editor.target = t.id
                UT:updateNativeKeybind(editor.editingBindId, { target = editor.target })
                UTMenu:_reopenKeybindPopover()
            end)
            btn.text:set_color(editor.target == t.id and UTTheme.Accent or UTTheme.TextPrimary)
            table.insert(self._popoverButtons, btn)
        end

        y = y + self.cardHeight + 8
    end

    if editor.widgetType == "slider" then
        local valueSlider = self:create_slider(popoverPanel, popoverWidth, y, "Value", widget.min, widget.max, editor.value, widget.step, function(newVal)
            editor.value = newVal
            UT:updateNativeKeybind(editor.editingBindId, { value = newVal })
        end, editor.value, widget.decimals)
        table.insert(self._popoverSliders, valueSlider)
        y = y + self.sliderRowHeight + 8
    end

    local iconWidth = (popoverWidth - 24 - 8) / 2

    local deleteBtn = self:create_action_button(popoverPanel, 12, y, iconWidth, "Delete", function()
        if widget.activeKeybind and widget.activeKeybind.id == editor.editingBindId then
            widget:revertKeybindOverride()
        end
        UT:removeNativeKeybind(editor.editingBindId)
        editor.step = editor.returnStep or "menu"
        editor.editingBindId = nil
        UTMenu:_reopenKeybindPopover()
    end)
    deleteBtn.text:set_color(Color(1, 1, 0.35, 0.35))
    table.insert(self._popoverButtons, deleteBtn)

    local hotkeysBtn = self:create_action_button(popoverPanel, 12 + iconWidth + 8, y, iconWidth, "Hotkeys", function()
        editor.step = "global"
        UTMenu:_reopenKeybindPopover()
    end)
    table.insert(self._popoverButtons, hotkeysBtn)
end

function UTMenu:_findKeybindWidget(widgetId)
    return UTMenu._boundWidgets[widgetId]
end

function UTMenu:_fireKeybind(widget, bind)
    if bind.widgetType == "toggle" then
        local value = bind.target ~= "off"
        widget:applyKeybindValue(bind, value)
    elseif bind.widgetType == "slider" then
        widget:applyKeybindValue(bind, bind.value)
    elseif bind.widgetType == "action" then
        if widget.onClick then
            widget.onClick()
        end
    end

    if managers.menu_component then
        managers.menu_component:post_event("box_tick")
    end
end

function UTMenu:_isAnyButtonDown(device)
    for _ in pairs(device:down_list()) do
        return true
    end
    return false
end

function UTMenu:_capturedNameFromDevice(device, isMouse)
    for _, key in pairs(device:down_list()) do
        local id = device:button_name(key)
        local name = device:button_name_str(id)

        if name and name ~= "" then
            if isMouse and not UT.Utility:stringStartsWith(name, "mouse wheel ") then
                name = "mouse " .. name
            end
            return name
        end
    end
    return nil
end

function UTMenu:_pollKeybindCapture()
    local keyboard = Input:keyboard()
    local mouse = Input:mouse()

    if not self._capturingKeybindArmed then
        if not self:_isAnyButtonDown(keyboard) and not self:_isAnyButtonDown(mouse) then
            self._capturingKeybindArmed = true
        end
        return
    end

    local name = self:_capturedNameFromDevice(keyboard, false)

    if name then
        if name == "esc" then
            self._capturingKeybind = false
            self:_reopenKeybindPopover()
            return
        end

        self._capturingKeybind = false
        if self._keybindEditor then
            self._keybindEditor.key = name
            UT:updateNativeKeybind(self._keybindEditor.editingBindId, { key = name })
        end
        self:_reopenKeybindPopover()
        return
    end

    name = self:_capturedNameFromDevice(mouse, true)

    if name then
        self._capturingKeybind = false
        if self._keybindEditor then
            self._keybindEditor.key = name
            UT:updateNativeKeybind(self._keybindEditor.editingBindId, { key = name })
        end
        self:_reopenKeybindPopover()
    end
end

function UTMenu:_updateKeybinds()
    if self._capturingKeybind then
        self:_pollKeybindCapture()
        return
    end

    local keyboard = Input:keyboard()
    local currentDown = {}

    for _, key in pairs(keyboard:down_list()) do
        local id = keyboard:button_name(key)
        local name = keyboard:button_name_str(id)
        if name and name ~= "" then
            currentDown[name] = true
        end
    end

    if not self.isOpen then
        local mouse = Input:mouse()
        for _, key in pairs(mouse:down_list()) do
            local id = mouse:button_name(key)
            local name = mouse:button_name_str(id)
            if name and name ~= "" then
                if not UT.Utility:stringStartsWith(name, "mouse wheel ") then
                    name = "mouse " .. name
                end
                currentDown[name] = true
            end
        end
    end

    for _, bind in ipairs(UT.nativeKeybinds) do
        local widget = self:_findKeybindWidget(bind.widgetId)

        if widget then
            local wasDown = self._keybindKeysDown[bind.key]
            local isDown = currentDown[bind.key]

            if bind.mode == "hold" then
                if isDown and not wasDown then
                    self:_fireKeybind(widget, bind)
                elseif wasDown and not isDown then
                    widget:revertKeybindOverride()
                end
            elseif bind.mode == "toggle" then
                if isDown and not wasDown then
                    if widget.activeKeybind and widget.activeKeybind.id == bind.id then
                        widget:revertKeybindOverride()
                    else
                        self:_fireKeybind(widget, bind)
                    end
                end
            else
                if isDown and not wasDown then
                    self:_fireKeybind(widget, bind)
                end
            end
        end
    end

    self._keybindKeysDown = currentDown
end

function UTMenu:_ensureTooltip()
    if not self._tooltipPanel then
        self._tooltipPanel = self._mainFrame:panel({ name = "tooltip", layer = self.popoverLayer + 1, visible = false })

        local background = self._tooltipPanel:rect({ name = "background", color = UTTheme.PopoverBackground })
        background:set_shape(0, 0, 1, 1)

        local text = self._tooltipPanel:text({
            name = "text",
            layer = 1,
            font = tweak_data.menu.pd2_small_font,
            font_size = tweak_data.menu.pd2_small_font_size,
            color = UTTheme.TextPrimary,
            vertical = "center"
        })

        self._tooltipBackground = background
        self._tooltipText = text
    end
end

function UTMenu:_showTooltip(x, y, text)
    self:_ensureTooltip()

    self._tooltipText:set_text(text)

    local width = 16 + string.len(text) * 6
    self._tooltipBackground:set_shape(0, 0, width, 20)
    self._tooltipText:set_shape(8, 0, width - 16, 20)

    local localX = math.clamp(x - self._mainFrame:world_x() + 8, 0, self.width - width)
    local localY = math.clamp(y - self._mainFrame:world_y() - 24, 0, self.height - 20)

    self._tooltipPanel:set_shape(localX, localY, width, 20)
    self._tooltipPanel:set_visible(true)
end

function UTMenu:_hideTooltip()
    if self._tooltipPanel then
        self._tooltipPanel:set_visible(false)
    end
end

function UTMenu:_openPopover(originX, originY, width, height, buildContentFn)
    self:_closePopover()
    self._popoverIsKeybindManager = false

    originX = math.clamp(originX, 0, math.max(0, self.width - width))
    originY = math.clamp(originY, 0, math.max(0, self.height - height))

    local popover = self._mainFrame:panel({ name = "popover", layer = self.popoverLayer })
    popover:set_shape(originX, originY, width, height)

    local background = popover:rect({ name = "background", color = UTTheme.PopoverBackground })
    background:set_shape(0, 0, width, height)
    self:draw_border(popover, UTTheme.Border)

    self._activePopover = popover
    self._activePopoverWidth = width
    self._activePopoverOrigin = { x = originX, y = originY }
    self._popoverSliders = {}
    self._popoverToggles = {}
    self._popoverButtons = {}
    self._popoverHotkeyRows = {}

    buildContentFn(popover, width)
end

function UTMenu:_closePopover()
    self:_hideNewBindPreview()

    if self._activePopover then
        self._mainFrame:remove(self._activePopover)
        self._activePopover = nil
        self._activePopoverWidth = nil
        self._activePopoverOrigin = nil
        self._popoverSliders = {}
        self._popoverToggles = {}
        self._popoverButtons = {}
        self._popoverHotkeyRows = {}
    end
end

function UTMenu:_buildSettingsPopoverContent(popoverPanel, popoverWidth)
    local placeholder = popoverPanel:text({
        name = "placeholder",
        layer = 1,
        font = tweak_data.menu.pd2_small_font,
        font_size = tweak_data.menu.pd2_small_font_size,
        text = "No settings yet",
        color = UTTheme.TextSecondary,
        vertical = "top"
    })
    placeholder:set_shape(12, 12, popoverWidth - 24, 20)
end

function UTMenu:create_slider(parent, parentWidth, yOffset, title, min, max, currentVal, step, callback, defaultVal, decimals, id, liveBaseline)
    local rowWidth = parentWidth - 48

    local function formatValue(value)
        if liveBaseline then
            local delta = math.round(value * 100)
            local sign = delta >= 0 and "+" or ""
            return sign .. tostring(delta) .. "%"
        end
        return tostring(value)
    end

    local row = parent:panel({ name = "slider_" .. tostring(#self._sliders + 1) })
    row:set_shape(24, yOffset, rowWidth, self.sliderRowHeight)

    local hover = row:rect({ name = "hover", color = UTTheme.Hover, visible = false })
    hover:set_shape(0, 0, rowWidth, self.sliderRowHeight)

    local titleText = row:text({
        name = "title",
        layer = 1,
        font = tweak_data.menu.pd2_medium_font,
        font_size = tweak_data.menu.pd2_medium_font_size,
        text = title,
        color = UTTheme.TextSecondary,
        vertical = "center"
    })
    titleText:set_shape(0, 0, rowWidth / 2, 20)

    if decimals then
        local multiplier = 10 ^ decimals
        currentVal = math.round(currentVal * multiplier) / multiplier
    end

    local valueText = row:text({
        name = "value",
        layer = 1,
        font = tweak_data.menu.pd2_medium_font,
        font_size = tweak_data.menu.pd2_medium_font_size,
        text = formatValue(currentVal),
        color = UTTheme.TextPrimary,
        align = "right",
        vertical = "center"
    })
    valueText:set_shape(rowWidth / 2, 0, rowWidth / 2, 20)

    local track = row:rect({
        name = "track",
        color = UTTheme.TextSecondary
    })
    track:set_shape(0, 30, rowWidth, self.sliderTrackHeight)

    local fill = row:rect({
        name = "fill",
        color = UTTheme.Accent
    })
    fill:set_shape(0, 30, rowWidth * (currentVal - min) / (max - min), self.sliderTrackHeight)

    local indicator = row:rect({ name = "keybind_indicator", color = UTTheme.Accent, visible = false })
    indicator:set_shape(rowWidth - 6, 30 - 10, 6, 6)

    local slider = {
        panel = row,
        hover = hover,
        track = track,
        fill = fill,
        valueText = valueText,
        indicator = indicator,
        title = title,
        min = min,
        max = max,
        step = step,
        value = currentVal,
        decimals = decimals,
        default_val = defaultVal or currentVal,
        callback = callback,
        id = id,
        activeKeybind = nil,
        liveBaseline = liveBaseline,
        x = 24,
        y = yOffset
    }

    function slider:refreshLiveDisplay()
        if self.liveBaseline and not self.focused and alive(self.valueText) then
            self.valueText:set_text(formatValue(self.value))
        end
    end

    function slider:applyKeybindValue(bind, value)
        self.activeKeybind = bind
        if alive(self.indicator) then
            self.indicator:set_visible(true)
        end
        if self.callback then
            self.callback(value)
        end
    end

    function slider:revertKeybindOverride()
        self.activeKeybind = nil
        if alive(self.indicator) then
            self.indicator:set_visible(false)
        end
        if self.callback then
            self.callback(self.value)
        end
    end

    if id then
        UTMenu._boundWidgets[id] = slider
    end

    function slider:setValue(newValue)
        newValue = math.clamp(newValue, self.min, self.max)

        if self.decimals then
            local multiplier = 10 ^ self.decimals
            newValue = math.round(newValue * multiplier) / multiplier
        end

        if newValue == self.value then
            return
        end

        self.value = newValue

        if alive(self.fill) and alive(self.track) then
            self.fill:set_w(self.track:w() * (self.value - self.min) / (self.max - self.min))
        end
        if alive(self.valueText) then
            self.valueText:set_text(formatValue(self.value))
        end

        if self.callback then
            self.callback(self.value)
        end
    end

    function slider:setValueByPercent(percent)
        percent = math.clamp(percent, 0, 1)
        local raw = self.min + (self.max - self.min) * percent
        local stepped = math.clamp(self.min + math.round((raw - self.min) / self.step) * self.step, self.min, self.max)
        self:setValue(stepped)
    end

    function slider:setValueFromMouseX(x)
        local left, right = self.track:world_left(), self.track:world_right()
        self:setValueByPercent((x - left) / (right - left))
    end

    function slider:resetToDefault()
        self:setValue(self.default_val)
    end

    slider.focused = false
    slider.editValue = nil

    function slider:_refreshEditDisplay()
        if alive(self.valueText) then
            self.valueText:set_text(self.editValue .. "|")
        end
    end

    function slider:appendDigit(digit)
        if digit == "." then
            if not self.decimals or self.decimals == 0 or self.editValue:find(".", 1, true) then
                return
            end
        end
        if #self.editValue >= 12 then
            return
        end
        self.editValue = self.editValue .. digit
        self:_refreshEditDisplay()
    end

    function slider:backspace()
        self.editValue = self.editValue:sub(1, -2)
        self:_refreshEditDisplay()
    end

    function slider:commit()
        local numeric = tonumber(self.editValue)
        self.editValue = nil
        if numeric then
            self:setValue(numeric)
        end
        if alive(self.valueText) then
            self.valueText:set_text(formatValue(self.value))
        end
    end

    function slider:setFocused(focused)
        self.focused = focused
        if focused then
            self.editValue = tostring(self.value)
            self:_refreshEditDisplay()
        else
            self:commit()
        end
    end

    valueText:enter_text(function(...)
        if UTMenu._focusedNumberInput ~= slider then
            return
        end

        local args = { ... }
        local s = args[#args]

        if s and (tonumber(s) or s == ".") then
            slider:appendDigit(s)
        end
    end)

    return slider
end

function UTMenu:_refreshContentVisibility()
    self:_closePopover()
    self:_blurNumberInput()

    for _, toggle in ipairs(self._featureToggles) do
        toggle.panel:set_visible(toggle.tab == self.activeTab and toggle.subTab == self.activeSubTab)
    end

    for _, slider in ipairs(self._sliders) do
        slider.panel:set_visible(slider.tab == self.activeTab and slider.subTab == self.activeSubTab)
    end

    for _, btn in ipairs(self._actionButtons) do
        btn.panel:set_visible(btn.tab == self.activeTab and btn.subTab == self.activeSubTab)
    end

    for _, row in ipairs(self._numberInputRows) do
        row.panel:set_visible(row.tab == self.activeTab and row.subTab == self.activeSubTab)
    end

    for _, pill in ipairs(self._entitiesPositionPills) do
        pill.panel:set_visible(pill.tab == self.activeTab and pill.subTab == self.activeSubTab)
    end
end

function UTMenu:_refreshTabStyles()
    for _, row in ipairs(self._tabRows) do
        local isActive = row.name == self.activeTab
        row.text:set_color(isActive and UTTheme.Accent or UTTheme.TextSecondary)
        row.marker:set_visible(isActive)
    end
end

function UTMenu:setActiveTab(tabName)
    if tabName == self.activeTab then
        return
    end

    self.activeTab = tabName
    self.activeSubTab = self.subTabsByTab[tabName][1]
    self:_refreshTabStyles()
    self:_rebuildSubTabPills()
    self:_refreshContentVisibility()
end

function UTMenu:open()
    if self.isOpen or not self._mainFrame then
        return
    end

    self:_repositionFrame()

    self.isOpen = true
    self._mainFrame:set_visible(true)

    managers.mouse_pointer:use_mouse({
        mouse_move = callback(self, self, "_onMouseMove"),
        mouse_press = callback(self, self, "_onMousePress"),
        mouse_release = callback(self, self, "_onMouseRelease"),
        mouse_wheel_up = callback(self, self, "_onMouseWheelUp"),
        mouse_wheel_down = callback(self, self, "_onMouseWheelDown"),
        id = self._mouseId
    })

    if game_state_machine and game_state_machine:current_state() then
        game_state_machine:current_state():set_controller_enabled(false)
    end
end

function UTMenu:close()
    if not self.isOpen then
        return
    end

    self.isOpen = false
    self._mainFrame:set_visible(false)
    self._draggingSlider = nil
    self:_blurNumberInput()
    self:_closePopover()

    managers.mouse_pointer:remove_mouse(self._mouseId)

    if game_state_machine and game_state_machine:current_state() then
        game_state_machine:current_state():set_controller_enabled(true)
    end
end

function UTMenu:toggle()
    if self.isOpen then
        self:close()
    else
        self:open()
    end
end

function UTMenu:_updateHoverList(list, x, y, filterByActiveTab, useAlpha)
    for _, item in ipairs(list) do
        if item.hover and alive(item.hover) then
            local eligible = not filterByActiveTab or (item.tab == self.activeTab and item.subTab == self.activeSubTab)
            local shouldShow = eligible and alive(item.panel) and item.panel:inside(x, y)
            if useAlpha then
                item.hover:set_alpha(shouldShow and 1 or 0)
            else
                item.hover:set_visible(shouldShow)
            end
        end
    end
end

function UTMenu:_onMouseMove(o, x, y)
    self._lastMouseX = x
    self._lastMouseY = y

    for _, row in ipairs(self._tabRows) do
        row.hover:set_visible(row.panel:inside(x, y))
    end

    if self._activePopover then
        self:_updateHoverList(self._popoverSliders, x, y, false)
        self:_updateHoverList(self._popoverToggles, x, y, false)
        self:_updateHoverList(self._popoverButtons, x, y, false)
    else
        self:_updateHoverList(self._featureToggles, x, y, true, true)
        self:_updateHoverList(self._sliders, x, y, true)
        self:_updateHoverList(self._actionButtons, x, y, true)
        self:_updateHoverList(self._numberInputs, x, y, true)
        self:_updateHoverList(self._entitiesPositionPills, x, y, true)
        self:_updateHoverList(self._subTabPills, x, y, false)
    end

    if self._draggingSlider then
        self._draggingSlider:setValueFromMouseX(x)
    end

    if self._keybindEditor and (self._keybindEditor.step == "global" or self._keybindEditor.step == "menu") then
        local hoveredRow = nil

        for _, row in ipairs(self._popoverHotkeyRows) do
            local isHovered = alive(row.panel) and row.panel:inside(x, y)
            if alive(row.background) then
                row.background:set_visible(isHovered)
            end
            if isHovered then
                hoveredRow = row
            end
        end

        if hoveredRow then
            self:_showHotkeyRowPreview(hoveredRow)
        else
            self:_hideNewBindPreview()
        end
    else
        self:_hideNewBindPreview()
    end

    local hovered = nil

    if self._activePopover then
        for _, slider in ipairs(self._popoverSliders) do
            if slider.activeKeybind and alive(slider.indicator) and slider.indicator:inside(x, y) then
                hovered = slider
                break
            end
        end

        if not hovered then
            for _, toggle in ipairs(self._popoverToggles) do
                if toggle.activeKeybind and alive(toggle.indicator) and toggle.indicator:inside(x, y) then
                    hovered = toggle
                    break
                end
            end
        end
    else
        for _, toggle in ipairs(self._featureToggles) do
            if toggle.activeKeybind and toggle.tab == self.activeTab and toggle.subTab == self.activeSubTab and alive(toggle.indicator) and toggle.indicator:inside(x, y) then
                hovered = toggle
                break
            end
        end

        if not hovered then
            for _, slider in ipairs(self._sliders) do
                if slider.activeKeybind and slider.tab == self.activeTab and slider.subTab == self.activeSubTab and alive(slider.indicator) and slider.indicator:inside(x, y) then
                    hovered = slider
                    break
                end
            end
        end
    end

    if hovered then
        self:_showTooltip(x, y, self:_describeBind(hovered.activeKeybind))
    else
        self:_hideTooltip()
    end

    return true, "pointer"
end

function UTMenu:_onMouseWheel(direction)
    if not self.isOpen then
        return
    end

    local x, y = self._lastMouseX, self._lastMouseY
    if not x or not y then
        return
    end

    for _, slider in ipairs(self._sliders) do
        if slider.tab == self.activeTab and slider.subTab == self.activeSubTab and alive(slider.panel) and slider.panel:inside(x, y) then
            if not slider.focused then
                slider:setValue(slider.value + slider.step * direction)
            end
            break
        end
    end
end

function UTMenu:_onMouseWheelUp(o, x, y)
    self:_onMouseWheel(1)
end

function UTMenu:_onMouseWheelDown(o, x, y)
    self:_onMouseWheel(-1)
end

function UTMenu:_onMousePress(o, button, x, y)
    if button == Idstring("0") then
        if self._activePopover then
            if not self._activePopover:inside(x, y) then
                self:_closePopover()
            else
                for _, slider in ipairs(self._popoverSliders) do
                    if slider.panel:inside(x, y) then
                        self._draggingSlider = slider
                        slider:setValueFromMouseX(x)
                        break
                    end
                end

                for _, toggle in ipairs(self._popoverToggles) do
                    if toggle.toggleArea:inside(x, y) then
                        toggle:setState(not toggle.state)
                        break
                    end
                end

                local clickedButton = false
                for _, btn in ipairs(self._popoverButtons) do
                    if btn.panel:inside(x, y) then
                        btn:click()
                        clickedButton = true
                        break
                    end
                end

                if not clickedButton then
                    for _, row in ipairs(self._popoverHotkeyRows) do
                        if row.panel:inside(x, y) then
                            self:_openHotkeyRowEditor(row)
                            break
                        end
                    end
                end
            end
        else
            if self._settingsGear and self._settingsGear:inside(x, y) then
                self:_openPopover(8, self.height - self.footerHeight - self.settingsPopoverHeight - 8, self.popoverWidth, self.settingsPopoverHeight, function(popoverPanel, popoverWidth)
                    self:_buildSettingsPopoverContent(popoverPanel, popoverWidth)
                end)
                return true
            end

            local clickedNumberInput = nil
            for _, input in ipairs(self._numberInputs) do
                if input.tab == self.activeTab and input.subTab == self.activeSubTab and input.panel:inside(x, y) then
                    clickedNumberInput = input
                    break
                end
            end

            if clickedNumberInput then
                self:_focusNumberInput(clickedNumberInput)
                return true
            elseif self._focusedNumberInput then
                self:_blurNumberInput()
            end

            for _, row in ipairs(self._tabRows) do
                if row.panel:inside(x, y) then
                    self:setActiveTab(row.name)
                    break
                end
            end

            for _, pill in ipairs(self._subTabPills) do
                if pill.panel:inside(x, y) then
                    self:setActiveSubTab(pill.name)
                    break
                end
            end

            for _, pill in ipairs(self._entitiesPositionPills) do
                if pill.tab == self.activeTab and pill.subTab == self.activeSubTab and pill.panel:inside(x, y) then
                    self:_setEntitiesPositionType(pill.id)
                    break
                end
            end

            for _, toggle in ipairs(self._featureToggles) do
                if toggle.tab == self.activeTab and toggle.subTab == self.activeSubTab then
                    if toggle.gearButton and toggle.gearButton:inside(x, y) then
                        self:_openPopover(self.sidebarWidth + toggle.x, toggle.y + self.cardHeight + 4, toggle.popoverWidth or self.popoverWidth, toggle.popoverHeight, toggle.buildPopoverContent)
                        break
                    elseif toggle.toggleArea:inside(x, y) then
                        toggle:setState(not toggle.state)
                        break
                    end
                end
            end

            for _, btn in ipairs(self._actionButtons) do
                if btn.tab == self.activeTab and btn.subTab == self.activeSubTab and btn.panel:inside(x, y) then
                    btn:click()
                    break
                end
            end

            for _, slider in ipairs(self._sliders) do
                if slider.tab == self.activeTab and slider.subTab == self.activeSubTab and slider.panel:inside(x, y) then
                    if alive(slider.valueText) and slider.valueText:inside(x, y) then
                        self:_focusNumberInput(slider)
                    else
                        self._draggingSlider = slider
                        slider:setValueFromMouseX(x)
                    end
                    break
                end
            end
        end
    elseif button == Idstring("1") then
        if self._activePopover and self._popoverIsKeybindManager then
            -- right-click inside the keybind manager itself does nothing
        elseif self._activePopover then
            local target = nil
            local widgetType = nil

            for _, slider in ipairs(self._popoverSliders) do
                if slider.id and slider.panel:inside(x, y) then
                    target = slider
                    widgetType = "slider"
                    break
                end
            end

            if not target then
                for _, toggle in ipairs(self._popoverToggles) do
                    if toggle.id and toggle.panel:inside(x, y) then
                        target = toggle
                        widgetType = "toggle"
                        break
                    end
                end
            end

            if not target then
                for _, btn in ipairs(self._popoverButtons) do
                    if btn.id and btn.panel:inside(x, y) then
                        target = btn
                        widgetType = "action"
                        break
                    end
                end
            end

            if target and self._activePopoverOrigin then
                self:_openKeybindManager(target, widgetType, self._activePopoverOrigin.x, self._activePopoverOrigin.y)
            end
        else
            local target = nil
            local widgetType = nil

            for _, toggle in ipairs(self._featureToggles) do
                if toggle.id and toggle.tab == self.activeTab and toggle.subTab == self.activeSubTab and toggle.panel:inside(x, y) then
                    target = toggle
                    widgetType = "toggle"
                    break
                end
            end

            if not target then
                for _, slider in ipairs(self._sliders) do
                    if slider.id and slider.tab == self.activeTab and slider.subTab == self.activeSubTab and slider.panel:inside(x, y) then
                        target = slider
                        widgetType = "slider"
                        break
                    end
                end
            end

            if not target then
                for _, btn in ipairs(self._actionButtons) do
                    if btn.id and btn.tab == self.activeTab and btn.subTab == self.activeSubTab and btn.panel:inside(x, y) then
                        target = btn
                        widgetType = "action"
                        break
                    end
                end
            end

            if target then
                local anchorX = self.sidebarWidth + target.x
                local anchorY = target.y + self:_widgetRowHeight(widgetType) + 4
                self:_openKeybindManager(target, widgetType, anchorX, anchorY)
            end
        end
    end

    return true
end

function UTMenu:_onMouseRelease(o, button, x, y)
    self._draggingSlider = nil

    return true
end

function UTMenu:_setEntitiesPositionType(positionType)
    self._entitiesPositionType = positionType

    for _, pill in ipairs(self._entitiesPositionPills) do
        pill.text:set_color(pill.id == positionType and UTTheme.Accent or UTTheme.TextSecondary)
    end
end

function UTMenu:_onKeyPress(o, k)
    if not self.isOpen then
        return
    end

    if self._focusedNumberInput then
        if k == Idstring("backspace") then
            self._focusedNumberInput:backspace()
        elseif k == Idstring("enter") or k == Idstring("esc") then
            self:_blurNumberInput()
        end
    end

    return true
end

function UTMenu:update()
    if not self._mainFrame then
        self:_build()
    end

    if not self._mainFrame then
        return
    end

    if UT.GameUtility:isInPauseMenu() or UT.GameUtility:isInChat() or UT.GameUtility:isListeningToInput() then
        return
    end

    if self.isOpen and game_state_machine and game_state_machine:current_state() then
        game_state_machine:current_state():set_controller_enabled(false)
    end

    local wasCapturingKeybind = self._capturingKeybind
    self:_updateKeybinds()
    if wasCapturingKeybind then
        return
    end

    local keyboard = Input:keyboard()

    local insertDown = keyboard:down(UT.GameUtility:idString("insert"))
    if insertDown and not self._insertKeyWasDown then
        self:toggle()
    end
    self._insertKeyWasDown = insertDown

    local deleteDown = keyboard:down(UT.GameUtility:idString("delete"))
    if deleteDown and not self._deleteKeyWasDown then
        self:toggle()
    end
    self._deleteKeyWasDown = deleteDown

    if self.isOpen then
        self._liveSliderRefreshFrame = (self._liveSliderRefreshFrame or 0) + 1
        if self._liveSliderRefreshFrame % 15 == 0 then
            for _, slider in ipairs(self._sliders) do
                if slider.liveBaseline then
                    slider:refreshLiveDisplay()
                end
            end
        end
    end
end
