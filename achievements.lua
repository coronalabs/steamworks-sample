
-- Abstract: Steamworks Plugin Sample App
-- Version: 1.0
-- Sample code is MIT licensed; see https://www.coronalabs.com/links/code/license
---------------------------------------------------------------------------------------
-- Scene file to show programmable achievement processes

local composer = require( "composer" )
local steamworks = require( "plugin.steamworks" )
local sampleUI = require( "sampleUI.sampleUI" )
local widget = require( "widget" )
local json = require( "json" )
local controller = require( "classes.controller" )

local scene = composer.newScene()

-- fetch our sampleUI values
local titleBarBottom = composer.getVariable( "titleBarBottom" )
local appFont = composer.getVariable( "appFont" )
local appFontBold = composer.getVariable( "appFontBold" )

-- forward declares
local achievementGroup 
local controlGroup

local cards = {}      -- Array of achiemvement UI objeects
local buttons = {}    -- Our controller button array

local distanceTravelled = composer.getVariable( "distanceTravelled" )
local feetTravelled = 0
local MILE = 5280

-- Creates a new display object which will automatically be "filled" with an achievement image
-- Image will be associated with the given unique achievement name
-- Image will automatically change when achievement changes from locked to unlocked
local function newSteamAchievementImage( achievementName )

    -- Create a rectangle which we'll later fill with the achievement image
    -- Note that Steam expects you to upload 64x64 pixel achievement images
    local defaultAchievementPixelSize = 64
    local achievementImage = display.newRect(
            display.contentCenterX, display.contentCenterY,
            defaultAchievementPixelSize * display.contentScaleX,
            defaultAchievementPixelSize * display.contentScaleY )
    if ( achievementImage == nil ) then
        return nil
    end

    -- Updates the achievement display object's "fill" to show the newest image
    local function updateAchievementTexture()
        -- Attempt to fetch info about the achievement's image
        -- Note that this function is likely to return nil on app startup
        local imageInfo = steamworks.getAchievementImageInfo( achievementName )
        if ( imageInfo == nil ) then
            return
        end

        -- Load the achievement image into a new texture resource object
        local newTexture = steamworks.newTexture( imageInfo.imageHandle )
        if ( newTexture == nil ) then
            return
        end

        -- Update the display object to show the achievement image
        achievementImage.fill =
        {
            type = "image",
            filename = newTexture.filename,
            baseDir = newTexture.baseDir
        }

        -- Release the texture reference created above
        newTexture:releaseSelf()
    end

    -- Attempt to update the display object with Steam's current image, if available
    -- If not currently available, this function call will trigger Steam to download it
    -- In this case, it dispatches an "achievementImageUpdate" event to be received below
    updateAchievementTexture()

    -- Set up a listener to be called when an achievement's image/status has changed
    local function onAchievementUpdated( event )
        if ( event.achievementName == achievementName ) then
            updateAchievementTexture()
        end
    end
    steamworks.addEventListener( "achievementImageUpdate", onAchievementUpdated )
    steamworks.addEventListener( "achievementInfoUpdate", onAchievementUpdated )

    -- Set up a listener to be called when the achievement display object is being removed
    local function onFinalizing( event )
        -- Remove event listeners which were added above
        steamworks.removeEventListener( "achievementImageUpdate", onAchievementUpdated )
        steamworks.removeEventListener( "achievementInfoUpdate", onAchievementUpdated )
    end
    achievementImage:addEventListener( "finalize", onFinalizing )

    -- Return the achievement display object created above
    return achievementImage
end

