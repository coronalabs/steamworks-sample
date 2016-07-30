
-- Abstract: Steamworks Plugin Sample App
-- Version: 1.0
-- Sample code is MIT licensed; see https://www.coronalabs.com/links/code/license
---------------------------------------------------------------------------------------
-- update and display custom leaderboards

local composer = require( "composer" )
local steamworks = require( "plugin.steamworks" )
local widget = require( "widget" )
local controller = require( "classes.controller" )
local json = require( "json" )

-- create the scene object
local scene = composer.newScene()

-- fetch our sampleUI values
local titleBarBottom = composer.getVariable( "titleBarBottom" )
local appFont = composer.getVariable( "appFont" )
local appFontBold = composer.getVariable( "appFontBold" )

-- forward declare variables
local submitButton
local radioGroup
local controlsGroup
local leaderboardGroup
local lbEntries = {}
local buttons = {}

composer.setVariable( "currentScore", 200 )
composer.setVariable( "currentLeaderboardID", "Feet Traveled" )
composer.setVariable( "currentLeaderboardTitle", "Feet Traveled" )


-- when the user taps on a row in the leaderboard, show that user's stats overlay
local function showUserOverlay( event )
	local userSteamId = event.target.id
	local phase = event.phase

	if "began" == phase then
		steamworks.showUserOverlay( userSteamId, "steamid" )
	end
	return true
end

-- display an array of scores
local function displayScores()
	-- create the background box for the leaderboard
	local background = display.newRect( leaderboardGroup, 0, 0, 230, 120 )
	background.anchorX = 0
	background.anchorY = 0
	background:setFillColor( 0.25 )

	-- create a bar for behind the column labels
	local headerBackground = display.newRect( leaderboardGroup, 5, 5, 220, 16 )
	headerBackground.anchorX = 0
	headerBackground.anchorY = 0
	headerBackground:setFillColor( 0.33 )

	-- create each header label
	local rankHeader = display.newText( leaderboardGroup, "Rank", 10, 8, appFontBold, 8 )
	rankHeader:setFillColor( 1 )
	rankHeader.anchorX = 0
	rankHeader.anchorY = 0

	local playerHeader = display.newText( leaderboardGroup, "Player", 40, 8, appFontBold, 8 )
	playerHeader:setFillColor( 1 )
	playerHeader.anchorX = 0
	playerHeader.anchorY = 0

	local scoreHeader = display.newText( leaderboardGroup, "Score", 135, 8, appFontBold, 8 )
	scoreHeader:setFillColor( 1 )
	scoreHeader.anchorX = 0
	scoreHeader.anchorY = 0

	local relationshipHeader = display.newText( leaderboardGroup, "Friend?", 165, 8, appFontBold, 8 )
	relationshipHeader:setFillColor( 1 )
	relationshipHeader.anchorX = 0
	relationshipHeader.anchorY = 0

	local onlineHeader = display.newText( leaderboardGroup, "Online?", 195, 8, appFontBold, 8 )
	onlineHeader:setFillColor( 1 )
	onlineHeader.anchorX = 0
	onlineHeader.anchorY = 0

	-- we need quite a few text objects so stick them in a table
	local textObjects = {}
	for i = 1, #lbEntries do
		-- create a row
		textObjects[i] = {}
		-- default to white
		local entryColor = { 1, 1, 1 }
		-- fetch their user info
		local userInfo = steamworks.getUserInfo( lbEntries[i].userSteamId)
		if userInfo then
			lbEntries[i].userName = userInfo.name
			lbEntries[i].relationship = userInfo.relationship
			lbEntries[i].status = userInfo.status
		else
			-- if Steam hasn't cached them use their steamId for their name temporarily
			lbEntries[i].userName = lbEntries[i].userSteamId
			lbEntries[i].relationship = ""
			lbEntries[i].status = ""
		end

		if lbEntries[i].userSteamId == steamworks.userSteamId then -- Its me!
			-- make your entry stand out with yellow text
			entryColor = { 1, 1, 0 }
		end

		-- create text objects for each entry in the row
		textObjects[i].rankText = display.newText( { parent = leaderboardGroup, text = lbEntries[i].globalRank, x = 0, y = i * 16 + 8, width = 35, height = 16, font = appFont, fontSize = 8, align = "center" } )
		textObjects[i].rankText.anchorX = 0
		textObjects[i].rankText.anchorY = 0
		textObjects[i].rankText:setFillColor( unpack( entryColor ) )
		-- if the name is too long for our space, clip it
		textObjects[i].userText = display.newText( { parent = leaderboardGroup, text = lbEntries[i].userName:sub(1, 20), x = 40, y = i * 16 + 16, width = 120, height = 16, font = appFont, fontSize = 8, alight = "left" } )
		textObjects[i].userText.anchorX = 0
		textObjects[i].userText.anchorX = 0
		textObjects[i].userText:setFillColor( unpack( entryColor ) )
		textObjects[i].scoreText = display.newText( { parent = leaderboardGroup, text = lbEntries[i].score, x = 115, y = i * 16 + 16, width = 40, height = 16, font = appFont, fontSize = 8, align = "right" } )
		textObjects[i].scoreText:setFillColor( unpack( entryColor ) )
		textObjects[i].scoreText.anchorX = 0
		textObjects[i].scoreText.anchorX = 0

		-- .relationship is nil for yourself and "friend" for a friend. But lets map this to a simple Yes or No string
		local isFriend = "No"
		if userinfo and userInfo.relationship and userInfo.relationship == "friend" then
			isFriend = "Yes"
		end
		-- if it's you, then put "Me" out there
		if lbEntries[i].userSteamId == steamworks.userSteamId then -- Its me!
			isFriend = "Me"
		end
		textObjects[i].friendText = display.newText( { parent = leaderboardGroup, text = isFriend, x = 165, y = i * 16 + 16, width = 20, height = 16, font = appFont, fontSize = 8, align = "center" } )
		textObjects[i].friendText:setFillColor( unpack( entryColor ) )
		textObjects[i].friendText.anchorX = 0
		textObjects[i].friendText.anchorX = 0

		-- simlar to relationship, online is either "online" or "offline". Lets map it to Yes or No
		local isOnline = "No"
		if userinfo and userInfo.status and userInfo.status == "online" then
			isOnline = "Yes"
		end
		textObjects[i].statusText = display.newText( { parent = leaderboardGroup, text = isOnline, x = 195, y = i * 16 + 16, width = 20, height = 16, font = appFont, fontSize = 8, align = "center" } )
		textObjects[i].statusText:setFillColor( unpack( entryColor ) )
		textObjects[i].statusText.anchorX = 0
		textObjects[i].statusText.anchorX = 0

		-- Lets make it if you tap a row, it will display the Steam overlay for that person. 
		-- Instead of adding touch handlers on every object, lets add a box that can be tapped. 
		-- Lets set it on top of the row and use transparency to fade it back.
		textObjects[i].touchBox = display.newRect( leaderboardGroup, 5, i * 16 + 6, 220, 15)
		textObjects[i].touchBox:setFillColor( 1, 1, 1, 0.25)
		textObjects[i].touchBox.anchorX = 0
		textObjects[i].touchBox.anchorY = 0
		textObjects[i].touchBox.id = lbEntries[i].userSteamId
		textObjects[i].touchBox:addEventListener( "touch", showUserOverlay )

	end
	leaderboardGroup.anchorX = 0
	leaderboardGroup.anchorY = 0
	leaderboardGroup.x = 240
	leaderboardGroup.y = controlsGroup.contentBounds.yMax + 10
