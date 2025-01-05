-- Author:FSG Modding - Giants Edit
-- Name:v3 4x Paint and Set Height for Tire Tracks By Spline
-- Description: Create a road or trail spline for tractor tire tracks.
-- Icon:iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAAA3NCSVQICAjb4U/gAAAACXBIWXMAAA50AAAOdAFrJLPWAAABJ0lEQVQokZWRvW+CUBTFL5+1IFEHEtHBOLRNnBqJTM7sXf0fOrg3nfq3dO7YMMOoZTPEwTgYHumgL4jSFz66NA2YRxvOeO753Zt3HgMe1BJLdfWZrs906oinupqm1bvwh+gXeJ7uVwJZltUDJEmqAphirVXNLF4XdAAAhk/DcTY2TRMALMtassvNy6YY4OCxBISTsPfei8+x7/voE7nPbn6VFwOXtaZK6swdjDHG2J7bqZJeBEoA98UBAC/+NCEIwq9ZeoPkSO2P9mA96LAdRVFarZYoigBACMEYh2G4z/bbm+3h/nCanhjwYPQwUlVV0zRZlg3DKO5zXZcQEkURQigIgtXbigEPIIfGutG1u32v3zw3i9+cJMnx+ri726Epim9jSq3/6htwhW2ylTHtxgAAAABJRU5ErkJgggAAAADubhsfAA4AgBQAH1DgT9Ag6jppEKLYCAArMDCdGQAvQzpcAAAAAAAAAAAAAAAAAAAAAAAAAFAAMQAAAAAAAAAAABAAVXNlcnMAPAAJAAQA774AAAAAAAAAAC4AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFUAcwBlAHIAcwAAABQAWgAxAAAAAAAAAAAAEABlemFpdHNldgAAQgAJAAQA774AAAAAAAAAAC4AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGUAegBhAGkAdABzAGUAdgAAABgAqAAxAAAAAAAKRw46EQBDcmVhdGl2ZSBDbG91ZCBGaWxlcwAAhAAJAAQA777PRrtyCkcOOi4AAAAAAAAAAAAAAAAAAAAAAAAAWAAAAAAA1wIqAEMAcgBlAGEAdABpAHYAZQAgAEMAbABvAHUAZAAgAEYAaQBsAGUAcwAAAEMAcgBlAGEAdABpAHYAZQAgAEMAbABvAHUAZAAg
-- Hide:no
source("editorUtils.lua")

-- Set this to your base game install location for Farming Simulator 25
local gInst = "C:/Program Files (x86)/Farming Simulator 2025/" 

------------------------------------- Beyond here be Dragons -----------------------------------------------------------------

textureName = {}
texturePaint = {}
folLayerName = {}
folLayerFT = {}
folXML = {}
folState = {}
mlFNA = {}
choice = {"Deselected", "Selected"}
densMap = {}
local fl = 100
local st = 20
for i = 1, fl do
    folState[i] = {}
    for j = 1, st do
        folState[i][j] = ""
    end
end
local fNd = 0
local index = 0
local i = 0
local count = 0
local fileName = getSceneFilename()
local fNd = fileName:find("/[^/]*$")
local newPath = string.sub(fileName, 1, fNd)
-- local filename2 = newPath .. "/foliage_States.txt"
-- local foliageStates = createFile(filename2, 0)
-- fileWrite(foliageStates, "Foliage States")
local xmlFile = loadXMLFile("map.i3d", fileName)
local countMax = 0
for x = 0, 10 do
    densMap[x] = getXMLString(xmlFile, "i3D.Scene.TerrainTransformGroup.Layers.FoliageSystem.FoliageMultiLayer("..x..")#densityMapId")
    if densMap[x] == nil then countMax = x break end
end

-- foliage Type/xml/haulm
while true do
    index = index + 1
    folLayerName[index] = getXMLString(xmlFile, "i3D.Scene.TerrainTransformGroup.Layers.FoliageSystem.FoliageMultiLayer("..count..").FoliageType("..i..")#name")
    folXML[index] = getXMLString(xmlFile, "i3D.Scene.TerrainTransformGroup.Layers.FoliageSystem.FoliageMultiLayer("..count..").FoliageType("..i..")#foliageXmlId")
    i = i + 1
    if folLayerName[index] == nil then count = count + 1 i = 0 index = index - 1 end
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
for d = 1, #folLayerName do
    local xmlID = folXML[d]
    for k, value in next, mlFNA do
        if value == xmlID then
            folXML[d] = getXMLString(xmlFile, "i3D.Files.File("..k..")#filename")
            if string.sub(folXML[d], 1, 1) == "$" then
                local dFoliage = string.sub(folXML[d], 2)
                folXML[d] = gInst .. dFoliage
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

