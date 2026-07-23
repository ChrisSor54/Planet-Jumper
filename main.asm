# Built-in process entry points.
# The kernel runs these processes automatically.
# Each process must end with an 'exit' instruction.

#-------------------------------------------------------------------------------
bmk "About"

# This is primarily a 2D n-body gravity simulation, but it also features
# a playable character with which to jump around the various gravitational bodies.

# The code is absolutely messy, partially due to my inexperience and having to learn
# the system as I went, so apologies to those more experienced lol


# Controls:
#   Most of the controls are visible in the UI, so here are the few that
#   are not.
#
#   BTN_SELECT: Enables freecam. Press BTN_B to toggle between
#               Player relative velocities and Global velocities.
#   BTN_START: Pause the game. This lets you access the editor, as
#              well as save and load the system.



#-------------------------------------------------------------------------------
bmk "DATA"

PLAYER_SPRITESHEET: emb file "assets/astronaut.png"
SCREENS_TEXTURES: emb file "assets/screens.png"
HUD_SPRITESHEET: emb file "assets/hud_compact.png"
FONT_SPRITESHEET: emb file "assets/font.png"


system_id: emb u8t 1 # The ID of the current planetary system
system_count: emb u8t 0

#-------------------------------------------------------------------------------
bmk "CONSTANTS"

# Simulation
def G 1.0 # This makes gravity a lot stronger but more fun :)
#def G 6.6743*(10**-11)
def MAX_BODIES 20
def BODY_ELASTICITY 0.8

def SCREEN_WIDTH_F fcast SCREEN_WIDTH
def SCREEN_HEIGHT_F fcast SCREEN_HEIGHT
def CENTER_X_F SCREEN_WIDTH_F/2.0
def CENTER_Y_F SCREEN_HEIGHT_F/2.0

def PLAYER_SPRITE_WIDTH 8
def PLAYER_SPRITE_WIDTH_F 8.0

def SCREENS_TEXTURE_WIDTH 640

def NEWLINE 10

def BG_TEX_WIDTH 320
def BG_TEX_HEIGHT 240
def BG_TEX_WIDTH_F 320.0
def BG_TEX_HEIGHT_F 240.0

def GROUNDED_PLAYER_COLLISION_MARGIN 2.0
    # How far a grounded player must be before no longer being considered grounded

#-------------------------------------------------------------------------------
sbmk "Simulation Settings"

def TIME_SCALE 1.0 # How fast the simulation runs. Must be greater than 0 or things dont work

#-------------------------------------------------------------------------------
sbmk "Visualization Settings"

def ZOOM_STEP 2.0 # How much to change zoom when zoom commands are input
def MAX_ZOOM 256.0 # Keep this as a multiple of 2
def MIN_ZOOM 1.0
def CAMERA_SPEED 0.5
def FREECAM_SPEED 100.0
def CAMERA_OFFSET 50.0
def GROUNDED_DISTANCE 1.0
    # How far the player must be from the parent body before the camera
    # centers on them, relative to the square root of the body's radius

def DRAW_BODY_VELOCITIES false # Draw velocity vectors for bodies (relative to the player)
def DRAW_PLAYER_VELOCITY false # Draw velocity vector for the player (relative to the 'global position')
def DRAW_ROTATIONAL_VELOCITY true   # Add visual indicator to show planet rotation
def VELOCITY_VISUAL_SCALE 1.0       # How much velocity vectors should be scaled
def VELOCITY_VECTOR_START_LUMA 10
def VELOCITY_VECTOR_END_LUMA 255

def CHARGE_BAR_LENGTH 8

def BG_SCROLL_SCALE 0.1 # How much the background moves relative to the foreground


#-------------------------------------------------------------------------------
sbmk "Enums"

INPUT:
    def .JUMP BTN_A
    def .MATCH_VELOCITY BTN_B
    def .ZOOM_IN BTN_X
    def .ZOOM_OUT BTN_Y
    def .PAUSE BTN_START
    def .FREE_CAM BTN_SELECT

STRINGS:
    # Data Headers
    .SYS_DATA_HEADER: emb string "SYS#"
    def .SYS_DATA_HEADER_SIZE ($ - STRINGS.SYS_DATA_HEADER - 1) # No need to save terminator
    .PLAYER_DATA_HEADER: emb string "PLR"
    def .PLAYER_DATA_HEADER_SIZE ($ - STRINGS.PLAYER_DATA_HEADER - 1)
    .BODIES_DATA_HEADER: emb string "BDS"
    def .BODIES_DATA_HEADER_SIZE ($ - STRINGS.BODIES_DATA_HEADER - 1)
    def .DATA_HEADER_SIZE ($ - STRINGS)+3 # 3 Additional bytes for the sysID ascii

    # Menus
    .START: emb string "PRESS START"
    .NEW_SYSTEM: emb string "NEW SYSTEM"
    .LOAD_SYSTEM: emb string "LOAD SYSTEM"

    # Game HUD
    .JUMP: emb string ":JUMP"
    .WALK: emb string ":WALK"
    .CANCEL: emb string ":CANCEL"
    .MATCH: emb string ":MATCH"
    .PLAYER: emb string ":PLAYER"
    .GLOBAL: emb string ":GLOBAL"
    .ZOOM_IN: emb string ":ZOOM+"
    .ZOOM_OUT: emb string ":ZOOM-"
    .FREECAM: emb string "FREECAM"
    .EDITOR: emb string "EDITOR"
    .PAUSE: emb string "GAME PAUSED"
    .TOGGLE_EDITOR: emb string ":TOGGLE EDITOR"

    # Editor
    .ADD_BODY: emb string ":ADD"
    .EDIT_BODY: emb string ":EDIT"
    .REMOVE_BODY: emb string ":REMOVE"
    .NEXT: emb string ":NEXT"
    .BACK: emb string ":BACK"
    .X: emb string "X:"
    .Y: emb string "Y:"
    .VAL: emb string "VAL:"
    .SCALE: emb string "SCALE:"
    .POS: emb string "POS(KM):"
    .VEL: emb string "VELOCITY(KM/S):"
    .ROT: emb string "ROTATION(RAD/S):"
    .R: emb string "RADIUS(KM):"
    .M: emb string "MASS(KG):"
    .LUM: emb string "LUMINOSITY:"
    .BODY_ID: emb string "ID:"


    # Errors
    .ERR_INVALID_SYSTEM_ID: emb string "ERROR: INVALID SYSTEM ID"


def MENU_COUNT 2

MENUS:
    def .NO_MENU 0
    def .MAIN_MENU 1
    def .PAUSE_MENU 2

#COMMANDS:
    #.ZOOM_IN: emb string "ZOOM_IN"
    #.ZOOM_OUT: emb string "ZOOM_OUT"


#-------------------------------------------------------------------------------
sbmk "Debug Settings"

#-------------------------------------------------------------------------------
bmk "STRUCTS"

#-------------------------------------------------------------------------------
sbmk "Player"

PLAYER:
    def .PLAYER_DATA $
    # Constants
    def .MOVE_SPEED 100.0
    def .THRUSTER_STRENGTH 100.0
    def .MIN_JUMP_CHARGE 50.0
    def .MAX_JUMP_CHARGE 200.0
    def .JUMP_CHARGE_SPEED (.MAX_JUMP_CHARGE-.MIN_JUMP_CHARGE)/0.8
    def .SMOKE_SPAWN_COOLDOWN 0.01 # How often smoke is produced while flying
    # Properties
    .x: emb f32t 0.0 # X Position
    .y: emb f32t 0.0 # Y Position
    .velx: emb f32t 0.0 # X Velocity (km/s)
    .vely: emb f32t 0.0 # Y Velocity (km/s) This is just to make the player face up at start
    .movex: emb f32t 0.0 # X Move Velocity
    .movey: emb f32t 0.0 # Y Move Velocity
    .rot: emb f32t 0.0 # Rotation (Radians)
    .mass: emb f32t 7.0 # Mass (kg)
    .collision_radius: emb f32t PLAYER_SPRITE_WIDTH_F/2.0 # Radius of collision circle

    .is_grounded: emb u8t false
    .is_flying: emb u8t false # Player is moving in the air
    .is_charging: emb u8t false # Player is charging a jump
    .can_jump: emb u8t true
    .can_move: emb u8t true
    .is_alive: emb u8t true # Unimplemented

    .jump_charge: emb f32t PLAYER.MIN_JUMP_CHARGE
    .smoke_cooldown_timer: emb f32t 0.0
    .parent_body_index: emb i8t -1 # -1 means no parent body has been found (only really applicable if no bodies exist)
    .flip_sprite: emb u8t false

    def .SIZE ($ - PLAYER)

#-------------------------------------------------------------------------------
sbmk "Body"

BODY:
    # Properties
    .active: emb u8t false # Whether the current body is available to be overwritten
    .x: emb f32t 0.0 # X Position (km)
    .y: emb f32t 0.0 # Y Position (km)
    .velx: emb f32t 0.0 # X Velocity (km/s)
    .vely: emb f32t 0.0 # Y Velocity (km/s)
    .rot: emb f32t 0.0 # Rotation (radians)
    .rot_av: emb f32t 0.0 # Rotational Angular Velocity (rad/s)
    .radius: emb f32t 1.0 # Radius (km)
    .mass: emb f32t 1.0 # Mass (kg)
    .luminosity: emb u16t 150   # Visual brightness. Although luma are constrained within 1-255,
                                # objects are darker at higher distance scales, so a higher
                                # luminosity will maintain brightness at greater distances
    # Offsets
    def .ACTIVE ($ - .active)
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
sbmk "Menu"

MENU:
    def .MAX_OPTIONS 10

    .name: res u32t 1 # Menu name address
    .x: emb u16t 0 # Menu x position
    .y: emb u16t 0 # Menu y position
    .options_count: emb u8t 0 # Number of options
    .option_names: res u32t 1 # Option names address
    .option_addresses: res u32t 1 # Option addresses array address

    def .NAME (.name - MENU)
    def .X (.x - MENU)
    def .Y (.y - MENU)
    def .OPTIONS_COUNT (.options_count - MENU)
    def .OPTION_NAMES (.option_names - MENU)
    def .OPTION_FUNCS (.option_addresses - MENU)
    def .SIZE ($ - MENU)


#-------------------------------------------------------------------------------
bmk "ARRAYS"

def SYSTEM_SIZE BODY.SIZE*MAX_BODIES
system_bodies: res u8t SYSTEM_SIZE
system_bodies_count: emb u8t 0
smoke: res u8t SMOKE.SIZE*SMOKE.MAX_SMOKE_COUNT
buffer: res u8t MAX_TERMINAL_INPUT_SIZE
menus: res u8t MENU.SIZE*(MENU_COUNT+1)

#-------------------------------------------------------------------------------
bmk "VARIABLES"
SCREENS:
    def .TITLE_SCREEN 0
    def .MAIN_MENU 1
    def .GAME_SCREEN 2

def STARTING_SCREEN SCREENS.TITLE_SCREEN
_current_screen: emb u8t STARTING_SCREEN # Which screen the player is currently in

current_active_menu_index: emb u8t MENUS.NO_MENU # Hold adress of the current active menu
current_menu_selection: emb u8t 0 # Which item on a menu is selected

distance_scale: emb f32t 1.0 # Distance per pixel in km
zoom_value: emb i8t 0 # How far the camera is zoomed out
dt: emb f32t 0.0 # DeltaTime

bg_offset_x: emb f32t 0.0
bg_offset_y: emb f32t 0.0
global_velx: emb f32t 0.0
global_vely: emb f32t 0.0
freecam_pos_x: emb f32t 0.0
freecam_pos_y: emb f32t 0.0
control_camera_offset_scalar: emb i8t 0 # -1, 1, or 1, used for controlling the camera with up and down

visible_editor_value_x: emb u16t 0
visible_editor_value_y: emb u16t 0
visible_editor_value_x_f: emb f32t 0.0
visible_editor_value_y_f: emb f32t 0.0
visible_editor_value_scale: emb i8t 0

selected_body_index: emb i8t -1 # index of planet the cursor is on. -1 for none selected

# Flags
debounce_check: emb u8t false # Only allow new inputs when none are held
player_move_initialized: emb u8t false
game_paused: emb u8t false # Used for pausing the game
smoke_can_spawn: emb u8t false
freecam_enabled: emb u8t false
freecam_relative_velocity_enabled: emb u8t true
editor_enabled: emb u8t false
#zoom_toggled: emb u8t true

#-------------------------------------------------------------------------------
bmk "-------------------------"

#-------------------------------------------------------------------------------
bmk "PROCESSES"

