# Built-in process entry points.
# The kernel runs these processes automatically.
# Each process must end with an 'exit' instruction.

#-------------------------------------------------------------------------------
bmk "About"

# This is primarily a 2D n-body gravity simulation, but it also features
# a playable character with which to jump around the various gravitational bodies.

# The code is absolutely messy, partially due to my inexperience and partially due to me switching to
# using relative positioning and velocities far into it's development, so apologies to those more experienced lol

# Some credit goes to Flatik, who uploaded a similar gravity simulation. Although none
# of the code was copied (despite how surprisingly similar certain elements turned out)
# I did incorporate some of their optimizations in a small few places, so I'd like to
# give them a shoutout nonetheless :)

# Controls:
# BTN_UP / BTN_DOWN / BTN_LEFT / BTN_RIGHT: Movement
# BTN_A: Jump away from the body you're standing on.
# BTN_B: Match player velocity relative to the "global" context. If used on a planet, slow your movement speed (useful for low-grav bodies)
# BTN_X: Zoom the camera in or out


#-------------------------------------------------------------------------------
bmk "DATA"

PLAYER_SPRITESHEET: emb file "assets/astronaut.png" # To be implemented
def PLAYER_SPRITE_WIDTH 8
def PLAYER_SPRITE_WIDTH_F 8.0
BACKGROUND_TEXTURE: emb file "assets/background_simple.png"
def BG_TEX_WIDTH 320
def BG_TEX_HEIGHT 240
def BG_TEX_WIDTH_F 320.0
def BG_TEX_HEIGHT_F 240.0
HUD_TEXTURE: emb file "assets/hud_compact.png"


#-------------------------------------------------------------------------------
bmk "CONSTANTS"

# Simulation
def G 1.0 # This makes gravity a lot stronger but more fun :)
#def G 6.6743*(10**-11)
def MAX_BODIES 20
def BODY_ELASTICITY 0.8

def SCREEN_WIDTH_F 320.0
def SCREEN_HEIGHT_F 240.0
def CENTER_X_F SCREEN_WIDTH_F/2.0
def CENTER_Y_F SCREEN_HEIGHT_F/2.0

def GROUNDED_PLAYER_COLLISION_MARGIN 2.0
    # How far a grounded player must be before no longer being considered grounded

#-------------------------------------------------------------------------------
sbmk "Simulation Settings"

def TIME_SCALE 1.0 # How fast the simulation runs. Must be greater than 0 or things dont work

#-------------------------------------------------------------------------------
sbmk "Visualization Settings"

def ZOOM_STEP 2.0 # How much to change zoom when zoom commands are input
def MAX_ZOOM 71.0 # Keep this at an odd number to avoid issues with sprite selection
def MIN_ZOOM 1.0
def CAMERA_SPEED 0.5
def CAMERA_OFFSET 50.0
def GROUNDED_DISTANCE 1.0
    # How far the player must be from the parent body before the camera
    # centers on them, relative to the square root of the body's radius

def DRAW_BODY_VELOCITIES false # Draw velocity vectors for bodies (relative to the player)
def DRAW_PLAYER_VELOCITY false # Draw velocity vector for the player (relative to the 'global position')
def DRAW_ROTATIONAL_VELOCITY false # Add visual indicator to show planet rotation
def VELOCITY_VISUAL_SCALE 1.0 # How much velocity vectors should be scaled
def VELOCITY_VECTOR_START_LUMA 10
def VELOCITY_VECTOR_END_LUMA 255

def CHARGE_BAR_LENGTH 8

def BG_SCROLL_SCALE 0.1 # How much the background moves relative to the foreground


#-------------------------------------------------------------------------------
sbmk "Input Bindings"

Input:
    def .JUMP BTN_A
    def .MATCH_VELOCITY BTN_B
    def .ZOOM_IN BTN_X
    def .ZOOM_OUT BTN_Y
    def .PAUSE BTN_START

#-------------------------------------------------------------------------------
bmk "STRUCTS"

#-------------------------------------------------------------------------------
sbmk "Player"

PLAYER:
    # Constants
    def .MOVE_SPEED 100.0
    def .THRUSTER_STRENGTH 100.0
    def .MIN_JUMP_CHARGE 50.0
    def .MAX_JUMP_CHARGE 200.0
    def .JUMP_CHARGE_SPEED (.MAX_JUMP_CHARGE-.MIN_JUMP_CHARGE)/0.8
    def .SMOKE_SPAWN_COOLDOWN 0.01 # How often smoke is produced while flying
    # Properties
    ## Physics
    .x: emb f32t 0.0 # X Position
    .y: emb f32t 0.0 # Y Position
    .velx: emb f32t 0.0 # X Velocity (km/s)
    .vely: emb f32t -0.001 # Y Velocity (km/s) This is just to make the player face up at start
    .movex: emb f32t 0.0 # X Move Velocity
    .movey: emb f32t 0.0 # Y Move Velocity
    .rot: emb f32t 0.0 # Rotation (Radians)
    .mass: emb f32t 7.0 # Mass (kg)
    .collision_radius: emb f32t PLAYER_SPRITE_WIDTH_F/2.0 # Radius of collision circle

    .is_grounded: emb u8t false
    .is_flying: emb u8t false # Player is moving in the air
    .is_charging: emb u8t false # Player is charging a jump
    .can_jump: emb u8t true
    .jump_charge: emb f32t PLAYER.MIN_JUMP_CHARGE
    .smoke_cooldown_timer: emb f32t 0.0

    .parent_body_index: emb i8t -1 # -1 means no parent body has been found (only really applicable if no bodies exist)
    .flip_sprite: emb u8t false

#-------------------------------------------------------------------------------
sbmk "Body"

BODY:
    # Properties
    .x: emb f32t 0.0 # X Position (km)
    .y: emb f32t 0.0 # Y Position (km)
    .velx: emb f32t 0.0 # X Velocity (km/s)
    .vely: emb f32t 0.0 # Y Velocity (km/s)
    .rot: emb f32t 0.0 # Rotation (radians)
    .rot_av: emb f32t 0.0 # Rotational Angular Velocity (rad/s)
    .radius: emb f32t 1.0 # Radius (km)
    .mass: emb f32t 1.0 # Mass (kg)
    .luminosity: emb u16t 150   # Visual brightness. Although luma are constrained from 0-255,
                                # objects are darker at higher distance scales, so a higher
                                # luminosity will maintain brightness at greater distances
    # Offsets
    def .X (.x - BODY)
    def .Y (.y - BODY)
    def .VX (.velx - BODY)
    def .VY (.vely - BODY)
    def .ROT (.rot - BODY) # Rotation
    def .ROT_AV (.rot_av - BODY)
    def .R (.radius - BODY)
    def .M (.mass - BODY)
    def .LUM (.luminosity - BODY)
    def .SIZE ($ - BODY)

#-------------------------------------------------------------------------------
sbmk "Smoke Particle"

SMOKE:
    # Constants
    def .MAX_SMOKE_COUNT 60
    def .MIN_VEL_SCALE 1.0
    def .MAX_VEL_SCALE 2.0
    def .MIN_ANGLE_OFFSET -PI/8
    def .MAX_ANGLE_OFFSET PI/8
    def .DEFAULT_LIFESPAN 0.5

    # Properties
    .x: emb f32t 0.0 # X Position
    .y: emb f32t 0.0 # Y Position
    .velx: emb f32t 0.0 # X Velocity (km/s)
    .vely: emb f32t 0.0 # Y Velocity (km/s)
    .lifespan: emb f32t 10.0
    # Offsets
    def .X (.x - SMOKE)
    def .Y (.y - SMOKE)
    def .VX (.velx - SMOKE)
    def .VY (.vely - SMOKE)
    def .LIFESPAN (.lifespan - SMOKE)
    def .SIZE ($ - SMOKE)


#-------------------------------------------------------------------------------
sbmk "Misc."


Commands:
    .ZOOM_IN: emb string "ZOOM_IN"
    .ZOOM_OUT: emb string "ZOOM_OUT"

Strings:
    .jump_charge: emb string "Jump Charge: "
    .zoom: emb string "Set Distance Scale to: "

#-------------------------------------------------------------------------------
bmk "VARIABLES"

distance_scale: emb f32t 1.0 # Camera Zoom
dt: emb f32t 0.0 # DeltaTime
bg_offset_x: emb f32t 0.0
bg_offset_y: emb f32t 0.0
# Velocities are updated to be relative to the player
global_velx: emb f32t 0.0
global_vely: emb f32t 0.0

control_camera_offset_scalar: emb i8t 0 # -1, 1, or 1, used for controlling the camera with up and down

# Arrays

buffer: res u8t MAX_TERMINAL_INPUT_SIZE

bodies: res u8t BODY.SIZE*MAX_BODIES
bodies_count: emb u8t 0

smoke: res u8t SMOKE.SIZE*SMOKE.MAX_SMOKE_COUNT

# Flags
system_paused: emb u8t false # Used for pausing the game
smoke_can_spawn: emb u8t false
#zoom_toggled: emb u8t true

#-------------------------------------------------------------------------------
bmk "-------------------------"

