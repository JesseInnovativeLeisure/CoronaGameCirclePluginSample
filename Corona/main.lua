local gamecircle = require("plugin.gamecircle")
gamecircle.Init(true, true, true)
local stopwatch = require("stopwatch")

local redButton = display.newGroup()
local blueButton = display.newGroup()
local greenButton = display.newGroup()
local ui = display.newGroup()
local failDialog = display.newGroup()
local infoDialog = display.newGroup()
local waitDialog = display.newGroup()

local colorConsts = {}
colorConsts[0] = {[1] = 255, [2] = 255, [3] = 255}
colorConsts[0].word = "White"
colorConsts[1] = {[1] = 255, [2] = 000, [3] = 000}
colorConsts[1].word = "Red"
colorConsts[2] = {[1] = 000, [2] = 255, [3] = 000}
colorConsts[2].word = "Green"
colorConsts[3] = {[1] = 000, [2] = 000, [3] = 255}
colorConsts[3].word = "Blue"

math.randomseed( os.time() ) 
math.random() --To clear out first random value

local score = 0;
local state = "startup"
local wordSet



----------
-- Main & Update Function
----------
function Main()
	SetupButton(redButton, -425, 125, "button_red.png", 1)
	SetupButton(greenButton, 0, 125, "button_green.png", 2)
	SetupButton(blueButton, 425, 125, "button_blue.png", 3)
	SetupUI()
	score = 0
	NextRound()
	Runtime:addEventListener("touch", TouchEvent)
	Runtime:addEventListener("enterFrame", Update)
end

function Update()
	if score == 0 then
		ui.achievementButton.isVisible = true
		ui.leaderboardButton.isVisible = true
		ui.infoButton.isVisible = true
	else
		ui.achievementButton.isVisible = false
		ui.leaderboardButton.isVisible = false
		ui.infoButton.isVisible = false
	end
	if state == "startup" then
		print("Checking for Gamecircle")
		if gamecircle ~= nil then
			print("-- Gamecircle is ready:" .. tostring(gamecircle.IsReady()))
			if gamecircle.IsReady() then
		
				state = "play"
				waitDialog.isVisible = false
				gamecircle.GetFriendIds(FriendIdsCallback);
				gamecircle.SetSignedInListener(PlayerSignedInCallback);
			end
		end
	end
end

----------
-- Game Logic Functions
----------

function InBounds(displayObject, x, y)
	local bounds = displayObject.contentBounds
	if x > bounds.xMin and x < bounds.xMax then
		if y > bounds.yMin and y < bounds.yMax then
			return true
		end
	end
	return false
end

function NewWordSet(word1, color1, word2, color2, lineColor, answer, timelimit, failMessage)
	local newSet = {}
	newSet[1] = {}
	newSet[1].word = word1
	newSet[1].color = color1
	newSet[2] = {}
	newSet[2].word = word2
	newSet[2].color = color2
	newSet.answer = answer
	newSet.timelimit = timelimit
	newSet.lineColor = lineColor
	newSet.failMessage = failMessage
	return newSet
end

function WordSetGen1() --Level 1 Sets. Word & Color are the same
	local i = math.random(1, 3)
	local failMessage = {[1] = "", [2] = "Press the button that matches the word. It's easy!", [3] = ""}
	local newSet = NewWordSet("Word", colorConsts[i], colorConsts[i].word, colorConsts[i], colorConsts[0], i, -1, failMessage)
	return newSet
end

function WordSetGen2() -- Level 2 Sets. Word & Font Color different
	local i = math.random(1, 3)
	local j = math.random(1, 3)
	local adjust = math.random(2)
	if i == j then
		if adjust == 1 then
			j = j + 1
			if j > 3 then
				j = 1
			end
		else
			j = j - 1
			if j < 1 then
				j = 3
			end
		end
	end
	local failMessage = {[1] = "Be sure to press the button corresponding to the word.", [2] = "Don't get confused by the color of the letters.", [3] = ""}
	local newSet = NewWordSet("Word", colorConsts[j], colorConsts[i].word, colorConsts[j], colorConsts[0], i, -1, failMessage)
	return newSet
