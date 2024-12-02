const toolbox = @import("toolbox");
const fiber = toolbox.fiber;
const std = @import("std");

pub const SCREEN_WIDTH = 256;
pub const SCREEN_HEIGHT = 232;
pub const FAST_LINE_1_NUM_SEGMENTS = 4;
pub const FAST_LINE_2_NUM_SEGMENTS = 8;

const LEVEL_DATA = @embedFile("levels.bin");
const EXPECTED_TEST_DATA = @embedFile("expected_values.bin");
//TODO this fails when set to true! See TODO.md
const VALIDATE_AGAINST_ARCADE = false;
const z = std.mem.zeroes;

//The game was designed around the fact that VBlank happend between
//scanlines 0-0x17 (inclusive), where nothing could be drawn to the screen.
//Thus, only values 0x18-0xFF were drawable Y coordinates.
//We need to take this into account here.
pub const Y_COORDINATE_OFFSET = 0x18;

pub const CHARACTER_BITMAP_HEIGHT = 5;
pub const CHARACTER_BITMAP_WIDTH = 5;

//@AL.55D:        ;  5x5 digits
pub const NUMBER_BITMAPS = [_]u8{
    0b11111000,
    0b11111000,
    0b10001000,
    0b11111000,
    0b11111000,

    0b10000000,
    0b10001000,
    0b11111000,
    0b10000000,
    0b10000000,

    0b10011000,
    0b11001000,
    0b11101000,
    0b10111000,
    0b10011000,

    0b10001000,
    0b10101000,
    0b10101000,
    0b11111000,
    0b11111000,

    0b00111000,
    0b00111000,
    0b00100000,
    0b11111000,
    0b00100000,

    0b10111000,
    0b10101000,
    0b10101000,
    0b11101000,
    0b11100000,

    0b11111000,
    0b10101000,
    0b10101000,
    0b11101000,
    0b11100000,

    0b00011000,
    0b00001000,
    0b00001000,
    0b11111000,
    0b11111000,

    0b11111000,
    0b10101000,
    0b10101000,
    0b11111000,
    0b11111000,

    0b00111000,
    0b00101000,
    0b00101000,
    0b11111000,
    0b11111000,
};

pub const LETTER_BITMAPS = [_]u8{
    0b11111000,
    0b11111000,
    0b00101000,
    0b00101000,
    0b11111000,

    0b11111000,
    0b10101000,
    0b10101000,
    0b11111000,
    0b11011000,

    0b11111000,
    0b11111000,
    0b10001000,
    0b10001000,
    0b10011000,

    0b11111000,
    0b11111000,
    0b10001000,
    0b10001000,
    0b01110000,

    0b11111000,
    0b11111000,
    0b10101000,
    0b10001000,
    0b10001000,

    0b11111000,
    0b11111000,
    0b00101000,
    0b00001000,
    0b00001000,

    0b11111000,
    0b11111000,
    0b10001000,
    0b10101000,
    0b11101000,

    0b11111000,
    0b11111000,
    0b00100000,
    0b00100000,
    0b11111000,

    0b10001000,
    0b10001000,
    0b11111000,
    0b10001000,
    0b10001000,

    0b11000000,
    0b10001000,
    0b11111000,
    0b11111000,
    0b00001000,

    0b11111000,
    0b00100000,
    0b01110000,
    0b11011000,
    0b10001000,

    0b11111000,
    0b11111000,
    0b10000000,
    0b10000000,
    0b10000000,

    0b11111000,
    0b00110000,
    0b01100000,
    0b00110000,
    0b11111000,

    0b11111000,
    0b00011000,
    0b00110000,
    0b01100000,
    0b11111000,

    0b11111000,
    0b11111000,
    0b10001000,
    0b10001000,
    0b11111000,

    0b11111000,
    0b11111000,
    0b00101000,
    0b00101000,
    0b00111000,

    0b11111000,
    0b10001000,
    0b10001000,
    0b11001000,
    0b11111000,

    0b11111000,
    0b11111000,
    0b00101000,
    0b11101000,
    0b00111000,

    0b10111000,
    0b10111000,
    0b10101000,
    0b11101000,
    0b11101000,

    0b00001000,
    0b00001000,
    0b11111000,
    0b00001000,
    0b00001000,

    0b11111000,
    0b11111000,
    0b10000000,
    0b10000000,
    0b11111000,

    0b00111000,
    0b01100000,
    0b11000000,
    0b01100000,
    0b00111000,

    0b11111000,
    0b01100000,
    0b00110000,
    0b01100000,
    0b11111000,

    0b10001000,
    0b01010000,
    0b00100000,
    0b01010000,
    0b10001000,

    0b00011000,
    0b00110000,
    0b11100000,
    0b00110000,
    0b00011000,

    0b10001000,
    0b11001000,
    0b11101000,
    0b10111000,
    0b10011000,

    //@64 space
    0b00000000,
    0b00000000,
    0b00000000,
    0b00000000,
    0b00000000,

    //@65 life symbol

    0b01101000,
    0b11010000,
    0b11110000,
    0b11010000,
    0b01101000,

    //@66, slash used in 1/2

    0b10000000,
    0b01000000,
    0b00100000,
    0b00010000,
    0b00001000,

    //@67, questionmark
    0b00001000,
    0b00001000,
    0b10101000,
    0b00111000,
    0b00010000,

    //@68  colon
    0b00000000,
    0b00000000,
    0b10010000,
    0b00000000,
    0b00000000,

    //@69
    0b00100000,
    0b00100000,
    0b10101000,
    0b01110000,
    0b00100000,
};
const WORDS = [_][]const u8{
    "INSERT[COIN",
    "COIN",
    "EEROM",
    "OVER",
    "GET",
    "READY",
    "PRESS[START",
    "START",
    "CREDITS",
    "GAME",
    "PLAYER",
    "8",
    "9",
    "8]9",
    "CRYSTAL",
    "CASTLES",
    "PASSED",
    "GET",
    "HIGH[SCORE",
    "GEMS",
    "BENTLEY",
    "BEAR",
    "AT[PC",
    "COPYRIGHT",
    "1983[ATARI",
    "ALL[RIGHTS",
    "RESERVED",
    ":",
    ";",
    "<",
    "=",
    "CLEAR",
    "CHECKSUM[FOR[ROM",
    "LEVEL",
    ";A",
    "EXTRA",
    "EVERY[>7777",
    ";B",
    "TREE",
    "WAVE",
    "TRACKBALL",
    "BERTHILDAS",
    "CASTLE",
    "HOR",
    "NASTY",
    "TUNNEL",
    "ELEVATOR",
    "FXL",
    "PYRAMID",
    "VERT",
    "OVER[TREES",
    "GREEN",
    "BLUE",
    "FORTRESS",
    "RED",
    "IMPOSSIBLE",
    "STAIRCASE",
    "STUN[THEM",
    "DOOMSDOME",
    "EATERS",
    "CROSS",
    "MAZE",
    "DUNGEON",
    "DIFFICULTY",
    "CROSSROADS",
    "MORE",
    "TUNNELS",
    "STARTING",
    "PALACE",
    "HIDDEN",
    "YOU",
    "GOT",
    "THE",
    "LAST",
    "GEM",
    "THEY",
    "NO",
    "BONUS",
    "RESET",
    "FREE[PLAY",
    "HALL",
    "OF",
    "FAME",
    "ENTER",
    "YOUR",
    "INITIALS",
    "BUTTON",
    "WARP",
    "EATING",
    "SPIRAL",
    "PRESS",
    "RESTORE[FACTORY",
    "HINTS",
    "MAGIC[HAT[MAKES[YOU[INVINCIBLE",
    "WEAR",
    "CAN[KILL[BERTHILDA",
    "CATCH",
    "WHEN[THEY[ARE",
    "STAY[AWAY",
    "MOVING[FROM",
    "TAKE[TOO[MUCH",
    "SWARM[RETURNS",
    "ACCOUNTING",
    "AUX",
    "LEFT",
    "RIGHT",
    "COINS",
    "TOTAL",
    "GAMES",
    "PLAYED",
    "PAID",
    "AVERAGE",
    "TIME",
    "HISTOGRAM",
    "ADVANCE",
    "SELECT",
    "WITH",
    "TEST",
    "GRID",
    "OPTIONS",
    "SWITCH",
    "TO",
    "EXIT",
    "RAM",
    "ROM",
    "OK",
    "FAILURE",
    "SELF",
    "JUMP",
    "VALUE",
    "MECH",
    "EEROM",
    "9[CREDITS",
    "8[CREDIT",
    "8]9[CREDIT",
    "8K_",
    "8L_",
    "8N_",
    "8H_",
    "8F_",
    "USE[SECRET",
    "NUMBER",
    "AT",
    "CORNER",
    "MEDIUM",
    "HARD",
    "HARDEST",
    "EASY",
    "I[GIVE[UP[_[YOU[WIN",
    "MUST[BE",
    "END",
    "LIVES",
    "BACK",
    "IT",
    "AND",
    "HAT",
    "BOTTOM",
    "ON",
    "RAMP",
    "VERY",
    "RIDICULOUSLY",
    "AMAZINGLY",
    "FANTASTICALLY",
    "AN[EXPERT",
    "GOOD",
    "YES",
    "A[VIDEO[WHIZ",
    "[",
    "[",
};

//@ ; creature distribution, depends on wave number
//@ ; creature table
//@ DF.CRT:
const CREATURE_TABLE = [_]isize{
    9, 9, 9, 9, 9, 1, 1, 1, //@ ; 00
    1, 1, 0xA, 1, 1, 1, 1, 1, //@ ; 10
    7, 0, 0, 0, 0, 0, 0, 0, //@ ; 20
    7, 6, 0xA, 1, 1, 1, 1, 1, //@ ; 30
    7, 0, 0xA, 1, 1, 1, 1, 1, //@ ; 01
    7, 9, 0xA, 1, 1, 1, 0xE, 0xB, //@ ; 11
    7, 0, 0xA, 1, 1, 1, 1, 0, //@ ; 21
    7, 6, 0xA, 9, 9, 1, 1, 0, //@ ; 31
    7, 0, 0xA, 1, 1, 1, 0, 9, //@ ; 02
    1, 0xC, 0xA, 1, 1, 1, 0, 9, //@ ; 12
    7, 1, 0xA, 1, 1, 1, 1, 0, //@ ; 22
    7, 6, 0xA, 1, 1, 1, 0xA, 9, //@ ; 32
    7, 1, 0xA, 1, 1, 1, 1, 0, //@ ; 03
    7, 1, 0xA, 1, 1, 1, 1, 0, //@ ; 13
    7, 1, 0xC, 0, 9, 9, 9, 0xB, //@ ; 23
    7, 6, 0xA, 0xE, 0xE, 1, 1, 0, //@ ; 33
};
//@ ;  creature numbers
//@ DF.CRN:
const CREATURE_NUMBERS = [_]isize{
    3, 8, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 6, 6, 6, 6,
};
//@ ;   initial speeds for gem-eaters
//@ DF.SP1:
const GEM_EATER_INTIAL_SPEEDS = [_]isize{
    2,   2,   3, 4, 5, 7, 8, 9,
    0xA, 0x1,
};

//@ ;  max speed for gem-eaters
//@ DF.MSG:
const GEM_EATER_MAX_SPEEDS = [_]isize{
    3,   5,   7, 9, 0xA, 0xB, 0xC, 0xD,
    0xA, 0x2,
};

//@ ;  crystal monster speed
//@ DF.CMS:
const CRYSTAL_MONSTER_SPEEDS = [_]isize{
    1,   4,   5, 6, 7, 8, 9, 0xA,
    0xA, 0x8,
};

//@ ;   eating times
//@ DF.ETD:
const EATING_TIMES = [_]isize{
    0x40, 0x20, 0x10, 0x10, 0x10, 0x10, 8, 8,
    8,    0x10,
};

//@ ;   swarm speed
//@ DF.SWS:
const SWARM_SPEEDS = [_]isize{
    0x1, 0x3, 0x6, 0x3, 0x5,
    0x6, 0x4, 0x8, 0x8, 0xC,
};

const CREATURE_INITIAL_POSITIONS = [_]V2{
    .{ 0x2, 0xC },   .{ 0x3, 0x14 },  .{ 0x4, 0x14 },
    .{ 0x5, 0x14 },  .{ 0x6, 0x14 },  .{ 0x7, 0x14 },
    .{ 0x8, 0x14 },  .{ 0x9, 0x14 },  .{ 0xA, 0x14 },
    .{ 0xF, 0x13 },  .{ 0x10, 0x10 }, .{ 0x14, 0x3 },
    .{ 0x14, 0x4 },  .{ 0x8, 0x14 },  .{ 0x9, 0x14 },
    .{ 0xA, 0x14 },  .{ 0xB, 0x14 },  .{ 0xC, 0x14 },
    .{ 0x1, 0x2 },   .{ 0x1, 0x1 },   .{ 0x1, 0x4 },
    .{ 0x1, 0x8 },   .{ 0x1, 0xC },   .{ 0x1, 0x10 },
    .{ 0x1, 0xA },   .{ 0x1, 0x6 },   .{ 0x14, 0x14 },
    .{ 0xC, 0x2 },   .{ 0xD, 0x2 },   .{ 0x2, 0x14 },
    .{ 0x7, 0x14 },  .{ 0x14, 0x14 }, .{ 0x13, 0x14 },
    .{ 0x12, 0x14 }, .{ 0x11, 0x14 }, .{ 0x10, 0x14 },
    .{ 0x1, 0x1 },   .{ 0x1, 0x1 },   .{ 0x1, 0x14 },
    .{ 0x2, 0x14 },  .{ 0x3, 0x14 },  .{ 0x4, 0x14 },
    .{ 0x5, 0x14 },  .{ 0x6, 0x14 },  .{ 0x7, 0x14 },
    .{ 0xC, 0x1 },   .{ 0xC, 0x1 },   .{ 0x14, 0x2 },
    .{ 0xD, 0x2 },   .{ 0x8, 0xC },   .{ 0x1, 0x14 },
    .{ 0x2, 0x14 },  .{ 0x2, 0x2 },   .{ 0xC, 0x6 },
    .{ 0xB, 0xB },   .{ 0xB, 0xB },   .{ 0xE, 0x14 },
    .{ 0xF, 0x14 },  .{ 0x10, 0x14 }, .{ 0x11, 0x14 },
    .{ 0x12, 0x14 }, .{ 0x13, 0x14 }, .{ 0x14, 0x14 },
    .{ 0xA, 0xC },   .{ 0xA, 0xC },   .{ 0x1, 0x10 },
    .{ 0x12, 0x14 }, .{ 0x11, 0x14 }, .{ 0x10, 0x14 },
    .{ 0xF, 0x14 },  .{ 0xE, 0x14 },  .{ 0xD, 0x14 },
    .{ 0x2, 0x9 },   .{ 0x2, 0x9 },   .{ 0x2, 0x14 },
    .{ 0x3, 0x14 },  .{ 0x4, 0x14 },  .{ 0x5, 0x14 },
    .{ 0x6, 0x14 },  .{ 0x7, 0x14 },  .{ 0x1, 0x14 },
    .{ 0xD, 0xD },   .{ 0x8, 0x14 },  .{ 0xD, 0xE },
    .{ 0x1, 0x14 },  .{ 0x4, 0x14 },  .{ 0x5, 0x14 },
    .{ 0x6, 0x14 },  .{ 0x7, 0x14 },  .{ 0x1, 0x14 },
    .{ 0x2, 0x2 },   .{ 0x2, 0x2 },   .{ 0x2, 0x14 },
    .{ 0x1, 0x1 },   .{ 0x4, 0x14 },  .{ 0x5, 0x14 },
    .{ 0x6, 0x14 },  .{ 0x7, 0x14 },  .{ 0x8, 0x14 },
    .{ 0x2, 0xC },   .{ 0x2, 0xD },   .{ 0x3, 0x2 },
    .{ 0x2, 0x2 },   .{ 0x5, 0x14 },  .{ 0x4, 0x14 },
    .{ 0x3, 0x14 },  .{ 0x2, 0x14 },  .{ 0x1, 0x14 },
    .{ 0x8, 0x14 },  .{ 0x8, 0x14 },  .{ 0x2, 0x14 },
    .{ 0x3, 0x14 },  .{ 0x4, 0x14 },  .{ 0x5, 0x14 },
    .{ 0x6, 0x14 },  .{ 0x7, 0x14 },  .{ 0x1, 0x14 },
    .{ 0x13, 0x6 },  .{ 0x13, 0x6 },  .{ 0x2, 0x14 },
    .{ 0x3, 0x14 },  .{ 0x4, 0x14 },  .{ 0x5, 0x14 },
    .{ 0x6, 0x14 },  .{ 0x7, 0x14 },  .{ 0x1, 0x14 },
    .{ 0x1, 0x2 },   .{ 0x2, 0x2 },   .{ 0x14, 0x2 },
    .{ 0x6, 0x6 },   .{ 0x4, 0x2 },   .{ 0x5, 0x14 },
    .{ 0x6, 0x14 },  .{ 0x14, 0x14 }, .{ 0xB, 0xB },
    .{ 0x8, 0x1 },   .{ 0x8, 0x1 },   .{ 0x2, 0x2 },
    .{ 0x14, 0x14 }, .{ 0x4, 0x4 },   .{ 0x5, 0x5 },
    .{ 0x6, 0x6 },   .{ 0x7, 0x7 },   .{ 0x1, 0x9 },
};
//@;   tree growing times
//@ DF.TRG:
const TREE_GROWING_TIMES = [_]isize{
    0x40, 0x20, 0x20, 0x10, 0x8, 0x8, 0x8, 0x8,
    0x10, 0x20,
};

//A "wave" is a sub-division of a "level".
//There are 4 waves per level except level 10 which only has 1 wave
//You can kind of think of a "wave" as Super Mario Bros level and
//a "level" as a  Super Mario Bros world.
const WAVE_DATA_SIZE = 0x400;

const MAX_NUMBER_OF_ENTITIES = 10; //EN.MAX
const MOTION_OBJECTS_PER_ENTITY = 4;
const PLAYER_ENTITY = 0;
const SWARM_ENTITY = 1;

const PLAYFIELD_WIDTH = 22;
const PLAYFIELD_HEIGHT = 22;

pub const Dimension = isize;
pub const V2 = @Vector(2, Dimension);
pub const ZV2 = V2{ 0, 0 };
pub const Color = enum(u8) {
    White,
    Red,
    Gray,
    DarkGray,
    Black,
};
const DrawCommand = struct {
    shape: Shape,
    number_of_segments: isize = 0, //@used for lines and screen erase
    character: u8 = 0, //only used for characters
    position: V2,
    color: Color,

    const Shape = enum {
        None,
        Line1,
        Line2,
        Line3,
        Character,
        ScreenErase,
        Pixel,
        ClearEntireScreen,
    };
};

//AKA Sprite
pub const MotionObject = struct {
    picture_number: isize = 0,
    position: V2 = ZV2,
    flags: usize = 0,
};

pub const GameState = struct {
    //input from platform layer:
    dt: toolbox.Duration,

    //output to platform layer:
    motion_objects: [MAX_NUMBER_OF_ENTITIES * MOTION_OBJECTS_PER_ENTITY]MotionObject =
        [_]MotionObject{.{}} ** (MAX_NUMBER_OF_ENTITIES * MOTION_OBJECTS_PER_ENTITY),
    draw_command_queue: toolbox.RingQueue(DrawCommand),
    number_of_draw_commands_this_frame: usize = 0,

    //Internal game state
    global_arena: *toolbox.Arena,
    rng_state: toolbox.RandomState,

    current_state: enum {
        Initial, //GM.IN -- GM.STA is set to 0
        StartGame, //GM.ST -- GM.STA is set to 1
        StartOfWave, //GM.SW -- GM.STA is set to 2
        GamePlay, //GM.GP -- GM.STA is set to 3
        DeathSequence, //GM.DT -- GM.STA is set to 4
        EndOfWave, //GM.EW -- GM.STA is set to 5
        EndOfGame, //GM.EG -- GM.STA is set to 6

        InitWaveMotionObjects, //GM.WO -- GM.STA is set to 0xA
        HallOfFame, //GM.HF -- GM.STA is set to 0xD
        ExplainationBoard, //GM.BE is set to 0xE
        AttractModeMainLoop, //GM.AT -- GM.STA is set to 0xF
    } = .Initial,

    is_in_attract_mode: bool = false, //ATRACT
    attract_mode_player_position_index: usize = 0, //WV.ATP

    //wave specific state
    wave_offset: isize = 0, //WV.OFF
    wave_xco: isize = 0, //TODO: figure out what "xco means"
    wave_xcd: isize = 0, //TODO: figure out what "xcd means"
    wave_yco: isize = 0, //TODO: figure out what "yco means"
    wave_ycd: isize = 0, //TODO: figure out what "yco means"
    wave_end_of_game: bool = false, //WV.EOG
    wave_current: isize = 0, //WV.NUM
    wave_difficulty_offset: isize = 0, //WV.DF0
    wave_short_term_difficulty: isize = 0, //WV.DF1
    wave_long_term_difficulty: isize = 0, //WV.DF2
    wave_time: isize = 0, //WV.TIM
    wave_enable_warp: bool = false, //WV.WAR

    wave_scroll_flag: enum { NoScroll, Right, Left, Up } = .NoScroll, //WV.SCF

    game_time: toolbox.Duration = .{}, //ST.TIM
    next_extra_life: isize = 0, //SC.NEL
    prevent_color_transfer: bool = false, //WV.CIN

    //draw background state
    background_animation_time_since_last_scanline: toolbox.Duration = .{},
    background_clip_y: isize = 0,

    //castle state
    castle_adl: usize = 0, //TODO: figure out what "adl means"
    castle_a2l: usize = 0, //TODO: figure out what "a2l means"
    castle_acl: usize = 0, //TODO: figure out what "acl means"
    castle_arl: usize = 0, //TODO: figure out what "arl means"
    castle_afl: usize = 0, //TODO: figure out what "afl means"
    castle_all: usize = 0, //TODO: figure out what "all means"
    castle_adb: usize = 0, //TODO: figure out what "adb means"

    castle_region_1: isize = 0, //CT.HR1
    castle_region_2: isize = 0, //CT.HR2
    castle_region_3: isize = 0, //CT.HR3

    castle_row_position: V2 = .{ 0, 0 }, //CR.HST and CR.VST

    castle_row_count: isize = 0, //CT.CNT

    castle_block_position: V2 = .{ 0, 0 }, //BL.HST and BL.VST
    castle_block_count: isize = 0, //CR.CNT
    castle_block_height: isize = 0, //BL.HEI
    castle_block_v1n: isize = 0, //BL.V1N TODO: figure what this means
    castle_block_v1s: isize = 0, //BL.V1S TODO: figure what this means
    castle_block_v2n: isize = 0, //BL.V2N TODO: figure what this means
    castle_block_v2s: isize = 0, //BL.V2S TODO: figure what this means
    castle_block_is_upper_right_edge_hidden: bool = false, //BL.URE
    castle_block_is_upper_left_edge_hidden: bool = false, //BL.ULE
    castle_block_is_upper_corner_hidden: bool = false, //BL.UCR
    castle_block_is_right_edge_hidden: bool = true, //BL.HRE
    castle_block_is_left_edge_hidden: bool = true, //BL.HLE
    castle_block_hidden_edge_start: isize = 0, //BL_HES
    castle_block_hidden_right_edge_length: isize = 0, //BL_HEL
    castle_block_hidden_left_edge_length: isize = 0, //BL_HLL

    face_position: V2 = .{ 0, 0 }, //FC.HST and FC.VST
    face_v1n: isize = 0, //FC.V1N
    face_v1s: isize = 0, //FC.V1S
    face_v2n: isize = 0, //FC.V2N
    face_v2s: isize = 0, //FC.V2S
    face_hidden_edge_color_value: u8 = 0, //FC.COH
    face_color_values: [7]u8 = undefined, //FC.BV
    face3_color_value_hidden_or_not: u8 = 0, //CT.BV3

    entity_end_of_wave_mode: bool = false, //EN.EWM
    entity_is_warping: bool = false, //EN.WRF    ;  warp flag
    entity_in_tunnel: EntityField(bool) = z(EntityField(bool)), //EN.TFL
    entity_is_dead: EntityField(bool) = z(EntityField(bool)), //EN.DEA
    entity_blanking_flag: EntityField(bool) = z(EntityField(bool)), //EN.BLK

    //TODO: figure out the different life mode states
    entity_life_mode: EntityField(LifeMode) = z(EntityField(LifeMode)), //EN.LMD
    //EN.XO1-EN.XO4, EN.YO1-EN.YO4
    entity_motion_object_offsets: EntityField([MOTION_OBJECTS_PER_ENTITY]V2) =
        z(EntityField([MOTION_OBJECTS_PER_ENTITY]V2)),
    entity_state: EntityField(EntityState) = z(EntityField(EntityState)), //EN.STA
    entity_playfield_position: EntityField(V2) = z(EntityField(V2)), //EN.MX and EN.MY
    entity_position: EntityField(V2) = z(EntityField(V2)), //EN.X and EN.Y
    entity_fine_position: EntityField(V2) = z(EntityField(V2)), //EN.IX and EN.IY
    entity_picture_position: EntityField(V2) = z(EntityField(V2)), //EN.HP and EN.VP
    //EN.PR1-EN.PR4
    entity_priority: EntityField([MOTION_OBJECTS_PER_ENTITY]isize) =
        z(EntityField([MOTION_OBJECTS_PER_ENTITY]isize)),
    //EN.PC1-EN.PC4
    entity_picture: EntityField([MOTION_OBJECTS_PER_ENTITY]isize) =
        z(EntityField([MOTION_OBJECTS_PER_ENTITY]isize)),
    entity_height: EntityField(isize) = z(EntityField(isize)), //EN.HEI
    entity_animation_direction: EntityField(isize) = z(EntityField(isize)), //EN.AND
    entity_playfield_square_height_index: EntityField(usize) = z(EntityField(usize)), //EN.MAT
    entity_playfield_square_flags_index: EntityField(usize) = z(EntityField(usize)), //EN.MA2
    entity_animation: EntityField(isize) = z(EntityField(isize)), //EN.ANV
    //@ ;  direction 0<=EN.DR<=3
    entity_direction: EntityField(isize) = z(EntityField(isize)), //EN.DR
    //TODO: don't know what HOF means.  maybe "horizontal_offset?"
    entity_hof: EntityField(isize) = z(EntityField(isize)), //EN.HOF
    entity_delay: EntityField(isize) = z(EntityField(isize)), //EN.DEL
    entity_slow_speed: EntityField(isize) = z(EntityField(isize)), //EN.SP1
    entity_fast_speed: EntityField(isize) = z(EntityField(isize)), //EN.SP2
    entity_wall_collision: EntityField(bool) = z(EntityField(bool)), //EN.WCF
    entity_new_square_flag: EntityField(bool) = z(EntityField(bool)), //EN.NSF

    entity_collision_delay: isize = 0, //EN.CDL
    entity_jump_delay: isize = 0, //EN.JDL
    entity_jump_flag: bool = false, //EN.JFL
    entity_movement_delta: V2 = ZV2, //EN.XD and EN.YD
    jump_button_pressed: bool = false, //EN.JBP

    gem_eater_max_speed: isize = 0, //EN.MSG
    crystal_monster_speed: isize = 0, //EN.CMS

    general_start_delay: isize = 0, //EN.GDL

    general_purpose_1: EntityField(isize) = z(EntityField(isize)), //EN.GP1
    general_purpose_2: EntityField(isize) = z(EntityField(isize)), //EN.GP2

    wave_gems_left: isize = 0, //CE.COC
    entity_that_took_last_gem: usize = 0, //EN.LDF

    tune_table_keys: [4]isize =
        .{ 0, 0, 0, 0 }, //RS.KEY

    //SC.GEM    ;  gem counter
    gems_collected: isize = 0,

    main_loop_delay: isize = 0, //MN.DEL

    has_tunnel: bool = false, //CT.TUN

    lives: isize = 0, //P1.LIV or WV.LIV
    score: isize = 0, //P1.SCO or SC.SCO

    frame: isize = 1, //FRAME
    number_of_credits: isize = 0, //$$CRDT or $CNCT
    current_wave_data: [WAVE_DATA_SIZE]u8 = undefined, //CTRAM,

    last_trackball_position: V2 = ZV2, //TR.I and TR.J

    show_easter_egg_count: isize = 0,

    scoreboard: Scoreboard = .{},

    debug_should_not_yield: bool = true,

    expected_test_data: []const ExpectedTestData = z([]const ExpectedTestData),

    fn EntityField(comptime T: type) type {
        return [MAX_NUMBER_OF_ENTITIES]T;
    }
};
const EntityState = enum(isize) {
    PlayerOrTree = 0,
    PlungerMovingTowardsWall = 1,
    PlungerFollowsWall = 2,
    PlungerEating = 3,
    NotUsed = 4,
    PlungerStunned = 5,
    Witch = 6,
    Honey = 7,
    Swarm = 8,
    CrystalBall = 9,
    Hat = 10,
    Cauldron = 11,
    Skeleton = 12,
    ScoreDisplay = 13,
    Ghost = 14,
};
const LifeMode = enum(isize) {
    Alive = 0,
    Dying = 1,
    Spawning = 2,
    Dead = 3,
};
//@        HFSIZ=250.
const HALL_OF_FAME_SIZE = 250;
const Scoreboard = struct {
    //@SC.HS1:    .BLKB HFSIZ    ;  high scores
    //@SC.HS2: .BLKB HFSIZ
    //@SC.HS3:    .BLKB HFSIZ
    //@SC.HI1:    .BLKB HFSIZ    ;  and initials
    //@SC.HI2: .BLKB HFSIZ
    //@SC.HI3: .BLKB HFSIZ
    entries: [HALL_OF_FAME_SIZE]Entry = ([_]Entry{.{}} ** HALL_OF_FAME_SIZE),

    const Entry = struct {
        name: toolbox.String8 = toolbox.str8lit("DAN"),
        score: isize = 0,
    };
};
const ExpectedTestData = extern struct {
    wave_time: u16,
    entity_positions: [0x20]u8,
    entity_fine_positions: [0x20]u8,
};

