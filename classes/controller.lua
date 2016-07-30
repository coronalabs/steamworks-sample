
-- Abstract: Steamworks Plugin Sample App
-- Version: 1.0
-- Sample code is MIT licensed; see https://www.coronalabs.com/links/code/license
---------------------------------------------------------------------------------------
-- A module to handle keyboard and controller input
-- For version one, keyboard controls are supported.

local json = require("json")
local composer = require("composer")

local controllerKeys = {}
controllerKeys["Sony PLAYSTATION(R)3 Controller"] = {}
controllerKeys["Sony PLAYSTATION(R)3 Controller"]["button1"] = "select"
controllerKeys["Sony PLAYSTATION(R)3 Controller"]["button2"] = "buttonL3"
controllerKeys["Sony PLAYSTATION(R)3 Controller"]["button3"] = "buttonR3"
controllerKeys["Sony PLAYSTATION(R)3 Controller"]["button4"] = "start"
controllerKeys["Sony PLAYSTATION(R)3 Controller"]["button5"] = "up"
controllerKeys["Sony PLAYSTATION(R)3 Controller"]["button6"] = "right"
controllerKeys["Sony PLAYSTATION(R)3 Controller"]["button7"] = "down"
controllerKeys["Sony PLAYSTATION(R)3 Controller"]["button8"] = "left"
controllerKeys["Sony PLAYSTATION(R)3 Controller"]["button9"] = "buttonL2"
controllerKeys["Sony PLAYSTATION(R)3 Controller"]["button10"] = "buttonR2"
controllerKeys["Sony PLAYSTATION(R)3 Controller"]["button11"] = "buttonL1"
controllerKeys["Sony PLAYSTATION(R)3 Controller"]["button12"] = "buttonR1"
controllerKeys["Sony PLAYSTATION(R)3 Controller"]["button13"] = "buttonY"
controllerKeys["Sony PLAYSTATION(R)3 Controller"]["button14"] = "buttonB"
controllerKeys["Sony PLAYSTATION(R)3 Controller"]["button15"] = "buttonA"
controllerKeys["Sony PLAYSTATION(R)3 Controller"]["button16"] = "buttonX"
controllerKeys["Sony PLAYSTATION(R)3 Controller"]["button17"] = "power"
controllerKeys["Sony Computer Entertainment Wireless Controller"] = {}
controllerKeys["Sony Computer Entertainment Wireless Controller"]["button1"] = "buttonX"
controllerKeys["Sony Computer Entertainment Wireless Controller"]["button2"] = "buttonA"
controllerKeys["Sony Computer Entertainment Wireless Controller"]["button3"] = "buttonB"
controllerKeys["Sony Computer Entertainment Wireless Controller"]["button4"] = "buttonY"
controllerKeys["Sony Computer Entertainment Wireless Controller"]["button5"] = "buttonL1"
controllerKeys["Sony Computer Entertainment Wireless Controller"]["button6"] = "buttonR1"
controllerKeys["Sony Computer Entertainment Wireless Controller"]["button7"] = "buttonL2"
controllerKeys["Sony Computer Entertainment Wireless Controller"]["button8"] = "buttonR2"
controllerKeys["Sony Computer Entertainment Wireless Controller"]["button9"] = "select"
controllerKeys["Sony Computer Entertainment Wireless Controller"]["button10"] = "start"
controllerKeys["Sony Computer Entertainment Wireless Controller"]["button11"] = "buttonL3"
controllerKeys["Sony Computer Entertainment Wireless Controller"]["button12"] = "buttonR3"
controllerKeys["Sony Computer Entertainment Wireless Controller"]["button13"] = "power"
controllerKeys["Xbox"] = {}
controllerKeys["Xbox"]["button1"] = "buttonA"
controllerKeys["Xbox"]["button2"] = "buttonB"
controllerKeys["Xbox"]["button3"] = "buttonX"
controllerKeys["Xbox"]["button4"] = "buttonY"
controllerKeys["Xbox"]["button5"] = "buttonL1"
controllerKeys["Xbox"]["button6"] = "buttonR1"
controllerKeys["Xbox"]["button7"] = "buttonL3"
controllerKeys["Xbox"]["button8"] = "buttonR3"
controllerKeys["Xbox"]["button9"] = "start"
controllerKeys["Xbox"]["button10"] = "select"
controllerKeys["Xbox"]["button11"] = "power"
controllerKeys["Xbox"]["button12"] = "up"
controllerKeys["Xbox"]["button13"] = "down"
controllerKeys["Xbox"]["button14"] = "left"
controllerKeys["Xbox"]["button15"] = "right"


local function mappedKey( event )
	local device = nil
	if event.device then
		device = event.device.productName
	else 
		return event.keyName
	end

	local keyName = event.keyName

	if device:lower():find("xbox") then
		device = "Xbox"
	end
	local key = keyName
	if controllerKeys[device] and controllerKeys[ device ][ keyName ] then
		key = controllerKeys[ device ][ keyName ]
	else
		key = keyName
	end
	return key