end

function WordSetGen3() -- Level 3 Sets. Instruction can be "Color" or "Word"
	local a = math.random(1, 2)
	local i = math.random(1, 3)
	local j = math.random(1, 3)
	local adjust = math.random(2)
	if i == j then
		if adjust == 1 then
			j = j + 1
			if j > 3 then
				j = 1
			end
		else
			j = j - 1
			if j < 1 then
				j = 3
			end
		end
	end
	local failMessage
	local wordSet
	if a == 1 then -- The instructions is "Word"
		failMessage = {[1] = "Be sure to watch the instruction word on the right.", [2] = "If it says \"Word\" you have to press", [3] = "the button corresponding to the word displayed."}
		wordSet = NewWordSet("Word", colorConsts[j], colorConsts[i].word, colorConsts[j], colorConsts[0], i, -1, failMessage)
	else
		failMessage = {[1] = "Be sure to watch the instruction word on the right.", [2] = "If it says \"Color\" you have to press", [3] = "the button corresponding to the color of the letters."}
		wordSet = NewWordSet("Color", colorConsts[j], colorConsts[i].word, colorConsts[j], colorConsts[0], j, -1, failMessage)
	end
	return wordSet
end

function WordSetGen4() -- Level 4 Sets. Word pairs can swap places
	local newSet = WordSetGen3()
	local a = math.random(1, 2)
	if a == 1 then --We swap the positions of the two words and their colors
		newSet = NewWordSet(newSet[2].word, newSet[2].color, newSet[1].word, newSet[1].color, newSet.lineColor, newSet.answer, newSet.timelimit, newSet.failMessage)
	end
	return newSet
end

function Reset()
	score = 0
	NextRound()
	failDialog.isVisible = false
	state = "restart"
end

function NextRound()
	local ranDecider = math.random(10)
	if score > 25 then
		wordSet = WordSetGen4()
	elseif score > 20 then
		wordSet = WordSetGen3()
	elseif score > 10 then
		if ranDecider > 5 then
			wordSet = WordSetGen2()
		else
			wordSet = WordSetGen1()
		end
	elseif score > 5 then
		wordSet = WordSetGen2()
	else
		wordSet = WordSetGen1()
	end
	UpdateUI()
end

function Failure()
	UpdateAchievements()
	state = "gameOver"
	failDialog.isVisible = true
	failDialog.message[1].text = wordSet.failMessage[1]
	failDialog.message[2].text = wordSet.failMessage[2]
	failDialog.message[3].text = wordSet.failMessage[3]
end

function GiveAnswer(answerNum)
	print("Answer Given: " .. wordSet.answer .. "|" .. answerNum)
	UpdateAchievements()
	if wordSet.answer == answerNum then
		score = score + 1
		UpdateUI()
		NextRound()
		gamecircle.Whispersync.IncrementAccumulatingNumber("correctAnswers", 1, "INT")
	else
		gamecircle.Whispersync.SetHighestNumber("localHighScore", score, "INT")
		gamecircle.Whispersync.SetLatestNumber("lastScore", score, "INT")
		gamecircle.Whispersync.SetLowestNumber("lowestScore", score, "INT")
		gamecircle.Leaderboard.SubmitScore("highscore", score)
		Failure()
	end
end

