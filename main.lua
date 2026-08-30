local love = require "love"
local button = require "button"

math.randomseed(os.time())

--[[ Aqui tem os estados do jogo, ele começa sempre no menu
"running' é ele rodando, "paused" quando pausamos com "esc"
O estado "ended" ainda não é utilizado, pois o jogo ainda não tem fim --]]
local game = {
    state = {
        menu = true,
        paused = false,
        running = false,
        ended = false,
    },
}

-- Fonte do que está escrito no jogo
local fonts = {
    medium = {
        font = love.graphics.newFont(16),
        size = 16
    },
    large = {
        font = love.graphics.newFont(24),
        size = 16
    },
    massive = {
        font = love.graphics.newFont(60),
        size = 16
    }
}

-- Dimensões do bonequinho
local player = { 
    radius = 20,
    x = 30,
    y = 30,
    speed = 300
}

-- Variáveis locais que representam o cursor do mouse e os botões
local cursorX, cursorY = 0, 0

local cursorImage = {}

local botao = {
    radius = 5,
    x = 30,
    y = 30
}
-- Botões do menu
local buttons = { 
    menu_state = {},
    paused_state = {}
}

--[[ Variáveis locais para manipular diferentes coisas, como:
mapas, portas lógicas, posição de objetos, posição do jogador ]]--
local currentMap = "mainMap"

local andGate = {}

local orGate = {}

local gates = {}

local gateDestinations = {
    {x = 543, y = 565}, -- Posição correta para a porta AND level1
    {x = 753, y = 384}, -- Posição correta para a porta AND1 level2
    {x = 753, y = 579}, -- Posição correta para a porta AND2 level2
    {x = 993, y = 483}  -- Posição correta para a porta OR level2
}

local chairs = {
    {x = 352, y = 2218, map = "level1", collisionMap = level1Map, requires = {}},
    {x = 1567, y = 2213, map = "level2", collisionMap = level2Map, requires = {"level1"}},
    {x = 358, y = 1573, map = "level3", collisionMap = level3Map, requires = {"level1", "level2"}},
    {x = 1587, y = 1573, map = "level4", collisionMap = level4Map, requires = {"level1", "level2", "level3"}},	
    {x = 358, y = 930, map = "level5", collisionMap = level5Map, requires = {"level1", "level2", "level3", "level4"}},
    {x = 1587, y = 930, map = "level6", collisionMap = level6Map, requires = {"level1", "level2", "level3", "level4", "level5"}}
}

-- Posição das moedas no level3
local coins = {
    {x = 700, y = 1230, Collect = false},
    {x = 495, y = 1060, Collect = false},
    {x = 780, y = 810, Collect = false},
    {x = 455, y = 655, Collect = false}
}

--[[ Posição dos números em bináro e seu valor. 
--Após comprar os binários '0' ou '1' se aparecerem no jogo ]]--
local numberStage3 = {
    { x = 635, y = 480, num = nil },
    { x = 820, y = 480, num = nil },
    { x = 1030, y = 480, num = nil },
    { x = 1220, y = 480, num = nil }
}

CorrectNumberStage3 = { 1, 0, 1, 1}

local numberStage4N = {
    { x = 620, y = 480, num = nil },
    { x = 830, y = 480, num = nil },
    { x = 1000, y = 480, num = nil },
    { x = 1200, y = 480, num = nil }
}

local CorrectNumberStage4N = { 0, 1, 1, 0} -- 6 

local numberStage4C1 = {
    { x = 572, y = 845, num = nil },
    { x = 772, y = 845, num = nil },
    { x = 962, y = 845, num = nil },
    { x = 1146, y = 845, num = nil }
}

local CorrectNumberStage4C1 = { 1, 0, 0, 1}

local numberStage4C2 = {
    { x = 572, y = 1236, num = nil },
    { x = 772, y = 1236, num = nil },
    { x = 962, y = 1236, num = nil },
    { x = 1146, y = 1236, num = nil }
}

local CorrectNumberStage4C2 = { 1, 0, 1, 0}

local previousPlayerX, previousPlayerY

local interactionStates = {
    level1 = true, 
    level2 = true,
    level3 = true,
    level4 = true,
    level5 = true,
    level6 = true
}

local autoReturn = {
    active = false,
    timer = 0,
    duration = 3,
    level = nil
}

-- Mensagem 1 do tutorial
local showInteractionMessage = false

-- Mensagem 2 do tutorial
local showInteractionMessage2 = false

-- NPC
local npc = {
    x = 1112,
    y = 2663,
    spriteSheet = nil,
    grid = nil,
    animation = nil,
    dialogues = {
        "Ola! Utilize E para interagir comigo!",
        "Acho que tem um professor bravo na sala",
        "Fale com ele!"
    },
    currentDialogue = 1,
    showDialogue = false
}

-- NPC Albini Level 3
local npcAlbini = {
    x = 273,
    y = 492,
    spriteSheet = nil,
    grid = nil,
    animation = nil,
    dialogues = {
      "Ola! Voce usara complemento de 1!",
      "Troque os numeros 1 por 0 e vice-versa",
      "Aperte 'b' e compre seus binarios",
	   "Escreva 4 em binário",
      "Agora transforme 4 para -4",
      "Compra realizada com sucesso",
      "Compra negada. Colete todas as moedas"
    },
    currentDialogue = 1,
    showDialogue = false
}