pub fn init(game_state: *GameState, global_arena: *toolbox.Arena) void {
    const draw_line_command_queue =
        toolbox.RingQueue(DrawCommand).init(10_000, global_arena);
    game_state.global_arena = global_arena;
    game_state.draw_command_queue = draw_line_command_queue;

    reset(game_state);
}

fn reset(game_state: *GameState) void {
    const draw_line_command_queue = game_state.draw_command_queue;
    const rand = toolbox.init_random(@bitCast(toolbox.now().microseconds()));
    const expected_test_data =
        @as([*]const ExpectedTestData, @ptrCast(@alignCast(EXPECTED_TEST_DATA)))[0 .. EXPECTED_TEST_DATA.len / @sizeOf(ExpectedTestData)];
    game_state.* = .{
        .dt = .{},
        .global_arena = game_state.global_arena,
        .draw_command_queue = draw_line_command_queue,
        .rng_state = rand,
        .expected_test_data = expected_test_data,
    };
    game_state.draw_command_queue.clear();

    initialize_sounds();
    initialize_high_scores();
    initialize_wave_data(game_state);
}
pub fn update(game_state: *GameState) void {
    while (true) {
        switch (game_state.current_state) {
            .Initial => init_attract_mode(game_state),
            .AttractModeMainLoop => update_attract_mode_state(game_state),
            .InitWaveMotionObjects => update_wave_motion_objects_state(game_state),
            .StartGame => update_start_game_state(game_state),
            .StartOfWave => update_start_of_wave_state(game_state),
            .GamePlay => update_game_play_state(game_state),
            .DeathSequence => update_death_sequence_state(game_state),
            .EndOfGame => update_end_of_game_state(game_state),
            .HallOfFame => update_hall_of_fame_state(game_state),
            .ExplainationBoard => update_explaination_board_state(game_state),

            .EndOfWave => unreachable,
        }
    }
}
fn draw_background(game_state: *GameState) void {
    //NOTE: this differentiates from the original code since instead of drawing squares,
    //      we just draw the background with a swipe effect
    game_state.background_clip_y = 0;
    while (true) {
        const BACKGROUND_ANIMATION_MS_PER_SCANLINE = 720 / SCREEN_HEIGHT;
        if (game_state.background_clip_y >= SCREEN_HEIGHT) {
            initialize_city(game_state);
            next_frame(game_state);
            break;
        }
        game_state.background_animation_time_since_last_scanline.ticks += game_state.dt.ticks;
        if (game_state.background_animation_time_since_last_scanline.milliseconds() >=
            BACKGROUND_ANIMATION_MS_PER_SCANLINE)
        {
            game_state.background_clip_y +=
                @divTrunc(
                game_state.background_animation_time_since_last_scanline.milliseconds(),
                BACKGROUND_ANIMATION_MS_PER_SCANLINE,
            );
            game_state.background_animation_time_since_last_scanline = .{};
        }
        next_frame(game_state);
    }
}
//@ ;---  state 15 attract mode
//@ GM.AT0:
fn init_attract_mode(game_state: *GameState) void {
    //@ TRAI 0F GM.STA
    game_state.current_state = .AttractModeMainLoop;

    //NOTE: don't think we need these
    //@     TRAI 20 TFLASH
    //@     JSR EECHKT        ; check up on EEROM
    //@ ;  draw wave 1 playfield
    //@     TRAI 0 ST.PLY        ; no game play
    //@     STA PL.UP        ; use hs inits, not p2

    //@     JSR WV.INI        ; init colors, wave number
    initialize_wave_data(game_state);
    //@     JSR WV.BDR        ; draw background
    draw_background(game_state);
    //@     JSR GR.MCL        ; clear mot obj
    clear_motion_objects(game_state);
    //@     JSR CT.INI        ; init city+elevators
    initialize_city(game_state);
    //@     JSR CT.DRW        ; draw city
    draw_city(game_state);

    //@JSR AL.BER
    erase_board(game_state);
    //@LDA #10
    //@JSR MS.DRW        ;  credits
    draw_message(0x10, game_state);

    //@LDA WV.WAR
    //@IFNE
    if (game_state.wave_enable_warp) {
        //TODO:
        unreachable;
        //@ LDA #1A
        //@ JSR MS.DRW        ;  warp message
        //@ TRAI 0C3 AL.X
        //@ TRAI 3B AL.Y
        //@ TRAM SC.HS1+HFSIZ-1 SC.NM
        //@ TRAM SC.HS2+HFSIZ-1 SC.NM+1
        //@ TRAM SC.HS3+HFSIZ-1 SC.NM+2
        //@ JSR SC.NDS        ;  display high score
        //@ LDA #10            ; wait 40 seconds before
    }
    //@ELSE            ; deactivating warp
    else {
        //@ LDA #1
        //NOTE it is actually 0x200, because the first decrement
        //@    doesn't affect the high byte
        game_state.main_loop_delay = 0x200;
        //@ENDIF
    }
    //@STA 1+MN.DEL

}
//EN.UPD
fn update_entities(game_state: *GameState) void {
    //@     ;---------------------------------------------
    //@ ; update EN
    //@ EN.UPD:
    //@ ;  background sound
    {
        //TODO: sound

        //@     LDA FRAME
        //@     AND #7F
        //@     IFEQ
        //@      LDA SN.GFL
        //@      IFEQ
        //@       LDA 1+WV.TIM
        //@       CMP #0C
        //@       IFCC
        //@       STA RS.KEY+1
        //@       LDA #15
        //@       JSR MN.SN1
        //@       ENDIF
        //@      ENDIF
        //@      TRAI 0 SN.GFL
        //@     ENDIF
    }

    //@ ;  trackball update
    {
        //TODO: player input

        //@     JSR TR.DEL

        //@ ; calculate CE deltas given TR deltas

        //@    ; truncate TR deltas, store in CE deltas
        //@     TRAI 9 TEMP1
        //@     LDA TR.XD
        //@     JSR GP.TRC
        //@     STA CE.XD
        //@     LDA TR.YD
        //@     JSR GP.TRC
        //@     NEGA        ;  invert delta Y
        //@     STA CE.YD

        //@    ;  rotate
        //@     LDA CE.XD    ; calculate new CE.YD
        //@     ASL
        //@     ADD CE.YD
        //@     STA CE.TMP    ; store in temp

        //@     LDA CE.YD    ; calculate new CE.XD
        //@     ASL
        //@     SUB CE.XD
        //@     STA CE.XD    ; and store
        //@     TRAM CE.TMP CE.YD    ; also store CE.YD

        //@ ;  truncate again
        //@     TRAI 0F TEMP1
        //@     LDA CE.XD
        //@     JSR GP.TRC
        //@     STA CE.XD
        //@     LDA CE.YD
        //@     JSR GP.TRC
        //@     STA CE.YD

        //@ ;    jumping
        //@     LDA EN.JFL
        //@     IFNE
        //@      LDA EN.JDL
        //@      CMP #1F
        //@      IFEQ
        //@       LDA EN.IX
        //@       ASLS 3
        //@       STA EN.JPX
        //@       LDA EN.IY
        //@       ASLS 3
        //@       STA EN.JPY
        //@      ENDIF
        //@      LDA EN.JDL
        //@      CMP #1E
        //@      IFEQ
        //@       LDA EN.IX
        //@       ASLS 3
        //@       SUB EN.JPX
        //@       DIV8
        //@       STA EN.JPX

        //@       LDA EN.IY
        //@       ASLS 3
        //@       SUB EN.JPY
        //@       DIV8
        //@       STA EN.JPY
        //@      ENDIF
        //@      LDA EN.JDL
        //@      CMP #1E
        //@      IFCC
        //@       TRAM EN.JPX CE.XD
        //@       TRAM EN.JPY CE.YD
        //@      ENDIF
        //@     ENDIF
    }

    //@ ;     end of wave calculation
    //@     JSR EN.EWC
    end_of_wave_calculation(game_state);

    //@     LDA GM.STA
    //@     CMP #5
    //@     IFEQ
    if (game_state.current_state == .EndOfWave) {
        //@      RTS
        return;
        //@     ENDIF
    }

    //@     JSR EN.PLU    ; player update
    update_player(game_state);

    //@     LDA EN.GDL
    //@     IFNE
    if (game_state.general_start_delay != 0) {
        //@      DEC EN.GDL
        game_state.general_start_delay -= 1;
        //@     ENDIF
    }

    //@     LDA EN.CDL    ;  collision delay
    //@     IFNE
    if (game_state.entity_collision_delay != 0) {
        //@      DEC EN.CDL
        game_state.entity_collision_delay -= 1;
        //@     ENDIF
    }

    //@     LDX #0
    //@     BEGIN
    for (0..MAX_NUMBER_OF_ENTITIES) |entity| {
        //@      TXA
        //@      IFNE
        if (entity != PLAYER_ENTITY) {
            //@       LDA EN.LMD    ;  if player alive
            //@       IFEQ
            if (game_state.entity_life_mode[PLAYER_ENTITY] == .Alive) {
                //@        JSR EN.COL    ; collision detect
                detect_collision(entity, game_state);
                //@       ENDIF
            }
            //@      ENDIF
        }

        //@      JSR EN.UP2    ; update EN
        //@ ;----------------------
        //@ ;  update EN
        //@ EN.UP2:
        {
            //@     TR16AM EN.MAT(X) EZ.MAT
            var height_index = game_state.entity_playfield_square_height_index[entity];
            const height = game_state.current_wave_data[height_index];
            //@     TR16AM EN.MA2(X) EZ.MA2
            //TODO: figure out what these flags are
            var flags_index = game_state.entity_playfield_square_flags_index[entity];
            const flags = game_state.current_wave_data[flags_index];

            //@ ;  if not in tunnel, update height
            //@     LDY #0
            //@     LDA @EZ.MA2(Y)
            //@     AND #20
            //@     IFEQ
            if (flags & 0x20 == 0) {
                //@      TRAM @EZ.MAT(Y) EN.HEI(X)
                game_state.entity_height[entity] = height;
            }
            //@     ENDIF

            //@     JSR EN.MOV
            move_entity(
                entity,
                game_state,
                &height_index,
                &flags_index,
            );

            //@     TR16AM EZ.MAT EN.MAT(X)
            game_state.entity_playfield_square_height_index[entity] = height_index;
            //@     TR16AM EZ.MA2 EN.MA2(X)
            game_state.entity_playfield_square_flags_index[entity] = flags_index;

            //@     RTS
        }
        //@      JSR EN.OUT
        output_entity(entity, game_state);

        //@     INXS 2
        //@     CPX EN.NUM
        //@     PLEND
    }

    //@     RTS

}
//EN.MOV
fn move_entity(
    entity: usize,
    game_state: *GameState,
    out_square_height_index: *usize,
    out_square_flags_index: *usize,
) void {
    const ATTRACT_MODE_PLAYER_DELTAS = [0x10]V2{
        //@ AT.XD:    .BYTE 0FD,0,0FB,4,5,0,2,3
        //@     .BYTE 0,0FF,0FD,0,2,3,4,5
        //@ AT.YD:    .BYTE 0FD,0,0,0,0,0,0,2
        //@     .BYTE 3,4,0,2,5,0F9,2,0
        .{ -3, -3 }, .{ 0, 0 },  .{ -5, 0 }, .{ 4, 0 }, .{ 5, 0 }, .{ 0, 0 },  .{ 2, 0 }, .{ 3, 2 },
        .{ 0, 3 },   .{ -1, 4 }, .{ -3, 0 }, .{ 0, 2 }, .{ 2, 5 }, .{ 3, -7 }, .{ 4, 2 }, .{ 5, 0 },
    };
    //@     ;---------
    //@ ;  move EN
    //@ EN.MOV:
    //@     TXA
    //@     IFEQ
    //@ ;  detect gems only if player not jumping
    //@     LDA EN.JFL
    //@     BNE 10$
    //@     ENDIF
    if (entity != PLAYER_ENTITY or !game_state.entity_jump_flag) {
        //@     JSR EN.CDT
        detect_gem(entity, game_state);
        //@ 10$:
    }

    //@     JSR EN.STC    ;  state calculation
    entity_state_calculation(entity, game_state);
    //@     JSR EN.LMC    ;  life mode calculation
    entity_life_mode_calculation(entity, game_state);

    //@     LDA EN.LMD
    //@     IFEQ        ;  if player alive
    if (game_state.entity_life_mode[PLAYER_ENTITY] == .Alive) {
        //@      TXA
        //@      IFEQ
        if (entity == PLAYER_ENTITY) {
            //@       LDA ATRACT
            //@       IFNE
            if (!game_state.is_in_attract_mode) {
                //*****TODO******
                unreachable;
                //@        TRAM CE.XD EN.XD    ; trackball inputs
                //@        TRAM CE.YD EN.YD
            }
            //@       ELSE
            else {
                //@        LDA WV.TIM
                //@        AND #3F        ;  once per second
                //@        IFEQ
                if (game_state.wave_time & 0x3F == 0) {
                    //@         INC WV.ATP    ;  increment atract mode pointer
                    game_state.attract_mode_player_position_index += 1;
                    //@        ENDIF
                }
                //@        LDA WV.ATP
                //@        CMP #0F
                //@        IFCS
                if (game_state.attract_mode_player_position_index >= ATTRACT_MODE_PLAYER_DELTAS.len - 1) {
                    //@         TRAI 0F WV.ATP
                    game_state.attract_mode_player_position_index = ATTRACT_MODE_PLAYER_DELTAS.len - 1;
                    //@        ENDIF
                }
                //@        TAY
                //@        TRAM AT.XD(Y) EN.XD
                //@        TRAM AT.YD(Y) EN.YD
                game_state.entity_movement_delta =
                    ATTRACT_MODE_PLAYER_DELTAS[game_state.attract_mode_player_position_index];
                //@       ENDIF
            }
            //@      ENDIF
        }
        //@     ELSE        ;  if player dead, everything stops
    } else {
        //@      TRAI 0 EN.XD
        //@      TRAI 0 EN.YD
        //@     ENDIF
        game_state.entity_movement_delta = ZV2;
    }

    //@     LDA EN.GDL
    //@     IFNE
    if (game_state.general_start_delay != 0) {
        //@       TXA
        //@       IFNE
        if (entity != PLAYER_ENTITY) {
            //@       TRAI 0 EN.XD        ;  creature freeze
            //@       STA EN.YD
            game_state.entity_movement_delta = ZV2;
        }
        //@       ENDIF
        //@     ENDIF
    }

    //@ 50$:
    //@     CPX #0
    //@     IFEQ
    if (entity == PLAYER_ENTITY) {
        //@      JSR EN.PUP    ;  player animation
        animate_player(game_state);
        //@     ENDIF
    }

    //@ ;  collision with playfield
    //@     TRAI 0 EN.WCF(X)    ; no wall collision
    game_state.entity_wall_collision[entity] = false;
    //@     STA    EN.NSF(X)    ; no new square
    game_state.entity_new_square_flag[entity] = false;

    //@     LDA EN.IX(X)
    //@     ADD EN.XD
    //@     STA EN.IX(X)
    //@     LDY EN.XD
    //@     IFPL
    //@      JSR EN.CXI
    //@     ELSE
    //@      JSR EN.CXD
    //@     ENDIF

    //@     LDA EN.IY(X)
    //@     ADD EN.YD
    //@     STA EN.IY(X)
    //@     LDY EN.YD
    //@     IFPL
    //@      JSR EN.CYI
    //@     ELSE
    //@      JSR EN.CYD
    //@     ENDIF

    game_state.entity_fine_position[entity] += game_state.entity_movement_delta;

    if (game_state.entity_movement_delta[0] >= 0) {
        if (game_state.entity_fine_position[entity][0] >= 0x14) {
            const square_height_index = out_square_height_index.* + PLAYFIELD_HEIGHT;
            const result = check_wall_collision(
                square_height_index,
                entity,
                game_state,
            );
            if (result.did_collide) {
                game_state.entity_fine_position[entity][0] = 0x13;
                game_state.entity_wall_collision[entity] = true;
            } else {
                //@ ;--------------------------
                //@ ; increment in  X-direction
                //@ EN.XIN:
                //@     LDA EN.IX(X)
                //@     SUB #20
                //@     BMI 40$
                if (game_state.entity_fine_position[entity][0] - 0x20 >= 0) {

                    //@     STA EN.IX(X)
                    game_state.entity_fine_position[entity][0] -= 0x20;

                    //@     LDA EN.HP(X)
                    //@     SUB #04
                    //@     STA EN.HP(X)

                    //@     LDA EN.VP(X)
                    //@     SUB #04
                    //@     STA EN.VP(X)
                    game_state.entity_picture_position[entity] += .{ -4, -4 };

                    //@     INC EN.MX(X)
                    game_state.entity_playfield_position[entity][0] += 1;

                    //@     JSR EN.MUP        ;  new square
                    move_entity_to_new_square(
                        entity,
                        game_state,
                        result.in_tunnel,
                        square_height_index,
                        out_square_height_index,
                        out_square_flags_index,
                    );
                    //@     TRAI 0 EN.AND(X)    ;  animation direction
                    game_state.entity_animation_direction[entity] = 0;
                    //@ 40$:
                    //@     RTS
                }
            }
        }
    } else {
        if (game_state.entity_fine_position[entity][0] < 0xC) {
            const square_height_index = out_square_height_index.* - PLAYFIELD_HEIGHT;
            const result = check_wall_collision(
                square_height_index,
                entity,
                game_state,
            );
            if (result.did_collide) {
                game_state.entity_fine_position[entity][0] = 0xC;
                game_state.entity_wall_collision[entity] = true;
            } else {
                //@ ;--------------------------
                //@ ;  decrement in X direction
                //@ EN.XDE:
                //@     LDA EN.IX(X)
                //@     BPL 40$
                if (game_state.entity_fine_position[entity][0] < 0) {
                    //@     ADD #20
                    //@     STA EN.IX(X)
                    game_state.entity_fine_position[entity][0] += 0x20;

                    //@     LDA EN.HP(X)
                    //@     ADD #04
                    //@     STA EN.HP(X)

                    //@     LDA EN.VP(X)
                    //@     ADD #04
                    //@     STA EN.VP(X)
                    game_state.entity_picture_position[entity] += .{ 4, 4 };

                    //@     DEC EN.MX(X)
                    game_state.entity_playfield_position[entity][0] -= 1;

                    //@     JSR EN.MUP        ;  new square
                    move_entity_to_new_square(
                        entity,
                        game_state,
                        result.in_tunnel,
                        square_height_index,
                        out_square_height_index,
                        out_square_flags_index,
                    );

                    //@     TRAI 2 EN.AND(X)    ;  animation direction
                    game_state.entity_animation_direction[entity] = 2;

                    //@ 40$:
                    //@     RTS
                }
            }
        }
    }
    if (game_state.entity_movement_delta[1] >= 0) {
        if (game_state.entity_fine_position[entity][1] >= 0x14) {
            const square_height_index = out_square_height_index.* + 1;
            const result = check_wall_collision(
                square_height_index,
                entity,
                game_state,
            );
            if (result.did_collide) {
                game_state.entity_fine_position[entity][1] = 0x13;
                game_state.entity_wall_collision[entity] = true;
            } else {
                //@ ;------------------------------
                //@ ;  increment in Y direction   -
                //@ ;------------------------------
                //@ EN.YIN:
                //@     LDA EN.IY(X)
                //@     SUB #20
                //@     BMI 40$
                if (game_state.entity_fine_position[entity][1] - 0x20 >= 0) {
                    //@     STA EN.IY(X)
                    game_state.entity_fine_position[entity][1] -= 0x20;

                    //@     LDA EN.HP(X)
                    //@     ADD #08
                    //@     STA EN.HP(X)

                    //@     DEC EN.VP(X)
                    //@     DEC EN.VP(X)
                    game_state.entity_picture_position[entity] += .{ 8, -2 };

                    //@     INC EN.MY(X)
                    game_state.entity_playfield_position[entity][1] += 1;
                    //@     JSR EN.MUP        ;  new square
                    move_entity_to_new_square(
                        entity,
                        game_state,
                        result.in_tunnel,
                        square_height_index,
                        out_square_height_index,
                        out_square_flags_index,
                    );
                    //@     TRAI 3 EN.AND(X)    ;  animation direction
                    game_state.entity_animation_direction[entity] = 3;
                    //@ 40$:
                }
                //@     RTS
            }
        }
    } else {
        if (game_state.entity_fine_position[entity][1] < 0xC) {
            const square_height_index = out_square_height_index.* - 1;
            const result = check_wall_collision(
                square_height_index,
                entity,
                game_state,
            );
            if (result.did_collide) {
                game_state.entity_fine_position[entity][1] = 0xC;
                game_state.entity_wall_collision[entity] = true;
            } else {
                //@ ;------------------------------
                //@ ;  decrement in Y direction   -
                //@ ;------------------------------
                //@ EN.YDE:
                //@     LDA EN.IY(X)
                //@     BPL 40$
                if (game_state.entity_fine_position[entity][1] < 0) {
                    //@     ADD #20
                    //@     STA EN.IY(X
                    game_state.entity_fine_position[entity][1] += 0x20;

                    //@     LDA EN.HP(X
                    //@     SUB #08
                    //@     STA EN.HP(X)

                    //@     INC EN.VP(X)
                    //@     INC EN.VP(X)
                    game_state.entity_picture_position[entity] += .{ -8, 2 };

                    //@     DEC EN.MY(X)
                    game_state.entity_playfield_position[entity][1] -= 1;

                    //@     JSR EN.MUP    ;  new sqare update
                    move_entity_to_new_square(
                        entity,
                        game_state,
                        result.in_tunnel,
                        square_height_index,
                        out_square_height_index,
                        out_square_flags_index,
                    );
                    //@     TRAI 1 EN.AND(X)    ;  animation direction
                    game_state.entity_animation_direction[entity] = 1;
                    //@ 40$:
                    //@     RTS
                }
            }
        }
    }

    //@ 60$:
    //@     RTS
}
const CollisionResult = struct {
    did_collide: bool = false,
    in_tunnel: bool = false, //for use in EN.MUP
};
fn check_collision_flag(
    square_height_index: usize,
    entity: usize,
    game_state: *GameState,
) bool {
    //TODO: figure out what these flags are
    const flags = game_state.current_wave_data[
        square_height_index +
            PLAYFIELD_HEIGHT * PLAYFIELD_HEIGHT
    ];
    const did_collide = flags & 0x8 != 0 and entity != PLAYER_ENTITY;
    return did_collide;
}
fn check_wall_collision(
    square_height_index: usize,
    entity: usize,
    game_state: *GameState,
) CollisionResult {
    //This is a combo of all the EN.CXI, EN.CYI, etc and EN.B2C subroutines
    //TODO: figure out what these flags are
    const flags_index =
        square_height_index +
        PLAYFIELD_HEIGHT * PLAYFIELD_HEIGHT;
    const flags = game_state.current_wave_data[flags_index];

    var did_collide = flags & 0x8 != 0 and entity != PLAYER_ENTITY;
    var in_tunnel = flags & 0x20 != 0;

    const square_height = game_state.current_wave_data[square_height_index];
    const vertical_distance = game_state.entity_height[entity] - square_height;
    if (@abs(vertical_distance) <= 2) {
        in_tunnel = false;
    } else if (!in_tunnel) {
        did_collide = true;
    }
    return .{ .in_tunnel = in_tunnel, .did_collide = did_collide };
}
//@ ;--------------------------------------------------
//@ ;  routine to update for new square
//@ EN.MUP:
fn move_entity_to_new_square(
    entity: usize,
    game_state: *GameState,
    in_tunnel: bool,
    new_square_height_index: usize,
    out_square_height_index: *usize,
    out_square_flags_index: *usize,
) void {
    //@     LDY #0
    //@     TXA
    //@     IFNE
    if (entity != PLAYER_ENTITY) {
        //@         ; clear collision bit
        //@     LDA @EZ.MA2(Y)
        //@     AND #^B11110111
        //@     STA @EZ.MA2(Y)
        const old_flags = &game_state.current_wave_data[out_square_flags_index.*];
        old_flags.* &= 0b11110111;
        //@     ENDIF
    }

    //@     TR16AM EZ.BOR,EZ.MAT
    out_square_height_index.* = new_square_height_index;
    //@     TR16AM EZ.BO2,EZ.MA2
    out_square_flags_index.* = new_square_height_index + PLAYFIELD_HEIGHT * PLAYFIELD_WIDTH;

    const new_flags = &game_state.current_wave_data[out_square_flags_index.*];
    //@     TXA
    //@     IFNE
    if (entity != PLAYER_ENTITY) {
        //@     LDA @EZ.MA2(Y)    ;  set collision bit, except player
        //@     ORA #^B00001000
        //@     STA @EZ.MA2(Y)
        new_flags.* |= 0b00001000;
        //@     ENDIF
    }

    //@     LDA @EZ.MA2(Y)
    //@     AND #20
    //@     IFEQ
    if (new_flags.* & 0x20 == 0) {
        //@      STA EN.TFL(X)
        game_state.entity_in_tunnel[entity] = false;
    }
    //@     ELSE        ; if tunnel
    else {
        //@      LDA EN.TFP(X)      ; update tunnel flag
        //@      IFNE
        if (in_tunnel) {
            //@       TRAI 1 EN.TFL(X)
            game_state.entity_in_tunnel[entity] = true;
            //@      ENDIF
        }
        //@      LDA EN.TFL(X)      ; and mt priority
        //@      IFNE
        if (game_state.entity_in_tunnel[entity]) {
            //@       TRAI 0FF EN.PR1(X)
            game_state.entity_priority[entity][0] = -1;
            //@       BNE 50$        ;  BRA
            //@ 50$:
            //@     TRAI 1 EN.NSF(X)    ;  new square flag
            game_state.entity_new_square_flag[entity] = true;
            //@     RTS
            return;

            //@      ENDIF
        }
        //@     ENDIF
    }

    //@     LDA  @EZ.MA2(Y)
    //@     AND #40
    //@     IFNE
    if (new_flags.* & 0x40 == 0) {
        //@      TRAI 0 EN.PR1(X)
        game_state.entity_priority[entity][0] = 0;
    }
    //@     ELSE
    else {
        //@      TRAI 0FF EN.PR1(X)
        game_state.entity_priority[entity][0] = -1;
        //@     ENDIF
    }

    //@ 50$:
    //@     TRAI 1 EN.NSF(X)    ;  new square flag
    game_state.entity_new_square_flag[entity] = true;

    //@     RTS
}

