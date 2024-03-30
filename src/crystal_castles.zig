const toolbox = @import("toolbox");
const std = @import("std");

pub const SCREEN_WIDTH = 256;
pub const SCREEN_HEIGHT = 232;
pub const FAST_LINE_1_NUM_SEGMENTS = 4;
pub const FAST_LINE_2_NUM_SEGMENTS = 8;

const level_data = @embedFile("levels.bin");

//The game was designed around the fact that VBlank happend between
//scanlines 0-0x17 (inclusive), where nothing could be drawn to the screen.
//Thus, only values 0x18-0xFF were drawable Y coordinates.
//We need to take this into account here.
pub const Y_COORDINATE_OFFSET = 0x18;

//A "wave" is a sub-division of a "level".
//There are 4 waves per level except level 10 which only has 1 wave
//You can kind of think of a "wave" as Super Mario Bros level and
//a "level" as a  Super Mario Bros world.
const WAVE_DATA_SIZE = 0x400;

pub const Dimension = isize;
pub const V2 = @Vector(2, Dimension);
pub const Color = enum(u8) {
    White,
    Red,
    Gray,
    DarkGray,
    Black,
};
const DrawCommand = struct {
    shape: Shape,
    number_of_segments: isize = 0, //only used for lines
    position: V2,
    color: Color,

    const Shape = enum { None, Line1, Line2, Line3, Pixel };
};
pub const GameState = struct {
    draw_command_queue: toolbox.RingQueue(DrawCommand),
    global_arena: *toolbox.Arena,
    rng_state: toolbox.RandomState,

    current_state: enum {
        DrawBackground,
        DrawCastle,
        DrawCastleRow,
        DoneDrawingCastle,
    } = .DrawBackground,

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

    wave_scroll_flag: enum { NoScroll, Right, Left, Up } = .NoScroll, //WV.SCF

    game_time: toolbox.Duration = .{}, //ST.TIM
    next_extra_life: isize = 0, //SC.NEL

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

    has_tunnel: bool = false, //CT.TUN

    current_wave_data: [WAVE_DATA_SIZE]u8 = undefined,
};

pub fn init(game_state: *GameState, global_arena: *toolbox.Arena) void {
    const draw_line_command_queue =
        toolbox.RingQueue(DrawCommand).init(10_000, global_arena);
    game_state.global_arena = global_arena;
    game_state.draw_command_queue = draw_line_command_queue;

    reset(game_state);
}

pub fn reset(game_state: *GameState) void {
    const draw_line_command_queue = game_state.draw_command_queue;
    //TODO: put back
    // const rand = toolbox.init_random(@bitCast(toolbox.now().microseconds()));
    const rand = toolbox.init_random(1);
    game_state.* = .{
        .global_arena = game_state.global_arena,
        .draw_command_queue = draw_line_command_queue,
        .rng_state = rand,
    };
    game_state.draw_command_queue.clear();

    initialize_sounds();
    initialize_high_scores();
    initialize_wave_data(game_state);
}

pub fn update(dt: toolbox.Duration, game_state: *GameState) void {
    switch (game_state.current_state) {
        .DrawBackground => {
            const BACKGROUND_ANIMATION_MS_PER_SCANLINE = 720 / SCREEN_HEIGHT;
            if (game_state.background_clip_y >= SCREEN_HEIGHT) {
                initialize_castle(game_state);
                game_state.current_state = .DrawCastle;
                return;
            }
            game_state.background_animation_time_since_last_scanline.ticks += dt.ticks;
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
        },
        .DrawCastle => {
            compute_castle(game_state);
            game_state.current_state = .DrawCastleRow;
        },
        .DrawCastleRow => {
            compute_castle_row(game_state);
            game_state.castle_row_count -= 1;
            if (game_state.castle_row_count < 0) {
                game_state.current_state = .DoneDrawingCastle;
                return;
            }
            advance_castle_row(game_state);
        },
        .DoneDrawingCastle => {},
    }
}

//MN.SNI
fn initialize_sounds() void {
    //TODO:
}

//RS.INI
fn initialize_high_scores() void {
    //TODO
}

//WV.INI
fn initialize_wave_data(game_state: *GameState) void {
    //NOTE: all handled in initialization of GameState object
    {
        // LDA #0
        // STA WV.XCO
        // STA WV.XCD
        // STA WV.YCO
        // STA WV.YCD
        // STA WV.EOG

        // STA ST.TIM	;  init game time
        // STA 1+ST.TIM

        // STA WV.SCF	;  don't scroll yet
    }

    {
        // LDA #7
        // LDX EEEXTR
        //TODO make configurable
        const EXTRA_LIVES_OPTIONS = 0;
        // IFNE
        //  LDA #099
        // ENDIF
        // STA SC.NEL	;  next extra life at 70000

        if (EXTRA_LIVES_OPTIONS != 0) {
            game_state.next_extra_life = 0x99;
        } else {
            game_state.next_extra_life = 7;
        }
    }

    // JSR WV.CMP
    compute_wave_parameters(game_state);

    //TODO
    // JSR MT.INI		; init motion objects

}