-- Variáveis para a animação do ônibus escolar
local schoolBus = {
    texture = nil,
    x = -200, -- Começa fora da tela à esquerda
    y = 2658,  -- Posição Y onde o ônibus vai parar
    targetX = 948, -- Posição onde o ônibus para para deixar o jogador
    speed = 400,
    state = "arriving", -- "arriving", "waiting", "leaving", "gone"
    waitTimer = 0,
    waitDuration = 0, -- Tempo que o ônibus espera antes de ir embora
    scale = 0.25 -- Escala para reduzir o tamanho do ônibus
}

local gameIntro = {
    active = false, -- Será true quando iniciar o jogo
    playerVisible = false, -- Jogador só aparece depois que sai do ônibus
    playerDropped = false -- Flag para marcar se o jogador já foi posicionado
}

-- Funções para manipular os estados do jogo
local function changeGameState(state)
    game.state["menu"] = state == "menu"
    game.state["ended"] = state == "ended"
    game.state["running"] = state == "running"
    game.state["paused"] = state == "paused"
end

-- Ao iniciar o jogo e clicarmos em jogar, o jogo muda
-- para o estado "running"
local function startNewGame ()
    changeGameState("running")
    gameIntro.active = true
    gameIntro.playerVisible = false
    gameIntro.playerDropped = false
    schoolBus.state = "arriving"
    schoolBus.x = -200
    schoolBus.waitTimer = 0
end

local barreiras = {
    {colisao = "bloqueio_1",
    art = "bloqueioarte_1",
    requer = {"level1", "level2"}
    },
    {colisao = "bloqueio_2",
    art = "bloqueioarte_2",
    requer = {"level3", "level4"}
    },
    {colisao = "bloqueio_3",
    art = "bloqueioarte_3",
    requer = {"level5", "level6"}
    }
}

local function barreiraCumprida(barreira)
    for _, lvl in ipairs(barreira.requer) do
        if interactionStates[lvl] ~= false then
            return false
        end
    end
    return true
end

local function levelDesbloqueado(chair)
    for _, requirement in ipairs(chair.requires) do
        --print(requirement)
        if interactionStates[requirement] ~= false then
            return false
        end
    end
    return true
end

-- Função que verifica quando o mouse clica nos botões
function love.mousepressed(x, y, button, istouch, presses) 
    if not game.state["running"] then
        if button == 1 then
            if game.state["menu"] then
                for index in pairs(buttons.menu_state) do
                    buttons.menu_state[index]:checkPressed(x, y, botao.radius)
                end
            elseif game.state["paused"] then
                for index in pairs(buttons.paused_state) do
                    buttons.paused_state[index]:checkPressed(x, y, botao.radius)
                end
            end
        end
    end
end

