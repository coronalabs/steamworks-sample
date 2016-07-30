-- Abstract: Steamworks Plugin Sample App
-- Version: 1.0
-- Sample code is MIT licensed; see https://www.coronalabs.com/links/code/license
---------------------------------------------------------------------------------------
-- This is the main menu UI. 

local composer = require( "composer" )
local widget = require( "widget" )
local steamworks = require( "plugin.steamworks" )
local playerCard = require( "playercard" )
local controller = require( "classes.controller" )
local json = require( "json" )

-- Create the scene
local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
local titleBarBottom = composer.getVariable( "titleBarBottom" )
local appFont = composer.getVariable( "appFont" )
local appFontBold = composer.getVariable( "appFontBold" )

-- This table will hold a reference to our various UI buttons that can be passed to our
-- controller function so it knows what buttons are where on the screen. The controller
-- code allows you to to use the arrow keys, enter and escape to navigate the UI.

-- buttons[1] = { object = displayObject, handler = callbackFunction, phase = "down|up|both" }
local buttons = {}

-- This function allows the scene to re-initialize the controller with the buttons for this scene.
-- It's called from the leaderboard, achievement and userstat's overlays when the overlay closes.
function scene:resetButtons()
	controller.init( buttons, 1)
end

-- There are two groupings of buttons, each in their own display group. One shows the various
-- Steamworks overlays and the other loads the various scenes for the examples of handing leaderboards,
-- achievements and userStats.steamworks
-- 
-- Ths one function handles all of the overlay buttons 
--
-- Scene buttons handler function
local function handleOverlayButton( event )
	local target = event.target
	local button = target.id
	local wasShown 

	print( "handleOverlayButton", event.phase)
	--print( json.prettify( event ) )

	if not steamworks.canShowOverlay then
		native.showAlert("Steamworks","Overlays are currently disabled.", {"OK"})
		return true
	end
	-- based on the ID of the button 
	if "achievements" == button then
		wasShown = steamworks.showGameOverlay( "Achievements" )
	elseif "community" == button then
		wasShown = steamworks.showGameOverlay( "Community" )
	elseif "friends" == button then 
		wasShown = steamworks.showGameOverlay( "Friends" )
	elseif "gamegroup" == button then
		wasShown = steamworks.showGameOverlay( "OfficalGameGroup" )
	elseif "players" == button then
		wasShown = steamworks.showGameOverlay( "Players" )
	elseif "settings" == button then 
		wasShown = steamworks.showGameOverlay( "Settings" )
	elseif "stats" == button then
		wasShown = steamworks.showGameOverlay( "Stats" )
	end
	if not wasShown then
		native.showAlert("Steamworks", "We couldn't show the overlay. Do you have this option turned on?", {"OK"})
	end
	return true
end


-- We are creating a lot of buttons in this scene that use almost identical code. Lets write a function that we can call
-- that passes in the various differences for the button and generate it. We will need to know what group to put it in,
-- the 'id' value for the handler function, the label to use for the button and where to put it.
--
-- DRY So much repeated code.....
local function makeOverlayButton( group, id, label, x, y )
	local button = widget.newButton({
		id = id,
		label = label,
		shape = "rectangle",
		width = 120,
		height = 18,
		font = appFont,
		fontSize = 10,
		fillColor = { default={ 0.13,0.39,0.44,1 }, over={ 0.13,0.429,0.484,1 } },
		labelColor = { default={ 1,1,1,1 }, over={ 1,1,1,1 } },
		onRelease = handleOverlayButton
	})
	button.anchorX = 0
	button.anchorY = 0
	button.y = y
	button.x = x
	group:insert( button )

	return button
end

-- Scene buttons handler function
-- This will handle the buttons that load composer overlay scenes. We end up using and id of 
-- achievements in both button groups. These buttons will be colored differently.local
local function handleCommandButton( event )
	local target = event.target
	local button = target.id

	if "achievements" == button then 
		composer.showOverlay( "achievements" )
	elseif "leaderboards" == button then
		composer.showOverlay( "leaderboards" )
	elseif "userstats" == button then
		composer.showOverlay( "userstats" )
	end

	return true
end

-- Just like we don't want to repeat ourselve's too much, this will handle the 
-- command buttons. They have a different color and a different handler function
--
local function makeCommandButton( group, id, label, x, y )
	local button = widget.newButton({
		id = id,
		label = label,
		shape = "rectangle",
		width = 120,
		height = 18,
		font = appFont,
		fontSize = 10,
		fillColor = { default={ 0.13,0.34,0.48,1 }, over={ 0.143,0.374,0.528,1 } },
		labelColor = { default={ 1,1,1,1 }, over={ 1,1,1,1 } },
		onRelease = handleCommandButton
	})
	button.anchorX = 0
	button.anchorY = 0
	button.y = y
	button.x = x
	group:insert( button )
	return button
