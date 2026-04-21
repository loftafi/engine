pub const Event = @This();

type: enum {
    unknown,
    key_up,
    key_down,
    mouse_up,
    mouse_down,
    mouse_enter,
    mouse_exit,
} = .unknown,

pub inline fn isKeyboardEvent(event: *const Event) bool {
    return event.type == .key_up or event.type == .key_down;
}
