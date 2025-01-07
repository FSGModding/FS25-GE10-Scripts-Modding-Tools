-- Author:Nicolas Wrobel
-- Name: FSG - 4x paintTerrainBySpline v2
-- Description: First parameter is the detail layer id. Combined layers are in the range [numLayers, numLayers+numCombinedLayers). Second parameter is half the width in meters
-- Icon:iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAAA3NCSVQICAjb4U/gAAAACXBIWXMAAArwAAAK8AFCrDSYAAAAGUlEQVQokWNsrP/PQApgIkn1qIZRDUNKAwBM3gIfYwhd6QAAAABJRU5ErkJgggAAPll81QUDAoAAAAAATgAAAEQAOgBcAGMAbwBkAGUAXABsAHMAaQBtADIAMAAyADEAXABiAGkAbgBcAGQAYQB0AGEAXABtAGEAcABzAFwAdABlAHgAdAB1AHIAZQBzAAAAZQB1AHIAbwBwAGUAYQBuAAAAAACgEAAAAAAAAAAAAAAmWXTVNQQCgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANDKTaZpAQAAYP5Dw2kBAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAACAAQAAAAAANAGmjz6fwAAAAAAAAAAAAAgAAAACIAAANDKTaZpAQAAAAAAAAAAAAABAAAAAAAAAC5ZbNW2BQKAbAAxAAAAAAAAAAAAEABPbmVEcml2ZQAAVAAJAAQA774AAAAAAAAAAC4AAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAE8AbgBlAEQAcgBpAHYAZQAAAE8AbgBlAEQAcgBpAHYAZQAAABgAAAB0AAAAAAAAAAAAFllk1S0GAoBDADoAXABVAHMAZQByAHMAXABmAGIAdQBzAHMAZQBcAEEAcABwAEQAYQB0AGEAXABSAG8AYQBtAGkAbgBnAFwATQBpAGMAcgBvAHMAbwBmAHQAXABXAGkAbgBkAG8AdwBzAFwAUgBlAGMAZQBuAHQAAAAAAAAAAAAeWRzVwgcCgGwAMQAAAAAAAAAAABAAT25lRHJpdmUAAFQACQAEAO++AAAAAAAAAAAuAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAABPAG4AZQBEAHIAaQB2AGUAAABPAG4AZQBEAHIAaQB2AGUAAAAYAAAAAAAEAAAAAAAAAAZZFNXyCAKA
-- Hide:no
-- Date: 1.5.2025

-- Load editor utils
source("editorUtils.lua");

-- Build the class
PaintTerrainBySpline = {}
PaintTerrainBySpline.WINDOW_WIDTH = 300
PaintTerrainBySpline.WINDOW_HEIGHT = -1
PaintTerrainBySpline.TEXT_WIDTH = 230
PaintTerrainBySpline.TEXT_HEIGHT = -1

-- Get things started
function PaintTerrainBySpline.new()
    local self = setmetatable({}, {__index=PaintTerrainBySpline})

    self.window = nil
    if g_currentPaintTerrainBySplineDialog ~= nil then
        g_currentPaintTerrainBySplineDialog:close()
    end
  
    self.textureLayers = {}
    self.textureLayerNames = {}
    self.textureLayers_Choice = {}
    self.textureLayers_Selected = 1
    
    self.paintWidth = 0
    self.paintWidthSlider = 0

    self.mSceneID = getRootNode()
    self.mTerrainID = 0
    for i = 0, getNumOfChildren(self.mSceneID) - 1 do
        local mID = getChildAt(self.mSceneID, i)
        if (getName(mID) == "terrain") then
            self.mTerrainID = mID
            break
        end
    end

    self:getTextureLayers()

    self:generateUI()

    g_currentPaintTerrainBySplineDialog = self

    return self

end

