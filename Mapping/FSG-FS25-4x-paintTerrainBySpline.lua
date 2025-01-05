-- Author:Nicolas Wrobel
-- Name:4x paintTerrainBySpline
-- Description: First parameter is the detail layer id. Combined layers are in the range [numLayers, numLayers+numCombinedLayers). Second parameter is half the width in meters
-- Icon:iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAAA3NCSVQICAjb4U/gAAAACXBIWXMAAArwAAAK8AFCrDSYAAAAGUlEQVQokWNsrP/PQApgIkn1qIZRDUNKAwBM3gIfYwhd6QAAAABJRU5ErkJgggAAPll81QUDAoAAAAAATgAAAEQAOgBcAGMAbwBkAGUAXABsAHMAaQBtADIAMAAyADEAXABiAGkAbgBcAGQAYQB0AGEAXABtAGEAcABzAFwAdABlAHgAdAB1AHIAZQBzAAAAZQB1AHIAbwBwAGUAYQBuAAAAAACgEAAAAAAAAAAAAAAmWXTVNQQCgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANDKTaZpAQAAYP5Dw2kBAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAACAAQAAAAAANAGmjz6fwAAAAAAAAAAAAAgAAAACIAAANDKTaZpAQAAAAAAAAAAAAABAAAAAAAAAC5ZbNW2BQKAbAAxAAAAAAAAAAAAEABPbmVEcml2ZQAAVAAJAAQA774AAAAAAAAAAC4AAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAE8AbgBlAEQAcgBpAHYAZQAAAE8AbgBlAEQAcgBpAHYAZQAAABgAAAB0AAAAAAAAAAAAFllk1S0GAoBDADoAXABVAHMAZQByAHMAXABmAGIAdQBzAHMAZQBcAEEAcABwAEQAYQB0AGEAXABSAG8AYQBtAGkAbgBnAFwATQBpAGMAcgBvAHMAbwBmAHQAXABXAGkAbgBkAG8AdwBzAFwAUgBlAGMAZQBuAHQAAAAAAAAAAAAeWRzVwgcCgGwAMQAAAAAAAAAAABAAT25lRHJpdmUAAFQACQAEAO++AAAAAAAAAAAuAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAABPAG4AZQBEAHIAaQB2AGUAAABPAG4AZQBEAHIAaQB2AGUAAAAYAAAAAAAEAAAAAAAAAAZZFNXyCAKA
-- Hide:no
source("editorUtils.lua");

 -- 80 is asphalt, 71 is grass, 82 is gravel
local mLayerId   = 40 -- should be int
local mSideCount = 4  -- should be int

local function setLayerId(value)
    mLayerId = value
end

local function setSideCount(value)
    mSideCount = value
end

local function paintTerrainBySplineUtil( mLayerId, mSideCount )
--[[
    paintTerrainBySplineUtil ( take x,z value from spline every 1 meter and paint selected texture on the terrain)
--]]

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
        return false
    end

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
            setTerrainLayerAtWorldPos(mTerrainID, mLayerId, mPosX, mPosY, mPosZ, 128.0 )
            -- define side to side shift in meters
            for i = 1, mSideCount, 1 do
                local mNewPosX1 = mPosX + i * mVecDx
                local mNewPosZ1 = mPosZ + i * mVecDz
                local mNewPosX2 = mPosX  - i * mVecDx
                local mNewPosZ2 = mPosZ  - i * mVecDz
                -- paint at the center
                setTerrainLayerAtWorldPos(mTerrainID, mLayerId, mNewPosX1, mPosY, mNewPosZ1, 128.0 )
                setTerrainLayerAtWorldPos(mTerrainID, mLayerId, mNewPosX2, mPosY, mNewPosZ2, 128.0 )
            end
            -- goto next point
            mSplinePos = mSplinePos + mSplinePiecePoint
        end
    end

    return true
end

local function paintTerrainBySpline()
    paintTerrainBySplineUtil(mLayerId, mSideCount);
end

-- UI
local labelWidth = 120.0

local frameSizer = UIRowLayoutSizer.new()
local myFrame = UIWindow.new(frameSizer, "Paint Terrain By Spline")

local borderSizer = UIRowLayoutSizer.new()
UIPanel.new(frameSizer, borderSizer)

local rowSizer = UIRowLayoutSizer.new()
UIPanel.new(borderSizer, rowSizer, -1, -1, -1, -1, BorderDirection.ALL, 10, 1)

local mLayerIdSliderSizer = UIColumnLayoutSizer.new()
UIPanel.new(rowSizer, mLayerIdSliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
UILabel.new(mLayerIdSliderSizer, "Layer Id", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth);
local mLayerIdSlider = UIIntSlider.new(mLayerIdSliderSizer, mLayerId, 0, 255 );
mLayerIdSlider:setOnChangeCallback(setLayerId)

local mSideCountSliderSizer = UIColumnLayoutSizer.new()
UIPanel.new(rowSizer, mSideCountSliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
UILabel.new(mSideCountSliderSizer, "Side Count", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
local mSideCountSlider = UIIntSlider.new(mSideCountSliderSizer, mSideCount, 1, 20)
mSideCountSlider:setOnChangeCallback(setSideCount)

UIButton.new(rowSizer, "Paint", paintTerrainBySpline)

myFrame:showWindow()