#-------------------------------------------------------------------------------
sbmk "Start"
_start: # Runs once when the VM starts.
    # Initialize your game state here.

    cal load_menus

    #mov a0, -34000.0 # X
    #mov a1, 0.0 # Y
    #mov a2, 0.0 # VELOCITY X
    #mov a3, 0.0 # VELOCITY Y
    #mov a4, 0.000003 # ROTATIONAL ANGULAR VELOCITY
    #mov a5, 20000.0 # RADIUS
    #mov a6, 20000000000.0 # MASS
    #mov a7, 50000 # LUMINOSITY
    #cal add_body

    #mov a0, 0.0 # X
    #mov a1, 0.0 # Y
    #mov a2, 0.0 # VELOCITY X
    #mov a3, 766.96 # VELOCITY Y
    #mov a4, 2*PI/600 # ROTATIONAL ANGLUAR VELOCITY
    #mov a5, 250.0 # RADIUS
    #mov a6, 8000000.0 # MASS
    #mov a7, 200 # LUMINOSITY
    #cal add_body

    #mov a0, -350.0 # X
    #mov a1, 0.0 # Y
    #mov a2, 0.0 # VELOCITY X
    #mov a3, 766.96 - 151.19 # VELOCITY Y
    #mov a4, 2*PI/5 # ROTATIONAL ANGULAR VELOCITY
    #mov a5, 10.0 # RADIUS
    #mov a6, 50000.0 # MASS
    #mov a7, 150 # LUMINOSITY
    #cal add_body

    #mov a0, -5000.0 # X
    #mov a1, 0.0 # Y
    #mov a2, 0.0 # VELOCITY X
    #mov a3, 830.45 # VELOCITY Y
    #mov a4, PI/10 # ROTATIONAL ANGULAR VELOCITY
    #mov a5, 100.0 # RADIUS
    #mov a6, 6500000.0 # MASS --- This one is tricky to take off from, but it's possible!
    #mov a7, 200 # LUMINOSITY
    #cal add_body

    lod u8t, t0, _current_screen

    @title_screen:
        cmp eq, t0, SCREENS.TITLE_SCREEN
        jfs @else+
        cal title_screen_start
        jmp @exit_start+
    @else:
    @main_menu:
        cmp eq, t0, SCREENS.MAIN_MENU
        jfs @else+
        cal main_menu_start
        jmp @exit_start+
    @else:
    @game_screen:
        cmp eq, t0, SCREENS.GAME_SCREEN
        jfs @else+
        cal game_screen_start
        jmp @exit_start+
    @else:
    @exit_start:

    exit

#-------------------------------------------------------------------------------
sbmk "Update"
_update: # Runs at 60 Hz.
    # Write your game logic here.

    syscall SYS_GET_UPDATE_DELTA # Update delta
    str f32t, dt, a0

    lod u8t, t0, _current_screen

    @title_screen:
        cmp eq, t0, SCREENS.TITLE_SCREEN
        jfs @else+
        cal title_screen_update
        jmp @exit_update+
    @else:
    @main_menu:
        cmp eq, t0, SCREENS.MAIN_MENU
        jfs @else+
        cal main_menu_update
        jmp @exit_update+
    @else:
    @game_screen:
        cmp eq, t0, SCREENS.GAME_SCREEN
        jfs @else+
        cal game_screen_update
        jmp @exit_update+
    @else:

    @exit_update:
    syscall SYS_GET_INPUT
    cmp eq, a0, 0
    jfs @end+
    str u8t, debounce_check, false

    @end:
    exit

#-------------------------------------------------------------------------------
sbmk "Draw"
_draw: # Runs at 60 Hz and updates the front buffer.
    # Draw graphics to the screen here.

    lod u8t, t0, _current_screen

    @title_screen:
        cmp eq, t0, SCREENS.TITLE_SCREEN
        jfs @else+
        cal title_screen_draw
        jmp @exit_draw+
    @else:
    @main_menu:
        cmp eq, t0, SCREENS.MAIN_MENU
        jfs @else+
        cal main_menu_draw
        jmp @exit_draw+
    @else:
    @game_screen:
        cmp eq, t0, SCREENS.GAME_SCREEN
        jfs @else+
        cal game_screen_draw
        jmp @exit_draw+
    @else:

    @exit_draw:

    exit

#-------------------------------------------------------------------------------
sbmk "Input"
_input: # Runs when input state changes.
    # a0: Input Bitmask
    # a1: BTN_RIGHT - BTN_LEFT input
    # a2: BTN_DOWN - BTN_UP input
    # a3: BTN_A input
    # a4: BTN_B input
    # a5: BTN_X input
    # a6: BTN_Y input
    # a7: BTN_START input
    # a8: BTN_SELECT input

    syscall SYS_GET_INPUT

    and t0, a0, BTN_LEFT
    cmp neq, t0, 0
    mov t0, cr
    and t1, a0, BTN_RIGHT
    cmp neq, t1, 0
    mov t1, cr
    and t2, a0, BTN_UP
    cmp neq, t2, 0
    mov t2, cr
    and t3, a0, BTN_DOWN
    cmp neq, t3, 0
    mov t3, cr
    sub a1, t1, t0
    sub a2, t3, t2

    and t0, a0, BTN_A
    cmp neq, t0, 0
    mov a3, cr
    and t0, a0, BTN_B
    cmp neq, t0, 0
    mov a4, cr
    and t0, a0, BTN_X
    cmp neq, t0, 0
    mov a5, cr
    and t0, a0, BTN_Y
    cmp neq, t0, 0
    mov a6, cr
    and t0, a0, BTN_START
    cmp neq, t0, 0
    mov a7, cr
    and t0, a0, BTN_SELECT
    cmp neq, t0, 0
    mov a8, cr

    lod u8t, t0, _current_screen

    @title_screen:
        cmp eq, t0, SCREENS.TITLE_SCREEN
        jfs @else+
        cal title_screen_input
        jmp @exit_input+
    @else:
    @main_menu:
        cmp eq, t0, SCREENS.MAIN_MENU
        jfs @else+
        cal main_menu_input
        jmp @exit_input+
    @else:
    @game_screen:
        cmp eq, t0, SCREENS.GAME_SCREEN
        jfs @else+
        cal game_screen_input
        jmp @exit_input+
    @else:
    str u8t, debounce_check, true

    @exit_input:
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
bmk "SCREENS"

#-------------------------------------------------------------------------------
bmk "Title Screen"

#-------------------------------------------------------------------------------
sbmk "Title Screen Start"
title_screen_start:

    ret

#-------------------------------------------------------------------------------
sbmk "Title Screen Update"
title_screen_update:

    ret

#-------------------------------------------------------------------------------
sbmk "Title Screen Draw"
title_screen_draw:

    def .TITLE_SCREEN_SCROLL_SPEED 2.0
    def .MIN_SCROLL_SPEED 0.5

    psh s0
    lod f32t, s0, bg_offset_y
    lod f32t, t0, dt
    fmul t0, .TITLE_SCREEN_SCROLL_SPEED
    flrp t0, s0, fcast SCREEN_HEIGHT , t0
    fsub t0, s0
    fmax t0, .MIN_SCROLL_SPEED
    fadd s0, t0

    fmin s0, fcast SCREEN_HEIGHT
    str f32t, bg_offset_y, s0
    fcti t0, s0

    mov a0, SCREENS_TEXTURES
    vmov a1..a3, 0
    sub a4, SCREEN_HEIGHT, t0
    mov a5, SCREEN_WIDTH
    mov a6, SCREEN_HEIGHT
    mov a7, 0
    syscall SYS_DRAW_TEXTURE_REGION

    # Press Start text
    mov a0, STRINGS.START
    mov a1, SCREEN_WIDTH/2 - 87
    mov a2, -SCREEN_HEIGHT * 3/8
    add a2, t0
    cal draw_string
    pop s0
    ret

#-------------------------------------------------------------------------------
sbmk "Title Screen Input"
title_screen_input:
    # > a0: Input Bitmask
    # > a1: BTN_RIGHT - BTN_LEFT input
    # > a2: BTN_DOWN - BTN_UP input
    # > a3: BTN_A input
    # > a4: BTN_B input
    # > a5: BTN_X input
    # > a6: BTN_Y input
    # > a7: BTN_START input
    # > a8: BTN_SELECT input

    @if_start:
        mov cr, a7
        jfs @endif+
        cal main_menu_start

    @endif:

    ret

#-------------------------------------------------------------------------------
bmk "Main Menu"


def MENU_ITEMS 2

#-------------------------------------------------------------------------------
sbmk "Main Menu Start"
main_menu_start:
    str f32t, bg_offset_x, 0.0
    str f32t, bg_offset_y, 0.0
    str u8t, current_active_menu_index, MENUS.MAIN_MENU
    str u8t, current_menu_selection, 0
    str u8t, _current_screen, SCREENS.MAIN_MENU
    ret

#-------------------------------------------------------------------------------
sbmk "Main Menu Update"
main_menu_update:

    ret


#-------------------------------------------------------------------------------
sbmk "Main Menu Draw"
main_menu_draw:
    vpsh s0..s1

    mov a0, SCREENS_TEXTURES
    vmov a1..a4, 0
    mov a5, SCREEN_WIDTH
    mov a6, SCREEN_HEIGHT
    mov a7, 0
    syscall SYS_DRAW_TEXTURE_REGION

    lod u8t, s0, current_menu_selection

    lod u8t, a1, system_id
    mov a0, buffer
    cal int_to_ascii

    mov a0, buffer
    mov a1, SCREEN_WIDTH/2 + 96
    mov a2, SCREEN_HEIGHT/2 + 24
    cal draw_string

    cal draw_menu

    vpop s0..s1
    ret

#-------------------------------------------------------------------------------
sbmk "Main Menu Input"
main_menu_input:
    # > a0: Input Bitmask
    # > a1: BTN_RIGHT - BTN_LEFT input
    # > a2: BTN_DOWN - BTN_UP input
    # > a3: BTN_A input
    # > a4: BTN_B input
    # > a5: BTN_X input
    # > a6: BTN_Y input
    # > a7: BTN_START input
    # > a8: BTN_SELECT input

    cea menus, t0, MENU.SIZE
    lde u8t, t1, MENU.OPTIONS_COUNT
    lod u8t, t2, current_menu_selection
    add t2, a2
    mod t2, t1
    str u8t, current_menu_selection, t2
    lde u32t, t3, MENU.OPTION_FUNCS

    cea t3, t2, 4
    lde u32t, t4, 0

    cala t4
    str u8t, player_move_initialized, false
    str u8t, debounce_check, true
    ret

#-------------------------------------------------------------------------------
bmk "Game Screen"

#-------------------------------------------------------------------------------
sbmk "Game Screen Start"
game_screen_start:
    str f32t, bg_offset_x, 0.0
    str f32t, bg_offset_y, 0.0
    cal update_collisions # Update collisions to fix overlapping positions
    mov a0, false
    cal center_camera
    str u8t, _current_screen, SCREENS.GAME_SCREEN
    ret

#-------------------------------------------------------------------------------
sbmk "Game Screen Update"
game_screen_update:

    psh s0
    lod f32t, t0, dt

    cmp flt, t0, 1.0 # Skip this update if the framerate is too low to avoid physics issues
    jfs @end_update+

    str u8t, smoke_can_spawn, false

    lod u8t, cr, game_paused
    jtr @end_update+
    @if_editor_enabled:
        lod u8t, cr, editor_enabled
        jfs @endif+

        cal freecam_input
        cal update_selected_body
        jmp @end_update+
    @endif:


    mov s0, zr
    cal update_gravity
    cal check_player_input
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

    @is_freecam_disabled:
        lod u8t, t0, editor_enabled
        lod u8t, cr, freecam_enabled
        orr cr, t0
        jtr @endif+
        mov a0, true
        cal center_camera
    @endif:

    @end_update:
    pop s0
    ret

#-------------------------------------------------------------------------------
sbmk "Game Screen Draw"
game_screen_draw:
    cal draw_background
    cal draw_smoke
    cal draw_bodies
    cal draw_player
    cal draw_hud
    cal draw_menu

    ret