-- get Haulm and position it in folLayerName and folXML
local k = 1 -- for second foliage layer name --todo repeat if more than 2 foliage layers (0,1)
local ke = 0
while true do
    ke = ke + 1
    if folLayerName[ke] == nil then break end
    if fileExists(folXML[ke]) then
        local xmlFileFL = loadXMLFile(folLayerName[ke].."XML", folXML[ke])
        folLayerFT[ke] = getXMLString(xmlFileFL, "foliageType.foliageLayer("..k..")#name")
        if folLayerFT[ke] ~= nil then
            table.insert(folLayerName, ke + 1, folLayerName[ke] .. "_haulm")
            table.insert(folXML, ke + 1, nil)
            ke = ke + 1
        end
    else
       break
    end
end

for item = 1, #folLayerName do
    local jump = 0
    index = 1
    local iex = 1
    if folXML[item] ~= nil and fileExists(folXML[item]) then
        local xmlFile2 = loadXMLFile(folLayerName[item], folXML[item])
        while true do
            if xmlFile2 ~= nil then
                local fState = getXMLString(xmlFile2, "foliageType.foliageLayer.foliageState("..jump..")#name")
                if fState then
                    folState[item][index] = tostring(iex) .. ". " .. fState .. " , "
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
    if string.match(folLayerName[item], "_haulm") then folState[item] = {" State 1"} end
    if item > 0 then
        local foName = string.upper(folLayerName[item])
        local pState = "\n" .. foName .. "\n" .. string.format("\tFoliage State ; 0 , Remove , %s ", table.concat(folState[item], "", 1))
        print(pState)
        -- fileWrite(foliageStates, pState)
    end
end
-- delete(foliageStates)


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

local numLayers = getTerrainNumOfLayers(mTerrainID)
addedLayer = numLayers + 1
for i = 0, addedLayer do
    texturePaint[i] = getTerrainLayerName(mTerrainID, i - 1)
    textureName[i] = getTerrainLayerName(mTerrainID, i)
end
texturePaint[addedLayer] = "-1"

-- 80 is asphalt, 71 is grass, 82 is gravel
local mLayerId = 117 -- should be int
local mLayerId2 = 120 -- should be int
local mLayerId3 = 119 -- should be int
local mSideCount = 2 -- should be int
local mSideCount2 = 2 -- should be int
local outer = 3 -- should be int
local spacing = 4.0
local width = 6.0
local falloff = 20.0

local state2 = 0
local folLayer1 = 0
local folState1 = 0

local function setLayerId(value)
    mLayerId = value - 1
end

local function setLayerId2(value)
    mLayerId2 = value - 1
end

local function setLayerId3(value)
    mLayerId3 = value - 1
end

local function setSideCount(value)
    mSideCount = value
end

-- function to set paint type
local function setSideCount2(value)
    mSideCount2 = value
end

local function setWidth(value)
    width = value
end

local function setSpacing(value)
    spacing = value
end

local function setOuter(value)
    outer = value
end

local function setFalloff(value)
    falloff = value
end

local function setState2(value)
    state2 = value
end

local function setFolState(value)
    folState1 = value
end

local function setFolLayer(value)
    folLayer1 = value
end

local function runTerrainBySpline()
    runPaintFieldDirt(mTerrainID, mLayerId, mLayerId2, mLayerId3)
    EditorUtils.setTerrainHeight(-0.1, width, falloff)
end

-- UI
local labelWidth = 200.0

local frameSizer = UIRowLayoutSizer.new()
local myFrame = UIWindow.new(frameSizer, "Paint and Set Height for Terrain By Spline")

local borderSizer = UIRowLayoutSizer.new()
UIPanel.new(frameSizer, borderSizer)

local rowSizer = UIRowLayoutSizer.new()
UIPanel.new(borderSizer, rowSizer, -1, -1, -1, -1, BorderDirection.ALL, 10, 1)

