-- Author: FSG Modding
-- Name: Random Foliage by Paint Tool
-- Description: Paints random foliage for texture area that selecting transform is located on.
-- Icon:
-- Hide: no
-- Date: 1.3.2025

RanFoliagePaint = {}
RanFoliagePaint.WINDOW_WIDTH = 300
RanFoliagePaint.WINDOW_HEIGHT = -1
RanFoliagePaint.TEXT_WIDTH = 230
RanFoliagePaint.TEXT_HEIGHT = -1
RanFoliagePaint.GAME_INSTALL_FOLDER = "C:/Program Files (x86)/Farming Simulator 2025/"
RanFoliagePaint.TRACKER_SIZE = 100
RanFoliagePaint.PARTITIONS_TOTAL = 64
RanFoliagePaint.DENSITY_MAP_CHANNELS = 4

-- Get things started
function RanFoliagePaint.new()
    local self = setmetatable({}, {__index=RanFoliagePaint})

    self.window = nil
    if g_currentRunFoliagePaintDialog ~= nil then
        g_currentRunFoliagePaintDialog:close()
    end

    self.foliageLayers = {}
    self.foliageStates = {}
    self.foliageStatesStart = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15" }
    self.foliageStatesNames = {}

    self.foliageLayer1 = 1
    self.foliageLayer1_State1 = 1
    self.foliageLayer1_State2 = 1
    self.foliageLayer1_State3 = 1

    self.folLayer1_Choice = 1
    self.folLayer1_State1_Choice = 1
    self.folLayer1_State2_Choice = 1
    self.folLayer1_State3_Choice = 1

    self.foliageLayer2 = 1
    self.foliageLayer2_State1 = 1
    self.foliageLayer2_State2 = 1
    self.foliageLayer2_State3 = 1

    self.folLayer2_Choice = 1
    self.folLayer2_State1_Choice = 1
    self.folLayer2_State2_Choice = 1
    self.folLayer2_State3_Choice = 1

    self.foliageLayer3 = 1
    self.foliageLayer3_State1 = 1
    self.foliageLayer3_State2 = 1
    self.foliageLayer3_State3 = 1

    self.folLayer3_Choice = 1
    self.folLayer3_State1_Choice = 1
    self.folLayer3_State2_Choice = 1
    self.folLayer3_State3_Choice = 1

    self.foliageLayer4 = 1
    self.foliageLayer4_State1 = 1
    self.foliageLayer4_State2 = 1
    self.foliageLayer4_State3 = 1

    self.folLayer4_Choice = 1
    self.folLayer4_State1_Choice = 1
    self.folLayer4_State2_Choice = 1
    self.folLayer4_State3_Choice = 1

    self.foliageLayer5 = 1
    self.foliageLayer5_State1 = 1
    self.foliageLayer5_State2 = 1
    self.foliageLayer5_State3 = 1

    self.folLayer5_Choice = 1
    self.folLayer5_State1_Choice = 1
    self.folLayer5_State2_Choice = 1
    self.folLayer5_State3_Choice = 1

    self.foliageDistance = 5              -- Radius of how far apart foliage is created from others
    self.mapPartition = 0                 -- Limit foliage creation to this partition number
    self.spacing = 1.0                    -- Spacing for foliage creations

    self.CurLocColorR = 0
    self.CurLocColorG = 0
    self.CurLocColorB = 0
    self.CurLocColorW = 0
    self.CurLocColorU = 0

    self:getFoliageLayers()

    self:generateUI()

    g_currentRunFoliagePaintDialog = self

    return self
end

