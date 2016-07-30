
-- Abstract: Steamworks Plugin Sample App
-- Version: 1.0
-- Sample code is MIT licensed; see https://www.coronalabs.com/links/code/license
---------------------------------------------------------------------------------------
local composer = require( "composer" )
local steamworks = require( "plugin.steamworks" )
local widget = require( "widget" )
local json = require( "json" )
local controller = require( "classes.controller" )

-- create our overlay scene
local scene = composer.newScene()

-- fetch our sampleUI values
local titleBarBottom = composer.getVariable( "titleBarBottom" )
local appFont = composer.getVariable( "appFont" )
local appFontBold = composer.getVariable( "appFontBold" )

-- forward declare values
local statsGroup 
local distanceTravelled = composer.getVariable( "distanceTravelled" )
local totalSpeed = composer.getVariable( "totalSpeed" )
local speedCount = composer.getVariable( "speedCount" )
local totalGamesPlayed = composer.getVariable( "totalGamesPlayed" )
local feetTravelled = 0

local gamesPlayedText
local feetTravelledText
local averageSpeedText

-- our controller button table
local buttons = {}

-- reset user progress
local function resetProgress()
	steamworks.resetUserProgress()
end

-- Fetch the user progress for the stats we know about
-- The test app supports: NumGames, FeetTraveled, and AverageSpeed.  
-- These values are provided by Steamworks for developers to test against.
local function showStats( steamUserId )

	-- fetch the stat and update the text
	local gamesPlayedStat = steamworks.getUserStatValue( { userSteamId = steamUserId, statName = "NumGames", type = "int" } )

	if not gamesPlayedStat then
		gamesPlayedStat = 0
	end
	gamesPlayedText.text = gamesPlayedStat
	totalGamesPlayed = gamesPlayedStat
	composer.setVariable( "totalGamesPlayed", totalGamesPlayed )

	local feetTravelledStat = steamworks.getUserStatValue( { userSteamId = steamUserId, statName = "FeetTraveled", type = "float" } )
	if not feetTravelledStat then
		feetTravelledStat = 0
	end
	distanceTravelled = math.floor( feetTravelledStat * 100 ) / 100
	feetTravelledText.text = distanceTravelled
	composer.setVariable( "distanceTravelled", distanceTravelled )

	local averageSpeedStat = steamworks.getUserStatValue( { userSteamId = steamUserId, statName = "AverageSpeed", type = "averageRate" })
	if not averageSpeedStat then
		averageSpeedStat = 0
	end
	averageSpeedText.text = math.floor( averageSpeedStat * 100 ) / 100

end


-- Called when user achievement/stat data has been received
local function onUserProgressUpdated( event )
    -- Do not continue if fetching user progression data failed
    if ( event.isError ) then
        return
    end

    -- We're only interested in the currently logged in user's stats (ignore info from other users)
    if ( event.userSteamId == steamworks.userSteamId ) then
        showStats( event.userSteamId )
    end
end

-- Button handler function
-- save all the values back to composer so that if we come back to the scene 
-- our previous progress was retained.
local function handleButton( event )

	local target = event.target

	-- look at the ID to determine the action the function will take.
	if ( target.id == "playonegame" ) then
		totalGamesPlayed = totalGamesPlayed + 1
		composer.setVariable( "totalGamesPlayed", totalGamesPlayed )
		local wasSuccessful = steamworks.setUserStatValues({
    		{
        		statName = "NumGames",
        		type = "int",
        		value = totalGamesPlayed
    		}
    	})
	elseif ( target.id == "go100feet" ) then
		distanceTravelled = distanceTravelled + 100
		composer.setVariable( "distanceTravelled", distanceTravelled )
		local wasSuccessful = steamworks.setUserStatValues({
    		{
        		statName = "FeetTraveled",
        		type = "float",
        		value = distanceTravelled
    		}
    	})
	elseif ( target.id == "gospeed" ) then
		local distance = math.random(50, 100)
		local runTime = math.random( 30, 60) * 1/3600
		local wasSuccessful = steamworks.setUserStatValues({
    		{
        		statName = "AverageSpeed",
        		type = "averageRate",
        		sessionTimeLength = runTime,
        		value = distance
    		}
    	})
	elseif ( target.id == "resetAll" ) then
		totalGamesPlayed = 0
		composer.setVariable( "totalGamesPlayed", totalGamesPlayed )
		distanceTravelled = 0
		composer.setVariable( "distanceTravelled", distanceTravelled )
		resetProgress()
	end
	-- update the stats after setting them.
	showStats()
	return true
