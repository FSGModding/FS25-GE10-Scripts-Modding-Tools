-- Author: FSG Modding
-- Name: FSG Auto Trees Replicator Rotation v6
-- Description: Replicate the selected tree(s) with random rotation on selected texture for entire map.
-- Icon:
-- Hide: no

-- Instructions
-- Put a group of trees in their own transformgroup.
-- Place the first (top) tree in the transformgroup on the texture you would like the trees to be replicated on.
-- Select the trees you want replicated.
-- Run the script and wait.  It takes a little while.

-- Settings
-- Tree Spacing in Meters - How far apart you want the trees placed.
-- Placement Fail Limit - The higher the number, the more places the script checks for locations to place trees, but higher the number the longer it takes.
-- Number of Map Partitions - How many partitions to separate the map into for tree placement.  This really just splits up the map into smaller areas to keep the memory usage down.
-- Limit to Map Partition - If not 0, the system will only run within the partition number selected.  This is for if you want to do one section at a time.
-- Randomly Angle Trees - When enabled it will randomly angle trees to give a slight bit more realism to the map.

-- This script takes some times to run.  If you want to see which partition (section) it is on open the editor_log.txt in VS Code and watch it update as it starts new sections.  GE does not update console display while running scripts.

-- Warning: Trees will place inside objects.


-- Changable Variables
local minHeightLevel = 1              -- Do not place trees below this Y level.
local maxHeightLevel = 9999           -- Do not place trees above this Y level.
local allowTreesAnywhere = false      -- This will override the minHeightLevel and maxHeightLevel variables and place the trees at any Y level.
local treeDistance = 5                -- The radius restriction for how far apart the trees should be placed.
local treeTrackerSize = 100           -- How many random points to skip that have no trees placed before ending section
local restrictPaint = true            -- Only plant on the ground type that first selected tree is located on.
local totalSections = 64              -- How many sections to devide the map up into for tree generation. 
local mapPartition = 0                -- Only runs within partition if not 0.  0 will run all partitions of map.
local randomAngledTrees = false       -- Sets random trees with a slight angle so not all trees are perfectly stright.
local partitionMarkers = false        -- Creates transform groups for center of each partition named with partition number.

-- DO NOT CHANGE ANYTHING BELOW THIS LINE UNLESS YOU KNOW WHAT YOU ARE DOING.

local function setTreeDistance(value)
    treeDistance = value
end

local function setTreeTrackerSize(value)
    treeTrackerSize = value
end

local function setTotalSections(value)
    totalSections = value
end

local function setMapPartition(value)
    mapPartition = value
end

local function setRandomAngledTrees(value)
    randomAngledTrees = value
end

local function setPartitionMarkers(value)
    partitionMarkers = value
end

-- Format Number with 00 at start if under 9 | add 0 if under 100
local function FormatNumber(idx)
    if idx < 10 then
        return string.format("00%s", idx)
    elseif idx < 100 then
        return string.format("0%s", idx)
    else
        return idx
    end
end

local TreeExists = false
local topLevelTransformId = -1

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
    print("Error: Terrain node not found. Node needs to be named 'terrain'.")
    return nil
end

local Terrain = getChild(getRootNode(), "terrain")

if Terrain == 0 then
    printError("Error: Failed to find terrain node")
    return
end

if (getNumSelected() == 0) then
    print("Error: Select one or more trees.")
    return nil
end

local terrainSize = getTerrainSize(mTerrainID)
local halfTerrainSize = terrainSize / 2

-- Number of sections
local numSectionsX = math.sqrt(totalSections)
local numSectionsY = math.sqrt(totalSections)

-- Get the section radius
local sectionSize = terrainSize / numSectionsX
local sectionSizeHalf = sectionSize / 2

print(string.format("Section Size: %d - Section Size Half: %d", sectionSize, sectionSizeHalf))

-- Auto get color of texture that the first tree selected is currently on.
print("Starting Tree Replication Script.  This process may take a moment to complete once started.")
treeNodeId = getSelection(0)
local tx,ty,tz = getTranslation(treeNodeId)
local CurLocColorR, CurLocColorG, CurLocColorB, CurLocColorW, CurLocColorU = getTerrainAttributesAtWorldPos(Terrain, tx, ty, tz, true, true, true, true, false)

CurLocColorR = string.format("%.12f",CurLocColorR)
CurLocColorG = string.format("%.12f",CurLocColorG)
CurLocColorB = string.format("%.12f",CurLocColorB)
CurLocColorW = string.format("%f",CurLocColorW)
CurLocColorU = string.format("%f",CurLocColorU)

print("Selected Tree Location: X: "..tx.." Y: "..ty.." Z: "..tz)
print("Selected Tree Color Codes: R: "..CurLocColorR.." G: "..CurLocColorG.." B: "..CurLocColorB.." W: "..CurLocColorW .. " U: "..CurLocColorU)

