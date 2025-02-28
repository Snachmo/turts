function inventoryFull()
  for slot = 1, 16 do
    if turtle.getItemCount(slot) == 0 then
      return false
    end
  end
  return true
end

function dropInventory()
  print("Dropping inventory to front...")
  for slot = 1, 16 do
    turtle.select(slot)
    if turtle.getItemCount() > 0 and not turtle.refuel(0) then
        while not turtle.drop() do
          print("Faild to drop item in slot " .. slot)
        end
      end
  end
  print('Dropped all non-fuel inventory.')
  return true
end

function plugShaft()
  while true do
    for slot = 1, 16 do
      turtle.select(slot)
      if turtle.getItemCount() > 0 then
        item = turtle.getItemDetail()
        if item then
          if item.name == "minecraft:obsidian" or item.name == "minecraft:cobblestone" then
            turtle.placeDown()
            return true
          end
        end
      end
    end
    print("Failed to plug shaft!")
  end
end

ABUNDANT_BLOCKS = {
  ["minecraft:dirt"] = true,
  ["minecraft:grass_block"] = true,
  ["minecraft:gravel"] = true,
  ["minecraft:stone"] = true,
  ["minecraft:deepslate"] = true,
  ["minecraft:granite"] = true,
  ["minecraft:diorite"] = true,
  ["minecraft:andesite"] = true,
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
  ["minecraft:tnt"] = true,
}

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
    return {
      name = data.name,
      hazard = HAZARD_BLOCKS[data.name],
      abundant = ABUNDANT_BLOCKS[data.name],
      indestructible = INDESTRUCTIBLE_BLOCKS[data.name]
    }
  else
    print("CRITICAL: getBlock.inspectFunct() retured error " .. data)
    return false
  end
end

function getFront()
  return _getBlock(turtle.detect, turtle.inspect)
end

function getUp()
  return _getBlock(turtle.detectUp, turtle.inspectUp)
end

function getDown()
  return _getBlock(turtle.detectDown, turtle.inspectDown)
end

function isHazard(block)
  return block ~= nil and (block == false or block.hazard)
end

function inDanger()
  local block = getFront()
  if isHazard(block) then
    print("Hazard in front: " .. front.name)
    return true
  end
  block = getUp()
  if isHazard(block) then
    print("Hazard above: " .. up.name)
    return true
  end
  block = getDown()
  if isHazard(block) then
    print("Hazard below: " .. down.name)
    return true
  end
  return false
end

function _dig(blockFunc, digFunc, digAbundant)
  local block = blockFunc()
  if block == nil then
    print("_dig found no block, digging anyway.")
    return digFunc()
  elseif block == false then
    print("_dig failed on blockFunc error.")
  elseif  inventoryFull() then 
    print("_dig failed, inventory full.")
  elseif block.indestructible then
    print("_dig failed, indestructible " .. block.name)
  elseif block.abundant and not digAbundant then
    print("_dig failed, abundant " .. block.name)
  else
    print("digging.")
    return digFunc()
  end
  return false
end

function digFront(digAbundant)
  return _dig(getFront, turtle.dig, digAbundant)
end

function digUp(digAbundant)
  return _dig(getUp, turtle.digUp, digAbundant)
end

function digDown(digAbundant)
  return _dig(getDown, turtle.digDown, digAbundant)
end

-- Direction: 0 = north, 1 = east, 2 = south, 3 = west, 4 = up, -1 = down
direction = 0

-- Turn: -1 = left, 1 = right
function turn(turnDirection)
  print("turning " .. turnDirection)
  if turnDirection == 1 then
    turtle.turnRight()
  elseif turnDirection == -1 then
    turtle.turnLeft()
  else
    return false
  end
  direction = (direction + turnDirection) % 4
end

function turnTo(newDirection)
  local diff = (newDirection - direction) % 4
  if diff == 3 then
    turn(-1)
  elseif diff == 2 then
    turn(1); turn(1)
  elseif diff == 1 then
    turn(1)
  end
