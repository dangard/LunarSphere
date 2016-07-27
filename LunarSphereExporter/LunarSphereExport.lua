-- /***********************************************
--  * LunarSphere Exporter Module
--  *********************
--
--  Author	: Moongaze (Twisting Nether)
--  Description	: Handles the exporting of data from LunarSphere into a file that can
--                be placed into the LunarSphere folder and imported into another
--                user's LunarSphere installation
--
--  ***********************************************/

-- /***********************************************
--  * Module Setup
--  *********************

Lunar = Lunar or {};

-- Create our Export object

if (not Lunar.Export) then
	Lunar.Export = {};
end

Lunar.Export.version = 1.26;

function Lunar.Export:ExportData(dataType, arg1, arg2)

	-- If our export database doesn't exist, make it now

	if not (LunarSphereExport) then
		LunarSphereExport = {};
	end

	-- If arg1 is true, we will wipe our export data
	-- if it already exists. This is to make sure our
	-- export data is pure. If arg1 is false, or not
	-- defined, we will just be appending to the data

	local i, v;

	if (LunarSphereExport[dataType]) and (arg1 == true) then
--		for i, v in pairs(LunarSphereExport[dataType]) do
			LunarSphereExport[dataType] = nil;
--		end
	end

	-- Based upon the dataType to export, save the data to our
	-- export file.

	local db, xDB;
	local entries, members = 0, 0;
	
	if (dataType == "speech") then

		-- If the speech export database doesn't exist, make it now;

		if not(LunarSphereExport[dataType]) then
			LunarSphereExport[dataType] = {};
		end

		-- Exporting the scripts. Arg1 is a specific script ID.
		-- If Arg2 is omitted, all scripts will be saved.

		if (LunarSpeechLibrary.script) then

			-- Prepare which scriptIDs to export. If arg2
			-- is specified, we only grab that script.

			local startID = 1;
			local endID = table.getn(LunarSpeechLibrary.script);
			if (arg2) then
				startID, endID = arg2, arg2;
			end

			-- Run through each entry that we need to grab and
			-- dump it's data into the export database

			local index, speechIndex, scriptID, isGlobal;
			for index = startID, endID do 

				-- If the local script exists, we dump our script into the export database and
				-- increase our entries. If it does not exist, it must be a global script,
				-- so we find the global index and pull from there. Also track how many members
				-- were added. Note: THIS IS A TABLE COPY, NOT A REFERENCE PASSING. This will
				-- generate a new table per entry.

				if (LunarSpeechLibrary.script[index]) and (LunarSpeechLibrary.script[index].speeches) then
					table.insert(LunarSphereExport[dataType], Lunar.API:CopyTable(LunarSpeechLibrary.script[index].speeches))
					entries = entries + 1;
					members = members + LunarSpeechLibrary.script[index].speeches.speechCount
				else
					scriptID, _, isGlobal = Lunar.Speech:GetLibraryID(Lunar.Speech:GetScriptName(index));
					if (LunarSphereGlobal.script[scriptID]) then
						if (LunarSphereGlobal.script[scriptID].speeches) then
							table.insert(LunarSphereExport[dataType], Lunar.API:CopyTable(LunarSphereGlobal.script[scriptID].speeches))
							entries = entries + 1;
							members = members + LunarSphereGlobal.script[scriptID].speeches.speechCount
						end
					end
				end

			end
		end
	end

	if (dataType == "template") then

		-- If the template export database doesn't exist, make it now;

		if not(LunarSphereExport[dataType]) then
			LunarSphereExport[dataType] = {};
		end

		-- Exporting the template based upon the parameters passed in Arg1.
		-- Arg2 is set up as: (name):::(classType):::(options)

--		collectgarbage();
--		UpdateAddOnMemoryUsage();
--		local total = GetAddOnMemoryUsage("LunarSphereExporter");
--		Lunar.API:Print(total);

		xDB = LunarSphereExport.template
		-- Create our new entry and save the list data into its place
		local id = (table.getn(xDB) or (0))  + 1;

		xDB[id] = {};
		xDB = xDB[id];

		-- Now, we save the pieces that we need.
		local _, _, saveData = string.match(arg2, "(.*):::(.*):::(.*)");
	
		local buttonType, cursorType, objectName, objectTexture, stance, clickType, newName;
		local tempActionName;

		-- First up, the button data
		if (string.sub(saveData, 1, 1) == "1") then
			xDB.buttonData = {};
			db = LunarSphereSettings.buttonData;
			local buttonDataBackup;
			if (db) then
				for i = 0, 130 do 

					-- If we have data, pull it!
					if (db[i] and not db[i].empty) then

						-- copy data
						buttonDataBackup = Lunar.API:CopyTable(db[i]);

						-- The new template system saves button data via spell ID/icon and not spell name/icon
						-- Run thru all click types and stances and convert the spell name into the spell ID.
						for clickType = 1, 3 do 
							for stance = 0, 12 do 
								buttonType, cursorType, objectName, objectTexture = Lunar.Button:GetButtonData(i, stance, clickType);
								-- handle spell/item/macro
								if (buttonType and buttonType == 1 and cursorType == "spell") then
									spellLink = GetSpellLink(objectName)
									if spellLink then
--									print(objectName);
--									print(spellLink);
										newName = "s" .. string.match(spellLink, "spell:(%d+)");
										Lunar.Button:SetButtonData(i, stance, clickType, buttonType, cursorType, newName, objectTexture);
									end
								end
							end
						end

						-- copy corrected data
						xDB.buttonData[i] = Lunar.API:CopyTable(db[i]);

						-- restore old data
						db[i] = buttonDataBackup;

						-- We don't save keybind data, that's for what's coming up next
						xDB.buttonData[i].keybindData = nil;

					end
				end
			end
			xDB.buttonData.mainButtonCount = LunarSphereSettings.mainButtonCount;
		end

		-- Next up, the keybind data
		if (string.sub(saveData, 2, 2) == "1") then
			xDB.keybinds = {};
			db = LunarSphereSettings.buttonData;
			if (db) then
				for i = 0, 130 do 
					if (db[i]) and (db[i].keybindData) then
						xDB.keybinds[i] = db[i].keybindData;
					end
				end
			end
		end

		-- After that, the sphere data
		if (string.sub(saveData, 3, 3) == "1") then
			xDB.sphere = {};
			db = LunarSphereSettings;
			if (db) then
				xDB.sphere.showOuter = db.showOuter;
				xDB.sphere.outerGaugeType = db.outerGaugeType;
				xDB.sphere.outerGaugeAnimate = db.outerGaugeAnimate;

				xDB.sphere.showInner = db.showInner;
				xDB.sphere.innerGaugeType = db.innerGaugeType;
				xDB.sphere.innerGaugeAnimate = db.innerGaugeAnimate;

				xDB.sphere.showAssignedCounts = db.showAssignedCounts;
				xDB.sphere.sphereTextType = db.sphereTextType;

				xDB.sphere.sphereScale = db.sphereScale;

				xDB.sphere.submenuCompression = db.submenuCompression;
				xDB.sphere.buttonOffset = db.buttonOffset;
				xDB.sphere.subMenuButtonDistance = db.subMenuButtonDistance;
				xDB.sphere.menuButtonDistance = db.menuButtonDistance;
				xDB.sphere.buttonDistance = db.buttonDistance;
				xDB.sphere.buttonSpacing = db.buttonSpacing;

				xDB.sphere.sphereTextEnd = db.sphereTextEnd;
				xDB.sphere.showSphereEditGlow = db.showSphereEditGlow;

				xDB.sphere.xOfs = db.xOfs;
				xDB.sphere.yOfs = db.yOfs;
				xDB.sphere.relativePoint = db.relativePoint;

			end
			
		end

		-- Then, the reagent list data
		if (string.sub(saveData, 4, 4) == "1") then
			xDB.reagents = {};
			db = LunarSphereSettings;
			if (db) and (db.reagentList) then
				xDB.reagents = Lunar.API:CopyTable(db.reagentList);
--				for i = 1, table.getn(db.reagentList) do 
--					if (db.reagentList[i]) then
--						xDB.reagents[i] = Lunar.API:CopyTable(db.reagentList[i]);
--					end
--				end
			end
		end

		-- Lastly, the skin data
		if (string.sub(saveData, 5, 5) == "1") then
			xDB.skin = {};
			db = LunarSphereSettings;
			if (db) then
				xDB.skin.gaugeColor = Lunar.API:CopyTable(db.gaugeColor);

				xDB.skin.tooltipBackground = Lunar.API:CopyTable(db.tooltipBackground);
				xDB.skin.tooltipBorder = Lunar.API:CopyTable(db.tooltipBorder);
				xDB.skin.skinAllTooltips = db.skinAllTooltips

				xDB.skin.vividButtons = db.vividButtons;
				xDB.skin.vividMana = Lunar.API:CopyTable(db.vividMana);
				xDB.skin.vividManaRange = Lunar.API:CopyTable(db.vividManaRange);
				xDB.skin.vividRange = Lunar.API:CopyTable(db.vividRange);

				xDB.skin.showButtonShine = db.showButtonShine;
				xDB.skin.buttonSkin = db.buttonSkin;
				xDB.skin.buttonColor = Lunar.API:CopyTable(db.buttonColor);

				xDB.skin.menuButtonColor = Lunar.API:CopyTable(db.menuButtonColor);
	
				xDB.skin.showSphereShine = db.showSphereShine;
				xDB.skin.customSphereColor = db.customSphereColor;
				xDB.skin.sphereSkin = db.sphereSkin;
				xDB.skin.sphereColor = Lunar.API:CopyTable(db.sphereColor);

				xDB.skin.showInnerGaugeShine = db.showInnerGaugeShine;
				xDB.skin.innerMarkSize = db.innerMarkSize;
				xDB.skin.innerMarkDark = db.innerMarkDark;
				xDB.skin.innerGaugeColor = Lunar.API:CopyTable(db.innerGaugeColor);
				xDB.skin.showInnerGaugeShine = db.showInnerGaugeShine;

				xDB.skin.showOuterGaugeShine = db.showOuterGaugeShine;
				xDB.skin.outerMarkSize = db.outerMarkSize;
				xDB.skin.outerMarkDark = db.outerMarkDark;
				xDB.skin.outerGaugeColor = Lunar.API:CopyTable(db.outerGaugeColor);
				xDB.skin.showOuterGaugeShine = db.showOuterGaugeShine;

				xDB.skin.gaugeFill = db.gaugeFill;
				xDB.skin.gaugeBorder = db.gaugeBorder;
				xDB.skin.gaugeBorderColor = Lunar.API:CopyTable(db.gaugeBorderColor);

			end
		end

		-- Prepare memory calculation
		Lunar.Memory:PrepareForCalculation("tempSize");

		Lunar.tempData = Lunar.API:CopyTable(xDB);
		local total = Lunar.Memory:Calculate();
		total = tostring(math.floor(total * 10)/10)
		Lunar.Memory.memoryData.tempSize = nil;
		Lunar.tempData = nil;

		collectgarbage();
--		UpdateAddOnMemoryUsage();
--		total = GetAddOnMemoryUsage("LunarSphereExporter") - total;
--		Lunar.API:Print(GetAddOnMemoryUsage("LunarSphereExporter"));

		xDB.listData = arg2 .. ":::" .. total .. "kb";
		entries = xDB.listData;

	end

	-- Return how many entries and members were exported

	return entries, members;

end