end
-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )

	local sceneGroup = self.view
	-- Code here runs when the scene is first created but has not yet appeared on screen

	-- For this scene we won't have a background. The "sampleUI" module provides one for us
	-- Let's just start placing items

	-- Get a player card object for me.
	local myPlayerCard = playerCard.new()
	myPlayerCard.x = 0 + display.screenOriginX
	myPlayerCard.y = titleBarBottom
	myPlayerCard.anchorX = 0
	myPlayerCard.anchorY = 0
	sceneGroup:insert( myPlayerCard )

	-- create a group to hold the seven buttons that show Steam overlays
	local overlayGroup = display.newGroup()
	local overlayGroupBG = display.newRect( overlayGroup, 0, 0, 130, 180 )
	overlayGroupBG.anchorX = 0
	overlayGroupBG.anchorY = 0
	overlayGroupBG:setFillColor( 0.20 )
	overlayGroup.anchorX = 0
	overlayGroup.anchorY = 0
	overlayGroup.x = 5 + display.screenOriginX
	overlayGroup.y = myPlayerCard.contentBounds.yMax + 5
	sceneGroup:insert( overlayGroup )

	-- Add a title to the box
	local overlayGroupTitle = display.newText( overlayGroup, "Overlays", 65, 12, appFont, 10 )

	-- Build all of the buttons for the group
	-- See how short the code is by using DRY principles?
	local showAchievementsButton = makeOverlayButton( overlayGroup, "achievements", "Show Achievements", 5, 20 )
	local showCommunityButton    = makeOverlayButton( overlayGroup, "community", "Show Community", 5, 42 )
	local showFriendsButton      = makeOverlayButton( overlayGroup, "friends", "Show Friends", 5, 64 )
	local showGameGroupButton    = makeOverlayButton( overlayGroup, "gamegroup", "Show Game Group", 5, 86 )
	local showPlayersButton      = makeOverlayButton( overlayGroup, "players", "Show Players", 5, 108 )
	local showSettingsButton     = makeOverlayButton( overlayGroup, "settings", "Show Settings", 5,130 )
	local showStatsButton        = makeOverlayButton( overlayGroup, "stats", "Show Stats", 5, 152 )

	-- Build out the 2nd column of buttons that will drive the more complex, user generated 
	-- displays. Just like above.
	local commandGroup = display.newGroup()
	sceneGroup:insert( commandGroup )
	local commandBG = display.newRect( commandGroup, 0, 0, 130, 90 )
	commandBG.anchorX = 0
	commandBG.anchorY = 0
	commandBG:setFillColor( 0.20 )
	commandGroup.anchorX = 0
	commandGroup.anchorY = 0
	commandGroup.x = overlayGroup.contentBounds.xMax + 5
	commandGroup.y = myPlayerCard.contentBounds.yMax + 5

	local commandGroupTitle = display.newText( commandGroup, "Commands", 65, 12, appFont, 10 )

	local doLeaderboardsButton = makeCommandButton( commandGroup, "leaderboards", "Leaderboards", 5, 20 )
	local doAchievementsButton = makeCommandButton( commandGroup, "achievements", "Achievements", 5, 42 )
	local doStatsButton        = makeCommandButton( commandGroup, "userstats", "User Stats", 5, 64 )

	-- This table is used by our keyboard handler (and eventual game controller support)
	-- It contains a  list of each button we want the keyboard to have access too in addition we
	-- need to know the function to call when the player hits enter and because we will be displaying
	-- a cursor to show which button you have selected, we need to know what group it's in since it
	-- afffects the X, Y values for drawing the cursor.
	buttons[#buttons + 1 ] = { object = showAchievementsButton, handler = handleOverlayButton, phase = "down", group = overlayGroup }
	buttons[#buttons + 1 ] = { object = showCommunityButton, handler = handleOverlayButton, phase = "down", group = overlayGroup }
	buttons[#buttons + 1 ] = { object = showFriendsButton, handler = handleOverlayButton, phase = "down", group = overlayGroup }
	buttons[#buttons + 1 ] = { object = showGameGroupButton, handler = handleOverlayButton, phase = "down", group = overlayGroup }
	buttons[#buttons + 1 ] = { object = showPlayersButton, handler = handleOverlayButton, phase = "down", group = overlayGroup }
	buttons[#buttons + 1 ] = { object = showSettingsButton, handler = handleOverlayButton, phase = "down", group = overlayGroup }
	buttons[#buttons + 1 ] = { object = showStatsButton, handler = handleOverlayButton, phase = "down", group = overlayGroup }
	buttons[#buttons + 1 ] = { object = doLeaderboardsButton, handler = handleCommandButton, phase = "down", group = commandGroup }
	buttons[#buttons + 1 ] = { object = doAchievementsButton, handler = handleCommandButton, phase = "down", group = commandGroup }
	buttons[#buttons + 1 ] = { object = doStatsButton, handler = handleCommandButton, phase = "down", group = commandGroup }

end


-- show()
function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is still off screen (but is about to come on screen)

	elseif ( phase == "did" ) then
		-- Code here runs when the scene is entirely on screen
		-- tell the controller to use this set of buttons and start at #1
		controller.init( buttons, 1)
		-- turn on the control event handling
		controller.start()
	end
end


-- hide()
function scene:hide( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is on screen (but is about to go off screen)
		-- turn off the controller handling
		controller.stop()
	elseif ( phase == "did" ) then
		-- Code here runs immediately after the scene goes entirely off screen

	end
end


-- destroy()
function scene:destroy( event )

	local sceneGroup = self.view
	-- Code here runs prior to the removal of scene's view

end


-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
-- -----------------------------------------------------------------------------------

return scene