end


local M = {}
--[[
	The module expects to be passed a table of objects, their handling function and if it's going
	to be executed on button press ("down"), or release ("up"), or act like a touch handler where
	the handler function is looking for both a "began" and "ended" phase. Use the sample table below
	as a starter:
	-- The button objects
	local objects = {}
	objects[1] = { object = displayObject, handler = callbackFunction, phase = "down|up|both" }

--]]

-- Called when a key event has been received
M.shiftedThisEvent = false 

-- The original version of this drew a darkened rectangle around the selected item. It gave it a
-- look as if it were disabled and the rectangle didn't work well with round objects. So lets make
-- a little polygon triangle instead.
M.focusPointer = display.newPolygon(0, 0, { -5, 6, 0, 11, -5, 16 } )
M.focusPointer:setFillColor( 1 )
M.focusPointer.isAnimating = false

M.resetAt0 = true
M.focusedObject = 1
M.objects = {}

-- Function to move the focus rect to the buttons position
-- This should posting our pointer just to the left of the object, but
-- the pointer has to be inserted into the same group as the object so it will
-- position correctly.
function M.focusPointer:moveToPosition(object, group)
	M.focusPointer.x = object.width * -1 * object.anchorX 	+ object.x - 5
	M.focusPointer.y = object.height * -1 * object.anchorY + object.y + 5
	M.focusPointer.anchorX = object.anchorX
	M.focusPointer.anchorY = object.anchorY
	group:insert( M.focusPointer )
end


function onKeyEvent(event)
	--
	-- Corona's widget.newButton() intercepts touch events and makes up a new event table to call onPress, onRelease or twice onTouch
	-- with "began" or "ended" phases. The widget.newButton() doesn't really get "moved" phases. Because onPress and onRelease mimic 
	-- tap events, that is you don't test for an event.phase where onEvent's functions will test for an event phase, we have to be 
	-- prepare for both. Luckilly most people using "tap" style listeners ignore the event table completly except for tap count.
	-- Buttons made with display objects are likely to have real touch handlers or real tap handlers. Since we won't have movement
	-- information, we can simply get by with sending "began" and "ended" phases. "tap" listeners will ignore them

	-- our fake event table

	local e = {}
	e.name = "touch"
	e.phase = "began"
	e.id = M.objects[M.focusedObject].object.id
	e.target = M.objects[M.focusedObject].object
	e.time = system.getTimer()
	e.x = M.objects[M.focusedObject].object.x
	e.xStart = M.objects[M.focusedObject].object.x
	e.y = M.objects[M.focusedObject].object.y
	e.yStart = M.objects[M.focusedObject].object.y
	e.numTaps = 1

	-- indicate that we haven't moved yet
	M.shiftedThisEvent = false

	-- note that we are not submitting yet
	local submitItem = false

	-- This code is a  touch confusing. We want to react to the same actions as the button. Since the button can be set to:
	-- onPressed -- we want to respond when the key is pressed (i.e. down). For touch events this is the "began" phase
	-- onRelease -- we want to respond when the key is let go (i.e. up). For touch events this is the "ended" phase
	-- onEvent   -- we want to respond with both down and up events mimicking "began" and "ended". 
	-- In any case, we will be calling the handler function so set submitItem to true and patch up the event table with the
	-- right phase
	if event.phase == "down" and ( M.objects[M.focusedObject].phase == "down" or M.objects[M.focusedObject].phase == "both" ) then
		e.phase = "began"
		submitItem = true
	elseif event.phase == "up" and ( M.objects[M.focusedObject].phase == "up" or M.objects[M.focusedObject].phase == "both" )  then
		e.phase = "ended"
		submitItem = true
	end
	
	local keyName = mappedKey( event )
	-- at this point we should have a good event table. So lets see if the user wants to execute something
	-- If the submitItem flag is true and we get an "enter" key from the keyboard or a "buttonA" from a controller
	-- Then trigger the button.
	-- TODO: Add controller mapping since not every controller generates "buttonA" for buttonA
	if (keyName == "buttonA" or keyName == "enter" or keyName == "button1" or keyName == "space" ) and submitItem then
		submitItem = false
		--
		-- Dangerous hack: Our widget library is not keyboard friendly. But its likely
		-- that someone will use a widget.newSwitch in the UI. This app uses radio buttons 
		-- in one scene. Try to detect if the object is a switch or a button and if we find
		-- a switch -- right now this only works for radio buttons! then select it and call its handler
		if M.objects[M.focusedObject].object.setState then -- likely a switch widget
			M.objects[M.focusedObject].object:setState( { isOn=true, isAnimated=true } )
			M.objects[M.focusedObject].handler( e )
		else
			-- regular old button so call it's handler
			M.objects[M.focusedObject].handler( e )
		end
		--TODO fully support as many widget types as possible

		-- Animate the focus rect, give our pointer a little flicker to show it was selcted
		if M.focusPointer.isAnimating == false then
			local function returnToDefault()
				transition.to(M.focusPointer, {xScale = 1, yScale = 1, alpha = 1, time = 250, transition = easing.inOutQuad, onComplete = function()
					M.focusPointer.isAnimating = false
				end })
			end
			transition.to(M.focusPointer, {xScale = 1.2, yScale = 1.2, alpha = 0, time = 250, transition = easing.inOutQuad, onComplete = returnToDefault})
			M.focusPointer.isAnimating = true
		end
		-- we don't need to do any more processing so get out of here.
		return true
	end

	-- now we need to handle other keyboard events besides selecting the target. 
	-- For up/down actions, we will move the pointer to the next object. We can use the 'escape' 
	-- key to close any open composer overlays instead of clicking on the close button or the background.
	if event.phase == "down" then
		-- lets test for down and right to move down. We will also map the wasd keys for people used to using them
		-- for extra credit, map the VI movement keystrokes: hjkl! 
		-- TODO: allow left/right movement to switch groups. 
		if keyName == "down" or keyName == "right" or keyName == "s" or keyName == "d" then
			-- we are moving the cursor
			M.shiftedThisEvent = true
			-- increment the cursor's object by one
			M.focusedObject = M.focusedObject + 1
			-- make sure we wrap around
			if M.focusedObject > #M.objects then
				M.focusedObject = 1
			end

			-- Move the focus rect to the correct position
			if M.shiftedThisEvent then
				M.focusPointer:moveToPosition(M.objects[M.focusedObject].object, M.objects[M.focusedObject].group)
			end

		elseif keyName == "up" or keyName == "left" or keyName == "w" or keyName == "a" then
			-- we are moving the cursor
			M.shiftedThisEvent = true
			-- decrement the object by one
			M.focusedObject = M.focusedObject - 1
			-- wrap around if necessary
			if M.focusedObject < 1 then
				M.focusedObject = #M.objects
			end
			-- Move the focus rect to the correct position
			if M.shiftedThisEvent then
				M.focusPointer:moveToPosition(M.objects[M.focusedObject].object, M.objects[M.focusedObject].group)
			end
		elseif keyName == "escape" or keyName == "buttonB" then
			-- check to see if we have a composer overlay active
			local overlayName = composer.getSceneName( "overlay" )
			-- if so then hide it
			if overlayName then
				composer.hideOverlay()
			end
		end
		return true
	end
	-- IMPORTANT! Return false to indicate that this app is NOT overriding the received key
	-- This lets the operating system execute its default handling of the key
	return false
