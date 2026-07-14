# Built-in process entry points.
# The kernel runs these processes automatically.
# Each process must end with an 'exit' instruction.

#-------------------------------------------------------------------------------
bmk "About"

# This is primarily a 2D n-body gravity simulation, but it also features
# a playable character with which to jump around the various gravitational bodies.

# Some credit goes to Flatik, who uploaded a similar gravity simulation. Although none
# of the code was copied (despite how surprisingly similar certain elements turned out)
# I did incorporate some of their optimizations in a small few places, so I'd like to
# give them a shoutout nonetheless :)

# Controls:
# BTN_UP: Charge your jump with more 'oomph'
# BTN_LEFT / BTN_RIGHT: Move along your current body
# BTN_A: Jump away from the body you're standing on.


#-------------------------------------------------------------------------------
bmk "DATA"

PLAYER_SPRITESHEET: emb file "assets/astronaut.png" # To be implemented

#-------------------------------------------------------------------------------
bmk "CONSTANTS"

# Simulation
def G 1.0 # This makes gravity a lot stronger but more fun :)
#def G 6.6743*(10**-11)
def MAX_BODIES 20
def BODY_ELASTICITY 0.8

# Visuals
def BODY_LUMA 70
def DISTANCE_SCALE 7.0
def TIME_SCALE 1.0
def CAMERA_SPEED 5.0


def CENTER_CAMERA true # Whether the camera follows the player or not

def SCREEN_WIDTH_F 320.0
def SCREEN_HEIGHT_F 240.0
def CENTER_X_F SCREEN_WIDTH_F/2.0
def CENTER_Y_F SCREEN_HEIGHT_F/2.0

Input:
    def .JUMP BTN_A

Strings:
    .jump_charge: emb string "Jump Charge: "

#-------------------------------------------------------------------------------
bmk "STRUCTS"

#-------------------------------------------------------------------------------
sbmk "Player"

PLAYER:
    # Constants
    def .SPEED 100.0
    def .JUMP_FORCE 600.0
    def .JUMP_CHARGE_SPEED -200.0
    def .MIN_JUMP_CHARGE 100.0
    def .MAX_JUMP_CHARGE 5000.0
    # Properties
    ## Physics
    .x: emb f32t 160.0 # X Position
    .y: emb f32t 100.0 # Y Position
    .velx: emb f32t 0.0 # X Velocity
    .vely: emb f32t 0.0 # Y Velocity
    .movex: emb f32t 0.0 # X Move Velocity
    .movey: emb f32t 0.0 # Y Move Velocity
    .rot: emb f32t 0.0 # Rotation (Radians)
    .mass: emb f32t 7.0 # Mass

    .jump_charge: emb f32t PLAYER.MIN_JUMP_CHARGE
    .grounded: emb u8t false
    .parent_body_index: emb u8t 0
    .collision_radius: emb f32t 0.5 # Radius of collision circle
    .flip_sprite: emb u8t false

#-------------------------------------------------------------------------------
sbmk "Body"

BODY:
    # Properties
    .x: emb f32t 0.0 # X Position
    .y: emb f32t 0.0 # Y Position
    .velx: emb f32t 0.0 # X Velocity
    .vely: emb f32t 0.0 # Y Velocity
    .rot: emb f32t 0.0 # Rotational velocity
    .radius: emb f32t 1.0 # Radius
    .mass: emb f32t 1.0 # Mass
    # Offsets
    def .X (.x - BODY)
    def .Y (.y - BODY)
    def .VX (.velx - BODY)
    def .VY (.vely - BODY)
    def .ROT (.rot - BODY)
    def .R (.radius - BODY)
    def .M (.mass - BODY)
    def .SIZE ($ - BODY)

#-------------------------------------------------------------------------------
bmk "VARIABLES"

bodies: res u8t BODY.SIZE*MAX_BODIES
bodies_count: emb u8t 0

player_check_collision: emb u8t false

dt: emb f32t 0.0 # DeltaTime

#-------------------------------------------------------------------------------
bmk "-------------------------"