#-------------------------------------------------------------------------------
sbmk "Game Screen Input"
game_screen_input:
    # > a0: Input Bitmask
    # > a1: BTN_RIGHT - BTN_LEFT input
    # > a2: BTN_DOWN - BTN_UP input
    # > a3: BTN_A input
    # > a4: BTN_B input
    # > a5: BTN_X input
    # > a6: BTN_Y input
    # > a7: BTN_START input
    # > a8: BTN_SELECT input

    vpsh s0..s4

    @debounce_check:
        lod u8t, cr, debounce_check
        jfs @end+
        orr t0, INPUT.ZOOM_IN, INPUT.ZOOM_OUT
        and a0, t0
        vmov a1..a7, 0
        #jmp @end_input+
    @end:

    # Zoom in
    and t0, a0, INPUT.ZOOM_IN
    cmp neq, t0, 0
    mov s0, cr

    # Zoom out
    and t0, a0, INPUT.ZOOM_OUT
    cmp neq, t0, 0
    mov s1, cr

    sub s0, s1, s0

    # Pause
    and t0, a0, INPUT.PAUSE
    cmp neq, t0, 0
    mov s2, cr

    # freecam
    and t0, a0, INPUT.FREE_CAM
    cmp neq, t0, 0
    mov s3, cr

    # Toggle velocity relativity
    and t0, a0, INPUT.MATCH_VELOCITY
    cmp neq, t0, 0
    mov s4, cr

    @zoom:
        cmp neq, s0, 0
        jfs @end+
        #lod u8t, t0, editor_enabled
        #lod u8t, t1, current_menu_selection
        #cmp neq, t1, 0
        #and cr, t0
        #jtr @end+


        #fmul s0, ZOOM_STEP
        lod f32t, t0, distance_scale
        lod i8t, t1, zoom_value
        add t1, s0
        pow t2, 2, t1
        fctf t2
        fclp t2, MIN_ZOOM, MAX_ZOOM
        cmp eq, t2, t0 # Don't call if nothing changed
        jtr @end+
        mov a0, t2
        str i8t, zoom_value, t1
        cal set_distance_scale
        str u8t, debounce_check, true
    @end:

    @editor_enabled:
        lod u8t, cr, editor_enabled
        jfs @endif+
        cal check_editor_input
        str u8t, debounce_check, true
        jmp @end_input+
    @endif:

    @toggle_pause:
        mov cr, s2
        jfs @end+
        lod u8t, cr, game_paused
        sel t0, false, true
        str u8t, game_paused, t0
        sel t0, MENUS.NO_MENU, MENUS.PAUSE_MENU
        str u8t, current_active_menu_index, t0
        str u8t, current_menu_selection, 0
        str u8t, debounce_check, true
        jmp @end_input+
    @end:

    @if_menu_active:
        lod u8t, t0, current_active_menu_index
        cmp neq, t0, 0
        jfs @endif+

        cea menus, t0, MENU.SIZE
        lde u8t, t1, MENU.OPTIONS_COUNT
        lod u8t, t2, current_menu_selection
        add t2, a2
        mod t2, t1
        str u8t, current_menu_selection, t2
        lde u32t, t3, MENU.OPTION_FUNCS

        cea t3, t2, 4
        lde u32t, t4, 0

        cala t4
        str u8t, player_move_initialized, false
        str u8t, debounce_check, true
        jmp @end_input+
    @endif:

    @toggle_freecam:
        mov cr, s3
        jfs @end+
        str f32t, freecam_pos_x, 0.0
        str f32t, freecam_pos_y, 0.0
        lod u8t, t0, freecam_enabled
        cmp eq, t0, false
        str u8t, freecam_enabled, cr
        jtr @end+
        mov a0, false
        cal center_camera # Center back on player if freecam is disabled
        str u8t, debounce_check, true
        jmp @end_input+
    @end:

    @toggle_relative_velocity: # Toggles freecam between player relative velocity and global velocity
        mov cr, s4
        jfs @end+
        lod u8t, cr, freecam_enabled
        jfs @end+
        lod u8t, cr, game_paused
        jtr @end+
        lod u8t, t0, freecam_relative_velocity_enabled
        cmp eq, t0, false
        str u8t, freecam_relative_velocity_enabled, cr
        str u8t, debounce_check, true
    @end:

    @end_input:
    vpop s0..s4
    ret

#-------------------------------------------------------------------------------
bmk "-------------------------"

#-------------------------------------------------------------------------------
bmk "MENUS"

sbmk "Main Menu"
MAIN_MENU:
    def .POS_X SCREEN_WIDTH/2 - 112
    def .POS_Y SCREEN_HEIGHT/2
    .MENU_NAME: emb string ""
    def .OPTIONS_COUNT 3
    .OPTION_NAMES: emb string "SYSTEM SLOT:\nNEW SYSTEM\nLOAD SYSTEM"
    .OPTION_FUNCS: emb u32t .system_slot, .new_system, .load_system

    .system_slot:
        lod u8t, t0, system_id
        add t0, a1
        cmp eq, t0, 0
        mvc t0, 255
        cmp eq, t0, 256
        mvc t0, 1
        clp t0, 1, 255
        str u8t, system_id, t0
        ret

    .new_system:
        mov cr, a3
        jfs @end+
        psh s0
        lod u8t, s0, system_id
        mov a0, 0
        cal load_system
        str u8t, system_id, s0
        pop s0
        cal game_screen_start
        str u8t, current_active_menu_index, MENUS.NO_MENU
        @end:
        ret

    .load_system:
        mov cr, a3
        jfs @end+
        lod u8t, a0, system_id
        cal load_system
        cal game_screen_start
        str u8t, current_active_menu_index, MENUS.NO_MENU
        @end:
        ret

sbmk "Pause Menu"
PAUSE_MENU:
    def .POS_X SCREEN_WIDTH/2 - 96
    def .POS_Y SCREEN_HEIGHT/2 - 48
    .MENU_NAME: emb string "GAME PAUSED"
    def .OPTIONS_COUNT 5
    .OPTION_NAMES: emb string "TOGGLE EDITOR\nSYSTEM SLOT:\nSAVE SYSTEM\nLOAD SYSTEM\nEXIT SYSTEM"
    .OPTION_FUNCS: emb u32t .toggle_editor, .system_slot, .save_system, .reset, .exit_system

    .toggle_editor:
        mov cr, a3
        jfs @end+
        lod u8t, t0, editor_enabled
        cmp eq, t0, false
        str u8t, editor_enabled, cr
        #str u8t, freecam_relative_velocity_enabled, cr
        str u8t, game_paused, false
        str u8t, freecam_enabled, false
        str u8t, current_active_menu_index, 0
        @end:

        ret

    .system_slot:
        lod u8t, t0, system_id
        add t0, a1
        cmp eq, t0, 0
        mvc t0, 255
        cmp eq, t0, 256
        mvc t0, 1
        clp t0, 1, 255
        str u8t, system_id, t0
        ret

    .save_system:
        mov cr, a3
        jfs @end+
        lod u8t, a0, system_id
        cal save_system
        str u8t, game_paused, false
        str u8t, freecam_enabled, false
        str u8t, current_active_menu_index, 0
        @end:
        ret

    .reset:
        mov cr, a3
        jfs @end+
        str u8t, current_active_menu_index, 0
        str u8t, game_paused, 0
        #lod u8t, a0, system_id
        #cal load_system
        cal reset_system
        cal update_positions
        cal update_collisions
        @end:

        ret

    .exit_system:
        mov cr, a3
        jfs @end+
        str u8t, current_active_menu_index, 0
        str u8t, game_paused, 0
        cal main_menu_start
        @end:
        ret


#-------------------------------------------------------------------------------
bmk "-------------------------"

#-------------------------------------------------------------------------------
bmk "FUNCTIONS"

#-------------------------------------------------------------------------------
bmk "Data Management"

def SYSTEM_DATA_SIZE PLAYER.SIZE + SYSTEM_SIZE + STRINGS.DATA_HEADER_SIZE + 2 # Additional bytes to hold the system id and body count

#-------------------------------------------------------------------------------
sbmk "Save System Data"
save_system:
    # Saves system data to storage
    # > a0: System ID

    vpsh s0..s1
    mov s0, a0

    @valid_id_check:
        cmp gte, s0, 1
        mov t0, cr
        cmp lte, s0, 255
        and cr, t0
        jtr @end_check+
        mov a0, STRINGS.ERR_INVALID_SYSTEM_ID
        syscall SYS_PRINT_LINE_STRING
        jmp @end+
    @end_check:

    # Save system ID header
    mul a0, s0, SYSTEM_DATA_SIZE
    mov a1, STRINGS.SYS_DATA_HEADER
    mov a2, STRINGS.SYS_DATA_HEADER_SIZE
    syscall SYS_STORAGE_WRITE
    add a0, a2 # Increment pointer

    mov s1, 2
    @loop: # Convert system ID to ASCII and store
        mov a1, s1
        mov s1, a0
        mov a0, s0
        cal get_digit_int
        mov t0, a0
        mov a0, s1
        mov s1, a1
        add t0, 48 # Convert to ASCII
        str u8t, system_id, t0

        mov a1, system_id
        mov a2, 1
        syscall SYS_STORAGE_WRITE
        add a0, a2
        dec s1
        cmp lt, s1, 0
        jfs @loop-
    @endloop:

    str u8t, system_id, s0 # restore system ID variable


    # Save system ID
    mov a1, system_id
    mov a2, 1
    syscall SYS_STORAGE_WRITE
    add a0, a2


    # Save player data header
    mov a1, STRINGS.PLAYER_DATA_HEADER
    mov a2, STRINGS.PLAYER_DATA_HEADER_SIZE
    syscall SYS_STORAGE_WRITE
    add a0, a2

    # Save player data
    mov a1, PLAYER
    mov a2, PLAYER.SIZE
    syscall SYS_STORAGE_WRITE
    add a0, a2

    # Save body data header
    mov a1, STRINGS.BODIES_DATA_HEADER
    mov a2, STRINGS.BODIES_DATA_HEADER_SIZE
    syscall SYS_STORAGE_WRITE
    add a0, a2 # Increment pointer

    # Save body data
    mov a1, system_bodies_count
    mov a2, 1
    syscall SYS_STORAGE_WRITE
    add a0, a2

    mov a1, system_bodies
    mov a2, SYSTEM_SIZE
    syscall SYS_STORAGE_WRITE
    add a0, a2

    @end:
    mov a0, s0
    vpop s0..s1
    ret

#-------------------------------------------------------------------------------
sbmk "Load System Data"
load_system:
    # Loads system data from storage
    # > a0: System ID

    psh s0
    mov s0, a0

    @valid_id_check:
        cmp gte, s0, 0
        mov t0, cr
        cmp lte, s0, 255
        and cr, t0
        jtr @end_check+
        mov a0, STRINGS.ERR_INVALID_SYSTEM_ID
        syscall SYS_PRINT_LINE_STRING
        jmp @end+
    @end_check:

    # Load system ID
    #mov a0, system_id
    fma a1, s0, SYSTEM_DATA_SIZE, STRINGS.SYS_DATA_HEADER_SIZE + 4
    #mov a2, 1
    #syscall SYS_STORAGE_READ
    #add a1, 1

    # Load Player data
    mov a0, PLAYER
    add a1, STRINGS.PLAYER_DATA_HEADER_SIZE
    mov a2, PLAYER.SIZE
    syscall SYS_STORAGE_READ
    add a1, a2

    # Load body data
    mov a0, system_bodies_count
    add a1, STRINGS.BODIES_DATA_HEADER_SIZE
    mov a2, 1
    syscall SYS_STORAGE_READ
    add a1, a2

    mov a0, system_bodies
    mov a2, SYSTEM_SIZE
    syscall SYS_STORAGE_READ
    add a1, a2

    str u8t, PLAYER.is_alive, true
    str u8t, PLAYER.can_move, true
    str f32t, PLAYER.collision_radius, PLAYER_SPRITE_WIDTH_F/2.0
    str i8t, PLAYER.parent_body_index, -1
    str u8t, player_move_initialized, false
    str f32t, PLAYER.rot, -PI/2
    mov a0, false
    cal center_camera

    @end:
    pop s0
    ret

#-------------------------------------------------------------------------------
sbmk "Reset System"
reset_system:
    # Reset values to default

    lod u8t, a0, system_id
    cal load_system
    #str f32t, bg_offset_x, 0.0
    #str f32t, bg_offset_y, 0.0
    cal update_collisions
    ret

#-------------------------------------------------------------------------------
sbmk "Load Menus"
load_menus:

    # Main menu
    cea menus, MENUS.MAIN_MENU, MENU.SIZE
    ste u32t, MENU.NAME, MAIN_MENU.MENU_NAME
    ste u16t, MENU.X, MAIN_MENU.POS_X
    ste u16t, MENU.Y, MAIN_MENU.POS_Y
    ste u8t, MENU.OPTIONS_COUNT, MAIN_MENU.OPTIONS_COUNT
    ste u32t, MENU.OPTION_NAMES, MAIN_MENU.OPTION_NAMES
    ste u32t, MENU.OPTION_FUNCS, MAIN_MENU.OPTION_FUNCS

    # Pause menu
    cea menus, MENUS.PAUSE_MENU, MENU.SIZE
    ste u32t, MENU.NAME, PAUSE_MENU.MENU_NAME
    ste u16t, MENU.X, PAUSE_MENU.POS_X
    ste u16t, MENU.Y, PAUSE_MENU.POS_Y
    ste u8t, MENU.OPTIONS_COUNT, PAUSE_MENU.OPTIONS_COUNT
    ste u32t, MENU.OPTION_NAMES, PAUSE_MENU.OPTION_NAMES
    ste u32t, MENU.OPTION_FUNCS, PAUSE_MENU.OPTION_FUNCS

    ret