#-------------------------------------------------------------------------------
bmk "PROCESSES"

#-------------------------------------------------------------------------------
sbmk "Start"
_start: # Runs once when the VM starts.
    # Initialize your game state here.

    mov a0, -21000.0 # X
    mov a1, 0.0 # Y
    mov a2, 0.0 # VELOCITY X
    mov a3, 0.0 # VELOCITY Y
    mov a4, 0.000003 # ROTATIONAL ANGULAR VELOCITY
    mov a5, 15000.0 # RADIUS
    mov a6, 20000000000.0 # MASS
    mov a7, 50000 # LUMINOSITY
    cal add_body

    mov a0, 0.0 # X
    mov a1, 0.0 # Y
    mov a2, 0.0 # VELOCITY X
    mov a3, 975.9 # VELOCITY Y
    mov a4, 2*PI/60 # ROTATIONAL ANGLUAR VELOCITY
    mov a5, 500.0 # RADIUS
    mov a6, 600000.0 # MASS
    mov a7, 150 # LUMINOSITY
    cal add_body

    mov a0, -350.0 # X
    mov a1, 0.0 # Y
    mov a2, 0.0 # VELOCITY X
    mov a3, 975.9 - 41.4 # VELOCITY Y
    mov a4, 2*PI/5 # ROTATIONAL ANGULAR VELOCITY
    mov a5, 10.0 # RADIUS
    mov a6, 50000.0 # MASS
    mov a7, 150 # LUMINOSITY
    cal add_body

    mov a0, -21000.0 + 10500.0 # X
    mov a1, 0.0 # Y
    mov a2, 0.0 # VELOCITY X
    mov a3, 1380.13 # VELOCITY Y
    mov a4, 2*PI # ROTATIONAL ANGULAR VELOCITY
    mov a5, 10.0 # RADIUS
    mov a6, 7000.0 # MASS
    mov a7, 200 # LUMINOSITY
    cal add_body

    mov a0, false
    cal center_camera

    exit

#-------------------------------------------------------------------------------
sbmk "Update"
_update: # Runs at 60 Hz.
    # Write your game logic here.
    syscall SYS_GET_UPDATE_DELTA
    str f32t, dt, a0

    cmp flt, a0, 1.0 # Skip this update if the framerate is too low to avoid physics issues
    jfs @pause_end+
    lod u8t, cr, system_paused
    jtr @pause_end+

    str u8t, smoke_can_spawn, false

    psh s0
    mov s0, zr
    cal update_gravity
    cal check_input
    cal update_velocities
    cal update_positions
    cal update_collisions
    cal update_smoke
    @iterate_update: # Iterate for larger timescales
        fadd s0, 1.0
        cmp flt, s0, TIME_SCALE
        jfs @end+
        cal update_gravity
        cal update_collisions
        cal update_velocities
        cal update_positions
        cal update_smoke
        jmp @iterate_update-
    @end:
    mov a0, true
    cal center_camera
    pop s0
    @pause_end:


    #lod u8t, a0, PLAYER.is_grounded
    #syscall SYS_PRINT_LINE_INT

    exit

#-------------------------------------------------------------------------------
sbmk "Draw"
_draw: # Runs at 60 Hz and updates the front buffer.
    # Draw graphics to the screen here.
    cal draw_background
    cal draw_smoke
    cal draw_bodies
    cal draw_player
    cal draw_hud
    exit

#-------------------------------------------------------------------------------
sbmk "Input"
_input: # Runs when input state changes.
    # React to player input here.

    vpsh s0..s2
    syscall SYS_GET_INPUT

    # Zoom in
    and t0, a0, Input.ZOOM_IN
    cmp neq, t0, 0
    mov s0, cr

    # Zoom out
    and t0, a0, Input.ZOOM_OUT
    cmp neq, t0, 0
    mov s1, cr

    sub t0, s1, s0
    fctf s0, t0

    # Pause
    and t0, a0, Input.PAUSE
    cmp neq, t0, 0
    mov s2, cr

    @zoom:
        cmp neq, s0, 0.0
        jfs @end+
        fmul s0, ZOOM_STEP
        lod f32t, a0, distance_scale
        mov t2, 1.0
        cmp fgt, a0, 7.0
        mvc t2, 2.0
        fmul s0, t2
        mov t1, a0
        fadd a0, s0
        fclp a0, MIN_ZOOM, MAX_ZOOM
        cmp eq, t1, a0 # Don't call if nothing changed
        jtr @end+
        cal set_distance_scale
        mov a0, Strings.zoom
        mov a1, 1
        syscall SYS_PRINT_STRING
        lod f32t, a0, distance_scale
        syscall SYS_PRINT_LINE_FLOAT
    @end:

    @toggle_pause:
        mov cr, s2
        jfs @end+
        lod u8t, t0, system_paused
        cmp eq, t0, false
        str u8t, system_paused, cr
    @end:

    vpop s0..s2
    exit

#-------------------------------------------------------------------------------
sbmk "Terminal Input"
_terminal_input:
    # Reads the terminal input string into memory.
    mov a0, buffer
    mov a1, MAX_TERMINAL_INPUT_SIZE
    syscall SYS_READ_TERMINAL_INPUT
    cal check_commands
    exit

#-------------------------------------------------------------------------------
bmk "-------------------------"

#-------------------------------------------------------------------------------
bmk "FUNCTIONS"


#-------------------------------------------------------------------------------
bmk "Spawning"

#-------------------------------------------------------------------------------
sbmk "Spawn Body"
add_body:
    # > (f32t) a0..a1: x, y position (from center of screen)
    # > (f32t) a2..a3: x, y velocity
    # > (f32t) a4: rotation speed
    # > (f32t) a5: radius
    # > (f32t) a6: mass
    # > (u8t)  a7: luma

    # Step by step instructions to add a new planet or moon with a stable circular orbit:
    #   1. Define P (Parent position), Vp (Parent velocity), M (Parent mass),
    #       m (desired mass), and r (Orbital distance)
    #   2. Pick desired angle t around parent body
    #   3. Compute body position p = P + r*(cos(t), sin(t))
    #   4. Compute tangent vector Vt = (-sin(t), cos(t))
    #   5. Compute orbital velocity v = sqrt(G*M/r) -> This is the formula for a circular orbit
    #   6. Compute final velocity vector V = Vp + (Vt*v)
    #
    # If the body is a moon/satellite of a child body, use the Hill's radius (the distance by which
    # a satellite's attraction to its parent is greater than its attraction to its grandparent)
    # to determine what the maximum distance of a (usually) stable orbit.
    #
    #   For a given r (distance from parent), m (parent mass), and M (grandparent mass),
    #   the formula for the Hill's radius is:
    #
    #       rH = r*(m/3*M)^(1/3) km
    #
    #   This value can be scaled lower to ensure greater stability. A recommended scalar is 1/3.
    #       (NOTE: This is only useful for ensuring a star will not disturb a moon's orbit.
    #               Other planets can still disrupt the orbit if close enough!)

    lod u8t, t0, bodies_count
    cmp lt, t0, MAX_BODIES
    jfs @end+

    cea bodies, t0, BODY.SIZE
    lod f32t, t1, PLAYER.x
    lod f32t, t2, PLAYER.y
    fsub t4, t1, a0 # Avoid objects being in the same coordinate to avoid issues
    fsub t5, t2, a1
    fadd t4, t5
    @if_body_on_player:
        cmp eq, t4, 0.0
        jfs @endif+
        fsub t2, a5
        str f32t, PLAYER.x, t1
        str f32t, PLAYER.y, t2
        str u8t, PLAYER.is_grounded, true
    @endif:
    ste f32t, BODY.X, a0 # Set X pos
    ste f32t, BODY.Y, a1 # Set Y pos
    ste f32t, BODY.VX, a2 # Set X velocity (km/s)
    ste f32t, BODY.VY, a3 # Set Y velocity (km/s)
    ste f32t, BODY.ROT, 0.0 # Set body rotation
    ste f32t, BODY.ROT_AV, a4 # Set body rotational angular velocity (rad/s)
    ste f32t, BODY.R, a5 # Set body radius (km)
    ste f32t, BODY.M, a6 # Set mass (kg)
    ste u16t, BODY.LUM, a7 # Set luminosity

    inc t0
    str u8t, bodies_count, t0
    @end:
    ret