--[[ Começo de uma das 3 funções principais: love.load()
Essa função é responsável por carregar tudo que será exibido no jogo, não só
design, mas suas bibliotecas de manipulação de câmera, animação do personagem,
mapas, fontes, colliders, sons e diferentes estados --]]
function love.load()
    wf = require 'libraries/windfield'
    world = wf.newWorld(0, 0)

    camera = require 'libraries/camera'
    cam = camera()

    anim8 = require 'libraries/anim8'
    love.graphics.setDefaultFilter("nearest", "nearest")

    sti = require 'libraries/sti'
    -- Mapas
    gameMap = sti('maps/mapaPrincipal2.0.lua')
    menuMap = sti ('maps/menu.lua')
    -- Levels
    level1Map = sti('maps/level1.lua')
    level2Map = sti('maps/level2.lua')
    level3Map = sti('maps/level3.lua')
    level4Map = sti('maps/level4.lua')
    level5Map = sti('maps/level5.lua')
    level6Map = sti('maps/level6.lua')

    -- Texturas
    andGateTexture = love.graphics.newImage('maps/Texture/andlogic.png')
    orGateTexture = love.graphics.newImage('maps/Texture/orlogic.png')
    schoolBus.texture = love.graphics.newImage('maps/Texture/school_bus.png')
    number0Texture = love.graphics.newImage('maps/Texture/binary0.png')
    number1Texture = love.graphics.newImage('maps/Texture/binary1.png')

    andGate = {
        x = 863,
        y = 744,
        beingCarried = false
    }

    andGateExtra = {
        x = 1064,
        y = 800,
        beingCarried = false
    }

    orGate = {
        x = 1064,
        y = 994,
        beingCarried = false
    }

    --[[
    gates = {
        {x = 762, y = 1054, beingCarried = false},
        {x = 426, y = 717, beingCarried = false},
        {x = 526, y = 1246, beingCarried = false}
    }
    --]]

    love.window.setTitle("PETGAME")
    love.mouse.setVisible(false)

    sounds = {}
    sounds.blip = love.audio.newSource('sounds/blip.mp3', 'static')
    sounds.music = love.audio.newSource('sounds/smw_bonus.mp3', 'stream')
    sounds.music:setLooping(true)

    sounds.music:play() 
    -- desativei temporariamente pq não aguento mais essa música

    cursorImage = love.graphics.newImage('libraries/cursor/cursor1.png')

    font8bit = love.graphics.newFont('libraries/fonts/8-bit-pusab.ttf')

    fontSmall = love.graphics.newFont('libraries/fonts/8-bit-pusab.ttf', 10)

    fontSmaller = love.graphics.newFont('libraries/fonts/8-bit-pusab.ttf', 8)

    balloonImage = love.graphics.newImage('maps/Texture/balloon_whitebackground.png')

    player.collider = world:newBSGRectangleCollider(400, 250, 50, 80, 10)
    player.collider:setFixedRotation(true)
    
    player.spriteSheet = love.graphics.newImage('sprites/player-sheet.png') -- Importando o bonequinho
    player.grid = anim8.newGrid(12, 18, player.spriteSheet:getWidth(), player.spriteSheet:getHeight())

    player.animations = {}
    player.animations.down = anim8.newAnimation(player.grid('1-4', 1), 0.1)
    player.animations.left = anim8.newAnimation(player.grid('1-4', 2), 0.1)
    player.animations.right = anim8.newAnimation(player.grid('1-4', 3), 0.1)
    player.animations.up = anim8.newAnimation(player.grid('1-4', 4), 0.1)

    player.anim = player.animations.left

    -- Carregando o NPC
    npc.spriteSheet = love.graphics.newImage('sprites/player-sheet2.png')
    npc.grid = anim8.newGrid(12, 18, npc.spriteSheet:getWidth(), npc.spriteSheet:getHeight())
    npc.animation = anim8.newAnimation(npc.grid('2-2', 1), 1) -- Frame parado olhando para frente

    npcAlbini.spriteSheet = love.graphics.newImage('sprites/player-sheet2.png')
    npcAlbini.grid = anim8.newGrid(12, 18, npcAlbini.spriteSheet:getWidth(), npcAlbini.spriteSheet:getHeight())
    npcAlbini.animation = anim8.newAnimation(npcAlbini.grid('2-2', 3), 1) -- Frame parado olhando para direita

    CoinSprite = love.graphics.newImage('sprites/coin-sheet.png') -- Carregando as moedas
    CoinframeWidth = CoinSprite:getWidth() / 12
    CoinframeHeight = CoinSprite:getHeight()
    CoinGrid = anim8.newGrid(CoinframeWidth, CoinframeHeight, CoinSprite:getWidth(), CoinSprite:getHeight())
    CoinAnim = anim8.newAnimation(CoinGrid('1-12', 1), 0.1)
    --print("CoinSprite size:", CoinSprite:getWidth(), CoinSprite:getHeight())

    --[[ Binários só aparecem no jogo após coletar todas as moedas 
    e comprá-los com o NPC ]] --
    DrawBinary = false 
    RealeseBinary = false 

    walls = {}
    loadMapCollisions(gameMap)

    -- barreiras de fases
    --[[
    for _, barreira in ipairs(barreiras) do
        barreira.collider = nil
        local layer = gameMap.layers[barreira.colisao]
        if layer then 
            for _, obj in ipairs(layer.objects) do
                barreira.collider = world:newRectangleCollider(obj.x, obj.y, obj.width, obj.height)
                barreira.collider:setType('static')
            end
        end
    end
    ]]--

    loadBarreiras()

    buttons.menu_state.play_game = button("Jogar", startNewGame, nil, 140, 40)
    buttons.menu_state.settings = button("Ajustes", nil, nil, 140, 40)
    buttons.menu_state.exit_game = button("Sair", love.event.quit, nil, 140, 40)

    buttons.paused_state.replay_game = button("Voltar", startNewGame, nil, 140, 40)
    buttons.paused_state.menu = button("Menu", changeGameState, "menu", 140, 40)
    buttons.paused_state.exit_game = button("Sair", love.event.quit, nil, 140, 40)

    local textoFases = gameMap.layers["textos"]
    local coordFases = {}
    for _, obj in ipairs(textoFases.objects) do 
        coordFases[obj.name] = {x = obj.x, y = obj.y}
    end

end