#-------------------------------------------------------------------------------
sbmk "Load String to Buffer"
load_string:
    # > a0*: String address
    # < a0: String size

    mov t0, a0
    mov a0, zr
    @loop:
        add t1, t0, a0
        add t2, buffer, a0
        lod u8t, t3, t1
        str u8t, t2, t3
        cmp eq, t3, 0
        jtr @endloop+
        inc a0
        jmp @loop-
    @endloop:
    ret

#-------------------------------------------------------------------------------
bmk "Spawning"

#-------------------------------------------------------------------------------
sbmk "Add Body"
add_body:
    # > (f32t) a0..a1: x, y position (from center of screen)
    # > (f32t) a2..a3: x, y velocity
    # > (f32t) a4: rotation speed
    # > (f32t) a5: radius
    # > (f32t) a6: mass
    # > (u8t)  a7: luma
    # < a0: Body index

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

    psh s0

    lod u8t, s0, system_bodies_count
    cmp lt, s0, MAX_BODIES
    jfs @end+

    # Find first open address
    mov t0, zr
    @loop:
        cea system_bodies, t0, BODY.SIZE
        lde u8t, cr, BODY.ACTIVE
        jfs @endloop+
        inc t0
        cmp gte, t0, MAX_BODIES
        jtr @end+
        jmp @loop-
    @endloop:

    ste u8t, BODY.ACTIVE, true
    ste f32t, BODY.X, a0 # Set X pos
    ste f32t, BODY.Y, a1 # Set Y pos
    ste f32t, BODY.VX, a2 # Set X velocity (km/s)
    ste f32t, BODY.VY, a3 # Set Y velocity (km/s)
    ste f32t, BODY.ROT, 0.0 # Set body rotation
    ste f32t, BODY.ROT_AV, a4 # Set body rotational angular velocity (rad/s)
    ste f32t, BODY.R, a5 # Set body radius (km)
    ste f32t, BODY.M, a6 # Set mass (kg)
    ste u16t, BODY.LUM, a7 # Set luminosity

    inc s0
    str u8t, system_bodies_count, s0

    mov a0, t0

    @end:
    pop s0
    ret

#-------------------------------------------------------------------------------
sbmk "Remove Body"
remove_body:
    # > a0: body_index

    cea system_bodies, a0, BODY.SIZE
    ste u8t, BODY.ACTIVE, false
    lod u8t, t0, system_bodies_count
    dec t0
    str u8t, system_bodies_count, t0
    lod u8t, t0, PLAYER.parent_body_index
    cmp eq, t0, a0
    sel t0, -1, t0
    str u8t, PLAYER.parent_body_index, t0
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
    vpsh s0..s5

    mov s3, zr # Strongest gravitational influence on player
    mov s0, zr
    mov s4, zr # Num active bodies counted
    @loop_bodies:
        cmp lt, s0, MAX_BODIES
        jfs @endloop_bodies+
        lod u8t, t0, system_bodies_count
        cmp gte, s4, t0
        jtr @endloop_bodies+
        cea system_bodies, s0, BODY.SIZE
        lde u8t, cr, BODY.ACTIVE
        jfs @skip+
        inc s4
        mov s1, zr
        mov s5, zr
        # Other Bodies
        @loop2:
            cmp lt, s1, MAX_BODIES
            jfs @endloop2+
            lod u8t, t0, system_bodies_count
            cmp gte, s5, t0
            jtr @endloop2+
            cea system_bodies, s1, BODY.SIZE
            lde u8t, cr, BODY.ACTIVE
            jfs @skip2+
            inc s5
            cmp eq, s1, s0
            jtr @skip2+

            cea system_bodies, s0, BODY.SIZE
            lde f32t, a0, BODY.X
            lde f32t, a1, BODY.Y
            lde f32t, a2, BODY.VX
            lde f32t, a3, BODY.VY
            lde f32t, a4, BODY.M
            cea system_bodies, s1, BODY.SIZE
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

            cea system_bodies, s0, BODY.SIZE
            ste f32t, BODY.VX, a2
            ste f32t, BODY.VY, a3

            @skip2:
            inc s1
            jmp @loop2-
        @endloop2:


        # Player
        lod f32t, a0, PLAYER.x
        lod f32t, a1, PLAYER.y
        lod f32t, a2, PLAYER.velx
        lod f32t, a3, PLAYER.vely
        lod f32t, a4, PLAYER.mass

        cea system_bodies, s0, BODY.SIZE
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

        @skip:

        inc s0
        jmp @loop_bodies-
    @endloop_bodies:
    vpop s0..s5
    ret

#-------------------------------------------------------------------------------
sbmk "Update Positions"
update_positions:
    # s0: body index
    # s1: deltatime
    # s2: distance_scale

    vpsh s0..s3

    lod f32t, s1, dt
    lod f32t, s2, distance_scale

    mov s0, zr
    mov s3, zr
    @loop_bodies:
        cmp lt, s0, MAX_BODIES
        jfs @endloop_bodies+
        lod u8t, t0, system_bodies_count
        cmp gte, s3, t0
        jtr @endloop_bodies+
        cea system_bodies, s0, BODY.SIZE
        lde u8t, cr, BODY.ACTIVE
        jfs @skip+
        inc s3

        lde f32t, t0, BODY.X
        lde f32t, t1, BODY.Y
        lde f32t, t2, BODY.VX
        lde f32t, t3, BODY.VY
        lde f32t, t4, BODY.ROT
        lde f32t, t5, BODY.ROT_AV

        # Apply distance scale
        #fdiv t2, s2
        #fdiv t3, s2

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
        @skip:

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
        cea system_bodies, t2, BODY.SIZE
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
        #lod f32t, t0, global_velx
        #lod f32t, t1, global_vely
        #fatan2 t2, t1, t0
        #fmod t2, 2.0*PI
        #mov t3, 0.0
        #cmp flt, t2, 0.0
        #mvc t3, 2.0*PI
        #fadd t2, t3
        #str f32t, PLAYER.rot, t2
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

    vpop s0..s3
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


    vpsh s0..s15

    mov s0, zr
    mov s4, zr
    @loop_bodies:
        cmp lt, s0, MAX_BODIES
        jfs @endloop_bodies+
        lod u8t, t0, system_bodies_count
        cmp gte, s4, t0
        jtr @endloop_bodies+
        cea system_bodies, s0, BODY.SIZE
        lde u8t, cr, BODY.ACTIVE
        jfs @skip+
        inc s4

        mov s1, zr
        mov s15, zr
        @loop2:
            cmp lt, s1, MAX_BODIES
            jfs @endloop2+
            cmp eq, s1, s0
            jtr @skip+
            lod u8t, t0, system_bodies_count
            cmp gte, s15, t0
            jtr @endloop2+
            cea system_bodies, s1, BODY.SIZE
            lde u8t, cr, BODY.ACTIVE
            jfs @skip2+
            inc s15

            mov a0, s0
            mov a1, s1
            cal check_collision
            jfs @skip2+
            cea system_bodies, s0, BODY.SIZE
            lde f32t, t0, BODY.X
            lde f32t, t1, BODY.Y
            lde f32t, t2, BODY.VX
            lde f32t, t3, BODY.VY
            lde f32t, t4, BODY.M
            cea system_bodies, s1, BODY.SIZE
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

            cmp gt, t9, t4
            sel t0, s1, s0
            sel t1, s0, s1

            cea system_bodies, t0, BODY.SIZE
            lde f32t, t2, BODY.X
            lde f32t, t3, BODY.Y
            lde f32t, t4, BODY.R
            cea system_bodies, t1, BODY.SIZE
            lde f32t, t5, BODY.X
            lde f32t, t6, BODY.Y
            lde f32t, t7, BODY.R
            fsub a0, t5, t2
            fsub a1, t6, t3
            vpsh t0..t7
            cal normal_vector
            vpop t0..t7

            fadd t8, t4, t7
            ffma t5, a0, t8, t2
            ffma t6, a1, t8, t3

            cea system_bodies, t1, BODY.SIZE
            ste f32t, BODY.X, t5
            ste f32t, BODY.Y, t6


            @skip2:
            inc s1
            jmp @loop2-
        @endloop2:
        @skip:
        inc s0
        jmp @loop_bodies-
    @endloop_bodies:

    # Player collisions
    mov s0, zr
    mov s1, zr
    @loop:
        cmp lt, s0, MAX_BODIES
        jfs @endloop+
        lod u8t, t0, system_bodies_count
        cmp gte, s1, t0
        jtr @endloop+
        cea system_bodies, s0, BODY.SIZE
        lde u8t, cr, BODY.ACTIVE
        jfs @skip+
        inc s1

        @if_player_colliding:
            mov a0, s0
            cal check_player_collision
            jfs @endif+
            lod f32t, t0, PLAYER.x
            lod f32t, t1, PLAYER.y
            cea system_bodies, s0, BODY.SIZE
            lde f32t, t2, BODY.X
            lde f32t, t3, BODY.Y
            lde f32t, t4, BODY.R
            lde f32t, t5, BODY.VX
            lde f32t, t6, BODY.VY

            # Get normal vector
            fsub a0, t0, t2 # dx
            fsub a1, t1, t3 # dy
            fadd t8, a0, a1
            cmp eq, t8, 0.0
            fsub t8, a1, 1.0
            mvc a1, t8
            cal normal_vector
            vmov t13..t15, a0..

            lod f32t, t11, PLAYER.collision_radius
            fadd t10, t4, t11

            ffma t11, a0, t10, t2 # Move player to radius
            ffma t12, a1, t10, t3
            str f32t, PLAYER.x, t11
            str f32t, PLAYER.y, t12

            str i8t, PLAYER.parent_body_index, s0

            vpsh t0..t15

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

            vpop t0..t15
            cea system_bodies, s0, BODY.SIZE
            lde f32t, t5, BODY.VX
            lde f32t, t6, BODY.VY
            lde f32t, t7, BODY.ROT_AV

            # Angular velocity from planets rotation

            # Get tangent vector
            fneg t8, t14
            mov t9, t13

            # Calculate velocity vector
            fmul t15, t10, t7
            fmul t2, t8, t15
            fmul t3, t9, t15

            # Apply rotational angular velocity
            fadd t5, t2
            fadd t6, t3

            str f32t, PLAYER.velx, t5
            str f32t, PLAYER.vely, t6

            str u8t, PLAYER.is_grounded, true
            jmp @end+
        @endif:
        @skip:
        inc s0
        jmp @loop-
    @endloop:
        str u8t, PLAYER.is_grounded, false
    @end:

    vpop s0..s15
    ret