//@     EN.PUP:
fn animate_player(game_state: *GameState) void {
    const entity = PLAYER_ENTITY;
    //@     .RADIX 10
    //@ EN.TBL:    .BYTE 1,5,25,29,17,21,9,13
    const PLAYER_PICTURE_NUMBERS = [_]isize{ 1, 5, 25, 29, 17, 21, 9, 13 };

    //@     LDA EN.LMD
    //@     CMP #1
    //@     IFEQ
    if (game_state.entity_life_mode[PLAYER_ENTITY] == .Dying) {
        //@ EN.DTL:
        //@     .BYTE 105.,105.,85.,81.
        //@     .BYTE 101.,101.,85.,81.
        //@     .BYTE 97.,93.,93.,81.
        //@     .BYTE 89.,89.,85.,81.
        const PLAYER_DYING_PICTURES = [16]isize{
            105, 105, 85, 81,
            101, 101, 85, 81,
            97,  93,  93, 81,
            89,  89,  85, 81,
        };
        //@      LDA EN.DEL
        const delay = game_state.entity_delay[PLAYER_ENTITY];
        //@      IFNE
        if (delay > 0) {
            //@       LSRS 5    ;  input 0-7F, output 0-3
            //@       AND #03    ;  just in case
            var picture_index = (delay >> 5) & 3;

            //@       STA TEMP1
            //@       LDA WV.LIV
            //@       CMP #4
            //@       IFCS
            //@        LDA #4
            //@       ENDIF
            const lives = @min(game_state.lives, 4);
            //@       SUB #1
            //@       ASLS 2
            //@       ADD TEMP1
            picture_index += (lives - 1) << 2;
            //@       TAY
            //@       LDA EN.DTL(Y)
            const picture = PLAYER_DYING_PICTURES[@intCast(picture_index)];
            //@      JSR EN.PCF
            fill_entity_pictures(picture, entity, game_state);
            //@      ENDIF
        }
        //@      RTS
        return;
        //@     ENDIF
    }

    //@ ;  get one of four directions
    //@     LDA EN.AND(X)
    //@     ASL
    //@     STA TEMP5

    //@ ;  get step,  left-right
    //@     LDA #0
    //@     LDY EN.JFL
    //@     IFEQ        ;  only if not jumping
    //@     LDA EN.IX
    //@     ADD EN.IY
    //@     AND #10
    //@     LSRS 4
    //@     ENDIF
    //@     ADD TEMP5
    var picture_number_index =
        game_state.entity_animation_direction[entity] << 1;
    if (!game_state.entity_jump_flag) {
        picture_number_index += ((game_state.entity_fine_position[entity][0] +
            game_state.entity_fine_position[entity][1]) & 0x10) >> 4;
    }

    //@ ;  picture
    //@     TAY
    //@     LDA EN.TBL(Y)
    var picture_number = PLAYER_PICTURE_NUMBERS[@intCast(picture_number_index)];

    //@     ADD #2
    //@     STA EN.PC3(X)
    game_state.entity_picture[entity][2] = picture_number + 2;
    //@     ADC #1
    //@     STA EN.PC4(X)
    game_state.entity_picture[entity][3] = picture_number + 3;

    //@     LDY EN.CDL
    //@     IFEQ
    //@      SUB #3
    //@     ELSE
    //@      LDA #109.
    //@     ENDIF
    if (game_state.entity_collision_delay > 0) {
        picture_number = 0x109;
    }

    //@     STA EN.PC1(X)
    game_state.entity_picture[entity][0] = picture_number;
    //@     ADD #1
    //@     STA EN.PC2(X)
    game_state.entity_picture[entity][1] = picture_number + 1;
    //@     RTS
}
//EN.COL
fn detect_collision(entity: usize, game_state: *GameState) void {
    //@ ;-----------------------
    //@ ;  collision EN vs EN(0)

    //@ EN.COL:
    //@     COLSIZ=080
    //@     LDA EN.LMD(X)    ;  if not on maze, no collision
    //@     IFNE
    if (game_state.entity_life_mode[entity] != .Alive) {
        //@      RTS
        return;
        //@     ENDIF
    }

    //@ ;  compare EN CE X
    //@     LDA EN.IX(X)
    //@     ASLS 3
    //@     STA EN.T1
    const entity_fine_x = game_state.entity_fine_position[entity][0] * 8;

    //@     LDA EN.IX
    //@     ASLS 3
    //@     SUB EN.T1
    //@     STA EN.T2
    const player_entity_delta_x = (game_state.entity_fine_position[PLAYER_ENTITY][0] * 8) - entity_fine_x + 0x80;
    //@     LDA EN.MX
    //@     SBC EN.MX(X)
    //@     STA EN.T3
    const playfield_delta_x =
        game_state.entity_playfield_position[PLAYER_ENTITY][0] -
        game_state.entity_playfield_position[entity][0] - @as(isize, if (player_entity_delta_x < 0) 1 else 0);

    //@     AD16AI EN.T2 COLSIZ
    //NOTE handled above

    //@     LDA EN.T3    ; high byte of difference must =0,1
    //@     CMP #1
    //@     IFCS
    if (u8gte(playfield_delta_x, 1)) {
        //@      RTS
        return;
        //@     ENDIF
    }

    //@     LDA EN.IY(X)
    //@     ASLS 3
    //@     STA EN.T4
    const entity_fine_y = game_state.entity_fine_position[entity][1] * 8;

    //@     LDA EN.IY
    //@     ASLS 3
    //@     SUB EN.T4
    //@     STA EN.T5
    const player_entity_delta_y =
        (game_state.entity_fine_position[PLAYER_ENTITY][1] * 8) -
        entity_fine_y; //TODO: where did this come from: + 0x80;

    //@     LDA EN.MY
    //@     SBC EN.MY(X)
    //@     STA EN.T6
    const playfield_delta_y =
        game_state.entity_playfield_position[PLAYER_ENTITY][1] -
        game_state.entity_playfield_position[entity][1] -
        @as(isize, if (player_entity_delta_y < 0) 1 else 0);
    //@     AD16AI EN.T5 COLSIZ
    //NOTE handled above

    //@     LDA EN.T6    ;  high byte of difference must =0
    //@     CMP #1
    //@     IFCS
    if (u8gte(playfield_delta_y, 1)) {
        //@      RTS
        return;
        //@     ENDIF
    }

    //@     LDA EN.JFL    ;  if not jumping
    //@     IFEQ
    if (!game_state.entity_jump_flag) {
        //@      LDA EN.HEI(X)    ;  height difference <=2
        //@      SUB EN.HEI
        const height_delta = game_state.entity_height[entity] - game_state.entity_height[PLAYER_ENTITY];
        //@      BINT 2,40$
        // 40$_B19B:
        //@      RTS
        if (height_delta >= 3 or height_delta < -4) {
            return;
        }
        //@     ENDIF
    }
    //@ 40$:
    //@     LDA EN.STA(X)
    //@     CMP #7        ;  honey
    //@     IFEQ
    if (game_state.entity_state[entity] == .Honey) {
        //@      LDA #14
        //@      JSR MN.SN1
        //TODO: game sound

        //@      TRAI 01 EN.ANV(X)
        game_state.entity_animation[entity] = 1;
        //@      LDA #10    ;  1000 points
        //@ 41$:
        //@      STA 1+SC.INC
        //@      LDA #0
        //@      STA SC.INC
        //@      STA 2+SC.INC

        //@      JSR SC.UPD
        update_score(1000, game_state);
        //@      TRAI 0D EN.STA(X)
        game_state.entity_state[entity] = .ScoreDisplay;
        //@      TRAI 080 EN.DEL(X)
        game_state.entity_delay[entity] = 0x80;
        //@      RTS
        return;
        //@     ENDIF
    }

    //@     CMP #6        ;  witch
    //@     IFEQ
    if (game_state.entity_state[entity] == .Witch) {
        //*******TODO********
        unreachable;
        //@      LDA EN.CDL
        //@      IFNE
        //@       TRAI 02 EN.ANV(X)
        //@       LDA #30    ;  3000 points
        //@       BNE 41$    ;  BRA
        //@      ENDIF
        //@     ENDIF
    }

    //@     LDA EN.CDL
    //@     IFNE
    if (game_state.entity_collision_delay != 0) {
        //@      RTS
        return;
        //@     ENDIF
    }

    //@     LDA EN.STA(X)
    switch (game_state.entity_state[entity]) {
        .ScoreDisplay => {
            //@     CMP #0D        ;  score display
            //@     IFEQ
            //@      RTS
            //@     ENDIF
            return;
        },
        .Hat => {
            //@     CMP #0A        ;  hat
            //@     IFEQ
            //@      TRAI 0FF EN.CDL    ;  collision delay
            game_state.entity_collision_delay = 0xFF;

            //@      LDA #8
            //@      JSR MN.SN1
            //TODO: game sound

            //@ 42$:     TRAI 0 EN.ANV(X)
            game_state.entity_animation[entity] = 0;

            //@      LDA #05
            //@      BNE 41$    ;   BRA

            //@ 41$:
            //@      STA 1+SC.INC
            //@      LDA #0
            //@      STA SC.INC
            //@      STA 2+SC.INC

            //@      JSR SC.UPD
            update_score(500, game_state);
            //@      TRAI 0D EN.STA(X)
            game_state.entity_state[entity] = .ScoreDisplay;
            //@      TRAI 080 EN.DEL(X)
            game_state.entity_delay[entity] = 0x80;
            //@      RTS
            return;
            //@     ENDIF

        },
        .PlungerEating => {
            //@ ;    LDA EN.STA(X)    ;  if creature eating
            //@     CMP #3
            //@     IFEQ
            //@      LDA EN.JFL
            //@      IFEQ        ;  and no jumping
            if (game_state.entity_jump_flag) {
                //@       LDA #2
                //@       JSR MN.SN1
                //TODO: game sound
            }
            //@       JMP 42$
            //@ 42$:     TRAI 0 EN.ANV(X)
            game_state.entity_animation[entity] = 0;

            //@      LDA #05
            //@      BNE 41$    ;   BRA

            //@ 41$:
            //@      STA 1+SC.INC
            //@      LDA #0
            //@      STA SC.INC
            //@      STA 2+SC.INC

            //@      JSR SC.UPD
            update_score(500, game_state);
            //@      TRAI 0D EN.STA(X)
            game_state.entity_state[entity] = .ScoreDisplay;
            //@      TRAI 080 EN.DEL(X)
            game_state.entity_delay[entity] = 0x80;
            //@      RTS
            return;
            //@      ENDIF
            //@     ELSE

        },
        else => {
            //@      LDA EN.JFL    ; if jumping
            //@      IFNE
            if (game_state.entity_jump_flag) {
                //@       LDA EN.STA(X)
                switch (game_state.entity_state[entity]) {
                    .PlayerOrTree => {
                        //@       IFEQ        ; if  a tree
                        //TODO:
                        unreachable;
                        //@        TRAI 0 EN.ANV(X)    ;  youth regained
                        //@        LDY WV.DF2
                        //@        TRAM DF.TRG(Y) EN.DEL(X)    ; tree growing time
                        //@        TRAI 0 1+EN.DEL(X)

                    },
                    //@        CMP #1
                    //@        IFPL
                    //@        CMP #3
                    //@        IFMI
                    .PlungerMovingTowardsWall, .PlungerFollowsWall => {
                        //@         TRAI 5 EN.STA(X)    ;  stun it
                        game_state.entity_state[entity] = .PlungerStunned;
                        //@         TR16AI 60 EN.DEL(X)
                        game_state.entity_delay[entity] = 0x60;
                        //@        ENDIF
                        //@        ENDIF

                    },
                    else => {},
                }
            }
            //@      ELSE
            else {
                //@       TRAI 1 EN.LMD    ;  else player death
                game_state.entity_life_mode[PLAYER_ENTITY] = .Dying;
                //@       TRAI 07F EN.DEL
                game_state.entity_delay[PLAYER_ENTITY] = 0x7F;
                //@       LDA #3
                //@       JSR MN.SN1    ;  pl death sound
                //TODO: game sound
                //@      ENDIF
            }
        },
    }
}

//SC.UPD
fn update_score(delta: isize, game_state: *GameState) void {
    //@ ;----------------------
    //@ ;  update score
    //@ SC.UPD:

    //@     SED
    //@     LDA SC.SCO
    //@     ADD SC.INC
    //@     STA SC.SCO
    //@     LDA SC.SCO+1
    //@     ADC SC.INC+1
    //@     STA SC.SCO+1
    //@     LDA SC.SCO+2
    //@     ADC SC.INC+2
    //@     STA SC.SCO+2
    //@     CLD
    //NOTE: this is decimal adjustment code which we don't need
    game_state.score += delta;

    //@     PHXYA            ;  don't zap (X)
    //@     JSR SC.OT2
    draw_score(game_state);
    //@     PLXYA

    //@     LDA SC.NEL
    //@     IFNE
    //@     LDA SC.SCO+2
    //@     CMP SC.NEL
    //@     IFCS
    if (game_state.next_extra_life != 0 and
        game_state.score >= (game_state.next_extra_life << 16))
    {
        //****TODO*****
        unreachable;

        //@      SED
        //@ 10$:     LDA SC.NEL
        //@      ADD #7        ;  extra life every 70000
        //@      IFCS
        //@       LDA #0
        //@      ENDIF        ;  no bugs at 1 million please
        //@      STA SC.NEL

        //@      LDA SC.SCO+2
        //@      CMP SC.NEL
        //@      BCS 10$    ;  max of 1 extra life per inc

        //@      CLD
        //@      LDA WV.LIV
        //@      CMP #6        ;  max of six lives
        //@      IFCC

        //@      LDA #1
        //@      JSR MN.SN1    ; extra life sound

        //@      LDA SC.INC+2
        //@      CMP #2        ;  don't give extra lives for warp
        //@      IFCC
        //@       INC WV.LIV
        //@      ENDIF

        //@      TRAM WV.LIV TEMP5
        //@      PHXYA            ;  don't zap (X)
        //@      JSR SC.LD2
        //@      PLXYA

        //@      ENDIF
        //@     ENDIF
        //@     ENDIF
    }

    //@     RTS
}

//EN.CDT
fn detect_gem(entity: usize, game_state: *GameState) void {
    //@ ;------------
    //@ ;  detect gem
    //@ EN.CDT:
    //@     LDA EN.LMD(X)
    //@     IFNE
    if (game_state.entity_life_mode[entity] != .Alive) {
        //@     RTS        ; must be alive to see gems
        return;
        //@     ENDIF
    }
    const entity_state = &game_state.entity_state[entity];

    //@     LDA EN.STA(X)
    //@     CMP #06        ; only gem-eaters and trees see gems
    //@     IFPL
    //@     CMP #9
    //@     IFNE
    //@      RTS
    //@     ENDIF
    //@     ENDIF
    if (@intFromEnum(entity_state.*) >= 6 and entity_state.* != .CrystalBall) {
        return;
    }

    //@     LDA EN.TFL(X)
    //@     IFEQ        ; if not in tunnel
    //NOTE: doing a return early instead of a giant if statement
    if (game_state.entity_in_tunnel[entity]) {
        return;
    }
    const entity_flags = &game_state.current_wave_data[
        game_state.entity_playfield_square_flags_index[entity]
    ];
    //@     LDA @EZ.MA2(Y)
    //@     AND #10
    //@     IFNE        ; first time there
    if (entity_flags.* & 0b00010000 != 0) {
        //@     LDA @EZ.MA2(Y)
        //@     AND #^B11101111
        //@     STA @EZ.MA2(Y)
        entity_flags.* &= 0b11101111;

        //@     TXA
        //@     IFEQ        ;  bear
        if (entity == PLAYER_ENTITY) {

            //@      LDA SC.GEM
            //@      CMP #99
            //@      IFCC
            if (u8lt(game_state.gems_collected, 99)) {
                //@       SED
                //@       ADC #1
                //@       CLD
                //@       STA SC.GEM
                game_state.gems_collected += 1;
                //@      ENDIF
            }
            //@      LDA #0
            //@      STA 1+SC.INC
            //@      STA 2+SC.INC
            //@      TRAM SC.GEM SC.INC
            //@      JSR SC.UPD
            update_score(game_state.gems_collected, game_state);

            //TODO: sound
            //@      JSR MN.SN2    ;  sound for gem
        }
        //@     ELSE        ;  others
        else {
            //TODO: sound
            //@      JSR MN.SN3

            //@      LDA EN.STA(X)
            //@      CMP #1
            //@      IFNE
            //@      CMP #2
            //@      BNE 10$
            //@      ENDIF

            switch (entity_state.*) {
                .PlungerMovingTowardsWall, .PlungerFollowsWall => {
                    //@       LDY WV.DF2
                    //@       TRAM DF.ETD(Y) EN.DEL(X)
                    //@       TRAI 0 1+EN.DEL(X)
                    game_state.entity_delay[entity] =
                        EATING_TIMES[@intCast(game_state.wave_long_term_difficulty)];
                    //@       TRAI 3 EN.STA(X)
                    entity_state.* = .PlungerEating;
                },
                else => {},
            }
            //@  10$:
            //@     ENDIF
        }

        //@     JSR EN.COE        ;  erase gem
        erase_gem(entity, game_state);
        //@     INC SN.GFL
        //TODO: sound

        //@     DEC16A CE.COC        ;  dec gem count
        game_state.wave_gems_left -= 1;

        //@     LDA CE.COC
        //@     ORA 1+CE.COC
        //@     IFEQ
        if (game_state.wave_gems_left == 0) {
            //@      STX EN.LDF
            game_state.entity_that_took_last_gem = entity;
            //@     ENDIF
        }
        //@     ENDIF
    }
    //@     ENDIF
    //@     RTS
}
//EN.OUT
fn output_entity(entity: usize, game_state: *GameState) void {
    //@ ;----------------------------------------
    //@ ;  output EN
    //@ ;  convert to screen coordinates
    //@ ;  INPUT  EN.HP VP HEI HOF IX IY
    //@ ;  OUTPUT EN.X EN.Y
    //@ EN.OUT:
    //@     LDA EN.BLK(X)
    //@     BNE 10$        ;  blanking

    //@     LDA EN.LMD(X)
    //@     CMP #3        ;  if dead, no picture
    //@     IFEQ
    //@ 10$:      LDA #0
    //@       JSR EN.PCF
    //@     ENDIF
    if (game_state.entity_blanking_flag[entity] or game_state.entity_life_mode[entity] == .Dead) {
        fill_entity_pictures(0, entity, game_state);
    }

    //@     LDA EN.LMD(X)
    //@             ;  if unalive, skip this
    //@     IFNE
    //@      RTS
    //@     ENDIF
    if (game_state.entity_life_mode[entity] != .Alive) {
        return;
    }

    //@     LDA EN.HEI(X)
    //@     ADD EN.HOF(X)
    //@     STA EN.HTO(X)

    //@     LDA EN.IY(X)    ; EN.IY/4
    //@     LSRS 2
    //@     STA EN.TMP

    //@     LDA EN.HP(X)
    //@     ADD EN.TMP
    //@     TAY        ; + EN.HP

    //@     LDA EN.IX(X)
    //@     LSRS 3
    //@     STA EN.TMP    ; EN.IX/8

    //@     TYA
    //@     SUB EN.TMP
    //@     STA EN.X(X)    ; EN.HP+EN.IY/4-EN.IX/8

    //@     LDA EN.VP(X)
    //@     SUB EN.TMP
    //@     TAY        ; EN.VP-EN.IX/8

    //@     LDA EN.IY(X)
    //@     ADD #08
    //@     LSRS 4
    //@     STA EN.TMP
    //@     TYA
    //@     SUB EN.TMP
    //@     ADD EN.HTO(X)
    //@     STA EN.Y(X)    ; -(EN.IY+8)/16+HEIGHT
    const fine_position = game_state.entity_fine_position[entity];
    const picture_position = game_state.entity_picture_position[entity];

    //TODO: I think this is right??
    game_state.entity_position[entity] = .{
        //X: EN.HP+EN.IY/4-EN.IX/8
        picture_position[0] + @divTrunc(fine_position[1], 4) - @divTrunc(fine_position[0], 8),

        //Y:  EN.VP-EN.IX/8-(EN.IY+8)/16+HEIGHT
        picture_position[1] - @divTrunc(fine_position[0], 8) -
            @divTrunc((fine_position[1] + 8), 16) +
            (game_state.entity_height[entity] + game_state.entity_hof[entity]),
    };

    //@     RTS

}
//EN.STC
fn entity_state_calculation(entity: usize, game_state: *GameState) void {
    //TODO
    //@ ;-------------------------------------------
    //@ ;  calculate EN movement,  state calculation
    //@ EN.STC:
    //@     TXA    ;  do nothing for player
    //@     IFEQ
    //@      RTS
    //@     ENDIF
    if (entity == PLAYER_ENTITY) {
        return;
    }

    //@     TRAI 0 EN.XD
    //@     STA EN.YD
    //TODO: player movement deltas.  do we need to make these global?
    //      Thinking we don't need to because the only caller has these zeroed out anyway

    //@     LDA EN.STA(X)
    //@     CMP #10
    //@     IFCS
    //@      LDA #10
    //@     ENDIF
    const entity_state = game_state.entity_state[entity];
    //@     ASL
    //@     TAY
    //@     JMPIN 1$

    switch (entity_state) {
        .PlungerMovingTowardsWall => {
            //@  DEC16A EN.DEL(X)
            game_state.entity_delay[entity] -= 1;
            //@  LDA EN.DEL(X)
            //@  IFEQ
            //@  LDA 1+EN.DEL(X)
            //@  IFEQ
            if (game_state.entity_delay[entity] == 0) {
                //@   LDA EN.SP1(X)
                //@   CMP EN.MSG
                //@   IFMI
                if (game_state.entity_slow_speed[entity] < game_state.gem_eater_max_speed) {
                    //@   INC EN.SP1(X)
                    game_state.entity_slow_speed[entity] += 1;
                    //@   ENDIF
                }

                //@   TR16AI 100 EN.DEL(X)
                game_state.entity_delay[entity] = 0x100;
                //@  ENDIF
                //@  ENDIF
            }

            //@  LDA EN.WCF(X)
            //@  IFNE        ;  if wall was hit
            if (game_state.entity_wall_collision[entity]) {
                //@   TRAI 0FF TEMP1 ;  turn right
                //@   LDA EN.DR(X)
                //@   ADD TEMP1
                //@   AND #03
                //@   STA EN.DR(X)
                game_state.entity_direction[entity] += 0xFF;
                game_state.entity_direction[entity] &= 3;
                //@   TRAI 2 EN.STA(X)    ; and follow wall
                game_state.entity_state[entity] = .PlungerFollowsWall;
                //@   TRAI 3 EN.ANV(X)    ; reset turn-counter
                game_state.entity_animation[entity] = 3;
                //@  ENDIF
            }
            //@  JSR EN.DRC    ;  direction calc
            calculate_entity_deltas(entity, game_state);
            //@  JSR EN.PLP
            fill_plunger_pictures(entity, game_state);

            //@  JMP 50$
            clamp_delta_entity_movement_delta(game_state);
        },
        .PlungerFollowsWall => {
            //@  DEC16A EN.DEL(X)
            //@  LDA EN.DEL(X)
            //@  IFEQ
            //@  LDA 1+EN.DEL(X)
            //@  IFEQ
            if (game_state.entity_delay[entity] == 0) {
                //@   LDA EN.SP1(X)
                //@   CMP EN.MSG
                //@   IFMI
                if (game_state.entity_slow_speed[entity] < game_state.gem_eater_max_speed) {
                    //@   INC EN.SP1(X)
                    game_state.entity_slow_speed[entity] += 1;
                    //@   ENDIF
                }

                //@   TR16AI 50 EN.DEL(X)
                game_state.entity_delay[entity] = 0x50;

                //@   LDA RANDOM
                //@   AND #03
                //@   STA EN.DR(X)
                game_state.entity_direction[entity] =
                    @intCast(toolbox.random32(&game_state.rng_state) & 3);
                //@  ENDIF
                //@  ENDIF
            }

            //@ LDA EN.NSF(X)
            //@ IFNE
            if (game_state.entity_new_square_flag[entity]) {
                //@  TRAI 1 TEMP1
                //@  LDA EN.DR(X)    ;  turn left at new square
                //@  ADD TEMP1
                //@  AND #03
                //@  STA EN.DR(X)
                game_state.entity_direction[entity] =
                    (game_state.entity_direction[entity] + 1) & 3;
                //@  DEC EN.ANV(X)
                //@  IFEQ
                if (game_state.entity_animation[entity] == 0) {
                    //@   TRAI 1 EN.STA(X)
                    game_state.entity_state[entity] = .PlungerMovingTowardsWall;
                    //@  ENDIF
                }
            }
            //@  ELSE
            else {
                //@ LDA EN.WCF(X)
                //@ IFNE
                if (game_state.entity_wall_collision[entity]) {
                    //@  TRAI 0FF TEMP1
                    //@  LDA EN.DR(X)    ;  turn right at wall
                    //@  ADD TEMP1
                    //@  AND #03
                    //@  STA EN.DR(X)
                    game_state.entity_direction[entity] =
                        (game_state.entity_direction[entity] - 1) & 3;
                    //@  TRAI 3 EN.ANV(X)
                    game_state.entity_animation[entity] = 3;
                    //@ ENDIF
                }
                //@ ENDIF
            }

            //@ JSR EN.DRC
            calculate_entity_deltas(entity, game_state);

            //@ JSR EN.PLP
            fill_plunger_pictures(entity, game_state);

            //@ JMP 50$
            clamp_delta_entity_movement_delta(game_state);
        },
        .CrystalBall => {
            //@ 37$:    .BYTE 228.,230.,232.,234.,234.,234.,236.,238.
            const CRYSTAL_BALL_PICURES = [_]isize{
                228, 230, 232, 234, 234, 234, 236, 238,
            };
            //@ ;  crystal ball, state 9

            //@ 19$:
            //@     LDA #0
            //@     JSR EN.PCF
            fill_entity_pictures(0, entity, game_state);
            //@     LDA FRAME
            //@     AND #70
            //@     LSRS 4
            //@     TAY
            //@     LDA 37$(Y)
            const picture = CRYSTAL_BALL_PICURES[@intCast((game_state.frame & 0x70) >> 4)];
            //@     STA EN.PC3(X)
            game_state.entity_picture[entity][2] = picture;
            //@     ADD #1
            //@     STA EN.PC4(X)
            game_state.entity_picture[entity][3] = picture + 1;

            //@     LDA FRAME
            //@     AND #03
            //@     IFEQ
            if (game_state.frame & 3 == 0) {
                //@      TRAM EN.CMS TEMP1

                //@      LDA EN.MX
                //@      SUB EN.MX(X)
                const delta_x =
                    game_state.entity_playfield_position[PLAYER_ENTITY][0] -
                    game_state.entity_playfield_position[entity][0];
                //@      IFMI
                //@       LDA EN.GP1(X)
                //@       SUB #1
                //@      ELSE
                //@       CMP #1
                //@       IFPL
                //@        LDA EN.GP1(X)
                //@        ADD #1
                //@       ELSE
                //@        LDA EN.GP1(X)
                //@       ENDIF
                //@      ENDIF
                game_state.general_purpose_1[entity] += if (delta_x < 0)
                    -1
                else if (delta_x >= 1)
                    1
                else
                    0;

                //@      JSR GP.TRC
                //@      STA EN.GP1(X)
                game_state.general_purpose_1[entity] = toolbox.clamp(
                    game_state.general_purpose_1[entity],
                    -game_state.crystal_monster_speed,
                    game_state.crystal_monster_speed,
                );

                //@ ;  y coordinate

                //@      LDA EN.MY
                //@      SUB EN.MY(X)
                const delta_y =
                    game_state.entity_playfield_position[PLAYER_ENTITY][1] -
                    game_state.entity_playfield_position[entity][1];
                //@      IFMI
                //@       LDA EN.GP2(X)
                //@       SUB #1
                //@      ELSE
                //@       CMP #1
                //@       IFPL
                //@        LDA EN.GP2(X)
                //@        ADD #1
                //@       ELSE
                //@        LDA EN.GP2(X)
                //@       ENDIF
                //@      ENDIF
                game_state.general_purpose_2[entity] += if (delta_y < 0)
                    -1
                else if (delta_y >= 1)
                    1
                else
                    0;
                //@      JSR GP.TRC
                //@      STA EN.GP2(X)
                game_state.general_purpose_2[entity] = toolbox.clamp(
                    game_state.general_purpose_2[entity],
                    -game_state.crystal_monster_speed,
                    game_state.crystal_monster_speed,
                );
            }
            //@     ENDIF

            //@     TRAM EN.GP1(X) EN.XD
            //@     TRAM EN.GP2(X) EN.YD
            game_state.entity_movement_delta =
                .{ game_state.general_purpose_1[entity], game_state.general_purpose_2[entity] };
            //@     RTS
        },
        .Swarm => {
            //@     DEC16A EN.DEL(X)
            //@     LDA EN.DEL(X)
            game_state.entity_delay[entity] -= 1;
            //@     IFEQ
            //@     LDA 1+EN.DEL(X)
            //@     IFEQ
            if (game_state.entity_delay[entity] == 0) {
                //@      TRAI 1 EN.LMD(X)
                game_state.entity_life_mode[entity] = .Dying;
                //@      JSR EN.CCB
                //clear collision bit
                game_state.current_wave_data[game_state.entity_playfield_square_flags_index[entity]] &= 0b11110111;
            }
            //@     ENDIF
            //@     ENDIF

            //@     LDA FRAME
            //@     AND #0C
            //@ ;    LSR        ; 0,4,8 OR C

            //@     ADD #128.+68.
            //@     JSR EN.PCF
            fill_entity_pictures(
                (game_state.frame & 0xC) + 128 + 68,
                entity,
                game_state,
            );

            //@     LDY WV.DF2
            //@     LDA 1+WV.TIM
            //@     LSR
            //@     ADD DF.SWS(Y)
            //@     CMP #10
            //@     IFCS
            //@     LDA #10
            //@     ENDIF
            const entity_slow_speed = @min((game_state.wave_time >> 9) +
                SWARM_SPEEDS[@intCast(game_state.wave_long_term_difficulty)], 0x10);
            //@     STA EN.SP1(X)
            game_state.entity_slow_speed[entity] = entity_slow_speed;

            //@     JMP 45$
            killer_algorithm(entity, game_state);
        },
        .PlungerStunned => {
            //  DEC16A EN.DEL(X)
            game_state.entity_delay[entity] -= 1;
            //  LDA EN.DEL(X)
            //  IFEQ
            //  LDA 1+EN.DEL(X)
            //  IFEQ
            if (game_state.entity_delay[entity] == 0) {
                //   TRAI 1 EN.STA(X)
                game_state.entity_state[entity] = .PlungerMovingTowardsWall;
                //   TRAI 1 EN.SP1(X)
                game_state.entity_slow_speed[entity] = 1;

                //   TR16AI 50 EN.DEL(X)
                game_state.entity_delay[entity] = 0x50;
                //   LDA RANDOM
                //   AND #03
                const direction: isize = @intCast(toolbox.random32(&game_state.rng_state) & 3);
                //   STA EN.DR(X)
                game_state.entity_direction[entity] = direction;
                //  ENDIF
                //  ENDIF
            }

            // LDA #80
            // JSR EN.PCF
            fill_entity_pictures(0x80, entity, game_state);
        },
        else =>
        //TODO
        unreachable,
    }
}
//45$
fn killer_algorithm(entity: usize, game_state: *GameState) void {

    //@ LDA EN.IX(X)
    //@ LSRS 2
    //@ STA TEMP1
    //@ LDA EN.MX(X)
    //@ ASLS 3
    //@ ORA TEMP1
    //@ STA TEMP2

    //@ LDA EN.IX
    //@ LSRS 2
    //@ STA TEMP1
    //@ LDA EN.MX
    //@ ASLS 3
    //@ ORA TEMP1
    //@ SUB TEMP2

    //@ IFCS
    //@  CMP EN.SP1(X)
    //@  IFCS
    //@   LDA EN.SP1(X)
    //@  ENDIF
    //@ ELSE
    //@  NEGA
    //@  CMP EN.SP1(X)
    //@  IFCS
    //@   LDA EN.SP1(X)
    //@  ENDIF
    //@  NEGA
    //@ ENDIF

    //@ STA EN.XD

    //@ LDA EN.IY(X)
    //@ LSRS 2
    //@ STA TEMP1
    //@ LDA EN.MY(X)
    //@ ASLS 3
    //@ ORA TEMP1
    //@ STA TEMP2

    //@ LDA EN.IY
    //@ LSRS 2
    //@ STA TEMP1
    //@ LDA EN.MY
    //@ ASLS 3
    //@ ORA TEMP1
    //@ SUB TEMP2

    //@ IFCS
    //@  CMP EN.SP1(X)
    //@  IFCS
    //@   LDA EN.SP1(X)
    //@  ENDIF
    //@ ELSE
    //@  NEGA
    //@  CMP EN.SP1(X)
    //@  IFCS
    //@   LDA EN.SP1(X)
    //@  ENDIF
    //@  NEGA
    //@ ENDIF

    //@ STA EN.YD

    const delta =
        (@divTrunc(game_state.entity_fine_position[entity], V2{ 4, 4 }) |
        @divTrunc(game_state.entity_playfield_position[entity], V2{ 8, 8 })) -
        (@divTrunc(game_state.entity_fine_position[PLAYER_ENTITY], V2{ 4, 4 }) |
        @divTrunc(game_state.entity_playfield_position[PLAYER_ENTITY], V2{ 8, 8 }));
    const slow_speed = game_state.entity_slow_speed[entity];
    inline for (0..2) |i| {
        if (delta[i] >= 0) {
            game_state.entity_movement_delta[i] = @min(delta[i], slow_speed);
        } else {
            game_state.entity_movement_delta[i] = @max(delta[i], -slow_speed);
        }
    }

    //@ JMP 50$
    clamp_delta_entity_movement_delta(game_state);
}
fn clamp_delta_entity_movement_delta(game_state: *GameState) void {
    //@ 50$:
    //@ TRAI 0C TEMP1    ;  truncate difs
    //@ LDA EN.XD
    //@ JSR GP.TRC
    //@ STA EN.XD

    //@ LDA EN.YD
    //@ JSR GP.TRC
    //@ STA EN.YD

    game_state.entity_movement_delta =
        toolbox.clamp(game_state.entity_movement_delta, .{ -12, -12 }, .{ 12, 12 });
}
//@ ;-----------------------
//@ ;  life mode calculation
//@ EN.LMC:
fn entity_life_mode_calculation(entity: usize, game_state: *GameState) void {
    //@     LDA EN.LMD(X)
    //@     IFEQ        ;  if alive skip this
    if (game_state.entity_life_mode[entity] == .Alive) {
        //@      RTS
        return;
        //@     ENDIF
    }
    //@     TRAI 0 EN.XD
    //@     STA EN.YD
    game_state.entity_movement_delta = ZV2;
    switch (game_state.entity_life_mode[entity]) {
        .Spawning => {
            //@   40$:        ;  if being born, then come in from top

            //@     LDA EN.LMD(X)
            //@     CMP #2
            //@     IFEQ
            //@ LDA EN.VP(X)
            //@ ADD EN.HEI(X)
            //@ STA TEMP1
            const destination = game_state.entity_picture_position[entity][1] +
                game_state.entity_height[entity];

            //@ LDA EN.STA(X)
            //@ CMP #8
            //@ IFEQ
            var dy: isize = 4;
            if (game_state.entity_state[entity] == .Swarm) {
                //@  LDA #8         ;  delete this if really pressed
                //@  LDY WV.DF2
                //@  CPY #4
                //@  IFCC
                //@  LDA WV.TIM+1
                //@  CMP #12
                //@  IFCC
                //@  LDA #2
                dy = if (game_state.wave_long_term_difficulty < 4 and
                    game_state.wave_time < 0x1200)
                    2
                else
                    8;
                //@  ENDIF
                //@  ENDIF
            }
            //@ ELSE
            //@  LDA #4
            //@ ENDIF
            //@ STA TEMP2

            //@ LDA EN.Y(X)
            //@ SUB TEMP2
            //@ STA EN.Y(X)
            game_state.entity_position[entity][1] -= dy;
            const entity_y = game_state.entity_position[entity][1];
            //@ CMP #-28
            //@ IFPL
            //@  CMP #-28+8    ;  between -4 and -1
            //@  IFMI
            if (entity_y >= -0x28 and
                entity_y < -0x28 + 8)
            {
                //@  TRAI 0 EN.BLK(X)    ;  no more blanking
                game_state.entity_blanking_flag[entity] = false;
            }
            //@  ENDIF
            //@ ENDIF

            //@ LDA EN.Y(X)
            //@ SUB #1
            //@ CMP TEMP1    ;  if at destination
            //@ IFCC
            //@  LDA EN.BLK(X)    ;  and visible
            //@  IFEQ
            if (u8lt(entity_y - 1, destination) and !game_state.entity_blanking_flag[entity]) {
                //@   STA EN.LMD(X)
                game_state.entity_life_mode[entity] = .Alive;
            }
            //@  ENDIF
            //@ ENDIF

        },
        .Dead => {
            //@ ;   swarm in limbo  start afresh, after timer

            //@     LDA EN.STA(X)
            //@     CMP #8
            //@     IFEQ

            //@     LDA 1+WV.TIM
            //@     CMP #06
            //@     IFCC
            //@      LDA WV.TIM    ;   check only every 4 secs
            //@      IFEQ
            //@      LDA 4+EN.STA
            //@      CMP #7        ;   if honey there
            //@      ENDIF
            //@     ELSE
            //@      LDA #0        ;   or too much time
            //@     ENDIF
            //@     IFEQ
            //@     LDA WV.TIM+1
            //@     CMP #1        ;  after 4 secs, come out anyway
            //@     IFCS
            //@     LDA EN.EWM
            //@     IFEQ        ;  not while eow in progress
            //@      LDA EN.DEA(X)
            //@      IFEQ
            if (game_state.entity_state[entity] == .Swarm and
                ((game_state.wave_time & 0xFF == 0 and
                game_state.entity_state[4] == .Honey) or
                (game_state.wave_time >= 0x600)) and
                game_state.wave_time >= 0x100 and
                !game_state.entity_end_of_wave_mode and
                !game_state.entity_is_dead[entity])
            {
                //@       TRAI 2 EN.LMD(X)    ;  start to scroll down
                game_state.entity_life_mode[entity] = .Spawning;
                //@       JSR EN.INR        ;  re-init position
                init_entity_position(entity, game_state);
                //@       LDA #4
                //@       JSR MN.SN1        ;  start bee warning sound
                //TODO: sound
                //@      ENDIF
                //@      ENDIF
                //@      ENDIF
                //@     ENDIF
                //@     ENDIF
            }
            //@     RTS

        },
        .Dying => {
            //@     TXA
            //@     IFEQ        ;  player rises to top, then dies
            if (entity == PLAYER_ENTITY) {
                //@       LDA EN.DEL
                //@       IFEQ
                if (game_state.entity_delay[entity] == 0) {
                    //@        LDA EN.Y
                    //@        ADD #8
                    //@        STA EN.Y
                    game_state.entity_position[entity][1] += 8;
                    //@        CMP #0FF-18
                    //@        IFCS
                    if (game_state.entity_position[entity][1] >= 0xFF - Y_COORDINATE_OFFSET) {
                        //@         TXA            ;  (X)=0
                        //@         JSR EN.PCF
                        fill_entity_pictures(0, entity, game_state);
                        //@         TRAI 3 EN.LMD
                        game_state.entity_life_mode[entity] = .Dead;
                        //@         JSR GM.DT0
                        init_death_sequence_state(game_state);
                    }
                    //@        ENDIF
                }
                //@       ELSE
                else {
                    //@        DEC EN.DEL
                    game_state.entity_delay[entity] -= 1;
                    //@       ENDIF

                }

                //@     ;  creature dying
            }
            //@     ELSE
            else {

                //@      JSR EN.CCB
                //clear collision
                game_state.current_wave_data[
                    game_state.entity_playfield_square_flags_index[entity]
                ] &= 0b11110111;
                //@      LDA EN.Y(X)
                //@      CMP #0FF-24
                //@      IFCS
                if (u8gte(game_state.entity_position[entity][1], 0xFF - 0x24)) {
                    //@       TRAI 3 EN.LMD(X)
                    game_state.entity_life_mode[entity] = .Dead;
                }
                //@      ELSE            ;  rise to top
                else {
                    //@       ADD #4
                    //@       STA EN.Y(X)
                    game_state.entity_position[entity][1] += 4;
                    //@      ENDIF
                }

                //@     ENDIF
            }
            //@     RTS
        },
        else => unreachable,
    }
}
//@ ;----------------------------------
//@ ;  calculate difs given direction
//@ ;  0 r 1 b 2 l 3 f
//@ EN.DRC:
fn calculate_entity_deltas(entity: usize, game_state: *GameState) void {
    //@     LDA EN.DR(X)
    //@     IFEQ
    //@      STA EN.XD
    //@      TRAM EN.SP1(X) EN.YD
    //@      RTS
    //@     ENDIF

    //@     CMP #1
    //@     IFEQ
    //@      LDA EN.SP1(X)
    //@      NEGA
    //@      STA EN.XD
    //@      TRAI  0 EN.YD
    //@      RTS
    //@     ENDIF

    //@     CMP #2
    //@     IFEQ
    //@      TRAI 0 EN.XD
    //@      LDA EN.SP1(X)
    //@      NEGA
    //@      STA EN.YD
    //@      RTS
    //@     ENDIF

    //@     CMP #3
    //@     IFEQ
    //@      TRAM EN.SP1(X) EN.XD
    //@      TRAI 0 EN.YD
    //@      RTS
    //@     ENDIF

    //@     RTS
    switch (game_state.entity_direction[entity]) {
        0 => {
            //@      STA EN.XD
            //@      TRAM EN.SP1(X) EN.YD
            //@      RTS
            game_state.entity_movement_delta = .{
                0,
                game_state.entity_slow_speed[entity],
            };
        },
        1 => {
            //@      LDA EN.SP1(X)
            //@      NEGA
            //@      STA EN.XD
            //@      TRAI  0 EN.YD
            game_state.entity_movement_delta = .{
                -game_state.entity_slow_speed[entity],
                0,
            };
        },
        2 => {
            //@      TRAI 0 EN.XD
            //@      LDA EN.SP1(X)
            //@      NEGA
            //@      STA EN.YD
            game_state.entity_movement_delta = .{
                0,
                -game_state.entity_slow_speed[entity],
            };
        },
        3 => {
            //@      TRAM EN.SP1(X) EN.XD
            //@      TRAI 0 EN.YD
            //@      RTS
            game_state.entity_movement_delta = .{
                game_state.entity_slow_speed[entity],
                0,
            };
        },
        else => unreachable,
    }
}
//@     ;-----------
//@ ;  erase gem
//@ EN.COE:
fn erase_gem(entity: usize, game_state: *GameState) void {
    //TODO
    //@     LDY #0
    //@     LDA @EZ.MA2(Y)
    const flags = game_state.current_wave_data[
        game_state.entity_playfield_square_flags_index[entity]
    ];
    //@     JSR CL.PR
    set_bitmap_values_of_faces(flags, game_state);

    //@     LDA EN.HP(X)
    //@     ADD #06
    //@     STA XB

    //@     LDA EN.VP(X)
    //@     SUB #03
    //@     ADD @EZ.MAT(Y)
    //@     NEGA

    //@     STA YB
    const height = game_state.current_wave_data[
        game_state.entity_playfield_square_height_index[entity]
    ];
    var position = V2{
        game_state.entity_picture_position[entity][0] + 6,
        -(game_state.entity_picture_position[entity][1] - 3 + height) & 0xFF,
    };
    //@     LDA FC.BV3
    const color_value = game_state.face_color_values[0];
    const color = color_value_to_color(color_value);
    //@     STA VB
    add_draw_pixel_command(color, position, game_state);
    //@     INC XB
    position[0] += 1;
    //@     STA VB
    add_draw_pixel_command(color, position, game_state);
    //@     INC XB
    position[0] += 1;
    //@     STA VB
    add_draw_pixel_command(color, position, game_state);

    //@     DEC YB
    position[1] -= 1;
    //@     INC XB
    position[0] += 1;
    //@     STA VB
    add_draw_pixel_command(color, position, game_state);
    //@     DEC XB
    position[0] -= 1;
    //@     STA VB
    add_draw_pixel_command(color, position, game_state);
    //@     DEC XB
    position[0] -= 1;
    //@     STA VB
    add_draw_pixel_command(color, position, game_state);
    //@     DEC XB
    position[0] -= 1;
    //@     STA VB
    add_draw_pixel_command(color, position, game_state);
    //@     DEC XB
    position[0] -= 1;
    //@     STA VB
    add_draw_pixel_command(color, position, game_state);

    //@     DEC YB
    position[1] -= 1;
    //@     INC XB
    position[0] += 1;
    //@     STA VB
    add_draw_pixel_command(color, position, game_state);
    //@     INC XB
    position[0] += 1;
    //@     STA VB
    add_draw_pixel_command(color, position, game_state);
    //@     INC XB
    position[0] += 1;
    //@     STA VB
    add_draw_pixel_command(color, position, game_state);

    //@     RTS
}

