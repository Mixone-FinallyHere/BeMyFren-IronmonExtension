local function BeMyFrenExtension()
	local self = {}

	-- Define descriptive attributes of the custom extension that are displayed on the Tracker settings
	self.name = "Be My Fren!"
	self.author = "Mixone"
	self.description = "This simple extension adds a heart button to the Tracker screen, to let everyone know that you're attached to your " .. Constants.Words.POKEMON .. "."
	self.version = "1.0"
	self.url = "https://github.com/Mixone-FinallyHere/BeMyFren-IronmonExtension" -- Remove or set to nil if no host website available for this extension

	-- key:PokemonObject, value = true/false
	self.attachedPokemon = {}
	self.oldHappiness = {}
	self.maxHappy = 250
	self.Heart = {
		x = Constants.SCREEN.WIDTH + Constants.SCREEN.MARGIN + 84,
		y = Constants.SCREEN.MARGIN + 11,
		defaultBorder = 0xFFBA0000, -- dark red
		defaultFill = 0xFFFF0000, -- red
		defaultShine = 0xFFFFFFFF, -- white
	}

	-- Set the colors used for the Heart Icon only after startup
	local function setHeartColors(border, fill, shine)
		self.colors = { border, fill, shine, }
	end

	local function getViewedPokemon()
		local viewedPokemon = Battle.getViewedPokemon(true) or Tracker.getDefaultPokemon()
		if viewedPokemon == nil or not PokemonData.isValid(viewedPokemon.pokemonID) then
			return nil
		end
		return viewedPokemon
	end

	local function setHappy()
		local addressOffset = 0
		local personality = Memory.readdword(GameSettings.pstats + addressOffset)
		local startAddress = GameSettings.pstats + addressOffset
		local otid = Memory.readdword(startAddress + 4)
		local magicword = Utils.bit_xor(personality, otid) -- The XOR encryption key for viewing the Pokemon data

		local aux          = personality % 24
		local growthoffset = (MiscData.TableData.growth[aux + 1] - 1) * 12
		local attackoffset = (MiscData.TableData.attack[aux + 1] - 1) * 12
		local effortoffset = (MiscData.TableData.effort[aux + 1] - 1) * 12
		local miscoffset   = (MiscData.TableData.misc[aux + 1] - 1) * 12

		-- Pokemon Data structure: https://bulbapedia.bulbagarden.net/wiki/Pok%C3%A9mon_data_substructures_(Generation_III)
		local growth1 = Utils.bit_xor(Memory.readdword(startAddress + 32 + growthoffset), magicword)
		local growth2 = Utils.bit_xor(Memory.readdword(startAddress + 32 + growthoffset + 4), magicword) -- Experience
		local growth3 = Utils.bit_xor(Memory.readdword(startAddress + 32 + growthoffset + 8), magicword)
		local attack1 = Utils.bit_xor(Memory.readdword(startAddress + 32 + attackoffset), magicword)
		local attack2 = Utils.bit_xor(Memory.readdword(startAddress + 32 + attackoffset + 4), magicword)
		local attack3 = Utils.bit_xor(Memory.readdword(startAddress + 32 + attackoffset + 8), magicword)
		local misc2   = Utils.bit_xor(Memory.readdword(startAddress + 32 + miscoffset + 4), magicword)

		local effort1 = Utils.bit_xor(Memory.readdword(startAddress + 32 + effortoffset), magicword)
		local effort2 = Utils.bit_xor(Memory.readdword(startAddress + 32 + effortoffset + 4), magicword)
		local effort3 = Utils.bit_xor(Memory.readdword(startAddress + 32 + effortoffset + 8), magicword)
		local misc1   = Utils.bit_xor(Memory.readdword(startAddress + 32 + miscoffset), magicword)
		local misc3   = Utils.bit_xor(Memory.readdword(startAddress + 32 + miscoffset + 8), magicword)
		
		local friendship = Utils.getbits(growth3, 8, 8)
		self.oldHappiness = friendship
		friendship = self.maxHappy
		local newGrowth3 = Utils.bit_lshift(friendship, 8)		
        local newcs = Utils.addhalves(growth1) + Utils.addhalves(growth2) + Utils.addhalves(newGrowth3) + Utils.addhalves(attack1) 
				   + Utils.addhalves(attack2) + Utils.addhalves(attack3)+ Utils.addhalves(effort1) + Utils.addhalves(effort2) 
				   + Utils.addhalves(effort3)+ Utils.addhalves(misc1) + Utils.addhalves(misc2) + Utils.addhalves(misc3)
		local newcs = newcs % 65536
		Memory.writeword(startAddress + 32 + growthoffset + 8, Utils.bit_xor(newGrowth3, magicword))
		Memory.writeword(startAddress + 28, newcs)
	end

	local function setOldHappy()
		local addressOffset = 0
		local personality = Memory.readdword(GameSettings.pstats + addressOffset)
		local startAddress = GameSettings.pstats + addressOffset
		local otid = Memory.readdword(startAddress + 4)
		local magicword = Utils.bit_xor(personality, otid) -- The XOR encryption key for viewing the Pokemon data

		local aux          = personality % 24
		local growthoffset = (MiscData.TableData.growth[aux + 1] - 1) * 12
		local attackoffset = (MiscData.TableData.attack[aux + 1] - 1) * 12
		local effortoffset = (MiscData.TableData.effort[aux + 1] - 1) * 12
		local miscoffset   = (MiscData.TableData.misc[aux + 1] - 1) * 12

		-- Pokemon Data structure: https://bulbapedia.bulbagarden.net/wiki/Pok%C3%A9mon_data_substructures_(Generation_III)
		local growth1 = Utils.bit_xor(Memory.readdword(startAddress + 32 + growthoffset), magicword)
		local growth2 = Utils.bit_xor(Memory.readdword(startAddress + 32 + growthoffset + 4), magicword) -- Experience
		local growth3 = Utils.bit_xor(Memory.readdword(startAddress + 32 + growthoffset + 8), magicword)
		local attack1 = Utils.bit_xor(Memory.readdword(startAddress + 32 + attackoffset), magicword)
		local attack2 = Utils.bit_xor(Memory.readdword(startAddress + 32 + attackoffset + 4), magicword)
		local attack3 = Utils.bit_xor(Memory.readdword(startAddress + 32 + attackoffset + 8), magicword)
		local misc2   = Utils.bit_xor(Memory.readdword(startAddress + 32 + miscoffset + 4), magicword)

		local effort1 = Utils.bit_xor(Memory.readdword(startAddress + 32 + effortoffset), magicword)
		local effort2 = Utils.bit_xor(Memory.readdword(startAddress + 32 + effortoffset + 4), magicword)
		local effort3 = Utils.bit_xor(Memory.readdword(startAddress + 32 + effortoffset + 8), magicword)
		local misc1   = Utils.bit_xor(Memory.readdword(startAddress + 32 + miscoffset), magicword)
		local misc3   = Utils.bit_xor(Memory.readdword(startAddress + 32 + miscoffset + 8), magicword)
		
		local friendship = Utils.getbits(growth3, 8, 8)
		friendship = self.oldHappiness
		local newGrowth3 = Utils.bit_lshift(friendship, 8)		
        local newcs = Utils.addhalves(growth1) + Utils.addhalves(growth2) + Utils.addhalves(newGrowth3) + Utils.addhalves(attack1) 
				   + Utils.addhalves(attack2) + Utils.addhalves(attack3)+ Utils.addhalves(effort1) + Utils.addhalves(effort2) 
				   + Utils.addhalves(effort3)+ Utils.addhalves(misc1) + Utils.addhalves(misc2) + Utils.addhalves(misc3)
		local newcs = newcs % 65536
		Memory.writeword(startAddress + 32 + growthoffset + 8, Utils.bit_xor(newGrowth3, magicword))
		Memory.writeword(startAddress + 28, newcs)
	end

	local function clickImAttached()
		local viewedPokemon = getViewedPokemon()
		if viewedPokemon == nil then
			return
		end

		-- TODO: do the thing
		if not self.attachedPokemon[viewedPokemon] then
			self.attachedPokemon[viewedPokemon] = true	
			setHappy()		
		else
			self.attachedPokemon[viewedPokemon] = nil
			setOldHappy()
		end
		Program.redraw(true)
		
	end

	local function isAttachedToLeadPokemon()
		local viewedPokemon = getViewedPokemon()
		if viewedPokemon == nil then
			return false
		end
		return self.attachedPokemon[viewedPokemon]
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
			return Tracker.Data.isViewingOwn and (allowedLegacy or allowedCurrent) and getViewedPokemon() ~= nil
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
		TrackerScreen.Buttons.HeartButton = heartBtn
	end

	-- Executed only once: When the extension is disabled by the user, necessary to undo any customizations, if able
	function self.unload()
		TrackerScreen.Buttons.HeartButton = nil
	end

	-- Executed once every 30 frames, after most data from game memory is read in
	function self.afterProgramDataUpdate()
		-- [ADD CODE HERE]
	end

	-- Executed once every 30 frames or after any redraw event is scheduled (i.e. most button presses)
	function self.afterRedraw()
		if TrackerScreen.Buttons.HeartButton ~= nil and TrackerScreen.Buttons.HeartButton:isVisible() then
			local shadowcolor = Utils.calcShadowColor(Theme.COLORS["Upper box background"])
			Drawing.drawButton(TrackerScreen.Buttons.HeartButton, shadowcolor)
		end
	end

	return self
end
return BeMyFrenExtension