#-------------------------------------------------------------------------------
sbmk "Update Velocities"
update_velocities:
    # Recalculate velocities relative to the player
    # s0..s1: Player x,y velocity
    vpsh s0..s1

    @if_freecam_enabled: # If freecam is enabled, determine whether velocity is relative to the player or global
        lod u8t, t0, editor_enabled
        lod u8t, t1, freecam_enabled
        lod u8t, cr, freecam_relative_velocity_enabled
        not cr
        and cr, t1
        orr cr, t0
        jfs @else+
        lod f32t, s0, global_velx
        lod f32t, s1, global_vely
        fneg s0
        fneg s1
        jmp @endif+
    @else:
        lod f32t, s0, PLAYER.velx
        lod f32t, s1, PLAYER.vely
    @endif:

    mov t15, zr
    mov t14, zr
    @loop_bodies:
        cmp lt, t15, MAX_BODIES
        jfs @endloop_bodies+
        lod u8t, t0, system_bodies_count
        cmp gte, t14, t0
        jtr @endloop_bodies+
        cea system_bodies, t15, BODY.SIZE
        lde u8t, cr, BODY.ACTIVE
        jfs @skip+
        inc t14

        lde f32t, t0, BODY.VX
        lde f32t, t1, BODY.VY

        fsub t0, s0
        fsub t1, s1

        ste f32t, BODY.VX, t0
        ste f32t, BODY.VY, t1

        @skip:
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

    @if_freecam_enabled:
        lod u8t, t0, editor_enabled
        lod u8t, t1, freecam_enabled
        lod u8t, cr, freecam_relative_velocity_enabled
        not cr
        and cr, t1
        orr cr, t0
        jfs @else+
        lod f32t, t0, PLAYER.velx
        lod f32t, t1, PLAYER.vely
        fsub t0, s0
        fsub t1, s1
        str f32t, PLAYER.velx, t0
        str f32t, PLAYER.vely, t1

        str f32t, global_velx, 0.0
        str f32t, global_vely, 0.0
        jmp @endif+
    @else:
        lod f32t, t0, global_velx
        lod f32t, t1, global_vely
        fadd t0, s0
        fadd t1, s1
        str f32t, global_velx, t0
        str f32t, global_vely, t1

        str f32t, PLAYER.velx, 0.0
        str f32t, PLAYER.vely, 0.0
    @endif:

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
sbmk "Check Player Input"
check_player_input:
    # Get input states
    # s0: Right - Left
    # s1: Down - Up
    # s2: Jump
    # s3: Kill Velocity

    vpsh s0..s3

    syscall SYS_GET_INPUT
    and t0, a0, BTN_LEFT
    cmp neq, t0, 0
    mov t0, cr
    and t1, a0, BTN_RIGHT
    cmp neq, t1, 0
    mov t1, cr
    and t2, a0, BTN_UP
    cmp neq, t2, 0
    mov t2, cr
    and t3, a0, BTN_DOWN
    cmp neq, t3, 0
    mov t3, cr
    sub s0, t1, t0
    sub s1, t3, t2

    and t0, a0, INPUT.JUMP
    cmp neq, t0, 0
    mov s2, cr

    and t0, a0, INPUT.MATCH_VELOCITY
    cmp neq, t0, 0
    mov s3, cr

    str u8t, PLAYER.is_flying, false
    str i8t, control_camera_offset_scalar, 0
    str f32t, PLAYER.movex, 0.0 # Reset movement
    str f32t, PLAYER.movey, 0.0

    @freecam:
        lod u8t, t0, editor_enabled
        lod u8t, t1, current_menu_selection
        cmp eq, t1, 0
        and t0, cr
        lod u8t, cr, freecam_enabled
        orr cr, t0
        jfs @end+

        fctf t0, s0
        fctf t1, s1
        fmul a0, t0, FREECAM_SPEED
        fmul a1, t1, FREECAM_SPEED
        lod f32t, t2, distance_scale
        fmul a0,t2
        fmul a1, t2
        lod f32t, t2, dt
        fmul a0, t2
        fmul a1, t2
        lod f32t, t0, freecam_pos_x
        lod f32t, t1, freecam_pos_y
        fadd a0, t0
        fadd a1, t1
        cal move_camera
        jmp @end_input+
    @end:

    @init_player:
        lod u8t, cr, player_move_initialized
        jtr @endif+
        cmp neq, s2, true # Player has to release a button to avoid it bleeding over from the menu
        jfs @end_input+
        str u8t, player_move_initialized, true
        jmp @end_input+
    @endif:

    @if_not_can_move:
        lod u8t, cr, PLAYER.can_move
        jtr @endif+
        vmov s0..s3, 0
    @endif:

    @is_grounded:
        lod u8t, cr, PLAYER.is_grounded
        jfs @else+
        @is_jump_pressed:
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
        str i8t, control_camera_offset_scalar, s1
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
        fctf a0, s0
        fctf a1, s1
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

    @end_input:

    vpop s0..s3
    ret

#-------------------------------------------------------------------------------
sbmk "Player Move"
player_move:
    # a0: horizontal direction
    # a1: vertical direction

    vpsh s0..s1
    vmov s0..s1, a0..
    @if_grounded:
        lod u8t, cr, PLAYER.is_grounded
        jfs @else+
        cmp neq, s0, 0.0
        jfs @endif+
        lod i8t, t0, PLAYER.parent_body_index
        cmp lt, t0, 0
        jtr @else+
        cea system_bodies, t0, BODY.SIZE
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
    @flip_sprite:
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
    cea system_bodies, t0, BODY.SIZE
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

    vpsh s0..s1
    mov s1, t9
    fsub s1, PLAYER.MIN_JUMP_CHARGE
    fdiv s1, PLAYER.MAX_JUMP_CHARGE
    mov s0, zr
    str u8t, smoke_can_spawn, true
    @loop:
        mov a0, s0
        mov a1, PI - PI/6
        mov a2, PI + PI/6
        #mov a3, SMOKE.MIN_VEL_SCALE
        fmul t0, s1, 0.8
        fmul t1, s1, 1.0
        mov a3, t0
        mov a4, t1
        #mov a4, SMOKE.MIN_VEL_SCALE
        cal spawn_smoke
        inc s0
        cmp lt, s0, 15
        jtr @loop-
    @endloop:
    vpop s0..s1
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

    @if_player_grounded: # If player is grounded, halve move speed and cancel jump. Helpful for low-gravity bodies
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
        lod i8t, t2, PLAYER.parent_body_index # Match velocity to parent body, or global if no parent body exists
        cmp gt, t2, -1
        lod f32t, a0, global_velx
        lod f32t, a1, global_vely
        fneg a0
        fneg a1
        cea system_bodies, t2, BODY.SIZE
        lde f32t, t0, BODY.VX
        lde f32t, t1, BODY.VY
        mvc a0, t0
        mvc a1, t1
        cal normal_vector
        cmp fgt, a2, 0.01
        jfs @end+
        cal player_move
    @end:
    str u8t, PLAYER.can_jump, false # Don't allow jumping until both keys are released
    ret

#-------------------------------------------------------------------------------
sbmk "Freecam Input"
freecam_input:
    # Get input states
    # s0: Right - Left
    # s1: Down - Up

    vpsh s0..s1

    syscall SYS_GET_INPUT
    and t0, a0, BTN_LEFT
    cmp neq, t0, 0
    mov t0, cr
    and t1, a0, BTN_RIGHT
    cmp neq, t1, 0
    mov t1, cr
    and t2, a0, BTN_UP
    cmp neq, t2, 0
    mov t2, cr
    and t3, a0, BTN_DOWN
    cmp neq, t3, 0
    mov t3, cr
    sub s0, t1, t0
    sub s1, t3, t2

    str u8t, PLAYER.is_flying, false
    str i8t, control_camera_offset_scalar, 0
    str f32t, PLAYER.movex, 0.0 # Reset movement
    str f32t, PLAYER.movey, 0.0

    @freecam:
        lod u8t, t0, editor_enabled
        lod u8t, t1, current_menu_selection
        cmp eq, t1, 0
        and t0, cr
        lod u8t, cr, freecam_enabled
        orr cr, t0
        jfs @end+

        fctf t0, s0
        fctf t1, s1
        fmul a0, t0, FREECAM_SPEED
        fmul a1, t1, FREECAM_SPEED
        lod f32t, t2, distance_scale
        fmul a0,t2
        fmul a1, t2
        lod f32t, t2, dt
        fmul a0, t2
        fmul a1, t2
        lod f32t, t0, freecam_pos_x
        lod f32t, t1, freecam_pos_y
        fadd a0, t0
        fadd a1, t1
        cal move_camera
        jmp @end_input+
    @end:

    @end_input:

    vpop s0..s1
    ret

#-------------------------------------------------------------------------------
bmk "Physics"

#-------------------------------------------------------------------------------
sbmk "Check Collision"
check_collision:
    # > a0: body1 index
    # > a1: body2 index
    cea system_bodies, a0, BODY.SIZE
    lde f32t, t0, BODY.X
    lde f32t, t1, BODY.Y
    lde f32t, t2, BODY.VX
    lde f32t, t3, BODY.VY
    lde f32t, t4, BODY.R

    cea system_bodies, a1, BODY.SIZE
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

    # Check if distance is less than radii
    cmp flt, t2, t4
    ret

#-------------------------------------------------------------------------------
sbmk "Check Player Collision"
check_player_collision:
    # > a0: body index
    cea system_bodies, a0, BODY.SIZE
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
    cmp eq, t2, 0.0
    mvc a0, 0.0
    mvc a1, 0.0
    mvc a2, 0.0
    jtr @end+
    # Normal Vector
    fsqrt t3, t2 # r
    fdiv t0, t3 # dx/r
    fdiv t1, t3 # dy/r

    fpow t2, t3, 2.0 # r^2

    # Calculate gravitational acceleration
    fmul t3, a4, G # G*m2 since we'll be dividing by m1 anyway, no point including it
    fdiv t3, t2

    # Get acceleration vector
    fmul a0, t0, t3
    fmul a1, t1, t3
    mov a2, t3

    @end:
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

    cea system_bodies, a2, BODY.SIZE
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
    vpsh s0..s1

    def .PLAYER_MAX_DRAW_DISTANCE 128.0 # Distance scale before player is no longer drawn

    lod u8t, cr, PLAYER.is_alive
    jfs @skipdraw+

    lod f32t, s0, distance_scale # Don't draw a microscopic player
    cmp fgt, s0, .PLAYER_MAX_DRAW_DISTANCE
    jtr @skipdraw+


    @if_zoomed_out:
        cmp fgt, s0, 4.0
        jfs @else+
        lod f32t, t0, PLAYER.x
        lod f32t, t1, PLAYER.y
        ffma t0, s0, CENTER_X_F, t0
        ffma t1, s0, CENTER_Y_F, t1
        # Apply distance scale
        fdiv t0, s0
        fdiv t1, s0
        frou t0
        frou t1
        fcti t0
        fcti t1
        # Draw player as a dot
        @is_offscreen:
            cmp lt, t0, 0
            jtr @endif+
            cmp lt, t1, 0
            jtr @endif+
            cmp lt, t0, SCREEN_WIDTH
            jfs @endif+
            cmp lt, t1, SCREEN_HEIGHT
            jfs @endif+
            sbpx t0, t1, 255
        jmp @endif+
    @else:
        mov a0, PLAYER_SPRITESHEET
        # Draw pos
        lod f32t, t0, PLAYER.x
        lod f32t, t1, PLAYER.y
        ffma t0, s0, CENTER_X_F, t0
        ffma t1, s0, CENTER_Y_F, t1
        # Apply distance scale
        fdiv t0, s0
        fdiv t1, s0
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
        #fdiv s1, s0, 2.0
        lod i8t, s1, zoom_value
        mul s1, 2
        #mul s1, 2
        lod u8t, t1, PLAYER.flip_sprite # Add 1 to index if flipped
        add a4, s1, t1
        mul a4, PLAYER_SPRITE_WIDTH

        mov a5, PLAYER_SPRITE_WIDTH
        mov a6, PLAYER_SPRITE_WIDTH
        mov a7, 0
        #lod u8t, a7, PLAYER.flip_sprite
        syscall SYS_DRAW_TEXTURE_REGION
        jmp @endif+

    @endif:

    @if_show_vectors:
        mov cr, DRAW_PLAYER_VELOCITY
        jfs @endif+
        lod f32t, t0, PLAYER.x
        lod f32t, t1, PLAYER.y
        ffma a0, t0, CENTER_X_F, t0
        ffma a1, t1, CENTER_Y_F, t1
        fdiv a0, s0
        fdiv a1, s0
        lod f32t, t2, global_velx
        lod f32t, t3, global_vely
        fdiv t2, s0
        fdiv t3, s0
        ffma a2, t2, VELOCITY_VISUAL_SCALE, a0
        ffma a3, t3, VELOCITY_VISUAL_SCALE, a1
        mov a4, VELOCITY_VECTOR_START_LUMA
        mov a5, VELOCITY_VECTOR_END_LUMA
        cal draw_gradient_line
    @endif:

    @skipdraw:
    vpop s0..s1
    ret

