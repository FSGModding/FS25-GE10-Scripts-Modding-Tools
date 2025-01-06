-- Author: FSG Modding
-- Name: FSG - Spline to Field Converter v5
-- Description: Paints random foliage for texture area that selected transform is located on.
-- Icon:
-- Hide: no
-- Date: 1.5.2025

-- Load editor utils
source("editorUtils.lua");
source("map/farmlandFields/fieldUtil.lua")

-- Build the class
SplineToFieldConverter = {}
SplineToFieldConverter.WINDOW_WIDTH = 300
SplineToFieldConverter.WINDOW_HEIGHT = -1
SplineToFieldConverter.TEXT_WIDTH = 230
SplineToFieldConverter.TEXT_HEIGHT = -1

-- Get things started
function SplineToFieldConverter.new()
    local self = setmetatable({}, {__index=SplineToFieldConverter})

    self.window = nil
    if g_currentSplineToFieldConverterDialog ~= nil then
        g_currentSplineToFieldConverterDialog:close()
    end

    self.objectDistance = 4
    self.objectDistanceSlider = 4
  
    self.textureLayers = {}
    self.textureLayerNames = {}
    self.textureLayers_Choice = 1
    
    self.enableTexturePaint = {"Disabled", "Enabled"}
    self.enableTexturePaint_Choice = 1

    self.paintWidth1 = 0
    self.paintWidth1Slider = 0
    self.paintWidth2 = 0
    self.paintWidth2Slider = 0

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

    g_currentSplineToFieldConverterDialog = self

    return self

end