end


-- Handle axis events
-- TODO - Enable this.
local function onAxisEvent(event)

	local normalizedValue = event.normalizedValue
	local shiftedThisEvent = false

	if normalizedValue < 0.1 then
		-- avoid noisey controllers
		return
	end

	if not event.axis or event.axis.type ~= "y" then
		return
	end

	if M.resetAt0 and normalizedValue < 0.1 then
		return
	end

	M.resetAt0 = false

	-- Handle swipes
	if math.abs(normalizedValue) > 0.5 then
		if normalizedValue > 0 then
			shiftedThisEvent = true
			M.focusedObject = M.focusedObject + 1
		end
		if normalizedValue < 0 then
			shiftedThisEvent = true
			M.focusedObject = M.focusedObject - 1
		end

		-- Make the butons wrap-around
		if M.focusedObject > #M.objects then
			M.focusedObject = 1
		elseif M.focusedObject < 1 then
			M.focusedObject = #M.objects
		end

		-- Move the focus rect to the correct position
		if shiftedThisEvent then
			M.focusPointer:moveToPosition(M.objects[M.focusedObject].object, M.objects[M.focusedObject].group)
		end

		M.resetAt0 = true
	end
end

-- Initialize the controller wiht a list of buttons to access and where to start focusing
function M.init( objects, focusItem )
	M.objects = objects
	if focusItem and type( focusItem ) == "number" then
		M.focusedObject = focusItem
	end

	-- Move the focus rect to the first button
	M.focusPointer:moveToPosition(objects[M.focusedObject].object, objects[M.focusedObject].group)

end

-- Enable the event handlers
function M.start()
	-- Add the axis event listener
	Runtime:addEventListener("axis", onAxisEvent)

	-- Add the key event listener
	Runtime:addEventListener("key", onKeyEvent)
end

-- disable the event handlers.
function M.stop()
	-- Add the axis event listener
	Runtime:removeEventListener("axis", onAxisEvent)

	-- Add the key event listener
	Runtime:removeEventListener("key", onKeyEvent)
end

return M