#-------------------------------------------------------------------------------
bmk "PROCESSES"

#-------------------------------------------------------------------------------
sbmk "Start"
_start: # Runs once when the VM starts.
    # Initialize your game state here.

    mov a0, 160.0 # X
    mov a1, 120.0 # Y
    mov a2, 0.0 # VX
    mov a3, 0.0 # VY
    mov a4, 0.0 # ROTATION
    mov a5, 100.0 # RADIUS
    mov a6, 1000000.0 # MASS
    cal add_body

    mov a0, 280.0 # X
    mov a1, 120.0 # Y
    mov a2, 0.0 # VX
    mov a3, 35.0 # VY
    mov a4, 0.0 # ROTATION
    mov a5, 20.0 # RADIUS
    mov a6, 100000.0 # MASS
    cal add_body

    mov a0, 287.0 # X
    mov a1, 120.0 # Y
    mov a2, -3.0 # VX
    mov a3, 82.0 # VY
    mov a4, 0.0 # ROTATION
    mov a5, 2.0 # RADIUS
    mov a6, 0.0000001 # MASS
    cal add_body

    mov a0, 160.0 # X
    mov a1, 0.0 # Y
    mov a2, 40.0 # VX
    mov a3, 0.0 # VY
    mov a4, 0.0 # ROTATION
    mov a5, 40.0 # RADIUS
    mov a6, 1000000.0 # MASS
    cal add_body

    exit

#-------------------------------------------------------------------------------
sbmk "Update"
_update: # Runs at 60 Hz.
    # Write your game logic here.
    syscall SYS_GET_UPDATE_DELTA
    str f32t, dt, a0

    str u8t, player_check_collision, true

    cal update_gravity
    cal update_collisions
    cal check_input
    cal update_positions
    .if_center_camera:
        mov cr, CENTER_CAMERA
        jfs @endif+
        cal center_camera
    @endif:

    exit

#-------------------------------------------------------------------------------
sbmk "Draw"
_draw: # Runs at 60 Hz and updates the front buffer.
    # Draw graphics to the screen here.
    cal draw_bodies
    cal draw_player
    exit

#-------------------------------------------------------------------------------
sbmk "Input"
_input: # Runs when input state changes.
    # React to player input here.
    exit

#-------------------------------------------------------------------------------
bmk "-------------------------"

#-------------------------------------------------------------------------------
bmk "FUNCTIONS"


#-------------------------------------------------------------------------------
bmk "Initialization"

#-------------------------------------------------------------------------------
sbmk "Add Body"
add_body:
    # > (f32t) a0..a1: x, y position
    # > (f32t) a2..a3: x, y velocity
    # > (f32t) a4: rotation speed
    # > (f32t) a5: radius
    # > (f32t) a6: mass

    lod u8t, t0, bodies_count
    cmp lt, t0, MAX_BODIES
    jfs @end+

    cea bodies, t0, BODY.SIZE
    ste f32t, BODY.X, a0
    ste f32t, BODY.Y, a1
    ste f32t, BODY.VX, a2
    ste f32t, BODY.VY, a3
    ste f32t, BODY.ROT, a4
    ste f32t, BODY.R, a5
    ste f32t, BODY.M, a6
    inc t0
    str u8t, bodies_count, t0
    @end:
    ret

#-------------------------------------------------------------------------------
bmk "Input"

#-------------------------------------------------------------------------------
sbmk "Check Input"
check_input:
    # Get input states
    # s0: Left - Right
    # s1: Up - Down
    # s2: Jump

    vpsh s0..s2

    syscall SYS_GET_INPUT
    and t0, a0, BTN_LEFT
    cmp neq, t0, 0
    fctf t0, cr
    and t1, a0, BTN_RIGHT
    cmp neq, t1, 0
    fctf t1, cr
    and t2, a0, BTN_UP
    cmp neq, t2, 0
    fctf t2, cr
    and t3, a0, BTN_DOWN
    cmp neq, t3, 0
    fctf t3, cr
    fneg t0
    fneg t2
    fadd s0, t0, t1
    fadd s1, t2, t3

    and t0, a0, Input.JUMP
    cmp neq, t0, 0
    mov s2, cr

    .is_grounded:
        lod u8t, cr, PLAYER.grounded
        jfs @end+
        str f32t, PLAYER.movex, 0.0 # Reset movement
        str f32t, PLAYER.movey, 0.0
        cmp neq, s1, 0
        jfs @end+
        mov a0, s1
        cal charge_jump
    @end:

    @move:
        cmp neq, s0, 0
        jfs @end+
        mov a0, s0
        cal player_move
    @end:

    @jump:
        cmp eq, s2, 1
        jfs @end+
        cal player_jump
    @end:
    vpop s0..s2
    ret

