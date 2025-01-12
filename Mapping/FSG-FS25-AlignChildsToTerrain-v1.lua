-- Author: FSG Modding
-- Name: FS25 - Align Childs to Terrain v2
-- Description: Select a transform and this will go through all of the transforms within that transform and set them to the terrain height it not already.
-- Icon:
-- Hide: no
-- Date: 1-11-25

local transformCount = 0
local totalCount = 0

print("Processing, this may take a while...")

local mSceneID = getRootNode()
local mTerrainID = 0
for i = 0, getNumOfChildren(mSceneID) - 1 do
    local mID = getChildAt(mSceneID, i)
    if (getName(mID) == "terrain") then
        mTerrainID = mID
        break
    end
end

if (getNumSelected() == 0) then
    printError("Error: Select one or more splines.")
    return false
end

local selectedTransform = getSelection(0)

local function floatFix(parentTransformNodeId)
    if parentTransformNodeId ~= nil then
        local numOfChildren = getNumOfChildren(parentTransformNodeId)
        for p=0,numOfChildren-1 do
            local childNodeId = getChildAt(parentTransformNodeId,p)
            local numOfChildrenCheck = getNumOfChildren(childNodeId)
            if(numOfChildrenCheck > 0) then
                local childCheckId = getChildAt(childNodeId,0)
                if getName(childCheckId) == "LOD0" then
                    local x,y,z = getTranslation(childNodeId)
                    local rx,ry,rz = getRotation(childNodeId)
                    local terrainHeight = getTerrainHeightAtWorldPos(mTerrainID, x, y, z)
                    local increaseHeightForRotation = 0
                    rx = math.deg(rx)
                    ry = math.deg(ry)
                    rz = math.deg(rz)
                    if y ~= terrainHeight then
                        setTranslation(childNodeId, x, terrainHeight, z)
                        transformCount = transformCount+1
                    end
                    totalCount = totalCount+1
                else
                    floatFix(childNodeId);
                end
            else
                floatFix(childNodeId);
            end
        end
    end
end

floatFix(selectedTransform)

print("Fixed Transform Count:" .. transformCount)
print("Total Transform Count:" .. totalCount)