-- Get parent group name and stuff
local topLevelTransformName = getName(getParent(getSelection(0)))

-- Function to walk up the tree and make sure the selection us under the top level parent specified on the top.
local function walkParents(treeNodeId)
    parentId = getParent(treeNodeId)
    if getName(parentId) == topLevelTransformName then
        topLevelTransformId = parentId
        return true
    elseif parentId < 2 then
        return false
    else
        return walkParents(parentId)
    end
end

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
        TreeExists = walkParents(treeNodeId)
    end
    if TreeExists == false then
        break
    end
end

if TreeExists == true then

    local function runTreePlacementStuff()

        -- Walk down the tree to find all children within the tree radius
        local function buildExistingTreeNodesInRadius(existingTreeNodesInRadius, parentTreeNodeId, origX, origZ)
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
                              if tx >= origX-(sectionSizeHalf+(treeDistance*2)) and tx <= origX+(sectionSizeHalf+(treeDistance*2)) and tz >= origZ-(sectionSizeHalf+(treeDistance*2)) and tz <= origZ+(sectionSizeHalf+(treeDistance*2)) then
                                  table.insert(existingTreeNodesInRadius, childNodeId)
                              end
                          else
                              existingTreeNodesInRadius = buildExistingTreeNodesInRadius(existingTreeNodesInRadius, childNodeId, origX, origZ);
                          end
                        end
                    end
                end
            end
            return existingTreeNodesInRadius
        end

        -- Function to see if a tree is too close to another before it plants a new one.
        local function checkForNoTreeConflict(x, y, z, treeDistance, existingTreeNodesInRadius, allowTreesAnywhere, minHeightLevel, maxHeightLevel)
            local placeTree = true
            local startIdx, endIdx = 1, #existingTreeNodesInRadius
            while startIdx <= endIdx do
                local value = existingTreeNodesInRadius[startIdx]
                local tx,ty,tz = getTranslation(value)
                if tx >= x-treeDistance and tx <= x+treeDistance and tz >= z-treeDistance and tz <= z+treeDistance then
                    placeTree = false
                    break
                elseif not allowTreesAnywhere and y < minHeightLevel then -- do not plant below minHeightLevel
                    placeTree = false
                    break
                elseif not allowTreesAnywhere and y > maxHeightLevel then -- do not plant above maxHeightLevel
                    placeTree = false
                    break
                elseif restrictPaint == true then
                    -- Only plant trees on allowed terrain paint.
                    local cR, cG, cB, cW, cU = getTerrainAttributesAtWorldPos(Terrain, x, y, z, true, true, true, true, false)
                    cR = string.format("%.12f",cR)
                    cG = string.format("%.12f",cG)
                    cB = string.format("%.12f",cB)
                    cW = string.format("%f",cW)
                    cU = string.format("%f",cU)
                    -- print("Checking Tree Color Codes: R: "..cR.." G: "..cG.." B: "..cB.." W: "..cW.." U:" .. cU)
                    if cR == CurLocColorR and cG == CurLocColorG and cB == CurLocColorB and cW == CurLocColorW then
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
            if mapPartition == 0 or (mapPartition > 0 and mapPartition == index) then

                print(string.format("Section %d: Center (x, y) = (%.2f, %.2f)", index, point.x, point.z))

                x = point.x
                z = point.z

                local treeTracker = treeTrackerSize

                -- treeNodeId = getSelection(0)
                -- x,y,z = getTranslation(treeNodeId)
                -- print("Selected Tree Location: " .. x .. " " .. y .. " " .. z)
                existingTreeNodesInRadius = buildExistingTreeNodesInRadius(existingTreeNodesInRadius, topLevelTransformId, x, z)
                while(treeTracker > 0) do
                    -- treeNodeId = getSelection(0)
                    -- x,y,z = getTranslation(treeNodeId)
                    origX = point.x
                    origZ = point.z
                    local treePlacedCheck = false
                    for c=0, 1, 1 do
                        -- print(string.format("SectionSizeHalf: %d", sectionSizeHalf))
                        local randomX = math.random(-sectionSizeHalf,sectionSizeHalf)
                        local randomZ = math.random(-sectionSizeHalf,sectionSizeHalf)
                        -- print(string.format("OrigX: %d OrigdZ: %d", origX, origZ))
                        -- print(string.format("RanX: %d RanZ: %d", randomX, randomZ))
                        x = origX+randomX
                        z = origZ+randomZ
                        -- print(string.format("X: %d Z: %d", x, z))

                        local terrainHeight = getTerrainHeightAtWorldPos(Terrain, x, y, z)
                        if checkForNoTreeConflict(x, terrainHeight, z, treeDistance, existingTreeNodesInRadius, allowTreesAnywhere, minHeightLevel, maxHeightLevel) == true and terrainHeight > 0 then
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
        local newTreeGroup = createTransformGroup(topLevelTransformName .. "-new");
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
            print("Could not place additional trees.")
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
              local terrainHeight = getTerrainHeightAtWorldPos(Terrain, point.x, 0, point.z)
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
              setTranslation(pmg1, -sectionSizeHalf, terrainHeight, sectionSizeHalf)
              setTranslation(pmg2, sectionSizeHalf, terrainHeight, sectionSizeHalf)
              setTranslation(pmg3, -sectionSizeHalf, terrainHeight, -sectionSizeHalf)
              setTranslation(pmg4, sectionSizeHalf, terrainHeight, -sectionSizeHalf)
            end
        end

    end


    -- UI
    local labelWidth = 240.0
    
    local boolean = {"true","false"}

    local frameSizer = UIRowLayoutSizer.new()
    local myFrame = UIWindow.new(frameSizer, "FSG Tree Placement ")

    local borderSizer = UIRowLayoutSizer.new()
    UIPanel.new(frameSizer, borderSizer)

    local rowSizer = UIRowLayoutSizer.new()
    UIPanel.new(borderSizer, rowSizer, -1, -1, -1, -1, BorderDirection.ALL, 10, 1)

    local treeDistanceSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, treeDistanceSliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    UILabel.new(treeDistanceSliderSizer, "Tree Spacing in Meters", TextAlignment.LEFT, -1, -1, labelWidth);
    local treeDistanceSlider = UIIntSlider.new(treeDistanceSliderSizer, treeDistance, 0, 255 );
    treeDistanceSlider:setOnChangeCallback(setTreeDistance)

    local treeTrakcerSizeSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, treeTrakcerSizeSliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    UILabel.new(treeTrakcerSizeSliderSizer, "Placement Fail Limit", TextAlignment.LEFT, -1, -1, labelWidth);
    local treeTrakcerSizeSlider = UIIntSlider.new(treeTrakcerSizeSliderSizer, treeTrackerSize, 0, 255 );
    treeTrakcerSizeSlider:setOnChangeCallback(setTreeTrackerSize)

    local totalSectionsSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, totalSectionsSliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    UILabel.new(totalSectionsSliderSizer, "Number of Map Partitions", TextAlignment.LEFT, -1, -1, labelWidth);
    local totalSectionsSlider = UIIntSlider.new(totalSectionsSliderSizer, totalSections, 0, 255 );
    totalSectionsSlider:setOnChangeCallback(setTotalSections)

    local mapPartitionSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, mapPartitionSliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    UILabel.new(mapPartitionSliderSizer, "Limit to Map Partition", TextAlignment.LEFT, -1, -1, labelWidth);
    local mapPartitionSlider = UIIntSlider.new(mapPartitionSliderSizer, mapPartition, 0, 255 );
    mapPartitionSlider:setOnChangeCallback(setMapPartition)

    local randomAngledTreesChoicePanelSizer = UIColumnLayoutSizer.new()
    local randomAngledTreesChoicePanel      = UIPanel.new(rowSizer, randomAngledTreesChoicePanelSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    local randomAngledTreesChoiceLabel      = UILabel.new(randomAngledTreesChoicePanelSizer, "Randomly Angle Trees:", TextAlignment.LEFT, -1, -1, 240, -1)
    -- load item number 2 from 'boolean' array // which is false
    local randomAngledTreesChoice           = UIChoice.new(randomAngledTreesChoicePanelSizer, boolean, 1, -1, 100, -1)
    randomAngledTreesChoice:setOnChangeCallback(setRandomAngledTrees)

    local partitionMarkersChoicePanelSizer = UIColumnLayoutSizer.new()
    local partitionMarkersChoicePanel      = UIPanel.new(rowSizer, partitionMarkersChoicePanelSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    local partitionMarkersChoiceLabel      = UILabel.new(partitionMarkersChoicePanelSizer, "Enable Partition Markers:", TextAlignment.LEFT, -1, -1, 240, -1)
    -- load item number 2 from 'boolean' array // which is false
    local partitionMarkersChoice           = UIChoice.new(partitionMarkersChoicePanelSizer, boolean, 1, -1, 100, -1)
    partitionMarkersChoice:setOnChangeCallback(setPartitionMarkers)

    UIButton.new(rowSizer, "Start Tree Replication", runTreePlacementStuff)

    myFrame:showWindow()


elseif getNumSelected() > 0 then
    print("Not all selections were detected as compatible trees.\nSelected trees need to have LOD0 as the first child node and "..topLevelTransformName.." as the highest parent.")
else
    print("Please select a tree to replicate.")
end