function UpdateAchievements()
	gamecircle.Achievement.UpdateAchievement("score10", (score / 10.0) * 100)
	gamecircle.Achievement.UpdateAchievement("score20", (score / 20.0) * 100)
	gamecircle.Achievement.UpdateAchievement("score30", (score / 30.0) * 100)
	gamecircle.Achievement.UpdateAchievement("score40", (score / 40.0) * 100)
	gamecircle.Achievement.UpdateAchievement("score50", (score / 50.0) * 100)
	gamecircle.Achievement.UpdateAchievement("score100", (score / 100.0) * 100)
	gamecircle.Achievement.UpdateAchievement("100redbuttons", (gamecircle.Whispersync.GetAccumulatedNumber("redButtonPresses", "INT") / 100) * 100)
	gamecircle.Achievement.UpdateAchievement("100greenbuttons", (gamecircle.Whispersync.GetAccumulatedNumber("greenButtonPresses", "INT") / 100) * 100)
	gamecircle.Achievement.UpdateAchievement("100bluebuttons", (gamecircle.Whispersync.GetAccumulatedNumber("blueButtonPresses", "INT") / 100) * 100)
	gamecircle.Achievement.UpdateAchievement("500rightanswers", (gamecircle.Whispersync.GetAccumulatedNumber("correctAnswers", "INT") / 500) * 100)
end

function CloseInfo()
	infoDialog.isVisible = false
	state = "play"
end

function OpenInfo()
	state = "viewInfo"
	UpdateInfo()
	infoDialog.isVisible = true
end

function FriendIdsCallback(returnTable)
	if returnTable.isError == true then
		print("Friend Ids Callback had an error: " .. returnTable.errorMessage)
	else
		print("===================Friend Ids Callback has returned!")
		for i = 1, returnTable.num do
			print("Friend Ids Found + " .. returnTable[i])
		end
		gamecircle.GetBatchFriends(returnTable, BatchFriendsCallback)
	end
end

function BatchFriendsCallback(returnTable)
	if returnTable.isError == true then
		print("Batch Friends Callback had an error: " .. returnTable.errorMessage)
	else
		print("===================Batch Friends Callback has returned!")
		for i = 1, returnTable.num do
			print("--Friend Found: " .. returnTable[i].alias)
		end
	end
end

function PlayerSignedInCallback(signedIn)
	if signedIn then
		print("Player signed In!")
	else
		print("Player signed out!")
	end
end

----------
-- UI Operation Functions
----------

function UpdateUI()
	ui.wordSetDisplay.leftWord.text = wordSet[1].word
	ui.wordSetDisplay.leftWord:setFillColor(wordSet[1].color[1], wordSet[1].color[2], wordSet[1].color[3])
	ui.wordSetDisplay.rightWord.text = wordSet[2].word
	ui.wordSetDisplay.rightWord:setFillColor(wordSet[2].color[1], wordSet[2].color[2], wordSet[2].color[3])
	ui.wordSetDisplay.bar:setFillColor(wordSet.lineColor[1], wordSet.lineColor[2], wordSet.lineColor[3])
	UpdateScoreText(score)
end

function UpdateInfo()
	if gamecircle.IsReady() then
		infoDialog.buttonPressRedDisplay.text = gamecircle.Whispersync.GetAccumulatedNumber("redButtonPresses", "INT")
		infoDialog.buttonPressGreenDisplay.text = gamecircle.Whispersync.GetAccumulatedNumber("greenButtonPresses", "INT")
		infoDialog.buttonPressBlueDisplay.text = gamecircle.Whispersync.GetAccumulatedNumber("blueButtonPresses", "INT")
		infoDialog.highScoreDisplay.text = gamecircle.Whispersync.GetHighestNumber("localHighScore", "INT").value .. ""
		infoDialog.latestScoreDisplay.text = gamecircle.Whispersync.GetLatestNumber("lastScore", "INT").value .. ""
		infoDialog.lowestScoreDisplay.text = gamecircle.Whispersync.GetLowestNumber("lowestScore", "INT").value .. ""
	end
end

function UpdateScoreText(newScore)
	ui.scoreText.text = newScore
	ui.scoreText.anchorX = .5
	ui.scoreText.anchorY = .5
	ui.scoreText.x = 0
	ui.scoreText.y = 20
end

