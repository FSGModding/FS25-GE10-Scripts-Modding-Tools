-- Author: FSG Modding
-- Name: FSG - Selection Replicator By Paint Script v7
-- Description: Replicates selected transforms randomly on terrain paint that matches the terrain paint for first selected transform.
-- Icon:
-- Hide:no
-- Date: 1.7.2025

-- Load editor utils
source("editorUtils.lua");

-- Build the class
SelectionReplicatorByPaint = {}
SelectionReplicatorByPaint.WINDOW_WIDTH = 300
SelectionReplicatorByPaint.WINDOW_HEIGHT = -1
SelectionReplicatorByPaint.TEXT_WIDTH = 230
SelectionReplicatorByPaint.TEXT_HEIGHT = -1

-- Get things started
function SelectionReplicatorByPaint.new()
    local self = setmetatable({}, {__index=SelectionReplicatorByPaint})

    self.window = nil
    if g_currentSelectionReplicatorByPaintDialog ~= nil then
        g_currentSelectionReplicatorByPaintDialog:close()
    end
      
    self.objectDistance = 20
    self.minHeightLevel = 1
    self.maxHeightLevel = 500
    self.limitPlacementHeights = false
    self.objectTrackerSize = 100
    self.restrictPaint = true
    self.totalSections = 64
    self.mapPartition = 0
    
    self.rotationType = 0
    self.rotationTypeChoice = {"No Rotation","Random Rotate","Terrain Outward"}

    self.disabledEnabledChoice = {"Disabled","Enabled"}

    self.CurLocColorR = 0
    self.CurLocColorG = 0
    self.CurLocColorB = 0
    self.CurLocColorW = 0
    self.CurLocColorU = 0

    self.topLevelTransformName = nil

    self.mSceneID = getRootNode()
    self.mTerrainID = 0
    for i = 0, getNumOfChildren(self.mSceneID) - 1 do
        local mID = getChildAt(self.mSceneID, i)
        if (getName(mID) == "terrain") then
            self.mTerrainID = mID
            break
        end
    end

    self.terrainSize = getTerrainSize(self.mTerrainID)
    self.halfTerrainSize = self.terrainSize / 2
    self.sectionSize = 0
    self.sectionSizeHalf = 0
    self.numSectionsX = math.sqrt(self.totalSections)
    self.numSectionsY = math.sqrt(self.totalSections)

    self:generateUI()

    g_currentSelectionReplicatorByPaintDialog = self

    return self

end

