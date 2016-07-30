
-- Abstract: Steamworks Plugin Sample App
-- Version: 1.0
-- Sample code is MIT licensed; see https://www.coronalabs.com/links/code/license
---------------------------------------------------------------------------------------
-- This module will generate a player card (GUI display ) for any given steam user
-- In this sample, it's only used for the current player.

local steamworks = require( "plugin.steamworks" )
local composer = require( "composer" )

local titleBarBottom = composer.getVariable( "titleBarBottom" )
local appFont = composer.getVariable( "appFont" )
local appFontBold = composer.getVariable( "appFontBold" )

-- define the module
local M = {}

local playerCard

-- need access to the various display objects later
M.userNameText = nil
M.nickNameText = nil
M.steamLevelText = nil
M.statusText = nil
M.avatarImage = nil

-- update the current steam Avartar with their updated one
local function displaySteamUserAvatar( userSteamId )
    -- Fetch information about the logged in user's medium sized avatar image.
    local imageInfo = steamworks.getUserImageInfo( "largeAvatar", userSteamId )
    if imageInfo == nil then
        -- Image is not available yet. Need to wait for a "userInfoUpdate" event.
        return
    end

    -- Display the avatar image.
    -- yes, we are taking the big 184x184 image and having Corona scale it down to a 
    -- 64x64 in our content group. If we don't we get a blurry image.
    local newAvatarImage = steamworks.newImageRect( imageInfo.imageHandle, 64, 64 )
    if newAvatarImage == nil then
        return
    end
 	playerCard:insert( newAvatarImage )   
    newAvatarImage.x = 50
    newAvatarImage.y = 50

    -- Store a reference to the new avatar image.
    -- Remove the last displayed avatar image, if it exists.
    if M.avatarImage then
        M.avatarImage:removeSelf()
    end
    M.avatarImage = newAvatarImage
end

-- If player information changes, this function will update the player card including the avatar
local function onSteamUserInfoUpdated( event )
    -- Display current user's medium sized avatar if it changed or loaded for the 1st time.
	if event.largeAvatarChanged and event.userSteamId == steamworks.userSteamId then
    	displaySteamUserAvatar( event.userSteamId)
    else
    	local userInfo = steamworks.getUserInfo( event.userSteamId )
	    if userInfo and event.userSteamId == steamworks.userSteamId then
	    	M.userNameText.text = userInfo.name
	    	M.nickNameText.text = userInfo.nickname
	    	M.steamLevelText.text = userInfo.steamLevel
	    	M.statusText.text = userInfo.status
	        print( "User Name: ", userInfo.name )
	        print( "User Nickname: ", userInfo.nickname )
	        print( "Steam Level: ", tostring( userInfo.steamLevel ) )
	        print( "Status: ", userInfo.status )
	        print( "Relationship: ", userInfo.relationship )
	    end
	end
end

-- Create a new player card. 
function M.new( userSteamId )
	M.thisUserSteamId = userSteamId
	if M.thisUserSteamId == nil then
		M.thisUserSteamId = steamworks.userSteamId
	end
	local playerCardWidth = 270
	local playerCardHeight = 105

	playerCard = display.newContainer( playerCardWidth, playerCardHeight )
	playerCard.anchorChildren = false
	playerCard.anchorX = 0
	playerCard.anchorY = 0

	local playerCardBG = display.newRect( playerCard, 0, 0, playerCardWidth, playerCardHeight)
	playerCardBG.anchorX = 0
	playerCardBG.anchorY = 0
	playerCardBG:setFillColor( 0.15 )

	local playerCardFrame = display.newRect( playerCard, 5, 5, playerCardWidth - 10, playerCardHeight - 10)
	playerCardFrame:setFillColor( 0.25, 0.25, 0.25, 0)
	playerCardFrame.strokeWidth = 1
	playerCardFrame:setStrokeColor( 0.85 )
	playerCardFrame.anchorX = 0
	playerCardFrame.anchorY = 0

	-- labels we don't need to access after we create them.
	local userNameLabel = display.newText( playerCard, "User: ", playerCardWidth / 2 - 40, 15, appFontBold, 12 )
	userNameLabel.anchorX = 0
	userNameLabel.anchorY = 0
	
	-- however the values text objects we do so stick them as members of the object
	M.userNameText = display.newText( playerCard, "", playerCardWidth / 2 + 25, userNameLabel.y, appFont, 12)
	M.userNameText.anchorX = 0
	M.userNameText.anchorY = 0
	
	local nickNameLabel = display.newText( playerCard, "Nickname: ", playerCardWidth / 2 - 40, userNameLabel.y + 20, appFontBold, 12 )
	nickNameLabel.anchorX = 0
	nickNameLabel.anchorY = 0
	
	M.nickNameText = display.newText( playerCard, "", playerCardWidth / 2 + 25, nickNameLabel.y, appFont, 12)
	M.nickNameText.anchorX = 0
	M.nickNameText.anchorY = 0
	
	local steamLevelLabel = display.newText( playerCard, "Level: ", playerCardWidth / 2 - 40, nickNameLabel.y + 20, appFontBold, 12 )
	steamLevelLabel.anchorX = 0
	steamLevelLabel.anchorY = 0
	
	M.steamLevelText = display.newText( playerCard, "", playerCardWidth / 2 + 25, steamLevelLabel.y, appFont, 12 )
	M.steamLevelText.anchorX = 0
	M.steamLevelText.anchorY = 0
	
	local statusLabel = display.newText( playerCard, "Status: ", playerCardWidth / 2 - 40, steamLevelLabel.y + 20, appFontBold, 12 )
	statusLabel.anchorX = 0
	statusLabel.anchorY = 0
	
	M.statusText = display.newText( playerCard, "", playerCardWidth / 2 + 25, statusLabel.y, appFont, 12 )
	M.statusText.anchorX = 0
	M.statusText.anchorY = 0

	-- fetch the user info for the current user and populate our text fields
	local userInfo = steamworks.getUserInfo( userSteamId )
	M.userNameText.text = userInfo.name
	M.nickNameText.text = userInfo.nickname
	M.steamLevelText.text = userInfo.steamLevel
	M.statusText.text = userInfo.status
	print("User name",    userInfo.name )
	print("Nick name:",   userInfo.nickname )
	print("Steam Level:", userInfo.steamLevel )
	print("Status",       userInfo.status )
	print("Relationship", userInfo.relationship )

	-- fetch the avatar
	displaySteamUserAvatar( userSteamId )

	-- set up for handling updates that come in.
	steamworks.addEventListener( "userInfoUpdate", onSteamUserInfoUpdated )

	return playerCard
end

return M