#-------------------------------------------------------------------------------
sbmk "Spawn Smoke"
spawn_smoke:
    # > a0: smoke index
    # > a1..a2: min/max angle offset
    # > a3..a4: min/max velocity scale

    lod f32t, t0, PLAYER.x
    lod f32t, t1, PLAYER.y
    lod f32t, t2, PLAYER.velx
    lod f32t, t3, PLAYER.vely
    lod f32t, t4, PLAYER.rot
    lod f32t, t5, PLAYER.collision_radius

    fadd t4, PI
    frnd t7, a1, a2
    fadd t6, t4, t7
    fcos t7, t6
    fsin t8, t6
    frnd t9, a3, a4
    fmul t9, PLAYER.THRUSTER_STRENGTH
    fmul t7, t9
    fmul t8, t9
    # Position offset vector
    fcos t2, t4
    fsin t3, t4
    fmul t2, t5
    fmul t3, t5
    lod f32t, t10, distance_scale
    fdiv t2, t10
    fdiv t3, t10
    fadd t2, t0
    fadd t3, t1

    cea smoke, a0, SMOKE.SIZE
    ste f32t, SMOKE.X, t2
    ste f32t, SMOKE.Y, t3
    ste f32t, SMOKE.VX, t7
    ste f32t, SMOKE.VY, t8
    ste f32t, SMOKE.LIFESPAN, SMOKE.DEFAULT_LIFESPAN

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

            vpsh a2..a7
            vmov a2..a4, a5..
            cal get_gravity_vector
            # Apply dt and timescale
            lod f32t, t4, dt
            @if_timescale_lt_1:
                cmp flt, TIME_SCALE, 1.0
                jfs @endif+
                fmul t4, TIME_SCALE
            @endif:
            fmul a0, t4
            fmul a1, t4
            vpop a2..a7
            fadd a2, a0 # Apply acceleration
            fadd a3, a1

            cea bodies, s0, BODY.SIZE
            ste f32t, BODY.VX, a2
            ste f32t, BODY.VY, a3

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

        vpsh a2..a7
        vmov a2..a4, a5..
        cal get_gravity_vector
        # Apply dt and timescale
        lod f32t, t4, dt
        @if_timescale_lt_1:
            cmp flt, TIME_SCALE, 1.0
            jfs @endif+
            fmul t4, TIME_SCALE
        @endif:
        fmul a0, t4
        fmul a1, t4
        mov t1, a2
        vpop a2..a7
        fadd a2, a0 # Apply acceleration
        fadd a3, a1
        str f32t, PLAYER.velx, a2
        str f32t, PLAYER.vely, a3

        # Check strongest gravitational influence
        @if_player_not_grounded:
            lod u8t, t0, PLAYER.is_grounded
            mov cr, t0
            jtr @endif+
            @update_parent_body:
                cmp fgt, t1, s3
                jfs @end+
                mov s2, s0
                mov s3, t1
            @end:
            str i8t, PLAYER.parent_body_index, s2
        @endif:

        inc s0
        jmp @loop_bodies-
    @endloop_bodies:
    vpop s0..s3
    ret

#-------------------------------------------------------------------------------
sbmk "Update Positions"
update_positions:
    # s0: body index
    # s1: deltatime
    # s2: distance_scale
    vpsh s0..s2

    lod f32t, s1, dt
    lod f32t, s2, distance_scale

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
        lde f32t, t4, BODY.ROT
        lde f32t, t5, BODY.ROT_AV

        # Apply distance scale
        fdiv t2, s2
        fdiv t3, s2

        # Apply deltatime
        fmul t2, s1
        fmul t3, s1
        fmul t5, s1

        # Apply timescale
        @if_timescale_lt_1:
            cmp flt, TIME_SCALE, 1.0
            jfs @endif+
            fmul t2, TIME_SCALE
            fmul t3, TIME_SCALE
            fmul t5, TIME_SCALE
        @endif:
        fadd t0, t2
        fadd t1, t3
        fadd t4, t5
        ste f32t, BODY.X, t0
        ste f32t, BODY.Y, t1
        ste f32t, BODY.ROT, t4

        inc s0
        jmp @loop_bodies-
    @endloop_bodies:


    # Player position
    lod f32t, t0, PLAYER.x
    lod f32t, t1, PLAYER.y
    lod f32t, t2, PLAYER.velx
    lod f32t, t3, PLAYER.vely

    @if_grounded:
        lod u8t, cr, PLAYER.is_grounded
        jfs @endif+
        lod f32t, t4, PLAYER.movex
        lod f32t, t5, PLAYER.movey
        fadd t2, t4
        fadd t3, t5

    @endif:

    # Apply distance scaling
    fdiv t2, s2
    fdiv t3, s2

    # Apply deltatime
    fmul t2, s1
    fmul t3, s1
    @if_timescale_lt_1:
        cmp flt, TIME_SCALE, 1.0
        jfs @endif+
        fmul t2, TIME_SCALE
        fmul t3, TIME_SCALE
    @endif:
    fadd t0, t2
    fadd t1, t3
    str f32t, PLAYER.x, t0
    str f32t, PLAYER.y, t1

    # Update player rotation
    @if_is_flying:
        lod u8t, cr, PLAYER.is_flying
        jtr @endif+
    @else:
    @if_close_to_ground:
        lod f32t, t0, PLAYER.x
        lod f32t, t1, PLAYER.y
        lod i8t, t2, PLAYER.parent_body_index
        cmp lt, t2, 0
        jtr @else+
        cea bodies, t2, BODY.SIZE
        lde f32t, t2, BODY.X
        lde f32t, t3, BODY.Y

        # Get angle and distance
        fsub t4, t1, t3
        fsub t5, t0, t2
        fpow t6, t4, 2.0
        fpow t7, t5, 2.0
        fadd t6, t7
        fsqrt t6
        lde f32t, t7, BODY.R
        lod f32t, t8, PLAYER.collision_radius
        fadd t7, t8
        fsqrt t8, t7
        ffma t7, t8, GROUNDED_DISTANCE, t7
        fdiv t7, s2
        cmp flt, t6, t7
        jfs @endif+

        fatan2 t6, t4, t5
        fmod t6, 2.0*PI
        mov t7, 0.0
        cmp flt, t6, 0.0
        mvc t7, 2.0*PI
        fadd t6, t7
        str f32t, PLAYER.rot, t6
        jmp @endif+
    @else:
        lod f32t, t0, global_velx
        lod f32t, t1, global_vely
        fatan2 t2, t1, t0
        fmod t2, 2.0*PI
        mov t3, 0.0
        cmp flt, t2, 0.0
        mvc t3, 2.0*PI
        fadd t2, t3
        str f32t, PLAYER.rot, t2
    @endif:

    # Update camera/background
    lod f32t, t0, bg_offset_x
    lod f32t, t1, bg_offset_y
    lod f32t, t2, global_velx
    lod f32t, t3, global_vely
    fmul t2, s1
    fmul t3, s1
    fdiv t2, s2
    fdiv t3, s2
    fmul t2, BG_SCROLL_SCALE
    fmul t3, BG_SCROLL_SCALE
    fadd t0, t2
    fadd t1, t3
    fmod t0, BG_TEX_WIDTH_F
    fmod t1, BG_TEX_HEIGHT_F
    str f32t, bg_offset_x, t0
    str f32t, bg_offset_y, t1

    vpop s0..s2
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

            vpsh t0..t9
            vmov a0..a9, t0..
            cal get_collision_vector
            vpop t0..t9
            mov t0, a0
            mov t1, a1

            # Apply impulses
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
        inc s0
        jmp @loop_bodies-
    @endloop_bodies:

    # Player collisions
    mov s0, zr
    @loop:
        lod u8t, t0, bodies_count
        cmp lt, s0, t0
        jfs @endloop+
        @if_player_colliding:
            mov a0, s0
            cal check_player_collision
            jfs @endif+
            lod f32t, t0, PLAYER.x
            lod f32t, t1, PLAYER.y
            cea bodies, s0, BODY.SIZE
            lde f32t, t2, BODY.X
            lde f32t, t3, BODY.Y
            lde f32t, t4, BODY.R
            lde f32t, t5, BODY.VX
            lde f32t, t6, BODY.VY
            lde f32t, t7, BODY.ROT_AV

            # Get normal vector
            fsub a0, t0, t2 # dx
            fsub a1, t1, t3 # dy
            cal normal_vector

            lod f32t, t11, PLAYER.collision_radius
            fadd t4, t11
            lod f32t, t11, distance_scale
            fdiv t10, t4, t11
            ffma t11, a0, t10, t2 # Move player to radius
            ffma t12, a1, t10, t3
            str f32t, PLAYER.x, t11
            str f32t, PLAYER.y, t12

            str i8t, PLAYER.parent_body_index, s0

            # Angular velocity from planets rotation

            # Get tangent vector
            fneg t8, a1
            mov t9, a0

            # Calculate velocity vector
            fmul a2, t4, t7
            fmul t2, t8, a2
            fmul t3, t9, a2

            # Apply rotational angular velocity
            fadd t5, t2
            fadd t6, t3

            @if_just_collided:
                lod u8t, cr, PLAYER.is_grounded # Only apply collision impulse on impact
                jtr @end+
                lod f32t, a0, PLAYER.x
                lod f32t, a1, PLAYER.y
                lod f32t, a2, PLAYER.velx
                lod f32t, a3, PLAYER.vely
                lod f32t, a4, PLAYER.mass
                lde f32t, a5, BODY.X
                lde f32t, a6, BODY.Y
                lde f32t, a7, BODY.VX
                lde f32t, a8, BODY.VY
                lde f32t, a9, BODY.M
                cal get_collision_vector
                mov a2, s0
                cal apply_impulse
            @end:

            str f32t, PLAYER.velx, t5
            str f32t, PLAYER.vely, t6

            str u8t, PLAYER.is_grounded, true
            jmp @end+
        @endif:
        inc s0
        jmp @loop-
    @endloop:
        str u8t, PLAYER.is_grounded, false
    @end:

    vpop s0..s13
    ret