#-------------------------------------------------------------------------------
sbmk "Draw Bodies"
draw_bodies:
    # s0: body index
    vpsh s0..s6

    mov s0, zr
    mov s6, zr
    @loop:
        cmp lt, s0, MAX_BODIES
        jfs @endloop+
        lod u8t, t0, system_bodies_count
        cmp gte, s6, t0
        jtr @endloop+

        cea system_bodies, s0, BODY.SIZE
        lde u8t, cr, BODY.ACTIVE
        jfs @skip+
        inc s6

        lde f32t, t0, BODY.X
        lde f32t, t1, BODY.Y
        lod f32t, t2, distance_scale
        lde f32t, a2, BODY.R
        ffma a0, CENTER_X_F, t2, t0
        ffma a1, CENTER_Y_F, t2, t1
        fdiv a0, t2
        fdiv a1, t2
        fdiv a2, t2

        cmp flt, a2, 0.1 # Don't draw miniscule objects
        jtr @skipdraw+
        #fdiv t4, 2.0

        @is_body_offscreen:
            fadd t0, a0, a2
            cmp flt, t0, 0.0
            jtr @skipdraw+
            fadd t0, a1, a2
            cmp flt, t0, 0.0
            jtr @skipdraw+
            fsub t0, a0, a2
            cmp flt, t0, fcast SCREEN_WIDTH
            jfs @skipdraw+
            fsub t0, a1, a2
            cmp flt, t0, fcast SCREEN_HEIGHT
            jfs @skipdraw+

        lod i8t, t6, zoom_value
        pow t6, 2, t6
        lde u16t, t5, BODY.LUM
        div t4, t5, t6 # Divide luminosity by the square of the zoom scale
        div t7, t5, 6 # Limit reduction to an 8th of the base luminosity
        max t4, t7
        clp a3, t4, 1, 255 # Clamp luma

        @if_tiny:
            cmp flt, a2, 1.0
            jfs @endif+
            fcti t0, a0
            fcti t1, a1
            cmp gte, t0, 0
            jfs @skipdraw+
            cmp gte, t1, 0
            jfs @skipdraw+
            cmp lt, t0, SCREEN_WIDTH
            jfs @skipdraw+
            cmp lt, t1, SCREEN_HEIGHT
            jfs @skipdraw+
            sbpx t0, t1, 255
            jmp @skipdraw+
        @endif:

        lod i8t, t0, selected_body_index
        cmp eq, s0, t0
        mov t2, cr
        lod u8t, cr, current_menu_selection
        cmp neq, cr, 6
        and cr, t2
        mvc a3, 255 # Selected body has full luma
        vpsh a0..a4
        mov a4, 2
        cal DrawPAcircle
        vpop a0..a4

        @if_show_rotation: # Draw lines on system_bodies to visualize rotation
            mov cr, DRAW_ROTATIONAL_VELOCITY
            jfs @endif+
            mov s1, a0
            mov s2, a1
            mov s3, a2
            cmp flt, a2, 4.0 # Minimum radius before rotation lines are no longer drawn
            jtr @endif+
            cea system_bodies, s0, BODY.SIZE
            lde f32t, s4, BODY.ROT
            fadd s5, s4, 2*PI
            cmp lt, a3, 255/2
            sel a4, 200, 1
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
            cea system_bodies, s0, BODY.SIZE
            lde f32t, t0, BODY.X
            lde f32t, t1, BODY.Y
            lod f32t, t2, distance_scale
            ffma a0, CENTER_X_F, t2, t0
            ffma a1, CENTER_Y_F, t2, t1
            lde f32t, t3, BODY.VX
            lde f32t, t4, BODY.VY
            fdiv t3, t2
            fdiv t4, t2
            #lod f32t, t4, global_velx
            #lod f32t, t5, global_vely
            #fadd t2, t4
            #fadd t3, t5
            ffma a2, t3, VELOCITY_VISUAL_SCALE, a0
            ffma a3, t4, VELOCITY_VISUAL_SCALE, a1
            mov a4, VELOCITY_VECTOR_START_LUMA
            mov a5, VELOCITY_VECTOR_END_LUMA
            cal draw_gradient_line
        @endif:

        @skip:

        inc s0
        jmp @loop-
    @endloop:
    vpop s0..s6
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

    lod u8t, t2, _current_screen
    mod t3, t2, SCREENS_TEXTURE_WIDTH/SCREEN_WIDTH
    div t4, t2, SCREENS_TEXTURE_WIDTH/SCREEN_WIDTH

    mul t3, SCREEN_WIDTH # Left
    mul t4, SCREEN_HEIGHT # Top

    add t5, t3, SCREEN_WIDTH # Right
    add t6, t4, SCREEN_HEIGHT # Bottom

    mov a0, SCREENS_TEXTURES
    vmov a1..a2, 0
    add a3, t3, t0
    add a4, t4, t1
    sub a5, t5, t0
    sub a6, t6, t1
    mov a7, 0
    syscall SYS_DRAW_TEXTURE_REGION
    sub a1, SCREEN_WIDTH, t0
    mov a3, t3
    add a5, t5, t0
    syscall SYS_DRAW_TEXTURE_REGION
    sub a2, SCREEN_HEIGHT, t1
    mov a4, t4
    add a6, t6, t1
    syscall SYS_DRAW_TEXTURE_REGION
    mov a1, 0
    add a3, t3, t0
    sub a5, t5, t0
    syscall SYS_DRAW_TEXTURE_REGION
    ret


#-------------------------------------------------------------------------------
sbmk "Draw Smoke"
draw_smoke:

    psh s0 # distance scale

    lod f32t, s0, distance_scale

    mov t15, zr
    @loop:
        cmp lt, t15, SMOKE.MAX_SMOKE_COUNT
        jfs @endloop+
        cea smoke, t15, SMOKE.SIZE
        lde f32t, t0, SMOKE.X
        lde f32t, t1, SMOKE.Y
        lde f32t, t2, SMOKE.LIFESPAN
        @if_smoke_alive:
            cmp fgt, t2, 0.0
            jfs @endif+
            ffma t0, s0, CENTER_X_F, t0
            ffma t1, s0, CENTER_Y_F, t1
            fdiv t0, s0
            fdiv t1, s0
            frou t0
            frou t1
            fcti t0
            fcti t1
            @if_in_bounds:
                cmp gt, t0, 0
                jfs @endif2+
                cmp gt, t1, 0
                jfs @endif2+
                cmp lt, t0, SCREEN_WIDTH
                jfs @endif2+
                cmp lt, t1, SCREEN_HEIGHT
                jfs @endif2+
                lod i8t, t3, zoom_value
                pow t3, 2, t3
                div t3, 255, t3 # Use a dimmer color when zoomed out
                clp t3, 1, 255
                sbpx t0, t1, t3
            @endif2:
        @endif:
    inc t15
    jmp @loop-
    @endloop:
    pop s0
    ret

#-------------------------------------------------------------------------------
sbmk "Draw HUD"
draw_hud:
    # Flags: -- Set to 0/false to not display
    #   s0: 1: Jump, 2: Add Body, 3: Edit Body, 4: Next
    #   s1: 1: Walk, 2: Cancel, 3: Match, 4: Player, 5: Global, 6: Remove Body, 7: Back
    #   s2: Zoom
    #   s3: 1: Freecam, 2: Editor
    #   s4: Cursor
    #   s5: 1: Body ID, 2: Position, 3: Velocity, 4: Rotation, 5: Radius, 6: Mass,
    #       7: Luminosity

    vpsh s0..s5

    def HUD_PADDING 2
    def LEFT_EDGE HUD_PADDING
    def RIGHT_EDGE SCREEN_WIDTH - HUD_PADDING
    def TOP_EDGE HUD_PADDING
    def BOTTOM_EDGE SCREEN_HEIGHT - HUD_PADDING
    def CHARGE_BAR_X RIGHT_EDGE - 16
    def CHARGE_BAR_Y BOTTOM_EDGE - (8*CHARGE_BAR_LENGTH)
    def ZOOM_BAR_LENGTH 13

    # Set draw flags
    vmov s0..s5, false
    mov s0, true
    mov s2, true
    @if_paused:
        lod u8t, cr, game_paused
        jfs @else+
        mov s0, false
        mov s1, false
        jmp @endif+
    @else:
    @if_editor_enabled:
        lod u8t, cr, editor_enabled
        jfs @else+
        @if_editing:
            lod u8t, t0, current_menu_selection
            cmp neq, t0, 0
            jfs @else2+
            mov s0, 4
            mov s3, 2
            mov s1, 7
            mov s4, true
            add t0, 1
            mov s5, t0
            jmp @endif+
        @else2:
            mov s0, false
            mov s3, 2
            mov s4, true
            lod i8t, t0, selected_body_index
            cmp gte, t0, 0
            mvc s1, 6
            mvc s5, 1
            sel s0, 3, 2
            jmp @endif+

    @else:
    @if_freecam_enabled:
        lod u8t, cr, freecam_enabled
        jfs @else+
        mov s3, 1
        mov s0, 0
        mov s1, 5
        lod u8t, cr, freecam_relative_velocity_enabled
        mvc s1, 4
        jmp @endif+
    @else: # Player is grounded
    @if_grounded:
        lod u8t, s1, PLAYER.is_grounded
        mov cr, s1
        jfs @else+
        mov s1, 1
        lod u8t, cr, PLAYER.is_charging
        mvc s1, 2
        jmp @endif+
    @else: # Player is flying
        mov s1, 3
    @endif:

    # X Y Buttons
    @if_flag_enabled:
        mov cr, s2
        jfs @endif+
        mov a0, HUD_SPRITESHEET
        mov a1, LEFT_EDGE
        mov a2, TOP_EDGE
        mov a3, 16
        mov a4, 0
        mov a5, 16
        mov a6, 32
        mov a7, 0
        syscall SYS_DRAW_TEXTURE_REGION

        mov a0, STRINGS.ZOOM_IN
        mov a1, LEFT_EDGE + 12
        cal draw_string
        mov a0, STRINGS.ZOOM_OUT
        mov a2, TOP_EDGE + 16
        cal draw_string
    @endif:

    # B Button
    @if_flag_enabled:
        mov cr, s1
        jfs @endif+

        mov a0, HUD_SPRITESHEET
        mov a1, LEFT_EDGE
        mov a2, BOTTOM_EDGE - 16
        mov a3, 0
        mov a4, 16
        mov a5, 16
        mov a6, 16
        syscall SYS_DRAW_TEXTURE_REGION

        # Text
        mov a0, STRINGS.WALK
        cmp eq, s1, 2
        mvc a0, STRINGS.CANCEL
        cmp eq, s1, 3
        mvc a0, STRINGS.MATCH
        cmp eq, s1, 4
        mvc a0, STRINGS.PLAYER
        cmp eq, s1, 5
        mvc a0, STRINGS.GLOBAL
        cmp eq, s1, 6
        mvc a0, STRINGS.REMOVE_BODY
        cmp eq, s1, 7
        mvc a0, STRINGS.BACK
        mov a1, LEFT_EDGE + 12
        mov a2, BOTTOM_EDGE - 16
        mov a4, 96
        cal draw_string
    @endif:

    # Freecam
    @if_flag_enabled:
        mov cr, s3
        jfs @endif+
        cmp eq, s3, 1
        sel a0, STRINGS.FREECAM, STRINGS.EDITOR
        sel a1, RIGHT_EDGE - 112, RIGHT_EDGE - 96
        mov a2, TOP_EDGE
        cal draw_string

    @endif:

    # A button
    @if_flag_enabled:
        mov cr, s0
        jfs @endif+
        @jump:
            cmp eq, s0, 1
            jfs @editor+
            mov a0, HUD_SPRITESHEET
            mov a1, RIGHT_EDGE - 112
            mov a2, BOTTOM_EDGE - 16
            vmov a3..a4, 0
            vmov a5..a6, 16
            syscall SYS_DRAW_TEXTURE_REGION

            mov a0, STRINGS.JUMP
            mov a1, RIGHT_EDGE - 100
            mov a2, BOTTOM_EDGE - 16
            cal draw_string

            # Jump charge bar

            # Calculate charge bar fill amount
            lod f32t, t0, PLAYER.jump_charge
            fsub t0, PLAYER.MIN_JUMP_CHARGE
            fsub t1, PLAYER.MAX_JUMP_CHARGE, PLAYER.MIN_JUMP_CHARGE
            fdiv t0, t1
            fctf t2, 8*CHARGE_BAR_LENGTH
            fsub t2, 12.0
            fmul t0, t2
            frou t0
            fcti t0

            # Draw charge bar background
            mov a0, CHARGE_BAR_X  + 4
            mov a1, CHARGE_BAR_Y + 6
            mov a2, 8
            mov a3, 8*CHARGE_BAR_LENGTH-12
            mov a4, 1
            syscall SYS_DRAW_RECT

            @if_charging:
                cmp gt, t0, 0
                jfs @endif2+
                #sub t0, 6
                sub a1, CHARGE_BAR_Y + 8*(CHARGE_BAR_LENGTH-1) + 2, t0
                mov a3, t0
                mov a4, 255
                syscall SYS_DRAW_RECT
            @endif2:

            # Charge Bar top
            mov a0, HUD_SPRITESHEET
            mov a1, CHARGE_BAR_X
            mov a2, CHARGE_BAR_Y
            mov a3, 88
            mov a4, 0
            mov a5, 16
            mov a6, 8
            syscall SYS_DRAW_TEXTURE_REGION

            # Charge Bar Middle
            mov a4, 8
            mov t0, zr
            @loop:
                mul t1, t0, 8
                add a2, CHARGE_BAR_Y + 8, t1
                syscall SYS_DRAW_TEXTURE_REGION
                inc t0
                cmp lt, t0, CHARGE_BAR_LENGTH-2
                jtr @loop-

            # Charge Bar Bottom
            mov a2, CHARGE_BAR_Y + 8*(CHARGE_BAR_LENGTH-1)
            mov a4, 24
            mov a5, 16
            mov a6, 8
            syscall SYS_DRAW_TEXTURE_REGION
            jmp @endif+

        @editor:
            mov a0, HUD_SPRITESHEET
            mov a1, RIGHT_EDGE - 128
            mov a2, TOP_EDGE + 16
            mov a3, 32
            mov a4, 16
            vmov a5..a6, 16
            mov a7, 0
            syscall SYS_DRAW_TEXTURE_REGION

            lod u8t, cr, freecam_relative_velocity_enabled
            sel a0, STRINGS.PLAYER, STRINGS.GLOBAL
            mov a1, RIGHT_EDGE - 112
            mov a2, TOP_EDGE + 16
            cal draw_string

            mov a0, HUD_SPRITESHEET
            mov a1, RIGHT_EDGE - 96
            mov a2, BOTTOM_EDGE - 16
            vmov a3..a4, 0
            vmov a5..a6, 16
            syscall SYS_DRAW_TEXTURE_REGION

            cmp eq, s0, 2
            sel a0, STRINGS.ADD_BODY, STRINGS.EDIT_BODY
            cmp eq, s0, 4
            mvc a0, STRINGS.NEXT
            mov a1, RIGHT_EDGE - 80
            mov a2, BOTTOM_EDGE - 16
            cal draw_string
    @endif:

    @cursor:
        mov cr, s4
        jfs @end+

        mov a0, HUD_SPRITESHEET
        mov a1, SCREEN_WIDTH/2 - 8
        mov a2, SCREEN_HEIGHT/2 - 8
        mov a3, 48
        mov a4, 16
        vmov a5..a6, 16
        mov a7, 0
        syscall SYS_DRAW_TEXTURE_REGION
    @end:

    @editor_active:
        cmp neq, s5, 0 # if body is selected
        jfs @end+

        @if_editing:
            cmp gte, s5, 2
            jfs @else+

            mov a0, STRINGS.POS
            cmp eq, s5, 3
            mvc a0, STRINGS.VEL
            cmp eq, s5, 4
            mvc a0, STRINGS.ROT
            cmp eq, s5, 5
            mvc a0, STRINGS.R
            cmp eq, s5, 6
            mvc a0, STRINGS.M
            cmp eq, s5, 7
            mvc a0, STRINGS.LUM

            mov a1, LEFT_EDGE
            mov a2, TOP_EDGE + 56
            cal draw_string

            mov a1, LEFT_EDGE
            mov a2, TOP_EDGE + 72
            mov a0, STRINGS.X
            cmp gt, s5, 3
            mvc a0, STRINGS.VAL
            cal draw_string



            lod f32t, t0, visible_editor_value_x_f
            lod u16t, t3, visible_editor_value_x

            mov a0, buffer
            @if_float:
                cmp neq, s5, 7
                jfs @else2+
                mov a1, t0
                mov a2, 2
                cal float_to_ascii
                jmp @endif2+
            @else2:
                mov a1, t3
                cal int_to_ascii
            @endif2:
            mov a0, buffer
            mov a1, LEFT_EDGE + 32
            mov a2, TOP_EDGE + 72
            cmp gt, s5, 3
            mvc a1, LEFT_EDGE + 64
            cal draw_string

            mov a1, LEFT_EDGE
            mov a2, TOP_EDGE + 88
            mov a0, STRINGS.Y
            cmp gt, s5, 3
            mvc a0, STRINGS.SCALE
            cal draw_string

            lod f32t, t1, visible_editor_value_y_f
            lod i8t, t2, visible_editor_value_scale
            fctf t2
            fpow t2, 10.0, t2

            mov a0, buffer
            cmp gt, s5, 3
            sel a1, t2, t1
            mov a2, 2
            cal float_to_ascii

            mov a0, buffer
            mov a1, LEFT_EDGE + 32
            mov a2, TOP_EDGE + 88
            cmp gt, s5, 3
            mvc a1, LEFT_EDGE + 96
            cal draw_string

            lod f32t, t0, visible_editor_value_x_f
            lod f32t, t1, visible_editor_value_y_f

            @if_position:
                cmp eq, s5, 2
                jfs @else2+
                lod f32t, t8, distance_scale
                mov a0, fcast SCREEN_WIDTH/2
                mov a1, fcast SCREEN_HEIGHT/2
                fdiv t0, t8
                fadd a2, t0, a0
                lod f32t, a3, visible_editor_value_y_f
                fdiv t1, t8
                fadd a3, t1, a1
                mov a4, 255
                cal draw_line
                jmp @endif2+
            @else2:
            @if_velocity:
                cmp eq, s5, 3
                jfs @endif2+
                lod u8t, t3, selected_body_index
                lod f32t, t8, distance_scale
                cea system_bodies, t3, BODY.SIZE
                lde f32t, t4, BODY.X
                lde f32t, t5, BODY.Y
                fdiv t4, t8
                fdiv t5, t8
                fadd a0, t4, fcast SCREEN_WIDTH/2
                fadd a1, t5, fcast SCREEN_HEIGHT/2
                fdiv t0, t8
                fdiv t1, t8
                fadd a2, a0, t0
                fadd a3, a1, t1
                mov a4, 255
                cal draw_line
            @endif2:

            jmp @endif+
        @else:
            mov a0, STRINGS.BODY_ID
            cal load_string
            add a0, buffer
            lod i8t, a1, selected_body_index
            cal int_to_ascii
            mov a0, buffer
            mov a1, LEFT_EDGE
            mov a2, TOP_EDGE + 56
            cal draw_string
        @endif:
    @end:

    # Zoom bar

    mov a0, HUD_SPRITESHEET
    mov a1, LEFT_EDGE
    mov a2, TOP_EDGE + 32
    mov a3, 104
    mov a4, 0
    mov a5, 8
    mov a6, 16
    syscall SYS_DRAW_TEXTURE_REGION

    mov t0, 1
    mov a3, 112
    @loop:
        mul t1, t0, 8
        add a1, LEFT_EDGE, t1
        syscall SYS_DRAW_TEXTURE_REGION
        inc t0
        cmp gt, t0, ZOOM_BAR_LENGTH-2
        jfs @loop-
    @endloop:

    mov a1, LEFT_EDGE + 8*(ZOOM_BAR_LENGTH-1)
    mov a3, 104
    mov a7, 0b10
    syscall SYS_DRAW_TEXTURE_REGION

    lod f32t, t0, distance_scale
    fdiv t0, MAX_ZOOM
    fctf t1, 8*(ZOOM_BAR_LENGTH-2)+2
    fmul t1, t0
    frou t1
    fcti t1

    add a1, t1, LEFT_EDGE
    add a1, 2
    mov a3, 120
    mov a7, 0
    syscall SYS_DRAW_TEXTURE_REGION

     #@if_paused:
        #lod u8t, cr, game_paused
        #jfs @endif+
        #mov a0, STRINGS.PAUSE
        #mov a1, SCREEN_WIDTH/2 - 88
        #mov a2, SCREEN_HEIGHT/2 - 32
        #cal draw_string

        ## B button
        #mov a0, HUD_SPRITESHEET
        #mov a1, SCREEN_WIDTH/2 - 120
        #add a2, 24
        #mov a3, 0
        #mov a4, 16
        #vmov a5..a6, 16
        #mov a7, 0
        #syscall SYS_DRAW_TEXTURE_REGION

        ## Editor toggle text
        #mov a0, STRINGS.TOGGLE_EDITOR
        #add a1, 16
        #cal draw_string

    #@endif:

    vpop s0..s5
    ret