end

-- Radio button handler function
local function handleRadio( event )

	for j = 1,radioGroup.numChildren do
		if ( radioGroup[j].isOn == true and radioGroup[j].label ) then
			radioGroup[j].label:setFillColor( 1 )
			composer.setVariable( "currentLeaderboardID", event.target.id )
			composer.setVariable( "currentLeaderboardTitle", event.target.title )
		elseif ( radioGroup[j].isOn == false and radioGroup[j].label ) then
			radioGroup[j].label:setFillColor( 0.7 )
		end
	end
end

local function onReceivedLeaderboradEntries( event )
    -- Do not continue if fetching of leaderboard entries failed
    if ( event.isError ) then
        print( "Failed to fetch leaderboard entries." )
        return
    end

    -- Print information about each leaderborad entry to the log
    for index = 1, #event.entries do
    	lbEntries[index] = {}
    	lbEntries[index].globalRank = event.entries[index].globalRank
    	lbEntries[index].userSteamId = event.entries[index].userSteamId
    	local userInfo = steamworks.getUserInfo( event.entries[index].userSteamId )  -- start caching these values
    	lbEntries[index].score = event.entries[index].score
    	if userInfo then
    		print( index, "Have data for ", lbEntries[index].userSteamId, userInfo.name, userInfo.relationship, userInfo.status )
    	end
    end
    displayScores()
end

local function onReceivedSetHighScoreResult( event )
    if ( event.isError ) then
        -- The request has failed
        -- Note that an error will not occur if the given score is less than the highest
        print( "Failed to access the leaderboard." )
    else
        -- Print the result of this request to the log
        print( "Leaderboard Name: " .. event.leaderboardName )
        print( "Was Score Changed: " .. tostring(event.scoreChanged) )
        if ( event.scoreChanged ) then
            print( "Current Rank: " .. tostring(event.currentGlobalRank) )
            print( "Previous Rank: " .. tostring(event.previousGlobalRank) )
        end
    end