local texLeftPanelSizer = UIColumnLayoutSizer.new()
local texLeftPanel = UIPanel.new(rowSizer, texLeftPanelSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
local texLeftLabel = UILabel.new(texLeftPanelSizer, "Trail Texture:", TextAlignment.LEFT, -1, -1, 150, -1)
local texLeftChoice = UIChoice.new(texLeftPanelSizer, texturePaint, -1, -1, 100, -1)
texLeftChoice:setOnChangeCallback(setLayerId)

local texCentrePanelSizer = UIColumnLayoutSizer.new()
local texCentrePanel = UIPanel.new(rowSizer, texCentrePanelSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
local texCentreLabel = UILabel.new(texCentrePanelSizer, "Center Texture:", TextAlignment.LEFT, -1, -1, 150, -1)
local texCentreChoice = UIChoice.new(texCentrePanelSizer, texturePaint, -1, -1, 100, -1)
texCentreChoice:setOnChangeCallback(setLayerId2)

local texRightPanelSizer = UIColumnLayoutSizer.new()
local texRightPanel = UIPanel.new(rowSizer, texRightPanelSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
local texRightLabel = UILabel.new(texRightPanelSizer, "Outer Texture:", TextAlignment.LEFT, -1, -1, 150, -1)
local texRightChoice = UIChoice.new(texRightPanelSizer, texturePaint, -1, -1, 100, -1)
texRightChoice:setOnChangeCallback(setLayerId3)

local mSideCountSliderSizer = UIColumnLayoutSizer.new()
UIPanel.new(rowSizer, mSideCountSliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
UILabel.new(mSideCountSliderSizer, "Trail Width 1", TextAlignment.LEFT, -1, -1, labelWidth)
local mSideCountSlider = UIIntSlider.new(mSideCountSliderSizer, mSideCount, 1, 10)
mSideCountSlider:setOnChangeCallback(setSideCount)

local mSideCount2SliderSizer = UIColumnLayoutSizer.new()
UIPanel.new(rowSizer, mSideCount2SliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
UILabel.new(mSideCount2SliderSizer, "Trail Width 2", TextAlignment.LEFT, -1, -1, labelWidth)
local mSideCount2Slider = UIIntSlider.new(mSideCount2SliderSizer, mSideCount2, 0, 255)
mSideCount2Slider:setOnChangeCallback(setSideCount2)

local spacingSliderSizer = UIColumnLayoutSizer.new()
UIPanel.new(rowSizer, spacingSliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
UILabel.new(spacingSliderSizer, "Trail Spacing", TextAlignment.LEFT, -1, -1, labelWidth)
local spacingSlider = UIFloatSlider.new(spacingSliderSizer, spacing, 0.0, 10.0, 0.0, 10.0)
spacingSlider:setOnChangeCallback(setSpacing)

local outerSliderSizer = UIColumnLayoutSizer.new()
UIPanel.new(rowSizer, outerSliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
UILabel.new(outerSliderSizer, "Trail Outer", TextAlignment.LEFT, -1, -1, labelWidth)
local outerSlider = UIFloatSlider.new(outerSliderSizer, outer, 0.0, 10.0, 0.0, 10.0)
outerSlider:setOnChangeCallback(setOuter)

local widthSliderSizer = UIColumnLayoutSizer.new()
UIPanel.new(rowSizer, widthSliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
UILabel.new(widthSliderSizer, "Terrain Width", TextAlignment.LEFT, -1, -1, labelWidth)
local widthSlider = UIFloatSlider.new(widthSliderSizer, width, 0.0, 10.0, 0.0, 10.0)
widthSlider:setOnChangeCallback(setWidth)

local falloffSliderSizer = UIColumnLayoutSizer.new()
UIPanel.new(rowSizer, falloffSliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
UILabel.new(falloffSliderSizer, "Smoothing Distance", TextAlignment.LEFT, -1, -1, labelWidth)
local falloffSlider = UIFloatSlider.new(falloffSliderSizer, falloff, 0.0, 100.0, 0.0, 100.0)
falloffSlider:setOnChangeCallback(setFalloff)

local folLayerPanelSizer = UIColumnLayoutSizer.new()
local folLayerPanel = UIPanel.new(rowSizer, folLayerPanelSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
local folLayerLabel = UILabel.new(folLayerPanelSizer, "Set Foliage Type", TextAlignment.LEFT, -1, -1, labelWidth, -1)
local folLayerChoice = UIChoice.new(folLayerPanelSizer, folLayerName, 0, -1, 100, -1)
folLayerChoice:setOnChangeCallback(setFolLayer)

local folStateSliderSizer = UIColumnLayoutSizer.new()
UIPanel.new(rowSizer, folStateSliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
UILabel.new(folStateSliderSizer, "Set Foliage State", TextAlignment.LEFT, -1, -1, labelWidth)
local folStateSlider = UIIntSlider.new(folStateSliderSizer, folState1, 0, 20)
folStateSlider:setOnChangeCallback(setFolState)

local state2SliderSizer = UIColumnLayoutSizer.new()
UIPanel.new(rowSizer, state2SliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
UILabel.new(state2SliderSizer, "Set Second Foliage State", TextAlignment.LEFT, -1, -1, labelWidth)
local state2Slider = UIIntSlider.new(state2SliderSizer, state2, 0, 20)
state2Slider:setOnChangeCallback(setState2)

UIButton.new(rowSizer, "Run Script", runTerrainBySpline)

myFrame:showWindow()

function crossProduct(ax, ay, az, bx, by, bz)
    return ay * bz - az * by, az * bx - ax * bz, ax * by - ay * bx
end

-- Function that paints field dirt within spline area
function runPaintFieldDirt(mTerrainID, mLayerId, mLayerId2, mLayerId3)

    if mLayerId == nil then
        mLayerId = 117
    end
    print('mLayerId : ' .. mLayerId)

    if mLayerId2 == nil then
        mLayerId2 = 120
    end
    print('mLayerId2 : ' .. mLayerId2)

    if mLayerId3 == nil then
        mLayerId3 = 119
    end
    print('mLayerId3 : ' .. mLayerId3)

    if (getNumSelected() == 0) then
        print("Error: Select one or more splines.")
        return nil
    end

    local mSplineIDs = {}
    for i = 0, getNumSelected() - 1 do
        mID = getSelection(i)
        table.insert(mSplineIDs, mID)
    end

    local terrainSize = getTerrainSize(mTerrainID)
    print('terrainSize : ' .. terrainSize)

    local modifier = nil

    local folLayer1s = folLayerName[folLayer1]
    
    if folLayer1s ~= nil then
        print('foliageLayer : ' .. folLayer1s)
        local foliageId = getTerrainDataPlaneByName(mTerrainID, folLayer1s)
        modifier = DensityMapModifier.new(foliageId, 0, 5)
    else
        print("Warning: Inner Foliage Type Not Selected or Not Found.")
    end

    for _, mSplineID in pairs(mSplineIDs) do

        print('Checking Selected Splines to Paint')

        local mSplineLength = getSplineLength(mSplineID)
        local mSplinePiece = 0.5 -- real size 0.5 meter
        local mSplinePiecePoint = mSplinePiece / mSplineLength -- relative size [0..1]

        local mSplinePos = 0.0
        while mSplinePos <= 1.0 do
            -- get XYZ at position on spline
            local mPosX, mPosY, mPosZ = getSplinePosition(mSplineID, mSplinePos)
            -- directional vector at the point
            local mDirX, mDirY, mDirZ = getSplineDirection(mSplineID, mSplinePos)
            local mVecDx, mVecDy, mVecDz = EditorUtils.crossProduct(mDirX, mDirY, mDirZ, 0, 0.25, 0)
            local mVecDxF, mVecDyF, mVecDzF = crossProduct(mDirX, mDirY, mDirZ, 0, 0.01, 0)

            -- Dynamic adjustment based on curvature
            local nextPosX, nextPosY, nextPosZ = getSplinePosition(mSplineID, mSplinePos + mSplinePiecePoint)
            local prevPosX, prevPosY, prevPosZ = getSplinePosition(mSplineID, mSplinePos - mSplinePiecePoint)
            local distNext = math.sqrt((nextPosX - mPosX)^2 + (nextPosZ - mPosZ)^2)
            local distPrev = math.sqrt((prevPosX - mPosX)^2 + (prevPosZ - mPosZ)^2)
            local curvature = math.abs(distNext - distPrev)
            mSplinePiece = math.max(0.1, 0.5 * (1 / (1 + curvature)))

            -- paint at the center
            setTerrainLayerAtWorldPos(mTerrainID, mLayerId2, mPosX, mPosY, mPosZ, 128.0)
            -- Get spacing half
            local spacingHalf = spacing / 2

            -- Fill in foliage to create the border areas
            -- for i = 1, mSideCount + spacingHalf + outer, 1 do
            --     -- Paint the foliage
            --     local mNewPosX1 = mPosX + mSideCount + spacingHalf + outer * mVecDxF
            --     local mNewPosZ1 = mPosZ + mSideCount + spacingHalf + outer * mVecDzF
            --     local mNewPosX2 = mPosX - mSideCount - spacingHalf - outer * mVecDxF
            --     local mNewPosZ2 = mPosZ - mSideCount - spacingHalf - outer * mVecDzF
            --     if modifier ~= nil then
            --         modifier:setParallelogramWorldCoords(mPosX, mPosZ, mNewPosX1, mNewPosZ1, mNewPosX2, mNewPosZ2, DensityCoordType.POINT_POINT_POINT)
            --         modifier:executeSet(folState1)
            --     end
            -- end

            -- Clear out foliage before painting
            for i = 1, mSideCount + spacingHalf, 1 do
                -- Paint the foliage
                local mNewPosX1 = mPosX + mSideCount + spacingHalf * mVecDxF
                local mNewPosZ1 = mPosZ + mSideCount + spacingHalf * mVecDzF
                local mNewPosX2 = mPosX - mSideCount - spacingHalf * mVecDxF
                local mNewPosZ2 = mPosZ - mSideCount - spacingHalf * mVecDzF
                if modifier ~= nil then
                    modifier:setParallelogramWorldCoords(mPosX, mPosZ, mNewPosX1, mNewPosZ1, mNewPosX2, mNewPosZ2, DensityCoordType.POINT_POINT_POINT)
                    modifier:executeSet(0)
                end
            end

            -- Paint the center line at the width of the spacing
            for i = 1, spacing, 1 do
                local mNewPosX1 = mPosX + i * mVecDx
                local mNewPosZ1 = mPosZ + i * mVecDz
                local mNewPosX2 = mPosX - i * mVecDx
                local mNewPosZ2 = mPosZ - i * mVecDz
                -- paint at the center
                setTerrainLayerAtWorldPos(mTerrainID, mLayerId2, mNewPosX1, mPosY, mNewPosZ1, 128.0)
                setTerrainLayerAtWorldPos(mTerrainID, mLayerId2, mNewPosX2, mPosY, mNewPosZ2, 128.0)

                if folState1 ~= nil and folState1 > 0 then
                    -- Randomly place foliage states
                    local randomNumber = math.random(1, 2)
                    -- Return the variable based on the random number
                    local folState = folState1
                    if randomNumber == 1 then
                        folState = state2
                    end

                    -- Paint the foliage
                    local mNewPosX1 = mPosX + spacing * mVecDxF
                    local mNewPosZ1 = mPosZ + spacing * mVecDzF
                    local mNewPosX2 = mPosX - spacing * mVecDxF
                    local mNewPosZ2 = mPosZ - spacing * mVecDzF
                    if modifier ~= nil then
                        modifier:setParallelogramWorldCoords(mPosX, mPosZ, mNewPosX1, mNewPosZ1, mNewPosX2, mNewPosZ2, DensityCoordType.POINT_POINT_POINT)
                        modifier:executeSet(folState)
                    end
                end
            end

            -- Paint the outer bits
            -- define side to side shift in meters
            for i = 1, outer + mSideCount + spacingHalf, 1 do
                -- Skip half of the spacing width
                if i > spacingHalf + mSideCount then
                    local mNewPosX1 = mPosX + i * mVecDx
                    local mNewPosZ1 = mPosZ + i * mVecDz
                    -- paint at the center
                    setTerrainLayerAtWorldPos(mTerrainID, mLayerId3, mNewPosX1, mPosY, mNewPosZ1, 128.0)
                end
            end
            -- define side to side shift in meters
            for i = 1, outer + mSideCount2 + spacingHalf, 1 do
                -- Skip half of the spacing width
                if i > spacingHalf + mSideCount2 then
                    local mNewPosX2 = mPosX - i * mVecDx
                    local mNewPosZ2 = mPosZ - i * mVecDz
                    -- paint at the center
                    setTerrainLayerAtWorldPos(mTerrainID, mLayerId3, mNewPosX2, mPosY, mNewPosZ2, 128.0)
                end
            end

            -- Paint the trails
            -- define side to side shift in meters
            for i = 1, mSideCount + spacingHalf, 1 do
                -- Skip half of the spacing width
                if i > spacingHalf then
                    local mNewPosX1 = mPosX + i * mVecDx
                    local mNewPosZ1 = mPosZ + i * mVecDz
                    -- paint at the center
                    setTerrainLayerAtWorldPos(mTerrainID, mLayerId, mNewPosX1, mPosY, mNewPosZ1, 128.0)
                end
            end
            -- define side to side shift in meters
            for i = 1, mSideCount2 + spacingHalf, 1 do
                -- Skip half of the spacing width
                if i > spacingHalf then
                    local mNewPosX2 = mPosX - i * mVecDx
                    local mNewPosZ2 = mPosZ - i * mVecDz
                    -- paint at the center
                    setTerrainLayerAtWorldPos(mTerrainID, mLayerId, mNewPosX2, mPosY, mNewPosZ2, 128.0)
                end
            end

            -- goto next point
            mSplinePos = mSplinePos + mSplinePiecePoint
        end
    end
end
