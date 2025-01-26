-- Author:Nicolas Wrobel, StrauntMaunt
-- Name: FSG - 4x paintTerrainBySpline v2 - Updated with window tools by StrauntMaunt
-- Description: Started from db716f3 on fsg github
-- Icon:iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAAA3NCSVQICAjb4U/gAAAACXBIWXMAAArwAAAK8AFCrDSYAAAAGUlEQVQokWNsrP/PQApgIkn1qIZRDUNKAwBM3gIfYwhd6QAAAABJRU5ErkJgggAAPll81QUDAoAAAAAATgAAAEQAOgBcAGMAbwBkAGUAXABsAHMAaQBtADIAMAAyADEAXABiAGkAbgBcAGQAYQB0AGEAXABtAGEAcABzAFwAdABlAHgAdAB1AHIAZQBzAAAAZQB1AHIAbwBwAGUAYQBuAAAAAACgEAAAAAAAAAAAAAAmWXTVNQQCgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANDKTaZpAQAAYP5Dw2kBAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAACAAQAAAAAANAGmjz6fwAAAAAAAAAAAAAgAAAACIAAANDKTaZpAQAAAAAAAAAAAAABAAAAAAAAAC5ZbNW2BQKAbAAxAAAAAAAAAAAAEABPbmVEcml2ZQAAVAAJAAQA774AAAAAAAAAAC4AAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAE8AbgBlAEQAcgBpAHYAZQAAAE8AbgBlAEQAcgBpAHYAZQAAABgAAAB0AAAAAAAAAAAAFllk1S0GAoBDADoAXABVAHMAZQByAHMAXABmAGIAdQBzAHMAZQBcAEEAcABwAEQAYQB0AGEAXABSAG8AYQBtAGkAbgBnAFwATQBpAGMAcgBvAHMAbwBmAHQAXABXAGkAbgBkAG8AdwBzAFwAUgBlAGMAZQBuAHQAAAAAAAAAAAAeWRzVwgcCgGwAMQAAAAAAAAAAABAAT25lRHJpdmUAAFQACQAEAO++AAAAAAAAAAAuAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAABPAG4AZQBEAHIAaQB2AGUAAABPAG4AZQBEAHIAaQB2AGUAAAAYAAAAAAAEAAAAAAAAAAZZFNXyCAKA
-- Hide:no
-- Date: 1.5.2025
-- Depends on helperfiles from: https://gitlab.com/StrauntMaunt/fs25_ge_scripts/-/tree/master/helpers?ref_type=eec48bd12d5fd566864e6337bdfc3e0f2d87d033
--   helpers/panel_factory.lua
--   helpers/input_helpers.lua
-- Load editor utils
source("editorUtils.lua");

source(getAppDataPath() .. "\\scripts\\helpers\\panel_factory.lua")
source(getAppDataPath() .. "\\scripts\\helpers\\input_helpers.lua")
source("ui/MessageBox.lua")

-- Build the class
PaintTerrainBySpline = {}

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
    self.window = PanelFactory.BuildWindow("Paint Terrain by Spline Tool",{
        PanelFactory.BuildPanel("Spline Paint Settings", {
            PanelFactory.BuildIntInput("Paint Width - Meters", 5, function(value) self:setPaintWidth(value) end, 1, 50), 
            PanelFactory.BuildChoiceInput("Field Texture Paint", self.textureLayers, function(value) self:setTextureLayer(value) end), 
            PanelFactory.BuildButton("Run script", function() self:runPaintTerrainBySpline() end)
        })
    })
    self.window:showWindow()
end

function PaintTerrainBySpline:close()
    self.window:close()
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
    if InputHelpers.GetTerrain() == nil then return end

    InputHelpers.RunForSelectedSplines(function(mSplineID)
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
    end)

    print("Script Done")

end

-- Start the party
PaintTerrainBySpline:new()