end

-- Button handler function
local function handleButton( event )

	local target = event.target

	-- Show leaderboard panel
	if ( target.id == "showLeaderboard" ) then
		local requestParams =
		{
		    leaderboardName = composer.getVariable( "currentLeaderboardID" ),
		    listener = onReceivedLeaderboradEntries,
		    playerScope = "GlobalAroundUser",
		    startIndex = -2,  -- Get 2 entries with higher score than user
		    endIndex = 3      -- Get 3 entries with lower score than user
		}
		steamworks.requestLeaderboardEntries( requestParams )
	-- Submit high score
	elseif ( target.id == "submitScore" ) then
		local leaderboard = composer.getVariable( "currentLeaderboardID" )
		local requestSettings =
		{
		    leaderboardName = leaderboard,
		    value = composer.getVariable( "currentScore" ),
		    listener = onReceivedSetHighScoreResult
		}
		steamworks.requestSetHighScore( requestSettings )

	-- Decrement current score
	elseif ( target.id == "decScore" and composer.getVariable( "currentScore" ) >= 20 ) then
		composer.setVariable( "currentScore", composer.getVariable( "currentScore" ) - 10 )
		submitButton:setLabel( "Submit ("..composer.getVariable( "currentScore" )..")" )

	-- Increment current score
	elseif ( target.id == "incScore" ) then
		composer.setVariable( "currentScore", composer.getVariable( "currentScore" ) + 10 )
		submitButton:setLabel( "Submit ("..composer.getVariable( "currentScore" )..")" )
	end
	return true
end

-- function to close the overlay
local function closeOverlay( event )
	composer.hideOverlay( )
	return true
end

