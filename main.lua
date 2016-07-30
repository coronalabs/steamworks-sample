
-- Abstract: Steamworks Plugin Sample App
-- Version: 1.0
-- Sample code is MIT licensed; see https://www.coronalabs.com/links/code/license
---------------------------------------------------------------------------------------

-- This sample app will demonstrate how to access the various methods of the Steamworks plugin
-- There is one primary scene: menu.lua that handles the core UI. Composer overlays are used to
-- display leaderboard, achievement and user status UI's.

display.setStatusBar( display.HiddenStatusBar )
local steamworks = require( "plugin.steamworks" )

------------------------------
-- RENDER THE SAMPLE CODE UI
------------------------------
local sampleUI = require( "sampleUI.sampleUI" )
sampleUI:newUI( { theme="darkgrey", title="Steamworks (appId: " .. steamworks.appId .. ")", showBuildNum=true } )

------------------------------
-- CONFIGURE STAGE
------------------------------

local composer = require( "composer" )
display.getCurrentStage():insert( sampleUI.backGroup )
display.getCurrentStage():insert( composer.stage )
display.getCurrentStage():insert( sampleUI.frontGroup )
composer.recycleOnSceneChange = false
local aliasGroup = display.newGroup()

----------------------
-- BEGIN SAMPLE CODE
----------------------

-- Set app font
composer.setVariable( "appFont", sampleUI.appFont )
composer.setVariable( "appFontBold", sampleUI.appFontBold )

-- The following property represents the bottom Y position of the sample title bar
composer.setVariable( "titleBarBottom",  sampleUI.titleBarBottom )

-- Set variables we want to track between scenes
composer.setVariable( "initializedSteam", false )
composer.setVariable( "distanceTravelled", 0)
composer.setVariable( "totalGamesPlayed", 0)
composer.setVariable( "totalSpeed", 0)
composer.setVariable( "speedCount", 0)


-- Check to see if the user is logged into steam. If not launch steam to try and
-- get them logged in.
local function checkLogin()
	-- Do not continue if failed to find a logged in Steam user.
	-- This means the Steam client is not running or the user is not logged in to it.
	if steamworks.isLoggedOn == false then

	    -- Handle the native alert's result displayed down below.
	    local function onAlertHandler( event )
	        -- If the user clicked the "Log In" button,
	        -- then display the Steam client via its custom URL scheme.
	        if ( event.action == "clicked" ) and ( event.index == 1 ) then
	            system.openURL( "steam:" )
	        end

	        -- Exit this app, regardless of which button was pressed.
	        -- The Steam client must be running when this app starts up.
	        native.requestExit()
	    end

	    -- Display a native alert asking the user to log into Steam.
	    local message =
	            "You must log into Steam in order to play this game.\n" ..
	            "After logging in, you must then relaunch this app."
	    native.showAlert( "Warning", message, { "Log In", "Close" }, onAlertHandler )

	    -- Exit out of the "main.lua" file.
	    -- The screen will be black. Only the above native alert will be shown on top.
	    return
	else
		-- everything is good, lets go to the main UI
		composer.gotoScene( "menu" )

	end
end

-- Initialize Steamworks if supported 
-- Steamworks is avaialble to Windows, macOS desktop builds and in the Corona Simulator. 
-- Luckily the simulator reports the same values for platformName
local platform = system.getInfo( "platformName" )
if ( platform == "Mac OS X" ) or ( platform == "Win" ) then
	checkLogin()
else
	native.showAlert( "Not Supported", "The Steamworks plugin is not supported on this platform. Please build and deploy as a desktop app.", { "OK" } )
end