#-------------------------------------------------------------------------------
sbmk "Player Move"
player_move:
    # a0: horizontal direction

    lod u8t, t0, PLAYER.grounded
    cmp eq, t0, true
    jfs @end+
    lod u8t, t0, PLAYER.parent_body_index
    cea bodies, t0, BODY.SIZE
    lod f32t, t0, PLAYER.x
    lod f32t, t1, PLAYER.y
    lod f32t, t2, PLAYER.velx
    lod f32t, t3, PLAYER.vely
    lde f32t, t4, BODY.X
    lde f32t, t5, BODY.Y

    # Calculate normal vector
    fsub t6, t0, t4 # dx
    fsub t7, t1, t5 # dy
    fpow t8, t6, 2.0
    fpow t9, t7, 2.0
    fadd t8, t9 # r^2
    fsqrt t8 # r
    fdiv t6, t8 # dx/r
    fdiv t7, t8 # dy/r
    fneg t0, t7 # x^
    mov t1, t6 # y^

    fmul t10, a0, PLAYER.SPEED
    fmul t0, t10
    fmul t1, t10
    fadd t2, t0
    fadd t3, t1
    str f32t, PLAYER.movex, t2
    str f32t, PLAYER.movey, t3

    @end:
    ret

#-------------------------------------------------------------------------------
sbmk "Charge Jump"
charge_jump:
    # > a0: UP/DOWN input

    lod u8t, cr, PLAYER.grounded
    jfs @end+

    fmul t0, a0, PLAYER.JUMP_CHARGE_SPEED
    lod f32t, t1, dt
    fmul t0, t1

    lod f32t, t1, PLAYER.jump_charge
    fadd t0, t1
    fclp t0, PLAYER.MIN_JUMP_CHARGE, PLAYER.MAX_JUMP_CHARGE
    str f32t, PLAYER.jump_charge, t0

    mov a0, Strings.jump_charge
    syscall SYS_PRINT_STRING
    fcti a0, t0
    syscall SYS_PRINT_LINE_INT

    @end:
    ret



#-------------------------------------------------------------------------------
sbmk "Player Jump"
player_jump:
    lod u8t, t0, PLAYER.grounded
    cmp eq, t0, true
    jfs @end+
    lod u8t, t0, PLAYER.parent_body_index
    cea bodies, t0, BODY.SIZE
    lod f32t, t0, PLAYER.x
    lod f32t, t1, PLAYER.y
    lod f32t, t2, PLAYER.velx
    lod f32t, t3, PLAYER.vely
    lde f32t, t4, BODY.X
    lde f32t, t5, BODY.Y

    # Calculate normal vector
    fsub t6, t0, t4 # dx
    fsub t7, t1, t5 # dy
    fpow t8, t6, 2.0
    fpow t9, t7, 2.0
    fadd t8, t9 # r^2
    fsqrt t8 # r
    fdiv t6, t8 # dx/r
    fdiv t7, t8 # dy/r
    lod f32t, t9, PLAYER.jump_charge
    fmul t6, t9
    fmul t7, t9
    fadd t2, t6
    fadd t3, t7
    str f32t, PLAYER.velx, t2
    str f32t, PLAYER.vely, t3
    str u8t, false, PLAYER.grounded

    @end:
    ret

#-------------------------------------------------------------------------------
bmk "Updates"

