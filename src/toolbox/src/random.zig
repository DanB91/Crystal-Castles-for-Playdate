const toolbox = @import("toolbox.zig");

pub const RandomState = u32;
pub fn init_random(seed: u32) RandomState {
    return seed;
}
pub fn random32(state: *RandomState) u32 {
    state.* +%= 0x6D2B79F5;
    var z = state.*;
    z = (z ^ z >> 15) *% (1 | z);
    z ^= z +% (z ^ z >> 7) *% (61 | z);
    return z ^ z >> 14;
}

pub fn randomf_range(comptime min: comptime_float, comptime max: comptime_float, state: *RandomState) f32 {
    const value_int = (random32(state) >> 9) | 0x3F80_0000;
    var value: f32 = @bitCast(value_int);
    value -= 1;
    const result = min + ((value - 0) * (max - min) / (1 - 0));
    return result;
}
