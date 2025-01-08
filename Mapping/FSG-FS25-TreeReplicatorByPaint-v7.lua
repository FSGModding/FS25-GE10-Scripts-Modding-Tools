-- Author: FSG Modding
-- Name: FSG - Tree Replicator By Paint Script v7
-- Description: Replicates selected trees randomly on terrain paint that matches the terrain paint for first selected tree.
-- Icon:
-- Hide:no
-- Date: 1.7.2025

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
      
    self.treeDistance = 3
    self.minHeightLevel = 1
    self.maxHeightLevel = 500
    self.limitPlacementHeights = false
    self.treeTrackerSize = 100
    self.restrictPaint = true
    self.totalSections = 64
    self.mapPartition = 0
    self.randomAngledTrees = false

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

    g_currentPaintTerrainBySplineDialog = self

    return self

end

-- Generate UI Function
function PaintTerrainBySpline:generateUI()
    -- Setup UI
    local frameRowSizer = UIRowLayoutSizer.new()
    self.window = UIWindow.new(frameRowSizer, "Tree Replicator Tool")

    local borderSizer = UIRowLayoutSizer.new()
    UIPanel.new(frameRowSizer, borderSizer)

    local rowSizer = UIRowLayoutSizer.new()
    UIPanel.new(borderSizer, rowSizer, -1, -1, PaintTerrainBySpline.WINDOW_WIDTH, PaintTerrainBySpline.WINDOW_HEIGHT, BorderDirection.ALL, 10, 1)

    -- Tree Replicator Settings
    local title = UILabel.new(rowSizer, "Tree Replicator Settings", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    title:setBold(true)
    UIHorizontalLine.new(rowSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)

    local objectDistanceSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, objectDistanceSliderSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    UILabel.new(objectDistanceSliderSizer, "Tree Radius - Meters", false, TextAlignment.LEFT, VerticalAlignment.TOP, PaintTerrainBySpline.TEXT_WIDTH, -1, 200);
    self.treeDistanceSlider = UIIntSlider.new(objectDistanceSliderSizer, self.treeDistance, 1, 50 );
    self.treeDistanceSlider:setOnChangeCallback(function(value) self:setTreeDistance(value) end)

    local restrictPaintPanelSizer = UIGridSizer.new(1, 2, 2, 2)
    local restrictPaintPanel = UIPanel.new(rowSizer, restrictPaintPanelSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    local restrictPaintLabel = UILabel.new(restrictPaintPanelSizer, "Limit to Texture", false, TextAlignment.LEFT, VerticalAlignment.TOP, PaintTerrainBySpline.TEXT_WIDTH, -1)
    local restrictPaint_Choice = UIChoice.new(restrictPaintPanelSizer, self.disabledEnabledChoice, 1, -1, 100, -1)
    restrictPaint_Choice:setOnChangeCallback(function(value) self:setRestrictPaint(value) end)

    local randomAngledTreesPanelSizer = UIGridSizer.new(1, 2, 2, 2)
    local randomAngledTreesPanel = UIPanel.new(rowSizer, randomAngledTreesPanelSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    local randomAngledTreesLabel = UILabel.new(randomAngledTreesPanelSizer, "Randomly Angle Trees", false, TextAlignment.LEFT, VerticalAlignment.TOP, PaintTerrainBySpline.TEXT_WIDTH, -1)
    local randomAngledTrees_Choice = UIChoice.new(randomAngledTreesPanelSizer, self.disabledEnabledChoice, 0, -1, 100, -1)
    randomAngledTrees_Choice:setOnChangeCallback(function(value) self:setRandomAngledTrees(value) end)

    local objectDistanceSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, objectDistanceSliderSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    UILabel.new(objectDistanceSliderSizer, "Placement Fail Limit", false, TextAlignment.LEFT, VerticalAlignment.TOP, PaintTerrainBySpline.TEXT_WIDTH, -1, 200);
    self.treeTrackerSizeSlider = UIIntSlider.new(objectDistanceSliderSizer, self.treeTrackerSize, 1, 1000);
    self.treeTrackerSizeSlider:setOnChangeCallback(function(value) self:setTreeTrackerSize(value) end)

    -- Space
    local title = UILabel.new(rowSizer, "", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)

    -- Height Limit Settings
    local title = UILabel.new(rowSizer, "Height Limit Settings", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    title:setBold(true)
    UIHorizontalLine.new(rowSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)

    local limitPlacementHeightsPanelSizer = UIGridSizer.new(1, 2, 2, 2)
    local limitPlacementHeightsPanel = UIPanel.new(rowSizer, limitPlacementHeightsPanelSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    local limitPlacementHeightsLabel = UILabel.new(limitPlacementHeightsPanelSizer, "Limit Placement Heights", false, TextAlignment.LEFT, VerticalAlignment.TOP, PaintTerrainBySpline.TEXT_WIDTH, -1)
    local limitPlacementHeights_Choice = UIChoice.new(limitPlacementHeightsPanelSizer, self.disabledEnabledChoice, 0, -1, 100, -1)
    limitPlacementHeights_Choice:setOnChangeCallback(function(value) self:setLimitPlacementHeights(value) end)

    local objectDistanceSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, objectDistanceSliderSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    UILabel.new(objectDistanceSliderSizer, "Min Placement Height", false, TextAlignment.LEFT, VerticalAlignment.TOP, PaintTerrainBySpline.TEXT_WIDTH, -1, 200);
    self.minHeightLevelSlider = UIIntSlider.new(objectDistanceSliderSizer, self.minHeightLevel, 1, 500);
    self.minHeightLevelSlider:setOnChangeCallback(function(value) self:setMinHeightLevel(value) end)

    local objectDistanceSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, objectDistanceSliderSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    UILabel.new(objectDistanceSliderSizer, "Max Placement Height", false, TextAlignment.LEFT, VerticalAlignment.TOP, PaintTerrainBySpline.TEXT_WIDTH, -1, 200);
    self.maxHeightLevelSlider = UIIntSlider.new(objectDistanceSliderSizer, self.maxHeightLevel, 1, 500);
    self.maxHeightLevelSlider:setOnChangeCallback(function(value) self:setMaxHeightLevel(value) end)

    -- Space
    local title = UILabel.new(rowSizer, "", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)

    -- Run Script Button
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

function PaintTerrainBySpline:setTreeDistance(value)
    -- print(value)
    if value > 0 then
      self.treeDistance = value
    else
      self.treeDistance = 1
    end
end

function PaintTerrainBySpline:setRestrictPaint(value)
    -- print(value)
    -- Change to true or false
    self.restrictPaint = (value ~= 1)
    print(self.restrictPaint)
end

function PaintTerrainBySpline:setRandomAngledTrees(value)
    -- print(value)
    -- Change to true or false
    self.randomAngledTrees = (value ~= 1)
    print(self.randomAngledTrees)
end

function PaintTerrainBySpline:setTreeTrackerSize(value)
    -- print(value)
    self.treeTrackerSize = value
end

function PaintTerrainBySpline:setLimitPlacementHeights(value)
    -- print(value)
    -- Change to true or false
    self.limitPlacementHeights = (value ~= 1)
    print(self.limitPlacementHeights)
end

function PaintTerrainBySpline:setMinHeightLevel(value)
    -- print(value)
    self.minHeightLevel = value
end

function PaintTerrainBySpline:setMaxHeightLevel(value)
    -- print(value)
    self.maxHeightLevel = value
end

-- Function to walk up the tree and make sure the selection us under the top level parent specified on the top.
function PaintTerrainBySpline:walkParents(treeNodeId)
    parentId = getParent(treeNodeId)
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

-- Function to see if a tree is too close to another before it plants a new one.
function PaintTerrainBySpline:checkForNoTreeConflict(x, y, z, existingTreeNodesInRadius)
    local placeTree = true
    local startIdx, endIdx = 1, #existingTreeNodesInRadius
    while startIdx <= endIdx do
        local value = existingTreeNodesInRadius[startIdx]
        local tx,ty,tz = getTranslation(value)
        if tx >= x-self.treeDistance and tx <= x+self.treeDistance and tz >= z-self.treeDistance and tz <= z+self.treeDistance then
            placeTree = false
            break
        elseif not self.limitPlacementHeights and y < self.minHeightLevel then -- do not plant below minHeightLevel
            placeTree = false
            break
        elseif not self.limitPlacementHeights and y > self.maxHeightLevel then -- do not plant above maxHeightLevel
            placeTree = false
            break
        elseif self.restrictPaint == true then
            -- Only plant trees on allowed terrain paint.
            local cR, cG, cB, cW, cU = getTerrainAttributesAtWorldPos(self.mTerrainID, x, y, z, true, true, true, true, false)
            cR = string.format("%.12f",cR)
            cG = string.format("%.12f",cG)
            cB = string.format("%.12f",cB)
            cW = string.format("%f",cW)
            cU = string.format("%f",cU)
            -- print("Checking Tree Color Codes: R: "..cR.." G: "..cG.." B: "..cB.." W: "..cW.." U:" .. cU)
            if cR == self.CurLocColorR and cG == self.CurLocColorG and cB == self.CurLocColorB and cW == self.CurLocColorW then
                -- Matched color to current top tree location
                placeTree = true
            else
                placeTree = false
                break
            end
        else
            placeTree = true
        end
        startIdx = startIdx + 1
    end
    return placeTree
end

-- Walk down the tree to find all children within the tree radius
function PaintTerrainBySpline:buildExistingTreeNodesInRadius(existingTreeNodesInRadius, parentTreeNodeId, origX, origZ)
    if parentTreeNodeId ~= nil then
        local numOfChildren = getNumOfChildren(parentTreeNodeId)
        local nameCheck = getName(parentTreeNodeId) == "partitionMarkers"
        if numOfChildren > 0 and not nameCheck then
            for p=0,numOfChildren-1 do
                local childNodeId = getChildAt(parentTreeNodeId,p)
                local numOfChildren2 = getNumOfChildren(childNodeId)
                if numOfChildren2 > 0 then
                  local tx,ty,tz = getTranslation(childNodeId)
                  local childCheckId = getChildAt(childNodeId,0)
                  if getName(childCheckId) == "LOD0" then
                      if tx >= origX-(self.sectionSizeHalf+(self.treeDistance*2)) and tx <= origX+(self.sectionSizeHalf+(self.treeDistance*2)) and tz >= origZ-(self.sectionSizeHalf+(self.treeDistance*2)) and tz <= origZ+(self.sectionSizeHalf+(self.treeDistance*2)) then
                          table.insert(existingTreeNodesInRadius, childNodeId)
                      end
                  else
                      existingTreeNodesInRadius = self:buildExistingTreeNodesInRadius(existingTreeNodesInRadius, childNodeId, origX, origZ);
                  end
                end
            end
        end
    end
    return existingTreeNodesInRadius
end

function PaintTerrainBySpline:runTreePlacementStuff()
    -- These are the main variables to process everything.
    local origX = 0
    local origZ = 0
    local x = 0
    local y = 0
    local z = 0
    local treesPlaced = 0
    local treeConflicts = 0
    local existingTreeNodesInRadius = {}
    local newTreesTable = {}
    print("Num Selected Trees to Randomly place: " .. getNumSelected())

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

            local treeTracker = self.treeTrackerSize

            -- treeNodeId = getSelection(0)
            -- x,y,z = getTranslation(treeNodeId)
            -- print("Selected Tree Location: " .. x .. " " .. y .. " " .. z)
            existingTreeNodesInRadius = self:buildExistingTreeNodesInRadius(existingTreeNodesInRadius, topLevelTransformId, x, z)
            while(treeTracker > 0) do
                -- treeNodeId = getSelection(0)
                -- x,y,z = getTranslation(treeNodeId)
                origX = point.x
                origZ = point.z
                local treePlacedCheck = false
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
                    if self:checkForNoTreeConflict(x, terrainHeight, z, existingTreeNodesInRadius) == true and terrainHeight > 0 then
                        treeNodeId = getSelection(math.random(0,getNumSelected()-1))
                        local tree = clone(treeNodeId, true)
                        
                        -- Create the tree
                        local rx = 0
                        local rz = 0
                        local sideWaysRotationAdjustment = 0

                        if randomAngledTrees then
                            -- Randomly set some trees slightly angled
                            local randomIndex = math.random(1, 30)
                            if randomIndex == 10 or randomIndex == 20 then
                              local ranAngle = {0.03,0.05,0.07,0.09}
                              local randomAngle1 = math.random(1,4)
                              local randomAngle2 = math.random(1,4)
                              rx = 0 + ranAngle[randomAngle1]
                              rz = 0 + ranAngle[randomAngle2]
                              sideWaysRotationAdjustment = -0.15
                            end
                        end

                        -- update tree rotation and angle
                        setTranslation(treeNodeId, x, terrainHeight+sideWaysRotationAdjustment, z)
                        setRotation(treeNodeId, rx, math.rad(math.random(1, 360)), rz)


                        treesPlaced = treesPlaced + 1
                        treeTracker = treeTracker + 1
                        treePlacedCheck = true
                        if tree then
                            table.insert(existingTreeNodesInRadius, tree)
                            table.insert(newTreesTable, tree)
                        end
                        break
                    end
                end
                if treePlacedCheck == false then
                    treeTracker = treeTracker - 1
                end
                -- print(string.format("Tree Tracker: %d", treeTracker))
            end

        end
    end

    -- Create a new transform group to put the new trees in
    local parentGroup = getParent(getSelection(0));
    local newTreeGroup = createTransformGroup(self.topLevelTransformName .. "-new");
    link(parentGroup, newTreeGroup)
    -- Loop through all the new trees and put them into their own transport group    
    if newTreesTable ~= nil and #newTreesTable > 0 then
      print("Putting New Trees in their own transport group.")
      for _,newTree in pairs(newTreesTable) do
        link(newTreeGroup,newTree)
      end
    end
    print("Number of Trees Placed: " .. treesPlaced)
    if(treesPlaced == 0 and treeTracker == 0) then
        printError("Error: Could not place additional trees.")
    end

    -- If partation markers enabled then create new tranportgorup for them
    if partitionMarkers then
        local parentGroup = getParent(getSelection(0));
        local newMarkersGroup = createTransformGroup("partitionMarkers");
        link(parentGroup, newMarkersGroup)
        -- Loop through all the new trees and put them into their own transport group   
        for index, point in ipairs(centerPoints) do
          local pmg = createTransformGroup(string.format("partition_%s",FormatNumber(index)));
          link(newMarkersGroup,pmg)
          -- Get terrain height
          local terrainHeight = getTerrainHeightAtWorldPos(self.mTerrainID, point.x, 0, point.z)
          setTranslation(pmg, point.x, terrainHeight, point.z)
          -- Create corners for each partition so it can be mapped later if needed
          local pmg1 = createTransformGroup(string.format("partition_%s_corner_1",FormatNumber(index)));
          local pmg2 = createTransformGroup(string.format("partition_%s_corner_2",FormatNumber(index)));
          local pmg3 = createTransformGroup(string.format("partition_%s_corner_3",FormatNumber(index)));
          local pmg4 = createTransformGroup(string.format("partition_%s_corner_4",FormatNumber(index)));
          link(pmg,pmg1)
          link(pmg,pmg2)
          link(pmg,pmg3)
          link(pmg,pmg4)
          setTranslation(pmg1, -self.sectionSizeHalf, terrainHeight, self.sectionSizeHalf)
          setTranslation(pmg2, self.sectionSizeHalf, terrainHeight, self.sectionSizeHalf)
          setTranslation(pmg3, -self.sectionSizeHalf, terrainHeight, -self.sectionSizeHalf)
          setTranslation(pmg4, self.sectionSizeHalf, terrainHeight, -self.sectionSizeHalf)
        end
    end

end

function PaintTerrainBySpline:runPaintTerrainBySpline()
    if self.limitPlacementHeights == true and self.minHeightLevel > self.maxHeightLevel then
        printError("Error: Min height must be less than max height.")
        return
    end

    if (getNumSelected() == 0) then
        print("Error: Select one or more trees.")
        return nil
    end

    -- Get the section radius
    self.sectionSize = self.terrainSize / self.numSectionsX
    self.sectionSizeHalf = self.sectionSize / 2

    -- print(string.format("Section Size: %d - Section Size Half: %d", self.sectionSize, self.sectionSizeHalf))

    -- Auto get color of texture that the first tree selected is currently on.
    print("Starting Tree Replication Script.  This process may take a moment to complete once started.")
    -- Get terrain color data for current location of first tree
    local treeNodeId = getSelection(0)
    local tx,ty,tz = getTranslation(treeNodeId)
    local CurLocColorR, CurLocColorG, CurLocColorB, CurLocColorW, CurLocColorU = getTerrainAttributesAtWorldPos(self.mTerrainID, tx, ty, tz, true, true, true, true, false)

    self.CurLocColorR = string.format("%.12f",CurLocColorR)
    self.CurLocColorG = string.format("%.12f",CurLocColorG)
    self.CurLocColorB = string.format("%.12f",CurLocColorB)
    self.CurLocColorW = string.format("%f",CurLocColorW)
    self.CurLocColorU = string.format("%f",CurLocColorU)

    print("Selected Tree Location: X: "..tx.." Y: "..ty.." Z: "..tz)
    print("Selected Tree Color Codes: R: "..self.CurLocColorR.." G: "..self.CurLocColorG.." B: "..self.CurLocColorB.." W: "..self.CurLocColorW .. " U: "..self.CurLocColorU)

    -- Get parent group name and stuff
    self.topLevelTransformName = getName(getParent(getSelection(0)))


    for selectCount = 0, getNumSelected()-1 do
        treeNodeId = getSelection(selectCount)
        local numOfChildren = getNumOfChildren(treeNodeId)
        if numOfChildren > 0 then
            childName = getName(getChildAt(treeNodeId,0))
        else
            childName = nil
        end
        if childName ~= "LOD0" then
            TreeExists = false
            break
        else
            TreeExists = self:walkParents(treeNodeId)
        end
        if TreeExists == false then
            break
        end
    end

    if TreeExists == true then
        self:runTreePlacementStuff()
    elseif getNumSelected() > 0 then
        print("Not all selections were detected as compatible trees.\nSelected trees need to have LOD0 as the first child node and "..self.topLevelTransformName.." as the highest parent.")
    else
        print("Please select a tree to replicate.")
    end

    print("Script Done")

end

-- Start the party
PaintTerrainBySpline:new()