#-------------------------------------------------------------------------------
sbmk "Update Gravity"
update_gravity:
    # s0: body1 index
    # s1: body2 index
    vpsh s0..s3

    mov s3, zr # Strongest gravitational influence on player
    mov s0, zr
    @loop_bodies:
        lod u8t, t0, bodies_count
        cmp lt, s0, t0
        jfs @endloop_bodies+
        mov s1, zr

        # Other Bodies
        @loop2:
            lod u8t, t0, bodies_count
            cmp lt, s1, t0
            jfs @endloop2+
            cmp eq, s1, s0
            jtr @skip+

            cea bodies, s0, BODY.SIZE
            lde f32t, a0, BODY.X
            lde f32t, a1, BODY.Y
            lde f32t, a2, BODY.VX
            lde f32t, a3, BODY.VY
            lde f32t, a4, BODY.M
            cea bodies, s1, BODY.SIZE
            lde f32t, a5, BODY.X
            lde f32t, a6, BODY.Y
            lde f32t, a7, BODY.M

            mov t2, a2
            mov t3, a3
            vpsh t2..t3
            cal get_gravity_vector
            vpop t2..t3
            fadd t2, a0 # Apply acceleration
            fadd t3, a1

            cea bodies, s0, BODY.SIZE
            ste f32t, BODY.VX, t2
            ste f32t, BODY.VY, t3

            @skip:
            inc s1
            jmp @loop2-
        @endloop2:


        # Player
        lod f32t, a0, PLAYER.x
        lod f32t, a1, PLAYER.y
        lod f32t, a2, PLAYER.velx
        lod f32t, a3, PLAYER.vely
        lod f32t, a4, PLAYER.mass

        cea bodies, s0, BODY.SIZE
        lde f32t, a5, BODY.X
        lde f32t, a6, BODY.Y
        lde f32t, a7, BODY.M

        mov t2, a2
        mov t3, a3
        vpsh t2..t3
        cal get_gravity_vector
        vpop t2..t3
        fadd t2, a0 # Apply acceleration
        fadd t3, a1
        str f32t, PLAYER.velx, t2
        str f32t, PLAYER.vely, t3

        # Check strongest gravitational influence
        .update_parent_body:
            cmp fgt, a2, s3
            jfs @end+
            mov s2, s0
            mov s3, a2
        @end:
        str u8t, PLAYER.parent_body_index, s2

        inc s0
        jmp @loop_bodies-
    @endloop_bodies:
    vpop s0..s3
    ret

#-------------------------------------------------------------------------------
sbmk "Update Positions"
update_positions:
    # s0: body index

    psh s0
    mov s0, zr
    @loop_bodies:
        lod u8t, t0, bodies_count
        cmp lt, s0, t0
        jfs @endloop_bodies+

        cea bodies, s0, BODY.SIZE
        lde f32t, t0, BODY.X
        lde f32t, t1, BODY.Y
        lde f32t, t2, BODY.VX
        lde f32t, t3, BODY.VY

        fdiv t2, DISTANCE_SCALE
        fdiv t3, DISTANCE_SCALE
        lod f32t, t4, dt
        fmul t2, t4
        fmul t3, t4
        fmul t2, TIME_SCALE
        fmul t3, TIME_SCALE
        fadd t0, t2
        fadd t1, t3
        ste f32t, BODY.X, t0
        ste f32t, BODY.Y, t1

        inc s0
        jmp @loop_bodies-
    @endloop_bodies:

    lod f32t, t0, PLAYER.x
    lod f32t, t1, PLAYER.y
    lod f32t, t2, PLAYER.velx
    lod f32t, t3, PLAYER.vely

    lod f32t, t4, PLAYER.movex
    lod f32t, t5, PLAYER.movey
    fadd t2, t4
    fadd t3, t5
    fdiv t2, DISTANCE_SCALE
    fdiv t3, DISTANCE_SCALE
    lod f32t, t4, dt
    fmul t2, t4
    fmul t3, t4
    fmul t2, TIME_SCALE
    fmul t3, TIME_SCALE
    fadd t0, t2
    fadd t1, t3
    str f32t, PLAYER.x, t0
    str f32t, PLAYER.y, t1

    .if_grounded:
        lod u8t, cr, PLAYER.grounded
        jfs @end+
        lod f32t, t0, PLAYER.x
        lod f32t, t1, PLAYER.y
        lod u8t, t2, PLAYER.parent_body_index
        cea bodies, t2, BODY.SIZE
        lde f32t, t3, BODY.X
        lde f32t, t4, BODY.Y
        lde f32t, t5, BODY.R
        fdiv t5, DISTANCE_SCALE

        fsub t6, t0, t3 # dx
        fsub t7, t1, t4 # dy
        fpow t8, t6, 2.0
        fpow t9, t7, 2.0
        fadd t8, t9 # r^2
        fsqrt t8 # r
        fdiv t6, t8 # dx/r
        fdiv t7, t8 # dy/r
        ffma t6, t5, t3
        ffma t7, t5, t4
        str f32t, PLAYER.x, t6
        str f32t, PLAYER.y, t7
    @end:

    pop s0
    ret