//@ ;---------------------------
//@ ;  update player,  jump etc.
//@ EN.PLU:
fn update_player(game_state: *GameState) void {

    //@     LDA EN.LMD    ;  must be alive
    //@     IFNE
    if (game_state.entity_life_mode[PLAYER_ENTITY] != .Alive) {
        //@      RTS
        return;
        //@     ENDIF
    }

    //@     JSR EN.BRD        ;  read both buttons
    _ = read_both_buttons(game_state);

    //@     LDA ATRACT
    //@     IFEQ
    if (game_state.is_in_attract_mode) {
        //@      TRAI 0 EN.JBP        ;  usually not jumping
        game_state.jump_button_pressed = false;
        //@      LDA WV.TIM+1
        //@      IFNE
        //@      LDA WV.TIM
        //@      IFEQ
        if (game_state.wave_time >= 0x100 and game_state.wave_time & 0xFF == 0) {
            //@       TRAI E.JUMP EN.JBP
            game_state.jump_button_pressed = true;
        }
        //@      ENDIF
        //@      ENDIF
        //@     ENDIF
    }

    //@     LDA EN.JFL    ;  jump flag update
    //@     IFEQ
    if (!game_state.entity_jump_flag) {
        //@      LDA EN.JDL
        //@      IFEQ
        if (game_state.entity_jump_delay == 0) {
            //@       LDA EN.JBP
            //@       AND #E.JUMP
            //@       IFNE        ;  button down
            if (game_state.jump_button_pressed) {
                //@        LDA EN.TFL    ; if not in tunnel
                //@        IFEQ
                if (!game_state.entity_in_tunnel[PLAYER_ENTITY]) {
                    //@         TRAI 0FF EN.JFL
                    game_state.entity_jump_flag = true;
                    //@         TRAI 20 EN.JDL    ;  start jump
                    game_state.entity_jump_delay = 0x20;
                    //@         LDA #9
                    //@         JSR MN.SN1        ;  jump sound
                    //TODO: sound
                }
                //@        ENDIF
                //@       ENDIF
            }
        }
        //@      ELSE
        else {
            //@       DEC EN.JDL
            game_state.entity_jump_delay -= 1;
            //@      ENDIF
        }
        //@     ENDIF
    }

    //@     LDA EN.JFL
    //@     IFNE
    if (game_state.entity_jump_flag) {
        //@      DEC EN.JDL
        game_state.entity_jump_delay -= 1;
        //@      IFEQ            ;  landing
        if (game_state.entity_jump_delay == 0) {
            //@       LDA #2
            //@       STA EN.JDL
            game_state.entity_jump_delay = 2;
            //@       LDA #0
            //@       STA EN.JFL
            game_state.entity_jump_flag = false;
            //@       LDA EN.MX
            //@       AND EN.MY
            //@       CMP #14
            //@       IFEQ
            if (@reduce(.And, game_state.entity_playfield_position[PLAYER_ENTITY]) == 0x14) {
                //@        INC AT.OUT
                game_state.show_easter_egg_count += 1;
                //@       ENDIF
            }
            //@      ENDIF
        }
        //@     ENDIF
    }

    //@     LDA EN.JFL
    //@     IFNE
    if (game_state.entity_jump_flag) {
        //@ EN.JTL:
        const JUMP_OFFSETS = [_]isize{
            0x0,  0x4,  0x8,  0xB,  0xE,  0x11, 0x14, 0x16, 0x18, 0x1A, 0x1C, 0x1D, 0x1E, 0x1F, 0x1F, 0x20,
            0x20, 0x20, 0x1F, 0x1F, 0x1E, 0x1D, 0x1C, 0x1A, 0x18, 0x16, 0x14, 0x11, 0xE,  0xB,  0x8,  0x4,
        };
        //@      LDA EN.JDL
        //@      TAY
        //@      LDA EN.JTL(Y)
        //@      STA EN.HOF
        game_state.entity_hof[PLAYER_ENTITY] = JUMP_OFFSETS[@intCast(game_state.entity_jump_delay)];
    }
    //@     ELSE
    else {
        //@      TRAI 0 EN.HOF
        game_state.entity_hof[PLAYER_ENTITY] = 0;
        //@     ENDIF
    }

    //@     RTS
}
//EC.UPD
fn update_elevators(game_state: *GameState) void {
    //TODO
    _ = game_state;
}

//EN.BRD
fn read_both_buttons(game_state: *GameState) usize {
    //TODO
    _ = game_state;

    return 0;
}

//EN.EWC
fn end_of_wave_calculation(game_state: *GameState) void {
    //@ ;-------------------------
    //@ ;  end of wave calculation
    //@ EN.EWC:

    //@ ;  if everybody in limbo, and no gems, advance wave

    //TODO: figure out what this is.  Has something to do with life mode != 3
    //  Need to know what life mode 3 is
    var not_sure_what_this_is = true;
    //@     LDX #2
    //@     BEGIN
    for (1..MAX_NUMBER_OF_ENTITIES) |entity| {
        //@      LDA EN.LMD(X)
        //@      CMP #3
        if (game_state.entity_life_mode[entity] != .Dead) {
            //@      BNE 20$
            not_sure_what_this_is = false;
            break;
            //@     INXS 2
            //@     CPX EN.NUM
            //@     PLEND
        }
    }

    if (not_sure_what_this_is) {
        //@     LDA EN.WRF
        //@     IFEQ
        if (!game_state.entity_is_warping) {
            //@     LDA CE.COC
            //@     ORA CE.COC+1
            //@     IFEQ        ;  all gems gone
            if (game_state.wave_gems_left == 0) {
                //****TODO******
                unreachable;
                //@      JSR EN.LDB    ;  last dot bonus awarded
                //@      JSR WV.UPD
                //@      JSR GM.EW0    ;  end of wave state
                //@     ENDIF
            }
            //@     ELSE        ;  end wave quickly when warping
        } else {
            //****TODO******
            unreachable;
            //@     JSR WV.MBF
            //@     JSR WV.UPD
            //@     JSR GM.EW0
            //@     ENDIF
        }
    }
    //@ 20$:

    //@     LDA EN.EWM
    //@     IFNE
    if (game_state.entity_end_of_wave_mode) {
        //@      RTS
        return;
        //@     ENDIF
    }

    //@ ;  all gems gone?
    //@     LDA CE.COC
    //@     ORA 1+CE.COC
    //@     IFEQ
    if (game_state.wave_gems_left == 0) {
        //@      JSR EN.EW    ;  end of wave
        //****TODO******
        unreachable;
        //@     ENDIF
    }

    //****TODO******
    //@ ;  warp
    //@     LDA EN.JBP
    //@     IFEQ
    //@      RTS
    //@     ENDIF
    //@ ;  button depressed

    //@     LDA WV.XCO
    //@     IFNE
    //@      JMP 55$
    //@     ENDIF

    //@ ;  ordinary warp
    //@     IFEQA WV.YCO 0
    //@     LDA EN.TFL
    //@     IFNE
    //@     LDA WV.WAR
    //@     IFNE
    //@ 10$:
    //@      STA TEMP5+1

    //@      LDA #0
    //@      STA SC.SCO
    //@      STA SC.SCO+1
    //@      STA SC.SCO+2
    //@      STA SC.INC
    //@      STA SC.INC+1
    //@      STA SC.INC+2
    //@      LDA #99
    //@      STA SC.GEM
    //@      LDX TEMP5+1
    //@      BEGIN
    //@       SED
    //@       LDA SC.INC+2
    //@       ADD #7
    //@       STA SC.INC+2
    //@       CLD
    //@       DEX
    //@      EQEND

    //@      LDY #4
    //@      LDX TEMP5+1
    //@      CPX #3
    //@      IFCS
    //@      LDY #5
    //@      ENDIF
    //@      LDA WV.LIV
    //@      STA TEMP1
    //@      CPY TEMP1
    //@      IFCC        ;  give at least the current lives
    //@       LDY TEMP1
    //@      ENDIF
    //@      STY WV.LIV
    //@      JSR SC.UPD

    //@      TRAM TEMP5+1 WV.XCD    ;  warp
    //@      LDX #0
    //@      STX WV.YCD
    //@      DEX
    //@      STX EN.WRF    ;  end wave immediately
    //@      JMP EN.EW
    //@ ;     RTS
    //@     ENDIF
    //@     ENDIF
    //@     ENDIF

    //@ ;  secret warp #1
    //@     LDA WV.YCO
    //@     IFEQ
    //@     IFEQA EN.MX 1
    //@     IFEQA EN.MY 1
    //@      LDA #2
    //@      JMP 10$
    //@     ENDIF
    //@     ENDIF
    //@     ENDIF

    //@ 55$:

    //@ ;  secret warp #2
    //@     IFEQA WV.XCO 2
    //@     IFEQA WV.YCO 0
    //@     IFEQA EN.MX 3
    //@     IFEQA EN.MY 3
    //@     LDA EN.CDL
    //@     IFNE
    //@      LDA #4
    //@      JMP 10$
    //@     ENDIF
    //@     ENDIF
    //@     ENDIF
    //@     ENDIF
    //@     ENDIF

    //@ ;  secret warp #3
    //@     IFEQA WV.XCO 4
    //@     IFEQA WV.YCO 2
    //@     IFEQA EN.MX 1
    //@     IFEQA EN.MY 1
    //@      LDA #6
    //@      JMP 10$
    //@     ENDIF
    //@     ENDIF
    //@     ENDIF
    //@     ENDIF

    //@ ;  FXL
    //@     IFEQA WV.XCO 5
    //@     IFEQA WV.YCO 3
    //@     IFEQA EN.MX 1
    //@     IFEQA EN.MY 1
    //@      LDA #35
    //@      JSR MS.DRW
    //@     ENDIF
    //@     ENDIF
    //@     ENDIF
    //@     ENDIF
    //@     RTS
}
// SC.LD2:
fn draw_lives(game_state: *GameState) void {
    //     TRAM WV.LIV TEMP5
    //     TRAI 0E8 AL.Y
    //     TRAI 010 AL.X
    const starting_position = V2{ 0x10, 0xE8 };

    //     LDA #6*6
    //     JSR SC.ERA
    screen_erase(starting_position, 6 * 6, game_state);

    // ;  life symbol
    //     TRAI 25 SC.DIG

    //     LDY TEMP5
    //     DEY
    //     STY TEMP5
    var lives = game_state.lives - 1;
    var position = starting_position;
    var suppress_zero = false;
    var pixels_left_to_erase: isize = 0;
    // 10$:
    while (true) {
        //     DEC TEMP5
        lives -= 1;
        //     BMI 20$
        if (lives < 0) {
            break;
        }
        //     JSR AL.DGO
        draw_digit(
            0x25,
            &position,
            &suppress_zero,
            &pixels_left_to_erase,
            game_state,
        );

        //     JMP 10$
    }
    // 20$:
    //     RTS
}

//@;--------------
//@;  draw gem row
//@CT.GRD:
fn draw_gem_row(game_state: *GameState) void {
    //@    JSR BL.INI
    initialize_block(game_state);
    //@10$:
    while (true) {
        //@    JSR BL.IN2
        initialize_block_2(game_state);

        //@    LDA @CT.A2L(Y)
        //@    AND #10
        //@    IFNE            ;  gem present
        if (game_state.current_wave_data[game_state.castle_a2l] & 0x10 != 0) {
            //@     INC16 CE.COC        ;  increment gem count
            game_state.wave_gems_left += 1;
            //@     JSR CT.SGD        ;  draw it
            {
                //@;--------------------------
                //@;  draw single gem
                //@CT.SGD:

                //@     LDA @CT.A2L(Y)        ;  set priority
                //@     JSR CL.PR
                set_bitmap_values_of_faces(
                    game_state.current_wave_data[game_state.castle_a2l],
                    game_state,
                );

                //@     LDA BL.HST
                //@     SUB #02
                //@     STA XB
                //@     LDA BL.VST
                //@     SUB BL.HEI
                //@     SUB #02
                //@     STA YB
                var position = game_state.castle_block_position - V2{
                    2,
                    2 + game_state.castle_block_height,
                };
                //@     TRAM FC.BVC VB
                var color =
                    color_value_to_color(game_state.face_color_values[4]); //this is FC.BVC
                add_draw_command(.{
                    .shape = .Pixel,
                    .position = position,
                    .color = color,
                }, game_state);

                //@     DEC XB
                position[0] -= 1;
                //@     STA VB
                add_draw_command(.{
                    .shape = .Pixel,
                    .position = position,
                    .color = color,
                }, game_state);
                //@     DEC YB
                //@     DEC XB
                position -= V2{ 1, 1 };
                //@     STA VB
                add_draw_command(.{
                    .shape = .Pixel,
                    .position = position,
                    .color = color,
                }, game_state);
                //@     DEC YB
                //@     INC XB
                position += V2{ 1, -1 };
                //@     STA VB
                add_draw_command(.{
                    .shape = .Pixel,
                    .position = position,
                    .color = color,
                }, game_state);
                //@     INC XB
                position[0] += 1;
                //@     STA VB
                add_draw_command(.{
                    .shape = .Pixel,
                    .position = position,
                    .color = color,
                }, game_state);
                //@     INC XB
                position[0] += 1;
                //@     STA VB
                add_draw_command(.{
                    .shape = .Pixel,
                    .position = position,
                    .color = color,
                }, game_state);
                //@     INC YB
                //@     INC XB
                position += V2{ 1, 1 };
                //@     STA VB
                add_draw_command(.{
                    .shape = .Pixel,
                    .position = position,
                    .color = color,
                }, game_state);
                //@     INC YB
                //@     DEC XB
                position += V2{ -1, 1 };
                //@     STA VB
                add_draw_command(.{
                    .shape = .Pixel,
                    .position = position,
                    .color = color,
                }, game_state);
                //@     DEC YB
                position[1] -= 1;
                //@     STA VB
                add_draw_command(.{
                    .shape = .Pixel,
                    .position = position,
                    .color = color,
                }, game_state);
                //@     DEC XB
                position[0] -= 1;
                //@     STA VB
                add_draw_command(.{
                    .shape = .Pixel,
                    .position = position,
                    .color = color,
                }, game_state);
                //@     DEC XB
                position[0] -= 1;
                //@     LDA FC.BVS    ;  white highlight
                color =
                    color_value_to_color(game_state.face_color_values[6]); //this is FC.BVS
                //@     STA VB
                add_draw_command(.{
                    .shape = .Pixel,
                    .position = position,
                    .color = color,
                }, game_state);
                //@    RTS
            }
            //@    ENDIF
        }

        //@    INC16 CT.ADL
        game_state.castle_adl += 1;
        //@    DEC CR.CNT
        game_state.castle_block_count -= 1;
        //@    BMI 20$
        if (game_state.castle_block_count < 0) {
            break;
        }
        //@    JSR BL.ADV
        advance_block(game_state);
        //@    JMP 10$
    }
    //@20$:
    //@    INC16 CT.ADL
    //@    INC16 CT.ADL
    game_state.castle_adl += 2;

    //@    RTS
}

//;  ----- state 2: start of wave
//GM.SW0
fn start_of_wave(game_state: *GameState) void {
    //@ TRAI 2 GM.STA
    game_state.current_state = .StartOfWave;

    //@    JSR MS.MWV        ; draw message, if any
    draw_beginning_of_wave_message(game_state);

    //@;  on block 0,0 don't draw city, for player 1
    //@    LDA PL.UP
    //@    ORA WV.XCO
    //@    ORA WV.YCO
    //@    BEQ 10$
    if (game_state.wave_xco != 0 or game_state.wave_yco != 0) {
        //@    JSR CT.INI        ; init city+elevators
        initialize_city(game_state);
        //@    JSR CT.DRW        ; draw city
        draw_city(game_state);
    }

    //@10$:

    //@    JSR EN.INI        ; init entities
    init_entities(game_state);

    //@    JSR EN.INP        ; and positions
    init_all_entity_positions(game_state);
    //@    JSR MN.INM        ; zero motion objects
    {
        //@ ;--------------------------------------
        //@ ;  init motion objects at start of game
        //@ MN.INM:

        //@    LDX #2
        //@    BEGIN
        inline for (1..MAX_NUMBER_OF_ENTITIES) |entity| {
            //@     TRAI 0F0 EN.Y(X)
            game_state.entity_position[entity][1] = 0xF0;
            //@     JSR MN.OFI
            //@     ;-------------
            //@; init offsets
            //@MN.OFI:
            //@    TRAI 0 EN.XO1(X)
            //@    STA  EN.YO1(X)
            //@    STA  EN.XO2(X)
            //@    STA  EN.YO2(X)
            //@    STA  EN.XO3(X)
            //@    STA  EN.YO3(X)
            //@    STA  EN.XO4(X)
            //@    STA  EN.XO4(X)
            game_state.entity_motion_object_offsets[entity] = .{
                ZV2, ZV2, ZV2, ZV2,
            };
            //@    RTS
            //@    INXS 2
            //@    CPX EN.NUM
            //@    PLEND
        }

        //@    TRAI 80 EN.X
        //@    TRAI 08 EN.Y
        //TODO: I think the entity position is unsigned, but the offsets are signed
        game_state.entity_position[0] = .{ 0x80, 8 };
        //@    RTS
    }
    //@    JSR WV.BSP        ; move bear to starting pos
    {
        //@ ;--------------------------------
        //@;  move bear to starting position
        //@WV.BSP:
        //@;  bear facing away
        //@    LDX #0
        //@    LDA #11
        //@    JSR EN.PCF
        fill_entity_pictures(0x11, PLAYER_ENTITY, game_state);

        //@; determine destination
        //@    LDA EN.VP
        //@    ADD EN.HEI
        //@    SUB #6
        //@    STA EN.DSY
        //@    LDA EN.HP
        //@    ADD #1
        //@    STA EN.DSX
        const player_destination =
            game_state.entity_picture_position[PLAYER_ENTITY] +
            V2{ 1, game_state.entity_height[PLAYER_ENTITY] - 6 };

        //NOTE(DanB): WV.BSP falls through to WV.BMV instead of jumping to it
        //@WV.BMV:
        move_player_to_destination(player_destination, game_state);
    }
    //@    JSR EN.INI        ; reinit entities
    init_entities(game_state);
    //@    JSR CT.GIN        ; init for gem drawing
    //@ ;-----------------------
    //@ ;  init for drawing gems
    //@ CT.GIN:
    //@     TR16AI 0 CE.COC
    game_state.wave_gems_left = 0;
    //@     JSR CR.INI
    initialize_castle_row(game_state);
    //@     RTS
}