-- Each achievement has an image with it. Normally it's a grayscale image until it's been
-- unlocked. During a reset, we need to remove each achievement image and re-generate it 
-- to get the locked version back.
-- we have to re-insert it into the the card's group and reposition it
-- Do this for each of the four achievements
local function resetProgress()
	steamworks.resetUserProgress()
	cards["ACH_WIN_ONE_GAME"].image:removeSelf()
	cards["ACH_WIN_ONE_GAME"].image = newSteamAchievementImage( "ACH_WIN_ONE_GAME" )
	if cards["ACH_WIN_ONE_GAME"].image then
		cards["ACH_WIN_ONE_GAME"]:insert( cards["ACH_WIN_ONE_GAME"].image )
		cards["ACH_WIN_ONE_GAME"].image.x = 16
		cards["ACH_WIN_ONE_GAME"].image.y = 16
	end
	cards["ACH_WIN_100_GAMES"].image:removeSelf()
	cards["ACH_WIN_100_GAMES"].image = newSteamAchievementImage( "ACH_WIN_100_GAMES" )
	if cards["ACH_WIN_100_GAMES"].image then
		cards["ACH_WIN_100_GAMES"]:insert( cards["ACH_WIN_100_GAMES"].image )
		cards["ACH_WIN_100_GAMES"].image.x = 16
		cards["ACH_WIN_100_GAMES"].image.y = 16
	end
	cards["ACH_TRAVEL_FAR_ACCUM"].image:removeSelf()
	cards["ACH_TRAVEL_FAR_ACCUM"].image = newSteamAchievementImage( "ACH_TRAVEL_FAR_ACCUM" )
	if cards["ACH_TRAVEL_FAR_ACCUM"].image then
		cards["ACH_TRAVEL_FAR_ACCUM"]:insert( cards["ACH_TRAVEL_FAR_ACCUM"].image )
		cards["ACH_TRAVEL_FAR_ACCUM"].image.x = 16
		cards["ACH_TRAVEL_FAR_ACCUM"].image.y = 16
	end
	cards["ACH_TRAVEL_FAR_SINGLE"].image:removeSelf()
	cards["ACH_TRAVEL_FAR_SINGLE"].image = newSteamAchievementImage( "ACH_TRAVEL_FAR_SINGLE" )
	if cards["ACH_TRAVEL_FAR_SINGLE"].image then
		cards["ACH_TRAVEL_FAR_SINGLE"]:insert( cards["ACH_TRAVEL_FAR_SINGLE"].image )
		cards["ACH_TRAVEL_FAR_SINGLE"].image.x = 16
		cards["ACH_TRAVEL_FAR_SINGLE"].image.y = 16
	end

end


-- Button handler function
-- take our button actions and score some achievements
local function handleButton( event )

	local target = event.target

	-- Show achievements panel
	-- These four achievements are pre-defined for testing

	-- winonegame: Will unlock after winning 
	if ( target.id == "winonegame" ) then
		steamworks.setAchievementUnlocked( "ACH_WIN_ONE_GAME" )

		-- Win 100 games
	elseif ( target.id == "win100games" ) then
		steamworks.setAchievementUnlocked( "ACH_WIN_100_GAMES" )
	elseif ( target.id == "go1000feet" ) then
		-- submit progress. This one is for progress over time. You can leave this scene and come
		-- back and it will have remembered the progress. Steamworks however does not remember your
		-- progress. It's up to your app to track it.
		distanceTravelled = distanceTravelled + 1000
		composer.setVariable( "distanceTravelled", distanceTravelled )
		steamworks.setAchievementProgress( "ACH_TRAVEL_FAR_ACCUM", distanceTravelled, MILE )
	elseif ( target.id == "go100feet" ) then
		-- This progress is session based. You have to make all your progress in a single run. If you leave 
		-- this scene it will reset. 
		feetTravelled = feetTravelled + 100
		steamworks.setAchievementProgress( "ACH_TRAVEL_FAR_SINGLE", feetTravelled, 500 )
	elseif ( target.id == "resetAll" ) then
		-- Reset them all.  
		resetProgress()
	end
	return true
end

-- Function to build a single achievement, show it's icon and description and set us up to 
-- have it update later
local function getAchievementInfoCard( achievement )
	local achievementInfo = steamworks.getAchievementInfo( achievement )

	local card = display.newGroup()
	local background = display.newRect( card, 80, 16, 160, 32 )
	background:setFillColor( 0.25 )

	card.image = newSteamAchievementImage( achievement )
	if card.image then
		card:insert( card.image )
		card.image.x = 16
		card.image.y = 16
	end

	card.name = display.newText( card, achievementInfo.localizedName, 36, 12, sampleUI.appFontBold, 10 )
	card.name.anchorX = 0
	card.description  = display.newText( card, achievementInfo.localizedDescription, 36, 24, sampleUI.appFont, 8 )
	card.description.anchorX = 0

	return card
end

-- function to close our overlay.
local function closeOverlay( event )
	composer.hideOverlay( )
	return true
end