#-------------------------------------------------------------------------------
sbmk "Update Collisions"
update_collisions:
    # s0: body1 index
    # s1..s2: body1 x,y
    # s3..s4: body1 vx, vy
    # s5: body1 radius
    # s6: body1 mass
    # s7: body2 index
    # s8..s9: body2 x,y
    # s10..s11: body2 vx, vy
    # s12: body2 radius
    # s13: body2 mass

    vpsh s0..s13

    mov s0, zr
    @loop_bodies:
        lod u8t, t0, bodies_count
        cmp lt, s0, t0
        jfs @endloop_bodies+
        mov s1, zr
        @loop2:
            lod u8t, t0, bodies_count
            cmp lt, s1, t0
            jfs @endloop2+
            cmp eq, s1, s0
            jtr @skip+
            mov a0, s0
            mov a1, s1
            cal check_collision
            jfs @skip+
            cea bodies, s0, BODY.SIZE
            lde f32t, t0, BODY.X
            lde f32t, t1, BODY.Y
            lde f32t, t2, BODY.VX
            lde f32t, t3, BODY.VY
            lde f32t, t4, BODY.M
            cea bodies, s1, BODY.SIZE
            lde f32t, t5, BODY.X
            lde f32t, t6, BODY.Y
            lde f32t, t7, BODY.VX
            lde f32t, t8, BODY.VY
            lde f32t, t9, BODY.M

            # Get collision vector
            fsub t10, t5, t0 # dx
            fsub t11, t6, t1 # dy
            fpow t0, t10, 2.0
            fpow t1, t11, 2.0
            fadd t1, t0
            fsqrt t1 # r
            fdiv t0, t10, t1 # normal vector
            fdiv t1, t11, t1

            # Get relative velocity vector
            fsub t2, t7, t2 # rvx
            fsub t3, t8, t3 # rvy

            # Calculate vn dot product
            fmul t2, t0
            fmul t3, t1
            fadd t2, t3 # dot product

            # Calculate impulse magnitude
            fmul t3, -(1.0 + BODY_ELASTICITY), t2
            fdiv t6, 1.0, t4 # 1/m1
            fdiv t7, 1.0, t9 # 1/m2
            fadd t6, t7
            fdiv t3, t6 # impulse magnitude

            # Calculate impulse vector
            fmul t0, t3
            fmul t1, t3

            # Apply impulses
            mov a0, t0
            mov a1, t1
            vpsh t0..t1
            mov a2, s1
            cal apply_impulse
            vpop t0..t1
            fmul a0, -1.0, t0
            fmul a1, -1.0, t1
            mov a2, s0
            cal apply_impulse

            @skip:
            inc s1
            jmp @loop2-
        @endloop2:

        # Player collision
        .if_player_colldiing:
            lod u8t, t0, player_check_collision
            cmp eq, t0, true
            jfs @endif+
            mov a0, s0
            cal check_player_collision
            jfs @else+
            cea bodies, s0, BODY.SIZE
            lde f32t, t0, BODY.X
            lde f32t, t1, BODY.Y
            lde f32t, t4, BODY.R
            lod f32t, t5, PLAYER.x
            lod f32t, t6, PLAYER.y

            # Calculate Distance
            fsub t7, t5, t0 # dx
            fsub t8, t6, t1 # dy
            fpow t9, t7, 2.0
            fpow t10, t8, 2.0
            fadd t9, t10 # r^2
            fsqrt t9 # r
            fdiv t7, t9 # Normal vector
            fdiv t8, t9

            fdiv t10, t4, DISTANCE_SCALE
            ffma t11, t7, t10, t0 # Move player to radius
            ffma t12, t8, t10, t1
            mov a0, t11
            mov a1, t12
            cal set_player_position

            lod f32t, t0, PLAYER.velx
            lod f32t, t1, PLAYER.vely
            cea bodies, s0, BODY.SIZE
            lde f32t, t2, BODY.VX
            lde f32t, t3, BODY.VY


            # Calculate horizontal vector by rotating normal vector
            #fneg t4, t8 # b1
            #mov t5, t7 # b2

            ## Find projection of player velocity along horizontal vector
            #fmul t6, t0, t4
            #fmul t7, t1, t5
            #fadd t6, t7 # a . b
            #fmul t8, t4, t4
            #fmul t9, t5, t5
            #fadd t8, t9
            #fdiv t6, t8 # a . b / b . b
            #fmul t4, t6
            #fmul t5, t6
            #fadd t4, t2
            #fadd t5, t3

            str f32t, PLAYER.velx, t2
            str f32t, PLAYER.vely, t3




            str u8t, PLAYER.grounded, true
            str u8t, player_check_collision, false
            jmp @endif+
        @else:
            str u8t, PLAYER.grounded, false
        @endif:

        inc s0
        jmp @loop_bodies-
    @endloop_bodies:

    vpop s0..s13
    ret