#-------------------------------------------------------------------------------
sbmk "Draw String"
draw_string:
    # > a0*: String address
    # > a1..a2: Draw position
    # < a0: String size

    vpsh s0..s2
    vmov s0..s2, a0..
    vpsh a0..a7
    mov a0, FONT_SPRITESHEET
    vmov a5..a6, 16
    mov a7, 0
    @loop:
        lod u8t, t0, s0
        cmp eq, t0, 0
        jtr @endloop+
        cmp eq, t0, NEWLINE
        mvc a1, SCREEN_WIDTH
        jtr @skipdraw+
        cmp gt, t0, 96 # if lowercase, convert to uppercase
        sel t1, 64, 32
        sub t0, t1
        mod a3, t0, 13
        div a4, t0, 13
        mul a3, 16
        mul a4, 16
        syscall SYS_DRAW_TEXTURE_REGION
        add a1, 16
        @skipdraw:
        inc s0
        cmp lt, a1, SCREEN_WIDTH
        jtr @loop-
        mov a1, s1
        add a2, 16
        jmp @loop-
    @endloop:
    vpop a0..a7
    mov a0, s0
    vpop s0..s2
    ret

#-------------------------------------------------------------------------------
sbmk "Draw Menu"
draw_menu:
    vpsh s0..s2
    lod u8t, s0, current_active_menu_index
    lod u8t, s2, current_menu_selection

    cmp eq, s0, 0
    jtr @skipdraw+

    cea menus, s0, MENU.SIZE
    lde u16t, a1, MENU.X
    lde u16t, a2, MENU.Y
    lde u32t, a0, MENU.NAME
    lde u32t, s1, MENU.OPTION_NAMES

    cal draw_string

    add a1, 16
    add a2, 24
    mov a0, s1
    cal draw_string

    mov a0, HUD_SPRITESHEET
    sub a1, 16
    fma a2, s2, 16, a2
    mov a3, 48
    mov a4, 0
    vmov a5..a6, 16
    mov a7, 0
    syscall SYS_DRAW_TEXTURE_REGION

    @if_pause_menu:
        cmp eq, s0, MENUS.PAUSE_MENU
        jfs @endif+
        lod u8t, a1, system_id
        mov a0, buffer
        cal int_to_ascii

        mov a0, buffer
        mov a1, SCREEN_WIDTH/2 + 112
        mov a2, SCREEN_HEIGHT/2 - 8
        cal draw_string

    @endif:


    #lod u16t, a1, t0 # Menu pos X
    #add s0, 2

    #lod u16t, a2, s0 # Menu pos y
    #add s0, 2

    #mov a0, s0
    #cal draw_string
    #add s0, a0

    #lod u8t, s1, s0 # Option count
    #add s0, 1

    #str u32t, current_menu_options, s0

    #fma t0, s1, 4, s2
    #lod u8t, a0, t0 # Option names address

    #add a1, 16
    #cal draw_string

    #lod u8t, t0, current_menu_selection

    #mov a0, HUD_SPRITESHEET

    #fma t0, 16, a2
    #add a2, t0, 16
    #mov a3, 48
    #mov a4, 0
    #vmov a5..a6, 16
    #mov a7, 0
    #syscall SYS_DRAW_TEXTURE_REGION

    @skipdraw:
    vpop s0..s2
    ret

#-------------------------------------------------------------------------------
bmk "Camera"

#-------------------------------------------------------------------------------
sbmk "Move Camera"
move_camera:
    # > a0..a1: Camera offset

    # Move Bodies
    mov t15, zr # Object counter
    mov t13, zr
    lod u8t, t14, system_bodies_count
    cmp eq, a0, 0.0
    mov t0, cr
    cmp eq, a1, 0.0
    and cr, t0
    jtr @end_move+
    @loop:
        cmp lt, t15, MAX_BODIES
        jfs @endloop+
        cmp gte, t13, t14
        jtr @endloop+

        cea system_bodies, t15, BODY.SIZE
        lde u8t, cr, BODY.ACTIVE
        jfs @skip+
        inc t13

        lde f32t, t0, BODY.X
        lde f32t, t1, BODY.Y
        fsub t0, a0
        fsub t1, a1
        ste f32t, BODY.X, t0
        ste f32t, BODY.Y, t1

        @skip:
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
    lod f32t, t4, distance_scale
    fmul t2, a0, BG_SCROLL_SCALE
    fmul t3, a1, BG_SCROLL_SCALE
    fdiv t2, t4
    fdiv t3, t4
    fadd t0, t2
    fadd t1, t3
    fmod t0, fcast SCREEN_WIDTH
    fmod t1, fcast SCREEN_HEIGHT
    str f32t, bg_offset_x, t0
    str f32t, bg_offset_y, t1

    @end_move:

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
    #fmul t2, CAMERA_SPEED, s0
    mov t2, CAMERA_SPEED

    mov t0, a0
    mov t1, a1

    # Get distance from parent body
    lod i8t, t3, PLAYER.parent_body_index
    cmp lt, t3, 0
    jtr @endif+
    cea system_bodies, t3, BODY.SIZE
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
        cmp flt, a2, t5
        jfs @endif+
        lod i8t, t6, control_camera_offset_scalar
        lod u8t, cr, PLAYER.is_grounded
        sel a2, t6, 0
        fctf a2
        #fdiv t3, CAMERA_OFFSET, s0
        fmul t3, -CAMERA_OFFSET, s0
        ffma a2, t3, CAMERA_OFFSET
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
    vpop s0..s1
    ret

#-------------------------------------------------------------------------------
sbmk "Set Distance Scale"
set_distance_scale:
    # Scales distance from center of camera
    # > a0: Distance Scale

    lod f32t, t13, distance_scale
    mov t15, zr # Object counter
    lod u8t, t14, system_bodies_count
    str f32t, distance_scale, a0
    @if_freecam_disabled:
        lod u8t, t0, editor_enabled
        lod u8t, cr, freecam_enabled
        orr cr, t0
        jtr @endif+

        mov a0, false
        cal center_camera
    @endif:
    ret

#-------------------------------------------------------------------------------
bmk "Editor"

