--------
-- Stopwatch Timing Class, v1.2.1
--
-- by Kyle Coburn
-- 10 April 2012
----
-- For the latest updates, release notes, and support/feedback:
-- http://developer.anscamobile.com/code/stopwatch-timing-class
----
-- Usage:
-- local stopwatch = require "stopwatch"
--
-- stopwatch.new() --Counts up indefinitely
-- stopwatch.new( 60 ) --Counts down from 60 seconds
--------

local stopwatch = {}
local stopwatch_mt = { __index = stopwatch }

local floor, getTime = math.floor, system.getTimer


local function timeFormat(secs)
	if (secs < 1) then
		return "00:00"
	end
	local mins = "00"
	if (secs > 59) then
		mins = floor(secs / 60)
		if (mins < 10) then
			mins = "0"..mins
		end
		secs = secs % 60
	end
	if (secs < 10) then
		secs = "0"..secs
	end
	return mins..":"..secs
end


-- Time check
function stopwatch:getElapsed()
	if (self._pauseStart) then
		return self._pauseStart - self._startTime
	end
	return getTime() - self._startTime
end

function stopwatch:getElapsedSeconds()
	return floor(self:getElapsed() / 1000)
end

function stopwatch:getRemaining()
	if (self._pauseStart) then
		return self._endTime - self._pauseStart
	end
	return self._endTime - getTime()
end

function stopwatch:getRemainingSeconds()
	return floor(self:getRemaining() / 1000)
end

function stopwatch:isElapsed()
	if (self._endTime) then
		return self:getRemaining() <= 0
	end
end


-- Modify
function stopwatch:addTime(seconds)
	if (self._endTime) then
		self._endTime = self._endTime + seconds * 1000
	else
		self._startTime = self._startTime - seconds * 1000
	end
end


-- Pause
function stopwatch:isPaused()
	return self._pauseStart ~= nil
end

function stopwatch:pause()
	if (not self:isPaused()) then
		self._pauseStart = getTime()
	end
end

function stopwatch:resume()
	if (self:isPaused()) then
		if (self._endTime) then
			self._endTime = self._endTime + (getTime() - self._pauseStart)
		else
			self._startTime = self._startTime + (getTime() - self._pauseStart)
		end
		self._pauseStart = nil
	end
end


-- Formatting
function stopwatch:toElapsedString()
	return timeFormat(self:getElapsedSeconds())
end

function stopwatch:toRemainingString()
	if (not self._endTime) then
		return "99:99"
	end
	return timeFormat(self:getRemainingSeconds())
end


-- Object creation
function stopwatch.new(countdown)
	local newTimer = {}
	local startTime = getTime()

	if (countdown) then
		newTimer._endTime = startTime + countdown * 1000
	end
	newTimer._startTime = startTime

	return setmetatable(newTimer, stopwatch_mt)
end

stopwatch.format = timeFormat


return stopwatch