#-------------------------------------------------------------------------------
sbmk "Update Velocities"
update_velocities:
    # Recalculate velocities relative to the player

    # s0..s1: Player x,y velocity
    vpsh s0..s1

    lod f32t, s0, PLAYER.velx
    lod f32t, s1, PLAYER.vely


    mov t15, zr
    @loop_bodies:
        lod u8t, t0, bodies_count
        cmp lt, t15, t0
        jfs @endloop_bodies+

        cea bodies, t15, BODY.SIZE
        lde f32t, t0, BODY.VX
        lde f32t, t1, BODY.VY

        fsub t0, s0
        fsub t1, s1

        ste f32t, BODY.VX, t0
        ste f32t, BODY.VY, t1

        inc t15
        jmp @loop_bodies-
    @endloop_bodies:

    # Update Smoke
    mov t15, zr
    @loop:
        cmp lt, t15, SMOKE.MAX_SMOKE_COUNT
        jfs @endloop+
        cea smoke, t15, SMOKE.SIZE
        lde f32t, t0, SMOKE.VX
        lde f32t, t1, SMOKE.VY
        fsub t0, s0
        fsub t1, s1
        ste f32t, SMOKE.VX, t0
        ste f32t, SMOKE.VY, t1

        inc t15
        jmp @loop-
    @endloop:

    lod f32t, t0, global_velx
    lod f32t, t1, global_vely
    fadd t0, s0
    fadd t1, s1
    str f32t, global_velx, t0
    str f32t, global_vely, t1

    str f32t, PLAYER.velx, 0.0
    str f32t, PLAYER.vely, 0.0

    vpop s0..s1
    ret

#-------------------------------------------------------------------------------
sbmk "Update Smoke"
update_smoke:
    vpsh s0..s2

    mov s1, false # Can smoke spawn or not
    lod f32t, s2, PLAYER.smoke_cooldown_timer
    lod f32t, t0, dt
    @if_timescale_lt_1:
        cmp flt, TIME_SCALE, 1.0
        jfs @endif2+
        fmul t0, TIME_SCALE
    @endif2:
    fsub s2, t0 # Decrement cooldown timer
    str f32t, PLAYER.smoke_cooldown_timer, s2
    @if_timer_done:
        cmp fgt, s2, 0.0
        jtr @endif+
        mov s1, true
    @endif:

    mov s0, zr
    @loop:
        cmp lt, s0, SMOKE.MAX_SMOKE_COUNT
        jfs @endloop+
        cea smoke, s0, SMOKE.SIZE
        lde f32t, t0, SMOKE.X
        lde f32t, t1, SMOKE.Y
        lde f32t, t2, SMOKE.VX
        lde f32t, t3, SMOKE.VY
        lde f32t, t4, SMOKE.LIFESPAN

        .if_smoke_alive:
            cmp fgt, t4, 0.0
            jfs @else+
            lod f32t, t5, dt
            fmul t2, t5
            fmul t3, t5
            lod f32t, t6, distance_scale
            fdiv t2, t6
            fdiv t3, t6
            @if_timescale_lt_1:
                cmp flt, TIME_SCALE, 1.0
                jfs @endif2+
                fmul t2, TIME_SCALE
                fmul t3, TIME_SCALE
                fmul t5, TIME_SCALE
            @endif2:
            fadd t0, t2
            fadd t1, t3
            fsub t4, t5
            ste f32t, SMOKE.X, t0
            ste f32t, SMOKE.Y, t1
            ste f32t, SMOKE.LIFESPAN, t4
            jmp @endif+
        @else:
            lod u8t, cr, smoke_can_spawn
            jfs @endif+
            mov cr, s1
            jfs @endif+
            mov a0, s0
            mov a1, SMOKE.MIN_ANGLE_OFFSET
            mov a2, SMOKE.MAX_ANGLE_OFFSET
            mov a3, SMOKE.MIN_VEL_SCALE
            mov a4, SMOKE.MAX_VEL_SCALE
            cal spawn_smoke
            mov s1, false
            str f32t, PLAYER.smoke_cooldown_timer, PLAYER.SMOKE_SPAWN_COOLDOWN # Reset cooldown
        @endif:
        inc s0
        jmp @loop-
    @endloop:
    vpop s0..s2
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
    # s3: Kill Velocity

    vpsh s0..s3

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

    and t0, a0, Input.MATCH_VELOCITY
    cmp neq, t0, 0
    mov s3, cr

    str u8t, PLAYER.is_flying, false
    str i8t, control_camera_offset_scalar, 0

    @is_grounded:
        lod u8t, cr, PLAYER.is_grounded
        jfs @else+
        str f32t, PLAYER.movex, 0.0 # Reset movement
        str f32t, PLAYER.movey, 0.0
        .is_jump_pressed:
            lod u8t, cr, PLAYER.can_jump # Check if jump is enabled
            and cr, s2
            jfs @else2+
            cal charge_jump
            jmp @endif2+
        @else2:
            lod u8t, cr, PLAYER.is_charging
            jfs @endif2+
            cal player_jump
        @endif2:
        fcti t0, s1
        str i8t, control_camera_offset_scalar, t0
        jmp @endif+
    @else:
        str f32t, PLAYER.jump_charge, PLAYER.MIN_JUMP_CHARGE
    @endif:


    @move:
        lod u8t, cr, PLAYER.is_charging
        jtr @end+
        cmp neq, s0, 0
        mov t0, cr
        cmp neq, s1, 0
        orr cr, t0
        jfs @end+
        lod u8t, t0, PLAYER.is_grounded
        cmp eq, t0, false
        and cr, s3 # Don't allow movement while matching velocity if not grounded
        jtr @end+
        mov a0, s0
        mov a1, s1
        cal player_move
    @end:

    @match_velocity:
        cmp eq, s3, true
        jfs @else+
        cal player_match_velocity
        jmp @end+
    @else:
        mov cr, s2 # Only reenable jump if jump key is not being held
        jtr @end+
        str u8t, PLAYER.can_jump, true
    @end:



    vpop s0..s3
    ret

#-------------------------------------------------------------------------------
sbmk "Player Move"
player_move:
    # a0: horizontal direction
    # a1: vertical direction

    vpsh s0..s1
    vmov s0..s1, a0..
    .if_grounded:
        lod u8t, cr, PLAYER.is_grounded
        jfs @else+
        cmp neq, s0, 0.0
        jfs @endif+
        lod i8t, t0, PLAYER.parent_body_index
        cmp lt, t0, 0
        jtr @else+
        cea bodies, t0, BODY.SIZE
        lod f32t, t0, PLAYER.x
        lod f32t, t1, PLAYER.y
        lod f32t, t2, PLAYER.velx
        lod f32t, t3, PLAYER.vely
        lde f32t, t4, BODY.X
        lde f32t, t5, BODY.Y

        # Calculate normal vector
        fsub a0, t4, t0 # dx
        fsub a1, t5, t1 # dy
        cal normal_vector
        vmov t6..t7, a0..

        # Rotate vector by -PI/2
        mov t0, a1 # x^
        fneg t1, a0 # y^

        fmul t8, s0, PLAYER.MOVE_SPEED
        fmul t0, t8
        fmul t1, t8

        # Player is moved towards the planet as well to help avoid flinging yourself off
        fabs t8
        lde f32t, t8, BODY.R
        lod f32t, t9, distance_scale
        fdiv t8, t9
        fdiv t8, 2.0
        fmul t6, t8
        fmul t7, t8
        fadd t0, t6
        fadd t1, t7

        str f32t, PLAYER.movex, t0
        str f32t, PLAYER.movey, t1

        jmp @endif+
    @else:
        lod f32t, t0, PLAYER.velx
        lod f32t, t1, PLAYER.vely
        lod f32t, t2, dt
        fmul s0, PLAYER.THRUSTER_STRENGTH
        fmul s1, PLAYER.THRUSTER_STRENGTH
        ffma t0, s0, t2, t0
        ffma t1, s1, t2, t1
        str f32t, PLAYER.velx, t0
        str f32t, PLAYER.vely, t1
        str u8t, smoke_can_spawn, true
        str u8t, PLAYER.is_flying, true
        # Update rotation to match movement
        fatan2 t2, a1, a0
        fmod t2, 2.0*PI
        mov t3, 0.0
        cmp flt, t2, 0.0
        mvc t3, 2.0*PI
        fadd t2, t3
        str f32t, PLAYER.rot, t2
    @endif:
    .flip_sprite:
        cmp neq, s0, 0.0
        jfs @end+
        mov t0, 0
        cmp flt, s0, 0.0
        mvc t0, 1
        str u8t, PLAYER.flip_sprite, t0
    @end:
    vpop s0..s1
    ret