--[[ Essa é a segunda função principal: love.update()
Ela é responsável por tudo que ocorre no momento em que estamos jogando o jogo,
sempre atualizando (fazendo update) com base nas ações do personagem. Por exemplo:
quando clicamos para mover o personagem nas setas, quando movemos as portas lógicas,
câmera acompanhando o personagem enquanto se move, são todas ações gerenciadas por essa função --]]
function love.update(dt)

    if game.state["menu"] or game.state["paused"] then
        cursorX, cursorY = love.mouse.getPosition() --cursor aparecer
    end

    local isMoving = false

    if game.state["running"] then
        -- Durante a animação do ônibus
        if gameIntro.active then
            -- Quando o ônibus está saindo, o jogador fica visível
            if schoolBus.state == "leaving" then
                gameIntro.playerVisible = true
                -- Só posiciona o jogador uma vez quando o ônibus começa a sair
                if not gameIntro.playerDropped then
                    player.collider:setPosition(schoolBus.x, schoolBus.y + 120)
                    player.x = schoolBus.x
                    player.y = schoolBus.y + 120
                    -- Para a velocidade do jogador
                    player.collider:setLinearVelocity(0, 0)
                    -- Define a animação para parado olhando para frente (idle)
                    player.anim = player.animations.down
                    player.anim:gotoFrame(2) -- Frame 2 é o idle/parado
                    gameIntro.playerDropped = true
                end
            elseif schoolBus.state == "gone" then
                gameIntro.active = false
                gameIntro.playerVisible = true
            end
        end

        if autoReturn.active then
            autoReturn.timer = autoReturn.timer + dt
            if autoReturn.timer >= autoReturn.duration then
                interactionStates[autoReturn.level] = false -- marca como vencido
                changeMap("mainMap")
                autoReturn.active = false
            end
        end 
        
        -- Movimento do jogador (só permite se a intro não está ativa OU o ônibus já foi embora)
        if not gameIntro.active or schoolBus.state == "leaving" then
            player.anim:update(dt)
            npc.animation:update(dt) -- Atualizar animação do NPC

            local nearInteraction, chairIndex = isNearInteractionObject()

            showInteractionMessage = nearInteraction

            showInteractionMessage2 = isNearGate(andGate)

            -- Verificar proximidade com NPC
            npc.showDialogue = isNearNPC()
            npcAlbini.showDialogue = isNearNPC()

            local vx = 0
            local vy = 0

            if love.keyboard.isDown ("right") then
                vx = player.speed
                player.anim = player.animations.right
                isMoving = true
            end

            if love.keyboard.isDown ("left") then
                vx = player.speed * -1
                player.anim = player.animations.left
                isMoving = true
            end

            if love.keyboard.isDown ("down") then
                vy = player.speed
                player.anim = player.animations.down
                isMoving = true
            end

            if love.keyboard.isDown ("up") then
                vy = player.speed * -1
                player.anim = player.animations.up
                isMoving = true
            end

            player.collider:setLinearVelocity(vx, vy)
            player.x = player.collider:getX()
            player.y = player.collider:getY()

            -- Atualizar posição da porta lógica se ela estiver sendo carregada
            if andGate.beingCarried then
                andGate.x = player.x
                andGate.y = player.y
            end

            if andGateExtra.beingCarried then
                andGateExtra.x = player.x
                andGateExtra.y = player.y
            end

            if orGate.beingCarried then
                orGate.x = player.x
                orGate.y = player.y
            end
	            
            if isMoving == false then
                player.anim:gotoFrame(2)
            end

            world:update(dt)
            player.x = player.collider:getX()
            player.y = player.collider:getY()
        end
    end

    -- Atualiza a animação do ônibus escolar
    if schoolBus.state == "arriving" then
        schoolBus.x = schoolBus.x + schoolBus.speed * dt
        if schoolBus.x >= schoolBus.targetX then
            schoolBus.x = schoolBus.targetX
            schoolBus.state = "waiting"
        end
    elseif schoolBus.state == "waiting" then
        schoolBus.waitTimer = schoolBus.waitTimer + dt
        if schoolBus.waitTimer >= schoolBus.waitDuration then
            schoolBus.state = "leaving"
        end
    elseif schoolBus.state == "leaving" then
        schoolBus.x = schoolBus.x - schoolBus.speed * dt
        -- Ônibus sai em linha reta (mesma altura Y)
        -- Remove qualquer modificação de Y para manter trajetória reta
        if schoolBus.x <= -200 then
            schoolBus.x = -200
            schoolBus.state = "gone"
        end
    end

    -- Camera seguir o boneco (ou o ônibus durante a intro)
    if gameIntro.active and schoolBus.state ~= "gone" and not gameIntro.playerDropped then
        -- Durante a intro, a câmera acompanha o ônibus até largar o jogador
        cam:lookAt(schoolBus.x + 100, schoolBus.y)
    else
        -- Movimento normal: câmera segue o jogador
        cam:lookAt(player.x, player.y)
    end 

    -- Não aparecer bordas pretas
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()

    if cam.x < w/2 then
        cam.x = w/2
    end

    if cam.y < h/2 then
        cam.y = h/2
    end

    local activeMap = gameMap;
    if currentMap == "level1" then activeMap = level1Map
    elseif currentMap == "level2" then activeMap = level2Map
    elseif currentMap == "level3" then activeMap = level3Map
    elseif currentMap == "level4" then activeMap = level4Map
    elseif currentMap == "level5" then activeMap = level5Map
    elseif currentMap == "level6" then activeMap = level6Map
    end
    
    local mapW = activeMap.width * activeMap.tilewidth
    local mapH = activeMap.height * activeMap.tileheight

    if cam.x > (mapW - w/2) then
        cam.x = (mapW - w/2)
    end

    if cam.y > (mapH - h/2) then
        cam.y = (mapH - h/2)
    end

    if currentMap == "level3" then 
        CoinAnim:update(dt)
    end

    -- atualiza o bloqueio feito pelas barreiras
    for _, barreira in ipairs(barreiras) do
        if barreira.collider and barreiraCumprida(barreira) then
            barreira.collider:destroy()
            barreira.collider = nil
        end
    end
end