//@ ;-------------------------------------------------------
//@ ;  draw message at beginning of wave, or in attract mode
//@ MS.MWV:
fn draw_beginning_of_wave_message(game_state: *GameState) void {
    //@      JSR AL.BER
    erase_board(game_state);
    //@      LDA ATRACT
    //@      IFNE
    if (!game_state.is_in_attract_mode) {
        //TODO:
        unreachable;
        //@       LDA WV.XCO
        //@       STA TEMP5+1

        //@       LDA WV.MFL
        //@       IFNE

        //@       LDA WV.MNM
        //@       IFEQ        ;  on wave 1
        //@        LDX WV.WAR
        //@        IFNE
        //@         STX TEMP5+1
        //@         LDA #1B
        //@        ENDIF
        //@       ELSE
        //@       CMP #1
        //@       IFEQ
        //@        LDX EEEXTR
        //@        IFNE
        //@         LDA #2B    ;  if no extra life, use ordinary title
        //@        ENDIF
        //@       ENDIF
        //@       ENDIF
        //@       JSR MS.DRW    ; wave titles
        //@       ENDIF

        //@       LDA #1F
        //@       JSR MS.DRW    ; level

        //@       LDA TEMP5+1    ;  level number
        //@       ADD #1
        //@       JSR DG.2OT
    }
    //@      ELSE
    else {
        //@       LDA #19    ; play crystal castles
        //@       JSR MS.DRW
        draw_message(0x19, game_state);
        //@      ENDIF
    }

    //@     RTS
}
//@WV.BMV:
//@; loop to move to destination
//Returns false if we need to wait for frame handler
fn move_player_to_destination(destination: V2, game_state: *GameState) void {
    var finished_moving = false;
    //@    BEGIN
    while (!finished_moving) {
        //@     JSR MN.FRA
        frame_handler(game_state);
        //@     JSR MT.UPD
        update_motion_objects(game_state);
        //@     TRAI 0 TEMP1
        //@     JSR WV.MVX
        //@     JSR WV.MVY
        const player_position = &game_state.entity_position[PLAYER_ENTITY];
        //@;----------------------------
        //@;  move bear to X destination
        //@WV.MVX:
        //@    LDA EN.X
        //@    SUB EN.DSX

        //@    IFCC
        //@     ADAI 4 EN.X
        //@     JMP WV.FFF
        //@    ENDIF

        //@    CMP #4
        //@    IFCS
        //@     SBAI 4 EN.X
        //@     JMP WV.FFF
        //@    ENDIF
        //@    TRAM EN.DSX EN.X
        //@    RTS
        //@WV.FFF:
        //@    TRAI 0FF TEMP1
        //@    RTS

        //@;----------------------------
        //@;  move bear to Y destination
        //@WV.MVY:

        //@    LDA EN.Y
        //@    SUB EN.DSY

        //@    IFCC
        //@     ADAI 4 EN.Y
        //@     JMP WV.FFF
        //@    ENDIF

        //@    CMP #4
        //@    IFCS
        //@     SBAI 4 EN.Y
        //@     JMP WV.FFF
        //@    ENDIF

        //@    TRAM EN.DSY EN.Y
        //@    RTS
        finished_moving = true;
        inline for (0..2) |i| {
            const delta = player_position[i] - destination[i];
            if (u8lt(delta, 0)) {
                player_position[i] += 4;
                finished_moving = false;
            }
            if (u8gte(delta, 4)) {
                player_position.*[i] -= 4;
                finished_moving = false;
            }
            player_position[i] = destination[i];
        }

        //@     LDA TEMP1
        //@    EQEND

    }

    //@    RTS
}

//@;------------------------
//@;  init for start of wave
//@EN.INI:
fn init_entities(game_state: *GameState) void {
    //NOTE: en.num seems like its just used as a loop counter
    //@    TRAI 2*EN.MAX EN.NUM

    //@    LDX #0
    //@    STX EN.EWM    ;  end of wave mode init
    game_state.entity_end_of_wave_mode = false;

    //@    STX EN.WRF    ;  warp flag
    game_state.entity_is_warping = false;
    //@    STX EN.TFL
    game_state.entity_in_tunnel[0] = false;
    //@    STX SC.GEM    ;  gem counter
    game_state.gems_collected = 0;

    //@    BEGIN
    for (0..MAX_NUMBER_OF_ENTITIES) |entity| {
        //@     JSR EN.IN3
        //@;------------------------------
        //@;  init state, at start of wave
        //@EN.IN3:
        //@;  state, picture offsets,  life or death

        //@    TRAI 0 EN.DEA(X)    ;  everybody is alive
        game_state.entity_is_dead[entity] = false;
        //@    STA AT.OUT
        game_state.show_easter_egg_count = 0;

        //@    TXA
        //@    IFEQ
        if (entity == PLAYER_ENTITY) {
            //@     STA EN.STA
            game_state.entity_state[entity] = .PlayerOrTree;
            //@     TRAI 0F-3  EN.YO1
            //@     STA        EN.YO2
            //@     TRAI 0FF-3 EN.YO3
            //@     STA        EN.YO4

            //@     TRAI 0FC   EN.XO1
            //@     STA        EN.XO3
            //@     TRAI 4        EN.XO2
            //@     STA        EN.XO4
            const STARTING_PLAYER_MOTION_OBJECT_POSITIONS =
                [_]V2{
                .{ to_isize(0xFC), 0xF - 3 },
                .{ 4, 0xF - 3 },
                .{ to_isize(0xFC), to_isize(0xFF - 3) },
                .{ 4, to_isize(0xFF - 3) },
            };
            @memcpy(
                &game_state.entity_motion_object_offsets[entity],
                &STARTING_PLAYER_MOTION_OBJECT_POSITIONS,
            );
        }
        //@    ELSE
        else {

            //@     TRAI 0F    EN.YO1(X)
            //@     STA        EN.YO2(X)
            //@     TRAI 0FF   EN.YO3(X)
            //@     STA        EN.YO4(X)

            //@     TRAI 0FF EN.XO1(X)
            //@     STA     EN.XO3(X)
            //@     TRAI 7   EN.XO2(X)
            //@     STA     EN.XO4(X)
            const STARTING_PLAYER_MOTION_OBJECT_POSITIONS =
                [_]V2{
                .{ to_isize(0xFF), 0xF },
                .{ 7, 0xF },
                .{ to_isize(0xFF), to_isize(0xFF) },
                .{ 7, to_isize(0xFF) },
            };
            @memcpy(
                &game_state.entity_motion_object_offsets[entity],
                &STARTING_PLAYER_MOTION_OBJECT_POSITIONS,
            );

            //@     CPX #2    ; slot for swarm
            //@     IFEQ
            if (entity == SWARM_ENTITY) {
                //@      TRAI 8 EN.STA(X)
                game_state.entity_state[entity] = .Swarm;
            }
            //@     ELSE
            else {
                //@      TXA
                //@      LSR
                //@      SUB #2
                //@      STA TEMP1      ; table entry

                //@      LDA WV.NUM
                //@;  now have distribution number (0-0F)
                //@      ASLS 3
                //@      ADD TEMP1
                //@      TAY
                const entity_signed: isize = @intCast(entity);
                //NOTE: the multiplication by 2 is due to the fact that the original
                //@     code assumes that entity is incremented by 2, but we increment by 1
                //@     in this code base
                const creature_table_index = (((entity_signed * 2) >> 1) - 2) + (game_state.wave_current << 3);
                //@      LDA DF.CRT(Y)
                //@      STA EN.STA(X)
                game_state.entity_state[entity] = @enumFromInt(
                    CREATURE_TABLE[@intCast(creature_table_index)],
                );

                //@     ENDIF
            }
            //@    ENDIF
        }
        //@    PLEND
    }
}

//@;----------------------------------
//@;  init positions on wave (re)start
//@EN.INP:
fn init_all_entity_positions(game_state: *GameState) void {

    //@    LDA HW.TBH    ;  init trackball
    //@    STA TR.I

    //@    LDA HW.TBV
    //@    STA TR.J
    //TODO: may want to call out to platform layer
    //      to get initial trackball positions?
    //      For now, assume 0
    game_state.last_trackball_position = ZV2;

    //@    TRAI 040 EN.GDL
    game_state.general_start_delay = 0x40;
    //@    TRAI 2*EN.MAX EN.NUM
    //@    LDX #0
    //@    STX EN.CDL    ;  init collision delay
    game_state.entity_collision_delay = 0;

    for (0..MAX_NUMBER_OF_ENTITIES) |entity| {
        //@    BEGIN
        //@     JSR EN.IN2
        init_entity(entity, game_state);

        //@    INXS 2
        //@    CPX EN.NUM
        //@    PLEND
    }
}

//@;---------------------------------------
//@; routine to initialize EN,  on gp start
//@EN.IN2:
fn init_entity(entity: usize, game_state: *GameState) void {
    //@;  life mode
    //@    TXA
    //@    STA TEMP1    ;  for comparison later
    switch (entity) {

        //@    IFEQ
        PLAYER_ENTITY => {
            //@     STA EN.LMD    ;  player is alive
            game_state.entity_life_mode[entity] = .Alive;
        },
        //@    ELSE
        //@    CPX #2
        //@    IFEQ
        SWARM_ENTITY => {
            //@     TRAI 3 EN.LMD(X);  swarm comes in later
            game_state.entity_life_mode[entity] = .Dead;
        },
        //@    ELSE
        else => {
            //@    LDY WV.NUM
            //@    LDA DF.CRN(Y)
            //@    ADD WV.DF2        ;  increase number
            const creature_number = CREATURE_NUMBERS[@intCast(game_state.wave_current)] +
                game_state.wave_long_term_difficulty;

            //@    CMP #8            ;  of creatures
            //@    IFCS            ;  max of 8
            //@     LDA #8
            //@    ENDIF

            //@    ASL
            //@    ADD #2
            //@    CMP TEMP1
            //NOTE: adding 1 instead of 2, and not left shifting
            //      because entities are not
            //      16-bit addresses like in the original code base
            const creature_entity: usize = @intCast(@min(creature_number, 8) + 1);
            //@    IFPL
            if (creature_entity >= entity) {
                //@     LDA EN.DEA(X)
                //@     IFEQ        ;  if not completely dead
                if (!game_state.entity_is_dead[entity]) {

                    //@      TRAI 2 EN.LMD(X)    ;  start descent
                    game_state.entity_life_mode[entity] = .Spawning;
                    //@      LDA EN.STA(X)
                    //@      SUB #7
                    if (game_state.entity_state[entity] == .Honey) {
                        //@      IFEQ
                        //@       STA EN.LMD(X)
                        game_state.entity_life_mode[entity] = .Alive;
                        //@      ENDIF
                    }
                    //@     ENDIF
                }
                //@    ENDIF
            }
            //@    ELSE
            else {
                //@     TRAI 3 EN.LMD(X)
                game_state.entity_life_mode[entity] = .Dead;
                //@    ENDIF
            }
        },
    }

    init_entity_position(entity, game_state);
}

//@EN.INR:            ;  entry for init positions
fn init_entity_position(entity: usize, game_state: *GameState) void {
    //@    JSR EN.PSI    ;  position init
    //@;--------------------------------------------
    //@;  initialize positions etc., after death etc.
    //@EN.PSI:
    {
        //@    TXA
        //@    IFEQ        ;  player
        if (entity == PLAYER_ENTITY) {
            //@      STA  EN.JDL    ; not jumping
            game_state.entity_jump_delay = 0;
            //@      STA  EN.JFL    ; anymore
            game_state.entity_jump_flag = false;
            //@      STA  EN.BLK
            game_state.entity_blanking_flag[entity] = false;
            //@      TRAI 14 EN.MX
            //@      TRAI 11 EN.MY
            game_state.entity_playfield_position[entity] = .{ 0x14, 0x11 };
        }
        //@    ELSE
        else {
            //@;  init positions of creatures
            //@      LDA WV.NUM    ; 0-15
            //@      ASLS 3
            //@      ADD WV.NUM
            //@      STA TEMP1
            //@      TXA
            //@      LSR
            //@      SUB #1
            //@      ADD TEMP1
            const creature_initial_position_index =
                @as(usize, @intCast((game_state.wave_current << 3) + game_state.wave_current)) +
                (entity - 1);
            //@      TAY
            //@      TRAM DF.INX(Y) EN.MX(X)
            //@      TRAM DF.INY(Y) EN.MY(X)
            game_state.entity_playfield_position[entity] =
                CREATURE_INITIAL_POSITIONS[creature_initial_position_index];

            //@;  swarm on top of player after too much time
            //@      LDA EN.STA(X)
            //@      CMP #8
            //@      IFEQ
            if (game_state.entity_state[entity] == .Swarm) {
                //@       LDA WV.TIM+1
                //@       STA RS.KEY+1        ; key of swarm sound
                game_state.tune_table_keys[1] = (game_state.wave_time >> 8) & 0xFF;

                //@       LDA WV.DF2
                //@       LSR
                //@       JSR NEGATE
                //@       ADD #0B        ;  44 seconds
                //@       CMP 1+WV.TIM
                //@       IFCC
                if (game_state.wave_time >=
                    0xB00 - (game_state.wave_long_term_difficulty * 0x100))
                {
                    //@       LDA EN.TFL
                    //@       IFEQ
                    if (!game_state.entity_in_tunnel[PLAYER_ENTITY]) {

                        //@        LDA WV.TIM+1
                        //@        ADC #3
                        //@        STA RS.KEY+1
                        game_state.tune_table_keys[1] = (@divTrunc(game_state.wave_time, 0x100)) + 3;
                        //@        TRAM EN.MX EN.MX(X)
                        //@        LDA EN.MY
                        game_state.entity_playfield_position[entity] = game_state.entity_playfield_position[PLAYER_ENTITY];
                    }
                    //@       ELSE
                    else {
                        //@        LDA #014
                        //@        STA EN.MX(X)
                        game_state.entity_playfield_position[entity] = .{ 0x14, 0x14 };
                        //@       ENDIF
                    }
                    //@       STA EN.MY(X)

                    //@       ENDIF
                    //@      ENDIF
                }
            }

            //@      LDA EN.STA(X)
            //@      CMP #7
            //@      IFEQ
            //@       LDA #0
            //@      ELSE
            //@       LDA #0FF
            //@      ENDIF
            //@      STA EN.BLK(X)
            game_state.entity_blanking_flag[entity] = game_state.entity_state[entity] != .Honey;

            //@      TRAI 0 EN.ANV(X)    ;  animation variable init
            game_state.entity_animation[entity] = 0;

            //NOTE ignore GP fields for now. Probably can be just replaced by locals
            //@      STA EN.GP1(X)        ;  general purpose init
            //@      STA EN.GP2(X)

            //@      STA EN.DR(X)    ; direction
            game_state.entity_direction[entity] = 0;
            //@      STA EN.HOF(X)
            game_state.entity_hof[entity] = 0;

            //@      LDA EN.STA(X)
            //@      IFEQ
            if (game_state.entity_state[entity] == .PlayerOrTree) {
                //@       STA 1+EN.DEL(X)
                //@       LDY WV.DF2
                //@       TRAM DF.TRG(Y) EN.DEL(X)    ; tree growing time
                game_state.entity_delay[entity] =
                    TREE_GROWING_TIMES[@intCast(game_state.wave_long_term_difficulty)];
            }
            //@      ELSE
            else {
                //@      CMP #8        ;  swarm
                //@      IFEQ
                //@       TR16AI 140 EN.DEL(X)
                //@      ELSE
                //@       TR16AI 20 EN.DEL(X)
                //@      ENDIF
                //@      ENDIF
                game_state.entity_delay[entity] =
                    if (game_state.entity_state[entity] == .Swarm)
                    0x140
                else
                    0x20;
            }

            //@      LDY WV.DF2
            //@      LDA DF.SP1(Y)
            //@      ADD WV.DFO
            //@      STA EN.SP1(X)
            game_state.entity_slow_speed[entity] =
                GEM_EATER_INTIAL_SPEEDS[@intCast(game_state.wave_long_term_difficulty)] +
                game_state.wave_difficulty_offset;
            //@      LDA DF.MSG(Y)
            //@      ADD WV.DFO
            //@      STA EN.MSG        ;  max speed g-eat
            game_state.gem_eater_max_speed =
                GEM_EATER_MAX_SPEEDS[@intCast(game_state.wave_long_term_difficulty)] +
                game_state.wave_difficulty_offset;

            //@      TRAM DF.CMS(Y) EN.CMS        ;  crys mons speed
            game_state.crystal_monster_speed =
                CRYSTAL_MONSTER_SPEEDS[@intCast(game_state.wave_long_term_difficulty)];

            //@    ENDIF
        }
    }
    //@10$:
    while (true) {
        //NOTE: CTRAM is just current_wave_data
        //@    TR16AI CTRAM EN.MAT(X)

        //@    JSR EN.MUL
        const entity_playfield_position =
            game_state.entity_playfield_position[entity];
        //NOTE: the playfield is column-major

        //NOTE this is EN.OFF
        const playfield_index: usize =
            @intCast(
            entity_playfield_position[0] * PLAYFIELD_HEIGHT +
                entity_playfield_position[1],
        );
        //@    AD16AM EN.MAT(X) EN.OFF
        game_state.entity_playfield_square_height_index[entity] = playfield_index;

        //@    TR16AM EN.MAT(X) EN.MA2(X)
        //@    AD16AI EN.MA2(X) 16*16
        game_state.entity_playfield_square_flags_index[entity] =
            PLAYFIELD_WIDTH * PLAYFIELD_HEIGHT + playfield_index;

        //@    TR16AM EN.MAT(X) EZ.MAT
        //@    TR16AM EN.MA2(X) EZ.MA2
        //@    LDY #0
        //@    TRAM @EZ.MAT(Y) EN.HEI(X)
        game_state.entity_height[entity] =
            game_state.current_wave_data[
            game_state.entity_playfield_square_height_index[entity]
        ];

        //@;  height at 1 1 must not be 0 !!!!!!!! otherwise
        //@;  an infinite loop happens here

        //@    LDA EN.HEI(X)
        //@    IFEQ
        if (game_state.entity_height[entity] == 0) {
            //@     TRAI 1 EN.MX(X)
            //@     STA    EN.MY(X)
            game_state.entity_playfield_position[entity] =
                .{ 1, 1 };
            //@     BNE 10$        ;  BRA
            //@    ENDIF
        } else {
            break;
        }
    }

    const entity_playfield_position = game_state.entity_playfield_position[entity];
    const picture_position = &game_state.entity_picture_position[entity];
    //@; horizontal position
    //@    LDA EN.MX(X)
    //@    SUB #1
    //@    ASLS 2
    //@    STA EN.T1
    const t1 = (entity_playfield_position[0] - 1) * 4;
    //@    LDA EN.MY(X)
    //@    SUB #1
    //@    ASLS 3
    //@    STA EN.T2
    var t2 = (entity_playfield_position[1] - 1) * 8;
    //@    LDA #CT.HST-9    ; picture offset
    //@    ADD EN.T2
    //@    SUB EN.T1
    //@    STA EN.HP(X)
    picture_position[0] = (0x5C - 9) + t2 - t1;

    //@; vertical position
    //@    LDA EN.MY(X)
    //@    SUB #1
    //@    ASL
    //@    STA EN.T2
    t2 = (entity_playfield_position[1] - 1) * 2;
    //@    LDA #0-CT.VST-0B+06+0A    ; picture offset
    //@    SUB EN.T2
    //@    SUB EN.T1
    //@    STA EN.VP(X)
    picture_position[1] = 0x7F - t2 - t1;

    //@;  screen vert coordinate (used for scrolling down)
    //@    ADD EN.HEI(X)
    //@    STA EN.Y(X)
    //@    LDA EN.HP(X)
    //@    STA EN.X(X)
    game_state.entity_position[entity] =
        .{
        picture_position[0],
        picture_position[1] + game_state.entity_height[entity],
    };

    //@; pictures
    //@    TRAI 2  EN.AND(X)
    game_state.entity_animation_direction[entity] = 2;

    //@    LDA #11
    //@    JSR EN.PCF    ;  bear
    fill_entity_pictures(
        0x11,
        entity,
        game_state,
    );

    //@; priority
    //@    LDY #0
    //@    LDA @EZ.MA2(Y)
    //TODO: figure out what these flags are
    const flags =
        game_state.current_wave_data[
        game_state.entity_playfield_square_flags_index[entity]
    ];
    //@    AND #40
    //@    IFNE
    //@     TRAI 0 EN.PR1(X)
    //@    ELSE
    //@     TRAI 0FF EN.PR1(X)
    //@    ENDIF
    game_state.entity_priority[entity][0] =
        if (flags & 0x40 != 0) 0 else -1;

    //@; fine x,y
    //@    TRAI 10 EN.IX(X)
    //@    TRAI 0C EN.IY(X)
    game_state.entity_fine_position[entity] = .{ 0x10, 0xC };

    //@;  set collision bit, if not dead
    //@    LDA EN.LMD(X)
    //@    CMP #3
    //@    IFNE
    //@    CPX #0
    //@    IFNE
    if (game_state.entity_life_mode[entity] != .Dead and
        entity != PLAYER_ENTITY)
    {

        //@     LDA @EZ.MA2(Y)
        //@     ORA #08
        //@     STA @EZ.MA2(Y)
        game_state.current_wave_data[
            game_state.entity_playfield_square_flags_index[entity]
        ] |= 0b00001000;

        //@    ENDIF

        //@    ENDIF
    }
}

//@;----------------------------------
//@;  routine to update motion objects
//@MT.UPD:
fn update_motion_objects(game_state: *GameState) void {

    //@    JSR MT.SOR    ;  sort them
    // ;------------------------------
    // ;  sort motion objects
    // MT.SOR:
    // ;  init pointers
    //     LDX #15
    //     LDA #0
    //     BEGIN
    //      STA EN.SPT(X)
    //     DEX
    //     MIEND
    var column_indices = [_]isize{0} ** PLAYFIELD_WIDTH;
    var sorted_entities = [_]usize{0} **
        (MAX_NUMBER_OF_ENTITIES * PLAYFIELD_WIDTH);
    // ;  sort
    //     LDX #0
    //     BEGIN
    for (0..MAX_NUMBER_OF_ENTITIES) |entity| {
        // ;           update pointer
        //NOTE: I am hoping its the column-major-ness of the playfield is what's associating MX as the
        //      "row index" instead of the column index
        //      LDY EN.MX(X)    ; row index
        const entity_x = game_state.entity_playfield_position[entity][0];
        //      LDA EN.SPT(Y)
        //      STA TEMP1    ; column index
        const column_index = column_indices[@intCast(entity_x)];
        //      ADD #1
        //      STA EN.SPT(Y)    ; inc pointer
        column_indices[@intCast(entity_x)] += 1;
        // ;        update matrix
        //      TYA
        //      ASL        ;  multiply by 10=EN.MAX
        //      STA TEMP3
        //      ASLS 2
        //      ADD TEMP3
        //      ADD TEMP1
        //      TAY
        //      TXA
        //      STA EN.SOR(Y)
        sorted_entities[@intCast(entity_x * MAX_NUMBER_OF_ENTITIES + column_index)] = entity;

        //     INXS 2
        //     CPX EN.NUM
        //     PLEND
    }
    //     RTS

    //@    LDY #0
    //@    STY TEMP1
    //@    STY TEMP2
    var temp2: isize = 0;
    var motion_objects_cursor: usize = 0;
    //@    BEGIN
    for (0..PLAYFIELD_WIDTH) |x| {
        //@10$:
        while (true) {
            //@     LDX TEMP1
            //@     DEC EN.SPT(X)
            column_indices[x] -= 1;

            //@     IFPL
            if (column_indices[x] >= 0) {
                //@      LDA EN.SPT(X)
                //@      ADD TEMP2
                //@      TAX
                //@      LDA EN.SOR(X)
                //@      TAX
                const entity = sorted_entities[
                    @intCast(column_indices[x] + temp2)
                ];
                //@      JSR EN.PMV
                draw_motion_objects(
                    entity,
                    game_state,
                    &motion_objects_cursor,
                );

                //@      JMP 10$
                //@     ENDIF
            } else {
                break;
            }
        }

        //@    INC TEMP1
        //NOTE handled in for loop

        //@    ADAI EN.MAX TEMP2
        temp2 += MAX_NUMBER_OF_ENTITIES;

        //@    LDA TEMP1
        //@    CMP #16
        //@    EQEND
    }

    //@    LDA MT.CUR
    //@    EOR #1
    //@    STA MT.CUR

    //@    RTS
}

// ;-----------------------------
// ;  move pictures
// EN.PMV:
fn draw_motion_objects(
    entity: usize,
    game_state: *GameState,
    motion_objects_cursor: *usize,
) void {
    //NOTE: The implementation here will deviate from the original code in that we will actually have
    // a struct of picture objects that we will modify.  In addition, I've gotten rid of the double buffer
    // which is unncessary here.
    for (0..MOTION_OBJECTS_PER_ENTITY) |i| {
        const motion_object =
            &game_state.motion_objects[motion_objects_cursor.*];
        const effective_position =
            game_state.entity_position[entity] +
            game_state.entity_motion_object_offsets[entity][i];

        motion_object.* = .{
            .picture_number = game_state.entity_picture[entity][i],
            .position = effective_position,
            .flags = @bitCast(game_state.entity_priority[entity][i]),
        };
        motion_objects_cursor.* += 1;
    }
}
//@ ;---------------------
//@ ;  plunger pictures
//@ EN.PLP:
fn fill_plunger_pictures(entity: usize, game_state: *GameState) void {
    //@ 50$:    .BYTE 080,084,088,084
    const PLUNGER_PICTURE_NUMBERS = [_]isize{ 0x80, 0x84, 0x88, 0x84 };
    //@     LDA FRAME
    //@     AND #^B00110000
    //@     LSRS 4
    //@     TAY
    const picture_index: usize = @intCast((game_state.frame & 0b00110000) >> 4);
    //@     LDA 50$(Y)
    const picture_number = PLUNGER_PICTURE_NUMBERS[picture_index];
    //@     JSR EN.PCF
    fill_entity_pictures(picture_number, entity, game_state);
    //@     RTS
}

//@ ;----------------------
//@ ;  fill pictures with data
//@ EN.PCF:
fn fill_entity_pictures(
    picture_number: isize,
    entity: usize,
    game_state: *GameState,
) void {
    if (picture_number != 0) {
        //@    STA EN.PC1(X)
        //@    BEQ 10$
        //@    ADD #1
        //@    STA EN.PC2(X)
        //@    ADC #1
        //@    STA EN.PC3(X)
        //@    ADC #1
        //@    STA EN.PC4(X)
        //@    RTS
        inline for (
            &game_state.entity_picture[entity],
            0..,
        ) |*p, i| {
            p.* = picture_number + i;
        }
    } else {
        //@10$:
        //@    STA EN.PC2(X)
        //@    STA EN.PC3(X)
        //@    STA EN.PC4(X)
        //@    RTS
        inline for (
            &game_state.entity_picture[entity],
        ) |*p| {
            p.* = 0;
        }
    }
}

//MN.SNI
fn initialize_sounds() void {
    //TODO:
}

//AL.BER
fn erase_board(game_state: *GameState) void {
    //@TRAI 8 TEMP2
    //@TRAI 0B0 AL.X
    //@TRAI 02E AL.Y
    //@BEGIN
    //@ LDA #0B*6+3
    //@ JSR SC.ERA
    //@ ADAI 08 AL.Y
    //@ DEC TEMP2
    //@EQEND

    var position = V2{ 0xB0, 0x2E };
    for (0..8) |_| {
        screen_erase(
            position,
            0xB * 6 + 3,
            game_state,
        );
        position[1] += 0x8;
    }
}