-- setup our scene
function scene:create( event )
	local sceneGroup = self.view

	local background = display.newRect( display.contentCenterX, display.contentCenterY + ( titleBarBottom * 0.5), display.actualContentWidth, display.actualContentHeight - titleBarBottom)
	sceneGroup:insert( background )
	background:setFillColor( 0, 0, 0, 0.667 )
	-- allow touch on the background to close things
	background:addEventListener( "touch", closeOverlay )

	-- create the UI group
	controlsGroup = display.newGroup()
	sceneGroup:insert( controlsGroup )
	controlBackground = display.newRect( controlsGroup, 0, 0, 170, 160 )
	controlBackground.anchorX = 0
	controlBackground.anchorY = 0
	controlBackground:setFillColor( 0.15 )

	radioGroup = display.newGroup()
	controlsGroup:insert( radioGroup )
	radioGroup.anchorX = 0
	radioGroup.anchorY = 0

	-- this group will hold the actual leaderboard. Lets insert it into the scene's view
	leaderboardGroup = display.newGroup()
	sceneGroup:insert( leaderboardGroup )

	-- create two radio buttons to choose the leaderboard to increment/decrement/show
	-- radio buttons in the same group will only allow one to be selected
	local radioButton1 = widget.newSwitch{
		style = "radio",
		id = "Feet Traveled",
		initialSwitchState = true,
		onPress = handleRadio
	}
	radioButton1:scale(0.5, 0.5)
	radioGroup:insert( radioButton1 )
	radioButton1.anchorX = 0
	radioButton1.anchorY = 0
	radioButton1.x = 15
	radioButton1.y = 30

	-- Radio buttons are just the button.  
	local radioLabel1 = display.newText( radioGroup, "Feet Traveled", 0, radioButton1.y, appFont, 12 )
	radioButton1.label = radioLabel1
	radioButton1.title = "Feet Traveled"
	radioLabel1.x = 50
	radioLabel1.anchorX = 0
	radioLabel1.anchorY = 0
	radioLabel1:setFillColor( 1 )

	local radioButton2 = widget.newSwitch{
		style = "radio",
		id = "Quickest Win",
		initialSwitchState = false,
		onPress = handleRadio
	}
	radioGroup:insert( radioButton2 )
	radioButton2:scale(0.5, 0.5)
	radioButton2.anchorX = 0
	radioButton2.anchorY = 0
	radioButton2.x = 15
	radioButton2.y = 50

	local radioLabel2 = display.newText( radioGroup, "Quickest Win", 0, radioButton2.y, appFont, 12 )
	radioButton2.label = radioLabel2
	radioButton2.title = "Quickest Win"
	radioLabel2.x = 50
	radioLabel2.anchorX = 0
	radioLabel2.anchorY = 0
	radioLabel2:setFillColor( 0.7 )

	-- button to take points away from our test score
	local decButton = widget.newButton{
		id = "decScore",
		label = "-10",
		shape = "rectangle",
		width = 26,
		height = 18,
		font = appFont,
		fontSize = 10,
		fillColor = { default={ 0.06,0.31,0.55,1 }, over={ 0.0672,0.347,0.616,1 } },
		labelColor = { default={ 1,1,1,1 }, over={ 1,1,1,1 } },
		onRelease = handleButton
	}
	decButton.anchorX = 0
	decButton.anchorY = 0
	decButton.x = 10
	decButton.y = 75
	controlsGroup:insert( decButton )

	-- button to add points to our test score
	local incButton = widget.newButton{
		id = "incScore",
		label = "+10",
		shape = "rectangle",
		width = 26,
		height = 18,
		font = appFont,
		fontSize = 10,
		fillColor = { default={ 0.06,0.31,0.55,1 }, over={ 0.0672,0.347,0.616,1 } },
		labelColor = { default={ 1,1,1,1 }, over={ 1,1,1,1 } },
		onRelease = handleButton
	}
	incButton.anchorX = 0
	incButton.anchorY = 0
	incButton.x = decButton.x + 35
	incButton.y = decButton.y
	controlsGroup:insert( incButton )

	-- button to submit a high score. Why is this forward declared?
	-- When we increment/decrement the score we want to update the label
	-- so we need access to this button outside of this scene.
	submitButton = widget.newButton{
		id = "submitScore",
		label = "Submit ("..composer.getVariable( "currentScore" )..")",
		shape = "rectangle",
		width = 80,
		height = 18,
		font = appFont,
		fontSize = 10,
		fillColor = { default={ 0.11,0.47,0.78,1 }, over={ 0.121,0.517,0.858,1 } },
		labelColor = { default={ 1,1,1,1 }, over={ 1,1,1,1 } },
		onRelease = handleButton
	}
	submitButton.anchorX = 0
	submitButton.anchorY = 0
	submitButton.x = incButton.x + 35
	submitButton.y = incButton.y
	controlsGroup:insert( submitButton )

	-- show the leaderboard
	local showLeaderboardButton = widget.newButton{
		id = "showLeaderboard",
		label = "Show Leaderboard",
		shape = "rectangle",
		width = 150,
		height = 18,
		font = appFont,
		fontSize = 10,
		fillColor = { default={ 0.31,0.35,0.67,1 }, over={ 0.341,0.385,0.737,1 } },
		labelColor = { default={ 1,1,1,1 }, over={ 1,1,1,1 } },
		onRelease = handleButton
	}
	showLeaderboardButton.anchorX = 0
	showLeaderboardButton.anchorY = 0
	showLeaderboardButton.x = 10
	showLeaderboardButton.y = decButton.y + 26
	controlsGroup:insert( showLeaderboardButton )

	-- button to close the overlay
	local closeButton = widget.newButton{
		id = "close",
		label = "Close",
		shape = "rectangle",
		width = 150,
		height = 18,
		font = appFont,
		fontSize = 10,
		fillColor = { default={ 0.31,0.35,0.67,1 }, over={ 0.341,0.385,0.737,1 } },
		labelColor = { default={ 1,1,1,1 }, over={ 1,1,1,1 } },
		onRelease = closeOverlay
	}
	closeButton.anchorX = 0
	closeButton.anchorY = 0
	closeButton.x = 10
	closeButton.y = showLeaderboardButton.y + 26
	controlsGroup:insert( closeButton )

	-- position the control group
	controlsGroup.anchorX = 0
	controlsGroup.anchorY = 0
	controlsGroup.x = 280 --+ display.screenOriginX
	controlsGroup.y = 10

	-- setup our keyboard/controller buttons
	buttons[#buttons + 1 ] = { object = radioButton1, handler = handleRadio, phase = "down", group = radioGroup }
	buttons[#buttons + 1 ] = { object = radioButton2, handler = handleRadio, phase = "down", group = radioGroup }
	buttons[#buttons + 1 ] = { object = decButton, handler = handleButton, phase = "down", group = controlsGroup }
	buttons[#buttons + 1 ] = { object = incButton, handler = handleButton, phase = "down", group = controlsGroup }
	buttons[#buttons + 1 ] = { object = submitButton, handler = handleButton, phase = "down", group = controlsGroup }
	buttons[#buttons + 1 ] = { object = showLeaderboardButton, handler = handleButton, phase = "down", group = controlsGroup }
	buttons[#buttons + 1 ] = { object = closeButton, handler = closeOverlay, phase = "down", group = controlsGroup }

end

-- show()
function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is still off screen (but is about to come on screen)

	elseif ( phase == "did" ) then
		-- Code here runs when the scene is entirely on screen
		-- provide our list of buttons to the controller
		controller.init( buttons, 1)

	end
end


-- hide()
function scene:hide( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is on screen (but is about to go off screen)
		-- reset the buttons for the menu
		event.parent.resetButtons()
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