-- create the scerne
function scene:create( event )

	local sceneGroup = self.view

	local background = display.newRect( display.contentCenterX, display.contentCenterY + ( titleBarBottom * 0.5), display.actualContentWidth, display.actualContentHeight - titleBarBottom)
	sceneGroup:insert( background )
	background:setFillColor( 0, 0, 0, 0.667 )
	-- allow the background to be closed on a touch
	background:addEventListener( "touch", closeOverlay )

	achievementGroup = display.newGroup()
	sceneGroup:insert( achievementGroup )

	local achievementBackground = display.newRect( achievementGroup, 0, 0, 300, 260)
	achievementBackground:setFillColor( 0.15 )
	achievementBackground.anchorX = 0
	achievementBackground.anchorY = 0

	controlsGroup = display.newGroup()
	sceneGroup:insert( controlsGroup )

	-- generate an achivement card and place it on the screen for each group
	cards["ACH_WIN_ONE_GAME"] = getAchievementInfoCard( "ACH_WIN_ONE_GAME" )
	achievementGroup:insert( cards["ACH_WIN_ONE_GAME"] )
	cards["ACH_WIN_ONE_GAME"].x = 10
	cards["ACH_WIN_ONE_GAME"].y = 10
	cards["ACH_WIN_ONE_GAME"].anchorX = 0
	cards["ACH_WIN_ONE_GAME"].anchorY = 0

	cards["ACH_WIN_100_GAMES"] = getAchievementInfoCard( "ACH_WIN_100_GAMES" )
	achievementGroup:insert( cards["ACH_WIN_100_GAMES"] )
	cards["ACH_WIN_100_GAMES"].x = 10
	cards["ACH_WIN_100_GAMES"].y = 46
	cards["ACH_WIN_100_GAMES"].anchorX = 0
	cards["ACH_WIN_100_GAMES"].anchorY = 0

	cards["ACH_TRAVEL_FAR_ACCUM"] = getAchievementInfoCard( "ACH_TRAVEL_FAR_ACCUM" )
	achievementGroup:insert( cards["ACH_TRAVEL_FAR_ACCUM"] )
	cards["ACH_TRAVEL_FAR_ACCUM"].x = 10
	cards["ACH_TRAVEL_FAR_ACCUM"].y = 82
	cards["ACH_TRAVEL_FAR_ACCUM"].anchorX = 0
	cards["ACH_TRAVEL_FAR_ACCUM"].anchorY = 0

	cards["ACH_TRAVEL_FAR_SINGLE"] = getAchievementInfoCard( "ACH_TRAVEL_FAR_SINGLE" )
	achievementGroup:insert( cards["ACH_TRAVEL_FAR_SINGLE"] )
	cards["ACH_TRAVEL_FAR_SINGLE"].x = 10
	cards["ACH_TRAVEL_FAR_SINGLE"].y = 118
	cards["ACH_TRAVEL_FAR_SINGLE"].anchorX = 0
	cards["ACH_TRAVEL_FAR_SINGLE"].anchorY = 0

	-- set up buttons so you can earn achivements
	-- TODO: Make this DRY
	local submitProgressButton = widget.newButton{
		id = "winonegame",
		label = "Win One Game",
		shape = "rectangle",
		width = 100,
		height = 18,
		font = sampleUI.appFont,
		fontSize = 10,
		fillColor = { default={ 0.11,0.47,0.78,1 }, over={ 0.121,0.517,0.858,1 } },
		labelColor = { default={ 1,1,1,1 }, over={ 1,1,1,1 } },
		onRelease = handleButton
	}
	submitProgressButton.x = 180
	submitProgressButton.y = cards["ACH_WIN_ONE_GAME"].y + 8
	submitProgressButton.anchorX = 0
	submitProgressButton.anchorY = 0
	achievementGroup:insert( submitProgressButton )

	local submit100ProgressButton = widget.newButton{
		id = "win100games",
		label = "Win 100 Games",
		shape = "rectangle",
		width = 100,
		height = 18,
		font = sampleUI.appFont,
		fontSize = 10,
		fillColor = { default={ 0.11,0.47,0.78,1 }, over={ 0.121,0.517,0.858,1 } },
		labelColor = { default={ 1,1,1,1 }, over={ 1,1,1,1 } },
		onRelease = handleButton
	}
	submit100ProgressButton.x = 180
	submit100ProgressButton.y = cards["ACH_WIN_100_GAMES"].y + 8
	submit100ProgressButton.anchorX = 0
	submit100ProgressButton.anchorY = 0
	achievementGroup:insert( submit100ProgressButton )

	local submit1000FeetProgressButton = widget.newButton{
		id = "go1000feet",
		label = "Go 1000 feet",
		shape = "rectangle",
		width = 100,
		height = 18,
		font = sampleUI.appFont,
		fontSize = 10,
		fillColor = { default={ 0.11,0.47,0.78,1 }, over={ 0.121,0.517,0.858,1 } },
		labelColor = { default={ 1,1,1,1 }, over={ 1,1,1,1 } },
		onRelease = handleButton
	}
	submit1000FeetProgressButton.x = 180
	submit1000FeetProgressButton.y = cards["ACH_TRAVEL_FAR_ACCUM"].y + 8
	submit1000FeetProgressButton.anchorX = 0
	submit1000FeetProgressButton.anchorY = 0
	achievementGroup:insert( submit1000FeetProgressButton )

	local submit100FeetProgressButton = widget.newButton{
		id = "go100feet",
		label = "Go 100 feet",
		shape = "rectangle",
		width = 100,
		height = 18,
		font = sampleUI.appFont,
		fontSize = 10,
		fillColor = { default={ 0.11,0.47,0.78,1 }, over={ 0.121,0.517,0.858,1 } },
		labelColor = { default={ 1,1,1,1 }, over={ 1,1,1,1 } },
		onRelease = handleButton
	}
	submit100FeetProgressButton.x = 180
	submit100FeetProgressButton.y = cards["ACH_TRAVEL_FAR_SINGLE"].y + 8
	submit100FeetProgressButton.anchorX = 0
	submit100FeetProgressButton.anchorY = 0
	achievementGroup:insert( submit100FeetProgressButton )


	local resetButton = widget.newButton{
		id = "resetAll",
		label = "Reset Achievements",
		shape = "rectangle",
		width = 100,
		height = 18,
		font = sampleUI.appFont,
		fontSize = 10,
		fillColor = { default={ 0.06,0.31,0.55,1 }, over={ 0.0672,0.347,0.616,1 } },
		labelColor = { default={ 1,1,1,1 }, over={ 1,1,1,1 } },
		onRelease = handleButton
	}
	resetButton.x = submit100FeetProgressButton.x
	resetButton.y = submit100FeetProgressButton.y + 32
	resetButton.anchorX = 0
	resetButton.anchorY = 0
	achievementGroup:insert( resetButton )

	local closeButton = widget.newButton{
		id = "close",
		label = "Close",
		shape = "rectangle",
		width = 100,
		height = 18,
		font = sampleUI.appFont,
		fontSize = 10,
		fillColor = { default={ 0.31,0.35,0.67,1 }, over={ 0.341,0.385,0.737,1 } },
		labelColor = { default={ 1,1,1,1 }, over={ 1,1,1,1 } },
		onRelease = closeOverlay
	}
	closeButton.anchorX = 0
	closeButton.anchorY = 0
	closeButton.x = resetButton.x 
	closeButton.y = resetButton.y + 32
	achievementGroup:insert( closeButton )

	achievementGroup.x = display.actualContentWidth - achievementGroup.contentBounds.xMax - 10 + display.screenOriginX
	achievementGroup.y = titleBarBottom + 4
	achievementGroup.anchorX = 0
	achievementGroup.anchorY = 0

	-- define our keyboard button objects
	buttons[#buttons + 1 ] = { object = submitProgressButton, handler = handleButton, phase = "down", group = achievementGroup }
	buttons[#buttons + 1 ] = { object = submit100ProgressButton, handler = handleButton, phase = "down", group = achievementGroup }
	buttons[#buttons + 1 ] = { object = submit1000FeetProgressButton, handler = handleButton, phase = "down", group = achievementGroup }
	buttons[#buttons + 1 ] = { object = submit100FeetProgressButton, handler = handleButton, phase = "down", group = achievementGroup }
	buttons[#buttons + 1 ] = { object = resetButton, handler = handleButton, phase = "down", group = achievementGroup }
	buttons[#buttons + 1 ] = { object = closeButton, handler = closeOverlay, phase = "down", group = achievementGroup }
end


function scene:show( event )

	if ( event.phase == "will" ) then
	else 
		-- set up our buttons
		controller.init( buttons, 1)
	end
end

function scene:hide( event )

	if ( event.phase == "will" ) then
		-- restore menu's buttons
		event.parent.resetButtons()
	else
		--
	end
end

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )

return scene