//This MS.TAB is a list of pointers, but that seems kind of unncessary.
//This will contain all of the data that those pointers pointed to, flattened out
const MESSAGE_DATA = [_][]const u8{
    //@ maze titles
    //@ get the gems bentley bear
    //MC.M00:
    &.{
        0xB1, 0x28,
        0x2,  0x1B,
        0x52, 0x3,
        0x1D, 0x2,
        0x1E, 0x3,
        0x1F,
    },

    //@ extra life
    //MC.M01:
    &.{
        0xB1,
        0x30,
        0x2D,
        0xA1,
        0x0,
        0x2E,
    },

    //@ tree wave
    //MC.M02:
    &.{
        0x0B1,
        0x30,
        0x30,
        0x31,
    },

    //@ berthildas castle
    //MC.M03:
    &.{
        0xB1,
        0x30,
        0x33,
        0x2,
        0x34,
    },

    //@ pyramid
    //MC.M04:
    &.{
        0xB1,
        0x2E,
        0x3A,
    },

    //@ hidden spiral
    //MC.M05:
    &.{
        0x0B1,
        0x30,
        0x4F,
        0x0,
        0x63,
    },

    //@ hidden ramp
    //MC.M06:
    &.{
        0xB1,
        0x30,
        0x4F,
        0xA8,
    },

    //@ berthildas fortress
    //MC.M07:
    &.{
        0x0B1,
        0x30,
        0x33,
        0x0,
        0x3F,
    },

    //@ impossible staircase
    //MC.M08:
    &.{
        0x0B1,
        0x30,
        0x41,
        0x0,
        0x42,
    },

    //@ maze 1
    //MC.M09:
    &.{
        0xB1,
        0x30,
        0x44,
    },

    //@ cross maze
    //MC.M0A:
    &.{
        0xB1,
        0x30,
        0x46,
        0x47,
    },

    //@ berthildas dungeon
    //MC.M0B:
    &.{
        0xB1,
        0x30,
        0x33,
        0x0,
        0x48,
    },

    //@ crossroads
    //MC.M0C:
    &.{
        0xB1,
        0x30,
        0x4A,
    },

    //@ nasty tree
    //MC.M0D:
    &.{
        0xB1,
        0x30,
        0x36,
        0x30,
    },

    //@  the end
    //MC.M0E:
    &.{
        0xB1,
        0x30,
        0x52,
        0x0A0,
    },

    //@ berthildas palace
    //MC.M0F:
    &.{
        0xB1,
        0x30,
        0x33,
        0x0,
        0x4E,
    },

    //@ credits
    //MC.M10:
    &.{
        0xC0,
        0x50,
        0x12,
    },

    //@ get ready
    //MC.M11:
    &.{
        0x60, 0x80, 0xE, 0xF,
    },
    //@ ;  option screen
    //@ MC.M12:
    &.{
        0x30, 0x30,
        7,    0x13,
        0x81, 0,
        0,    0,
        0xB,  0x8B,
        0,    0,
        0x72, 0x8C,
        0x8B, 0,
        0,    0x73,
        0x8C, 0x8B,
        0,    0,
        0x13, 0x49,
        0,    0,
        0x4D, 0xA1,
        0,    0,
        0x2D, 0xA1,
        0,    0,
        0x65, 0x81,
        0,    0,
        0x84,
    },

    //@ ;  insert coin
    //@ MC.M13:
    &.{
        0xB1, 0x48, 0, 0xA, 0xB,
    },

    //@ ;  game over
    //@ MC.M14:
    &.{
        0x60, 0x80, 0x13, 0xD,
    },

    //@ ;  player 1
    //@ MC.M15:
    &.{
        0x60, 0x88, 0x14, 0x15,
    },

    //@ ;  player 2
    //@ MC.M16:
    &.{
        0x60, 0x88, 0x14, 0x16,
    },

    //@ ;  checksum for rom at pc etc.
    //@ MC.M17:
    &.{
        0x20, 0x70,
        0x2A, 0x20,
        0x91, 0,
        0x2A, 0x20,
        0x92, 0,
        0x2A, 0x20,
        0x93, 0,
        0x2A, 0x20,
        0x94, 0,
        0x2A, 0x20,
        0x95,
    },
    //@ ;  use secret warp number 1
    //@ ;  jump at back corner of maze 1 level 1
    //@ MC.M18:
    &.{
        0x40, 0xC0,
        0x96, 0x61,
        0x97, 0x15,
        0,    0x8A,
        0x98, 0xA2,
        0x99, 0x5B,
        5,    0x47,
        0x15, 5,
        0x2B, 0x15,
    },
    //@ ;  atract mode messages
    //@ ;  crystal castles  copyright atari 1983
    //@ MC.M19:
    &.{
        0xB1, 0x2C,
        2,    0x18,
        2,    0x19,
        0,    0,
        0x21, 0,
        0x22, 0,
        0x23, 1,
        0x24,
    },
    //@     ;  warp activated, high score
    //@ MC.M1A:
    &.{
        0xB6, 0x28,
        0,    0x1C,
    },

    //@ ;  warp instructions
    //@ MC.M1B:
    &.{
        0xB1, 0x38,
        0x5D, 0,
        0x37, 0xA4,
        0,    0x64,
        0x8A, 0,
        0x60, 0,
        0x83, 0x61,
        0x83,
    },
    //@ ;  i give up:  you win
    //@ MC.M1C:
    &.{
        0x20, 0x60,
        0x9E, 0,
        0,    0x50,
        0x9F, 0,
        0,    0xA1,
        0x57, 0,
        0,    0x7A,
        0x57,
    },

    //@ ;  crystal castles hall of fame
    //@ MC.M1D:
    &.{
        0x30, 0x30,
        0x18, 0x19,
        0x5A, 0x5B,
        0x5C,
    },
    //@ ; enter your initials
    //@ MC.M1E:
    &.{
        0x40, 0xF0,
        0x5D, 0x5E,
        0x5F,
    },
    //@;  level
    //@ MC.M1F:
    &.{
        0xB1, 0x58,
        2,    0x2B,
    },

    //@ ;  you got the last gem
    //@ ;  bonus 1000
    //@ MC.M20:
    &.{
        0x40, 0x80,
        0x50, 0x51,
        0x52, 0x53,
        0x54, 0x6,
        0x57,
    },

    //@ ;  they got the last gem
    //@ ;  no bonus
    //@ MC.M21:
    &.{
        0x40, 0x80,
        0x55, 0x51,
        0x52, 0x53,
        0x54, 0x6,
        0x56, 0x57,
    },

    //@ ;  accounting messages
    //@ MC.M22:
    &.{
        0x20, 0x20,
        5,    0x70,
        0,    0,
        0,    0x71,
        0x74, 0,
        0x72, 0x74,
        0,    0x73,
        0x74, 0,
        0x75, 0x78,
        0x74, 0,
        0x15, 0x14,
        0x76, 0,
        0x16, 0x14,
        0x76, 0,
        0x75, 0x12,
        0x77, 0,
        0x79, 0x13,
        0x7A, 0,
        0x7B,
    },

    //@ ;  explanation board
    //@ MC.M23:
    &.{
        0x20, 0x20,
        0x8,  0x66,
        0,    0,
        0,    0x3,
        0x67, 0,
        0,    3,
        0x68, 0xA3,
        3,    0xA4,
        0x50, 0x69,
        0,    0,
        0,    0x6A,
        0x54, 0x45,
        0,    0x6B,
        0x62, 0,
        0,    0x6C,
        0x6B, 0,
        0x6D, 0x54,
        0x83, 0x54,
        0,    0,
        3,    0x6E,
        0x7A, 0xA4,
        3,    0x52,
        0x6F, 0,
        0,    5,
        0x8A, 0x3C,
        0x83, 0x43,
    },
};

//MS.DRW
fn draw_message(message_number: usize, game_state: *GameState) void {
    //@ASL
    //@TAX

    //@.IF NE,CG.ST
    //@TR16AM MS.TAB(X) MS.PTR
    //@INXS 2
    //@TR16AM MS.TAB(X) MS.LEN

    //@.ENDC

    //@SB16AM MS.LEN MS.PTR
    const msg = MESSAGE_DATA[message_number];

    //@TRAI 07F AL.COL
    const letter_color_value = 0x7F;
    //@LDY #1
    //@TRAM @MS.PTR(Y) AL.Y
    //@DEY
    //@TRAM @MS.PTR(Y) AL.X
    var position = V2{ msg[0], msg[1] };
    //@STA AL.LMG        ;  left margin
    const left_margin = position[0];

    //@SBAI 2 MS.LEN

    //@BEGIN            ;  loop through words
    for (2..msg.len) |i| {
        //@ LDY #2
        //@ LDA @MS.PTR(Y)        ;  word number
        var word_number: isize = msg[i];
        //@ CMP #0A            ;  if not CR-directive
        //@ IFCS
        if (u8gte(word_number, 0xA)) {
            //@  JSR WR.DRW
            draw_word(
                word_number,
                &position,
                letter_color_value,
                game_state,
            );
        }
        //@ ELSE
        else {
            //@  CMP #6
            //@  IFPL        ;  6,7,8 map to 8,12.,16.
            if (word_number >= 6) {
                //@   ASLS 2
                //@   SUB #10
                word_number = word_number * 4 - 0x10;
                //@  ENDIF
            }
            //@  ASL
            //@  STA TEMP1
            //@  ASL
            //@  ADD TEMP1
            //@  ADD AL.LMG    ; 0B1+6*CRdirective
            word_number = (word_number * 4) + (word_number * 2) + left_margin;
            //@  STA AL.X    ; hor position
            //@  ADAI 08 AL.Y  ; vert position
            position = .{ word_number, position[1] + 8 };
            //@ ENDIF
        }
        //@INC16 MS.PTR
        //@DEC MS.LEN
        //@EQEND
    }
}

//WR.DRW
fn draw_word(
    word_number: isize,
    position: *V2,
    color_value: u8,
    game_state: *GameState,
) void {
    //@SUB #0A
    const word_index: usize = @intCast(word_number - 0xA);
    //@ASL                ;  up to 246 words
    //@STA TEMP1
    //@IFCC
    //@ TRAI 0 1+TEMP1
    //@ELSE
    //@ TRAI 1 1+TEMP1
    //@ENDIF            ;  TEMP1,1+TEMP1  cointain table offset
    //@TR16AI WR.TAB WR.TPT
    //@AD16AM WR.TPT TEMP1    ; points to table entry of word
    //@LDY #0
    //@TRAM @WR.TPT(Y) WR.PTR
    //@INY
    //@TRAM @WR.TPT(Y) WR.PTR+1
    //@INY
    //@TRAM @WR.TPT(Y) WR.LEN    ;  next word
    //@INY
    //@TRAM @WR.TPT(Y) WR.LEN+1
    //@SB16AM WR.LEN WR.PTR
    const word = WORDS[word_index];
    const color = color_value_to_color(color_value);
    //@BEGIN
    for (word) |char| {
        //@ LDY #0
        //@ TRAM @WR.PTR(Y) AL.DIG
        //@ JSR AL.DRW
        add_draw_character_command(
            char,
            color,
            position.*,
            game_state,
        );

        //@ LDA AL.X
        //@ ADD #6        ;  works only for 5x5
        //@ STA AL.X
        position.*[0] += 6;

        //@INC16 WR.PTR
        //@DEC WR.LEN
        //@EQEND
    }
    //@ADAI 6 AL.X
    position.*[0] += 6;
}

//RS.INI
fn initialize_high_scores() void {
    //TODO
}

//WV.INI
fn initialize_wave_data(game_state: *GameState) void {
    //NOTE: all handled in initialization of GameState object
    {
        //@LDA #0
        //@STA WV.XCO
        //@STA WV.XCD
        //@STA WV.YCO
        //@STA WV.YCD
        //@STA WV.EOG

        //@STA ST.TIM    ;  init game time
        //@STA 1+ST.TIM

        //@STA WV.SCF    ;  don't scroll yet
    }

    {
        //@LDA #7
        //@LDX EEEXTR
        //TODO make configurable
        const EXTRA_LIVES_OPTIONS = 0;
        //@IFNE
        //@ LDA #099
        //@ENDIF
        //@STA SC.NEL    ;  next extra life at 70000

        if (EXTRA_LIVES_OPTIONS != 0) {
            game_state.next_extra_life = 0x99;
        } else {
            game_state.next_extra_life = 7;
        }
    }

    //@JSR WV.CMP
    compute_wave_parameters(game_state);

    //@JSR MT.INI        ; init motion objects
    //NOTE we don't need this since we don't need to do double buffering
}

//@;-------------------------------------------
//@;  compute wave parameters, given game_state.wave_xco and game_state.wave_yco
fn compute_wave_parameters(game_state: *GameState) void {

    //@    JSR DF.UPD
    update_current_wave_and_difficulty(game_state);

    //already done in initialize_castle()
    {
        //@;  compute WV.OFF,  this assumes WV.SIZ=400
        //@    TRAI 0 WV.OFF
        //@    LDA WV.NUM
        //@    ASLS 2
        //@    STA WV.OFF+1
    }

    //@    JSR CL.UPD
    update_colors(game_state);

    //TODO.  We may not need to implement WV.MNM if its always dependent on WV.NUM
    {
        //@;  update message pointer
        //@    LDA WV.NUM
        //@    STA WV.MNM
        //@    TRAI 0FF WV.MFL
    }
}

//DF.UPD
fn update_current_wave_and_difficulty(game_state: *GameState) void {
    const WAVE_NUMBER_TABLE = [_]isize{
        0x0,  0x2,  0x9,  0xC3,
        0x46, 0x71, 0xC,  0xC7,
        0x06, 0xD,  0x45, 0xCB,
        0x4,  0xA,  0x6,  0x4F,
        0x41, 0x4D, 0x3C, 0xC3,
        0xA,  0x2,  0x32, 0x3F,
        0x1,  0x4,  0x75, 0xFB,
        0x1,  0x3A, 0x6,  0xF7,
        0x8,  0x7D, 0x5,  0xCB,
        0xE,
    };
    //@    LDA WV.XCO
    //@ASLS 2
    //@ADD WV.YCO    ;  wave number index
    //@TAX
    const wave_number_table_index = game_state.wave_xco * 4 + game_state.wave_yco;
    //@LDA WV.TAB(X)
    //@TAY
    //@AND #0F
    //@STA WV.NUM
    game_state.wave_current = WAVE_NUMBER_TABLE[@intCast(wave_number_table_index)] & 0xF;

    //NOTE: handled in GameState initialization
    //@    ;  compute regions
    //@    LDA #0
    //@    STA CT.HR1
    //@    STA CT.HR2
    //@    STA CT.HR3
    game_state.castle_region_1 = 0;
    game_state.castle_region_2 = 0;
    game_state.castle_region_3 = 0;

    //@    LDX #0FF

    //@    TYA
    //@    AND #30
    //@    IFEQ        ;  if both reg 1 and 2 off
    //@             ; turn off only one of them
    if (wave_number_table_index & 0x30 == 0) {
        //@     LDA RANDOM
        const r: i32 = if (comptime VALIDATE_AGAINST_ARCADE)
            0
        else
            @bitCast(toolbox.random32(&game_state.rng_state));
        //@     IFMI
        //@      STX CT.HR1
        //@     ELSE
        //@      STX CT.HR2
        //@     ENDIF
        if (r < 0) {
            game_state.castle_region_1 = -1;
        } else {
            game_state.castle_region_2 = -1;
        }
        //@    ELSE
        //@     TYA
        //@     AND #10
    } else if (wave_number_table_index & 0x10 == 0) {

        //@     IFEQ
        //@      STX CT.HR1
        //@     ENDIF

        game_state.castle_region_1 = -1;
        //@     TYA
        //@     AND #20
        //@     IFEQ
    } else if (wave_number_table_index & 0x20 == 0) {
        //@      STX CT.HR2
        game_state.castle_region_2 = -1;
        //@     ENDIF
        //@    ENDIF

    }
    //@    TYA
    //@    AND #0C0
    //@    IFEQ
    if (wave_number_table_index & 0xC0 == 0) {
        //@     STX CT.HR3
        game_state.castle_region_3 = -1;
        //@    ELSE
        //@     CMP #0C0
        //@     IFEQ
    } else if (wave_number_table_index == 0xC0) {
        //@      LDA RANDOM
        //@      AND #1F    ;  0 to 31
        //@     STA CT.HR3
        game_state.castle_region_3 = @intCast(toolbox.random32(&game_state.rng_state) & 0x1F);
    } else {
        //@     ELSE
        //@      LDA #0
        //@     STA CT.HR3
        game_state.castle_region_3 = 0;
        //@     ENDIF
    }
    //@    ENDIF

    //@;  compute difficulties
    //@    LDA WV.XCO
    //@    CMP #04
    //@    IFCS
    //@      LDA #03
    //@    ENDIF
    //@    ASLS 2
    //@    ADD WV.YCO
    //@    STA WV.DF1    ;  short term difficulty
    game_state.wave_short_term_difficulty =
        @min(3, game_state.wave_xco & 0xFF) * 4 +
        game_state.wave_yco;

    //@    LDA WV.XCO
    //@    CMP #09        ;  max out at level 10
    //@    IFCS
    //@     LDA #09
    //@    ENDIF
    //@    STA WV.DF2    ;  long term difficulty
    game_state.wave_long_term_difficulty = @min(9, game_state.wave_xco & 0xFF);

    //@    TAY
    //@;  difficulty offset

    //@    LDA EEDIFF
    //TODO make configurable
    const CONFIGURED_DIFFICULTY_OFFSET = 0;

    //@    AND #03
    var difficulty_offset: isize = CONFIGURED_DIFFICULTY_OFFSET & 3;

    //@    CMP #3
    //@    IFEQ
    //@     LDA #0FF
    //@    ENDIF
    if (difficulty_offset == 3) {
        difficulty_offset = -1;
    }

    //@    CPY #5
    //@    IFCS
    //@     LDA #0        ;  all are equal starting at level 6
    //@    ENDIF
    if (u8gte(game_state.wave_xco, 5)) {
        difficulty_offset = 0;
    }

    //@    STA WV.DFO
    game_state.wave_difficulty_offset = difficulty_offset;
}
//CL.UPD
fn update_colors(game_state: *GameState) void {
    //TODO
    _ = game_state;
}

//CT.INI
fn initialize_city(game_state: *GameState) void {
    const wave_data = &game_state.current_wave_data;

    //should be equvalent to WV.OFF
    const wave_data_offset: usize = @intCast(game_state.wave_current * WAVE_DATA_SIZE);
    @memcpy(
        wave_data,
        LEVEL_DATA[wave_data_offset .. wave_data_offset + WAVE_DATA_SIZE],
    );

    initialize_castle_row(game_state);

    row_loop: while (true) {
        //CT.RGR
        //traverse row
        {
            initialize_block(game_state);
            block_loop: while (true) {
                initialize_block_2(game_state);
                //LDY #0
                //@LDA @CT.A2L(Y)
                //@AND #3

                //On the first iteration of this loop, the region is the 0x1FBth byte
                //of the current wave data
                //For wave 0, this is 4&3 = 0
                const data = wave_data[game_state.castle_a2l];
                const region = data & 3;
                if (region > 0) {
                    const height_offset_of_region: i8 = @intCast(switch (region) {
                        1 => game_state.castle_region_1,
                        2 => game_state.castle_region_2,
                        3 => game_state.castle_region_3,
                        else => unreachable,
                    });
                    if (height_offset_of_region < 0) {
                        //@ LDA @CT.A2L(Y)
                        //@ AND #^B11101111
                        //@ STA @CT.A2L(Y)    ;  no gems when height=0
                        game_state.current_wave_data[game_state.castle_a2l] &=
                            0b11101111;
                        //@LDA #0
                        //@STA @CT.ADL(Y)
                        game_state.current_wave_data[game_state.castle_adl] = 0;
                    } else {
                        //@ADD @CT.ADL(Y)
                        //@STA @CT.ADL(Y)
                        game_state.current_wave_data[game_state.castle_adl] +%=
                            @as(u8, @bitCast(height_offset_of_region));
                    }
                }

                game_state.castle_adl += 1;
                game_state.castle_block_count -= 1;

                if (game_state.castle_block_count >= 0) {
                    advance_block(game_state);
                } else {
                    game_state.castle_adl += 2;
                    break :block_loop;
                }
            }
        }
        game_state.castle_row_count -= 1;
        if (game_state.castle_row_count < 0) {
            break :row_loop;
        }
        advance_castle_row(game_state);
    }
    if (game_state.wave_xco == 0 and game_state.wave_yco == 0) {
        const NUMBER_OF_INITIALS = 5;
        for (0..NUMBER_OF_INITIALS) |initial| {
            add_high_score_initial_to_castle(initial, game_state);
        }
    }

    //TODO:
    //@    if (game_state.warp_level > 0 and !game_state.attract_mode) {
    //@        //Putting in tunnel for warp, Don't care about this right now
    //@    }
    //@}
}
fn add_high_score_initial_to_castle(initial_index: usize, game_state: *GameState) void {
    //@CT.HSS: .WORD SC.HI1+HFSIZ-1,SC.HI2+HFSIZ-1,SC.HI3+HFSIZ-1
    //@    .WORD SC.HI2+HFSIZ-1,SC.HI3+HFSIZ-1
    const initials = [_]toolbox.Rune{
        game_state.scoreboard.entries[0].name.rune_at(0).rune,
        game_state.scoreboard.entries[0].name.rune_at(1).rune,
        game_state.scoreboard.entries[0].name.rune_at(2).rune,
        game_state.scoreboard.entries[0].name.rune_at(1).rune,
        game_state.scoreboard.entries[0].name.rune_at(2).rune,
    };
    //@;  get initial
    //@LDA TEMP4
    //@ASL
    //@TAX
    //@LDA PL.UP
    //@IFEQ        ;  player 1
    //@ LDA CT.HSS(X)
    //@ STA TEMP1
    //@ LDA 1+CT.HSS(X)
    //@ELSE        ;  player 2
    //@ LDA CT.HS2(X)
    //@ STA TEMP1
    //@ LDA 1+CT.HS2(X)
    //@ENDIF

    //@STA 1+TEMP1
    //NOTE: for above, ignore player 2 code

    //@CT.RMS: .WORD CTRAM+<6*16>+2,CTRAM+<6*16>+7,CTRAM+<6*16>+0C
    //@    .WORD CTRAM+<0B*16>+2,CTRAM+<10*16>+2
    const castle_rms = [_]usize{
        (0x6 * 0x16) + 2, (0x6 * 0x16) + 7,  (0x6 * 0x16) + 0xC,
        (0xB * 0x16) + 2, (0x10 * 0x16) + 2,
    };
    //@TR16AM CT.RMS(X) CT.ADL
    game_state.castle_adl = castle_rms[initial_index];

    //@LDY #0
    //@LDA @TEMP1(Y)        ;  now have initial
    //@SUB #4A

    //@STA TEMP1    ;  mult by 5 so (A) points to sym
    //@ASLS 2
    //@ADD TEMP1
    //@STA TEMP1
    var letter_bitmap_array_cursor = (initials[initial_index] - 'A') * 5;

    //@TRAI 4 TEMP3
    //@BEGIN
    for (0..CHARACTER_BITMAP_HEIGHT) |_| {

        //@LDX TEMP1
        //@LDA AL.55L(X)
        //@STA TEMP5
        var character_row = LETTER_BITMAPS[letter_bitmap_array_cursor];

        //@LDX #4
        //@BEGIN
        for (0..CHARACTER_BITMAP_WIDTH) |_| {
            //@ASL TEMP5
            //@IFCS
            if (character_row & 0x80 != 0) {
                //@ LDA @CT.ADL(Y)
                //@ ADD #0A
                //@ STA @CT.ADL(Y)
                game_state.current_wave_data[game_state.castle_adl] += 0xA;
                //@ JSR BL.IN2
                initialize_block_2(game_state);
                //@ LDA @CT.A2L(Y)
                //@ AND #^B11111011    ;  Accessibility=0
                //@ STA @CT.A2L(Y)
                game_state.current_wave_data[game_state.castle_a2l] &=
                    @as(u8, 0b11111011);

                //@ENDIF
            }
            character_row <<= 1;
            //@SB16AI CT.ADL 16
            game_state.castle_adl -= 0x16;
            //@DEX
            //@MIEND
        }

        //@AD16AI CT.ADL 16*5+1
        game_state.castle_adl += 0x16 * 5 + 1;

        //@INC TEMP1
        letter_bitmap_array_cursor += 1;
        //@DEC TEMP3
        //@MIEND
    }
}
//CR.INI
fn initialize_castle_row(game_state: *GameState) void {
    //TR16AI CTRAM+CT.YDM+4 CT.ADL
    game_state.castle_adl = 0 + 0x13 + 0x4; //0x17
    //TRAI CT.HST CR.HST
    //TRAI CT.VST CR.VST
    game_state.castle_row_position = .{ 0x5C, 0x86 };

    //@TRAI CT.XDM CT.CNT
    game_state.castle_row_count = 0x13;
}
//BL.INI
fn initialize_block(game_state: *GameState) void {
    //TRAM CR.HST BL.HST
    //TRAM CR.VST BL.VST
    game_state.castle_block_position = game_state.castle_row_position;

    //TRAI CT.YDM CR.CNT
    game_state.castle_block_count = 0x13;

    //.INCLUDE CATOUT.MAC
    check_and_display_atari_easter_egg();
}
//BL.IN2
fn initialize_block_2(game_state: *GameState) void {
    //@LDY #0
    //@TRAM @CT.ADL(Y) BL.HEI
    //When this is first called after initialize_city_row()
    //this gets the 0x17th byte of the current wave data.
    //For wave 0, this value is 4.
    game_state.castle_block_height = game_state.current_wave_data[game_state.castle_adl];

    //@TR16AM CT.ADL,CT.A2L
    //@AD16AI CT.A2L,16*16
    game_state.castle_a2l = game_state.castle_adl + 0x16 * 0x16; //offset of 0x1E4;
    //The above line results in  game_state.castle_a2l having the value 0x1FB in the
    //first iteration of this loop
}
//@BL.ADV:
//@;  advance to next block
fn advance_block(game_state: *GameState) void {
    //@LDA BL.HST
    //@ADD #CT.YSZ
    //@STA BL.HST
    //@INC BL.VST
    //@INC BL.VST
    game_state.castle_block_position += .{ 8, 2 };
}
//CR.ADV
fn advance_castle_row(game_state: *GameState) void {
    //@LDA CR.HST
    //@SUB #CT.XSZ
    //@STA CR.HST
    //@LDA CR.VST
    //@ADD #CT.XSZ
    //@STA CR.VST
    game_state.castle_row_position += .{ -4, 4 };
}

//CT.DRW
fn draw_city(game_state: *GameState) void {
    //@;  traverse through rows
    //@TR16AI CTRAM CT.ACL
    game_state.castle_acl = 0;
    //@TR16AI CTRAM+1 CT.ARL
    game_state.castle_arl = 1;
    //@TR16AI CTRAM+2 CT.AFL
    game_state.castle_afl = 2;
    //@TR16AI CTRAM+CT.YDM+3 CT.ALL
    game_state.castle_all = 0 + 0x13 + 0x3; //0x16

    initialize_castle_row(game_state);

    while (true) {
        draw_castle_row(game_state);
        game_state.castle_row_count -= 1;
        if (game_state.castle_row_count < 0) {
            break;
        }
        advance_castle_row(game_state);
    }
}

//CR.DRW
fn draw_castle_row(game_state: *GameState) void {
    initialize_block(game_state);
    const wave_data = &game_state.current_wave_data;

    while (true) {
        initialize_block_2(game_state);
        {
            //@;   compute if necessary to draw face1,face2
            //@TR16AM CT.ADL CT.ADB    ; square before ADL X dir
            //@INC16 CT.ADB
            game_state.castle_adb = game_state.castle_adl + 1;
            //@TRAM @CT.ADB(Y) TEMP1
            //NOTE: Y is set to 0 in initialize_block_2();
            const next_block_height = wave_data[game_state.castle_adb];

            //@LDA BL.HEI
            //@SUB TEMP1
            const height_difference = game_state.castle_block_height - next_block_height;
            if (height_difference < 0) {
                //@ LDA BL.VST
                //@ SUB BL.HEI
                //@ STA BL.V1S
                game_state.castle_block_v1s = game_state.castle_block_position[1] -
                    game_state.castle_block_height;
                //@ TRAI 0 BL.V1N
                game_state.castle_block_v1n = 0;
            } else {
                //@ STA BL.V1N
                game_state.castle_block_v1n = height_difference;

                //@ LDA BL.VST
                //@ SUB TEMP1
                //@ STA BL.V1S
                game_state.castle_block_v1s = game_state.castle_block_position[1] -
                    next_block_height;
            }
        }
        {
            //TR16AM CT.ADL CT.ADB    ; square before ADL Y dir
            //@AD16AI CT.ADB 16
            game_state.castle_adb = game_state.castle_adl + 0x16;

            //@TRAM @CT.ADB(Y) TEMP1
            //NOTE: Y is set to 0 in initialize_block_2();
            const next_block_height = wave_data[game_state.castle_adb];

            //@LDA BL.HEI
            //@SUB TEMP1
            const height_difference = game_state.castle_block_height - next_block_height;
            if (height_difference < 0) {
                //@ LDA BL.VST
                //@ SUB BL.HEI
                //@ STA BL.V2S
                game_state.castle_block_v2s = game_state.castle_block_position[1] -
                    game_state.castle_block_height;
                //@ TRAI 0 BL.V2N
                game_state.castle_block_v2n = 0;
            } else {
                //@ STA BL.V2N
                game_state.castle_block_v2n = height_difference;
                //@ LDA BL.VST
                //@ SUB TEMP1
                //@ STA BL.V2S
                game_state.castle_block_v2s = game_state.castle_block_position[1] -
                    next_block_height;
            }
        }
        //;  priority
        //@LDY #0
        //@LDA @CT.A2L(Y)
        //@JSR CL.PR
        set_bitmap_values_of_faces(
            wave_data[game_state.castle_a2l],
            game_state,
        );
        //@; accessibility
        //@LDA @CT.A2L(Y)
        //@AND #4
        //@IFNE
        //@ LDA FC.BV3
        //@ELSE
        //@ LDA FC.BVC
        //@ENDIF
        //@STA CT.BV3
        game_state.face3_color_value_hidden_or_not = if ((wave_data[game_state.castle_a2l] & 0x4) != 0)
            game_state.face_color_values[0] //yes, this is FC.BV3
        else
            game_state.face_color_values[4]; //this is FC.BVC

        //;  tunnel
        //@LDA @CT.A2L(Y)
        //@AND #20
        //@STA CT.TUN
        game_state.has_tunnel = wave_data[game_state.castle_a2l] & 0x20 != 0;

        //@JSR BL.EDT
        determine_edge_switches(game_state);

        if (game_state.castle_block_height != 0) {
            draw_block(game_state);
        }

        //@    INC16 CT.ADL
        game_state.castle_adl += 1;

        //@    DEC CR.CNT
        game_state.castle_block_count -= 1;
        if (game_state.castle_block_count < 0) {
            break;
        }
        advance_block(game_state);
    }
    //@; increment ADL,ACL,ARL,AFL,ALL twice

    //@    INC16 CT.ADL
    //@    INC16 CT.ADL
    game_state.castle_adl += 2;
    //@    INC16 CT.ACL
    //@    INC16 CT.ACL
    game_state.castle_acl += 2;
    //@    INC16 CT.ARL
    //@    INC16 CT.ARL
    game_state.castle_arl += 2;
    //@    INC16 CT.AFL
    //@    INC16 CT.AFL
    game_state.castle_afl += 2;
    //@    INC16 CT.ALL
    //@    INC16 CT.ALL
    game_state.castle_all += 2;
}
//BL.DRW
fn draw_block(game_state: *GameState) void {
    //@ TRAM BL.HST FC.HST
    //@TRAM BL.VST FC.VST
    game_state.face_position = game_state.castle_block_position;

    //@TRAM BL.V1S FC.V1S
    //@TRAM BL.V1N FC.V1N
    game_state.face_v1s = game_state.castle_block_v1s;
    game_state.face_v1n = game_state.castle_block_v1n;
    //@JSR FACE1
    draw_face1(game_state);

    //@TRAM BL.V2S FC.V2S
    //@TRAM BL.V2N FC.V2N
    game_state.face_v2s = game_state.castle_block_v2s;
    game_state.face_v2n = game_state.castle_block_v2n;
    //@JSR FACE2
    draw_face2(game_state);

    //@LDA FC.VST
    //@SUB BL.HEI
    //@STA FC.VST
    game_state.face_position[1] -= game_state.castle_block_height;
    //@JSR FACE3
    draw_face3(game_state);

    //@LDA CT.TUN
    //@IFNE
    //@ JSR FC.TUN
    //@ENDIF
    if (game_state.has_tunnel) {
        draw_tunnel(game_state);
    }
}

