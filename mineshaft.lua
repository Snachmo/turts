


position = { x = 0, y = 0, z = 0 }
-- Directions: 0 = north, 1 = east, 2 = south, 3 = west, 4 = up, -1 = down
direction = 0

function turnRight()
  turtle.turnRight()
  direction = (direction + 1) % 4
end

-- turnTo: Rotates the turtle to face an absolute direction (0 = north, etc.).
function turnTo(newDirection)
  if newDirection > -1 and newDirection < 4 then
    local diff = (newDirection - direction) % 4
    if diff == 3 then
      turtle.turnLeft()
      direction = (direction - 1) % 4
    elseif diff == 2 then
      turnRight(); turnRight()
    elseif diff == 1 then
      turnRight()
    end
  end
end

HAZARD_BLOCKS = {
  ["minecraft:water"] = true,
  ["minecraft:flowing_water"] = true,
  ["minecraft:lava"] = true,
  ["minecraft:flowing_lava"] = true,
  ["minecraft:fire"] = true,
  ["minecraft:soul_fire"] = true,
  ["minecraft:campfire"] = true,
  ["minecraft:lit_campfire"] = true,
  ["minecraft:magma_block"] = true,
  ["minecraft:tnt"] = true,
}

function isHazard(block_name)
  if HAZARD_BLOCKS[block_name] then
    print("HAZARD: " .. block_name .. " detected.")
    return true
  end
  return false
end

INDESTRUCTIBLE_BLOCKS = {
    ["minecraft:bedrock"] = true,
    ["minecraft:chest"] = true,
    ["minecraft:ancient_debris"] = true,
    ["minecraft:nether_portal"] = true,
    ["minecraft:ender_portal"] = true,
    ["minecraft:respawn_anchor"] = true,
  }

function isIndestructible(block_name)
  if INDESTRUCTIBLE_BLOCKS[block_name] then
    print("INDESTRUCTIBLE: " .. block_name .. " detected.")
    return true
  end
  return false
end

ABUNDANT_BLOCKS = {
  ["minecraft:dirt"] = true,
  ["minecraft:grass_block"] = true,
  ["minecraft:stone"] = true,
  ["minecraft:deepslate"] = true,
  ["minecraft:granite"] = true,
  -- Add additional block types as desired.
}

function isAbundant(block_name)
  return ABUNDANT_BLOCKS[block_name]
end

function getBlock(detectFunc, inspectFunc)
  if not detectFunc() then
    print("getBlock.detectFunc returned false")
    return nil
  end
  local success, data = inspectFunc()
  if success then
    if data == nil then
      print("getBlock.inspectFunc() successfully returned a nil block")
      return nil
    end
    local block_name = data.name
    return {
      success = true,
      error = nil,
      name = block_name,
      hazard = isHazard(block_name),
      indestructible = isIndestructible(block_name),
      abundant = isAbundant(block_name),
    }
  else
    print("CRITICAL: getBlock.inspectFunct() retured error " .. data)
    return {
      success = false,
      error = data
    }
  end
end

function _safeDig(detectFunc, inspectFunc, digFunc, digAbundant)
  local block = getBlock(detectFunc, inspectFunc)
  print(block)
  if block == nil then
    return nil
  elseif block.abundant and digAbundant == false then
    print("Not digging abundant block " .. block.name)
    return false
  elseif block.indestructible then
    print("Not diggin indestructible block " .. block.name)
    return false
  elseif not digFunc() then
    print("CRITICAL: safeDig.digFunc() returned false.")
    return false
  end
  return true
end

function safeDig(digDirection, digAbundant)
  print("Attempting safeDig " .. digDirection)
  if digDirection == 0 then
    return _safeDig(turtle.detect, turtle.inspect, turtle.dig, digAbundant)
  elseif digDirection == -1 then
    return _safeDig(turtle.detectDown, turtle.inspectDown, turtle.digDown, digAbundant)
  elseif digDirection == 4 then
    return _safeDig(turtle.digUp, turtle.inspectUp, turtle.digUp, digAbundant)
  else
    print("CRITICAL: Bad safeDig.digDirection " .. digDirection)
    return false
  end
end

function _safeMove(digDirection, moveFunc)
  while not moveFunc() do
    print("_safeMove.moveFunc() returned false")
    if not safeDig(digDirection, true) then
      print("Failed to safeMove.")
      return false
    end
  end
  return true
end

function safeMove(moveDirection)
  print("Attempting safeMove " .. moveDirection)
  if moveDirection > -1 and moveDirection < 4 then
    turnTo(moveDirection)
    return _safeMove(0, turtle.forward)
  elseif moveDirection == -1 then
    return _safeMove(moveDirection, turtle.down)
  elseif moveDirection == 4 then
    return _safeMove(moveDirection, turtle.up)
  else
    print("CRITICAL: Bad safeMove.moveDirection " .. moveDirection)
    return false
  end
end
  
function moveTo(targetX, targetY, targetZ)
  -- Vertical down move (minus Y axis).
  while position.y > targetY do
    if not safeMove(-1, true) then
      return false
    end
    position.y = position.y - 1
  end
  -- Move North (minus Z axis)
  while position.z > targetZ do
    if not safeMove(0, true) then
      return false
    end
    position.z = position.z - 1
  end
  -- Move South (plus Z axis)
  while position.z < targetZ do
    if not safeMove(2, true) then
      return false
    end
    position.z = position.z + 1
  end
  -- Move East (plus X axis)
  while position.x < targetX do
    if not safeMove(1, true) then
      return false
    end
    position.x = position.x + 1
  end
  -- Move West (minus X axis)
  while position.x > targetX do
    if not safeMove(3, true) then
      return false
    end
    position.x = position.x - 1
  end
  -- Vertical Up move (plus Y axis).
  while position.y < targetY do
    if not safeMove(4, true) then
      return false
    end
    position.y = position.y + 1
  end
  return true
end

function mineShaft(minY)
  while minY < position.y do
    print("Digging down.")
    if not moveTo(position.x, position.y-1, position.z) then
      print("Failed to dig down, going home.")
      moveTo(position.x, 0, position.z)
      return false
    end
    print('Digging direction 0')
    safeDig(0, false)
    for turns = 1, 3 do
      print('Digging direction ' .. turns)
      turnRight()
      safeDig(0, false)
    end
  end
  print("Going home.")
  moveTo(position.x, 0, position.z)
end

mineShaft(-40)