#-------------------------------------------------------------------------------
sbmk "Move Camera"
move_camera:
    # > a0..a1: Camera offset

    mov t15, zr # Object counter
    lod u8t, t14, bodies_count
    @loop:
        cmp lt, t15, t14
        jfs @endloop+

        cea bodies, t15, BODY.SIZE
        lde f32t, t0, BODY.X
        lde f32t, t1, BODY.Y
        fadd t0, a0
        fadd t1, a1
        ste f32t, BODY.X, t0
        ste f32t, BODY.Y, t1

        inc t15
        jmp @loop-
    @endloop:

    ret

#-------------------------------------------------------------------------------
sbmk "Center Camera"
center_camera:
    lod f32t, t0, PLAYER.x
    lod f32t, t1, PLAYER.y

    fsub a0, CENTER_X_F, t0
    fsub a1, CENTER_Y_F, t1
    cal move_camera
    str f32t, PLAYER.x, CENTER_X_F
    str f32t, PLAYER.y, CENTER_Y_F
    ret

sbmk "Set Player Position"
set_player_position: # Move player and recenter camera
    # > a0..a1: new x, y position



    ret

#-------------------------------------------------------------------------------
bmk "Drawing"

#-------------------------------------------------------------------------------
sbmk "Draw Player"
draw_player:
    #def .SPRITE_WIDTH 16

    #mov a0, PLAYER_SPRITESHEET

    lod f32t, t0, PLAYER.x
    lod f32t, t1, PLAYER.y
    fcti a1, t0
    fcti a2, t1

    .is_offscreen:
        cmp lt, a1, 0
        jtr @end+
        cmp lt, a2, 0
        jtr @end+
        cmp lt, a1, SCREEN_WIDTH
        jfs @end+
        cmp lt, a2, SCREEN_HEIGHT
        jfs @end+
        sbpx a1, a2, 255
    @end:
    #lod f32t, t2, PLAYER.rot
    #fdiv t2, PI/4.0
    #fcti t2
    #mul t2, .SPRITE_WIDTH
    #mov a3, t2
    #mov a4, 16
    #mov a5, .SPRITE_WIDTH
    #mov a6, .SPRITE_WIDTH
    #lod u8t, a7, PLAYER.flipped
    #syscall SYS_DRAW_TEXTURE_REGION


    ret