#-------------------------------------------------------------------------------
sbmk "Charge Jump"
charge_jump:
    str u8t, PLAYER.is_charging, true
    lod f32t, t0, dt
    fmul t0, PLAYER.JUMP_CHARGE_SPEED

    lod f32t, t1, PLAYER.jump_charge
    fadd t0, t1

    fclp t0, PLAYER.MIN_JUMP_CHARGE, PLAYER.MAX_JUMP_CHARGE
    str f32t, PLAYER.jump_charge, t0
    ret

#-------------------------------------------------------------------------------
sbmk "Player Jump"
player_jump:
    str u8t, PLAYER.is_charging, false
    lod i8t, t0, PLAYER.parent_body_index
    cmp lt, t0, 0
    jtr @end+
    cea bodies, t0, BODY.SIZE
    lod f32t, t0, PLAYER.x
    lod f32t, t1, PLAYER.y
    lod f32t, t2, PLAYER.velx
    lod f32t, t3, PLAYER.vely
    lde f32t, t4, BODY.X
    lde f32t, t5, BODY.Y

    # Calculate normal vector
    fsub a0, t0, t4 # dx
    fsub a1, t1, t5 # dy
    cal normal_vector
    vmov t6..t7, a0..
    lod f32t, t9, PLAYER.jump_charge

    # Jump impulse vector
    fmul t6, t9
    fmul t7, t9

    fadd t2, t6
    fadd t3, t7
    str f32t, PLAYER.velx, t2
    str f32t, PLAYER.vely, t3
    str u8t, PLAYER.is_grounded, false

    # Apply impulse to parent body
    fneg a0, t6
    fneg a1, t7
    lod i8t, a2, PLAYER.parent_body_index
    cal apply_impulse

    psh s0
    mov s0, zr
    str u8t, smoke_can_spawn, true
    @loop:
        mov a0, s0
        mov a1, PI - PI/6
        mov a2, PI + PI/6
        #mov a3, SMOKE.MIN_VEL_SCALE
        mov a3, 0.5
        mov a4, 0.9
        #mov a4, SMOKE.MIN_VEL_SCALE
        cal spawn_smoke
        inc s0
        cmp lt, s0, 15
        jtr @loop-
    @endloop:
    pop s0
    str u8t, smoke_can_spawn, false
    str f32t, PLAYER.jump_charge, PLAYER.MIN_JUMP_CHARGE
    @end:
    ret

#-------------------------------------------------------------------------------
sbmk "Player Match Velocity"
player_match_velocity:
    # Match player velocity to background. Useful for recovering after flinging yourself

    lod f32t, t0, PLAYER.velx
    lod f32t, t1, PLAYER.vely

    .if_player_grounded: # If player is grounded, halve move speed and cancel jump. Helpful for low-gravity bodies
        lod u8t, cr, PLAYER.is_grounded
        jfs @else+
        lod f32t, t2, PLAYER.movex
        lod f32t, t3, PLAYER.movey
        fdiv t2, 5.0
        fdiv t3, 5.0
        str f32t, PLAYER.movex, t2
        str f32t, PLAYER.movey, t3
        str u8t, PLAYER.is_charging, false
        str f32t, PLAYER.jump_charge, PLAYER.MIN_JUMP_CHARGE
        jmp @end+
    @else:
        # Calculate normal vector
        lod f32t, a0, global_velx
        lod f32t, a1, global_vely
        cal normal_vector
        cmp fgt, a2, 1.0
        jfs @end+
        fneg a0
        fneg a1
        cal player_move
    @end:
    str u8t, PLAYER.can_jump, false # Don't allow jumping until both keys are released
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
    lod f32t, t10, distance_scale
    fdiv t2, t10
    fdiv t3, t10
    fdiv t7, t10
    fdiv t8, t10

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
    lod f32t, t10, distance_scale
    fdiv t4, t10

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
    lod f32t, t10, distance_scale
    fdiv t2, t10
    fdiv t3, t10
    fdiv t7, t10
    fdiv t8, t10

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

    # Add player collision radius
    lod f32t, t6, PLAYER.collision_radius
    fadd t4, t6

    ## Add collision margin
    @if_player_grounded:
        lod u8t, cr, PLAYER.is_grounded
        jfs @endif+
        fadd t4, GROUNDED_PLAYER_COLLISION_MARGIN
    @endif:

    # Apply distance scale
    lod f32t, t5, distance_scale
    fdiv t4, t5

    # Check if distance is less than body radius
    cmp flt, t2, t4
    ret

#-------------------------------------------------------------------------------
sbmk "Get Gravity Vector"
get_gravity_vector:
    # > a0..a1: object1 pos
    # > a2..a3: object2 pos
    # > a4: object2 mass
    # < a0..a1: Acceleration vector
    # < a2: Force

    # Calculate Distance
    fsub t0, a2, a0 # dx
    fsub t1, a3, a1 # dy
    fpow t2, t0, 2.0
    fpow t3, t1, 2.0
    fadd t2, t3 # r^2

    # Normal Vector
    fsqrt t3, t2 # r
    fdiv t0, t3 # dx/r
    fdiv t1, t3 # dy/r

    # Scale Distance
    lod f32t, t5, distance_scale
    fmul t3, t5
    fpow t2, t3, 2.0 # r^2

    # Calculate gravitational acceleration
    fmul t3, a4, G # G*m2 since we'll be dividing by m1 anyway, no point including it
    fdiv t3, t2

    # Get acceleration vector
    fmul a0, t0, t3
    fmul a1, t1, t3
    mov a2, t3

    ret

#-------------------------------------------------------------------------------
sbmk "Get Collision Vector"
get_collision_vector:
    # > a0..a1: object1 pos
    # > a2..a3: object1 velocity
    # > a4: object1 mass
    # > a5..a6: object2 pos
    # > a7..a8: object2 velocity
    # > a9: object2 mass
    # < a0..a1: impulse vector

    # Get collision vector
    fsub t0, a5, a0 # dx
    fsub t1, a6, a1 # dy
    vpsh a0..a2
    vmov a0..a1, t0..
    cal normal_vector
    vmov t0..t1, a0..
    vpop a0..a2


    # Get relative velocity vector
    fsub t2, a7, a2 # relvx
    fsub t3, a8, a3 # relvy

    # Calculate vn dot product
    fmul t2, t0
    fmul t3, t1
    fadd t2, t3 # dot product

    # Calculate impulse magnitude
    fmul t3, -(1.0 + BODY_ELASTICITY), t2
    fdiv t5, 1.0, a4 # 1/m1
    fdiv t6, 1.0, a9 # 1/m2
    fadd t5, t6
    fdiv t3, t5 # impulse magnitude

    # Calculate impulse vector
    fmul a0, t0, t3
    fmul a1, t1, t3
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
bmk "Drawing"

#-------------------------------------------------------------------------------
sbmk "Draw Player"
draw_player:
    # s0: Which version of the player sprite (based on zoom)
    psh s0

    lod f32t, t0, distance_scale
    fsub s0, t0, 1.0
    fdiv s0, 2.0

    @if_zoomed_out:
        cmp gt, s0, 2.0
        jfs @else+
        lod f32t, t0, PLAYER.x
        lod f32t, t1, PLAYER.y
        fadd t0, CENTER_X_F
        fadd t1, CENTER_Y_F
        frou t0
        frou t1
        fcti t0
        fcti t1
        # Draw player as a dot
        .is_offscreen:
            cmp lt, t0, 0
            jtr @end+
            cmp lt, t1, 0
            jtr @end+
            cmp lt, t0, SCREEN_WIDTH
            jfs @end+
            cmp lt, t1, SCREEN_HEIGHT
            jfs @end+
            sbpx t0, t1, 255
        jmp @end+
    @else:

        mov a0, PLAYER_SPRITESHEET
        # Draw pos
        lod f32t, t0, PLAYER.x
        lod f32t, t1, PLAYER.y
        fadd t0, CENTER_X_F
        fadd t1, CENTER_Y_F
        frou t0
        frou t1
        fcti t0
        fcti t1
        sub a1, t0, PLAYER_SPRITE_WIDTH/2
        sub a2, t1, PLAYER_SPRITE_WIDTH/2

        # Rotation sprite
        lod f32t, t2, PLAYER.rot
        fdiv a3, t2, PI/4.0
        frou a3
        fcti a3
        mod a3, 8
        mul a3, PLAYER_SPRITE_WIDTH

        # Zoomed Sprite
        frou s0
        fcti s0
        mul s0, 2
        lod u8t, t1, PLAYER.flip_sprite # Add 1 to index if flipped
        add a4, s0, t1
        mul a4, PLAYER_SPRITE_WIDTH

        mov a5, PLAYER_SPRITE_WIDTH
        mov a6, PLAYER_SPRITE_WIDTH
        mov a7, 0
        #lod u8t, a7, PLAYER.flip_sprite
        syscall SYS_DRAW_TEXTURE_REGION
        jmp @end+

    @end:

    .if_show_vectors:
        mov cr, DRAW_PLAYER_VELOCITY
        jfs @endif+
        lod f32t, t0, PLAYER.x
        lod f32t, t1, PLAYER.y
        fadd a0, t0, CENTER_X_F
        fadd a1, t1, CENTER_Y_F
        lod f32t, t2, global_velx
        lod f32t, t3, global_vely
        ffma a2, t2, VELOCITY_VISUAL_SCALE, a0
        ffma a3, t3, VELOCITY_VISUAL_SCALE, a1
        mov a4, VELOCITY_VECTOR_START_LUMA
        mov a5, VELOCITY_VECTOR_END_LUMA
        cal draw_gradient_line
    @endif:
    pop s0
    ret