--[[ Essa é a última função principal: love.draw().
Enquanto na função love.load() nós carregamos tudo que vamos utilizar no jogo,
nessa função, nós "desenhamos" o que propriamente aparecerá no mapa, em cada nível ou
a partir de cada ação do personagem. Por exemplo, se nós completamos o nível 1 e o personagem
não precisa voltar mais lá, nós não vamos desenhar mais o nível 1. Outro exemplo seria ao entrar
no nível 1, os desenhos do mapa principal precisarão se apagar por um momento e só os do mapa do
nível 1 serem exibidos --]]
function love.draw()
    love.graphics.setFont(font8bit)

    if game.state["running"] or game.state["paused"] and currentMap == "mainMap" then
        cam:attach()
            gameMap:drawLayer(gameMap.layers["floor"]) --desenhando chão
            gameMap:drawLayer(gameMap.layers["trees"]) --desenhando árvores

            -- as barreiras dependem dos niveis que o jogador completou
            for _, barreira in ipairs(barreiras) do
                if not barreiraCumprida(barreira) then
                    gameMap:drawLayer(gameMap.layers[barreira.art])
                end
            end

            gameMap:drawLayer(gameMap.layers["doors"]) --desenhando portas


            -- Desenha o ônibus escolar se estiver ativo (dentro da câmera)
            if gameIntro.active then
                love.graphics.setColor(1, 1, 1, 1) -- Reseta a cor para branco
                -- Virar o ônibus horizontalmente (escala X negativa)
                love.graphics.draw(schoolBus.texture, schoolBus.x, schoolBus.y, 0, -schoolBus.scale, schoolBus.scale)
            end
            
            -- Só desenha o jogador se ele estiver visível (não dentro do ônibus)
            if not gameIntro.active or gameIntro.playerVisible then
                player.anim:draw(player.spriteSheet, player.x, player.y, nil, 5, nil, 6, 9) --desenhando o boneco
            end

            -- Desenhar NPC
            npc.animation:draw(npc.spriteSheet, npc.x, npc.y, nil, 5, nil, 6, 9)

            -- Mostrar diálogo do NPC se estiver próximo
            if npc.showDialogue then
               DrawBalloon(npc)
	            DrawText(npc)
            end

            if showInteractionMessage then
                -- Posição da mensagem em relação ao jogador
                local messageX = chairs[1].x - 30
                local messageY = chairs[1].y - 50

                love.graphics.draw(balloonImage, messageX - 30, messageY - 15)

                love.graphics.setFont(fontSmall)
                love.graphics.setColor(0, 0, 0, 1) -- Cor preta
                love.graphics.printf("aperte E para interagir", messageX, messageY, 100, "center")
                love.graphics.setColor(1, 1, 1, 1) -- Resetando cor para branco
            end
            --world:draw()
        cam:detach() 
    end

    if currentMap == "level1" then
        cam:attach()
            level1Map:drawLayer(level1Map.layers["Ground"]) --desenhando chão
            level1Map:drawLayer(level1Map.layers["letters"]) --desenhando o puzzle
            -- Desenhar todos os objetos "and"
            love.graphics.draw(andGateTexture, andGate.x, andGate.y)

            if showInteractionMessage2 then
                -- Posição da mensagem em relação ao jogador
                local messageX = andGate.x - 30
                local messageY = andGate.y - 50

                love.graphics.draw(balloonImage, messageX - 30, messageY - 18)
                love.graphics.setFont(fontSmaller)
                love.graphics.setColor(0, 0, 0, 1) -- Cor preta
                love.graphics.printf("aperte E para pegar/soltar a porta logica", messageX, messageY, 100, "center")
                love.graphics.setColor(1, 1, 1, 1) -- Resetando cor para branco
            end

            player.anim:draw(player.spriteSheet, player.x, player.y, nil, 5, nil, 6, 9) --desenhando o boneco
            --world:draw()
        cam:detach() 
    end

    if currentMap == "level2" then
        cam:attach()
            level2Map:drawLayer(level2Map.layers["Ground"]) --desenhando chão
            level2Map:drawLayer(level2Map.layers["letters"]) --desenhando o puzzle
            -- Desenhar todos os objetos "and"
            love.graphics.draw(andGateTexture, andGate.x, andGate.y)
            love.graphics.draw(andGateTexture, andGateExtra.x, andGateExtra.y)
            love.graphics.draw(orGateTexture, orGate.x, orGate.y)

            player.anim:draw(player.spriteSheet, player.x, player.y, nil, 5, nil, 6, 9) --desenhando o boneco
            --world:draw()
        cam:detach() 
    end
    
    if currentMap == "level3" then
        cam:attach()
            level3Map:drawLayer(level3Map.layers["Ground"]) --desenhando chão
            -- removi porque estava dando erro
            --level3Map:drawLayer(level3Map.layers["letters"]) --desenhando o puzzle
	    
	         -- Desenhar moedas e apagá-las ao passar com o player por cima
            for i, coin in ipairs(coins) do
                RealeseBinary = false 
		            if not coin.Collect then
                     CoinAnim:draw(CoinSprite, coin.x, coin.y, 0, 3, 3, 8, 8)
		                  if isClose(coin.x, coin.y, "COIN") then 
		                     coin.Collect = true
		                  end
		            else RealeseBinary = true
	               end	
	         end
	   
            -- Desenhar NPC
            npcAlbini.animation:draw(npcAlbini.spriteSheet, npcAlbini.x, npcAlbini.y, nil, 5, nil, 6, 9)

            if npcAlbini.showDialogue then
               DrawBalloon(npcAlbini)
		         DrawText(npcAlbini)
            end
            
            -- Desenhar todos os numeros "0" e "1"
	         DrawNumber(numberStage3)

            player.anim:draw(player.spriteSheet, player.x, player.y, nil, 5, nil, 6, 9) --desenhando o boneco
            --world:draw()
        cam:detach()
    end

    if currentMap == "level4" then
        cam:attach()
            level4Map:drawLayer(level4Map.layers["Ground"]) --desenhando chão
            -- removi pelo mesmo erro do level3 
            -- level4Map:drawLayer(level4Map.layers["Number"]) --desenhando o números
            
	         -- Desenhar os binários
            DrawNumber(numberStage4N) -- Binário Normal
	         DrawNumber(numberStage4C1) -- Binário Complemento de 1
	         DrawNumber(numberStage4C2) -- Binário Complemento de 2
	
            player.anim:draw(player.spriteSheet, player.x, player.y, nil, 5, nil, 6, 9) --desenhando o boneco
            --world:draw()
        cam:detach()
    end

    if currentMap == "level5" then
        cam:attach()
        level5Map:drawLayer(level5Map.layers["Ground"])
        player.anim:draw(player.spriteSheet, player.x, player.y, nil, 5, nil, 6, 9) --desenhando o boneco
        cam:detach()
    end

    if currentMap == "level6" then
        cam:attach()
        level6Map:drawLayer(level6Map.layers["Ground"])
        player.anim:draw(player.spriteSheet, player.x, player.y, nil, 5, nil, 6, 9) --desenhando o boneco
        cam:detach()
    end


    if game.state["menu"] then
        menuMap:drawLayer(menuMap.layers["default"])
        menuMap:drawLayer(menuMap.layers["trees"])
        buttons.menu_state.play_game:draw(350, 230, 17, 10)
        buttons.menu_state.settings:draw(350, 280, 17, 10)
        buttons.menu_state.exit_game:draw(350, 330, 17, 10)

    elseif game.state["paused"] then
        buttons.paused_state.replay_game:draw(180, 100, 17, 10)
        buttons.paused_state.menu:draw(330, 100, 17, 10)
        buttons.paused_state.exit_game:draw(480, 100, 17, 10)
    end

    -- Desenhando o cursor
    if not game.state["running"] then
        local scale = 0.3
        love.graphics.draw(cursorImage, cursorX, cursorY, nil, scale, scale)
        --love.graphics.circle ("fill", player.x, player.y, botao.radius)
    end