-- Generate UI Function
function PaintTerrainBySpline:generateUI()
    -- Setup UI
    local frameRowSizer = UIRowLayoutSizer.new()
    self.window = UIWindow.new(frameRowSizer, "Paint Terrain by Spline Tool")

    local borderSizer = UIRowLayoutSizer.new()
    UIPanel.new(frameRowSizer, borderSizer)

    local rowSizer = UIRowLayoutSizer.new()
    UIPanel.new(borderSizer, rowSizer, -1, -1, PaintTerrainBySpline.WINDOW_WIDTH, PaintTerrainBySpline.WINDOW_HEIGHT, BorderDirection.ALL, 10, 1)

    -- First Layer Set
    local title = UILabel.new(rowSizer, "Spline Paint Settings", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    title:setBold(true)
    UIHorizontalLine.new(rowSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)

    local folLayerPanelSizer = UIGridSizer.new(1, 2, 2, 2)
    local folLayerPanel = UIPanel.new(rowSizer, folLayerPanelSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    local folLayerLabel = UILabel.new(folLayerPanelSizer, "Field Texture Paint", false, TextAlignment.LEFT, VerticalAlignment.TOP, PaintTerrainBySpline.TEXT_WIDTH, -1)
    self.textureLayers_Choice = UIChoice.new(folLayerPanelSizer, self.textureLayers, 0, -1, 100, -1)
    self.textureLayers_Choice:setOnChangeCallback(function(value) self:setTextureLayer(value) end)

    local objectDistanceSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, objectDistanceSliderSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    UILabel.new(objectDistanceSliderSizer, "Paint Width - Meters", false, TextAlignment.LEFT, VerticalAlignment.TOP, PaintTerrainBySpline.TEXT_WIDTH, -1, 200);
    self.paintWidthSlider = UIIntSlider.new(objectDistanceSliderSizer, self.paintWidth, 1, 50 );
    self.paintWidthSlider:setOnChangeCallback(function(value) self:setPaintWidth(value) end)

    -- Run Script Button
    local title = UILabel.new(rowSizer, "", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    local title = UILabel.new(rowSizer, "Click Run Script to Start", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    title:setBold(true)
    UIHorizontalLine.new(rowSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)

    UIButton.new(rowSizer, "Run Script", function() self:runPaintTerrainBySpline() end, self, -1, -1, -1, -1, BorderDirection.BOTTOM, 2, 1)

    -- layout and show window
    self.window:setOnCloseCallback(function() self:onClose() end)
    self.window:showWindow()

end

function PaintTerrainBySpline:close()
    self.window:close()
end

function PaintTerrainBySpline:onClose()
    -- Clears out any active functions
end

function PaintTerrainBySpline:getTextureLayers()
    print("Get Texture Layers")

    local numLayers = getTerrainNumOfLayers(self.mTerrainID)
    local addedLayer = numLayers +1
    for i = 0,addedLayer do
        self.textureLayers[i] = getTerrainLayerName(self.mTerrainID, i-1)
        self.textureLayerNames[i] = getTerrainLayerName(self.mTerrainID, i)
    end
end

function PaintTerrainBySpline:setTextureLayer(value)
    if self.textureLayerNames[value - 1] ~= nil and self.textureLayerNames[value - 1] ~= "" then
      print(string.format("Selected Field Texture Paint: %s", self.textureLayerNames[value - 1]))
      self.textureLayers_Selected = value - 1
      -- print(self.textureLayers_Selected)
      -- print(self.textureLayerNames[value - 1])
    else
      printError("Selected Field Texture Paint is Not Valid!  Please select a different texture.")
    end
end

function PaintTerrainBySpline:setPaintWidth(value)
    -- print(value)
    self.paintWidth = value
end

function PaintTerrainBySpline:runPaintTerrainBySpline()

    if (getNumSelected() == 0) then
        printError("Error: Select one or more splines.")
        return false
    end

    local mSplineIDs = {}
    for i = 0, getNumSelected() - 1 do
        local mID = getSelection( i )
        if not getHasClassId(mID, ClassIds.SHAPE) or not getHasClassId(getGeometry(mID), ClassIds.SPLINE) then
            continue
        end
        table.insert( mSplineIDs, mID )
    end

    if #mSplineIDs == 0 then
        printError("Error: No splines were selected.")
        return nil
    end

    for _, mSplineID in pairs(mSplineIDs) do
        local mSplineLength = getSplineLength( mSplineID )
        local mSplinePiece = 0.5 -- real size 0.5 meter
        local mSplinePiecePoint = mSplinePiece / mSplineLength  -- relative size [0..1]

        local mSplinePos = 0.0
        while mSplinePos <= 1.0 do
            -- get XYZ at position on spline
            local mPosX, mPosY, mPosZ = getSplinePosition( mSplineID, mSplinePos )
            -- directional vector at the point
            local mDirX, mDirY,   mDirZ   = getSplineDirection ( mSplineID, mSplinePos)
            local mVecDx, _mVecDy, mVecDz = EditorUtils.crossProduct( mDirX, mDirY, mDirZ, 0, 0.25, 0)
            -- paint at the center
            setTerrainLayerAtWorldPos(self.mTerrainID, self.textureLayers_Selected, mPosX, mPosY, mPosZ, 128.0 )
            -- define side to side shift in meters
            for i = 1, self.paintWidth, 1 do
                local mNewPosX1 = mPosX + i * mVecDx
                local mNewPosZ1 = mPosZ + i * mVecDz
                local mNewPosX2 = mPosX  - i * mVecDx
                local mNewPosZ2 = mPosZ  - i * mVecDz
                -- paint at the center
                setTerrainLayerAtWorldPos(self.mTerrainID, self.textureLayers_Selected, mNewPosX1, mPosY, mNewPosZ1, 128.0 )
                setTerrainLayerAtWorldPos(self.mTerrainID, self.textureLayers_Selected, mNewPosX2, mPosY, mNewPosZ2, 128.0 )
            end
            -- goto next point
            mSplinePos = mSplinePos + mSplinePiecePoint
        end
    end

    print("Script Done")

end

-- Start the party
PaintTerrainBySpline:new()