-- Generate UI Function
function SplineToFieldConverter:generateUI()
    -- Setup UI
    local frameRowSizer = UIRowLayoutSizer.new()
    self.window = UIWindow.new(frameRowSizer, "Spline to Field Converter")

    local borderSizer = UIRowLayoutSizer.new()
    UIPanel.new(frameRowSizer, borderSizer)

    local rowSizer = UIRowLayoutSizer.new()
    UIPanel.new(borderSizer, rowSizer, -1, -1, SplineToFieldConverter.WINDOW_WIDTH, SplineToFieldConverter.WINDOW_HEIGHT, BorderDirection.ALL, 10, 1)

    -- First Layer Set
    local title = UILabel.new(rowSizer, "Spline to Field Converter Settings", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    title:setBold(true)
    UIHorizontalLine.new(rowSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)

    local objectDistanceSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, objectDistanceSliderSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    UILabel.new(objectDistanceSliderSizer, "Spline Point Separation - Meters", false, TextAlignment.LEFT, VerticalAlignment.TOP, SplineToFieldConverter.TEXT_WIDTH, -1, 200);
    self.objectDistanceSlider = UIIntSlider.new(objectDistanceSliderSizer, self.objectDistance, 0, 255 );
    self.objectDistanceSlider:setOnChangeCallback(function(value) self:setObjectDistance(value) end)

    local folLayerPanelSizer = UIGridSizer.new(1, 2, 2, 2)
    local folLayerPanel = UIPanel.new(rowSizer, folLayerPanelSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    local folLayerLabel = UILabel.new(folLayerPanelSizer, "Enable Field Texture Paint", false, TextAlignment.LEFT, VerticalAlignment.TOP, SplineToFieldConverter.TEXT_WIDTH, -1)
    self.enableTexturePaint_Choice = UIChoice.new(folLayerPanelSizer, self.enableTexturePaint, 0, -1, 100, -1)
    self.enableTexturePaint_Choice:setOnChangeCallback(function(value) self:setEnableTexturePaint(value) end)

    local folLayerPanelSizer = UIGridSizer.new(1, 2, 2, 2)
    local folLayerPanel = UIPanel.new(rowSizer, folLayerPanelSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    local folLayerLabel = UILabel.new(folLayerPanelSizer, "Field Texture Paint", false, TextAlignment.LEFT, VerticalAlignment.TOP, SplineToFieldConverter.TEXT_WIDTH, -1)
    self.textureLayers_Choice = UIChoice.new(folLayerPanelSizer, self.textureLayers, 0, -1, 100, -1)
    self.textureLayers_Choice:setOnChangeCallback(function(value) self:setTextureLayer(value) end)

    local objectDistanceSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, objectDistanceSliderSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    UILabel.new(objectDistanceSliderSizer, "Paint Width 1 - Meters", false, TextAlignment.LEFT, VerticalAlignment.TOP, SplineToFieldConverter.TEXT_WIDTH, -1, 200);
    self.paintWidth1Slider = UIIntSlider.new(objectDistanceSliderSizer, self.paintWidth1, 0, 255 );
    self.paintWidth1Slider:setOnChangeCallback(function(value) self:setPaintWidth1(value) end)

    local objectDistanceSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, objectDistanceSliderSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    UILabel.new(objectDistanceSliderSizer, "Paint Width 2 - Meters", false, TextAlignment.LEFT, VerticalAlignment.TOP, SplineToFieldConverter.TEXT_WIDTH, -1, 200);
    self.paintWidth2Slider = UIIntSlider.new(objectDistanceSliderSizer, self.paintWidth2, 0, 255 );
    self.paintWidth2Slider:setOnChangeCallback(function(value) self:setPaintWidth2(value) end)

    -- Run Script Button
    local title = UILabel.new(rowSizer, "", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    local title = UILabel.new(rowSizer, "Click Run Script to Start", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    title:setBold(true)
    UIHorizontalLine.new(rowSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)

    UIButton.new(rowSizer, "Run Script", function() self:runSplineToFieldConverter() end, self, -1, -1, -1, -1, BorderDirection.BOTTOM, 2, 1)

    -- layout and show window
    self.window:setOnCloseCallback(function() self:onClose() end)
    self.window:showWindow()

end

function SplineToFieldConverter:close()
    self.window:close()
end

function SplineToFieldConverter:onClose()
    -- Clears out any active functions
end

function SplineToFieldConverter:getTextureLayers()
    print("Get Texture Layers")

    local numLayers = getTerrainNumOfLayers(self.mTerrainID)
    local addedLayer = numLayers +1
    for i = 0,addedLayer do
        self.textureLayers[i] = getTerrainLayerName(self.mTerrainID, i-1)
        self.textureLayerNames[i] = getTerrainLayerName(self.mTerrainID, i)
    end
end

function SplineToFieldConverter:setTextureLayer(value)
    if self.textureLayerNames[value - 1] ~= nil and self.textureLayerNames[value - 1] ~= "" then
      print(string.format("Selected Field Texture Paint: %s", self.textureLayerNames[value - 1]))
      self.textureLayers_Choice = value
      -- print(self.textureLayers_Choice)
      -- print(self.textureLayerNames[value - 1])
    else
      printError("Selected Field Texture Paint is Not Valid!  Please select a different texture.")
    end
end

function SplineToFieldConverter:setEnableTexturePaint(value)
    if value ~= nil and value == 2 then
        print("Field Texture Paint Enabled")
        self.enableTexturePaint_Choice = 2
    else
        print("Field Texture Paint Disabled")
        self.enableTexturePaint_Choice = 1
    end
end

function SplineToFieldConverter:setObjectDistance(value)
    -- print(value)
    self.objectDistance = value
end

function SplineToFieldConverter:setPaintWidth1(value)
    print(value)
    self.paintWidth1 = value
end

function SplineToFieldConverter:setPaintWidth2(value)
    print(value)
    self.paintWidth2 = value
end

function SplineToFieldConverter:crossProduct(ax, ay, az, bx, by, bz)	
    return ay*bz - az*by, az*bx - ax*bz, ax*by - ay*bx;
end

-- Function that paints field dirt within spline area
function SplineToFieldConverter:runPaintFieldDirt(mSplineID)

  print('Start of dirt paint thingy')

    if self.textureLayers_Choice == nil then 
      self.textureLayers_Choice = 118
    end

    local terrainSize = getTerrainSize(self.mTerrainID)
    print('terrainSize : ' .. terrainSize)

    local mSplineLength = getSplineLength( mSplineID ) 
    local mSplinePiece = 0.5 -- real size 0.5 meter
    local mSplinePiecePoint = mSplinePiece / mSplineLength  -- relative size [0..1]

    local mSplinePos = 0.0
    while mSplinePos <= 1.0 do
        -- get XYZ at position on spline
        local mPosX, mPosY, mPosZ = getSplinePosition( mSplineID, mSplinePos )
        -- directional vector at the point
        local mDirX, mDirY,   mDirZ   = getSplineDirection ( mSplineID, mSplinePos)
        local mVecDx, mVecDy, mVecDz = EditorUtils.crossProduct( mDirX, mDirY, mDirZ, 0, 1, 0)
        -- paint at the center
        setTerrainLayerAtWorldPos(self.mTerrainID, self.textureLayers_Choice - 1, mPosX, mPosY, mPosZ, 128.0 )
        -- define side to side shift in meters
        for i = 1, self.paintWidth1, 1 do
            local mNewPosX1 = mPosX + i * mVecDx
            local mNewPosZ1 = mPosZ + i * mVecDz
            -- paint at the center
            setTerrainLayerAtWorldPos(self.mTerrainID, self.textureLayers_Choice - 1, mNewPosX1, mPosY, mNewPosZ1, 128.0 )
        end
        -- define side to side shift in meters
        for i = 1, self.paintWidth2, 1 do
            local mNewPosX2 = mPosX  - i * mVecDx
            local mNewPosZ2 = mPosZ  - i * mVecDz
            -- paint at the center
            setTerrainLayerAtWorldPos(self.mTerrainID, self.textureLayers_Choice - 1, mNewPosX2, mPosY, mNewPosZ2, 128.0 )
        end
        -- goto next point
        mSplinePos = mSplinePos + mSplinePiecePoint
    end
end

-- Function to convert spline to transforms
function SplineToFieldConverter:convertSpline(selectedGroup,spline,newGroup)
  --print(string.format('Spline id: %d',spline))
  -- Get spline lengeth and make sure it is long enough for what we need to do
  local splineLength = getSplineLength(spline);
  --print(string.format('Spline Length: %s',splineLength))
  if splineLength < 3 then
    print(string.format('Skipped Short Spline: %s | nodeId: %d',getName(spline), spline))
    return nil
  end
  -- Set translations
  local xParent, yParent, zParent = getWorldTranslation(selectedGroup)

  local iObject = 0   -- Number of the object in objectsToPlace
  local numObjectsToPlace = 0

  local pointNum = 1

  -- Set start of spline position
  local splinePos = 0
  if splinePos < 0 then 
    splinePos = 0 
  end
  if splinePos > 1 then 
    print("Error: splinePos > 1 at start!")
    return 
  end

  -- Position of last location in spline
  local xlast, ylast, zlast = getSplinePosition(spline, 0);

  -- Initialize variables for center calculation
  local totalX, totalY, totalZ = 0, 0, 0
  local pointCount = 0

  -- Run through the spline and create transform groups to create an outer edge for field creation
  while splinePos <= 1 do

    local placeId = true
    local x, y, z = getSplinePosition(spline, splinePos);	

    if startX == 0 then
      startX = x
    end

    y = getTerrainHeightAtWorldPos(self.mTerrainID, x, y, z);
    if y == 0 then -- remove object, probably outside the map - delete object, is probably outside the map -
      placeId = false
    end
      
    local rx, ry, rz = getSplineOrientation(spline, splinePos, 0, -1, 0);  

    local yyy = 0

    if placeId then -- place object 
      local newPoint = createTransformGroup("point" .. pointNum)
      pointNum = pointNum + 1
      link(newGroup,newPoint)
      local mDirX, mDirY,   mDirZ = worldDirectionToLocal( spline, getSplineDirection (spline, splinePos) );
      local mVecDx, mVecDy, mVecDz = self:crossProduct( mDirX, mDirY, mDirZ, 0, 1, 0);

      setTranslation(newPoint, x-xParent, getTerrainHeightAtWorldPos(self.mTerrainID, x-xParent, 0, z-zParent), z-zParent);		
      
      setRotation(newPoint, rx, ry, rz);
      yyy =  y-ylast	
        
      -- Calculate center
      totalX = totalX + x
      totalY = totalY + y
      totalZ = totalZ + z

      pointCount = pointCount + 1

    end -- if placeId

    xlast = x -- update last position
    ylast = y
    zlast = z
    yyy = self.objectDistance/splineLength
    
    if useDistanceTable then 
      yyy = distanceTable[iObject+1]/splineLength -- Increase splinePos by 1 unit
      
      if iObject >= numObjectsToPlace then 
        iObject = 0
      end
    end
    splinePos = splinePos + yyy -- Increase splinePos by 1 unit
    if splinePos < 0 then -- can be made negative by randomObjectDistance
      splinePos = 0 
    end
    
    iObject = iObject + 1 -- take next object
    if iObject >= numObjectsToPlace then 
      iObject = 0
    end

  end -- while

  -- Calculate the center coordinates
  local centerX = totalX / pointCount
  local centerZ = totalZ / pointCount

  return newGroup, centerX, centerZ;

end

function SplineToFieldConverter:getFieldSize(fieldNode)
    local indexPath = getUserAttribute(fieldNode, "polygonIndex")
    local polygonPoints = EditorUtils.getNodeByIndexPath(indexPath, fieldNode)
    if polygonPoints ~= nil and getNumOfChildren(polygonPoints) >= 3 then
        local size = 0

        local lastPoint = getChildAt(polygonPoints, getNumOfChildren(polygonPoints)-1)
        for i=0, getNumOfChildren(polygonPoints)-1 do
            local point = getChildAt(polygonPoints, i)
            local x1, _, z1 = getWorldTranslation(point)
            local x2, _, z2 = getWorldTranslation(lastPoint)

            local averageHeight = (z1 + z2) * 0.5
            local width = x2 - x1
            local edgeSize = width * averageHeight

            size = size + edgeSize

            lastPoint = point
        end

        return math.abs(size) / 10000
    end

    return 0
end

function SplineToFieldConverter:updateFieldNote(field)
    local indicatorPath = getUserAttribute(field, "nameIndicatorIndex")
    local indicator = EditorUtils.getNodeByIndexPath(indicatorPath, field)
    if indicator ~= nil and getNumOfChildren(indicator) == 1 then
        local fieldSize = self:getFieldSize(field)
        local fieldName = getName(field)
        local noteName = string.format("%s\n%.2f ha", fieldName, fieldSize)

        local note = getChildAt(indicator, 0)
        local oldNote = getNoteNodeText(note)
        if oldNote ~= noteName then
            setNoteNodeText(note, noteName)

            oldNote = string.gsub(oldNote, "\n", " ")
            noteName = string.gsub(noteName, "\n", " ")
            print(string.format("    Adjusted field note name from '%s' to '%s'", oldNote, noteName))
        end
    end
end

function SplineToFieldConverter:runSplineToFieldConverter()
    print("Run Spline to Field Converter")
    if type(self.enableTexturePaint_Choice) ~= "number" then
      self.enableTexturePaint_Choice = 1
    end
    if type(self.textureLayers_Choice) ~= "number" then
      self.textureLayers_Choice = 1
    end

    -- Debug stuffs
    -- print("objectDistance: ",self.objectDistance)
    -- print("enableTexturePaint_Choice: ",self.enableTexturePaint_Choice)
    -- print("textureLayers_Choice: ",self.textureLayers_Choice)
    -- print("paintWidth1: ",self.paintWidth1)
    -- print("paintWidth2: ",self.paintWidth2)

    -- Get fields group and see if it is empty, if empty add to it, if not then request user to empty it
    local fields = FieldUtil.getFieldsRootNode()
    if fields == nil then
        print("Error: No fields root node found!")
        return
    end

    -- Check if fields exist, if not create them and let user know to add attributes 
    if fields == nil or fields == 0 then
      -- Get the gameplay transform group
      local gamePlayID = 0
      for i = 0, getNumOfChildren(self.mSceneID) - 1 do
          local mID = getChildAt(self.mSceneID, i)
          if (getName(mID) == "gameplay") then
              gamePlayID = mID
              break
          end
      end

      if (gamePlayID == 0) then
          printError("Error: GamePlay node not found. Node needs to be named 'gameplay'.")
          return nil
      end
      -- Fields Group is missing, create one
      fields = createTransformGroup("fields")
      -- setUserAttribute(fields, "onCreate", "scriptCallback", "FieldUtil.onCreate");
      link(gamePlayID, fields)
      print('Info: fields transform has been added to the gameplay transport group.')
      print('Please add user attribute type "script callback" with name "onCreate" to the fields transform.')
      print('Once the script callback is added, add "FieldUtil.onCreate" to the onCreate field.')
      return
    end
    -- Check if fields group has on create attribute
    if getUserAttribute(fields, "onCreate") ~= "FieldUtil.onCreate" then
      print('Error: fields transform is missing a required user attribute to continue.')
      print('Please add user attribute type "script callback" with name "onCreate" to the fields transform.')
      print('Once the script callback is added, add "FieldUtil.onCreate" to the onCreate field.')
      return
    end

    local selectedGroup = getSelection(0)
    if selectedGroup == 0 or selectedGroup == nil then
        printError("No transform selected.  Please select the transform that contains the splines you want to convert to fields.")
        return
    end
    -- Get splines in selected transform group
    local numOfChildren = getNumOfChildren(selectedGroup)
    print('Number of items in selected transform: ' .. numOfChildren)
    -- Start creating fields data
    local fieldNum = 0;
    -- loop though all children and check if they are splines
    for g=0, getNumOfChildren(selectedGroup)-1 do
      -- Get all groups within selected group
      local spline = getChildAt(selectedGroup, g)
      local splineLength = getSplineLength(spline);
      -- Run function to convert spline to transform
      if spline ~= nil and splineLength > 2 then
        -- Create transform for field data
        fieldNum = fieldNum + 1
        -- Add new field to the fields tab
        print(string.format("Processing field: %d", fieldNum))
        -- Create new field transform
        local fieldNode = FieldUtil.getFieldsRootNode()
        if fieldNode == nil then
            printError("No fields node defined")
            return nil
        end
        local fieldName = string.format("field%01d", getNumOfChildren(fieldNode)+1)
        local field = createTransformGroup(fieldName)
        local polygonPoints = createTransformGroup("polygonPoints")

        local fieldSpline, centerX, centerZ = self:convertSpline(selectedGroup,spline,polygonPoints)

        local nameIndicator = createTransformGroup("nameIndicator")
        local teleportIndicator = createTransformGroup("teleportIndicator")

        local note = createNoteNode(nameIndicator, fieldName, 0, 0, 0, true)
        link(nameIndicator, note)
        setTranslation(note, 0, 0, 0)

        link(field, polygonPoints)
        link(field, nameIndicator)
        link(field, teleportIndicator)

        link(fieldNode, field)

        setTranslation(nameIndicator, centerX, getTerrainHeightAtWorldPos(self.mTerrainID, centerX, 0, centerZ), centerZ)
        setTranslation(teleportIndicator, centerX, getTerrainHeightAtWorldPos(self.mTerrainID, centerX, 0, centerZ), centerZ)

        setUserAttribute(field, "polygonIndex", UserAttributeType.STRING, EditorUtils.getNodeIndexPath(field, polygonPoints))
        setUserAttribute(field, "nameIndicatorIndex", UserAttributeType.STRING, EditorUtils.getNodeIndexPath(field, nameIndicator))
        setUserAttribute(field, "teleportIndicatorIndex", UserAttributeType.STRING, EditorUtils.getNodeIndexPath(field, teleportIndicator))
        setUserAttribute(field, "angle", UserAttributeType.INTEGER, 0)
        setUserAttribute(field, "missionOnlyGrass", UserAttributeType.BOOLEAN, false)
        setUserAttribute(field, "missionAllowed", UserAttributeType.BOOLEAN, true)

        if fieldSpline ~= nil and centerX ~= nil and centerZ ~= nil then
          -- Check if user wants to paint dirt or not and change from 1,2 to true,false
          if self.enableTexturePaint_Choice == 2 then
            -- Run the paint dirt within spline function
            self:runPaintFieldDirt(spline)
          end

          -- print('====')
          -- print('Field Spline Data')
          -- print(fieldSpline)
          -- print(centerX)
          -- print(centerZ)
          -- print('====')

          -- Get the number of fields to create
          local numberOfShapes = getNumOfChildren(fieldSpline)

          -- Make sure we have fields to work with
          if numberOfShapes == nil or numberOfShapes == 0 then
            printWarning(string.format('Info: No fields were able to be created for field spline: %s - Skipping',fieldSpline))
            return
          end

        end

        addSelection(field)
        self:updateFieldNote(field)
        print(string.format("Created new field '%s'", fieldName))

      end
    end

end

-- Start everything up
SplineToFieldConverter.new()