// ;-------------------------------------------
// ;  compute wave parameters, given game_state.wave_xco and game_state.wave_yco
fn compute_wave_parameters(game_state: *GameState) void {

    //     JSR DF.UPD
    update_current_wave_and_difficulty(game_state);

    //already done in initialize_castle()
    {
        // ;  compute WV.OFF,  this assumes WV.SIZ=400
        // 	TRAI 0 WV.OFF
        // 	LDA WV.NUM
        // 	ASLS 2
        // 	STA WV.OFF+1
    }

    // 	JSR CL.UPD
    update_colors(game_state);

    //TODO.  We may not need to implement WV.MNM if its always dependent on WV.NUM
    {
        // ;  update message pointer
        // 	LDA WV.NUM
        // 	STA WV.MNM
        // 	TRAI 0FF WV.MFL
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
    // 	LDA WV.XCO
    // ASLS 2
    // ADD WV.YCO	;  wave number index
    // TAX
    const wave_number_table_index = game_state.wave_xco * 4 + game_state.wave_yco;
    // LDA WV.TAB(X)
    // TAY
    // AND #0F
    // STA WV.NUM
    game_state.wave_current = WAVE_NUMBER_TABLE[@intCast(wave_number_table_index)] & 0xF;

    //NOTE: handled in GameState initialization
    //     ;  compute regions
    // 	LDA #0
    // 	STA CT.HR1
    // 	STA CT.HR2
    // 	STA CT.HR3

    // 	LDX #0FF

    // 	TYA
    // 	AND #30
    // 	IFEQ		;  if both reg 1 and 2 off
    // 	 		; turn off only one of them
    if (wave_number_table_index & 0x30 == 0) {
        // 	 LDA RANDOM
        const r: i32 = @bitCast(toolbox.random32(&game_state.rng_state));
        // 	 IFMI
        // 	  STX CT.HR1
        // 	 ELSE
        // 	  STX CT.HR2
        // 	 ENDIF
        if (r < 0) {
            game_state.castle_region_1 = -1;
        } else {
            game_state.castle_region_2 = -1;
        }
        // 	ELSE
        // 	 TYA
        // 	 AND #10
    } else if (wave_number_table_index & 0x10 == 0) {

        // 	 IFEQ
        // 	  STX CT.HR1
        // 	 ENDIF

        game_state.castle_region_1 = -1;
        // 	 TYA
        // 	 AND #20
        // 	 IFEQ
    } else if (wave_number_table_index & 0x20 == 0) {
        // 	  STX CT.HR2
        game_state.castle_region_2 = -1;
        // 	 ENDIF
        // 	ENDIF

    }
    // 	TYA
    // 	AND #0C0
    // 	IFEQ
    if (wave_number_table_index & 0xC0 == 0) {
        // 	 STX CT.HR3
        game_state.castle_region_3 = -1;
        // 	ELSE
        // 	 CMP #0C0
        // 	 IFEQ
    } else if (wave_number_table_index == 0xC0) {
        // 	  LDA RANDOM
        // 	  AND #1F	;  0 to 31
        // 	 STA CT.HR3
        game_state.castle_region_3 = @intCast(toolbox.random32(&game_state.rng_state) & 0x1F);
    } else {
        // 	 ELSE
        // 	  LDA #0
        // 	 STA CT.HR3
        game_state.castle_region_3 = 0;
        // 	 ENDIF
    }
    // 	ENDIF

    // ;  compute difficulties
    // 	LDA WV.XCO
    // 	CMP #04
    // 	IFCS
    //  	 LDA #03
    // 	ENDIF
    // 	ASLS 2
    // 	ADD WV.YCO
    // 	STA WV.DF1	;  short term difficulty
    game_state.wave_short_term_difficulty =
        @min(3, game_state.wave_xco) * 4 +
        game_state.wave_yco;

    // 	LDA WV.XCO
    // 	CMP #09		;  max out at level 10
    // 	IFCS
    // 	 LDA #09
    // 	ENDIF
    // 	STA WV.DF2	;  long term difficulty
    game_state.wave_long_term_difficulty = @min(9, game_state.wave_xco);

    // 	TAY
    // ;  difficulty offset

    // 	LDA EEDIFF
    //TODO make configurable
    const CONFIGURED_DIFFICULTY_OFFSET = 0;

    // 	AND #03
    var difficulty_offset: isize = CONFIGURED_DIFFICULTY_OFFSET & 3;

    // 	CMP #3
    // 	IFEQ
    // 	 LDA #0FF
    // 	ENDIF
    if (difficulty_offset == 3) {
        difficulty_offset = -1;
    }

    // 	CPY #5
    // 	IFCS
    // 	 LDA #0		;  all are equal starting at level 6
    // 	ENDIF
    if (game_state.wave_xco >= 5) {
        difficulty_offset = 0;
    }

    // 	STA WV.DFO
    game_state.wave_difficulty_offset = difficulty_offset;
}
//CL.UPD
fn update_colors(game_state: *GameState) void {
    //TODO
    _ = game_state;
}

//CT.INI
fn initialize_castle(game_state: *GameState) void {
    const wave_data = &game_state.current_wave_data;

    //should be equvalent to WV.OFF
    const wave_data_offset: usize = @intCast(game_state.wave_current * WAVE_DATA_SIZE);
    @memcpy(
        wave_data,
        level_data[wave_data_offset .. wave_data_offset + WAVE_DATA_SIZE],
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
                // LDA @CT.A2L(Y)
                // AND #3

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
                        //  LDA @CT.A2L(Y)
                        //  AND #^B11101111
                        //  STA @CT.A2L(Y)	;  no gems when height=0
                        game_state.current_wave_data[game_state.castle_a2l] &=
                            0b11101111;
                        // LDA #0
                        // STA @CT.ADL(Y)
                        game_state.current_wave_data[game_state.castle_adl] = 0;
                    } else {
                        // ADD @CT.ADL(Y)
                        // STA @CT.ADL(Y)
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
    //TODO:
    //put in tunnel for warp
    //also put in high score initials
    // if (game_state.wv_xco == 0 and game_state.wv_yco == 0) {
    //     game_state.temp4 = 4;
    //     while (game_state.temp4 <= 0) : (game_state.temp4 -= 1) {
    //         //CT.HIN
    //         //put in initial
    //         {
    //             //TODO
    //         }
    //     }

    //     if (game_state.warp_level > 0 and !game_state.attract_mode) {
    //         //Don't care about this right now
    //     }
    // }
}
//CR.INI
fn initialize_castle_row(game_state: *GameState) void {
    //TR16AI CTRAM+CT.YDM+4 CT.ADL
    game_state.castle_adl = 0 + 0x13 + 0x4; //0x17
    //TRAI CT.HST CR.HST
    //TRAI CT.VST CR.VST
    game_state.castle_row_position = .{ 0x5C, 0x86 };

    // TRAI CT.XDM CT.CNT
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
    // LDY #0
    // TRAM @CT.ADL(Y) BL.HEI
    //When this is first called after initialize_city_row()
    //this gets the 0x17th byte of the current wave data.
    //For wave 0, this value is 4.
    game_state.castle_block_height = game_state.current_wave_data[game_state.castle_adl];

    // TR16AM CT.ADL,CT.A2L
    // AD16AI CT.A2L,16*16
    game_state.castle_a2l = game_state.castle_adl + 0x16 * 0x16; //offset of 0x1E4;
    //The above line results in  game_state.castle_a2l having the value 0x1FB in the
    //first iteration of this loop
}
// BL.ADV:
// ;  advance to next block
fn advance_block(game_state: *GameState) void {
    // LDA BL.HST
    // ADD #CT.YSZ
    // STA BL.HST
    // INC BL.VST
    // INC BL.VST
    game_state.castle_block_position += .{ 8, 2 };
}
//CR.ADV
fn advance_castle_row(game_state: *GameState) void {
    // LDA CR.HST
    // SUB #CT.XSZ
    // STA CR.HST
    // LDA CR.VST
    // ADD #CT.XSZ
    // STA CR.VST
    game_state.castle_row_position += .{ -4, 4 };
}
//CT.DRW
fn compute_castle(game_state: *GameState) void {
    // ;  traverse through rows
    // TR16AI CTRAM CT.ACL
    game_state.castle_acl = 0;
    // TR16AI CTRAM+1 CT.ARL
    game_state.castle_arl = 1;
    // TR16AI CTRAM+2 CT.AFL
    game_state.castle_afl = 2;
    // TR16AI CTRAM+CT.YDM+3 CT.ALL
    game_state.castle_all = 0 + 0x13 + 0x3; //0x16

    initialize_castle_row(game_state);

    // while (true) {
    //     compute_castle_row(game_state);
    //     game_state.castle_row_count -= 1;
    //     if (game_state.castle_row_count < 0) {
    //         break;
    //     }
    //     advance_castle_row(game_state);
    // }
}

//CR.DRW
fn compute_castle_row(game_state: *GameState) void {
    initialize_block(game_state);
    const wave_data = &game_state.current_wave_data;

    while (true) {
        initialize_block_2(game_state);
        {
            // ;   compute if necessary to draw face1,face2
            // TR16AM CT.ADL CT.ADB	; square before ADL X dir
            // INC16 CT.ADB
            game_state.castle_adb = game_state.castle_adl + 1;
            // TRAM @CT.ADB(Y) TEMP1
            //NOTE: Y is set to 0 in initialize_block_2();
            const next_block_height = wave_data[game_state.castle_adb];

            // LDA BL.HEI
            // SUB TEMP1
            const height_difference = game_state.castle_block_height - next_block_height;
            if (height_difference < 0) {
                //  LDA BL.VST
                //  SUB BL.HEI
                //  STA BL.V1S
                game_state.castle_block_v1s = game_state.castle_block_position[1] -
                    game_state.castle_block_height;
                //  TRAI 0 BL.V1N
                game_state.castle_block_v1n = 0;
            } else {
                //  STA BL.V1N
                game_state.castle_block_v1n = height_difference;

                //  LDA BL.VST
                //  SUB TEMP1
                //  STA BL.V1S
                game_state.castle_block_v1s = game_state.castle_block_position[1] -
                    next_block_height;
            }
        }
        {
            //TR16AM CT.ADL CT.ADB	; square before ADL Y dir
            // AD16AI CT.ADB 16
            game_state.castle_adb = game_state.castle_adl + 0x16;

            // TRAM @CT.ADB(Y) TEMP1
            //NOTE: Y is set to 0 in initialize_block_2();
            const next_block_height = wave_data[game_state.castle_adb];

            // LDA BL.HEI
            // SUB TEMP1
            const height_difference = game_state.castle_block_height - next_block_height;
            if (height_difference < 0) {
                //  LDA BL.VST
                //  SUB BL.HEI
                //  STA BL.V2S
                game_state.castle_block_v2s = game_state.castle_block_position[1] -
                    game_state.castle_block_height;
                //  TRAI 0 BL.V2N
                game_state.castle_block_v2n = 0;
            } else {
                //  STA BL.V2N
                game_state.castle_block_v2n = height_difference;
                //  LDA BL.VST
                //  SUB TEMP1
                //  STA BL.V2S
                game_state.castle_block_v2s = game_state.castle_block_position[1] -
                    next_block_height;
            }
        }
        //;  priority
        // LDY #0
        // LDA @CT.A2L(Y)
        // JSR CL.PR
        set_bitmap_values_of_faces(
            wave_data[game_state.castle_a2l],
            game_state,
        );
        // ; accessibility
        // LDA @CT.A2L(Y)
        // AND #4
        // IFNE
        //  LDA FC.BV3
        // ELSE
        //  LDA FC.BVC
        // ENDIF
        // STA CT.BV3
        game_state.face3_color_value_hidden_or_not = if ((wave_data[game_state.castle_a2l] & 0x4) != 0)
            game_state.face_color_values[0] //yes, this is FC.BV3
        else
            game_state.face_color_values[4]; //this is FC.BVC

        //;  tunnel
        // LDA @CT.A2L(Y)
        // AND #20
        // STA CT.TUN
        game_state.has_tunnel = wave_data[game_state.castle_a2l] & 0x20 != 0;

        // JSR BL.EDT
        determine_edge_switches(game_state);

        if (game_state.castle_block_height != 0) {
            compute_block(game_state);
        }

        // 	INC16 CT.ADL
        game_state.castle_adl += 1;

        // 	DEC CR.CNT
        game_state.castle_block_count -= 1;
        if (game_state.castle_block_count < 0) {
            break;
        }
        advance_block(game_state);
    }
    // ; increment ADL,ACL,ARL,AFL,ALL twice

    // 	INC16 CT.ADL
    // 	INC16 CT.ADL
    game_state.castle_adl += 2;
    // 	INC16 CT.ACL
    // 	INC16 CT.ACL
    game_state.castle_acl += 2;
    // 	INC16 CT.ARL
    // 	INC16 CT.ARL
    game_state.castle_arl += 2;
    // 	INC16 CT.AFL
    // 	INC16 CT.AFL
    game_state.castle_afl += 2;
    // 	INC16 CT.ALL
    // 	INC16 CT.ALL
    game_state.castle_all += 2;
}
//BL.DRW
fn compute_block(game_state: *GameState) void {
    //  TRAM BL.HST FC.HST
    // TRAM BL.VST FC.VST
    game_state.face_position = game_state.castle_block_position;

    // TRAM BL.V1S FC.V1S
    // TRAM BL.V1N FC.V1N
    game_state.face_v1s = game_state.castle_block_v1s;
    game_state.face_v1n = game_state.castle_block_v1n;
    // JSR FACE1
    compute_face1(game_state);

    // TRAM BL.V2S FC.V2S
    // TRAM BL.V2N FC.V2N
    game_state.face_v2s = game_state.castle_block_v2s;
    game_state.face_v2n = game_state.castle_block_v2n;
    // JSR FACE2
    compute_face2(game_state);

    // LDA FC.VST
    // SUB BL.HEI
    // STA FC.VST
    game_state.face_position[1] -= game_state.castle_block_height;
    // JSR FACE3
    compute_face3(game_state);

    // LDA CT.TUN
    // IFNE
    //  JSR FC.TUN
    // ENDIF
    if (game_state.has_tunnel) {
        compute_tunnel(game_state);
    }
}
//CL.PR
fn set_bitmap_values_of_faces(face: u8, game_state: *GameState) void {
    // EOR #80
    // ORA #0F
    // AND #8F

    var face_tmp = ((face ^ 0x80) | 0x0F) & 0x8F;
    //LDY #7
    var i: isize = 7;
    // BEGIN
    while (i > 0) : (i -= 1) {
        //  SUB #10
        face_tmp -%= 0x10;
        //  STA FC.BV-1(Y)
        game_state.face_color_values[@intCast(i - 1)] = face_tmp;
        //  DEY
        // EQEND

    }
}
fn color_value_to_color(color_value: u8) Color {
    //TODO: figure out when Red is drawn
    // if (color_value & 0x20 != 0) {
    //     return .Red;
    // }

    //Only top 4 bits are used
    return switch ((color_value >> 4) & 0xF) {
        0x9, 0x1 => .White,
        0xA, 0x2 => .Gray,
        0xB, 0x3 => .DarkGray,
        0xC, 0x4 => .Black,
        0xD => .Red,
        else => unreachable,
        // 0...0x9 => .White,
        // 0xA...0xC => .Gray,
        // else => .Black,
    };
}

// ;------------------------------------
// ;  routine to determine edge switches
// BL.EDT
fn determine_edge_switches(game_state: *GameState) void {
    //TODO:
    const wave_data = game_state.current_wave_data;
    const adl = game_state.castle_adl;

    //  LDY #0
    // 	JSR BL.URC
    game_state.castle_block_is_upper_right_edge_hidden =
        wave_data[adl] != wave_data[game_state.castle_arl];

    // 	JSR BL.ULC
    game_state.castle_block_is_upper_left_edge_hidden =
        wave_data[adl] != wave_data[game_state.castle_all];
    // 	BIT BL.URE
    // 	BMI 10$
    // 	BIT BL.ULE
    // 	BMI 10$
    if (!game_state.castle_block_is_upper_right_edge_hidden and
        !game_state.castle_block_is_upper_left_edge_hidden)
    {
        // 	JSR BL.UCC
        game_state.castle_block_is_upper_corner_hidden =
            wave_data[adl] != wave_data[game_state.castle_acl];
        // 	JMP 20$
    } else {
        // 10$:	TRAI 0FF BL.UCR
        game_state.castle_block_is_upper_corner_hidden = true;
    }
    // 20$:
    // 	JSR BL.HRC
    calculate_hidden_right_line(game_state);

    // 	JSR BL.HLC
    calculate_hidden_left_line(game_state);

    // 	INC16 CT.ACL
    game_state.castle_acl += 1;
    // 	INC16 CT.ARL
    game_state.castle_arl += 1;
    // 	INC16 CT.AFL
    game_state.castle_afl += 1;
    // 	INC16 CT.ALL
    game_state.castle_all += 1;
}
// ;-----------------------------
// ;  calculate right hidden line
// ;  HES HEL start and length of hidden edge
// BL.HRC:
fn calculate_hidden_right_line(game_state: *GameState) void {
    const wave_data = game_state.current_wave_data;
    const adl = game_state.castle_adl;
    const arl = game_state.castle_arl;
    const afl = game_state.castle_afl;
    // 	LDA #0FF
    // 	STA BL.HRE
    game_state.castle_block_is_right_edge_hidden = true;

    // 	CMPIN CT.ADL,CT.ARL
    // 	BCC 10$
    if (wave_data[adl] < wave_data[arl]) {
        // 10$:	CMPIN CT.ADL,CT.AFL
        // 	BCS 30$
        if (wave_data[adl] >= wave_data[afl]) {
            // 30$:	TRAM @CT.AFL(Y) BL.HES	; cases 3 and 5
            // 	INC BL.HES
            game_state.castle_block_hidden_edge_start =
                wave_data[afl] + 1;

            // 	TRAM FC.BV1 FC.COH
            game_state.face_hidden_edge_color_value =
                game_state.face_color_values[2];
            // 	LDA NY,CT.ADL
            // 35$:
            // 	SUB @CT.AFL(Y)
            // 	JMP 25$
            // 25$:	STA BL.HEL
            // 	DEC BL.HEL
            // 	BMI 5$
            // 	DEC BL.HEL
            // 	BMI 5$
            game_state.castle_block_hidden_right_edge_length =
                @as(isize, @intCast(wave_data[adl])) -
                @as(isize, @intCast(wave_data[afl])) - 2;
            if (game_state.castle_block_hidden_right_edge_length < 0) {
                // 5$:	LDA #0
                // 	STA BL.HRE
                game_state.castle_block_is_right_edge_hidden = false;
            }
        }
        // 	BCC 5$		; BRA
        else {
            // 5$:	LDA #0
            // 	STA BL.HRE
            game_state.castle_block_is_right_edge_hidden = false;
        }
        return;
    }
    // 	CMPIN CT.AFL,CT.ARL
    // 	BCC 30$
    if (wave_data[afl] < wave_data[arl]) {
        // 30$:	TRAM @CT.AFL(Y) BL.HES	; cases 3 and 5
        // 	INC BL.HES
        game_state.castle_block_hidden_edge_start =
            wave_data[afl] + 1;

        // 	TRAM FC.BV1 FC.COH
        game_state.face_hidden_edge_color_value =
            game_state.face_color_values[2];
        // 	LDA NY,CT.ADL
        // 35$:
        // 	SUB @CT.AFL(Y)
        // 	JMP 25$
        // 25$:	STA BL.HEL
        // 	DEC BL.HEL
        // 	BMI 5$
        // 	DEC BL.HEL
        // 	BMI 5$
        game_state.castle_block_hidden_right_edge_length =
            wave_data[adl] - wave_data[afl] - 2;

        // 	BMI 5$
        if (game_state.castle_block_hidden_right_edge_length < 0) {
            // 5$:	LDA #0
            // 	STA BL.HRE
            game_state.castle_block_is_right_edge_hidden = false;
        }
        // 	RTS
        return;
    }
    game_state.castle_block_is_right_edge_hidden = false;

    //NOTE: this should all be implmented above
    // 	LDA #0FF
    // 	STA BL.HRE
    // 	CMPIN CT.ADL,CT.ARL
    // 	BCC 10$

    // 	CMPIN CT.AFL,CT.ARL
    // 	BCC 30$
    // ; cases 4 and 6,  no erase
    // 5$:	LDA #0
    // 	STA BL.HRE
    // 	RTS

    // 10$:	CMPIN CT.ADL,CT.AFL
    // 	BCS 30$
    // 	BCC 5$		; BRA
    // 			; cases 1 and 2 used to be here
    // 25$:	STA BL.HEL
    // 	BMI 5$
    // 	DEC BL.HEL
    // 	BMI 5$
    // 	DEC BL.HEL
    // 	BMI 5$
    // 	RTS

    // 30$:	TRAM @CT.AFL(Y) BL.HES	; cases 3 and 5
    // 	INC BL.HES
    // 	TRAM FC.BV1 FC.COH
    // 	CMPIN CT.ARL,CT.ADL
    // 	BCC 35$
    // 	LDA NY,CT.ADL
    // 35$:
    // 	SUB @CT.AFL(Y)
    // 	JMP 25$
}
// ;---------------------------
// ; calculate left hidden line
// BL.HLC:
fn calculate_hidden_left_line(game_state: *GameState) void {
    const wave_data = game_state.current_wave_data;
    const adl = game_state.castle_adl;
    const all = game_state.castle_all;
    //	LDA #0FF
    // 	STA BL.HLE
    game_state.castle_block_is_left_edge_hidden = true;

    // 	CMPIN CT.ADL,CT.ALL
    // 	BCC 10$		; erase line to min of ALL,ADL
    // 	LDA NY,CT.ALL
    // 10$:	STA BL.HLL
    // 	BEQ 40$
    // 	DEC BL.HLL
    // 	BEQ 40$
    // 	DEC BL.HLL
    // 	BEQ 40$
    game_state.castle_block_hidden_left_edge_length =
        @min(wave_data[adl], wave_data[all]);

    // 	RTS

    // 40$:	LDA #0
    // 	STA BL.HLE

    // 	RTS
    if (game_state.castle_block_hidden_left_edge_length - 2 <= 0) {
        game_state.castle_block_is_left_edge_hidden = false;
    } else {
        game_state.castle_block_hidden_left_edge_length -= 2;
    }
}
//FACE1:
fn compute_face1(game_state: *GameState) void {
    // TRAM FC.HST LN.HCR
    // TRAM FC.V1S LN.VCR
    var line_position = V2{
        game_state.face_position[0],
        game_state.face_v1s,
    };
    // TRAM FC.BV1 LN.CO1
    var color = color_value_to_color(game_state.face_color_values[2]);
    // TRAM FC.V1N CURLIN
    var current_line = game_state.face_v1n;
    while (true) {
        // JSR LN.F1
        add_draw_command(
            .Line1,
            color,
            FAST_LINE_1_NUM_SEGMENTS,
            line_position,
            game_state,
        );
        // DEC CURLIN
        current_line -= 1;
        // BMI 20$
        if (current_line < 0) {
            break;
        }
        // DEC LN.VCR
        line_position -= .{ 0, 1 };
    }
    //draw border
    //     BORDR1:
    {
        //  TRAM FC.BVB LN.CO1	; upper edge
        // 	STA LN.CO3
        const border_color_value = game_state.face_color_values[3];
        color = color_value_to_color(border_color_value);
        // 	JSR LN.F1
        add_draw_command(
            .Line1,
            color,
            FAST_LINE_1_NUM_SEGMENTS,
            line_position,
            game_state,
        );

        // 	TRAM FC.VST LN.VCR	; lower edge
        line_position[1] = game_state.face_position[1];
        // 	JSR LN.F1
        add_draw_command(
            .Line1,
            color,
            FAST_LINE_1_NUM_SEGMENTS,
            line_position,
            game_state,
        );

        // 	TRAM FC.V1N LN.LG3
        // 	LDA FC.HST		; right edge
        // 	ADD #CT.XSZ
        // 	STA LN.HCR

        // 	LDA FC.V1S
        // 	SUB #CT.XSZ
        // 	STA LN.VCR
        line_position = .{
            game_state.face_position[0] + 4, game_state.face_v1s - 4,
        };
        // 	JSR LN.3
        add_draw_command(
            .Line3,
            color,
            game_state.castle_block_v1n,
            line_position,
            game_state,
        );

        // ;  hidden edge
        // 	BIT BL.HRE
        // 	IFMI

        // 	 LDA FC.V1N
        // 	 IFNE

        if (game_state.castle_block_is_right_edge_hidden and
            game_state.face_v1n != 0)
        {
            // 	  TRAM BL.HEL LN.LG3
            // 	  TRAM FC.COH LN.CO3

            // 	  LDA FC.VST
            // 	  SUB #CT.XSZ
            // 	  SUB BL.HES
            //    STA LN.VCR
            line_position[1] =
                game_state.face_position[1] - 4 - game_state.castle_block_hidden_edge_start;

            const hidden_edge_color = color_value_to_color(game_state.face_hidden_edge_color_value);
            // 	  JSR LN.3
            add_draw_command(
                .Line3,
                hidden_edge_color,
                game_state.castle_block_hidden_right_edge_length,
                line_position,
                game_state,
            );
        }
        // 	 ENDIF
        // 	ENDIF
    }
}
//FACE2:
fn compute_face2(game_state: *GameState) void {
    //  TRAM FC.HST LN.HCR
    // 	TRAM FC.V2S LN.VCR
    var line_position = V2{
        game_state.face_position[0],
        game_state.face_v2s,
    };
    // 	TRAM FC.BV2 LN.CO2
    var color = color_value_to_color(game_state.face_color_values[1]);
    // 	TRAM FC.V2N CURLIN
    var current_line = game_state.face_v2n;

    while (true) {
        // 10$:	JSR LN.F2
        add_draw_command(
            .Line2,
            color,
            FAST_LINE_2_NUM_SEGMENTS,
            line_position,
            game_state,
        );
        // 	DEC CURLIN
        current_line -= 1;
        // 	BMI 20$
        if (current_line < 0) {
            break;
        }
        // 	DEC LN.VCR
        line_position -= .{ 0, 1 };
        // 	JMP 10$
    }
    // 20$:	JSR BORDR2

    //BORDR2:
    {
        //  TRAM FC.BVB LN.CO2	; upper line
        // 	STA LN.CO3
        const border_color_value = game_state.face_color_values[3];
        color = color_value_to_color(border_color_value);
        // 	JSR LN.F2
        add_draw_command(
            .Line2,
            color,
            FAST_LINE_2_NUM_SEGMENTS,
            line_position,
            game_state,
        );

        // 	TRAM FC.V2S LN.VCR	; lower line
        line_position[1] = game_state.face_v2s;
        // 	JSR LN.F2
        add_draw_command(
            .Line2,
            color,
            FAST_LINE_2_NUM_SEGMENTS,
            line_position,
            game_state,
        );

        // 	TRAM FC.V2S LN.VCR
        line_position[1] = game_state.face_v2s;
        // 	TRAM FC.V2N LN.LG3	; right vertical line
        const number_of_segments = game_state.face_v2n;
        // 	JSR LN.3
        add_draw_command(
            .Line3,
            color,
            number_of_segments,
            line_position,
            game_state,
        );

        // 	LDA FC.HST	; left vertical line
        // 	SUB #CT.YSZ
        // 	STA LN.HCR
        // 	LDA LN.VCR
        // 	SUB #CT.YSZ/4
        // 	STA LN.VCR
        line_position = .{
            game_state.face_position[0] - 8,
            line_position[1] - 2,
        };
        // 	JSR LN.3
        add_draw_command(
            .Line3,
            color,
            number_of_segments,
            line_position,
            game_state,
        );

        // ;  hidden edge
        // 	BIT BL.HLE
        // 	IFMI
        // 	 LDA FC.V2N
        // 	 IFNE

        if (game_state.castle_block_is_left_edge_hidden and
            game_state.face_v2n != 0)
        {
            // 	  LDA FC.VST
            // 	  SUB #CT.YSZ/4
            // 	  STA LN.VCR
            // 	  DEC LN.VCR
            line_position[1] = game_state.face_position[1] - 2 - 1;
            // 	  TRAM FC.BV2 LN.CO3
            color = color_value_to_color(game_state.face_color_values[1]);
            // 	  TRAM BL.HLL LN.LG3
            // 	  JSR LN.3
            add_draw_command(
                .Line3,
                color,
                game_state.castle_block_hidden_left_edge_length,
                line_position,
                game_state,
            );
        }
        // 	 ENDIF
        // 	ENDIF
        // 	RTS

    }
}
//FACE3:
fn compute_face3(game_state: *GameState) void {
    //TODO
    //  TRAI CT.XSZ LN.LG1
    var number_of_line_1_segments: isize = 4;
    // 	TRAI CT.YSZ CURLIN
    var number_of_lines: isize = 8;
    // 	TRAM FC.HST LN.HCR
    // 	TRAM FC.VST LN.VCR
    var line_position = game_state.face_position;
    // 	TRAM CT.BV3 LN.CO1
    var line_1_color = color_value_to_color(game_state.face_color_values[0]);

    // 10$:
    while (true) {
        // JSR LN.F1
        add_draw_command(
            .Line1,
            line_1_color,
            FAST_LINE_1_NUM_SEGMENTS,
            line_position,
            game_state,
        );
        // 	DEC CURLIN
        number_of_lines -= 1;

        // 	BMI 20$
        if (number_of_lines < 0) {
            break;
        }
        // 	DEC LN.HCR
        line_position[0] -= 1;

        // 	JSR LN.F1
        add_draw_command(
            .Line1,
            line_1_color,
            FAST_LINE_1_NUM_SEGMENTS,
            line_position,
            game_state,
        );

        // 	DEC CURLIN
        number_of_lines -= 1;
        // 	BMI 20$
        if (number_of_lines < 0) {
            break;
        }
        // 	DEC LN.HCR
        line_position[0] -= 1;

        // 	JSR LN.F1
        add_draw_command(
            .Line1,
            line_1_color,
            FAST_LINE_1_NUM_SEGMENTS,
            line_position,
            game_state,
        );
        // 	DEC CURLIN
        number_of_lines -= 1;
        // 	BMI 20$
        if (number_of_lines < 0) {
            break;
        }

        // 	DEC LN.VCR
        line_position[1] -= 1;

        // 	DEC LN.LG1
        number_of_line_1_segments -= 1;

        // 	JSR LN.1
        add_draw_command(
            .Line1,
            line_1_color,
            number_of_line_1_segments,
            line_position,
            game_state,
        );
        // 	INC LN.LG1
        number_of_line_1_segments += 1;

        // 	DEC LN.HCR
        line_position[0] -= 1;

        // 	JSR LN.F1
        add_draw_command(
            .Line1,
            line_1_color,
            FAST_LINE_1_NUM_SEGMENTS,
            line_position,
            game_state,
        );
        // 	DEC CURLIN
        number_of_lines -= 1;
        // 	BMI 20$
        if (number_of_lines < 0) {
            break;
        }
        // 	DEC LN.HCR
        line_position[0] -= 1;

        // 	JMP 10$
    }
    // 20$:	JSR BORDR3
    //BORDR3:
    {
        //  TRAM FC.BVB LN.CO1	; upper left edge
        line_1_color = color_value_to_color(game_state.face_color_values[3]);
        // 	STA LN.CO2
        const line_2_color = line_1_color;
        // 	BIT BL.ULE
        // 	IFMI
        if (game_state.castle_block_is_upper_left_edge_hidden) {
            // 	 JSR LN.F1
            add_draw_command(
                .Line1,
                line_1_color,
                FAST_LINE_1_NUM_SEGMENTS,
                line_position,
                game_state,
            );
        }
        // 	ELSE
        else {
            // 			; delete extraneous line
            // 	 TRAM CT.BV3 LN.CO1
            line_1_color = color_value_to_color(game_state.face_color_values[0]);
            // 	 DEC LN.LG1
            number_of_line_1_segments -= 1;
            // 	 JSR LN.1
            add_draw_command(
                .Line1,
                line_1_color,
                number_of_line_1_segments,
                line_position,
                game_state,
            );

            // 	 INC LN.LG1
            number_of_line_1_segments += 1;
            // 	 TRAM FC.BVB LN.CO1
            line_1_color = color_value_to_color(game_state.face_color_values[3]);
            // 	ENDIF
        }

        // 	TRAM FC.HST LN.HCR	; lower right edge
        // 	TRAM FC.VST LN.VCR
        line_position = game_state.face_position;
        // 	JSR LN.F1
        add_draw_command(
            .Line1,
            line_1_color,
            FAST_LINE_1_NUM_SEGMENTS,
            line_position,
            game_state,
        );

        // 				; lower left edge
        // 	JSR LN.F2
        add_draw_command(
            .Line2,
            line_2_color,
            FAST_LINE_2_NUM_SEGMENTS,
            line_position,
            game_state,
        );

        // 	LDA FC.HST	; upper right edge
        // 	ADD #CT.XSZ
        // 	STA LN.HCR
        // 	LDA FC.VST
        // 	SUB #CT.XSZ
        // 	STA LN.VCR
        line_position = game_state.face_position + V2{ 4, -4 };
        // 	BIT BL.URE
        // 	IFMI
        if (game_state.castle_block_is_upper_right_edge_hidden) {
            // 	 JSR LN.F2
            add_draw_command(
                .Line2,
                line_2_color,
                FAST_LINE_2_NUM_SEGMENTS,
                line_position,
                game_state,
            );
            // 	ENDIF
        }
        // ;  upper corner pixel
        // 	BIT BL.UCR
        // 	IFMI
        if (game_state.castle_block_is_upper_corner_hidden) {
            // 	 LDA LN.HCR
            // 	 SUB #CT.YSZ
            // 	 STA XB
            // 	 DEC LN.VCR
            // 	 DEC LN.VCR
            line_position[1] -= 2;
            // 	 TRAM LN.VCR YB
            const pixel_position = line_position - V2{ 8, 0 };
            // 	 TRAM FC.BVB VB
            add_draw_command(
                .Pixel,
                line_2_color,
                0,
                pixel_position,
                game_state,
            );
        }
        // 	ENDIF
    }
    // 	RTS
}
fn compute_tunnel(game_state: *GameState) void {
    _ = game_state;
    //TODO
    unreachable;
}

fn add_draw_command(
    shape: DrawCommand.Shape,
    color: Color,
    number_of_segments: isize,
    position: V2,
    game_state: *GameState,
) void {
    toolbox.assert(
        !(position[0] < 0 or position[0] >= SCREEN_WIDTH or
            position[1] - Y_COORDINATE_OFFSET < 0 or
            position[1] - Y_COORDINATE_OFFSET >= SCREEN_HEIGHT),
        "draw commmand out of bounds!",
        .{},
    );
    if (shape == .Line1 and color == .DarkGray and
        @reduce(
        .And,
        position == V2{ 0x5C, 0x82 },
    ) and
        number_of_segments == 3)
    {
        @breakpoint();
    }
    game_state.draw_command_queue.enqueue_expecting_room(
        .{
            .shape = shape,
            .color = color,
            .number_of_segments = number_of_segments,
            .position = position - V2{ 0, 0x18 },
        },
    );
}

fn check_and_display_atari_easter_egg() void {}
