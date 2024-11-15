from ball import *
from block import *
from paddle import *

class Game:
    def __init__(self):
        sgd.init()
        sgd.createWindow(1920,1080,"Paddles, Balls, Blocks, and Walls",sgd.WINDOW_FLAGS_FULLSCREEN)
        self.env = sgd.loadCubeTexture("assets/night.jpg",sgd.TEXTURE_FORMAT_SRGBA8,sgd.TEXTURE_FLAGS_DEFAULT)
        sgd.setEnvTexture(self.env)
        self.skybox = sgd.createSkybox(self.env)
        self.camera = sgd.createPerspectiveCamera()
        sgd.moveEntity(self.camera,0,15,0)
        self.light = sgd.createDirectionalLight()
        sgd.turnEntity(self.light,-45,-45,0)
        sgd.setLightShadowsEnabled(self.light,True)
        # ground
        #ground_material = sgd.loadPBRMaterial("assets/Gravel041_1K-JPG")
        #ground_mesh = sgd.createBoxMesh(-32,-0.1,-32,32,0,32,ground_material)
        #sgd.transformTexCoords(ground_mesh,16,16,0,0)
        #self.ground = sgd.createModel(ground_mesh)

        # walls
        self.walls = sgd.loadModel("assets/walls.glb")
        sgd.moveEntity(self.walls,-19,0,37)
        self.walls_collider = sgd.createMeshCollider(self.walls,0,sgd.getModelMesh(self.walls))

        # balls
        self.balls=[]
        self.ball_mesh = sgd.loadMesh("assets/ball1.glb")
        sgd.setMeshShadowsEnabled(self.ball_mesh,True)

        # block
        self.block_mesh = sgd.loadMesh("assets/block_yellow.glb")
        sgd.setMeshShadowsEnabled(self.block_mesh, True)
        self.blocks = []
        for i in range(10):
            self.blocks.append(Block(self.block_mesh,i * 2 - 14,16))

        # paddle
        self.paddle_mesh = sgd.loadMesh("assets/paddle_4m.glb")
        sgd.setMeshShadowsEnabled(self.paddle_mesh, True)
        self.paddle = Paddle(self.paddle_mesh)

        # collisions setup
        # ball with walls, ball = 1, walls = 0
        sgd.enableCollisions(1, 0, sgd.COLLISION_RESPONSE_NONE)
        # ball with paddle, ball = 1, paddle = 2
        sgd.enableCollisions(1, 2 ,sgd.COLLISION_RESPONSE_STOP)
        # ball with blocks, ball = 1, blocks = 3
        sgd.enableCollisions(1, 3, sgd.COLLISION_RESPONSE_STOP)
        self.colliding = False # flag to display collisions for debug purposes

        # load audio
        self.title_sound = sgd.loadSound("assets/wave/title.wav")
        self.bgm_sound = sgd.loadSound("assets/wave/bgm.wav")
        self.paddle_sound = sgd.loadSound("assets/wave/pad.wav")
        self.audio_on = False
        if self.audio_on:
            sgd.playSound(self.title_sound)
        # pre-loop stuff
        self.loop = True
        self.paused = False
        sgd.setMouseCursorMode(3)

    def load_stage(self,stage):
        pass
    def run_stage(self):
        if self.audio_on:
            background_music = sgd.playSound(self.bgm_sound)
            sgd.setAudioLooping(background_music,True)
        while self.loop:
            e=sgd.pollEvents()
            if e==sgd.EVENT_MASK_CLOSE_CLICKED: self.loop = False
            if sgd.isKeyHit(sgd.KEY_ESCAPE): self.loop = False
            if sgd.isKeyHit(sgd.KEY_P):
                if self.paused:
                    self.paused = False
                else:
                    self.paused = True
            if not self.paused:
                # on mouse right click, release a ball (if available)
                if sgd.isMouseButtonHit(1):
                    # set which way the ball goes left or right based on X location of paddle
                    if sgd.getEntityX(self.paddle.model) < -3.9:
                        vx = -0.1
                    else:
                        vx= 0.1
                    self.balls.append(Ball(self.ball_mesh,sgd.getEntityX(self.paddle.model),sgd.getEntityY(self.paddle.model) + 0.5,vx,0.7))
                # balls update loop
                for ball in self.balls:
                    ball.update()
                    if sgd.getCollisionCount(ball.collider) > 0:
                        self.colliding = True
                        collided_collider = sgd.getCollisionCollider(ball.collider,0)
                        # check for walls
                        if sgd.getColliderType(collided_collider) == 0:
                            if sgd.getEntityY(ball.model) > 29:
                                # we're probably at the ceiling
                                ball.velocity[1] = -abs(ball.velocity[1] * 0.8)
                            else:
                                # we're probably hitting the side walls
                                if sgd.getEntityX(ball.model) < -16:
                                    # left wall
                                    ball.velocity[0] = abs(ball.velocity[0] * 0.8)
                                else:
                                    # right wall
                                    ball.velocity[0] = -abs(ball.velocity[0] * 0.8)
                        elif sgd.getColliderType(collided_collider) == 2:
                            # check for paddle collisions
                            collided_entity = sgd.getColliderEntity(collided_collider)
                            paddle_height = sgd.getEntityY(collided_entity)
                            # sgd.setEntityPosition(ball.model,sgd.getEntityX(ball.model),paddle_height + 1,sgd.getEntityZ(ball.model))
                            ball.velocity[1] = abs(ball.velocity[1])
                            if paddle_height < 2 and not sgd.isMouseButtonDown(0):
                                # add some velocity for ball hit with "swung" paddle
                                ball.velocity[1] += ball.velocity[1] / 3
                            if self.audio_on: sgd.playSound(self.paddle_sound)
                        elif sgd.getColliderType(collided_collider) == 3:
                            # block collisions
                            block_collision_point = sgd.getColliderEntity(collided_collider)
                            block_model = sgd.getEntityParent(block_collision_point)
                            for block in self.blocks:
                                if block.model == block_model:
                                    sgd.destroyEntity(block.model)
                                    self.blocks.remove(block)
                            ball.velocity[1] = - ball.velocity[1]
                    else:
                        self.colliding = False
                    if not ball.active:
                        sgd.destroyEntity(ball.model)
                        self.balls.remove(ball)
                self.paddle.update()
                sgd.updateColliders()
            sgd.renderScene()
            sgd.clear2D()
            if self.colliding: sgd.draw2DText("Colliding",0,0)
            sgd.draw2DText("FPS : " + str(int(sgd.getFPS())),0,sgd.getWindowHeight() - 20)
            sgd.present()
    def __del__(self):
        sgd.terminate()
