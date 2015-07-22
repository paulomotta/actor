local actor = {
  _VERSION     = 'actor v0.1',
  _URL         = 'https://github.com/paulomotta/actor.lua',
  _DESCRIPTION = 'An game actor library for Lua',
  _LICENSE     = [[
    still to define
  ]],
  listOfActors = {},
  actorId = 1,
  listOfColliders = {},
  colliderId = 1
}
--Um actor tem animacoes associadas, movimentacao, uma representacao para colisao

local anim8 = require 'anim8' --para animacao

local Actor = {}
Actor.__index = Actor
--definicao dos atributos
Actor.sprite = nil
Actor.width = 0
Actor.height = 0
Actor.flipped = false
Actor.grid = nil
Actor.animation = nil
Actor.mapObject = nil
Actor.npc = false
Actor.collider = false
Actor.collectable = false
Actor.flyer = false
Actor.move = "left"
Actor.face = "left"
Actor.name = nil
Actor.world = nil
Actor.jumping = false
Actor.itemsCollected = {coins = 0, keys = 0, bibles = 0, books = 0}
Actor.lifes = 5
Actor.upCount = 0
Actor.hitCount = 0
Actor.resetPlayer = false
Actor.originX = 0
Actor.originY = 0
Actor.stationery = false
Actor.id = -1
Actor.score = 0
Actor.win = false