end


-- Função para determinar se a porta lógica está posicionada no lugar correto
-- Se ela estiver, então a próxima ação será desbloqueada
local function isGateAtCorrectPosition(gate, destination)
    local tolerance = 100 -- Tolerância para considerar que a porta está na posição correta
    return math.abs(gate.x - destination.x) < tolerance and math.abs(gate.y - destination.y) < tolerance
end

-- Função para checar se todas as portas lógicas / binários estão posicionadas no lugar correto
-- Se estiverem, então a próxima ação será desbloqueada
local function checkGatePositions()
    if currentMap == "level1" then
        if isGateAtCorrectPosition(andGate, gateDestinations[1]) then
            -- Portas estão na posição correta, vá para o mapa principal
            interactionStates.level1 = false
            changeGameState("running")
            clearColliders()
            loadMapCollisions(gameMap)
            loadBarreiras()
            currentMap = "mainMap"
        end
    end

    if currentMap == "level2" then
        if isGateAtCorrectPosition(andGate, gateDestinations[2]) and 
           isGateAtCorrectPosition(andGateExtra, gateDestinations[3]) and
           isGateAtCorrectPosition(orGate, gateDestinations[4]) then
            -- Portas estão na posição correta, vá para o mapa principal
            interactionStates.level2 = false
            changeGameState("running")
            clearColliders()
            loadMapCollisions(gameMap)
            loadBarreiras()
            currentMap = "mainMap"
        end
    end

     if currentMap == "level3" then
        if numberRightPlace(numberStage3, CorrectNumberStage3) then
            -- Números estão na ordem correta, vá para o mapa principal
            interactionStates.level3 = false
            changeGameState("running")
            clearColliders()
            loadMapCollisions(gameMap)
            loadBarreiras()
            currentMap = "mainMap"
        end
    end

    if currentMap == "level4" then
        -- debug
        --[[
        print("print da linha")
        for _, i in ipairs(numberStage4N) do
            print(i.num)
        end]]--
        if numberRightPlace(numberStage4N, CorrectNumberStage4N) and
            numberRightPlace(numberStage4C1, CorrectNumberStage4C1) and
	         numberRightPlace(numberStage4C2, CorrectNumberStage4C2) then
            -- Números estão na ordem correta, vá para o mapa principal
            interactionStates.level4 = false
            changeGameState("running")
            clearColliders()
            loadMapCollisions(gameMap)
            loadBarreiras()
            currentMap = "mainMap"
        end
    end


    -- Restaura a posição do jogador
    if currentMap == "mainMap" then
        if previousPlayerX and previousPlayerY then
            player.x = previousPlayerX
            player.y = previousPlayerY
            player.collider:setPosition(previousPlayerX, previousPlayerY)
        end
    end

        --[[ 
        Remover o collider do objeto de interação
        for i, wall in ipairs(walls) do
            if wall:isDestroyed() == false then
                wall:destroy()
            end
        end
        --]]
end

--[[ Função voltada para o debug do código, utilizada quando queremos
queremos saber em que posição está o jogador no mapa para configurar
as portas lógicas. Não é utilizada diretamente no jogo. --]]
local function printPlayerPosition()
    print("Player position: x = " .. player.x .. ", y = " .. player.y)
end