function TouchEvent(event)
	if state == "gameOver" then
		if event.phase == "began" then
			if InBounds(failDialog, event.x, event.y) then
				Reset()
			end
		end
	elseif state == "viewInfo" then
		if event.phase == "began" then
			if InBounds(infoDialog, event.x, event.y) then
				CloseInfo()
			end
		end
	elseif state == "restart" then
		if event.phase == "ended" or event.phase == "cancelled" then
			state = "play"
		end
	elseif state == "play" then
		if event.phase == "ended" then
			redButton.tint.isVisible = false
			greenButton.tint.isVisible = false
			blueButton.tint.isVisible = false
			ui.achievementTint.isVisible = false
			ui.leaderboardTint.isVisible = false
			ui.infoTint.isVisible = false
			if InBounds(redButton, event.x, event.y) then
				gamecircle.Whispersync.IncrementAccumulatingNumber("redButtonPresses", 1, "INT")
				GiveAnswer(redButton.answerNum)
			end
			if InBounds(greenButton, event.x, event.y) then
				gamecircle.Whispersync.IncrementAccumulatingNumber("greenButtonPresses", 1, "INT")
				GiveAnswer(greenButton.answerNum)
			end
			if InBounds(blueButton, event.x, event.y) then
				gamecircle.Whispersync.IncrementAccumulatingNumber("blueButtonPresses", 1, "INT")
				GiveAnswer(blueButton.answerNum)
			end
			if  ui.achievementButton.isVisible and InBounds(ui.achievementButton, event.x, event.y) then
				gamecircle.Achievement.OpenOverlay()
			end
			if ui.leaderboardButton.isVisible and InBounds(ui.leaderboardButton, event.x, event.y) then
				gamecircle.Leaderboard.OpenOverlay()
			end
			if  ui.infoButton.isVisible and InBounds(ui.infoButton, event.x, event.y) then
				OpenInfo()
			end
			
		elseif event.phase == "began" or event.phase == "moved" then
			if InBounds(redButton, event.x, event.y) then
				redButton.tint.isVisible = true
			else
				redButton.tint.isVisible = false
			end
			
			if InBounds(greenButton, event.x, event.y) then
				greenButton.tint.isVisible = true
			else
				greenButton.tint.isVisible = false
			end
			
			if InBounds(blueButton, event.x, event.y) then
				blueButton.tint.isVisible = true
			else
				blueButton.tint.isVisible = false
			end
			
			if  ui.achievementButton.isVisible and InBounds(ui.achievementButton, event.x, event.y) then
				ui.achievementTint.isVisible = true
			else
				ui.achievementTint.isVisible = false
			end
			
			if ui.leaderboardButton.isVisible and InBounds(ui.leaderboardButton, event.x, event.y) then
				ui.leaderboardTint.isVisible = true
			else
				ui.leaderboardTint.isVisible = false
			end
			
			if ui.infoButton.isVisible and InBounds(ui.infoButton, event.x, event.y) then
				ui.infoTint.isVisible = true
			else
				ui.infoTint.isVisible = false
			end
		else
			redButton.tint.isVisible = false
			greenButton.tint.isVisible = false
			blueButton.tint.isVisible = false
			ui.achievementTint.isVisible = false
			ui.leaderboardTint.isVisible = false
			ui.infoTint.isVisible = false
		end
	end
end

----------
-- UI Setup Functions
----------

function SetupButton(parentGroup, centerOffsetX, centerOffsetY, circleFilename, answerNum)
	-- This function setups up a single button and is used to setup the three colored buttons at the bottom of the screen
	-- This function contains no GameCircle focused functions
	parentGroup.x = display.contentCenterX + centerOffsetX
	parentGroup.y = display.contentCenterY + centerOffsetY
	parentGroup.circle = display.newImageRect(parentGroup, circleFilename, 300, 300)
	parentGroup.circle.anchorX = .5
	parentGroup.circle.anchorY = .5
	parentGroup.circle.x = 0
	parentGroup.circle.y = 0
	parentGroup.tint = display.newRect(parentGroup, 0, 0, 300, 300)
	parentGroup.tint:setFillColor(0, 0, 0, .5)
	parentGroup.tint.isVisible = false
	parentGroup.answerNum = answerNum
