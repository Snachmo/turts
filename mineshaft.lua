ABUNDANT_BLOCKS = {
  ["minecraft:dirt"] = true,
  ["minecraft:grass_block"] = true,
  ["minecraft:stone"] = true,
  ["minecraft:deepslate"] = true,
  ["minecraft:granite"] = true,
}

INDESTRUCTIBLE_BLOCKS = {
  ["minecraft:bedrock"] = true,
  ["minecraft:chest"] = true,
  ["minecraft:ancient_debris"] = true,
  ["minecraft:nether_portal"] = true,
  ["minecraft:ender_portal"] = true,
  ["minecraft:respawn_anchor"] = true,
}

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

function isHazard(block)
  if block == nil then
    return false
  end
  return HAZARD_BLOCKS[block]
end

function isDiggable(block, digAbundant)
  if block != nil then
    return not INDESTRUCTIBLE_BLOCKS[block] and not (ABUNDANT_BLOCKS[block] and digAbundant)
  end
  return false
end

function _getBlock(detectFunc, inspectFunc)
  if not detectFunc() then
    print("getBlock found no block")
    return nil
  end
  local success, data = inspectFunc()
  if success then
    if data == nil then
      print("getBlock.inspectFunc() successfully returned a nil block")
      return nil
    end
    return data.name
  else
    print("CRITICAL: getBlock.inspectFunct() retured error " .. data)
    return false
  end
end

-- Adjacent blocks
front = nil
up = nil
down = nil

function getFront()
  front = _getBlock(turtle.detect, turtle.inspect)
  return front
end

function getUp()
  up = _getBlock(turtle.detectUp, turtle.inspectUp)
  return up
end

function getDown()
  down = _getBlock(turtle.detectDown, turtle.inspectDown)
  return down
end

function inDanger()
  getFront()
  getUp()
  getDown()
  return isHazard(front) or isHazard(up) or isHazard(down)
end

function _dig(block, digFunc, digAbundant)
  if block != nil and not INDESTRUCTIBLE_BLOCKS[block] and not (ABUNDANT_BLOCKS[block] and digAbundant) then
    return digFunc()
  end
  return false
end

function digFront(digAbundant)
  return _dig(getFront(), turtle.dig, digAbundant)
end

function digUp(digAbundant)
  return _dig(getUp(), turtle.digUp, digAbundant)
end

function digDown(digAbundant)
  return _dig(getDown(), turtle.digDown, digAbundant)
end

-- Position (coordinates relative to starting position).
position = { x = 0, y = 0, z = 0 }

-- Directions: 0 = north, 1 = east, 2 = south, 3 = west, 4 = up, -1 = down
direction = 0

-- Turn: -1 = left, 1 = right
function turn(turnDirection)
  if turnDirection == 1
    turtle.turnRight()
  elseif turnDirection == -1
    turtle.turnLeft()
  else
    return false
  end
  direction = (direction + turnDirection) % 4
  getFront()
end

function _move(moveFunc)
  if moveFunc() then
    if moveFunc == turtle.forward then
      if direction == 0 then
        position.z = position.z - 1
      elseif direction == 1 then
        position.x = position.x + 1
      elseif direction == 2 then
        position.z = position.z + 1
      elseif direction == 3 then
        position.x = position.x - 1
      end
    elseif moveFunc == turtle.up then
      position.y = position.y + 1
    elseif moveFunc == turtle.down then
      position.y = position.y - 1
    else
      return false
    end
    getFront()
    getUp()
    getDown()
    return true
  end
  return false
end

function move()
  return _move(turtle.forward)
end

function moveUp()
  return _move(turtle.up)
end

function moveDown()
  return _move(turtle.down)
end

function refuel()
  print("Attempting to refuel from inventory.")
  for slot = 1, 16 do
    turtle.select(slot)
    if turtle.refuel(0) then
      print("Refueling from slot " .. slot)
      turtle.refuel(1)
      print("New fuel level " .. turtle.getFuelLevel())
      return true
    end
  end
  print("No fuel in inventory.")
  return false
end

fuel_buffer = 300
function hasFuel()
  local min_fuel = fuel_buffer + math.abs(position.x) + math.abs(position.y) + math.abs(position.z)
  while turtle.getFuelLevel() <= min_fuel_level then
    print("Low fuel. " .. fuel_level .. " remaining of " .. min_fuel_level .. " minimum.")
    if not refuel() then
      return false
    end
  end
  return true
end

function safeMove(moveFunc, digFunc)
  while hasFuel() and not inDanger() and not moveFunc() do
      if not digFunc(true) then
        return false
      end
    end
  end
  return false
end

function mineShaft(maxDepth)
  print("Starting fuel " .. turtle.getFuelLevel())

  while position.y > maxDepth do
    print("Digging down.")
    if not safeMove(moveDown, digDown) then
      return false
    end
    digFront(false)
    if inDanger() then
      return false
    end
    for turn in 0, 2 do
      turnLeft()
      if inDanger() then
        return false
      end
      digFront(false)
      if inDanger() then
        return false
      end
    end
  end
end

function goHome()
  print ("Going home.")
  while position.y < 0 do
    if not moveUp() then
      digUp(true)
    end
  end
end

mineShaft(-10)
goHome()