--[[ Teclas de atalho
Não apenas teclas auxiliares, mas elas que determinam:
quando pausa o jogo, se queremos pausar a música, quando pegamos uma
porta lógica na mão, se queremos saber a posição do jogador (debug) --]]
function love.keypressed(key)
    if key == 'escape' then
        if game.state["paused"] then
            changeGameState("running")
        elseif game.state["running"] then
            changeGameState("paused")
        end
    end

    if key == 'space' then
        sounds.blip:play()
    end
    if key == 'z' then
        sounds.music:stop()
    end
 
    if key == 'b' then -- Botão para comprar binários
        if currentMap == "level3" then
            if isNearNPC() then
		         if RealeseBinary then
                  DrawBinary  = true
                  npcAlbini.currentDialogue = #npcAlbini.dialogues -1
                  sounds.blip:play()
                  -- "Compra realizada com sucesso"
		         else 
                  npcAlbini.currentDialogue = #npcAlbini.dialogues
		            sounds.blip:play()
		            -- "Compra negada. Colete todas as moedas"
		    		end
            end
        end
    end

    if key == 'e' then
         if game.state["running"] then
            -- Interação com NPC
            if isNearNPC() then
                npc.currentDialogue = npc.currentDialogue + 1
                if npc.currentDialogue > #npc.dialogues then
                    npc.currentDialogue = 1 -- Volta para o primeiro diálogo
                end
		         if currentMap == "level3" then 
		            npcAlbini.currentDialogue = npcAlbini.currentDialogue + 1
		            if npcAlbini.currentDialogue > #npcAlbini.dialogues - 2 then
                     npcAlbini.currentDialogue = 1 -- Volta para o primeiro diálogo
                  end
		         end
            sounds.blip:play() -- Som de interação
            return -- Sai da função para não executar outras interações
         end
            
         local bool, nearbyChair = isNearInteractionObject()
            if bool then
               -- Salva a posição atual do jogador
               previousPlayerX, previousPlayerY = player.x, player.y
               
               local chairMap = chairs[nearbyChair].map
               -- Verifica qual cadeira está perto e muda o mapa de acordo

               if currentMap == "mainMap" then
                    changeMap(chairMap)
                    --print("Mudou para mapa"..chairMap)
                    -- roda 5 e 6
                    if chairMap == "level5" or chairMap == "level6" then
                        autoReturn.active = true
                        autoReturn.timer = 0
                        autoReturn.level = chairMap
                    end
                elseif currentMap == chairMap then 
                  changeMap("mainMap")
               end
            end
            
            if currentMap == "level1" then
                if isNearGate(andGate) then
                    -- Alternar entre pegar e soltar a porta
                    andGate.beingCarried = not andGate.beingCarried
                end
                checkGatePositions()
            end
            if currentMap == "level2" then
                if isNearGate(andGate) then
                    andGate.beingCarried = not andGate.beingCarried
                end
                if isNearGate(andGateExtra) then
                    andGateExtra.beingCarried = not andGateExtra.beingCarried
                end
                if isNearGate(orGate) then
                    orGate.beingCarried = not orGate.beingCarried
                end
                checkGatePositions()
            end
	         if currentMap == "level3" then
		         ChangeNumber(numberStage3)
		         --[[ Substitui o número desenhado quando a tecla "e" é pressionada
		         e está próximo a posição do número ]]--
		         checkGatePositions()
	         end
	         if currentMap == "level4" then 
               ChangeNumber(numberStage4N)
               ChangeNumber(numberStage4C1)
               ChangeNumber(numberStage4C2)
               checkGatePositions()
	         end
        end
    end

    if key == 'p' then -- Pressione 'p' para ver a posição
        printPlayerPosition()
    end 
end

-- Função que determina se você está próximo suficiente da porta para pegar ela na mão
function isNearGate(gate)
    if gate == nil then
        return false
    end

    local playerX, playerY = player.x, player.y

    if not gate.x or not gate.y then
        return false
    end

    -- Verifica se o jogador está próximo da porta
    if math.abs(playerX - gate.x) < 100 and math.abs(playerY - gate.y) < 100 then
       return true
    end
    return false
end

-- Função para verificar proximidade com as moedas/Objetos/posições
function isClose(ObjX, ObjY, OBJ)
    local playerX, playerY = player.x, player.y  -- Posições do jogador
    local tolerance = 80

    if OBJ == "COIN" then 
       tolerance = 30
    end 

    if math.abs(playerX - ObjX) < tolerance and math.abs(playerY - ObjY) < tolerance then
       return true
    end
    return false
end

-- Função para verificar se os números estão na posição correta
function numberRightPlace(numbers, CorrectNumber)
    for i, number in ipairs(numbers) do
        if number.num ~= CorrectNumber[i] then
            return false
        end
    end 
    return true 
end

-- Função para mudar o número desenhado quando a tecla "e" é apertada
function ChangeNumber(numbers)
    if currentMap == "level3" then 
        isPossibleDraw = DrawBinary --[[ Na fase 3 é preciso comprar 
        os binários para estarem disponíveis para uso/desenho ]]--
    else isPossibleDraw = true
    end
    
    for i, number in ipairs(numbers) do
       if isClose (number.x, number.y, "NUMBER") then
        -- Testa proximidade com o local dos números
            if isPossibleDraw then 
               if number.num == nil then
                  number.num = 0
               elseif number.num == 0 then --Substitui o número
                  number.num = 1
               else number.num = 0
               end
            end
      end
    end
end    

-- Função para desenhar todos os numeros "0" e "1"
function DrawNumber(numbers)
   for i, number in ipairs(numbers) do
      if number.num == 0 then
         love.graphics.draw(number0Texture, number.x, number.y, 0, 1, 1 , 64, 64)
      elseif number.num == 1 then
         love.graphics.draw(number1Texture, number.x, number.y, 0, 1, 1 , 64, 64 )
      end
   end
end

-- Função para verificar proximidade do objeto de interação
function isNearInteractionObject()
    local playerX, playerY = player.x, player.y  -- Posições do jogador

   -- Verifica se o jogador está perto de qualquer cadeira e retorna o índice

   for i, chair in ipairs(chairs) do
      -- A distância é baseada em uma circuferência de raio 83
      if math.sqrt((playerX - chair.x)^2 + (playerY - chair.y)^2) < 83 then
      -- Verifica se o nível correspondente está ativo
         if interactionStates[chair.map] and levelDesbloqueado(chair) then
            return true, i
         end
      end
   end

   return false -- Se não estiver perto de nenhuma cadeira, retorna falso