end

function SetupUI()
	-- This functions sets up most of the main UI content that remains largely static during the operation of the sample
	-- This function contains no GameCircle focused functions
	
	-- Centers UI origin at top, middle of the screen
	ui.x = display.contentCenterX
	ui.y = 0
	
	--Sets up the score display 
	ui.scorePill = display.newImageRect(ui, "pill_purple.png", 400, 192)
	ui.scorePill.anchorX = .5
	ui.scorePill.anchorY = .5
	ui.scorePill.x = 0
	ui.scorePill.y = -35
	ui.scoreText = display.newText(ui, "0", 0, 0, "Groboldov", 30)
	UpdateScoreText(score)
	
	--Sets up the "Stats" button at the bottom of the screen.
	ui.infoButton = display.newGroup()
	ui:insert(ui.infoButton)
	ui.infoButton.x = 0
	ui.infoButton.y = display.contentHeight - 10
	ui.infoPill = display.newImageRect(ui.infoButton, "pill_purple.png", 150, 48)	
	ui.infoText = display.newText(ui.infoButton, "Stats", 0, 0, "Groboldov", 14)
	ui.infoText.y = -7
	ui.infoTint = display.newRect(ui.infoButton, 0, 0, 150, 48)
	ui.infoTint.anchorX = .5
	ui.infoTint.anchorY = .5
	ui.infoTint.isVisible = false
	ui.infoTint:setFillColor(0, 0, 0, .5)
	
	--Sets up the Achievement Button in one corner of the screen
	ui.achievementButton = display.newGroup()
	ui:insert(ui.achievementButton)
	ui.achievementButton.x = 0
	ui.achievementButton.y = 0
	ui.achievementPill = display.newImageRect(ui.achievementButton, "pill_purple.png", 300, 96)
	ui.achievementPill.anchorX = .5
	ui.achievementPill.anchorY = .5
	ui.achievementPill.y = 15
	ui.achievementPill.x = (display.pixelHeight / 2) - 30 --Using Height because of Landscape
	ui.achievementText = display.newText(ui.achievementButton, "Achievements", 0, 0, "Groboldov", 20)
	ui.achievementText.anchorX = 1
	ui.achievementText.anchorY = .5
	ui.achievementText.y = 22
	ui.achievementText.x = (display.pixelHeight / 2) - 10 --Using Height because of Landscape
	ui.achievementTint = display.newRect(ui.achievementButton, 0, 0, 300, 96)
	ui.achievementTint:setFillColor(0, 0, 0, .5)
	ui.achievementTint.isVisible = false
	ui.achievementTint.anchorX = .5
	ui.achievementTint.anchorY = .5
	ui.achievementTint.y = 15
	ui.achievementTint.x = (display.pixelHeight / 2) - 30 --Using Height because of Landscape
	
	--Sets up the Leaderboard button in one corner of the screen
	ui.leaderboardButton = display.newGroup()
	ui:insert(ui.leaderboardButton)
	ui.leaderboardButton.x = 0
	ui.leaderboardButton.y = 0
	ui.leaderboardPill = display.newImageRect(ui.leaderboardButton, "pill_purple.png", 300, 96) 
	ui.leaderboardPill.anchorX = .5
	ui.leaderboardPill.anchorY = .5
	ui.leaderboardPill.y = 15
	ui.leaderboardPill.x = -(display.pixelHeight / 2) + 30 --Using Height because of Landscape
	ui.leaderboardText = display.newText(ui.leaderboardButton, "Leaderboards", 0, 0, "Groboldov", 20)
	ui.leaderboardText.anchorX = 0
	ui.leaderboardText.anchorY = .5
	ui.leaderboardText.y = 22
	ui.leaderboardText.x = -(display.pixelHeight / 2) + 10 --Using Height because of Landscape
	ui.leaderboardTint = display.newRect(ui.leaderboardButton, 0, 0, 300, 96)
	ui.leaderboardTint:setFillColor(0, 0, 0, .5)
	ui.leaderboardTint.isVisible = false
	ui.leaderboardTint.anchorX = .5
	ui.leaderboardTint.anchorY = .5
	ui.leaderboardTint.y = 15
	ui.leaderboardTint.x = -(display.pixelHeight / 2)+ 30 --Using Height because of Landscape
	
	--Sets up the constant instructional text which floats beneath the score display
	ui.instructionText = display.newText(ui, "Press the button corresponding to the pair of words below.", 0, 0, "Groboldov", 30)
	ui.instructionText.anchorX = .5
	ui.instructionText.anchorY = .5
	ui.instructionText.x = 0
	ui.instructionText.y = 100
	
	--Sets up the two words and line that tell the player which button to press
	ui.wordSetDisplay = display.newGroup()
	ui.wordSetDisplay.bar = display.newText(ui, "|", 0, 0, "Groboldov", 50)
	ui.wordSetDisplay.bar.anchorX = .5
	ui.wordSetDisplay.bar.anchorY = .5
	ui.wordSetDisplay.bar.x = 0
	ui.wordSetDisplay.bar.y = 200 
	ui.wordSetDisplay.leftWord = display.newText(ui, "Word", 0, 0, "Groboldov", 50)
	ui.wordSetDisplay.leftWord.anchorX = 1
	ui.wordSetDisplay.leftWord.anchorY = .5
	ui.wordSetDisplay.leftWord.x = -30
	ui.wordSetDisplay.leftWord.y = 200
	ui.wordSetDisplay.rightWord = display.newText(ui, "Color", 0, 0, "Groboldov", 50)
	ui.wordSetDisplay.rightWord.anchorX = 0
	ui.wordSetDisplay.rightWord.anchorY = .5
	ui.wordSetDisplay.rightWord.x = 30
	ui.wordSetDisplay.rightWord.y = 200
	
	--Sets up the failure dialog that appears when a player presses the wrong button
	failDialog.x = display.contentCenterX
	failDialog.y = display.contentCenterY
	failDialog.curtain = display.newRect(failDialog, 0, 0, display.actualContentWidth, display.actualContentHeight)
	failDialog.curtain:setFillColor(0, 0, 0, .75)
	failDialog.curtain.anchorX = .5
	failDialog.curtain.anchorY = .5
	failDialog.background = display.newImageRect(failDialog, "fail_background.png", 800, 400)
	failDialog.background.x = 0
	failDialog.background.y = 0
	failDialog.background.anchorX = .5
	failDialog.background.anchorY = .5
	failDialog.title = display.newText(failDialog, "Game Over", 0, -170, "Groboldov", 40)
	failDialog.title.anchorX = .5
	failDialog.title.anchorY = .5
	failDialog.message = {}
	failDialog.message[1] = display.newText(failDialog, "First Line of the Fail Dialog", 0, -100, "Groboldov", 30)
	failDialog.message[1].anchorX = .5
	failDialog.message[1].anchorY = .5
	failDialog.message[2] = display.newText(failDialog, "Second Line of the Fail Dialog", 0, -50, "Groboldov", 30)
	failDialog.message[2].anchorX = .5
	failDialog.message[2].anchorY = .5
	failDialog.message[3] = display.newText(failDialog, "Third Line of the Fail Dialog", 0, 0, "Groboldov", 30)
	failDialog.message[3].anchorX = .5
	failDialog.message[3].anchorY = .5
	failDialog.tapMessage = display.newText(failDialog, "Tap this Popup to Play Again", 0, 175, "Groboldov", 20)
	failDialog.tapMessage.anchorX = .5
	failDialog.tapMessage.anchorY = .5
	failDialog.isVisible = false;
	
	--Sets up the info dialog that appears when a player hits the "info" button
	infoDialog.x = display.contentCenterX
	infoDialog.y = display.contentCenterY
	infoDialog.curtain = display.newRect(infoDialog, 0, 0, display.actualContentWidth, display.actualContentHeight)
	infoDialog.curtain:setFillColor(0, 0, 0, .75)
	infoDialog.curtain.anchorX = .5
	infoDialog.curtain.anchorY = .5
	infoDialog.background = display.newImageRect(infoDialog, "info_background.png", 800, 700)
	infoDialog.background.x = 0
	infoDialog.background.y = 0
	infoDialog.background.anchorX = .5
	infoDialog.background.anchorY = .5
	infoDialog.title = display.newText(infoDialog, "Stats", 0, -300, "Groboldov", 50)
	infoDialog.title.anchorX = .5
	infoDialog.title.anchorY = .5
	infoDialog.buttonPressLabel = display.newText(infoDialog, "Button Press Counts", 0, -245, "Groboldov", 30)
	infoDialog.buttonPressRedLabel = display.newText(infoDialog, "Red", -100, -215, "Groboldov", 20)
	infoDialog.buttonPressGreenLabel = display.newText(infoDialog, "Green", 0, -215, "Groboldov", 20)
	infoDialog.buttonPressBlueLabel = display.newText(infoDialog, "Blue", 100, -215, "Groboldov", 20)
	infoDialog.buttonPressRedDisplay = display.newText(infoDialog, "0", -100, -195, "Groboldov", 20)
	infoDialog.buttonPressGreenDisplay = display.newText(infoDialog, "0", 0, -195, "Groboldov", 20)
	infoDialog.buttonPressBlueDisplay = display.newText(infoDialog, "0", 100, -195, "Groboldov", 20)
	infoDialog.highScoreLabel = display.newText(infoDialog, "High Score", 0, -150, "Groboldov", 30)
	infoDialog.highScoreDisplay = display.newText(infoDialog, "0", 0, -120, "Groboldov", 20)
	infoDialog.latestScoreLabel = display.newText(infoDialog, "Latest Score", 0, -75, "Groboldov", 30)
	infoDialog.latestScoreDisplay = display.newText(infoDialog, "0", 0, -45, "Groboldov", 20)
	infoDialog.lowestScorelabel = display.newText(infoDialog, "Lowest Score", 0, 0, "Groboldov", 30)
	infoDialog.lowestScoreDisplay = display.newText(infoDialog, "0", 0, 30, "Groboldov", 20)
	infoDialog.tapMessage = display.newText(infoDialog, "Tap this Popup to Close", 0, 320, "Groboldov", 20)
	infoDialog.tapMessage.anchorX = .5
	infoDialog.tapMessage.anchorY = .5
	infoDialog.isVisible = false
	
	
	--Sets up the wait dialog that appears while the system is still connecting/setting up Gamecircle Featuers
	waitDialog.x = display.contentCenterX
	waitDialog.y = display.contentCenterY
	waitDialog.curtain = display.newRect(waitDialog, 0, 0, display.actualContentWidth, display.actualContentHeight)
	waitDialog.curtain:setFillColor(0, 0, 0, .75)
	waitDialog.curtain.anchorX = .5
	waitDialog.curtain.anchorY = .5
	waitDialog.background = display.newImageRect(waitDialog, "fail_background.png", 800, 400)
	waitDialog.background.x = 0
	waitDialog.background.y = 0
	waitDialog.background.anchorX = .5
	waitDialog.background.anchorY = .5
	waitDialog.title = display.newText(waitDialog, "Game Over", 0, -170, "Groboldov", 40)
	waitDialog.title.anchorX = .5
	waitDialog.title.anchorY = .5
	waitDialog.message = display.newText(waitDialog, "Please wait while Amazon GameCircle initializes.", 0, 0, "Groboldov", 30)
	waitDialog.message.anchorX = .5
	waitDialog.message.anchorY = .5
	
	UpdateInfo()
	
end



-- WHERE THE MAIN CODE IS LAUNCHED
Main()