#-------------------------------------------------------------------------------
sbmk "Draw Bodies"
draw_bodies:
    # s0: body index
    psh s0

    mov s0, zr
    @loop:
        lod u8t, t0, bodies_count
        cmp lt, s0, t0
        jfs @endloop+

        cea bodies, s0, BODY.SIZE
        lde f32t, a0, BODY.X
        lde f32t, a1, BODY.Y
        lde f32t, a2, BODY.R
        fdiv a2, DISTANCE_SCALE
        mov a3, BODY_LUMA
        cal draw_circle

        inc s0
        jmp @loop-
    @endloop:
    pop s0
    ret

#-------------------------------------------------------------------------------
sbmk "Draw Circle"
draw_circle:
    # > (f32t) a0..a1: x,y center
    # > (f32t) a2: radius
    # > (u8t) a3: luma

    .is_circle_offscreen:
        fadd t0, a0, a2
        cmp flt, t0, 0.0
        jtr @end+
        fadd t0, a1, a2
        cmp flt, t0, 0.0
        jtr @end+
        fsub t0, a0, a2
        cmp fgt, t0, SCREEN_WIDTH_F
        jtr @end+
        fsub t0, a1, a2
        cmp fgt, t0, SCREEN_HEIGHT_F
        jtr @end+

    fdiv t14, 1.0, a2 # How much to increment angle by
    mov t15, zr # t15: angle
    @loop:
        fcos t0, t15 # t0: r*cos(t) = x
        ffma t0, a2, a0
        fsin t1, t15 # t1: r*sin(t) = y
        ffma t1, a2, a1
        fcti t0
        fcti t1
        .if_in_bounds:
            cmp gt, t0, 0
            jfs @endif+
            cmp gt, t1, 0
            jfs @endif+
            cmp lt, t0, SCREEN_WIDTH
            jfs @endif+
            cmp lt, t1, SCREEN_HEIGHT
            jfs @endif+
            sbpx t0, t1, a3
        @endif:
        fadd t15, t14 # increment angle
        cmp fgt, t15, 2.0*PI
        jtr @end+
        jmp @loop-
    @end:
    ret

#-------------------------------------------------------------------------------
sbmk "Draw Line"
draw_line:
    # > a0..a1: start x,y
    # > a2..a3: end x,y

    ret

#-------------------------------------------------------------------------------
bmk "Physics"

#-------------------------------------------------------------------------------
sbmk "Check Collision"
check_collision:
    # > a0: body1 index
    # > a1: body2 index
    cea bodies, a0, BODY.SIZE
    lde f32t, t0, BODY.X
    lde f32t, t1, BODY.Y
    lde f32t, t2, BODY.VX
    lde f32t, t3, BODY.VY
    lde f32t, t4, BODY.R

    cea bodies, a1, BODY.SIZE
    lde f32t, t5, BODY.X
    lde f32t, t6, BODY.Y
    lde f32t, t7, BODY.VX
    lde f32t, t8, BODY.VY
    lde f32t, t9, BODY.R

    # Apply deltatime
    lod f32t, t10, dt
    fmul t2, t10
    fmul t3, t10
    fmul t7, t10
    fmul t8, t10

    # Apply distance scale
    fdiv t2, DISTANCE_SCALE
    fdiv t3, DISTANCE_SCALE
    fdiv t7, DISTANCE_SCALE
    fdiv t8, DISTANCE_SCALE

    # Add velocities
    fadd t0, t2
    fadd t1, t3
    fadd t5, t7
    fadd t6, t8

    # Calculate Distance
    fsub t2, t5, t0 # dx
    fsub t3, t6, t1 # dy
    fpow t2, 2.0
    fpow t3, 2.0
    fadd t2, t3 # r^2
    fsqrt t2 # r

    # Add Radii
    fadd t4, t9
    fdiv t4, DISTANCE_SCALE

    # Check if distance is less than radii
    cmp flt, t2, t4
    ret