end

-- Função para mudar de mapa e carregar colisão
function changeMap(newMap)
   currentMap = newMap
   clearColliders()
   clearBarreiras()

   if newMap == "mainMap" then
      loadMapCollisions(gameMap)
      loadBarreiras()
      player.collider:setPosition(previousPlayerX, previousPlayerY)
      player.x = previousPlayerX
      player.y = previousPlayerY
   elseif newMap == "level1" then
      loadMapCollisions(level1Map)
      player.collider:setPosition(500,695)
      player.x = 500
      player.y = 695
   elseif newMap == "level2" then
      loadMapCollisions(level2Map)
      player.collider:setPosition(500,695)
      player.x = 500
      player.y = 695
   elseif newMap == "level3" then
      loadMapCollisions(level3Map)
      player.collider:setPosition(1210,1340)
      player.x = 1210
      player.y = 1340
   elseif newMap == "level4" then
      loadMapCollisions(level4Map)
      player.collider:setPosition(1210,1340)
      player.x = 1210
      player.y = 1340
    elseif newMap == "level5" then
        loadMapCollisions(level5Map)
        player.collider:setPosition(1350,775)
        player.x = 1350
        player.y = 775
    elseif newMap == "level6" then
        loadMapCollisions(level6Map)
        player.collider:setPosition(1350,775)
        player.x = 1350
        player.y = 775
     end

end

-- Função para verificar proximidade com o NPC
function isNearNPC()
   local playerX, playerY = player.x, player.y
   local distance = nil

   if currentMap == "mainMap" then 
      distance = math.sqrt((playerX - npc.x)^2 + (playerY - npc.y)^2)    
   elseif currentMap == "level3" then
      distance = math.sqrt((playerX - npcAlbini.x)^2 + (playerY - npcAlbini.y)^2) 
   end

   if distance then 
      return (distance < 80) -- Retorna true se estiver próximo o suficiente
   else 
      return false
   end
end

-- Função para desenhar moedas
function DrawCoins()
   for i, coin in ipairs(coins) do
      if not coin.CollectCoin then 
         CoinAnim:draw(CoinSprite, coin.x, coin.y, 0, 3, 3, 8, 8)	
      end
   end
end

-- Cria as barreiras de fases (só as que ainda não foram cumpridas)
function loadBarreiras()
    for _, barreira in ipairs(barreiras) do
        barreira.collider = nil
        if not barreiraCumprida(barreira) then
            local layer = gameMap.layers[barreira.colisao]
            if layer then
                for _, obj in ipairs(layer.objects) do
                    barreira.collider = world:newRectangleCollider(obj.x, obj.y, obj.width, obj.height)
                    barreira.collider:setType('static')
                end
            end
        end
    end
end

-- Remove todas as barreiras de fases do mundo físico
function clearBarreiras()
    for _, barreira in ipairs(barreiras) do
        if barreira.collider then
            barreira.collider:destroy()
            barreira.collider = nil
        end
    end
end

-- Função para remover todas as colisões
function clearColliders()
    for i, wall in ipairs(walls) do
        wall:destroy()
    end
    walls = {}
end

-- Função para calcular posição do balão relativa ao NPC
function DrawBalloon(npc)
    local balloonX = npc.x - 70
    local balloonY = npc.y - 130
    -- novo npc x = 1708 e y = 1700
    -- Desenhar o balão
    love.graphics.setColor(1, 1, 1, 1) -- Cor branca para o balão
    love.graphics.draw(balloonImage, balloonX, balloonY)
end

--[[ Função para calcular posição do texto dentro do 
balão (ajustada para ficar centralizada) e desenhar a 
mensagem ]]--
function DrawText(npc)
    -- Configurar texto
    love.graphics.setFont(fontSmaller)
    love.graphics.setColor(0, 0, 0, 1) -- Cor preta para o texto

    local balloonX = npc.x - 70
    local balloonY = npc.y - 130

    -- Posição do texto dentro do balão (ajustada para ficar centralizada)
    local textX = balloonX + 20
    local textY = balloonY + 20
    local textWidth = 110

    -- Desenhar o texto do diálogo
    love.graphics.printf(npc.dialogues[npc.currentDialogue], textX, textY, textWidth, "center")

    -- Resetar cor
    love.graphics.setColor(1, 1, 1, 1)
    -- Posição da mensagem em relação ao jogador
    local messageX = npc.x -30
    local messageY = npc.y - 60

    love.graphics.setFont(fontSmall)
    love.graphics.setColor(0, 0, 0, 1) -- Cor preta
    love.graphics.setColor(1, 1, 1, 1) -- Resetando cor para branco
end

-- Função para carregar as colisões de determinados mapas (níveis diferentes, mapas diferentes)
function loadMapCollisions(map)
    if map and map.layers then  -- Verifica se o mapa e as camadas existem
        local collisionLayer = map.layers["Walls"]  -- Obtem a camada de colisão chamada "Walls"
        if collisionLayer then
            --print("existe collisionLayer")
            for _, obj in ipairs(collisionLayer.objects) do
                local wall = world:newRectangleCollider(obj.x, obj.y, obj.width, obj.height)
                wall:setType('static')  -- Define o collider como estático
                table.insert(walls, wall)  -- Adiciona o collider à tabela walls
            end
        end
    end
end
