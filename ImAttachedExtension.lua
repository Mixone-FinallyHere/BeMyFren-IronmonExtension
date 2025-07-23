local function ImAttachedExtension()
	local self = {}
	-- Define descriptive attributes of the custom extension that are displayed on the Tracker settings
	self.version = "1.3"
	self.name = "I'm Attached!"
	self.author = "UTDZac"
	self.description = "This simple extension adds a heart button to the Tracker screen, to let everyone know that you're attached to your " .. Constants.Words.POKEMON .. "."
	self.url = "https://github.com/UTDZac/ImAttached-IronmonExtension" -- Remove or set to nil if no host website available for this extension

	-- Converts "FFFFFF" to a numerical value
	local function hexToColor(hexCode)
		if type(hexCode) ~= "string" then return 0x00000000 end
		local colorValue = tonumber(hexCode, 16)
		if colorValue == nil then return 0x00000000 end
		return 0xFF000000 + colorValue
	end
	-- Converts a numerical color value to a hex color code "FFFFFF"
	local function colorToHex(colorValue)
		if type(colorValue) ~= "number" then return "000000" end
		return string.sub(string.format("%#x", colorValue), 5)
	end

	-- key:PokemonObject, value = true/false
	self.attachedPokemon = {}
	self.Heart = {
		x = Constants.SCREEN.WIDTH + Constants.SCREEN.MARGIN + 84,
		y = Constants.SCREEN.MARGIN + 11,
		defaultBorder = 0xFFBA0000, -- dark red
		defaultFill = 0xFFFF0000, -- red
		defaultShine = 0xFFFFFFFF, -- white
	}
	self.Options = {
		settingsName = "ImAttached", -- to be prepended to all other settings here
		heartFillColor = colorToHex(self.Heart.defaultFill),
	}

	local function clickImAttached()
		local viewedPokemon = Battle.getViewedPokemon(true) or {}
		if not PokemonData.isValid(viewedPokemon.pokemonID) then
			return
		end

		-- TODO: do the thing
		if not self.attachedPokemon[viewedPokemon.personality] then
			self.attachedPokemon[viewedPokemon.personality] = true
		else
			self.attachedPokemon[viewedPokemon.personality] = nil
		end
		Program.redraw(true)
	end

	local function isAttachedToLeadPokemon()
		local viewedPokemon = Battle.getViewedPokemon(true) or {}
		return self.attachedPokemon[viewedPokemon.personality or false]
	end

	local function loadOptions()
		-- Load options from the Settings file
		self.Options.heartFillColor = TrackerAPI.getExtensionSetting(self.Options.settingsName, "heartFillColor") or self.Options.heartFillColor

		-- Apply the loaded options
		if self.Options.heartFillColor ~= nil then
			local colorValue = hexToColor(self.Options.heartFillColor)
			self.Heart.defaultFill = colorValue
			self.Heart.defaultBorder = Utils.calcGrayscale(colorValue, 0.6)
		end
	end

	local function saveOptions()
		-- Save options to the Settings file
		TrackerAPI.saveExtensionSetting(self.Options.settingsName, "heartFillColor", self.Options.heartFillColor)
	end

	local function applyOptionsCallback(formInput)
		if formInput == nil or formInput == "" or tonumber(formInput, 16) == nil then
			return
		end

		if self.Options.heartFillColor ~= formInput then
			self.Options.heartFillColor = formInput
			local colorValue = hexToColor(formInput)
			self.Heart.defaultFill = colorValue
			self.Heart.defaultBorder = Utils.calcGrayscale(colorValue, 0.8)
			saveOptions()
		end

		self.textBox = nil
		self.picBox = nil
	end

	local function refreshColorBox()
		if self.textBox == nil or self.picBox == nil then return end
		local formInput = forms.gettext(self.textBox)
		if #formInput ~= 6 then return end

		local colorBoxSize = 20
		local colorValue = hexToColor(formInput)
		forms.drawRectangle(self.picBox, 0, 0, colorBoxSize, colorBoxSize, nil, colorValue)
		forms.refresh(self.picBox)
	end

	local function openOptionsPopup()
		if not Main.IsOnBizhawk() then return end
		Program.destroyActiveForm()
		local form = forms.newform(320, 130, "I'm Attached Settings", function() client.unpause() end)
		Program.activeFormId = form
		Utils.setFormLocation(form, 100, 50)

		local colorBoxSize = 20

		forms.label(form, "Set the color for the heart icon:", 48, 10, 300, 20)
		self.textBox = forms.textbox(form, self.Options.heartFillColor, 200, 30, "HEX", 50, 30)
		self.picBox = forms.pictureBox(form, 20, 30, colorBoxSize, colorBoxSize)
		refreshColorBox()

		forms.button(form, "Save", function()
			local formInput = forms.gettext(self.textBox)
			applyOptionsCallback(formInput)
			client.unpause()
			forms.destroy(form)
		end, 72, 60)
		forms.button(form, "Cancel", function()
			client.unpause()
			forms.destroy(form)
		end, 157, 60)
	end

	local heartPixelImage = { -- 12x12
		{0,0,1,1,0,0,0,1,1,0,0,},
		{0,1,2,2,1,0,1,2,2,1,0,},
		{1,2,3,3,2,1,2,2,2,2,1,},
		{1,2,3,2,2,2,2,2,2,2,1,},
		{1,2,2,2,2,2,2,2,2,2,1,},
		{0,1,2,2,2,2,2,2,2,1,0,},
		{0,0,1,2,2,2,2,2,1,0,0,},
		{0,0,0,1,2,2,2,1,0,0,0,},
		{0,0,0,0,1,2,1,0,0,0,0,},
		{0,0,0,0,0,1,0,0,0,0,0,},
	}
	local heartBtn = {
		type = Constants.ButtonTypes.PIXELIMAGE,
		textColor = "Default text",
		box = { self.Heart.x, self.Heart.y, 12, 12 },
		isVisible = function()
			local allowedLegacy = (Program.Screens ~= nil and Program.currentScreen == Program.Screens.TRACKER)
			local allowedCurrent = (Program.currentScreen == TrackerScreen)
			local viewedPokemon = Battle.getViewedPokemon(true) or {}
			return Tracker.Data.isViewingOwn and (allowedLegacy or allowedCurrent) and PokemonData.isValid(viewedPokemon.pokemonID)
		end,
		draw = function()
			self.colors = self.colors or {}
			local shadowcolor = Utils.calcShadowColor(Theme.COLORS["Upper box background"])
			local colors
			if isAttachedToLeadPokemon() then
				colors = {
					self.colors[1] or self.Heart.defaultBorder,
					self.colors[2] or self.Heart.defaultFill,
					self.colors[3] or self.Heart.defaultShine,
				}
			else
				colors = {
					Theme.COLORS["Default text"],
					Theme.COLORS["Upper box background"],
					Theme.COLORS["Upper box background"],
				}
			end
			Drawing.drawImageAsPixels(heartPixelImage, self.Heart.x, self.Heart.y, colors, shadowcolor)
		end,
		onClick = function() clickImAttached() end
	}

	-- Executed when the user clicks the "Options" button while viewing the extension details within the Tracker's UI
	-- Remove this function if you choose not to include a way for the user to configure options for your extension
	function self.configureOptions()
		openOptionsPopup()
	end

	-- Executed when the user clicks the "Check for Updates" button while viewing the extension details within the Tracker's UI
	-- Returns [true, downloadUrl] if an update is available (downloadUrl auto opens in browser for user); otherwise returns [false, downloadUrl]
	-- Remove this function if you choose not to implement a version update check for your extension
	function self.checkForUpdates()
		local versionCheckUrl = "https://api.github.com/repos/UTDZac/ImAttached-IronmonExtension/releases/latest"
		local versionResponsePattern = '"tag_name":%s+"%w+(%d+%.%d+)"' -- matches "1.0" in "tag_name": "v1.0"
		local downloadUrl = "https://github.com/UTDZac/ImAttached-IronmonExtension/releases/latest"

		local isUpdateAvailable = Utils.checkForVersionUpdate(versionCheckUrl, self.version, versionResponsePattern, nil)
		return isUpdateAvailable, downloadUrl
	end

	-- Executed only once: When the extension is enabled by the user, and/or when the Tracker first starts up, after it loads all other required files and code
	function self.startup()
		if not Main.IsOnBizhawk() then return end
		loadOptions()
		TrackerScreen.Buttons.HeartButton = heartBtn
	end

	-- Executed only once: When the extension is disabled by the user, necessary to undo any customizations, if able
	function self.unload()
		if not Main.IsOnBizhawk() then return end
		TrackerScreen.Buttons.HeartButton = nil
	end

	-- Executed once every 30 frames or after any redraw event is scheduled (i.e. most button presses)
	function self.afterRedraw()
		if not Main.IsOnBizhawk() then return end
		if TrackerScreen.Buttons.HeartButton ~= nil and TrackerScreen.Buttons.HeartButton:isVisible() then
			local shadowcolor = Utils.calcShadowColor(Theme.COLORS["Upper box background"])
			Drawing.drawButton(TrackerScreen.Buttons.HeartButton, shadowcolor)
		end
		refreshColorBox()
	end

	return self
end
return ImAttachedExtension