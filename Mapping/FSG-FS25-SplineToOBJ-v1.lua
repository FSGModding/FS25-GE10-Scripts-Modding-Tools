-- Author: FSG Modding
-- Name: FSG - Spline to OBJ v1
-- Description: Paints random foliage for texture area that selected transform is located on.
-- Icon:
-- Hide: no
-- Date: 1.6.2025

-- Load editor utils
source("editorUtils.lua");
source("map/farmlandFields/fieldUtil.lua")

-- Build the class
SplineToOBJConverter = {}
SplineToOBJConverter.WINDOW_WIDTH = 300
SplineToOBJConverter.WINDOW_HEIGHT = -1
SplineToOBJConverter.TEXT_WIDTH = 230
SplineToOBJConverter.TEXT_HEIGHT = -1

-- Get things started
function SplineToOBJConverter.new()
    local self = setmetatable({}, {__index=SplineToOBJConverter})

    self.window = nil
    if g_currentSplineToOBJConverterDialog ~= nil then
        g_currentSplineToOBJConverterDialog:close()
    end

    self.objectDistance = 4
    self.objectDistanceSlider = 4
  
    self.mSceneID = getRootNode()
    self.mTerrainID = 0
    for i = 0, getNumOfChildren(self.mSceneID) - 1 do
        local mID = getChildAt(self.mSceneID, i)
        if (getName(mID) == "terrain") then
            self.mTerrainID = mID
            break
        end
    end

    self:generateUI()

    g_currentSplineToOBJConverterDialog = self

    return self

end

-- Generate UI Function
function SplineToOBJConverter:generateUI()
    -- Setup UI
    local frameRowSizer = UIRowLayoutSizer.new()
    self.window = UIWindow.new(frameRowSizer, "Spline to OBJ Converter")

    local borderSizer = UIRowLayoutSizer.new()
    UIPanel.new(frameRowSizer, borderSizer)

    local rowSizer = UIRowLayoutSizer.new()
    UIPanel.new(borderSizer, rowSizer, -1, -1, SplineToOBJConverter.WINDOW_WIDTH, SplineToOBJConverter.WINDOW_HEIGHT, BorderDirection.ALL, 10, 1)

    -- First Layer Set
    local title = UILabel.new(rowSizer, "Spline to OBJ Converter Settings", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    title:setBold(true)
    UIHorizontalLine.new(rowSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)

    local objectDistanceSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, objectDistanceSliderSizer, -1, -1, 200, -1, BorderDirection.BOTTOM, 0)
    UILabel.new(objectDistanceSliderSizer, "Spline Point Separation - Meters", false, TextAlignment.LEFT, VerticalAlignment.TOP, SplineToOBJConverter.TEXT_WIDTH, -1, 200);
    self.objectDistanceSlider = UIIntSlider.new(objectDistanceSliderSizer, self.objectDistance, 0, 255 );
    self.objectDistanceSlider:setOnChangeCallback(function(value) self:setObjectDistance(value) end)

    -- Run Script Button
    local title = UILabel.new(rowSizer, "", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    local title = UILabel.new(rowSizer, "Click Run Script to Start", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    title:setBold(true)
    UIHorizontalLine.new(rowSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)

    UIButton.new(rowSizer, "Run Script", function() self:runSplineToOBJConverter() end, self, -1, -1, -1, -1, BorderDirection.BOTTOM, 2, 1)

    -- layout and show window
    self.window:setOnCloseCallback(function() self:onClose() end)
    self.window:showWindow()

end

function SplineToOBJConverter:close()
    self.window:close()
end

function SplineToOBJConverter:onClose()
    -- Clears out any active functions
end

function SplineToOBJConverter:setObjectDistance(value)
    -- print(value)
    self.objectDistance = value
end

-- Function to convert spline to transforms
function SplineToOBJConverter:convertSpline(spline)
  local lineConfig = "" -- "l"
  local output = string.format("o %s\n", getName(spline))
  -- Get spline length and make sure it is long enough for what we need to do
  local splineLength = getSplineLength(spline);
  if splineLength < 3 then
    print(string.format('Skipped Short Spline: %s | nodeId: %d',getName(spline), spline))
    return nil
  end

  local iObject = 0   -- Number of the object in objectsToPlace
  local numObjectsToPlace = 0

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
  local xLast, yLast, zLast = getSplinePosition(spline, 0);

  local pointCount = 0

  -- Run through the spline and create transform groups to create an outer edge for field creation
  while splinePos <= 1 do

    local placeId = true
    local x, y, z = getSplinePosition(spline, splinePos);	

    y = getTerrainHeightAtWorldPos(self.mTerrainID, x, y, z);
    if y == 0 then -- remove object, probably outside the map - delete object, is probably outside the map -
      placeId = false
    end

    local yyy = 0

    if placeId then -- create point for obj output

      output = string.format("%sv %f %f %f 1.00000\n", output, x, y, z)

      pointCount = pointCount + 1

      if pointCount > 1 then
          lineConfig = string.format("%sl %d %d\n", lineConfig, pointCount - 1, pointCount)
      end

    end -- if placeId

    xLast = x -- update last position
    yLast = y
    zLast = z
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

  return string.format("%s%s", output, lineConfig)

end

function SplineToOBJConverter:checkIsSpline(spline)
  if spline ~= 0 or spline ~= nil then
    if getHasClassId(spline, ClassIds.SPLINE) then
      return true 
    end
    if getHasClassId(spline, ClassIds.SHAPE) and getSplineNumOfCV(spline) > 0 then
      return true
    end
  end
  return false
end

function SplineToOBJConverter:runSplineToOBJConverter()
    print("Run Spline to Field Converter")

    local selectedSpline = getSelection(0)
    if not self:checkIsSpline(selectedSpline) then
        printError("No spline selected.  Please select the spline that you would like to convert to an OBJ file.")
        return
    end

    -- create and load obj file
    local objFilePath = openFileDialog("Choose a name for your new object file in selected folder.", "*.obj")
    local objFileId = createFile(objFilePath, FileAccess.WRITE)
    
    if objFileId ~= nil and objFileId ~= 0 then

        -- Get all groups within selected group
        local splineLength = getSplineLength(selectedSpline);
        -- Run function to convert spline to transform
        if selectedSpline ~= nil and splineLength > 2 then

          print(selectedSpline)
          print(splineLength)

          local outputFileData = self:convertSpline(selectedSpline)

          fileWrite(objFileId, outputFileData)
          delete(objFileId)

          local cleanedUpFilename = string.sub( objFilePath, 1, string.len( objFilePath ) - 1 )
          cleanedUpFilename = string.gsub(cleanedUpFilename, "\\", "/")

          if fileExists(objFilePath) then
              print(string.format("Successfully created OBJ file '%s'", cleanedUpFilename))
          else
              printError(string.format("ERROR: Failed to create OBJ file '%s'!", cleanedUpFilename))
          end

        else
          printError("Error converting spline.  Spline must have more than two points to export.")
        end
    else
      printError("Error creating OBJ file.  Possible write access issue.  Please try again.")
    end
end

-- Start everything up
SplineToOBJConverter.new()