setmetatable(Actor, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function Actor.new(id, npc, face, collider, collectable, flyer, resetPlayer, stationery)
  local self = setmetatable({}, Actor)
  self.name = id
  self.npc = npc
  self.collider = collider
  self.collectable = collectable
  self.flyer = flyer
  self.resetPlayer = resetPlayer
  self.stationery = stationery
    if (not collider) then
        self.id = actor.actorId
        actor.listOfActors[self.id] = self
        actor.actorId = actor.actorId + 1
    else
        self.id = actor.colliderId
        actor.listOfColliders[self.id] = self
        actor.colliderId = actor.colliderId + 1
    end
  self.face = face
  if (self.face == "left") then
    self.flipped = true
  end
  return self
end

-- the : syntax here causes a "self" arg to be implicitly added before any other args
function Actor:setSprite(s)
    --print(s)
  self.sprite = love.graphics.newImage(s)
end

function Actor:getSprite()
  return self.sprite
end

function Actor:setGrid(frameWidth, frameHeight)
  self.grid = anim8.newGrid(frameWidth, frameHeight, self.sprite:getWidth(), self.sprite:getHeight())
  self.width = frameWidth
  self.height = frameHeight
end

function Actor:getSprite()
  return self.sprite
end

function Actor:setAnimation(frames, speed)
  self.animation = anim8.newAnimation(self.grid(unpack(frames)), speed)
end

function Actor:getAnimation()
  return self.animation
end

function Actor:setImage(s, frameWidth, frameHeight, frames, speed)
    self:setSprite(s)
    self:setGrid(frameWidth, frameHeight)
    self:setAnimation(frames, speed)
end

function Actor:setMapObject(obj)
    --print(" setMatObject "..obj.name)
    self.mapObject = obj
    self.originX = obj.x
    self.originY = obj.y
end

function Actor:getMapObject()
  return self.mapObject
end

function Actor:setWorld(w)
    --print(w)
    self.world = w
    -- x,y, width, height
    if (self.collider) then
        self.world:add(self, self.mapObject.x, self.mapObject.y, self.mapObject.width, self.mapObject.height )
    else
        self.world:add(self, self.mapObject.x, self.mapObject.y, self.width, self.height )
    end
end

function Actor:getWorld()
  return self.world
end

function Actor:getCoins()
    return self.itemsCollected.coins
end

function Actor:getKeys()
    return self.itemsCollected.keys
end

function Actor:getBibles()
    return self.itemsCollected.bibles
end

function Actor:getBooks()
    return self.itemsCollected.books
end

function Actor:getLifes()
    return self.lifes
end

function Actor:getScore()
    return self.score
end

function Actor:iswin()
    return self.win
end

function Actor:hit()
    -- so tem um hit se nao tiver sido acertado recentemente
    if (self.hitCount <= 0 ) then
        if (self.lifes > 0 ) then
            self.lifes = self.lifes - 1
        end
        self.hitCount = 50
    end
end

function Actor:resetPosition()
    self.mapObject.x = self.originX
    self.mapObject.y = self.originY
    self.world:update(self, self.mapObject.x,self.mapObject.y)
end

function Actor:resetPlayerState()
    self.lifes = 5
    self.itemsCollected = {coins = 0, keys = 0, bibles = 0, books = 0}
    self:resetPosition()
end


local playerFilter = function(item, other)

    if (other ~= nil and item ~= nil) then 

        if (item.npc and other.npc) then

            if (item.collider or other.collider) then
                --print("item="..item.name.." other="..other.name.." slide")
                return 'slide'
            else
                --print("item="..item.name.." other="..other.name.." cross")
                return 'cross'
            end
        else
            --pelo menos um dos dois nao e npc
            
            if (other.collectable)then
              return 'cross'
            elseif (not other.collider) then
              return 'touch'
            end
        end
    end

    return 'slide'
end

function Actor:processCollision(cols, sides)
    for i=1,#cols do
        local other = cols[i].other

        if (self.npc) then
            if (sides) then
                local collisiontype = cols[i].type
                if collisiontype ~= 'cross' then
                    if (self.move == 'left') then
                        self.move = "right"
                    else
                        self.move = "left"
                    end
                end
            end
        else
            -- se nao e npc entao e o player
            if (other.collectable) then
              --print("collect  "..other.name)
              if (other.name:find("coin")) then
                coletarmoeda:play()
                self.itemsCollected.coins = self.itemsCollected.coins + 1
                self.world:remove(other)
                actor.listOfActors[other.id] = nil
                --print("removing coin "..other.id)
              elseif (other.name:find("life")) then
                coletarlife:play()
                self.lifes = self.lifes + 1
                self.world:remove(other)
                actor.listOfActors[other.id] = nil
                --print("removing life "..other.id)
              elseif (other.name:find("book")) then
                coletarbook:play()
                self.itemsCollected.bibles = self.itemsCollected.bibles + 1
                self.world:remove(other)
                actor.listOfActors[other.id] = nil
                --print("removing book "..other.id)
            elseif (other.name:find("porta")) then
                self.win = true
                print("ganhou "..other.id)
              end
            end

            if (other.collider) then

                if (other.name:find("abismo")) then
                    hit:play()
                    --print(self.name.." touch  "..other.name)
                    if (self.npc) then
                        other:hit()
                        if (self.resetPlayer) then
                            --caiu no abismo
                            --print(self.name.." touch  "..other.name.." caiu no abismo")
                            other:resetPosition()
                        end
                    else
                        if (other.resetPlayer) then
                            --caiu no abismo
                            --print(self.name.." touch  "..other.name.." caiu no abismo")
                            self:resetPosition()
                        end
                        self:hit()
                    end
                    
                    tx = -lasallinho:getMapObject().x + 64
                    ty = -367
                    return
                end
                if (self.jumping) then
                    self.jumping = false
                end 
            end
        end

        --independente de ser npc ou nao, testar colisao de vida
        local collisiontype = cols[i].type
        if collisiontype == 'touch' then
            hit:play()
            --print(self.name.." touch  "..other.name)
            
            if (self.npc) then
                other:hit()
                if (self.resetPlayer) then
                    --caiu no abismo
                    --print(self.name.." touch  "..other.name.." caiu no abismo")
                    other:resetPosition()
                end
            else
                if (sides) then
                    if (other.resetPlayer) then
                        --caiu no abismo
                        --print(self.name.." touch  "..other.name.." caiu no abismo")
                        self:resetPosition()
                    end
                    self:hit()
                else
                    self.score = self.score + 100
                    self.world:remove(other)
                    actor.listOfActors[other.id] = nil
                end
            end
        end
    end
end

function Actor:update(dt)
    if (not self.npc) then
        --print("updatePlayer")
        self:updatePlayer(dt)
    elseif (self.npc and (not self.collider)) then
        --print("updateNPC")
        self:updateNPC(dt)
    end
end

function Actor:updateNPC(dt)
    --print( "  "..self.move)
    --print( "  "..self.id)
    --print( "  "..self.mapObject.x)
    if (self.stationery) then
        self:getAnimation():update(dt)
        return
    end

    if (self.collectable) then
        self:getAnimation():update(dt)
        return
    end

    if (self.move == "right") then

        if (self.flipped) then
            self:getAnimation():flipH()
            self.flipped = false
        end

        self:getAnimation():update(dt)

        local actualX, actualY, cols, len = self.world:move(self, self.mapObject.x + 1,self.mapObject.y, playerFilter)
        self.mapObject.x = actualX        
        self:processCollision(cols, true)
        
    end

    if (self.move == "left") then

        if (not self.flipped) then
            self:getAnimation():flipH()
            self.flipped = true
        end

        self:getAnimation():update(dt)

        if ( self.mapObject.x > 0 ) then
            local actualX, actualY, cols, len = self.world:move(self, self.mapObject.x - 1,self.mapObject.y, playerFilter)
            self.mapObject.x = actualX
            self:processCollision(cols, true)
        end
    end

    if (not self.flyer) then
        local actualX, actualY, cols, len = self.world:move(self, self.mapObject.x,self.mapObject.y + 5, playerFilter, playerFilter)
        self.mapObject.y = actualY
        self:processCollision(cols, false)
    end

end

function Actor:updatePlayer(dt)
    --print( "  "..self.move)
    --print( "  "..self.id)
    --print( "  "..self.mapObject.x)

    left = false
    right = false
    jump = false
    if (android) then
        for i = 1, love.touch.getTouchCount() do
          local index, x, y, pressure = love.touch.getTouch(i)
          local cx = x * love.graphics.getWidth() + offsetx

          if (cx > upButton.x - 45) then
            jump = true
          end

          if (cx < leftButton.x + 80) then
            left = true
          elseif (cx > rightButton.x - 45 and cx < rightButton.x + 45) then
            right = true
          end
          
        end

        --x = 10 + offsetx + 32
        --y = 450 + offsety
        --love.graphics.print("TouchCount="..love.touch.getTouchCount(), x, y)
    end

    if (self:getLifes() <= 0) then
        return
    end

    if love.keyboard.isDown(" ") or (android and jump) then
        if (not self.jumping) then
            self.jumping = true
            self.upCount = 35
        end
    end

    local offset = 5
    if (self.jumping) then
        offset = -self.upCount
        self.upCount = self.upCount - 3
    end

    local actualX, actualY, cols, len = self.world:move(self, self.mapObject.x,self.mapObject.y + offset, playerFilter)
    self.mapObject.y = actualY
    self:processCollision(cols, false)

    if love.keyboard.isDown("right") or (android and right) then

        if (self.flipped) then
            self:getAnimation():flipH()
            self.flipped = false
        end

        self:getAnimation():update(dt)

        local offset = 5
        if (self.jumping) then
            offset = 10
        end

        local actualX, actualY, cols, len = self.world:move(self, self.mapObject.x + offset,self.mapObject.y, playerFilter)
        
        self.mapObject.x = actualX
        self:processCollision(cols, true)
        return
    end

    if love.keyboard.isDown("left") or (android and left) then

        if (not self.flipped) then
            self:getAnimation():flipH()
            self.flipped = true
        end

        self:getAnimation():update(dt)

        local offset = -5
        if (self.jumping) then
            offset = -10
        end

        local actualX, actualY, cols, len = self.world:move(self, self.mapObject.x + offset,self.mapObject.y, playerFilter)
        
        self.mapObject.x = actualX
        self:processCollision(cols, true)
        return
    end

        
        
end

function Actor:animationFlip()
    if (self.flipped) then
        self:getAnimation():flipH()
        self.flipped = false
    end
end

function Actor:draw() 
    if (self.mapObject ~= nil ) then
        local shouldDraw = true
        if (self.hitCount > 0 ) then
            if (self.hitCount % 2 ~= 0) then
                shouldDraw = false
            end
            self.hitCount = self.hitCount - 1
        end

        if (shouldDraw) then
            self:getAnimation():draw(self:getSprite(), self.mapObject.x, self.mapObject.y)
            --love.graphics.print("x="..self.mapObject.x.." y="..self.mapObject.y, self.mapObject.x, self.mapObject.y)
            --love.graphics.setColor(0,255,0)
            --love.graphics.rectangle("line", self.mapObject.x, self.mapObject.y, self.width, self.height)
            --love.graphics.setColor(255,255,255)
        end
    end
end

--permite ao usuario conseguir uma instancia do Actor

actor.new = function(...)
    return Actor(...)
end


return actor