end

-- Position (coordinates relative to starting position).
position = { x = 0, y = 0, z = 0 }

function positionStr()
  return "(" .. position.x .. "," .. position.y .. "," .. position.z .. ")"
end

function moveForward()
  if turtle.forward() then
    if direction == 0 then
      position.z = position.z - 1
    elseif direction == 1 then
      position.x = position.x + 1
    elseif direction == 2 then
      position.z = position.z + 1
    elseif direction == 3 then
      position.x = position.x - 1
    end
    -- print("Moved forward " .. positionStr())
    return true
  end
  print("turtle.forward() returned false.")
  return false
end

function moveUp()
  if turtle.up() then
    position.y = position.y + 1
    -- print("Moved up " .. positionStr())
    return true
  end
  print("turtle.up() returned false.")
  return false
end

function moveDown()
  if turtle.down() then
    position.y = position.y - 1
    -- print("Moved down " .. positionStr())
    return true
  end
  print("turtle.down() returned false.")
  return false
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
  while turtle.getFuelLevel() <= min_fuel do
    print("Low fuel.")
    if not refuel() then
      return false
    end
  end
  return true
end

move_attempts = 4
function safeMove(moveFunc, digFunc)
  if not hasFuel() then
    print("safeMove failed on fuel")
    return false
  end
  for attempt = 1, move_attempts do
    if not moveFunc() then
      digFunc(true)
    else
      return true
    end
  end
  return false
end

function mineShaft(maxDepth)
  turnTo(3)
  while position.y > maxDepth do
    if not safeMove(moveDown, digDown) then
      return false
    end
    local turn_direction = 0
    digFront(false)
    if direction == 3 then
      turn_direction = 1
    elseif direction == 1 then
      turn_direction = -1
    end
    for turn_num = 1, 2 do
      turn(turn_direction)
      digFront(false)
    end
  end
  print("Reached max depth.")
end

function goY(targetY)
  while position.y < targetY do
    if not moveUp() then
      digUp(true)
    end
  end
  while position.y > targetY do
    if not moveDown() then
      digDown(true)
    end
  end
  return true
end

function goZ(targetZ)
  while position.z > targetZ do
    turnTo(0)
    moveForward()
  end
  while position.z < targetZ do
    turnTo(2)
    moveForward()
  end
  return true
end

function goHome()
  goY(0)
  goZ(0)
  turnTo(2)
end

shaftStart = {y = 0, z = 0}

function goToShaft()
  print("Moving to shaft start at " .. shaftStart.y .. ", " .. shaftStart.z)
  if goZ(shaftStart.z) and goY(shaftStart.y) then
    turnTo(0)
    return true
  end
  return false
end

function dumpCargo()
  print("Going home to dump cargo.")
  goHome()
  print("Dumping cargo.")
  dropInventory()
end

function main()
  local shaftDepth = -256
  while true do
    if not goToShaft() then
      goHome()
      print("goToShaft returned false.")
      return
    end
    mineShaft(shaftDepth)
    shaftStart.y = position.y + 1
    if position.y <= shaftDepth then
      print("Reached max depth of " .. shaftDepth)
      goY(0)
      plugShaft()
      shaftStart.z = shaftStart.z - 2
      shaftStart.y = 0
    end
    local block_below = getDown()
    if block_below ~= nil and block_below.name == "minecraft:bedrock" then
      print("Hit bedrock at " .. position.y .. ", starting new shaft.")
      goY(0)
      plugShaft()
      shaftStart.z = shaftStart.z - 2
      shaftStart.y = 0
    end
    if inventoryFull() then
      dumpCargo()
    end
    while not hasFuel() do
      goHome()
      print("NEED FUEL")
    end
    if shaftStart.z < -6 then
      print("Mined all shafts!")
      return
    end
  end
end

main()
goHome()
dropInventory()