#-------------------------------------------------------------------------------
sbmk "Check Player Collision"
check_player_collision:
    # > a0: body index
    cea bodies, a0, BODY.SIZE
    lde f32t, t0, BODY.X
    lde f32t, t1, BODY.Y
    lde f32t, t2, BODY.VX
    lde f32t, t3, BODY.VY
    lde f32t, t4, BODY.R

    lod f32t, t5, PLAYER.x
    lod f32t, t6, PLAYER.y
    lod f32t, t7, PLAYER.velx
    lod f32t, t8, PLAYER.vely

    # Apply deltatime
    lod f32t, t10, dt
    fmul t2, t10
    fmul t3, t10
    fmul t7, t10
    fmul t8, t10

    # Apply distance scale
    fdiv t2, DISTANCE_SCALE
    fdiv t3, DISTANCE_SCALE
    fdiv t7, DISTANCE_SCALE
    fdiv t8, DISTANCE_SCALE

    # Add velocities
    fadd t0, t2
    fadd t1, t3
    fadd t5, t7
    fadd t6, t8

    # Calculate Distance
    fsub t2, t0, t5 # dx
    fsub t3, t1, t6 # dy
    fpow t2, 2.0
    fpow t3, 2.0
    fadd t2, t3 # r^2
    fsqrt t2 # r

    # Apply distance scale
    fdiv t4, DISTANCE_SCALE

    # Check if distance is less than body radius
    cmp flt, t2, t4
    ret

#-------------------------------------------------------------------------------
sbmk "Get Gravity Vector"
get_gravity_vector:
    # > a0..a1: object1 pos
    # > a2..a3: object1 velocity
    # > a4: object1 mass
    # > a5..a6: object2 pos
    # > a7: object2 mass
    # < a0..a1: Acceleration vector
    # < a2: Force

    # Calculate Distance
    fsub t0, a5, a0 # dx
    fsub t1, a6, a1 # dy
    fpow t2, t0, 2.0
    fpow t3, t1, 2.0
    fadd t2, t3 # r^2

    # Normal Vector
    fsqrt t3, t2 # r
    fdiv t0, t3 # dx/r
    fdiv t1, t3 # dy/r

    # Scale Distance
    fmul t3, DISTANCE_SCALE
    fpow t2, t3, 2.0 # r^2

    # Calculate gravitational acceleration
    fmul t3, a7, G # G*m2 since we'll be dividing by m1 anyway, no point including it
    fdiv t3, t2

    # Apply dt
    lod f32t, t4, dt
    fmul t3, t4

    # Apply timescale
    fmul t3, TIME_SCALE

    # Get acceleration vector
    fmul a0, t0, t3
    fmul a1, t1, t3
    mov a2, t3

    ret

#-------------------------------------------------------------------------------
sbmk "Apply Impulse"
apply_impulse:
    # > a0..a1: impulse vector
    # > a2: body index

    cea bodies, a2, BODY.SIZE
    lde f32t, t0, BODY.VX
    lde f32t, t1, BODY.VY
    lde f32t, t2, BODY.M

    fdiv t3, a0, t2
    fdiv t4, a1, t2
    fadd t0, t3
    fadd t1, t4

    ste f32t, BODY.VX, t0
    ste f32t, BODY.VY, t1

    ret

#-------------------------------------------------------------------------------
bmk "Calculations"

#-------------------------------------------------------------------------------
sbmk "Get Angle"
get_angle:
    # > a0..a1: vector x, y
    # < a0: angle in radians

    .if_x_0: # If x is 0
        cmp eq, a0, 0
        jfs @endif+
        mov a0, PI/2.0
        cmp flt, a1, 0
        mvc a0, 3.0*(PI/2.0)
        ret
    @endif:

    fdiv t0, a1, a0 # y/x
    fatan t0 # atan(y/x)

    .if_x_neg:
        cmp flt, a0, 0
        jfs @end+
        fadd t0, PI
    @end:

    fadd t0, 2.0*PI # Convert to interval 0-2PI
    fmod a0, t0, 2.0*PI
    ret