end

-- close the composer overlay. Not to be confused with Steamworks's overlays.
local function closeOverlay( event )
	composer.hideOverlay( )
	return true
end

-- create the scene
function scene:create( event )

	local sceneGroup = self.view

	local background = display.newRect( display.contentCenterX, display.contentCenterY + ( titleBarBottom * 0.5), display.actualContentWidth, display.actualContentHeight - titleBarBottom)
	sceneGroup:insert( background )
	background:setFillColor( 0, 0, 0, 0.667 )
	-- put a touch listener in to close the overlay, like dismissing a keyboard.
	background:addEventListener( "touch", closeOverlay )

	-- create the container to hold our display UI parts
	statsGroup = display.newGroup()
	sceneGroup:insert( statsGroup )

	local statsBackground = display.newRect( statsGroup, 0, 0, 300, 150)
	statsBackground:setFillColor( 0.15 )
	statsBackground.anchorX = 0
	statsBackground.anchorY = 0

	local gamesPlayedLabel = display.newText(statsGroup, "Games played:", 10, 10, appFontBold, 12 )
	gamesPlayedLabel.anchorX = 0
	gamesPlayedLabel.anchorY = 0

	gamesPlayedText = display.newText( statsGroup, "", 110, 10, appFont, 12 )
	gamesPlayedText.anchorX = 0
	gamesPlayedText.anchorY = 0

	local feetTravelledLabel = display.newText(statsGroup, "Feet Travelled:", 10, 40, appFontBold, 12 )
	feetTravelledLabel.anchorX = 0
	feetTravelledLabel.anchorY = 0

	feetTravelledText = display.newText( statsGroup, "", 110, 40, appFont, 12 )
	feetTravelledText.anchorX = 0
	feetTravelledText.anchorY = 0

	local averageSpeedLabel = display.newText(statsGroup, "Average Speed:", 10, 70, appFontBold, 12 )
	averageSpeedLabel.anchorX = 0
	averageSpeedLabel.anchorY = 0

	averageSpeedText = display.newText( statsGroup, "", 110, 70, appFont, 12 )
	averageSpeedText.anchorX = 0
	averageSpeedText.anchorY = 0

	-- here is a good example of why we used DRY techinques in the menu
	-- We have 5 buttons for this scene spanning 3 colors. It really wasn't
	-- quite worth it to make a function to generate them because in this case
	-- they were copy/pasted from other scenes. 
	-- TODO make them all one color and use DRY principles to avoid these long 
	-- widget initialization blocks.

	local winOneButton = widget.newButton{
		id = "playonegame",
		label = "Play one game",
		shape = "rectangle",
		width = 100,
		height = 18,
		font = appFont,
		fontSize = 10,
		fillColor = { default={ 0.11,0.47,0.78,1 }, over={ 0.121,0.517,0.858,1 } },
		labelColor = { default={ 1,1,1,1 }, over={ 1,1,1,1 } },
		onRelease = handleButton
	}
	winOneButton.x = 190
	winOneButton.y = 10
	winOneButton.anchorX = 0
	winOneButton.anchorY = 0
	statsGroup:insert( winOneButton )

	local go100FeetButton = widget.newButton{
		id = "go100feet",
		label = "Go 100 feet",
		shape = "rectangle",
		width = 100,
		height = 18,
		font = appFont,
		fontSize = 10,
		fillColor = { default={ 0.11,0.47,0.78,1 }, over={ 0.121,0.517,0.858,1 } },
		labelColor = { default={ 1,1,1,1 }, over={ 1,1,1,1 } },
		onRelease = handleButton
	}
	go100FeetButton.x = 190
	go100FeetButton.y = 35
	go100FeetButton.anchorX = 0
	go100FeetButton.anchorY = 0
	statsGroup:insert( go100FeetButton )

	local goSpeedButton = widget.newButton{
		id = "gospeed",
		label = "Go a random speed",
		shape = "rectangle",
		width = 100,
		height = 18,
		font = appFont,
		fontSize = 10,
		fillColor = { default={ 0.11,0.47,0.78,1 }, over={ 0.121,0.517,0.858,1 } },
		labelColor = { default={ 1,1,1,1 }, over={ 1,1,1,1 } },
		onRelease = handleButton
	}
	goSpeedButton.x = 190
	goSpeedButton.y = 60
	goSpeedButton.anchorX = 0
	goSpeedButton.anchorY = 0
	statsGroup:insert( goSpeedButton )

	local resetButton = widget.newButton{
		id = "resetAll",
		label = "Reset stats",
		shape = "rectangle",
		width = 100,
		height = 18,
		font = appFont,
		fontSize = 10,
		fillColor = { default={ 0.06,0.31,0.55,1 }, over={ 0.0672,0.347,0.616,1 } },
		labelColor = { default={ 1,1,1,1 }, over={ 1,1,1,1 } },
		onRelease = handleButton
	}
	resetButton.x = 190
	resetButton.y = 85
	resetButton.anchorX = 0
	resetButton.anchorY = 0
	statsGroup:insert( resetButton )

	local closeButton = widget.newButton{
		id = "close",
		label = "Close",
		shape = "rectangle",
		width = 100,
		height = 18,
		font = appFont,
		fontSize = 10,
		fillColor = { default={ 0.31,0.35,0.67,1 }, over={ 0.341,0.385,0.737,1 } },
		labelColor = { default={ 1,1,1,1 }, over={ 1,1,1,1 } },
		onRelease = closeOverlay
	}
	closeButton.anchorX = 0
	closeButton.anchorY = 0
	closeButton.x = 190 
	closeButton.y = 110
	statsGroup:insert( closeButton )

	statsGroup.x = display.actualContentWidth - statsGroup.contentBounds.xMax - 10 + display.screenOriginX
	statsGroup.y = titleBarBottom + 4
	statsGroup.anchorX = 0
	statsGroup.anchorY = 0


	-- define our controller/keyboard objects
	buttons[#buttons + 1 ] = { object = winOneButton, handler = handleButton, phase = "down", group = statsGroup }
	buttons[#buttons + 1 ] = { object = go100FeetButton, handler = handleButton, phase = "down", group = statsGroup }
	buttons[#buttons + 1 ] = { object = goSpeedButton, handler = handleButton, phase = "down", group = statsGroup }
	buttons[#buttons + 1 ] = { object = resetButton, handler = handleButton, phase = "down", group = statsGroup }
	buttons[#buttons + 1 ] = { object = closeButton, handler = closeOverlay, phase = "down", group = statsGroup }

end


function scene:show( event )

	if ( event.phase == "did" ) then
		-- setup the controller table
		controller.init( buttons, 1)

		-- Set up a listener to be invoked when achievement and stat data has been updated
		steamworks.addEventListener( "userProgressUpdate", onUserProgressUpdated )
		-- populate the stats table
		showStats()
	end
end

function scene:hide( event )

	if ( event.phase == "will" ) then
		-- when closing the overlay, we need to reset the keyboard controller to use the menu's buttons.
		event.parent.resetButtons()
	else
		--
	end
end

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )

return scene