//GM.AT
fn update_attract_mode_state(game_state: *GameState) void {

    //@    JSR MN.FRA
    frame_handler(game_state);
    //@    TRAI 0 ATRACT        ; atract mode is on
    game_state.is_in_attract_mode = true;

    //TODO: handle credits
    //@    LDA $$CRDT
    //@    IFNE
    //@     JSR MN.SBD        ;  start button decode
    //@    ENDIF

    //@    TRAI 048 AL.Y
    //@    TRAI 0B1 AL.X
    var word_position = V2{ 0xB1, 0x48 };

    //@    LDA FRAME
    //@    AND #03F
    //@    IFEQ
    if (game_state.frame & 0x3F == 0) {
        //@     LDA #11.*6
        //@     JSR SC.ERA
        screen_erase(
            word_position,
            0x42,
            game_state,
        );

        //TODO: handle different coin states
        //@I don't think we will have something called "free play?"
        //@     LDA $CMODE
        //@     AND #03
        //@     IFEQ
        //@      TRAI 2 $$CRDT
        //@      LDA #59        ;  free play
        //@     ELSE
        //@     LDA $$CRDT
        //@     IFEQ
        //@      LDA #0A        ;  insert coin
        //@     ELSE
        //@      LDA #10        ;  press start
        //@     ENDIF
        //@     ENDIF
        //@     JSR WR.DRW
        draw_word(
            0xA,
            &word_position,
            0x7F,
            game_state,
        );
        //@    ELSE
        //@    CMP #20
        //@    IFEQ
    } else if (game_state.frame & 0x3F == 0x20) {
        //@     LDA #11.*6
        //@     JSR SC.ERA
        screen_erase(
            word_position,
            0x42,
            game_state,
        );
        //@    ENDIF
        //@    ENDIF
    }

    //@    LDA FRAME
    //@    AND #1F            ;  update once per half sec
    //@    IFEQ
    if (game_state.frame & 0x1F == 0) {

        //@    TRAI 0C5 AL.X        ;  erase for credit display
        //@    TRAI 058 AL.Y
        word_position = V2{ 0xC5, 0x58 };
        //@    LDA #6*6
        //@    JSR SC.ERA
        screen_erase(
            word_position,
            6 * 6,
            game_state,
        );

        //@    LDA $CNCT
        //@    IFEQ
        //@     TRAI 0D0 AL.X
        //@    ENDIF
        if (game_state.number_of_credits == 0) {
            word_position[0] = 0xD0;
        }

        //@    LDA $$CRDT
        //@    IFEQ
        if (game_state.number_of_credits == 0) {
            //@     LDY $CNCT
            //@     BNE 10$
            //@    ENDIF
            //NOTE: we won't have a concept of 1/2 credits so if
            //@$$CRDT (credit count) is 0
            //@$CNCT (coin count) would also be 0.

            //@    JSR DG.2OT
            draw_2_digit_number_suppress_leading_zero(
                game_state.number_of_credits,
                word_position,
                game_state,
            );
        }

        //@10$:

        //@    LDA AL.X
        //@    ADD #4
        //@    STA AL.X
        word_position[0] += 4;

        //@    LDA $CNCT
        //@    IFNE
        //@     LDA #17
        //@     JSR WR.DRW    ;  1/2 credit display
        //@    ENDIF
        //NOTE: we won't have a concept of 1/2 credits
        //@     so, we do not implement the above

        //@    ENDIF
    }

    //@    LDA $$CRDT
    //@    ORA $CNCT    ;  no half credits
    //@    IFEQ
    if (game_state.number_of_credits == 0) {

        //@    DEC MN.DEL
        //@    IFEQ
        //@    DEC 1+MN.DEL
        game_state.main_loop_delay -= 1;
        //@    IFMI
        if (game_state.main_loop_delay < 0) {
            //NOTE this will be a 1 player game only. So ignore all 2 player references

            //@      TRAI 1 P1.LIV
            game_state.lives = 1;
            //@      TRAI 0 PL.FLG        ;  one player game
            //@      STA P2.LIV
            //@      STA PL.UP
            //@      STA WV.WAR        ;  reset warp
            game_state.wave_enable_warp = false;
            //@      JSR MN.SCI
            initialize_and_draw_player_score(game_state);
            //@      JSR GM.ST0
            initialize_game_start_state(game_state);
            //@;      JMP GM.ENL
            //@    ENDIF
        }
        //@    ENDIF

        //@    ENDIF
    }

    //@    JMP GM.ENL
}

//GM.ST
fn update_start_game_state(game_state: *GameState) void {
    //TODO: code seems to be in  CJTB.MAC
    //@SEI
    //@JSR MN.SNI
    //@CLI

    //@JSR WV.INI        ; init waves
    initialize_wave_data(game_state);

    //TODO:
    //@LDA #0
    //@JSR MN.SN1    ;  start game music

    //@JSR GM.SW0
    start_of_wave(game_state);
    //@JMP GM.ENL

}
//@ GM.SW:
fn update_start_of_wave_state(game_state: *GameState) void {
    //@     JSR MN.FRA
    frame_handler(game_state);

    //@     JSR         ; draw a row of gems
    {
        //@;--------------------
        //@;  draw a row of gems
        //@CT.GDR:
        //@    LDA FRAME
        //@    AND #1
        //@    IFEQ
        if (game_state.frame & 1 == 0) {
            //@    JSR CT.GRD
            draw_gem_row(game_state);

            //@    DEC CT.CNT
            game_state.castle_row_count -= 1;
            //@    IFPL
            if (game_state.castle_row_count >= 0) {
                //@    JSR CR.ADV
                advance_castle_row(game_state);
                //@    RTS
            } else {
                //@    JSR GM.WO0    ; done, so go to next game state
                game_state.current_state = .InitWaveMotionObjects;

                //@    ENDIF
            }

            //@    ENDIF
        }
        //@    RTS
    }

    //@     JMP GM.ENL
}

fn update_wave_motion_objects_state(game_state: *GameState) void {
    //@ JSR SC.LDS        ; lives display
    {
        //@ ;------------------------------------------
        //@ ;  lives and score display at start of wave
        //@ SC.LDS:
        //@     JSR SC.LD2
        draw_lives(game_state);
        //@     JSR SC.OT2
        draw_score(game_state);

        //@     RTS

    }
    //@ JSR EN.INP        ; init entity position
    init_all_entity_positions(game_state);

    //@ JSR GM.GP0
    {
        //@ ;  ----- state 3:  game play
        //@ GM.GP0:
        //@     TRAI 3 GM.STA
        game_state.current_state = .GamePlay;
        //@     LDA #0
        //@     STA CT.GMD
        //NOTE: CT.GMD is "gem regeneration mode" which doesn't seem to be used?

        //@     STA WV.TIM
        //@     STA 1+WV.TIM
        game_state.wave_time = 0;
        //@     STA WV.ATP
        game_state.attract_mode_player_position_index = 0;
        //@     STA WV.CIN        ;  color inhibit
        game_state.prevent_color_transfer = true;
        //@     RTS
    }
    //@ JMP GM.ENL
}
fn update_game_play_state(game_state: *GameState) void {
    //@  JSR MN.FRA        ;  frame handler
    frame_handler(game_state);

    //@     JSR EC.UPD        ; elevator control
    update_elevators(game_state);
    //@     JSR EN.UPD        ; EN update
    update_entities(game_state);
    //@     JSR MT.UPD        ; motion objects
    update_motion_objects(game_state);

    //@ ;  exit attract mode if coin has dropped
    //@     LDA ATRACT
    //@     IFEQ
    if (game_state.is_in_attract_mode) {
        //@      LDA $$CRDT
        //@      IFNE
        if (game_state.number_of_credits > 0) {
            //@       JSR GM.AT0
            init_attract_mode(game_state);
            //@      ENDIF
            //@     ENDIF
        }
    }

    //@     JMP GM.ENL
}

//@     ; ------- state 4:  death sequence
//@ GM.DT0:
fn init_death_sequence_state(game_state: *GameState) void {
    //@    TRAI 4 GM.STA
    game_state.current_state = .DeathSequence;
    //@     TRAI 60 MN.DEL        ;  init delay
    game_state.main_loop_delay = 0x60;
    //@     RTS
}
//@ GM.DT:
fn update_death_sequence_state(game_state: *GameState) void {
    //@     JSR MN.FRA    ;  delay loop
    frame_handler(game_state);
    //@     LDA MN.DEL
    //@     IFNE
    if (game_state.main_loop_delay > 0) {
        //@       DEC MN.DEL
        game_state.main_loop_delay -= 1;
        //@       JMP GM.ENL
        return;
        //@     ENDIF
    }

    //@     DEC WV.LIV
    game_state.lives -= 1;
    //@     IFEQ        ;  if lost last life,
    if (game_state.lives == 0) {
        //@       JSR GM.EG0    ;  end of game
        init_end_of_game_state(game_state);
    }
    //@     ELSE
    else {
        //@       JSR GM.DH0    ;  else continue
        //TODO:
        unreachable;
        //@     ENDIF
    }

    //@     JMP GM.ENL
}
//@ ;  state 6  end of game
//@ GM.EG0:
fn init_end_of_game_state(game_state: *GameState) void {
    //@     TRAI 6 GM.STA
    game_state.current_state = .EndOfGame;
    //@     LDA ATRACT
    //@     IFEQ
    if (game_state.is_in_attract_mode) {
        //@      JMP 10$
        //@ 10$:
        //@     TRAI 01 MN.DEL
        //@     STA 1+MN.DEL
        game_state.main_loop_delay = 0x101;
        //@     RTS
        return;
        //@     ENDIF
    }
    //TODO:
    unreachable;

    //@     TRAI 0 TEMP4
    //@     LDA ST.TIM
    //@     CMP #70
    //@     BCS 40$        ;  280 secs = 4 2/3 minutes game time
    //@     LDA 1+ST.TIM
    //@     BNE 40$
    //@     JMP 50$
    //@ 40$:            ;  which secret warp is it ?
    //@     LDA WV.XCO
    //@     CMP #2
    //@     IFEQ
    //@      LDX #18
    //@      BNE 45$
    //@     ENDIF
    //@     CMP #4
    //@     IFEQ
    //@      LDX #25
    //@      BNE 45$
    //@     ENDIF
    //@     CMP #6
    //@     IFEQ
    //@      LDX #2E
    //@      BNE 45$
    //@     ENDIF
    //@     BNE 50$
    //@ 45$:    STX TEMP4        ;  erase whole screen
    //@     STX TEMP3        ;  message number

    //@ 50$:
    //@     LDA WV.EOG
    //@     IFNE
    //@      STA TEMP4
    //@     ENDIF

    //@     LDA TEMP4
    //@     IFNE
    //@      JSR GR.SCL    ;  either clear whole screen
    //@     ELSE
    //@      JSR GR.MCL    ;  or only part of it
    //@      JSR AL.MDB
    //@     ENDIF

    //@     LDA WV.EOG
    //@     IFEQ        ;  end of crystal castles
    //@      JMP 20$
    //@     ENDIF

    //@     LDA #1C
    //@     JSR MS.DRW    ;  explain last castle

    //@     LDA #10
    //@     JSR MN.SN1

    //@     TRAI 099 SC.NEL        ;  no more extra lives

    //@     LDA WV.EOG    ;  1 to 6
    //@     CMP #1
    //@     IFCC
    //@     LDA #1
    //@     ENDIF
    //@     CMP #6
    //@     IFCS
    //@     LDA #6
    //@     ENDIF

    //@     ADD #2E
    //@     JSR MS.DRW    ;  comment on player

    //@ ;  extra lives bonus
    //@     TRAI 80 AL.X
    //@     STA     AL.Y
    //@     LDA #0
    //@     STA SC.NM
    //@     STA 1+SC.NM
    //@     STA SC.INC
    //@     STA 1+SC.INC

    //@     LDA WV.EOG
    //@     STA 2+SC.INC
    //@     STA 2+SC.NM
    //@     JSR SC.NDS
    //@     JSR SC.UPD

    //@ ;  time bonus
    //@     TRAI 80 AL.X
    //@     TRAI 90 AL.Y

    //@     SED
    //@     LDA #0
    //@     STA SC.NM
    //@     STA SC.INC

    //@     SUB ST.TIM
    //@     STA 1+SC.NM
    //@     LDA #2
    //@     SBC 1+ST.TIM
    //@     IFCS
    //@      STA 2+SC.NM
    //@     ELSE
    //@      LDA #0
    //@      STA 1+SC.NM
    //@      STA 2+SC.NM
    //@     ENDIF
    //@     CLD

    //@     .REPT 4
    //@     ASL 1+SC.NM
    //@     ROL 2+SC.NM
    //@     .ENDM
    //@     TRAM 1+SC.NM 1+SC.INC
    //@     TRAM 2+SC.NM 2+SC.INC

    //@     JSR SC.NDS
    //@     JSR SC.UPD

    //@     LDA #4
    //@     STA MN.DEL
    //@     STA MN.DEL+1

    //@     JMP 30$
    //@ 20$:
    //@     ;  out of lives

    //@     LDA #14
    //@     JSR MS.DRW    ;  game over message
    //@     JSR MN.P12    ;  player 1-2

    //@     LDA TEMP4
    //@     IFNE
    //@      LDA TEMP3
    //@      JSR MS.DRW    ;  secret warp message
    //@      LDA #4
    //@     ELSE
    //@      LDA #2
    //@     ENDIF
    //@     STA 1+MN.DEL
    //@     STA MN.DEL

    //@     LDA #0A
    //@     JSR MN.SN1    ;  game over music start

    //@ 30$:
    //@     JSR EEACC2    ;  end of game accounting
    //@     JSR WV.WRU    ;  update warp
    //@     RTS
    //@ 10$:
    //@     TRAI 01 MN.DEL
    //@     STA 1+MN.DEL
    //@     RTS
}
//@ GM.EG:
fn update_end_of_game_state(game_state: *GameState) void {
    //@     JSR MN.FRA
    frame_handler(game_state);

    //@     JSR EN.BRD
    const buttons = read_both_buttons(game_state);
    //@     BNE 10$
    if (buttons == 0) {

        //@     DEC MN.DEL
        //@     IFEQ
        //@     DEC 1+MN.DEL
        //@     IFEQ
        game_state.main_loop_delay -= 1;
    }
    if (buttons != 0 or game_state.main_loop_delay == 0) {
        //@ 10$:     JSR GM.HF0    ;  high score table
        init_hall_of_fame_state(game_state);
        //@     ENDIF
        //@     ENDIF
    }

    //@     JMP GM.ENL
}
//@ ;  state 13: high scores at end of game, enter initials
//@ GM.HF0:
fn init_hall_of_fame_state(game_state: *GameState) void {
    //@     TRAI 0D GM.STA
    game_state.current_state = .HallOfFame;
    //@     TRAI 03 MN.DEL
    //@     STA 1+MN.DEL
    game_state.main_loop_delay = 0x303;
    //@     TRAI 010 TFLASH
    //NOTE: would be cool to have a flashing trackball, but alas, the Playdate does not have one
    //@     RTS
}
//@ GM.HF:
fn update_hall_of_fame_state(game_state: *GameState) void {
    //@     JSR MN.FRA
    frame_handler(game_state);

    //@     LDA ATRACT
    //@     IFNE        ; not in attract mode
    if (!game_state.is_in_attract_mode) {
        //TODO:
        unreachable;
        //@     JSR SC.HSU    ; update high score
        //@     LDA SC.NWP    ; if new high score
        //@     CMP #0FF
        //@     IFNE
        //@      LDA TEMP1
        //@      JSR HF.DRW    ; display high score table
        //@      JSR SC.INE    ; enter initials
        //@     ELSE
        //@      LDA P2.LIV    ;  if no high score and
        //@      IFEQ        ;  other player dead,  wait
        //@       DEC MN.DEL
        //@       IFEQ
        //@       DEC 1+MN.DEL
        //@       ENDIF
        //@       BNE 10$
        //@      ENDIF
        //@     ENDIF
    }
    //@     ELSE
    else {
        //@      LDA #HFSIZ-1        ;  display top 32 scores
        //@      JSR HF.DRW
        draw_hall_of_fame(HALL_OF_FAME_SIZE - 1, game_state);
        //@     ENDIF
    }

    //@      LDA 2+SC.SCO
    //@      CMP #70
    //@      IFCS
    if (game_state.score >= 0x700000) {
        //@       JSR GM.FL0
        //TODO:
        unreachable;
    }
    //@      ELSE
    else {
        //@       JSR GM.BE0
        init_explaination_board_state(game_state);
        //@      ENDIF
    }

    //@ 10$:
    //@     TRAI 0FF TFLASH
    //NOTE: would be cool to have a flashing trackball, but alas, the Playdate does not have one
    //@     JMP GM.ENL
}
//@ ;-----------------------------
//@ ;  hall of fame drawing
//@ ;  (A) has index of upper left score
//@ HF.DRW:
fn draw_hall_of_fame(upper_left_score_index: usize, game_state: *GameState) void {

    //@     STA TEMP4
    var temp4 = upper_left_score_index;
    //@     SUB #20            ; display  32 entries
    //@     STA TEMP4+1
    const temp4_1 = upper_left_score_index - 0x20;

    //@     JSR GR.SCL
    clear_screen(game_state);
    //@     LDA #1D
    //@     JSR MS.DRW        ;  hall of fame title
    draw_message(0x1D, game_state);

    //@     HF.YOF=48
    const hf_yof = 0x48;
    //@     TRAI HF.YOF AL.Y
    var y: Dimension = hf_yof;

    //@     TRAI 0 TEMP5
    var temp5: isize = 0;
    //@     STA AT.PRT
    //@     BEGIN
    while (temp4_1 != temp4) {
        //@     LDA TEMP5
        //@     AND #080
        //@     ADD #2*6
        //@     STA AL.X
        var x = (temp5 & 0x80) + 12;

        //@     LDA #HFSIZ
        //@     SUB TEMP4
        const rank: isize = @intCast(HALL_OF_FAME_SIZE - temp4);
        //@     JSR AL.CNV
        //NOTE: this converts to hex to decimal, but no need to do that

        //@     STA SC.NM
        //@     STX 1+SC.NM
        //@     TRAI 0 2+SC.NM
        //@     JSR SC.NDS        ;  rank
        draw_6_digit_number(
            rank,
            .{ x, y },
            game_state,
        );

        //@     LDA TEMP5
        //@     AND #080
        //@     ADD #6*6
        //@     STA AL.X
        x = (temp5 & 0x80) + 6 * 6;

        //@     LDX TEMP4
        //@     LDA SC.HS1(X)
        //@     STA SC.NM
        const entry = game_state.scoreboard.entries[temp4];
        const score = entry.score;

        //@     LDA SC.HS2(X)
        //@     STA 1+SC.NM
        //@     LDA SC.HS3(X)
        //@     STA 2+SC.NM
        //@     JSR SC.NDS
        draw_6_digit_number(score, .{ x, y }, game_state);

        //@ ;  initials
        //@     LDA TEMP5
        //@     AND #080
        //@     ADD #0D*6
        //@     STA AL.X
        x = (temp5 & 0x80) + 0xD * 6;

        //@     LDX TEMP4
        //@     TRAM   SC.HI1(X) AL.DIG
        //@     JSR AL.DRW
        add_draw_character_command(
            entry.name.bytes[0],
            .White,
            .{ x, y },
            game_state,
        );
        //@     ADAI 6 AL.X
        x += 6;
        //@     LDX TEMP4
        //@     TRAM   SC.HI2(X) AL.DIG
        //@     JSR AL.DRW
        add_draw_character_command(
            entry.name.bytes[1],
            .White,
            .{ x, y },
            game_state,
        );
        //@     ADAI 6 AL.X
        x += 6;
        //@     LDX TEMP4
        //@     TRAM   SC.HI3(X) AL.DIG
        //@     JSR AL.DRW
        add_draw_character_command(
            entry.name.bytes[2],
            .White,
            .{ x, y },
            game_state,
        );

        //@     ADAI 8 AL.Y
        y += 8;
        //@     LDA TEMP5
        //@     CMP #78
        //@     IFEQ
        if (temp5 == 0x78) {
            //@     TRAI HF.YOF AL.Y
            y = hf_yof;
            //@     ENDIF
        }
        //@     ADAI 8 TEMP5
        temp5 += 8;
        //@     DEC TEMP4
        temp4 -= 1;
        //@     LDA TEMP4
        //@     CMP TEMP4+1
        //NOTE: handled in the while condition
        //@     EQEND
    }

    //@     LDA ATRACT
    //@     IFEQ
    if (game_state.is_in_attract_mode) {
        //@      TRAI 4 1+MN.DEL
        game_state.main_loop_delay = 0x400 | (game_state.main_loop_delay & 0xFF);
        {
            //TODO this seems to read some vblank registers we don't have...
            //@      LDA HW.ST1
            //@      AND #MA.ST1
            //@      IFEQ
            //@      LDA HW.ST2
            //@      AND #MA.ST2
            //@      IFEQ
            //@       JSR EEACC
            //@      ENDIF
            //@      ENDIF
        }

        //@      BEGIN
        while ((game_state.main_loop_delay) >> 8 != 0) {
            //@       JSR MN.FRA
            frame_handler(game_state);
            //@       LDA $$CRDT
            //@       BNE 30$
            if (game_state.number_of_credits > 0) {
                break;
            }
            //@       DEC MN.DEL
            //@       IFEQ
            //@       DEC 1+MN.DEL
            //@       ENDIF
            game_state.main_loop_delay -= 1;
            //@      LDA 1+MN.DEL
            //@      EQEND
        }
        //@  30$:
        //@     ENDIF
    }
    //@     RTS
}
//@ ;---  state 14 explanation board
//@ GM.BE0:
fn init_explaination_board_state(game_state: *GameState) void {
    //@     TRAI 0E GM.STA
    game_state.current_state = .ExplainationBoard;
    //@     LDA $$CRDT
    //@     ORA $CNCT
    //@     IFEQ
    if (game_state.number_of_credits == 0) {
        //@      JSR GR.SCL
        clear_screen(game_state);
        //@      LDA #23    ;  draw it if no pending coins
        //@      JSR MS.DRW
        draw_message(0x23, game_state);
        //@     ENDIF
    }

    //@     LDA #0        ;  init animation variable
    //@     TAX
    //@     BEGIN
    //@     STA EN.ANV(X)
    //@     INXS 2
    //@     CPX #14
    //@     PLEND
    @memset(game_state.entity_animation[0..8], 0);
    //@     TRAI 06 1+MN.DEL
    game_state.main_loop_delay = 0x600 | (game_state.main_loop_delay & 0xFF);

    //@     RTS
}

//@ GM.BE:
fn update_explaination_board_state(game_state: *GameState) void {
    //@     JSR MN.FRA
    frame_handler(game_state);

    const buttons = read_both_buttons(game_state);
    //@     LDA $$CRDT
    //@     ORA $CNCT
    //@     BNE 10$
    if (game_state.number_of_credits == 0) {

        //@     JSR EN.BRD

        //@     BNE 10$        ;  if button pressed,  exit

        //@     JSR EN.BEM
        draw_explaination_board(game_state);
        //@     JSR MT.UPD
        update_motion_objects(game_state);
    }
    //@     DEC MN.DEL
    //@     IFEQ
    //@     DEC 1+MN.DEL
    game_state.main_loop_delay -= 1;
    //@     IFEQ
    //@ 10$:
    if (buttons != 0 or game_state.number_of_credits > 0 or game_state.main_loop_delay == 0) {
        //@      JSR GR.SCL
        clear_screen(game_state);
        //@      JSR GM.AT0
        game_state.debug_should_not_yield = false;
        init_attract_mode(game_state);
        //@     ENDIF
        //@     ENDIF
    }
    //@     JMP GM.ENL
}
//@ ;-------------------
//@ ;  explanation board

//@ EN.BEM:
fn draw_explaination_board(game_state: *GameState) void {
    //EN.BEX and EN.BEY
    const ENTITY_POSITIONS = [10]V2{
        .{ 0x20, 0xB8 }, .{ 0x20, 0x90 },
        .{ 0xD8, 0x90 }, .{ 0xA0, 0x70 },
        .{ 0xB0, 0x58 }, .{ 0x20, 0x38 },
        .{ 0x40, 2 },    .{ 0x70, 2 },
        .{ 0x90, 2 },    .{ 0xC0, 2 },
    };
    //EN.BEP
    const ENTITY_PICTURES = [10]isize{ 107, 1, 49, 0x80 + 16, 0x80, 0x80 + 68, 33, 33, 33, 33 };
    const EN_ZFL = [11]u8{ 0, 0x7, 0x1F, 0x1F, 0x1F, 0x7, 0xF, 0xF, 0xF, 0xF, 0xF };
    const EN_BEK = [10]u8{ 0x7, 0x1F, 0x1F, 0x1F, 0x7, 0xF, 0xF, 0xF, 0xF, 0xF };
    //@     LDX #0
    //@     BEGIN
    for (0..MAX_NUMBER_OF_ENTITIES) |entity| {
        //@       TXA
        //@       LSR
        //@       TAY
        const reg_y = entity;
        //@       TRAM EN.BEX(Y) EN.X(X)
        //@       TRAM EN.BEY(Y) EN.Y(X)
        game_state.entity_position[entity] = ENTITY_POSITIONS[reg_y];
        //@       LDA EN.ANV(X)
        //@       ADD EN.BEP(Y)
        //@       JSR EN.PCF
        const picture = game_state.entity_animation[entity] + ENTITY_PICTURES[reg_y];
        fill_entity_pictures(picture, entity, game_state);
        //@       LDA EN.ZFL(Y)
        //@       IFEQ
        if (EN_ZFL[reg_y] == 0) {
            //@        STA EN.PC1(X)
            game_state.entity_picture[entity][0] = 0;
            //@        STA EN.PC2(X)
            game_state.entity_picture[entity][1] = 0;
            //@       ENDIF
        }

        //@       CPX #08
        //@       IFEQ
        if (entity == 4) {
            //@        LDA FRAME
            //@        AND #3F
            //@        LSR
            //@        CMP #10
            //@        IFPL
            var x = (game_state.frame & 0x3F) >> 1;
            if (x == 0x10) {
                //@         JSR NEGATE
                //@         ADD #20
                x = -x + 0x20;
                //@        ENDIF
            }
            //@        ADD EN.BEX(Y)
            x += ENTITY_POSITIONS[reg_y][0];
            //@        STA EN.X(X)
            game_state.entity_position[entity][0] = x;
            //@       ENDIF

        }

        //@       LDA EN.ANV(X)
        //@       IFPL
        if (u8gte(game_state.entity_animation[entity], 0)) {
            //@        LDA FRAME
            //@        AND #0F
            //@        IFEQ
            if (game_state.frame & 0xF == 0) {
                //@         LDA EN.ANV(X)
                //@         CPY #0
                //@         IFEQ
                //@          ADD #2
                //@         ELSE
                //@          ADD #4
                //@         ENDIF
                //@         AND EN.BEK(Y)
                //@         STA EN.ANV(X)
                game_state.entity_animation[entity] += if (reg_y == 0) 2 else 4;
                game_state.entity_animation[entity] &= EN_BEK[reg_y];
                //@        ENDIF
                //@       ENDIF
            }
        }
        //@     INXS 2
        //@     CPX EN.NUM
        //@     PLEND
    }
    //@     RTS
}
//SC.ERA
inline fn screen_erase(
    start_position: V2,
    number_of_pixel_columns_to_erase: isize,
    game_state: *GameState,
) void {
    add_draw_command(.{
        .shape = .ScreenErase,
        .position = start_position,
        .number_of_segments = number_of_pixel_columns_to_erase,

        //unused
        .color = undefined,
    }, game_state);
}

//DG.2OT
inline fn draw_2_digit_number_suppress_leading_zero(
    number: isize,
    position: V2,
    game_state: *GameState,
) void {
    //@ JSR AL.CNV
    //@    LDX #0
    //@    STX SC.FNZ    ; 1= found first non-zero digit
    var suppress_leading_zero = true;
    draw_2_digit_number(
        number,
        position,
        &suppress_leading_zero,
        game_state,
    );
}
//@DG.2HT
fn draw_2_digit_number(
    number: isize,
    start_position: V2,
    suppress_leading_zero: *bool,
    game_state: *GameState,
) void {
    if (number < 0) {
        toolbox.panic(
            "Uhhh don't know what to do with negative numbers: {}",
            .{number},
        );
    }

    //@    PHA
    //@    LSRS 4
    //@    STA SC.DIG

    //@    TRAI 2*6 SC.LEF    ; pixels left to erase
    var pixels_left_to_erase: isize = 2 * 6; //6 pixels per digit
    var position = start_position;
    var n = number;

    for (0..2) |_| {
        //@    JSR AL.DGO
        draw_digit(
            @intCast(@mod(n, 10)),
            &position,
            suppress_leading_zero,
            &pixels_left_to_erase,
            game_state,
        );
        n = @divExact(n, 10);
        suppress_leading_zero.* = false;
    }

    //@    LDA SC.LEF
    //@    JSR SC.ERA
    screen_erase(
        position,
        pixels_left_to_erase,
        game_state,
    );
}
//@AL.DGO:
fn draw_digit(
    digit: isize,
    position: *V2,
    suppress_zero: *bool,
    pixels_left_to_erase: *isize,
    game_state: *GameState,
) void {
    //@    LDA SC.FNZ    ;  zero suppress
    //@    IFEQ
    //@    LDA SC.DIG
    //@    IFEQ
    //@    JMP 50$
    if (suppress_zero.* and digit == 0) {
        return;
    }
    //@    ELSE

    //@    INC SC.FNZ
    suppress_zero.* = false;

    //@    ENDIF
    //@    ENDIF

    //@    LDA #6
    //@    JSR SC.ERA
    screen_erase(
        position.*,
        6,
        game_state,
    );

    //@    LDA SC.DIG
    //@    ADD #40
    //@    STA AL.DIG

    //@    CL.ALP=07F
    const color = color_value_to_color(0x7F);
    //@    TRAI CL.ALP AL.COL
    //@    JSR AL.DRW
    add_draw_character_command(
        @intCast(@mod(digit, 10) + '0'),
        color,
        position.*,
        game_state,
    );

    //@    ADAI 6 AL.X
    position.*[0] += 6;
    //@    SBAI 6 SC.LEF
    pixels_left_to_erase.* -= 6;
    //@50$:
    //@RTS
}

//MN.SCI
fn initialize_and_draw_player_score(game_state: *GameState) void {
    //@    LDA #0
    //@STA P1.SCO
    //@STA P1.SCO+1
    //@STA P1.SCO+2
    game_state.score = 0;
    //@JSR SC.2PL        ;  and output too
    draw_score(game_state);
}

//SC.2PL
//SC.OUT
//SC.OT2
fn draw_score(game_state: *GameState) void {
    //@LDA #2E
    //@STA AL.Y
    //@TRAI 10 AL.X

    //@TR24AM SC.SCO SC.NM    ;  score
    //@JSR SC.NDS
    draw_6_digit_number(
        game_state.score,
        .{ 0x10, 0x2E },
        game_state,
    );
}