-- Generate UI Function
function RanFoliagePaint:generateUI()
    -- Setup UI
    local frameRowSizer = UIRowLayoutSizer.new()
    self.window = UIWindow.new(frameRowSizer, "Random Foliage by Texture")

    local borderSizer = UIRowLayoutSizer.new()
    UIPanel.new(frameRowSizer, borderSizer)

    local rowSizer = UIRowLayoutSizer.new()
    UIPanel.new(borderSizer, rowSizer, -1, -1, RanFoliagePaint.WINDOW_WIDTH, RanFoliagePaint.WINDOW_HEIGHT, BorderDirection.ALL, 10, 1)

    -- First Layer Set
    local title = UILabel.new(rowSizer, "First Random Foliage Layer and States", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    title:setBold(true)
    UIHorizontalLine.new(rowSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)

    local folLayerPanelSizer = UIGridSizer.new(1, 2, 2, 2)
    local folLayerPanel = UIPanel.new(rowSizer, folLayerPanelSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    local folLayerLabel = UILabel.new(folLayerPanelSizer, "Foliage Type", false, TextAlignment.LEFT, VerticalAlignment.TOP, RanFoliagePaint.TEXT_WIDTH, -1)
    self.folLayer1_Choice = UIChoice.new(folLayerPanelSizer, self.foliageLayers, 0, -1, 100, -1)
    self.folLayer1_Choice:setOnChangeCallback(function(value) self:setFoliageLayer1(value) end)

    local folLayerPanelSizer = UIGridSizer.new(1, 2, 2, 2)
    local folLayerPanel = UIPanel.new(rowSizer, folLayerPanelSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    local folLayerLabel = UILabel.new(folLayerPanelSizer, "State 1", false, TextAlignment.LEFT, VerticalAlignment.TOP, RanFoliagePaint.TEXT_WIDTH, -1)
    self.folLayer1_State1_Choice = UIChoice.new(folLayerPanelSizer, self.foliageStatesStart, 0, -1, 100, -1)
    self.folLayer1_State1_Choice:setOnChangeCallback(function(value) self:setFoliageLayer1_State1(value) end)

    local folLayerPanelSizer = UIGridSizer.new(1, 2, 2, 2)
    local folLayerPanel = UIPanel.new(rowSizer, folLayerPanelSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    local folLayerLabel = UILabel.new(folLayerPanelSizer, "State 2", false, TextAlignment.LEFT, VerticalAlignment.TOP, RanFoliagePaint.TEXT_WIDTH, -1)
    self.folLayer1_State2_Choice = UIChoice.new(folLayerPanelSizer, self.foliageStatesStart, 0, -1, 100, -1)
    self.folLayer1_State2_Choice:setOnChangeCallback(function(value) self:setFoliageLayer1_State2(value) end)

    local folLayerPanelSizer = UIGridSizer.new(1, 2, 2, 2)
    local folLayerPanel = UIPanel.new(rowSizer, folLayerPanelSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    local folLayerLabel = UILabel.new(folLayerPanelSizer, "State 3", false, TextAlignment.LEFT, VerticalAlignment.TOP, RanFoliagePaint.TEXT_WIDTH, -1)
    self.folLayer1_State3_Choice = UIChoice.new(folLayerPanelSizer, self.foliageStatesStart, 0, -1, 100, -1)
    self.folLayer1_State3_Choice:setOnChangeCallback(function(value) self:setFoliageLayer1_State3(value) end)

    -- Second Layer Set
    local title = UILabel.new(rowSizer, "", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    local title = UILabel.new(rowSizer, "Second Random Foliage Layer and States", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    title:setBold(true)
    UIHorizontalLine.new(rowSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)

    local folLayerPanelSizer = UIGridSizer.new(1, 2, 2, 2)
    local folLayerPanel = UIPanel.new(rowSizer, folLayerPanelSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    local folLayerLabel = UILabel.new(folLayerPanelSizer, "Foliage Type", false, TextAlignment.LEFT, VerticalAlignment.TOP, RanFoliagePaint.TEXT_WIDTH, -1)
    self.folLayer2_Choice = UIChoice.new(folLayerPanelSizer, self.foliageLayers, 0, -1, 100, -1)
    self.folLayer2_Choice:setOnChangeCallback(function(value) self:setFoliageLayer2(value) end)

    local folLayerPanelSizer = UIGridSizer.new(1, 2, 2, 2)
    local folLayerPanel = UIPanel.new(rowSizer, folLayerPanelSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    local folLayerLabel = UILabel.new(folLayerPanelSizer, "State 1", false, TextAlignment.LEFT, VerticalAlignment.TOP, RanFoliagePaint.TEXT_WIDTH, -1)
    self.folLayer2_State1_Choice = UIChoice.new(folLayerPanelSizer, self.foliageStatesStart, 0, -1, 100, -1)
    self.folLayer2_State1_Choice:setOnChangeCallback(function(value) self:setFoliageLayer2_State1(value) end)

    local folLayerPanelSizer = UIGridSizer.new(1, 2, 2, 2)
    local folLayerPanel = UIPanel.new(rowSizer, folLayerPanelSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    local folLayerLabel = UILabel.new(folLayerPanelSizer, "State 2", false, TextAlignment.LEFT, VerticalAlignment.TOP, RanFoliagePaint.TEXT_WIDTH, -1)
    self.folLayer2_State2_Choice = UIChoice.new(folLayerPanelSizer, self.foliageStatesStart, 0, -1, 100, -1)
    self.folLayer2_State2_Choice:setOnChangeCallback(function(value) self:setFoliageLayer2_State2(value) end)

    local folLayerPanelSizer = UIGridSizer.new(1, 2, 2, 2)
    local folLayerPanel = UIPanel.new(rowSizer, folLayerPanelSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    local folLayerLabel = UILabel.new(folLayerPanelSizer, "State 3", false, TextAlignment.LEFT, VerticalAlignment.TOP, RanFoliagePaint.TEXT_WIDTH, -1)
    self.folLayer2_State3_Choice = UIChoice.new(folLayerPanelSizer, self.foliageStatesStart, 0, -1, 100, -1)
    self.folLayer2_State3_Choice:setOnChangeCallback(function(value) self:setFoliageLayer2_State3(value) end)

    -- Third Layer Set
    local title = UILabel.new(rowSizer, "", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    local title = UILabel.new(rowSizer, "Third Random Foliage Layer and States", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    title:setBold(true)
    UIHorizontalLine.new(rowSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)

    local folLayerPanelSizer = UIGridSizer.new(1, 2, 2, 2)
    local folLayerPanel = UIPanel.new(rowSizer, folLayerPanelSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    local folLayerLabel = UILabel.new(folLayerPanelSizer, "Foliage Type", false, TextAlignment.LEFT, VerticalAlignment.TOP, RanFoliagePaint.TEXT_WIDTH, -1)
    self.folLayer3_Choice = UIChoice.new(folLayerPanelSizer, self.foliageLayers, 0, -1, 100, -1)
    self.folLayer3_Choice:setOnChangeCallback(function(value) self:setFoliageLayer3(value) end)

    local folLayerPanelSizer = UIGridSizer.new(1, 2, 2, 2)
    local folLayerPanel = UIPanel.new(rowSizer, folLayerPanelSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    local folLayerLabel = UILabel.new(folLayerPanelSizer, "State 1", false, TextAlignment.LEFT, VerticalAlignment.TOP, RanFoliagePaint.TEXT_WIDTH, -1)
    self.folLayer3_State1_Choice = UIChoice.new(folLayerPanelSizer, self.foliageStatesStart, 0, -1, 100, -1)
    self.folLayer3_State1_Choice:setOnChangeCallback(function(value) self:setFoliageLayer3_State1(value) end)

    local folLayerPanelSizer = UIGridSizer.new(1, 2, 2, 2)
    local folLayerPanel = UIPanel.new(rowSizer, folLayerPanelSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    local folLayerLabel = UILabel.new(folLayerPanelSizer, "State 2", false, TextAlignment.LEFT, VerticalAlignment.TOP, RanFoliagePaint.TEXT_WIDTH, -1)
    self.folLayer3_State2_Choice = UIChoice.new(folLayerPanelSizer, self.foliageStatesStart, 0, -1, 100, -1)
    self.folLayer3_State2_Choice:setOnChangeCallback(function(value) self:setFoliageLayer3_State2(value) end)

    local folLayerPanelSizer = UIGridSizer.new(1, 2, 2, 2)
    local folLayerPanel = UIPanel.new(rowSizer, folLayerPanelSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    local folLayerLabel = UILabel.new(folLayerPanelSizer, "State 3", false, TextAlignment.LEFT, VerticalAlignment.TOP, RanFoliagePaint.TEXT_WIDTH, -1)
    self.folLayer3_State3_Choice = UIChoice.new(folLayerPanelSizer, self.foliageStatesStart, 0, -1, 100, -1)
    self.folLayer3_State3_Choice:setOnChangeCallback(function(value) self:setFoliageLayer3_State3(value) end)

    -- Forth Layer Set
    local title = UILabel.new(rowSizer, "", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    local title = UILabel.new(rowSizer, "Forth Random Foliage Layer and States", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    title:setBold(true)
    UIHorizontalLine.new(rowSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)

    local folLayerPanelSizer = UIGridSizer.new(1, 2, 2, 2)
    local folLayerPanel = UIPanel.new(rowSizer, folLayerPanelSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    local folLayerLabel = UILabel.new(folLayerPanelSizer, "Foliage Type", false, TextAlignment.LEFT, VerticalAlignment.TOP, RanFoliagePaint.TEXT_WIDTH, -1)
    self.folLayer4_Choice = UIChoice.new(folLayerPanelSizer, self.foliageLayers, 0, -1, 100, -1)
    self.folLayer4_Choice:setOnChangeCallback(function(value) self:setFoliageLayer4(value) end)

    local folLayerPanelSizer = UIGridSizer.new(1, 2, 2, 2)
    local folLayerPanel = UIPanel.new(rowSizer, folLayerPanelSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    local folLayerLabel = UILabel.new(folLayerPanelSizer, "State 1", false, TextAlignment.LEFT, VerticalAlignment.TOP, RanFoliagePaint.TEXT_WIDTH, -1)
    self.folLayer4_State1_Choice = UIChoice.new(folLayerPanelSizer, self.foliageStatesStart, 0, -1, 100, -1)
    self.folLayer4_State1_Choice:setOnChangeCallback(function(value) self:setFoliageLayer4_State1(value) end)

    local folLayerPanelSizer = UIGridSizer.new(1, 2, 2, 2)
    local folLayerPanel = UIPanel.new(rowSizer, folLayerPanelSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    local folLayerLabel = UILabel.new(folLayerPanelSizer, "State 2", false, TextAlignment.LEFT, VerticalAlignment.TOP, RanFoliagePaint.TEXT_WIDTH, -1)
    self.folLayer4_State2_Choice = UIChoice.new(folLayerPanelSizer, self.foliageStatesStart, 0, -1, 100, -1)
    self.folLayer4_State2_Choice:setOnChangeCallback(function(value) self:setFoliageLayer4_State2(value) end)

    local folLayerPanelSizer = UIGridSizer.new(1, 2, 2, 2)
    local folLayerPanel = UIPanel.new(rowSizer, folLayerPanelSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    local folLayerLabel = UILabel.new(folLayerPanelSizer, "State 3", false, TextAlignment.LEFT, VerticalAlignment.TOP, RanFoliagePaint.TEXT_WIDTH, -1)
    self.folLayer4_State3_Choice = UIChoice.new(folLayerPanelSizer, self.foliageStatesStart, 0, -1, 100, -1)
    self.folLayer4_State3_Choice:setOnChangeCallback(function(value) self:setFoliageLayer4_State3(value) end)

    -- Fifth Layer Set
    local title = UILabel.new(rowSizer, "", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    local title = UILabel.new(rowSizer, "Fifth Random Foliage Layer and States", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    title:setBold(true)
    UIHorizontalLine.new(rowSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)

    local folLayerPanelSizer = UIGridSizer.new(1, 2, 2, 2)
    local folLayerPanel = UIPanel.new(rowSizer, folLayerPanelSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    local folLayerLabel = UILabel.new(folLayerPanelSizer, "Foliage Type", false, TextAlignment.LEFT, VerticalAlignment.TOP, RanFoliagePaint.TEXT_WIDTH, -1)
    self.folLayer5_Choice = UIChoice.new(folLayerPanelSizer, self.foliageLayers, 0, -1, 100, -1)
    self.folLayer5_Choice:setOnChangeCallback(function(value) self:setFoliageLayer5(value) end)

    local folLayerPanelSizer = UIGridSizer.new(1, 2, 2, 2)
    local folLayerPanel = UIPanel.new(rowSizer, folLayerPanelSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    local folLayerLabel = UILabel.new(folLayerPanelSizer, "State 1", false, TextAlignment.LEFT, VerticalAlignment.TOP, RanFoliagePaint.TEXT_WIDTH, -1)
    self.folLayer5_State1_Choice = UIChoice.new(folLayerPanelSizer, self.foliageStatesStart, 0, -1, 100, -1)
    self.folLayer5_State1_Choice:setOnChangeCallback(function(value) self:setFoliageLayer5_State1(value) end)

    local folLayerPanelSizer = UIGridSizer.new(1, 2, 2, 2)
    local folLayerPanel = UIPanel.new(rowSizer, folLayerPanelSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    local folLayerLabel = UILabel.new(folLayerPanelSizer, "State 2", false, TextAlignment.LEFT, VerticalAlignment.TOP, RanFoliagePaint.TEXT_WIDTH, -1)
    self.folLayer5_State2_Choice = UIChoice.new(folLayerPanelSizer, self.foliageStatesStart, 0, -1, 100, -1)
    self.folLayer5_State2_Choice:setOnChangeCallback(function(value) self:setFoliageLayer5_State2(value) end)

    local folLayerPanelSizer = UIGridSizer.new(1, 2, 2, 2)
    local folLayerPanel = UIPanel.new(rowSizer, folLayerPanelSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    local folLayerLabel = UILabel.new(folLayerPanelSizer, "State 3", false, TextAlignment.LEFT, VerticalAlignment.TOP, RanFoliagePaint.TEXT_WIDTH, -1)
    self.folLayer5_State3_Choice = UIChoice.new(folLayerPanelSizer, self.foliageStatesStart, 0, -1, 100, -1)
    self.folLayer5_State3_Choice:setOnChangeCallback(function(value) self:setFoliageLayer5_State3(value) end)

    -- Run Script Button
    local title = UILabel.new(rowSizer, "", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    local title = UILabel.new(rowSizer, "Click Run Script to Start", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    title:setBold(true)
    UIHorizontalLine.new(rowSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)

    UIButton.new(rowSizer, "Run Script", function() self:runFoliagePainter() end, self, -1, -1, -1, -1, BorderDirection.BOTTOM, 2, 1)

    -- Show States In Console
    local title = UILabel.new(rowSizer, "", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    local title = UILabel.new(rowSizer, "List out all available foliage and states in console.", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    title:setBold(true)
    UIHorizontalLine.new(rowSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)

    UIButton.new(rowSizer, "Show Foliage States in Console", function() self:runFoliageStatesPrint() end, self, -1, -1, -1, -1, BorderDirection.BOTTOM, 2, 1)

    -- layout and show window
    self.window:setOnCloseCallback(function() self:onClose() end)
    self.window:showWindow()

end

function RanFoliagePaint:close()
    self.window:close()
end

function RanFoliagePaint:onClose()
    -- Clears out any active functions
end

-- Function to see if a foliage is too close to another before it plants a new one.
function RanFoliagePaint:checkForNoFoliageConflict(x, y, z, mTerrainID)
    local placeFoliage = true
    -- Only plant foliages on allowed terrain paint.
    local cR, cG, cB, cW, cU = getTerrainAttributesAtWorldPos(mTerrainID, x, y, z, true, true, true, true, false)
    cR = string.format("%.12f",cR)
    cG = string.format("%.12f",cG)
    cB = string.format("%.12f",cB)
    cW = string.format("%f",cW)
    cU = string.format("%f",cU)
    -- print("Checking Foliage Color Codes: R: "..cR.." G: "..cG.." B: "..cB.." W: "..cW.." U:" .. cU)
    if cR == self.CurLocColorR and cG == self.CurLocColorG and cB == self.CurLocColorB and cW == self.CurLocColorW then
        -- Matched color to current top foliage location
        placeFoliage = true
    else
        placeFoliage = false
    end
    return placeFoliage
end

function RanFoliagePaint:crossProduct(ax, ay, az, bx, by, bz)
    return ay * bz - az * by, az * bx - ax * bz, ax * by - ay * bx
end

function RanFoliagePaint:runFoliagePainter()
    print("Run Foliage Painter Function");

    if self.foliageLayer1 == nil then
      self.foliageLayer1 = 1
    end

    if self.foliageLayer1_state1 == nil then
      self.foliageLayer1_state1 = 1
    end

    -- print("self.foliageLayer1 : ")
    -- print(self.foliageLayer1)
    -- print("self.foliageLayer1_state1 : ")
    -- print(self.foliageLayer1_state1)

    -- Get terrain node Id
    local mSceneID = getRootNode()
    local mTerrainID = 0

    for i = 0, getNumOfChildren(mSceneID) - 1 do
        local mID = getChildAt(mSceneID, i)
        if (getName(mID) == "terrain") then
            mTerrainID = mID
            break
        end
    end

    if (mTerrainID == 0) then
        printError("Error: Terrain node not found. Node needs to be named 'terrain'.")
        return nil
    end


    -- Auto get color of texture that the first foliage selected is currently on.
    local transformNodeId = getSelection(0)
    if transformNodeId ~= nil and transformNodeId ~= 0 then

        local tx,ty,tz = getTranslation(transformNodeId)
        local CurLocColorR, CurLocColorG, CurLocColorB, CurLocColorW, CurLocColorU = getTerrainAttributesAtWorldPos(mTerrainID, tx, ty, tz, true, true, true, true, false)

        self.CurLocColorR = string.format("%.12f",CurLocColorR)
        self.CurLocColorG = string.format("%.12f",CurLocColorG)
        self.CurLocColorB = string.format("%.12f",CurLocColorB)
        self.CurLocColorW = string.format("%f",CurLocColorW)
        self.CurLocColorU = string.format("%f",CurLocColorU)

        print("Selected Transform Location: X: "..tx.." Y: "..ty.." Z: "..tz)
        print("Selected Transform Color Codes: R: "..self.CurLocColorR.." G: "..self.CurLocColorG.." B: "..self.CurLocColorB.." W: "..self.CurLocColorW .. " U: "..self.CurLocColorU)

    else
        printError("Please select a transform that is placed on the texture you would like foliage to be randomly painted on.")
        return
    end


    -- Do stuff with area for random stuffs
    local terrainSize = getTerrainSize(mTerrainID)
    local halfTerrainSize = terrainSize / 2

    -- Number of sections
    local numSectionsX = math.sqrt(RanFoliagePaint.PARTITIONS_TOTAL)
    local numSectionsY = math.sqrt(RanFoliagePaint.PARTITIONS_TOTAL)

    -- Get the section radius
    local sectionSize = terrainSize / numSectionsX
    local sectionSizeHalf = sectionSize / 2

    print(string.format("Section Size: %d - Section Size Half: %d", sectionSize, sectionSizeHalf))

    -- Put the modifiers together for random placement
    local modifiers = {}
    local states = {}
    local states1 = {}
    local states2 = {}
    local states3 = {}
    local states4 = {}
    local states5 = {}

    local modifier1 = self:buildModifier(mTerrainID,self.foliageLayers,self.foliageLayer1)
    if modifier1 ~= nil then
      table.insert(modifiers, modifier1)
      if self.foliageLayer1_state1 ~= nil and self.foliageLayer1_state1 ~= 0 then
        table.insert(states1, self.foliageLayer1_state1)
      end
      if self.foliageLayer1_state2 ~= nil and self.foliageLayer1_state2 ~= 0 then
        table.insert(states1, self.foliageLayer1_state2)
      end
      if self.foliageLayer1_state3 ~= nil and self.foliageLayer1_state3 ~= 0 then
        table.insert(states1, self.foliageLayer1_state3)
      end
      if states1 ~= nil then
        table.insert(states, states1)
      end
    end

    local modifier2 = self:buildModifier(mTerrainID,self.foliageLayers,self.foliageLayer2)
    if modifier2 ~= nil then
      table.insert(modifiers, modifier2)
      if self.foliageLayer2_state1 ~= nil and self.foliageLayer2_state1 ~= 0 then
        table.insert(states2, self.foliageLayer2_state1)
      end
      if self.foliageLayer2_state2 ~= nil and self.foliageLayer2_state2 ~= 0 then
        table.insert(states2, self.foliageLayer2_state2)
      end
      if self.foliageLayer2_state3 ~= nil and self.foliageLayer2_state3 ~= 0 then
        table.insert(states2, self.foliageLayer2_state3)
      end
      if states2 ~= nil then
        table.insert(states, states2)
      end
    end

    local modifier3 = self:buildModifier(mTerrainID,self.foliageLayers,self.foliageLayer3)
    if modifier3 ~= nil then
      table.insert(modifiers, modifier3)
      if self.foliageLayer3_state1 ~= nil and self.foliageLayer3_state1 ~= 0 then
        table.insert(states3, self.foliageLayer3_state1)
      end
      if self.foliageLayer3_state2 ~= nil and self.foliageLayer3_state2 ~= 0 then
        table.insert(states3, self.foliageLayer3_state2)
      end
      if self.foliageLayer3_state3 ~= nil and self.foliageLayer3_state3 ~= 0 then
        table.insert(states3, self.foliageLayer3_state3)
      end
      if states3 ~= nil then
        table.insert(states, states3)
      end
    end

    local modifier4 = self:buildModifier(mTerrainID,self.foliageLayers,self.foliageLayer4)
    if modifier4 ~= nil then
      table.insert(modifiers, modifier4)
      if self.foliageLayer4_state1 ~= nil and self.foliageLayer4_state1 ~= 0 then
        table.insert(states4, self.foliageLayer4_state1)
      end
      if self.foliageLayer4_state2 ~= nil and self.foliageLayer4_state2 ~= 0 then
        table.insert(states4, self.foliageLayer4_state2)
      end
      if self.foliageLayer4_state3 ~= nil and self.foliageLayer4_state3 ~= 0 then
        table.insert(states4, self.foliageLayer4_state3)
      end
      if states4 ~= nil then
        table.insert(states, states4)
      end
    end

    local modifier5 = self:buildModifier(mTerrainID,self.foliageLayers,self.foliageLayer5)
    if modifier5 ~= nil then
      table.insert(modifiers, modifier5)
      if self.foliageLayer5_state1 ~= nil and self.foliageLayer5_state1 ~= 0 then
        table.insert(states5, self.foliageLayer5_state1)
      end
      if self.foliageLayer5_state2 ~= nil and self.foliageLayer5_state2 ~= 0 then
        table.insert(states5, self.foliageLayer5_state2)
      end
      if self.foliageLayer5_state3 ~= nil and self.foliageLayer5_state3 ~= 0 then
        table.insert(states5, self.foliageLayer5_state3)
      end
      if states5 ~= nil then
        table.insert(states, states5)
      end
    end

    -- These are the main variables to process everything.
    local origX = 0
    local origZ = 0
    local x = 0
    local y = 0
    local z = 0
    local foliagesPlaced = 0

    -- Calculate the width and height of each section
    local sectionWidth = sectionSize
    local sectionHeight = sectionSize

    -- Table to store center points
    local centerPoints = {}

    -- Calculate center points
    for i = 0, numSectionsX - 1 do
        for j = 0, numSectionsY - 1 do
            local centerX = (i * sectionWidth) + (sectionWidth / 2) - (halfTerrainSize)
            local centerY = (j * sectionHeight) + (sectionHeight / 2) - (halfTerrainSize)
            table.insert(centerPoints, {x = centerX, z = centerY})
        end
    end

    -- Print the center points
    for index, point in ipairs(centerPoints) do

        -- Check if user wants to only do one partition
        if self.mapPartition == 0 or (self.mapPartition > 0 and self.mapPartition == index) then

            print(string.format("Section %d: Center (x, y) = (%.2f, %.2f)", index, point.x, point.z))

            x = point.x
            z = point.z

            local foliageTracker = RanFoliagePaint.TRACKER_SIZE


            while(foliageTracker > 0) do
                origX = point.x
                origZ = point.z
                local foliagePlacedCheck = false
                local maxFoliage = 500
                
                for i=1, maxFoliage do

                    local randomX = math.random(-sectionSizeHalf,sectionSizeHalf)
                    local randomZ = math.random(-sectionSizeHalf,sectionSizeHalf)

                    local newX = origX+randomX
                    local newZ = origZ+randomZ

                    local terrainHeight = getTerrainHeightAtWorldPos(mTerrainID, newX, 0, newZ)

                    if self:checkForNoFoliageConflict(newX, terrainHeight, newZ, mTerrainID) == true and terrainHeight > 0 then

                      -- print(string.format("Paint Foliage: %d %d", newX, newZ))
                      local randomIndex = math.random(1, #modifiers)
                      local randomStatesIndex = math.random(1, #states[randomIndex])

                      if modifiers[randomIndex] ~= nil then
                          
                          modifiers[randomIndex]:setParallelogramWorldCoords(
                              newX, newZ,
                              newX + self.spacing, newZ,
                              newX, newZ + self.spacing,
                              DensityCoordType.POINT_POINT_POINT
                          )
                          modifiers[randomIndex]:executeSet(states[randomIndex][randomStatesIndex])
                          foliagesPlaced = foliagesPlaced + 1
                      end

                    end
                end

                if foliagePlacedCheck == false then
                    foliageTracker = foliageTracker - 1
                end
                -- print(string.format("Foliage Tracker: %d", foliageTracker))
            end

        end
    end

    print(string.format("Foliages Placed: %d", foliagesPlaced))
    print("Script Run Complete.")

end

-- Builds new foliage modifier
function RanFoliagePaint:buildModifier(mTerrainID,foliageLayers,foliageLayer)
    local modifier = nil
    if foliageLayers ~= nil and foliageLayer ~= nil then
      local folLayer1s = foliageLayers[foliageLayer]
      if folLayer1s ~= nil then
          print('foliageLayer : ' .. folLayer1s)
          local foliageId = getTerrainDataPlaneByName(mTerrainID, folLayer1s)
          modifier = DensityMapModifier.new(foliageId, 0, RanFoliagePaint.DENSITY_MAP_CHANNELS)
      else
          print("Warning: Inner Foliage Type Not Selected or Not Found.")
          modifier = nil
      end
    end
    return modifier
end

function RanFoliagePaint:getFoliageLayers()
    -- print("Get Foliage Layers Data")

    -- Get all of the map foliage layers
    local folLayerFT = {}
    local folXML = {}
    local mlFNA = {}
    local densMap = {}
    local fl = 100
    local st = 20
    for i = 1, fl do
        self.foliageStates[i] = {}
        for j = 1, st do
            self.foliageStates[i][j] = ""
        end
    end
    for i = 1, fl do
        self.foliageStatesNames[i] = {}
        for j = 1, st do
            self.foliageStatesNames[i][j] = ""
        end
    end
    local index = 0
    local i = 0
    local count = 0
    local fileName = getSceneFilename()
    local fNd = fileName:find("/[^/]*$")
    local newPath = string.sub(fileName, 1, fNd)
    local xmlFile = loadXMLFile("map.i3d", fileName)
    local countMax = 0
    for x = 0, 10 do
        densMap[x] = getXMLString(xmlFile, "i3D.Scene.TerrainTransformGroup.Layers.FoliageSystem.FoliageMultiLayer("..x..")#densityMapId")
        if densMap[x] == nil then countMax = x break end
    end

    -- foliage Type/xml/haulm
    while true do
        index = index + 1
        self.foliageLayers[index] = getXMLString(xmlFile, "i3D.Scene.TerrainTransformGroup.Layers.FoliageSystem.FoliageMultiLayer("..count..").FoliageType("..i..")#name")
        folXML[index] = getXMLString(xmlFile, "i3D.Scene.TerrainTransformGroup.Layers.FoliageSystem.FoliageMultiLayer("..count..").FoliageType("..i..")#foliageXmlId")
        i = i + 1
        if self.foliageLayers[index] == nil then count = count + 1 i = 0 index = index - 1 end
        if count == countMax then
            index = 0 i = 0 count = 0
            break
        end
    end

    -- parse all fileId's to assign correct xml path for foliage.xml's
    while true do
        index = index + 1
        mlFNA[index] = getXMLString(xmlFile, "i3D.Files.File("..index..")#fileId")
        if mlFNA[index] == nil then index = 0 break end
    end

    -- create full xml path
    posSlash = {}
    for d = 1, #self.foliageLayers do
        local xmlID = folXML[d]
        for k, value in next, mlFNA do
            if value == xmlID then
                folXML[d] = getXMLString(xmlFile, "i3D.Files.File("..k..")#filename")
                if string.sub(folXML[d], 1, 1) == "$" then
                    local dFoliage = string.sub(folXML[d], 2)
                    folXML[d] = RanFoliagePaint.GAME_INSTALL_FOLDER .. dFoliage
                else
                    local slC = 0
                    local pit = 0
                    for i in folXML[d]:gmatch("%.%./") do
                        slC = slC + 1
                    end
                    for i = 1, #newPath do
                        if newPath:sub(i, i) == "/" then
                            count = count + 1
                            posSlash[count] = i
                        end
                    end
                    if slC ~= nil then
                        pit = posSlash[count - slC]
                        newPath2 = string.sub(newPath, 1, pit)
                        local folXML2 = folXML[d]:gsub("%.%./", "")
                        folXML[d] = newPath2 .. folXML2
                    end
                end
            end
        end
    end

    -- get Haulm and position it in self.foliageLayers and folXML
    local k = 1 -- for second foliage layer name --todo repeat if more than 2 foliage layers (0,1)
    local ke = 0
    while true do
        ke = ke + 1
        if self.foliageLayers[ke] == nil then break end
        if fileExists(folXML[ke]) then
            local xmlFileFL = loadXMLFile(self.foliageLayers[ke].."XML", folXML[ke])
            folLayerFT[ke] = getXMLString(xmlFileFL, "foliageType.foliageLayer("..k..")#name")
            if folLayerFT[ke] ~= nil then
                table.insert(self.foliageLayers, ke + 1, self.foliageLayers[ke] .. "_haulm")
                table.insert(folXML, ke + 1, nil)
                ke = ke + 1
            end
        else
          break
        end
    end

    for item = 1, #self.foliageLayers do
        local jump = 0
        index = 1
        local iex = 1
        if folXML[item] ~= nil and fileExists(folXML[item]) then
            local xmlFile2 = loadXMLFile(self.foliageLayers[item], folXML[item])
            while true do
                if xmlFile2 ~= nil then
                    local fState = getXMLString(xmlFile2, "foliageType.foliageLayer.foliageState("..jump..")#name")
                    if fState then
                        self.foliageStates[item][index] = tostring(iex) .. ". " .. fState .. " , "
                        self.foliageStatesNames[item][index] = fState
                        iex = iex + 1
                        jump = jump + 1
                        index = index + 1
                    else
                        break
                    end
                else
                    break
                end
            end
        end
    end
end


function RanFoliagePaint:runFoliageStatesPrint()
    for item = 1, #self.foliageLayers do
        if string.match(self.foliageLayers[item], "_haulm") then self.foliageStates[item] = {" State 1"} end
        if item > 0 then
            local foName = string.upper(self.foliageLayers[item])
            local pState = "\n" .. foName .. "\n" .. string.format("\tFoliage State ; 0 , Remove , %s ", table.concat(self.foliageStates[item], "", 1))
            print(pState)
        end
    end
end

-- Build the vars for the input box
function RanFoliagePaint:setFoliageLayer1(value)
    self.foliageStatesStart = self.foliageStates[self.foliageLayer1]

    self.foliageLayer1 = value    
end

function RanFoliagePaint:setFoliageLayer1_State1(value)
    if self.foliageStatesNames[self.foliageLayer1][value] ~= nil and self.foliageStatesNames[self.foliageLayer1][value] ~= "" then
      print(self.foliageStatesNames[self.foliageLayer1][value] .. " foliage state selected.")
    else
      printError("Selected Foliage State Not Valid.  Try another one.")
    end

    self.foliageLayer1_state1 = value
end

function RanFoliagePaint:setFoliageLayer1_State2(value)
    if self.foliageStatesNames[self.foliageLayer1][value] ~= nil and self.foliageStatesNames[self.foliageLayer1][value] ~= "" then
      print(self.foliageStatesNames[self.foliageLayer1][value] .. " foliage state selected.")
    else
      printError("Selected Foliage State Not Valid.  Try another one.")
    end

    self.foliageLayer1_state2 = value
end

function RanFoliagePaint:setFoliageLayer1_State3(value)
    if self.foliageStatesNames[self.foliageLayer1][value] ~= nil and self.foliageStatesNames[self.foliageLayer1][value] ~= "" then
      print(self.foliageStatesNames[self.foliageLayer1][value] .. " foliage state selected.")
    else
      printError("Selected Foliage State Not Valid.  Try another one.")
    end

    self.foliageLayer1_state3 = value
end

function RanFoliagePaint:setFoliageLayer2(value)
    self.foliageStatesStart = self.foliageStates[self.foliageLayer2]

    self.foliageLayer2 = value    
end

function RanFoliagePaint:setFoliageLayer2_State1(value)
    if self.foliageStatesNames[self.foliageLayer2][value] ~= nil and self.foliageStatesNames[self.foliageLayer2][value] ~= "" then
      print(self.foliageStatesNames[self.foliageLayer2][value] .. " foliage state selected.")
    else
      printError("Selected Foliage State Not Valid.  Try another one.")
    end

    self.foliageLayer2_state1 = value
end

function RanFoliagePaint:setFoliageLayer2_State2(value)
    if self.foliageStatesNames[self.foliageLayer2][value] ~= nil and self.foliageStatesNames[self.foliageLayer2][value] ~= "" then
      print(self.foliageStatesNames[self.foliageLayer2][value] .. " foliage state selected.")
    else
      printError("Selected Foliage State Not Valid.  Try another one.")
    end

    self.foliageLayer2_state2 = value
end

function RanFoliagePaint:setFoliageLayer2_State3(value)
    if self.foliageStatesNames[self.foliageLayer2][value] ~= nil and self.foliageStatesNames[self.foliageLayer2][value] ~= "" then
      print(self.foliageStatesNames[self.foliageLayer2][value] .. " foliage state selected.")
    else
      printError("Selected Foliage State Not Valid.  Try another one.")
    end

    self.foliageLayer2_state3 = value
end

function RanFoliagePaint:setFoliageLayer3(value)
    self.foliageStatesStart = self.foliageStates[self.foliageLayer3]

    self.foliageLayer3 = value    
end

function RanFoliagePaint:setFoliageLayer3_State1(value)
    if self.foliageStatesNames[self.foliageLayer3][value] ~= nil and self.foliageStatesNames[self.foliageLayer3][value] ~= "" then
      print(self.foliageStatesNames[self.foliageLayer3][value] .. " foliage state selected.")
    else
      printError("Selected Foliage State Not Valid.  Try another one.")
    end

    self.foliageLayer3_state1 = value
end

function RanFoliagePaint:setFoliageLayer3_State2(value)
    if self.foliageStatesNames[self.foliageLayer3][value] ~= nil and self.foliageStatesNames[self.foliageLayer3][value] ~= "" then
      print(self.foliageStatesNames[self.foliageLayer3][value] .. " foliage state selected.")
    else
      printError("Selected Foliage State Not Valid.  Try another one.")
    end

    self.foliageLayer3_state2 = value
end

function RanFoliagePaint:setFoliageLayer3_State3(value)
    if self.foliageStatesNames[self.foliageLayer3][value] ~= nil and self.foliageStatesNames[self.foliageLayer3][value] ~= "" then
      print(self.foliageStatesNames[self.foliageLayer3][value] .. " foliage state selected.")
    else
      printError("Selected Foliage State Not Valid.  Try another one.")
    end

    self.foliageLayer3_state3 = value
end

function RanFoliagePaint:setFoliageLayer4(value)
    self.foliageStatesStart = self.foliageStates[self.foliageLayer4]

    self.foliageLayer4 = value    
end

function RanFoliagePaint:setFoliageLayer4_State1(value)
    if self.foliageStatesNames[self.foliageLayer4][value] ~= nil and self.foliageStatesNames[self.foliageLayer4][value] ~= "" then
      print(self.foliageStatesNames[self.foliageLayer4][value] .. " foliage state selected.")
    else
      printError("Selected Foliage State Not Valid.  Try another one.")
    end

    self.foliageLayer4_state1 = value
end

function RanFoliagePaint:setFoliageLayer4_State2(value)
    if self.foliageStatesNames[self.foliageLayer4][value] ~= nil and self.foliageStatesNames[self.foliageLayer4][value] ~= "" then
      print(self.foliageStatesNames[self.foliageLayer4][value] .. " foliage state selected.")
    else
      printError("Selected Foliage State Not Valid.  Try another one.")
    end

    self.foliageLayer4_state2 = value
end

function RanFoliagePaint:setFoliageLayer4_State3(value)
    if self.foliageStatesNames[self.foliageLayer4][value] ~= nil and self.foliageStatesNames[self.foliageLayer4][value] ~= "" then
      print(self.foliageStatesNames[self.foliageLayer4][value] .. " foliage state selected.")
    else
      printError("Selected Foliage State Not Valid.  Try another one.")
    end

    self.foliageLayer4_state3 = value
end

function RanFoliagePaint:setFoliageLayer5(value)
    self.foliageStatesStart = self.foliageStates[self.foliageLayer5]

    self.foliageLayer5 = value    
end

function RanFoliagePaint:setFoliageLayer5_State1(value)
    if self.foliageStatesNames[self.foliageLayer5][value] ~= nil and self.foliageStatesNames[self.foliageLayer5][value] ~= "" then
      print(self.foliageStatesNames[self.foliageLayer5][value] .. " foliage state selected.")
    else
      printError("Selected Foliage State Not Valid.  Try another one.")
    end

    self.foliageLayer5_state1 = value
end

function RanFoliagePaint:setFoliageLayer5_State2(value)
    if self.foliageStatesNames[self.foliageLayer5][value] ~= nil and self.foliageStatesNames[self.foliageLayer5][value] ~= "" then
      print(self.foliageStatesNames[self.foliageLayer5][value] .. " foliage state selected.")
    else
      printError("Selected Foliage State Not Valid.  Try another one.")
    end

    self.foliageLayer5_state2 = value
end

function RanFoliagePaint:setFoliageLayer5_State3(value)
    if self.foliageStatesNames[self.foliageLayer5][value] ~= nil and self.foliageStatesNames[self.foliageLayer5][value] ~= "" then
      print(self.foliageStatesNames[self.foliageLayer5][value] .. " foliage state selected.")
    else
      printError("Selected Foliage State Not Valid.  Try another one.")
    end

    self.foliageLayer5_state3 = value
end

-- Start everything up
RanFoliagePaint.new()