#-------------------------------------------------------------------------------
sbmk "Handle Editor Input"
check_editor_input:
    # > a0: Input Bitmask
    # > a1: BTN_RIGHT - BTN_LEFT input
    # > a2: BTN_DOWN - BTN_UP input
    # > a3: BTN_A input
    # > a4: BTN_B input
    # > a5: BTN_X input
    # > a6: BTN_Y input
    # > a7: BTN_START input
    # > a8: BTN_SELECT input

    vpsh s0..s3

    lod i8t, s0, selected_body_index
    lod u8t, s1, current_menu_selection
    lod f32t, s2, distance_scale
    lod i8t, s3, visible_editor_value_scale

    @toggle_relative_velocity: # Toggles freecam between player relative velocity and global velocity
        mov cr, a8
        jfs @end+
        lod u8t, t0, freecam_relative_velocity_enabled
        cmp eq, t0, false
        str u8t, freecam_relative_velocity_enabled, cr
        str u8t, debounce_check, true
    @end:

    @close_editor:
        mov cr, a7
        jfs @end+
        str u8t, editor_enabled, false
        #str u8t, freecam_relative_velocity_enabled, cr
        str u8t, current_active_menu_index, 0
        str u8t, current_menu_selection, 0
        str i8t, selected_body_index, -1
        jmp @end_input+
    @end:

    @if_editing_planet:
        mov cr, s1
        jfs @else+


        sub t0, a3, a4
        add s1, t0
        str u8t, current_menu_selection, s1

        cea system_bodies, s0, BODY.SIZE

        cmp eq, s1, 1
        jtr @edit_pos+
        cmp eq, s1, 2
        jtr @edit_velocity+
        cmp eq, s1, 3
        jtr @edit_rotation+
        cmp eq, s1, 4
        jtr @edit_radius+
        cmp eq, s1, 5
        jtr @edit_mass+
        cmp eq, s1, 6
        jtr @edit_luminosity+
        str u8t, current_menu_selection, 0
        str f32t, visible_editor_value_x_f, 0.0
        str f32t, visible_editor_value_y_f, 0.0
        str u8t, visible_editor_value_x, 0
        str u8t, visible_editor_value_y, 0
        str i8t, visible_editor_value_scale, 0
        jmp @end_input+

        @edit_pos:
            fctf t1, a1
            fctf t2, a2
            fmul t1, s2
            fmul t2, s2
            lde f32t, t3, BODY.X
            lde f32t, t4, BODY.Y
            fadd t3, t1
            fadd t4, t2
            ste f32t, BODY.X, t3
            ste f32t, BODY.Y, t4
            str f32t, visible_editor_value_x_f, t3
            str f32t, visible_editor_value_y_f, t4
            jmp @end+
        @edit_velocity:
            fctf t1, a1
            fctf t2, a2
            fmul t1, s2
            fmul t2, s2
            lde f32t, t3, BODY.VX
            lde f32t, t4, BODY.VY
            fadd t3, t1
            fadd t4, t2
            ste f32t, BODY.VX, t3
            ste f32t, BODY.VY, t4
            lod u8t, cr, freecam_relative_velocity_enabled
            lod f32t, t5, global_velx
            lod f32t, t6, global_vely
            sel t5, 0.0, t5
            sel t6, 0.0, t6
            fadd t3, t5
            fadd t4, t6
            str f32t, visible_editor_value_x_f, t3
            str f32t, visible_editor_value_y_f, t4
            jmp @end+
        @edit_rotation:
            fctf t1, a1
            sub t2, s3, a2
            fctf t3, t2
            fpow t3, 10.0, t3
            fmul t1, t3
            lde f32t, t3, BODY.ROT_AV
            fadd t3, t1
            ste f32t, BODY.ROT_AV, t3
            str f32t, visible_editor_value_x_f, t3
            str i8t, visible_editor_value_scale, t2
            jmp @end+
        @edit_radius:
            fctf t1, a1
            sub t2, s3, a2
            fctf t3, t2
            fpow t3, 10.0, t3
            fmul t1, t3
            lde f32t, t3, BODY.R
            fadd t3, t1
            fmax t3, 0.1
            ste f32t, BODY.R, t3
            str f32t, visible_editor_value_x_f, t3
            str i8t, visible_editor_value_scale, t2
            jmp @end+
        @edit_mass:
            fctf t1, a1
            sub t2, s3, a2
            fctf t3, t2
            fpow t3, 10.0, t3
            fmul t1, t3
            lde f32t, t3, BODY.M
            fadd t3, t1
            fmax t3, 0.01
            ste f32t, BODY.M, t3
            str f32t, visible_editor_value_x_f, t3
            str i8t, visible_editor_value_scale, t2
            jmp @end+
        @edit_luminosity:
            mov t1, a1
            sub t2, s3, a2
            pow t3, 10, t2
            mul t1, t3
            lde u16t, t3, BODY.LUM
            neg t4, t3
            max t1, t4
            add t3, t1
            fmax t3, 1
            ste u16t, BODY.LUM, t3
            str u16t, visible_editor_value_x, t3
            str i8t, visible_editor_value_scale, t2

        @end:

        jmp @end_input+
    @else:
        str f32t, visible_editor_value_x_f, 0.0
        str f32t, visible_editor_value_y_f, 0.0
        str u8t, visible_editor_value_x, 0
        str u8t, visible_editor_value_y, 0
        str i8t, visible_editor_value_scale, 0
        @edit_planet:
            cmp gte, s0, 0
            jfs @end+
            mov cr, a3
            jfs @end+
            str u8t, current_menu_selection, 1
            vpsh a0..a1
            cea system_bodies, s0, BODY.SIZE
            lde f32t, a0, BODY.X
            lde f32t, a1, BODY.Y
            cal move_camera
            vpop a0..a1
            jmp @end_input+
        @end:
        @add_body:
            mov cr, a3
            jfs @end+
            vpsh a0..a8
            vmov a0..a1, 0.0
            lod u8t, cr, freecam_relative_velocity_enabled
            lod f32t, a2, global_velx
            lod f32t, a3, global_vely
            fneg a2
            fneg a3
            sel a2, 0.0, a2
            sel a3, 0.0, a3
            mov a4, 0.0
            mov a5, 5.0
            lod f32t, t0, distance_scale
            fmul a5, t0
            mov a6, 1.0
            mov a7, 255/2
            cal add_body
            str i8t, selected_body_index, a0
            mov s0, a0
            vpop a0..a8
            jmp @edit_planet-
        @end:

        @remove_body:
            mov cr, a4
            jfs @end+
            @if_body_selected:
                lod i8t, t0, selected_body_index
                cmp gte, t0, 0
                jfs @endif+
                mov t1, a0
                mov a0, t0
                cal remove_body
                mov a0, t1
            @endif:
        @end:

    @end_input:
    vpop s0..s3
    ret

#-------------------------------------------------------------------------------
sbmk "Update Selected Body"
update_selected_body:
    psh s0 # Distance scale


    lod u8t, t0, current_menu_selection
    cmp eq, t0, 0
    jfs @end+
    lod f32t, s0, distance_scale
    str i8t, selected_body_index, -1

    mov t15, zr
    mov t14, zr
    @loop:
        cmp lt, t15, MAX_BODIES
        jfs @endloop+
        lod u8t, t0, system_bodies_count
        cmp gte, t14, t0
        jtr @endloop+

        cea system_bodies, t15, BODY.SIZE
        lde u8t, cr, BODY.ACTIVE
        jfs @skip+
        inc t14

        lde f32t, t0, BODY.X
        lde f32t, t1, BODY.Y
        lde f32t, t2, BODY.R

        fpow t0, 2.0
        fpow t1, 2.0
        fadd t0, t1
        fsqrt t0

        @if_cursor_colliding:
            cmp lt, t0, t2
            jfs @endif+
            str i8t, selected_body_index, t15
            jmp @endloop+
        @endif:
    @skip:
        inc t15
        jmp @loop-
    @endloop:

    @end:
    pop s0
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
                jtr @endloop+ # STRINGS terminated
                cmp eq, t2, 32 # Count spaces as terminators
                jtr @endloop+
                inc t0
                inc t1
                jmp @loop-
    @endloop:
    ret

#-------------------------------------------------------------------------------
sbmk "Get Digit Int"
get_digit_int:
    # > a0: Target number
    # > a1: Which digit to extract. (digit = (a0 - a0*10**(a1+1))/10**a1)
    # < a0: The targeted digit

    pow t1, 10, a1
    add t2, a1, 1
    pow t2, 10, t2

    rem a0, t2 # Isolate previous digit
    div a0, t1 # Isolate digit
    ret

#-------------------------------------------------------------------------------
sbmk "Get Digit Float"
get_digit_float:
    # > a0: Target number
    # > a1: Which digit to extract. (digit = (a0 - a0*10**(a1+1))/10**a1)
    # < a0: The targeted digit


    fctf t3, a1

    fpow t1, 10.0, t3
    fadd t2, t3, 1.0
    fpow t2, 10.0, t2

    fmod a0, t2 # Isolate previous digit
    fdiv a0, t1 # Isolate digit
    fcti a0
    ret

#-------------------------------------------------------------------------------
sbmk "Int to ASCII"
int_to_ascii:
    # > a0*: Destination address
    # > a1: Number
    vpsh s0..s1

    vmov s0..s1, a0..
    # Get order of magnitude
    mov t0, 1
    @loop:
        cmp gte, t0, 8
        jtr @endloop+
        pow t1, 10, t0
        div t2, s1, t1
        cmp eq, t2, 0
        jtr @endloop+
        inc t0
        jmp @loop-
    @endloop:

    # Convert to ascii
    @loop:
        dec t0
        cmp lt, t0, 0
        jtr @endloop+
        mov a0, s1
        mov a1, t0
        cal get_digit_int
        add a0, 48
        str u8t, s0, a0
        inc s0
        jmp @loop-
    @endloop:

    str u8t, s0, 0 # Add terminator
    vpop s0..s1
    ret

#-------------------------------------------------------------------------------
sbmk "Float to ASCII"
float_to_ascii:
    # > a0*: Destination address
    # > a1: Number
    # > a2: Decimals - How many decimal places to display

    vpsh s0..s2

    vmov s0..s2, a0..

    cmp flt, s1, 0.0
    sel t0, 45, 43
    str u8t, s0, t0
    inc s0
    fabs s1

    # Get order of magnitude
    mov t0, 1
    @loop:
        cmp gte, t0, 8
        jtr @endloop+
        pow t1, 10, t0
        fctf t1
        fdiv t2, s1, t1
        cmp flt, t2, 1.0
        jtr @endloop+
        inc t0
        jmp @loop-
    @endloop:



    pow t1, 10, s2
    fctf t1
    fmul s1, t1
    add t0, s2
    dec s2

    fcti s1

    # Convert to ascii
    @loop:
        dec t0
        cmp lt, t0, 0
        jtr @endloop+
        @has_decimal_been_added:
            cmp eq, t0, s2
            jfs @endif+
            str u8t, s0, 46
            inc s0
        @endif:
        mov a0, s1
        mov a1, t0
        cal get_digit_int
        add a0, 48
        str u8t, s0, a0
        inc s0
        jmp @loop-
    @endloop:

    str u8t, s0, 0 # Add terminator
    vpop s0..s2
    ret

#-------------------------------------------------------------------------------
sbmk "Draw Circle"
draw_circle:
    # > (f32t) a0..a1: x,y center
    # > (f32t) a2: radius
    # > (u8t) a3: luma

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
    @if_distance_zero:
        cmp eq, a2, 0
        jfs @endif+
        mov a0, 1.0
        mov a1, 0.0
        mov a2, 0
        jmp @end+
    @endif:
    fdiv a0, a2 # dx/r
    fdiv a1, a2 # dy/r

    @end:
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

# Modified to use a0..a1 as x,y directly, a3 for the fill color, and a4 for the level of precision

DrawPAcircle:
    vpsh s0..s10

    @is_circle_offscreen:
        fadd t0, a0, a2
        cmp flt, t0, 0.0
        jtr @end+
        fadd t0, a1, a2
        cmp flt, t0, 0.0
        jtr @end+
        fsub t0, a0, a2
        cmp fgt, t0, fcast SCREEN_WIDTH
        jtr @end+
        fsub t0, a1, a2
        cmp fgt, t0, fcast SCREEN_HEIGHT
        jtr @end+

    mov s0, a0 # centre x
    mov s1, a1 # centre y
    mov s9, a3
    mov s2, a2
    mov s10, a4
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
        #mov a3, 1
        mov a3, s10
        mov a4, s9
        syscall SYS_DRAW_RECT # draw upper quarter
        fadd t0, s1, s6
        fcei t0
        fcti t0
        mov a1, t0
        syscall SYS_DRAW_RECT # draw lower quarter
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
        #mov a2, 1
        mov a2, s10
        mov a4, s9
        syscall SYS_DRAW_RECT # draw left quarter
        fsub t1, s0, s6
        fflo t1
        fcti t1
        mov a0, t1
        syscall SYS_DRAW_RECT # draw right quarter
        yield
        add s4, s10
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
    syscall SYS_DRAW_RECT
    @end:
    vpop s0..s10
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