//SC.NDS
fn draw_6_digit_number(
    number: isize,
    start_position: V2,
    game_state: *GameState,
) void {
    //TRAI 6*6 SC.LEF    ; pixels left to erase
    var pixels_left_to_erase: isize = 0x6 * 0x6;
    //@    TRAI 0 SC.FNZ    ; 1= found first non-zero digit
    var suppress_zero = true;

    //@;  first digit
    //@    LDA SC.NM+2
    //@    LSRS 4
    //@    STA SC.DIG
    //@    JSR AL.DGO
    var position = start_position;
    var divisor: isize = 100000;
    for (0..5) |_| {
        const digit = @mod(@divTrunc(number, divisor), 10);
        draw_digit(
            digit,
            &position,
            &suppress_zero,
            &pixels_left_to_erase,
            game_state,
        );
        divisor = @divTrunc(divisor, 10);
    }
    suppress_zero = false;
    draw_digit(
        @mod(number, 10),
        &position,
        &suppress_zero,
        &pixels_left_to_erase,
        game_state,
    );
    //@LDA SC.LEF
    //@JSR SC.ERA
    screen_erase(position, pixels_left_to_erase, game_state);
}

//GM.ST0
fn initialize_game_start_state(game_state: *GameState) void {
    //@TRAI 1 GM.STA
    game_state.current_state = .StartGame;

    //NOTE: for trackball flash which is not on the playdate
    //@TRAI 0FF TFLASH
}

//MN.FRA
fn frame_handler(game_state: *GameState) void {
    //@    10$:     LSR SYNC        ;
    //@     BCC 10$        ;  frame handler

    //Check against the arcade coordinates
    if ((comptime VALIDATE_AGAINST_ARCADE) and
        game_state.current_state == .GamePlay and
        game_state.wave_time < game_state.expected_test_data.len)
    {
        const test_data = game_state.expected_test_data[@intCast(game_state.wave_time)];
        toolbox.expecteq(
            test_data.wave_time,
            game_state.wave_time,
            "Unexpected wave time",
        );
        for (0..MAX_NUMBER_OF_ENTITIES) |entity| {
            const expected_x = test_data.entity_positions[entity * 2];
            const expected_y = test_data.entity_positions[entity * 2 + 1];
            const expected_fine_x = test_data.entity_fine_positions[entity * 2];
            const expected_fine_y = test_data.entity_fine_positions[entity * 2 + 1];
            const actual_x: u8 = @intCast(game_state.entity_position[entity][0] & 0xFF);
            const actual_y: u8 = @intCast(game_state.entity_position[entity][1] & 0xFF);
            const actual_fine_x: u8 = @intCast(game_state.entity_fine_position[entity][0] & 0xFF);
            const actual_fine_y: u8 = @intCast(game_state.entity_fine_position[entity][1] & 0xFF);

            toolbox.expect(
                expected_x == actual_x,
                "Unexpected x position: Expected: {X}, Actual: {X}, Wave Time: {X}, Entity: {X}",
                .{ expected_x, actual_x, game_state.wave_time, entity },
            );
            toolbox.expect(
                expected_y == actual_y,
                "Unexpected y position: Expected: {X}, Actual: {X}, Wave Time: {X}, Entity: {X}",
                .{ expected_y, actual_y, game_state.wave_time, entity },
            );
            toolbox.expect(
                expected_fine_x == actual_fine_x,
                "Unexpected fine x position: Expected: {X}, Actual: {X}, Wave Time: {X}, Entity: {X}",
                .{ expected_fine_x, actual_fine_x, game_state.wave_time, entity },
            );
            toolbox.expect(
                expected_fine_y == actual_fine_y,
                "Unexpected fine y position: Expected: {X}, Actual: {X}, Wave Time: {X}, Entity: {X}",
                .{ expected_fine_y, actual_fine_y, game_state.wave_time, entity },
            );
        }
    }
    next_frame(game_state);

    //@    INC16 FRAME
    game_state.frame +%= 1;
    //@    INC16 WV.TIM
    game_state.wave_time +%= 1;

    //@    LDA HW.STS        ;  self test switch
    //@    AND #MA.STS
    //@    IFEQ
    //@     JMP MN.SLT
    //@    ENDIF

    //@;  housekeeping, at least every 6x16 milliseconds.
    //@MN.HOU:
    //@    STA HW.WDC        ; prevent watchdog reset
    //@    JSR EEACC1        ;  coin stats
}

//CL.PR
fn set_bitmap_values_of_faces(face: u8, game_state: *GameState) void {
    //@EOR #80
    //@ORA #0F
    //@AND #8F

    var face_tmp = ((face ^ 0x80) | 0x0F) & 0x8F;
    //LDY #7
    var i: isize = 7;
    //@BEGIN
    while (i > 0) : (i -= 1) {
        //@ SUB #10
        face_tmp -%= 0x10;
        //@ STA FC.BV-1(Y)
        game_state.face_color_values[@intCast(i - 1)] = face_tmp;
        //@ DEY
        //@EQEND

    }
}
fn color_value_to_color(color_value: u8) Color {

    //Only top 4 bits are used
    return switch ((color_value >> 4) & 0xF) {
        0xF, 0x9, 0x7, 0x1 => .White,
        0xA, 0x2 => .Gray,
        0xB, 0x3 => .DarkGray,
        0xC, 0x4, 0 => .Black,
        0xD => .Red,
        else => toolbox.panic("Unknown color value: {}", .{color_value}),
        //@0...0x9 => .White,
        //@0xA...0xC => .Gray,
        //@else => .Black,
    };
}

//@;------------------------------------
//@;  routine to determine edge switches
//@BL.EDT
fn determine_edge_switches(game_state: *GameState) void {
    const wave_data = game_state.current_wave_data;
    const adl = game_state.castle_adl;

    //@ LDY #0
    //@    JSR BL.URC
    game_state.castle_block_is_upper_right_edge_hidden =
        wave_data[adl] != wave_data[game_state.castle_arl];

    //@    JSR BL.ULC
    game_state.castle_block_is_upper_left_edge_hidden =
        wave_data[adl] != wave_data[game_state.castle_all];
    //@    BIT BL.URE
    //@    BMI 10$
    //@    BIT BL.ULE
    //@    BMI 10$
    if (!game_state.castle_block_is_upper_right_edge_hidden and
        !game_state.castle_block_is_upper_left_edge_hidden)
    {
        //@    JSR BL.UCC
        game_state.castle_block_is_upper_corner_hidden =
            wave_data[adl] != wave_data[game_state.castle_acl];
        //@    JMP 20$
    } else {
        //@10$:    TRAI 0FF BL.UCR
        game_state.castle_block_is_upper_corner_hidden = true;
    }
    //@20$:
    //@    JSR BL.HRC
    calculate_hidden_right_line(game_state);

    //@    JSR BL.HLC
    calculate_hidden_left_line(game_state);

    //@    INC16 CT.ACL
    game_state.castle_acl += 1;
    //@    INC16 CT.ARL
    game_state.castle_arl += 1;
    //@    INC16 CT.AFL
    game_state.castle_afl += 1;
    //@    INC16 CT.ALL
    game_state.castle_all += 1;
}
//@;-----------------------------
//@;  calculate right hidden line
//@;  HES HEL start and length of hidden edge
//@BL.HRC:
fn calculate_hidden_right_line(game_state: *GameState) void {
    const wave_data = game_state.current_wave_data;
    const adl = game_state.castle_adl;
    const arl = game_state.castle_arl;
    const afl = game_state.castle_afl;
    //@    LDA #0FF
    //@    STA BL.HRE
    game_state.castle_block_is_right_edge_hidden = true;

    //@    CMPIN CT.ADL,CT.ARL
    //@    BCC 10$
    if (wave_data[adl] < wave_data[arl]) {
        //@10$:    CMPIN CT.ADL,CT.AFL
        //@    BCS 30$
        if (wave_data[adl] >= wave_data[afl]) {
            //@30$:    TRAM @CT.AFL(Y) BL.HES    ; cases 3 and 5
            //@    INC BL.HES
            game_state.castle_block_hidden_edge_start =
                wave_data[afl] + 1;

            //@    TRAM FC.BV1 FC.COH
            game_state.face_hidden_edge_color_value =
                game_state.face_color_values[2];
            //@    LDA NY,CT.ADL
            //@35$:
            //@    SUB @CT.AFL(Y)
            //@    JMP 25$
            //@25$:    STA BL.HEL
            //@    DEC BL.HEL
            //@    BMI 5$
            //@    DEC BL.HEL
            //@    BMI 5$
            game_state.castle_block_hidden_right_edge_length =
                @as(isize, @intCast(wave_data[adl])) -
                @as(isize, @intCast(wave_data[afl])) - 2;
            if (game_state.castle_block_hidden_right_edge_length < 0) {
                //@5$:    LDA #0
                //@    STA BL.HRE
                game_state.castle_block_is_right_edge_hidden = false;
            }
        }
        //@    BCC 5$        ; BRA
        else {
            //@5$:    LDA #0
            //@    STA BL.HRE
            game_state.castle_block_is_right_edge_hidden = false;
        }
        return;
    }
    //@    CMPIN CT.AFL,CT.ARL
    //@    BCC 30$
    if (wave_data[afl] < wave_data[arl]) {
        //@30$:    TRAM @CT.AFL(Y) BL.HES    ; cases 3 and 5
        //@    INC BL.HES
        game_state.castle_block_hidden_edge_start =
            wave_data[afl] + 1;

        //@    TRAM FC.BV1 FC.COH
        game_state.face_hidden_edge_color_value =
            game_state.face_color_values[2];
        //@    LDA NY,CT.ADL
        //@35$:
        //@    SUB @CT.AFL(Y)
        //@    JMP 25$
        //@25$:    STA BL.HEL
        //@    DEC BL.HEL
        //@    BMI 5$
        //@    DEC BL.HEL
        //@    BMI 5$
        game_state.castle_block_hidden_right_edge_length =
            wave_data[adl] - wave_data[afl] - 2;

        //@    BMI 5$
        if (game_state.castle_block_hidden_right_edge_length < 0) {
            //@5$:    LDA #0
            //@    STA BL.HRE
            game_state.castle_block_is_right_edge_hidden = false;
        }
        //@    RTS
        return;
    }
    game_state.castle_block_is_right_edge_hidden = false;

    //NOTE: this should all be implmented above
    //@    LDA #0FF
    //@    STA BL.HRE
    //@    CMPIN CT.ADL,CT.ARL
    //@    BCC 10$

    //@    CMPIN CT.AFL,CT.ARL
    //@    BCC 30$
    //@; cases 4 and 6,  no erase
    //@5$:    LDA #0
    //@    STA BL.HRE
    //@    RTS

    //@10$:    CMPIN CT.ADL,CT.AFL
    //@    BCS 30$
    //@    BCC 5$        ; BRA
    //@            ; cases 1 and 2 used to be here
    //@25$:    STA BL.HEL
    //@    BMI 5$
    //@    DEC BL.HEL
    //@    BMI 5$
    //@    DEC BL.HEL
    //@    BMI 5$
    //@    RTS

    //@30$:    TRAM @CT.AFL(Y) BL.HES    ; cases 3 and 5
    //@    INC BL.HES
    //@    TRAM FC.BV1 FC.COH
    //@    CMPIN CT.ARL,CT.ADL
    //@    BCC 35$
    //@    LDA NY,CT.ADL
    //@35$:
    //@    SUB @CT.AFL(Y)
    //@    JMP 25$
}
//@;---------------------------
//@; calculate left hidden line
//@BL.HLC:
fn calculate_hidden_left_line(game_state: *GameState) void {
    const wave_data = game_state.current_wave_data;
    const adl = game_state.castle_adl;
    const all = game_state.castle_all;
    //    LDA #0FF
    //@    STA BL.HLE
    game_state.castle_block_is_left_edge_hidden = true;

    //@    CMPIN CT.ADL,CT.ALL
    //@    BCC 10$        ; erase line to min of ALL,ADL
    //@    LDA NY,CT.ALL
    //@10$:    STA BL.HLL
    //@    BEQ 40$
    //@    DEC BL.HLL
    //@    BEQ 40$
    //@    DEC BL.HLL
    //@    BEQ 40$
    game_state.castle_block_hidden_left_edge_length =
        @min(wave_data[adl], wave_data[all]);

    //@    RTS

    //@40$:    LDA #0
    //@    STA BL.HLE

    //@    RTS
    if (game_state.castle_block_hidden_left_edge_length - 2 <= 0) {
        game_state.castle_block_is_left_edge_hidden = false;
    } else {
        game_state.castle_block_hidden_left_edge_length -= 2;
    }
}
//FACE1:
fn draw_face1(game_state: *GameState) void {
    //@TRAM FC.HST LN.HCR
    //@TRAM FC.V1S LN.VCR
    var line_position = V2{
        game_state.face_position[0],
        game_state.face_v1s,
    };
    //@TRAM FC.BV1 LN.CO1
    var color = color_value_to_color(game_state.face_color_values[2]);
    //@TRAM FC.V1N CURLIN
    var current_line = game_state.face_v1n;
    while (true) {
        //@JSR LN.F1
        add_draw_line_command(
            .Line1,
            color,
            FAST_LINE_1_NUM_SEGMENTS,
            line_position,
            game_state,
        );
        //@DEC CURLIN
        current_line -= 1;
        //@BMI 20$
        if (current_line < 0) {
            break;
        }
        //@DEC LN.VCR
        line_position -= .{ 0, 1 };
    }
    //draw border
    //@    BORDR1:
    {
        //@ TRAM FC.BVB LN.CO1    ; upper edge
        //@    STA LN.CO3
        const border_color_value = game_state.face_color_values[3];
        color = color_value_to_color(border_color_value);
        //@    JSR LN.F1
        add_draw_line_command(
            .Line1,
            color,
            FAST_LINE_1_NUM_SEGMENTS,
            line_position,
            game_state,
        );

        //@    TRAM FC.VST LN.VCR    ; lower edge
        line_position[1] = game_state.face_position[1];
        //@    JSR LN.F1
        add_draw_line_command(
            .Line1,
            color,
            FAST_LINE_1_NUM_SEGMENTS,
            line_position,
            game_state,
        );

        //@    TRAM FC.V1N LN.LG3
        //@    LDA FC.HST        ; right edge
        //@    ADD #CT.XSZ
        //@    STA LN.HCR

        //@    LDA FC.V1S
        //@    SUB #CT.XSZ
        //@    STA LN.VCR
        line_position = .{
            game_state.face_position[0] + 4, game_state.face_v1s - 4,
        };
        //@    JSR LN.3
        add_draw_line_command(
            .Line3,
            color,
            game_state.castle_block_v1n,
            line_position,
            game_state,
        );

        //@;  hidden edge
        //@    BIT BL.HRE
        //@    IFMI

        //@     LDA FC.V1N
        //@     IFNE

        if (game_state.castle_block_is_right_edge_hidden and
            game_state.face_v1n != 0)
        {
            //@      TRAM BL.HEL LN.LG3
            //@      TRAM FC.COH LN.CO3

            //@      LDA FC.VST
            //@      SUB #CT.XSZ
            //@      SUB BL.HES
            //@   STA LN.VCR
            line_position[1] =
                game_state.face_position[1] - 4 - game_state.castle_block_hidden_edge_start;

            const hidden_edge_color = color_value_to_color(game_state.face_hidden_edge_color_value);
            //@      JSR LN.3
            add_draw_line_command(
                .Line3,
                hidden_edge_color,
                game_state.castle_block_hidden_right_edge_length,
                line_position,
                game_state,
            );
        }
        //@     ENDIF
        //@    ENDIF
    }
}
//FACE2:
fn draw_face2(game_state: *GameState) void {
    //@ TRAM FC.HST LN.HCR
    //@    TRAM FC.V2S LN.VCR
    var line_position = V2{
        game_state.face_position[0],
        game_state.face_v2s,
    };
    //@    TRAM FC.BV2 LN.CO2
    var color = color_value_to_color(game_state.face_color_values[1]);
    //@    TRAM FC.V2N CURLIN
    var current_line = game_state.face_v2n;

    while (true) {
        //@10$:    JSR LN.F2
        add_draw_line_command(
            .Line2,
            color,
            FAST_LINE_2_NUM_SEGMENTS,
            line_position,
            game_state,
        );
        //@    DEC CURLIN
        current_line -= 1;
        //@    BMI 20$
        if (current_line < 0) {
            break;
        }
        //@    DEC LN.VCR
        line_position -= .{ 0, 1 };
        //@    JMP 10$
    }
    //@20$:    JSR BORDR2

    //BORDR2:
    {
        //@ TRAM FC.BVB LN.CO2    ; upper line
        //@    STA LN.CO3
        const border_color_value = game_state.face_color_values[3];
        color = color_value_to_color(border_color_value);
        //@    JSR LN.F2
        add_draw_line_command(
            .Line2,
            color,
            FAST_LINE_2_NUM_SEGMENTS,
            line_position,
            game_state,
        );

        //@    TRAM FC.V2S LN.VCR    ; lower line
        line_position[1] = game_state.face_v2s;
        //@    JSR LN.F2
        add_draw_line_command(
            .Line2,
            color,
            FAST_LINE_2_NUM_SEGMENTS,
            line_position,
            game_state,
        );

        //@    TRAM FC.V2S LN.VCR
        line_position[1] = game_state.face_v2s;
        //@    TRAM FC.V2N LN.LG3    ; right vertical line
        const number_of_segments = game_state.face_v2n;
        //@    JSR LN.3
        add_draw_line_command(
            .Line3,
            color,
            number_of_segments,
            line_position,
            game_state,
        );

        //@    LDA FC.HST    ; left vertical line
        //@    SUB #CT.YSZ
        //@    STA LN.HCR
        //@    LDA LN.VCR
        //@    SUB #CT.YSZ/4
        //@    STA LN.VCR
        line_position = .{
            game_state.face_position[0] - 8,
            line_position[1] - 2,
        };
        //@    JSR LN.3
        add_draw_line_command(
            .Line3,
            color,
            number_of_segments,
            line_position,
            game_state,
        );

        //@;  hidden edge
        //@    BIT BL.HLE
        //@    IFMI
        //@     LDA FC.V2N
        //@     IFNE

        if (game_state.castle_block_is_left_edge_hidden and
            game_state.face_v2n != 0)
        {
            //@      LDA FC.VST
            //@      SUB #CT.YSZ/4
            //@      STA LN.VCR
            //@      DEC LN.VCR
            line_position[1] = game_state.face_position[1] - 2 - 1;
            //@      TRAM FC.BV2 LN.CO3
            color = color_value_to_color(game_state.face_color_values[1]);
            //@      TRAM BL.HLL LN.LG3
            //@      JSR LN.3
            add_draw_line_command(
                .Line3,
                color,
                game_state.castle_block_hidden_left_edge_length,
                line_position,
                game_state,
            );
        }
        //@     ENDIF
        //@    ENDIF
        //@    RTS

    }
}
//FACE3:
fn draw_face3(game_state: *GameState) void {
    //@ TRAI CT.XSZ LN.LG1
    var number_of_line_1_segments: isize = 4;
    //@    TRAI CT.YSZ CURLIN
    var number_of_lines: isize = 8;
    //@    TRAM FC.HST LN.HCR
    //@    TRAM FC.VST LN.VCR
    var line_position = game_state.face_position;
    //@    TRAM CT.BV3 LN.CO1
    var line_1_color = color_value_to_color(game_state.face_color_values[0]);

    //@10$:
    while (true) {
        //@JSR LN.F1
        add_draw_line_command(
            .Line1,
            line_1_color,
            FAST_LINE_1_NUM_SEGMENTS,
            line_position,
            game_state,
        );
        //@    DEC CURLIN
        number_of_lines -= 1;

        //@    BMI 20$
        if (number_of_lines < 0) {
            break;
        }
        //@    DEC LN.HCR
        line_position[0] -= 1;

        //@    JSR LN.F1
        add_draw_line_command(
            .Line1,
            line_1_color,
            FAST_LINE_1_NUM_SEGMENTS,
            line_position,
            game_state,
        );

        //@    DEC CURLIN
        number_of_lines -= 1;
        //@    BMI 20$
        if (number_of_lines < 0) {
            break;
        }
        //@    DEC LN.HCR
        line_position[0] -= 1;

        //@    JSR LN.F1
        add_draw_line_command(
            .Line1,
            line_1_color,
            FAST_LINE_1_NUM_SEGMENTS,
            line_position,
            game_state,
        );
        //@    DEC CURLIN
        number_of_lines -= 1;
        //@    BMI 20$
        if (number_of_lines < 0) {
            break;
        }

        //@    DEC LN.VCR
        line_position[1] -= 1;

        //@    DEC LN.LG1
        number_of_line_1_segments -= 1;

        //@    JSR LN.1
        add_draw_line_command(
            .Line1,
            line_1_color,
            number_of_line_1_segments,
            line_position,
            game_state,
        );
        //@    INC LN.LG1
        number_of_line_1_segments += 1;

        //@    DEC LN.HCR
        line_position[0] -= 1;

        //@    JSR LN.F1
        add_draw_line_command(
            .Line1,
            line_1_color,
            FAST_LINE_1_NUM_SEGMENTS,
            line_position,
            game_state,
        );
        //@    DEC CURLIN
        number_of_lines -= 1;
        //@    BMI 20$
        if (number_of_lines < 0) {
            break;
        }
        //@    DEC LN.HCR
        line_position[0] -= 1;

        //@    JMP 10$
    }
    //@20$:    JSR BORDR3
    //BORDR3:
    {
        //@ TRAM FC.BVB LN.CO1    ; upper left edge
        line_1_color = color_value_to_color(game_state.face_color_values[3]);
        //@    STA LN.CO2
        const line_2_color = line_1_color;
        //@    BIT BL.ULE
        //@    IFMI
        if (game_state.castle_block_is_upper_left_edge_hidden) {
            //@     JSR LN.F1
            add_draw_line_command(
                .Line1,
                line_1_color,
                FAST_LINE_1_NUM_SEGMENTS,
                line_position,
                game_state,
            );
        }
        //@    ELSE
        else {
            //@            ; delete extraneous line
            //@     TRAM CT.BV3 LN.CO1
            line_1_color = color_value_to_color(game_state.face_color_values[0]);
            //@     DEC LN.LG1
            number_of_line_1_segments -= 1;
            //@     JSR LN.1
            add_draw_line_command(
                .Line1,
                line_1_color,
                number_of_line_1_segments,
                line_position,
                game_state,
            );

            //@     INC LN.LG1
            number_of_line_1_segments += 1;
            //@     TRAM FC.BVB LN.CO1
            line_1_color = color_value_to_color(game_state.face_color_values[3]);
            //@    ENDIF
        }

        //@    TRAM FC.HST LN.HCR    ; lower right edge
        //@    TRAM FC.VST LN.VCR
        line_position = game_state.face_position;
        //@    JSR LN.F1
        add_draw_line_command(
            .Line1,
            line_1_color,
            FAST_LINE_1_NUM_SEGMENTS,
            line_position,
            game_state,
        );

        //@                ; lower left edge
        //@    JSR LN.F2
        add_draw_line_command(
            .Line2,
            line_2_color,
            FAST_LINE_2_NUM_SEGMENTS,
            line_position,
            game_state,
        );

        //@    LDA FC.HST    ; upper right edge
        //@    ADD #CT.XSZ
        //@    STA LN.HCR
        //@    LDA FC.VST
        //@    SUB #CT.XSZ
        //@    STA LN.VCR
        line_position = game_state.face_position + V2{ 4, -4 };
        //@    BIT BL.URE
        //@    IFMI
        if (game_state.castle_block_is_upper_right_edge_hidden) {
            //@     JSR LN.F2
            add_draw_line_command(
                .Line2,
                line_2_color,
                FAST_LINE_2_NUM_SEGMENTS,
                line_position,
                game_state,
            );
            //@    ENDIF
        }
        //@;  upper corner pixel
        //@    BIT BL.UCR
        //@    IFMI
        if (game_state.castle_block_is_upper_corner_hidden) {
            //@     LDA LN.HCR
            //@     SUB #CT.YSZ
            //@     STA XB
            //@     DEC LN.VCR
            //@     DEC LN.VCR
            line_position[1] -= 2;
            //@     TRAM LN.VCR YB
            const pixel_position = line_position - V2{ 8, 0 };
            //@     TRAM FC.BVB VB
            add_draw_pixel_command(
                line_2_color,
                pixel_position,
                game_state,
            );
        }
        //@    ENDIF
    }
    //@    RTS
}
fn draw_tunnel(game_state: *GameState) void {
    _ = game_state;
    //TODO
    unreachable;
}
//@ ;------------------------
//@ ; routine to clear screen
//@ GR.SCL:
fn clear_screen(game_state: *GameState) void {
    //@     JSR GR.MCL    ;  clear motion objects
    clear_motion_objects(game_state);
    add_draw_command(.{
        .shape = .ClearEntireScreen,

        //unused
        .position = undefined,
        .color = undefined,
    }, game_state);
    next_frame(game_state);
}
//@ ;------------------------
//@ ; routine to clear screen
//@ GR.SCL:
fn clear_screen_old(game_state: *GameState) void {
    //@     JSR GR.MCL    ;  clear motion objects
    clear_motion_objects(game_state);

    //@ ;  bit-map too
    //@ ;    LDY #0    ;  GR.MCL set Y to 0
    //@     STY HW.AY
    //@     STY TEMP1
    var temp1: u8 = 0;
    //@      DEY
    //@     STY HW.YIN

    //@     LDA #00F
    //@ 5$:
    while (true) {
        //@     LDY #40
        var i: isize = 0x40;
        //@     LDX TEMP1
        //@     STX XB
        const x: Dimension = temp1;
        var y: Dimension = 0xFF;
        //@ 10$:
        while (true) {
            //@     .REPT 4
            for (0..4) |_| {
                //@     STA VB
                add_draw_command(.{
                    .shape = .Pixel,
                    .position = .{ x, y },
                    .color = .Black,
                }, game_state);
                y -= 1;
                //@     .ENDM
            }
            //@     DEY
            i -= 1;
            //@     BNE 10$
            if (i == 0) {
                break;
            }
        }
        //@     JSR MN.HOU    ;  housekeeping
        //@     DEC TEMP1
        temp1 -%= 1;
        //@     BNE 5$
        if (temp1 == 0) {
            break;
        }
    }

    //@     TRAI 0FF HW.AY
    //@     RTS
}
//@ ;-------------------------
//@ ;  hide all motion objects
//@ GR.MCL:
fn clear_motion_objects(game_state: *GameState) void {
    for (&game_state.motion_objects) |*mo| {
        mo.* = .{};
    }
    //@     TR16AI MT.BU1 MT.PTR
    //@     JSR GR.MC1
    //@     TR16AI MT.BU0 MT.PTR
    //@     JSR GR.MC1
    //@ ; (Y)=0
    //@     RTS
    //@ GR.MC1:
    //@     LDY #28*4
    //@     BEGIN
    //@     DEY
    //@      TRAI 0F0 @MT.PTR(Y)
    //@      TYA
    //@     EQEND
    //@ ; (Y)=0
    //@     RTS
}
fn next_frame(game_state: *GameState) void {
    if (game_state.debug_should_not_yield) {
        return;
    }
    //TODO: system advance to only yield once a certain state is reacjhed
    fiber.yield();
}

inline fn add_draw_line_command(
    shape: DrawCommand.Shape,
    color: Color,
    number_of_segments: isize,
    position: V2,
    game_state: *GameState,
) void {
    add_draw_command(.{
        .shape = shape,
        .color = color,
        .number_of_segments = number_of_segments,
        .position = position,
    }, game_state);
}
inline fn add_draw_character_command(
    character: u8,
    color: Color,
    position: V2,
    game_state: *GameState,
) void {
    add_draw_command(.{
        .shape = .Character,
        .color = color,
        .character = character,
        .position = position,
    }, game_state);
}
inline fn add_draw_pixel_command(
    color: Color,
    position: V2,
    game_state: *GameState,
) void {
    add_draw_command(.{
        .shape = .Pixel,
        .color = color,
        .position = position,
    }, game_state);
}

fn add_draw_command(
    command: DrawCommand,
    game_state: *GameState,
) void {

    //NOTE: 200 is arbitrarily chosen
    const MAX_DRAW_COMMANDS_PER_FRAME = 200;
    if (game_state.number_of_draw_commands_this_frame >= MAX_DRAW_COMMANDS_PER_FRAME) {
        //TODO: add command to clear screen
        // if (game_state.draw_command_queue.is_full()) {
        flush_draw_command_queue(game_state);
    }
    const position = command.position;
    if (command.shape != .ClearEntireScreen and (position[0] < 0 or position[0] >= SCREEN_WIDTH or
        position[1] - Y_COORDINATE_OFFSET < 0 or
        position[1] - Y_COORDINATE_OFFSET >= SCREEN_HEIGHT))
    {
        toolbox.println(
            "draw commmand out of bounds: {}.  Discarding...",
            .{position},
        );
        return;
    }
    toolbox.assert(
        command.shape != .Character or command.character >= ' ',
        "Bad character value: {}",
        .{command.character},
    );

    var command_copy = command;
    command_copy.position[1] -= Y_COORDINATE_OFFSET;
    game_state.draw_command_queue.enqueue_expecting_room(
        command_copy,
    );

    // const MAX_DRAW_COMMANDS_PER_FRAME = game_state.draw_command_queue.data.len - 1;
    game_state.number_of_draw_commands_this_frame += 1;

    // if (game_state.number_of_draw_commands_this_frame >=
    //     MAX_DRAW_COMMANDS_PER_FRAME)
    // {
    //     flush_draw_command_queue(game_state);
    // }
}

fn flush_draw_command_queue(game_state: *GameState) void {
    if (game_state.number_of_draw_commands_this_frame > 0) {
        //NOTE: next_frame doesn't work if we are currently disabled by debug_should_not_yield
        //      So must be fiber.yield()
        // next_frame(game_state);
        fiber.yield();
        game_state.number_of_draw_commands_this_frame = 0;
    }
}

fn to_isize(comptime n: comptime_int) isize {
    if (n & 0x80 != 0) {
        return @as(isize, @as(i8, @bitCast(@as(u8, n))));
    }
    return @as(isize, n);
    // return n;
}

//8-bit unsigned >=
inline fn u8gte(a: isize, b: isize) bool {
    return (a & 0xFF) >= (b & 0xFF);
}
//8-bit unsigned <
inline fn u8lt(a: isize, b: isize) bool {
    return (a & 0xFF) < (b & 0xFF);
}

fn check_and_display_atari_easter_egg() void {
    //TODO
}