#-------------------------------------------------------------------------------
sbmk "Draw Bodies"
draw_bodies:
    # s0: body index
    vpsh s0..s5

    mov s0, zr
    @loop:
        lod u8t, t0, bodies_count
        cmp lt, s0, t0
        jfs @endloop+


        cea bodies, s0, BODY.SIZE
        lde f32t, t0, BODY.X
        lde f32t, t1, BODY.Y
        fadd a0, t0, CENTER_X_F
        fadd a1, t1, CENTER_Y_F
        lde f32t, a2, BODY.R
        lod f32t, t1, distance_scale
        fdiv a2, t1
        fadd t4, t1, 1.0
        #fdiv t4, 2.0

        @is_body_offscreen:
            fadd t0, a0, a2
            cmp flt, t0, 0.0
            jtr @skipdraw+
            fadd t0, a1, a2
            cmp flt, t0, 0.0
            jtr @skipdraw+
            fsub t0, a0, a2
            cmp fgt, t0, SCREEN_WIDTH_F
            jtr @skipdraw+
            fsub t0, a1, a2
            cmp fgt, t0, SCREEN_HEIGHT_F
            jtr @skipdraw+
        fsqrt t4
        lde u16t, t5, BODY.LUM
        fctf t5
        fdiv t4, t5, t4 # Divide luma by the sqrt of the zoom scale
        fcti t4
        fclp a3, t4, 1, 255 # Clamp luma
        vpsh a0..a3
        cal DrawPAcircle
        vpop a0..a3

        @if_show_rotation: # Draw lines on bodies to visualize rotation
            mov cr, DRAW_ROTATIONAL_VELOCITY
            jfs @endif+
            mov s1, a0
            mov s2, a1
            mov s3, a2
            cea bodies, s0, BODY.SIZE
            lde f32t, s4, BODY.ROT
            fadd s5, s4, 2*PI
            mov a4, 1
            cmp lt, a3, 255/2
            mvc a4, 255
            @draw_loop:
                fcos t1, s4
                fsin t2, s4
                ffma a2, t1, s3, s1
                ffma a3, t2, s3, s2
                fmul t3, s3, 0.9
                #fsub t3, s3,
                ffma a0, t1, t3, s1
                ffma a1, t2, t3, s2
                cal draw_line
                fadd s4, (2*PI/3)
                cmp fgt, s4, s5
                jfs @draw_loop-
        @endif:

        @skipdraw:

        @if_show_vectors:
            mov cr, DRAW_BODY_VELOCITIES
            jfs @endif+
            cea bodies, s0, BODY.SIZE
            lde f32t, t0, BODY.X
            lde f32t, t1, BODY.Y
            fadd a0, t0, CENTER_X_F
            fadd a1, t1, CENTER_Y_F
            lde f32t, t2, BODY.VX
            lde f32t, t3, BODY.VY
            #lod f32t, t4, global_velx
            #lod f32t, t5, global_vely
            #fadd t2, t4
            #fadd t3, t5
            ffma a2, t2, VELOCITY_VISUAL_SCALE, a0
            ffma a3, t3, VELOCITY_VISUAL_SCALE, a1
            mov a4, VELOCITY_VECTOR_START_LUMA
            mov a5, VELOCITY_VECTOR_END_LUMA
            cal draw_gradient_line
        @endif:

        inc s0
        jmp @loop-
    @endloop:
    vpop s0..s5
    ret

#-------------------------------------------------------------------------------
sbmk "Draw Background"
draw_background:
    lod f32t, t0, bg_offset_x
    lod f32t, t1, bg_offset_y
    frou t0
    frou t1
    fcti t0
    fcti t1

    mov a0, BACKGROUND_TEXTURE
    vmov a1..a2, 0
    vmov a3..a4, t0..
    sub a5, BG_TEX_WIDTH, t0
    sub a6, BG_TEX_HEIGHT, t1
    mov a7, 0
    syscall SYS_DRAW_TEXTURE_REGION
    sub a1, BG_TEX_WIDTH, t0
    mov a3, 0
    mov a5, t0
    syscall SYS_DRAW_TEXTURE_REGION
    sub a2, BG_TEX_HEIGHT, t1
    mov a4, 0
    mov a6, t1
    syscall SYS_DRAW_TEXTURE_REGION
    mov a1, 0
    mov a3, t0
    sub a5, BG_TEX_WIDTH, t0
    syscall SYS_DRAW_TEXTURE_REGION
    ret


#-------------------------------------------------------------------------------
sbmk "Draw Smoke"
draw_smoke:
    mov t15, zr
    @loop:
        cmp lt, t15, SMOKE.MAX_SMOKE_COUNT
        jfs @endloop+
        cea smoke, t15, SMOKE.SIZE
        lde f32t, t0, SMOKE.X
        lde f32t, t1, SMOKE.Y
        lde f32t, t2, SMOKE.LIFESPAN
        .if_smoke_alive:
            cmp fgt, t2, 0.0
            jfs @endif+
            fadd t0, CENTER_X_F
            fadd t1, CENTER_Y_F
            frou t0
            frou t1
            fcti t0
            fcti t1
            .if_in_bounds:
                cmp gt, t0, 0
                jfs @endif2+
                cmp gt, t1, 0
                jfs @endif2+
                cmp lt, t0, SCREEN_WIDTH
                jfs @endif2+
                cmp lt, t1, SCREEN_HEIGHT
                jfs @endif2+
                lod f32t, t3, distance_scale # Use a dimmer color when zoomed out
                fcti t3
                sub t3, 1
                div t3, 2
                max t3, 1
                div t3, 255, t3
                sbpx t0, t1, t3
            @endif2:
        @endif:
    inc t15
    jmp @loop-
    @endloop:
    ret

#-------------------------------------------------------------------------------
sbmk "Draw HUD"
draw_hud:
    def HUD_PADDING 2

    # Text
    mov a0, HUD_TEXTURE
    mov a1, SCREEN_WIDTH - 108 - HUD_PADDING
    mov a2, SCREEN_HEIGHT - 16 - HUD_PADDING
    vmov a3..a4, 0
    mov a5, 88
    mov a6, 16
    mov a7, 0
    syscall SYS_DRAW_TEXTURE_REGION

    mov a1, HUD_PADDING
    mov a2, SCREEN_HEIGHT - 16 - HUD_PADDING
    mov a4, 16
    syscall SYS_DRAW_TEXTURE_REGION

    mov a1, HUD_PADDING
    mov a2, HUD_PADDING
    mov a4, 32
    mov a5, 104
    mov a6, 32
    syscall SYS_DRAW_TEXTURE_REGION


    @if_paused:
        lod u8t, cr, system_paused
        jfs @endif+
        mov a1, SCREEN_WIDTH/2 - 48
        mov a2, SCREEN_HEIGHT/2
        mov a4, 64
        mov a5, 96
        mov a6, 32
        syscall SYS_DRAW_TEXTURE_REGION
    @endif:

    def CHARGE_BAR_X SCREEN_WIDTH - 16 - HUD_PADDING
    def CHARGE_BAR_Y SCREEN_HEIGHT - (8*CHARGE_BAR_LENGTH) - HUD_PADDING

    # Calculate jump charge bar length
    lod f32t, t0, PLAYER.jump_charge
    fsub t0, PLAYER.MIN_JUMP_CHARGE
    fsub t1, PLAYER.MAX_JUMP_CHARGE, PLAYER.MIN_JUMP_CHARGE
    fdiv t0, t1
    fctf t2, 8*CHARGE_BAR_LENGTH
    fsub t2, 12.0
    fmul t0, t2
    frou t0
    fcti t0

    # Draw charge bar
    mov a0, CHARGE_BAR_X  + 4
    mov a1, CHARGE_BAR_Y + 6
    mov a2, 8
    mov a3, 8*CHARGE_BAR_LENGTH-12
    mov a4, 1
    syscall SYS_DRAW_RECT

    .if_charging:
        cmp gt, t0, 0
        jfs @endif+
        #sub t0, 6
        sub a1, CHARGE_BAR_Y + 8*(CHARGE_BAR_LENGTH-1) + 2, t0
        mov a3, t0
        mov a4, 255
        syscall SYS_DRAW_RECT
    @endif:

    # Jump Bar top
    mov a0, HUD_TEXTURE
    mov a1, CHARGE_BAR_X
    mov a2, CHARGE_BAR_Y
    mov a3, 88
    mov a4, 0
    mov a5, 16
    mov a6, 8
    syscall SYS_DRAW_TEXTURE_REGION

    # Jump Bar Middle
    mov a4, 8
    mov t0, zr
    @loop:
        mul t1, t0, 8
        add a2, CHARGE_BAR_Y + 8, t1
        syscall SYS_DRAW_TEXTURE_REGION
        inc t0
        cmp lt, t0, CHARGE_BAR_LENGTH-2
        jtr @loop-

    # Jump Bar Bottom
    mov a2, CHARGE_BAR_Y + 8*(CHARGE_BAR_LENGTH-1)
    mov a4, 24
    mov a5, 16
    mov a6, 8
    syscall SYS_DRAW_TEXTURE_REGION
    ret