-- Generate UI Function
function SelectionReplicatorByPaint:generateUI()
    -- Setup UI
    local frameRowSizer = UIRowLayoutSizer.new()
    self.window = UIWindow.new(frameRowSizer, "Selection Replicator Tool")

    local borderSizer = UIRowLayoutSizer.new()
    UIPanel.new(frameRowSizer, borderSizer)

    local rowSizer = UIRowLayoutSizer.new()
    UIPanel.new(borderSizer, rowSizer, -1, -1, SelectionReplicatorByPaint.WINDOW_WIDTH, SelectionReplicatorByPaint.WINDOW_HEIGHT, BorderDirection.ALL, 10, 1)

    -- Selection Replicator Settings
    local title = UILabel.new(rowSizer, "Selection Replicator Settings", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    title:setBold(true)
    UIHorizontalLine.new(rowSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)

    local objectDistanceSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, objectDistanceSliderSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    UILabel.new(objectDistanceSliderSizer, "Separation Radius - Meters", false, TextAlignment.LEFT, VerticalAlignment.TOP, SelectionReplicatorByPaint.TEXT_WIDTH, -1, 200);
    self.objectDistanceSlider = UIIntSlider.new(objectDistanceSliderSizer, self.objectDistance, 1, 50 );
    self.objectDistanceSlider:setOnChangeCallback(function(value) self:setObjectDistance(value) end)

    local restrictPaintPanelSizer = UIGridSizer.new(1, 2, 2, 2)
    local restrictPaintPanel = UIPanel.new(rowSizer, restrictPaintPanelSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    local restrictPaintLabel = UILabel.new(restrictPaintPanelSizer, "Limit to Texture", false, TextAlignment.LEFT, VerticalAlignment.TOP, SelectionReplicatorByPaint.TEXT_WIDTH, -1)
    local restrictPaint_Choice = UIChoice.new(restrictPaintPanelSizer, self.disabledEnabledChoice, 1, -1, 100, -1)
    restrictPaint_Choice:setOnChangeCallback(function(value) self:setRestrictPaint(value) end)

    local rotationTypePanelSizer = UIGridSizer.new(1, 2, 2, 2)
    local rotationTypePanel = UIPanel.new(rowSizer, rotationTypePanelSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    local rotationTypeLabel = UILabel.new(rotationTypePanelSizer, "Transforms Rotation", false, TextAlignment.LEFT, VerticalAlignment.TOP, SelectionReplicatorByPaint.TEXT_WIDTH, -1)
    local rotationType_Choice = UIChoice.new(rotationTypePanelSizer, self.rotationTypeChoice, 0, -1, 100, -1)
    rotationType_Choice:setOnChangeCallback(function(value) self:setRotationType(value) end)

    local objectDistanceSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, objectDistanceSliderSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    UILabel.new(objectDistanceSliderSizer, "Placement Fail Limit", false, TextAlignment.LEFT, VerticalAlignment.TOP, SelectionReplicatorByPaint.TEXT_WIDTH, -1, 200);
    self.objectTrackerSizeSlider = UIIntSlider.new(objectDistanceSliderSizer, self.objectTrackerSize, 1, 1000);
    self.objectTrackerSizeSlider:setOnChangeCallback(function(value) self:setObjectTrackerSize(value) end)

    -- Space
    local title = UILabel.new(rowSizer, "", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)

    -- Height Limit Settings
    local title = UILabel.new(rowSizer, "Height Limit Settings", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    title:setBold(true)
    UIHorizontalLine.new(rowSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)

    local limitPlacementHeightsPanelSizer = UIGridSizer.new(1, 2, 2, 2)
    local limitPlacementHeightsPanel = UIPanel.new(rowSizer, limitPlacementHeightsPanelSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    local limitPlacementHeightsLabel = UILabel.new(limitPlacementHeightsPanelSizer, "Limit Placement Heights", false, TextAlignment.LEFT, VerticalAlignment.TOP, SelectionReplicatorByPaint.TEXT_WIDTH, -1)
    local limitPlacementHeights_Choice = UIChoice.new(limitPlacementHeightsPanelSizer, self.disabledEnabledChoice, 0, -1, 100, -1)
    limitPlacementHeights_Choice:setOnChangeCallback(function(value) self:setLimitPlacementHeights(value) end)

    local objectDistanceSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, objectDistanceSliderSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    UILabel.new(objectDistanceSliderSizer, "Min Placement Height", false, TextAlignment.LEFT, VerticalAlignment.TOP, SelectionReplicatorByPaint.TEXT_WIDTH, -1, 200);
    self.minHeightLevelSlider = UIIntSlider.new(objectDistanceSliderSizer, self.minHeightLevel, 1, 500);
    self.minHeightLevelSlider:setOnChangeCallback(function(value) self:setMinHeightLevel(value) end)

    local objectDistanceSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, objectDistanceSliderSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    UILabel.new(objectDistanceSliderSizer, "Max Placement Height", false, TextAlignment.LEFT, VerticalAlignment.TOP, SelectionReplicatorByPaint.TEXT_WIDTH, -1, 200);
    self.maxHeightLevelSlider = UIIntSlider.new(objectDistanceSliderSizer, self.maxHeightLevel, 1, 500);
    self.maxHeightLevelSlider:setOnChangeCallback(function(value) self:setMaxHeightLevel(value) end)

    -- Space
    local title = UILabel.new(rowSizer, "", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)

    -- Run Script Button
    local title = UILabel.new(rowSizer, "Click Run Script to Start", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    title:setBold(true)
    UIHorizontalLine.new(rowSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)

    UIButton.new(rowSizer, "Run Script", function() self:runSelectionReplicatorByPaint() end, self, -1, -1, -1, -1, BorderDirection.BOTTOM, 2, 1)

    -- layout and show window
    self.window:setOnCloseCallback(function() self:onClose() end)
    self.window:showWindow()

end

function SelectionReplicatorByPaint:close()
    self.window:close()
end

function SelectionReplicatorByPaint:onClose()
    -- Clears out any active functions
end

function SelectionReplicatorByPaint:setObjectDistance(value)
    -- print(value)
    if value > 0 then
      self.objectDistance = value
    else
      self.objectDistance = 1
    end
end

function SelectionReplicatorByPaint:setRestrictPaint(value)
    -- print(value)
    -- Change to true or false
    self.restrictPaint = (value ~= 1)
    -- print(self.restrictPaint)
end

function SelectionReplicatorByPaint:setRotationType(value)
    -- print(value)
    self.rotationType = value
end

function SelectionReplicatorByPaint:setObjectTrackerSize(value)
    -- print(value)
    self.objectTrackerSize = value
end

function SelectionReplicatorByPaint:setLimitPlacementHeights(value)
    -- print(value)
    -- Change to true or false
    self.limitPlacementHeights = (value ~= 1)
    -- print(self.limitPlacementHeights)
end

function SelectionReplicatorByPaint:setMinHeightLevel(value)
    -- print(value)
    self.minHeightLevel = value
end

function SelectionReplicatorByPaint:setMaxHeightLevel(value)
    -- print(value)
    self.maxHeightLevel = value
end

-- Function to walk up the selection and make sure the selection us under the top level parent specified on the top.
function SelectionReplicatorByPaint:walkParents(selectedNodeId)
    parentId = getParent(selectedNodeId)
    -- print(parentId)
    if parentId ~= 0 then
        if getName(parentId) == self.topLevelTransformName then
            topLevelTransformId = parentId
            return true
        elseif parentId < 2 then
            return false
        else
            return self:walkParents(parentId)
        end
    else
        return false
    end
end

-- Function to see if a transform is too close to another before it plants a new one.
function SelectionReplicatorByPaint:checkForNoTransformConflict(x, y, z, existingTransformNodesInRadius)
    local placeTransform = true
    local startIdx, endIdx = 1, #existingTransformNodesInRadius
    while startIdx <= endIdx do
        local value = existingTransformNodesInRadius[startIdx]
        local tx,ty,tz = getTranslation(value)
        if tx >= x-self.objectDistance and tx <= x+self.objectDistance and tz >= z-self.objectDistance and tz <= z+self.objectDistance then
            placeTransform = false
            break
        elseif not self.limitPlacementHeights and y < self.minHeightLevel then -- do not plant below minHeightLevel
            placeTransform = false
            break
        elseif not self.limitPlacementHeights and y > self.maxHeightLevel then -- do not plant above maxHeightLevel
            placeTransform = false
            break
        elseif self.restrictPaint == true then
            -- Only place transforms on allowed terrain paint.
            local cR, cG, cB, cW, cU = getTerrainAttributesAtWorldPos(self.mTerrainID, x, y, z, true, true, true, true, false)
            cR = string.format("%.12f",cR)
            cG = string.format("%.12f",cG)
            cB = string.format("%.12f",cB)
            cW = string.format("%f",cW)
            cU = string.format("%f",cU)
            -- print("Checking Transform Color Codes: R: "..cR.." G: "..cG.." B: "..cB.." W: "..cW.." U:" .. cU)
            if cR == self.CurLocColorR and cG == self.CurLocColorG and cB == self.CurLocColorB and cW == self.CurLocColorW then
                -- Matched color to current top transform location
                placeTransform = true
            else
                placeTransform = false
                break
            end
        else
            placeTransform = true
        end
        startIdx = startIdx + 1
    end
    return placeTransform
end

-- Walk down the transforms to find all children within the transform radius
function SelectionReplicatorByPaint:buildExistingTransformNodesInRadius(existingTransformNodesInRadius, parentTransformNodeId, origX, origZ)
    if parentTransformNodeId ~= nil then
        local numOfChildren = getNumOfChildren(parentTransformNodeId)
        if numOfChildren > 0 then
            for p=0,numOfChildren-1 do
                local childNodeId = getChildAt(parentTransformNodeId,p)
                local numOfChildren2 = getNumOfChildren(childNodeId)
                if numOfChildren2 > 0 then
                  local tx,ty,tz = getTranslation(childNodeId)
                  local childCheckId = getChildAt(childNodeId,0)
                  if getName(childCheckId) == "LOD0" then
                      if tx >= origX-(self.sectionSizeHalf+(self.objectDistance*2)) and tx <= origX+(self.sectionSizeHalf+(self.objectDistance*2)) and tz >= origZ-(self.sectionSizeHalf+(self.objectDistance*2)) and tz <= origZ+(self.sectionSizeHalf+(self.objectDistance*2)) then
                          table.insert(existingTransformNodesInRadius, childNodeId)
                      end
                  else
                      existingTransformNodesInRadius = self:buildExistingTransformNodesInRadius(existingTransformNodesInRadius, childNodeId, origX, origZ);
                  end
                end
            end
        end
    end
    return existingTransformNodesInRadius
end

function SelectionReplicatorByPaint:getLowestTerrainDirection(x, y, z)
    -- print(string.format("Calculating downhill direction for location: x=%d y=%d z=%d", x, y, z))

    if x ~= nil and y ~= nil and z ~= nil then
        local lowestHeight = math.huge
        local lowestDirection = nil
        local heightSums = {}

        local radii = {1, 2, 4, 8} -- Radii to check
        for _, radius in ipairs(radii) do
            for angle = 0, 360, 15 do -- 15° increments
                local rad = math.rad(angle)
                local checkX = x + math.cos(rad) * radius
                local checkZ = z + math.sin(rad) * radius
                local terrainHeight = getTerrainHeightAtWorldPos(self.mTerrainID, checkX, 0, checkZ)

                -- Normalize angle within -360 to 360
                local normalizedAngle = (angle % 360 + 360) % 360
                if normalizedAngle > 180 then
                    normalizedAngle = normalizedAngle - 360
                end

                heightSums[#heightSums + 1] = {
                    rotation = normalizedAngle,
                    height = terrainHeight
                }

                if terrainHeight < lowestHeight then
                    lowestHeight = terrainHeight
                    lowestDirection = normalizedAngle
                end
            end
        end

        -- Compute weighted average direction
        local directionSum = 0
        local weightSum = 0
        for _, data in ipairs(heightSums) do
            local weight = 1 / (1 + math.abs(data.height - lowestHeight))
            directionSum = directionSum + data.rotation * weight
            weightSum = weightSum + weight
        end

        local weightedDirection = directionSum / weightSum

        -- Normalize final weighted direction within -360 to 360
        weightedDirection = (weightedDirection % 360 + 360) % 360
        if weightedDirection > 180 then
            weightedDirection = weightedDirection - 360
        end

        return weightedDirection
    end

    return 0
end



function SelectionReplicatorByPaint:runTransformPlacementStuff()
    -- These are the main variables to process everything.
    local origX = 0
    local origZ = 0
    local x = 0
    local y = 0
    local z = 0
    local transformsPlaced = 0
    local transformConflicts = 0
    local existingTransformNodesInRadius = {}
    local newTransformsTable = {}
    print("Num Selected Transforms to Randomly place: " .. getNumSelected())

    -- Calculate the width and height of each section
    local sectionWidth = self.sectionSize
    local sectionHeight = self.sectionSize

    -- Table to store center points
    local centerPoints = {}

    -- Calculate center points
    for i = 0, self.numSectionsX - 1 do
        for j = 0, self.numSectionsY - 1 do
            local centerX = (i * sectionWidth) + (sectionWidth / 2) - (self.halfTerrainSize)
            local centerY = (j * sectionHeight) + (sectionHeight / 2) - (self.halfTerrainSize)
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

            local transformTracker = self.objectTrackerSize

            -- transformNodeId = getSelection(0)
            -- x,y,z = getTranslation(transformNodeId)
            -- print("Selected Transform Location: " .. x .. " " .. y .. " " .. z)
            existingTransformNodesInRadius = self:buildExistingTransformNodesInRadius(existingTransformNodesInRadius, topLevelTransformId, x, z)
            while(transformTracker > 0) do
                -- transformNodeId = getSelection(0)
                -- x,y,z = getTranslation(transformNodeId)
                origX = point.x
                origZ = point.z
                local transformPlacedCheck = false
                for c=0, 1, 1 do
                    -- print(string.format("self.SectionSizeHalf: %d", self.sectionSizeHalf))
                    local randomX = math.random(-self.sectionSizeHalf,self.sectionSizeHalf)
                    local randomZ = math.random(-self.sectionSizeHalf,self.sectionSizeHalf)
                    -- print(string.format("OrigX: %d OrigdZ: %d", origX, origZ))
                    -- print(string.format("RanX: %d RanZ: %d", randomX, randomZ))
                    x = origX+randomX
                    z = origZ+randomZ
                    -- print(string.format("X: %d Z: %d", x, z))

                    local terrainHeight = getTerrainHeightAtWorldPos(self.mTerrainID, x, y, z)
                    if self:checkForNoTransformConflict(x, terrainHeight, z, existingTransformNodesInRadius) == true and terrainHeight > 0 then
                        transformNodeId = getSelection(math.random(0,getNumSelected()-1))
                        local transform = clone(transformNodeId, true)
                        
                        -- Create the transform
                        local rx = 0
                        local rz = 0
                        local ry = 0

                        -- Set location for new transform
                        setTranslation(transformNodeId, x, terrainHeight, z)

                        -- Check to see what the rotation should be for the new transform
                        if self.rotationType == 2 then
                            -- Randomly Rotate Transform
                            setRotation(transformNodeId, rx, math.rad(math.random(1, 360)), rz)
                        elseif self.rotationType == 3 then
                            -- Rotate towards lowest nearby terrain
                            local nry = self:getLowestTerrainDirection(x, terrainHeight, z)
                            setRotation(transformNodeId, rx, nry, rz)
                        else
                            -- Default to no rotation
                            setRotation(transformNodeId, rx, ry, rz)
                        end



                        transformsPlaced = transformsPlaced + 1
                        transformTracker = transformTracker + 1
                        transformPlacedCheck = true
                        if transform then
                            table.insert(existingTransformNodesInRadius, transform)
                            table.insert(newTransformsTable, transform)
                        end
                        break
                    end
                end
                if transformPlacedCheck == false then
                    transformTracker = transformTracker - 1
                end
                -- print(string.format("Transform Tracker: %d", transformTracker))
            end

        end
    end

    -- Create a new transform group to put the new transforms in
    local parentGroup = getParent(getSelection(0));
    local newTransformGroup = createTransformGroup(self.topLevelTransformName .. "-new");
    link(parentGroup, newTransformGroup)
    -- Loop through all the new transforms and put them into their own transport group    
    if newTransformsTable ~= nil and #newTransformsTable > 0 then
      print("Putting New Transforms in their own transport group.")
      for _,newTransform in pairs(newTransformsTable) do
        link(newTransformGroup,newTransform)
      end
    end
    print("Number of Transforms Placed: " .. transformsPlaced)
    if(transformsPlaced == 0 and transformTracker == 0) then
        printError("Error: Could not place additional transforms.")
    end

end

function SelectionReplicatorByPaint:runSelectionReplicatorByPaint()
    if self.limitPlacementHeights == true and self.minHeightLevel > self.maxHeightLevel then
        printError("Error: Min height must be less than max height.")
        return
    end

    if (getNumSelected() == 0) then
        print("Error: Select one or more transforms.")
        return nil
    end

    -- Get the section radius
    self.sectionSize = self.terrainSize / self.numSectionsX
    self.sectionSizeHalf = self.sectionSize / 2

    -- print(string.format("Section Size: %d - Section Size Half: %d", self.sectionSize, self.sectionSizeHalf))

    -- Auto get color of texture that the first transform selected is currently on.
    print("Starting Transform Replication Script.  This process may take a moment to complete once started.")
    -- Get terrain color data for current location of first transform
    local transformNodeId = getSelection(0)
    local tx,ty,tz = getTranslation(transformNodeId)
    local CurLocColorR, CurLocColorG, CurLocColorB, CurLocColorW, CurLocColorU = getTerrainAttributesAtWorldPos(self.mTerrainID, tx, ty, tz, true, true, true, true, false)

    self.CurLocColorR = string.format("%.12f",CurLocColorR)
    self.CurLocColorG = string.format("%.12f",CurLocColorG)
    self.CurLocColorB = string.format("%.12f",CurLocColorB)
    self.CurLocColorW = string.format("%f",CurLocColorW)
    self.CurLocColorU = string.format("%f",CurLocColorU)

    print("Selected Transform Location: X: "..tx.." Y: "..ty.." Z: "..tz)
    print("Selected Transform Color Codes: R: "..self.CurLocColorR.." G: "..self.CurLocColorG.." B: "..self.CurLocColorB.." W: "..self.CurLocColorW .. " U: "..self.CurLocColorU)

    -- Get parent group name and stuff
    self.topLevelTransformName = getName(getParent(getSelection(0)))


    for selectCount = 0, getNumSelected()-1 do
        transformNodeId = getSelection(selectCount)
        local numOfChildren = getNumOfChildren(transformNodeId)
        if numOfChildren > 0 then
            childName = getName(getChildAt(transformNodeId,0))
        else
            childName = nil
        end
        TransformExists = self:walkParents(transformNodeId)
        if TransformExists == false then
            break
        end
    end

    if TransformExists == true then
        self:runTransformPlacementStuff()
    elseif getNumSelected() > 0 then
        print("Please select a transform to replicate.")
    else
        print("Please select a transform to replicate.")
    end

    print("Script Done")

end

-- Start the party
SelectionReplicatorByPaint:new()