#-------------------------------------------------------------------------------
bmk "Camera"

#-------------------------------------------------------------------------------
sbmk "Move Camera"
move_camera:
    # > a0..a1: Camera offset

    # Move Bodies
    mov t15, zr # Object counter
    lod u8t, t14, bodies_count
    @loop:
        cmp lt, t15, t14
        jfs @endloop+

        cea bodies, t15, BODY.SIZE
        lde f32t, t0, BODY.X
        lde f32t, t1, BODY.Y
        fsub t0, a0
        fsub t1, a1
        ste f32t, BODY.X, t0
        ste f32t, BODY.Y, t1

        inc t15
        jmp @loop-
    @endloop:

    # Move Smoke
    mov t15, zr
    @loop:
        cmp lt, t15, SMOKE.MAX_SMOKE_COUNT
        jfs @endloop+
        cea smoke, t15, SMOKE.SIZE
        lde f32t, t0, SMOKE.X
        lde f32t, t1, SMOKE.Y
        fsub t0, a0
        fsub t1, a1
        ste f32t, SMOKE.X, t0
        ste f32t, SMOKE.Y, t1

        inc t15
        jmp @loop-
    @endloop:

    # Move Player
    lod f32t, t0,  PLAYER.x
    lod f32t, t1,  PLAYER.y
    fsub t0, a0
    fsub t1, a1
    str f32t, PLAYER.x, t0
    str f32t, PLAYER.y, t1

    # Update Background offset
    lod f32t, t0, bg_offset_x
    lod f32t, t1, bg_offset_y
    fmul t2, a0, BG_SCROLL_SCALE
    fmul t3, a1, BG_SCROLL_SCALE
    fadd t0, t2
    fadd t1, t3
    fmod t0, BG_TEX_WIDTH_F
    fmod t1, BG_TEX_HEIGHT_F
    str f32t, bg_offset_x, t0
    str f32t, bg_offset_y, t1

    ret

#-------------------------------------------------------------------------------
sbmk "Center Camera"
center_camera:
    # > a0: Lerp (true) or Snap (false)
    # s0: distance_scale
    # s1: Lerp or snap
    vpsh s0..s1
    mov s1, a0
    lod f32t, a0, PLAYER.x
    lod f32t, a1, PLAYER.y
    lod f32t, s0, distance_scale
    fdiv t2, CAMERA_SPEED, s0

    mov t0, a0
    mov t1, a1

    # Get distance from parent body
    lod i8t, t3, PLAYER.parent_body_index
    cmp lt, t3, 0
    jtr @endif+
    cea bodies, t3, BODY.SIZE
    lde f32t, t3, BODY.X
    lde f32t, t4, BODY.Y
    lde f32t, t5, BODY.R

    fsub a0, t0, t3
    fsub a1, t1, t4
    cal normal_vector # Normalize vector


    @should_offset_camera:
        fsqrt t6, t5
        ffma t5, t6, GROUNDED_DISTANCE, t5
        lod f32t, t6, PLAYER.collision_radius
        fadd t5, t6
        fdiv t5, s0
        cmp flt, a2, t5
        jfs @endif+
        mov a2, 0
        lod i8t, t6, control_camera_offset_scalar
        lod u8t, cr, PLAYER.is_grounded
        mvc a2, t6
        fctf a2
        fdiv t3, CAMERA_OFFSET, s0
        ffma a2, -CAMERA_OFFSET, t3
        ffma t0, a0, a2, t0
        ffma t1, a1, a2, t1
    @endif:
    mov a0, t0
    mov a1, t1
    @lerp_cam:
        mov cr, s1 # Check if camera should lerp or snap
        jfs @end+
        flrp a0, 0.0, t0, t2
        flrp a1, 0.0, t1, t2
    @end:

    cal move_camera
    #str f32t, PLAYER.x, 0.0
    #str f32t, PLAYER.y, 0.0
    vpop s0..s1
    ret

#-------------------------------------------------------------------------------
sbmk "Set Distance Scale"
set_distance_scale:
    # Scales distance from center of camera
    # > a0: Distance Scale

    lod f32t, t13, distance_scale
    mov t15, zr # Object counter
    lod u8t, t14, bodies_count
    @loop:
        cmp lt, t15, t14
        jfs @endloop+

        cea bodies, t15, BODY.SIZE
        lde f32t, t0, BODY.X
        lde f32t, t1, BODY.Y
        # Multiply by previous distance scale
        fmul t0, t13
        fmul t1, t13
        # Divide by new distance scale
        fdiv t0, a0
        fdiv t1, a0
        # Store new position
        ste f32t, BODY.X, t0
        ste f32t, BODY.Y, t1

        inc t15
        jmp @loop-
    @endloop:
    # Player
    lod f32t, t0, PLAYER.x
    lod f32t, t1, PLAYER.y
    # Divide by previous distance scale
    fmul t0, t13
    fmul t1, t13
    # Multiply by new distance scale
    fdiv t0, a0
    fdiv t1, a0
    # Store new position
    str f32t, PLAYER.x, t0
    str f32t, PLAYER.y, t1

    # Smoke
    mov t15, zr
    @loop:
        cmp lt, t15, SMOKE.MAX_SMOKE_COUNT
        jfs @endloop+
        cea smoke, t15, SMOKE.SIZE
        lde f32t, t0, SMOKE.X
        lde f32t, t1, SMOKE.Y
        # Divide by previous distance scale
        fmul t0, t13
        fmul t1, t13
        # Multiply by new distance scale
        fdiv t0, a0
        fdiv t1, a0
        ste f32t, SMOKE.X, t0
        ste f32t, SMOKE.Y, t1

        inc t15
        jmp @loop-
    @endloop:
    str f32t, distance_scale, a0
    mov a0, false
    cal center_camera
    ret

#-------------------------------------------------------------------------------
bmk "Terminal Input"

#-------------------------------------------------------------------------------
sbmk "Check Terminal Commands"
check_commands:
    # s0: command address
    psh s0
    mov s0, buffer
    @loop:
        .zoom_in:
            mov a0, s0
            mov a1, Commands.ZOOM_IN
            cal cmp_strings
            jfs @endif+
            lod f32t, t0, distance_scale
            fsub t0, ZOOM_STEP
            fmax t0, 1.0
            mov a0, t0
            cal set_distance_scale
            mov a1, 1
            mov a0, Strings.zoom
            syscall SYS_PRINT_STRING
            lod f32t, a0, distance_scale
            syscall SYS_PRINT_LINE_FLOAT
            jmp @endloop+
        @endif:
        .zoom_out:
            mov a0, s0
            mov a1, Commands.ZOOM_OUT
            cal cmp_strings
            jfs @endif+
            lod f32t, t0, distance_scale
            fadd t0, ZOOM_STEP
            fmax t0, 1.0
            mov a0, t0
            cal set_distance_scale
            mov a0, Strings.zoom
            mov a1, 1
            syscall SYS_PRINT_STRING
            lod f32t, a0, distance_scale
            syscall SYS_PRINT_LINE_FLOAT
            jmp @endloop+
        @endif:
    @endloop:
    pop s0
    ret

#-------------------------------------------------------------------------------
bmk "Helper Functions"

#-------------------------------------------------------------------------------
sbmk "Compare Strings"
cmp_strings:
    # > a0*: string1 address
    # > a1*: string2 address
    # < cr: Are strings equal

    cmp eq, a0, a1
    jtr @endloop+

    mov t0, a0
    mov t1, a1
    @loop:
        lod u8t, t2, t0
        lod u8t, t3, t1
        .if_eq:
            cmp eq, t2, t3
            jfs @endloop+
            .if_null:
                cmp eq, t2, 0
                jtr @endloop+ # Strings terminated
                cmp eq, t2, 32 # Count spaces as terminators
                jtr @endloop+
                inc t0
                inc t1
                jmp @loop-
    @endloop:
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
    # > a4: Luma

    vpsh s0..s3
    mov s0, a0
    mov s1, a1
    mov s2, a2
    mov s3, a3
    fsub t0, s2, s0
    fsub t1, s3, s1
    fpow t4, t0, 2.0
    fpow t5, t1, 2.0
    fadd t4, t5
    fsqrt t4 # Length
    fatan2 t7, t1, t0
    fcos t2, t7 # dx
    fsin t3, t7 # dy
    mov t0, s0
    mov t1, s1
    mov t15, zr
    @loop:
        frou t5, t0
        frou t6, t1
        fcti t5
        fcti t6
        @if_in_bounds:
            cmp gt, t5, 0
            jfs @endif+
            cmp gt, t6, 0
            jfs @endif+
            cmp lt, t5, SCREEN_WIDTH
            jfs @endif+
            cmp lt, t6, SCREEN_HEIGHT
            jfs @endif+
            sbpx t5, t6, a4
        @endif:
        fadd t0, t2
        fadd t1, t3
        fadd t15, 1.0
        yield
        cmp flt, t15, t4
        jtr @loop-
    @end:
    vpop s0..s3
    ret

#-------------------------------------------------------------------------------
sbmk "Draw Gradient Line"
draw_gradient_line:
    # > a0..a1: start x,y
    # > a2..a3: end x,y
    # > a4: start luma
    # > a5: end luma

    vpsh s0..s3
    mov s0, a0
    mov s1, a1
    mov s2, a2
    mov s3, a3
    fsub t0, s2, s0
    fsub t1, s3, s1
    fpow t4, t0, 2.0
    fpow t5, t1, 2.0
    fadd t4, t5
    fsqrt t4 # Length
    cmp fgt, t4, 0.001
    jfs @end+

    fatan2 t7, t1, t0
    fcos t2, t7 # dx
    fsin t3, t7 # dy
    mov t0, s0
    mov t1, s1

    sub t9, a5, a4
    fctf t9
    fdiv t9, t4
    fflo t9
    fcti t9
    mov t14, a4
    mov t15, zr
    @loop:
        frou t5, t0
        frou t6, t1
        fcti t5
        fcti t6
        .if_in_bounds:
            cmp gt, t5, 0
            jfs @endif+
            cmp gt, t6, 0
            jfs @endif+
            cmp lt, t5, SCREEN_WIDTH
            jfs @endif+
            cmp lt, t6, SCREEN_HEIGHT
            jfs @endif+
            sbpx t5, t6, t14
        @endif:
        fadd t0, t2
        fadd t1, t3
        fadd t15, 1.0
        add t14, t9
        yield
        cmp flt, t15, t4
        jtr @loop-
    @end:
    vpop s0..s3
    ret

#-------------------------------------------------------------------------------
sbmk "Normalize Vector"
normal_vector:
    # > a0..a1: Vector x,y
    # < a0..a1: Normal vector x,y
    # < a2: Vector length

    vpsh s0..s1

    fpow s0, a0, 2.0
    fpow s1, a1, 2.0
    fadd s0, s1 # r^2
    fsqrt a2, s0 # r
    fdiv a0, a2 # dx/r
    fdiv a1, a2 # dy/r

    vpop s0..s1
    ret

#-------------------------------------------------------------------------------
sbmk "Get Vector Length"
get_length:
    # > a0..a1: Vector x,y
    # < a0: Vector length

    vpsh s0..s1

    fpow s0, a0, 2.0
    fpow s1, a1, 2.0
    fadd s0, s1 # r^2
    fsqrt a0, s0 # r

    vpop s0..s1
    ret

#-------------------------------------------------------------------------------
sbmk "Get Vector Projection"
project_vector:
    # > a0..a1: source vector x,y
    # > a2..a3: base vector x,y
    # < a0..a1: result vector

    # dot v1 v2
    fmul t0, a0, a2
    fmul t1, a1, a3
    fadd t0, t1

    # length squared
    fpow t1, a2, 2.0
    fpow t2, a3, 2.0
    fadd t1, t2

    # Scalar
    fdiv t0, t1

    fmul a0, t0
    fmul a1, t0
    ret


#-------------------------------------------------------------------------------
bmk "DrawLib"

#-------------------------------------------------------------------------------
sbmk "DrawPAcircle"
## Author: lawrziepan
## Draws a circle to the screen using a pixel-aligned centre and a float radius
## Parameters:
## > a0: centre
## > a1: radius
## Additional Implementation Notes:
##  Because this function assumes a pixel-aligned centre, it actually only draws an eigth
## of a circle, and copies it to the other 7 eigths. You can also use this with non-pixel
## aligned circles, as it has very similar quality but is drawn much faster.

# Modified to use a0..a1 as x,y directly, and a3 for the fill color

DrawPAcircle:
    vpsh s0..s9


    @is_circle_offscreen:
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

    mov s0, a0 # centre x
    mov s1, a1 # centre y
    mov s9, a3
    mov s2, a2
    fabs s2
    mov t3, s2
    mov s5, t3
    fcti t3
    neg s3, t3
    fdiv s5, 2.0
    fcti s5
    neg s5
    add s5, 1
    fpow s8, s2, 2.0 # square radius
    mov s4, s3 # counter
    sub s4, 1
    @loop:
        cmp lte, s4, s5
        jfs @endloop+
        mov s6, s4
        fctf s6 # y coordinate (0 centre)
        mov s7, s6
        fpow s7, 2.0
        fsub s7, s8, s7
        fsqrt s7 # x coordinate (0 centre)
        fcei a2, s7
        fmul a2, 2.0
        fadd a2, -1.0
        fcti a2
        fsub t0, s1, s6
        fsub t1, s0, s7
        fflo t0
        fcei t1
        fcti t0
        fcti t1
        mov a0, t1
        mov a1, t0
        mov a3, 1
        mov a4, s9
        cal is_rect_offscreen
        jtr @skip+
        syscall SYS_DRAW_RECT # draw upper quarter
        @skip:
        fadd t0, s1, s6
        fcei t0
        fcti t0
        mov a1, t0
        cal is_rect_offscreen
        jtr @skip+
        syscall SYS_DRAW_RECT # draw upper quarter
        @skip:
        fcei a3, s7
        fmul a3, 2.0
        fadd a3, -1.0
        fcti a3
        fsub t0, s1, s7
        fadd t1, s0, s6
        fcei t0
        fcei t1
        fcti t0
        fcti t1
        mov a0, t1
        mov a1, t0
        mov a2, 1
        mov a4, s9
        cal is_rect_offscreen
        jtr @skip+
        syscall SYS_DRAW_RECT # draw left quarter
        @skip:
        fsub t1, s0, s6
        fflo t1
        fcti t1
        mov a0, t1
        cal is_rect_offscreen
        jtr @skip+
        syscall SYS_DRAW_RECT # draw right quarter
        @skip:
        yield
        inc s4
        jmp @loop-
    @endloop:
    fmul s2, 0.5
    # draw inner square
    fsub a0, s0, s2
    fsub a1, s1, s2
    fcei a0
    fcei a1
    fcti a0
    fcti a1
    fmul a2, s2, 2.0
    fflo a2
    fcti a2
    mov a3, a2
    mov a4, s9
    cal is_rect_offscreen
    jtr @end+
    syscall SYS_DRAW_RECT
    @end:
    vpop s0..s9
    ret

is_rect_offscreen:
    # > a0..a1: x,y pos
    # > a2..a3: width, height

    add t0, a0, a2
    cmp lt, t0, 0
    jtr @end+
    add t0, a1, a3
    cmp lt, t0, 0
    jtr @end+
    cmp gt, a0, SCREEN_WIDTH
    jtr @end+
    cmp gt, a1, SCREEN_HEIGHT
    jtr @end+
    mov cr, false
    @end:
    ret

#-------------------------------------------------------------------------------
sbmk "DrawLine(A: vec2, B: vec2)"
## Author: a.flatik
## Bresenham's Alghorhithm for all octants
## Parameters:
## > a0 - vec2 A
## > a1 - vec2 B
## Additional Implementation Notes
##  Rounds vec2 coordinates to the nearest whole pixel, non-destructively
DrawLine:




    # Round positions
    frou t0, a0
    frou t1, a1
    frou t2, a2
    frou t3, a3

    fcti t0
    fcti t1
    fcti t2
    fcti t3

    # Calculate deltas
    sub t4, t0, t2
    abs t4 # t4 = dx
    sub t5, t1, t3
    abs t5
    neg t5 # t5 = dy

    mov t6, -1
    cmp lt, t0, t2
    mvc t6, 1 # t6 = sx

    mov t7, -1
    cmp lt, t1, t3
    mvc t7, 1 # t7 = sy

    add t8, t4, t5 # t8 = err

    @loop:
        cmp gte, t0, SCREEN_WIDTH
        jtr @skip+
        cmp gte, t1, SCREEN_HEIGHT
        jtr @skip+
        cmp lt, t0, 0
        jtr @skip+
        cmp lt, t1, 0
        jtr @skip+

        sbpx t0, t1, a4 # Plot Ax, Ay

        @skip:

        cmp eq, t0, t2 # If Ax = Bx...
        jfs @continue+
        cmp eq, t1, t3 # ... and Ay = By ...
        jfs @continue+
        jmp @rtn+ # ... then break
        @continue:

        add t9, t8, t8 # t9 = 2*err

        cmp gte, t9, t5 # If 2 * err >= dy
        add t10, t8, t5 # t10 = err + dy
        mvc t8, t10 # err = err + dy
        add t10, t0, t6 # t10 = Ax + sx
        mvc t0, t10 # Ax = Ax + sx

        cmp lte, t9, t4 # If 2 * err <= dx
        add t10, t8, t4 # t10 = err + dx
        mvc t8, t10 # err = err + dx
        add t10, t1, t7 # t10 = Ay + sy
        mvc t1, t10 # Ay = Ay + sy
    yield
    jmp @loop-
    @rtn:
ret
