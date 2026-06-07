const max_callbacks = 20;

/// Add or update the fields of an Entity by parsing the contents of a
/// string describing the contents to apply to that entity.
///
///     var entity = try readEntity(MyStruct, &my_struct,
///        \\panel name "coffee" image "cat"
///        \\minimum width=33 height=120
///        \\horizontal style tinted
///        \\on_resized "recalculate_speed"
///    )
///
/// Developer note: A three parameter option that declares the type
/// explicitly might be better. Undecided at this point.
///
///    pub fn readEntity(
///       comptime HandlerType: type, handler: *HandleType, data: []const u8
///    ) Error!?Entity {
pub fn readEntity(
    allocator: Allocator,
    data: []const u8,
    comptime HandlerType: type,
    handler: *HandlerType,
) (Error || Allocator.Error)!?Entity {
    var token: Token = try .init(data);
    return try readEntityTokens(allocator, &token, HandlerType, handler) orelse return null;
}

pub fn readEntityTokens(
    allocator: Allocator,
    token: *Token,
    comptime HandlerType: type,
    handler: *HandlerType,
) (Error || Allocator.Error)!?Entity {
    var buffer1: [max_callbacks]CallbackOption = undefined;
    var buffer2: [max_callbacks]StateCallbackOption = undefined;
    var buffer3: [max_callbacks]UpdateCallbackOption = undefined;
    var buffer4: [max_callbacks]BoolCallbackOption = undefined;

    const callbacks = callbackFunctionList(HandlerType, &buffer1);
    const state_callbacks = callbackStateFunctionList(HandlerType, &buffer2);
    const update_callbacks = callbackUpdateFunctionList(HandlerType, &buffer3);
    const bool_callbacks = callbackBoolFunctionList(HandlerType, &buffer4);

    errdefer {
        err("Unexpected token {t} at {d}.{d}: {s}", .{
            token.tag,
            token.begins.line,
            token.begins.column,
            token.slice(),
        });
    }
    if (token.tag == .eof) return null;
    var entity = readEntityType(token) catch return error.UnexpectedToken;
    //entity.setup(display);
    readAttributes(
        token,
        &entity,
        HandlerType,
        handler,
        callbacks,
        state_callbacks,
        update_callbacks,
        bool_callbacks,
    ) catch return error.UnexpectedToken;

    if (entity.type == .panel) {
        if (token.tag != .open_bracket) return entity;
        token.* = try token.next();
        while (token.tag != .close_bracket and token.tag != .eof) {
            const child = try readEntityTokens(allocator, token, HandlerType, handler);
            if (child == null) break;
            const c = try allocator.create(Entity);
            errdefer allocator.destroy(c);
            c.* = child.?;
            try entity.type.panel.children.append(allocator, c);
        }
        token.* = try token.next();
    }

    return entity;
}

/// Describes a function exposed to a UI at runtime
pub const CallbackOption = struct {
    f: *const fn (*anyopaque, *engine.Display, *Entity, *const engine.Event) error{OutOfMemory}!void,
    name: []const u8,
};

/// Return the name and pointer to all functions matching the Callback
/// function definition.
pub fn callbackFunctionList(t: type, list: []CallbackOption) []const CallbackOption {
    var count: usize = 0;
    inline for (@typeInfo(t).@"struct".decls) |decl| {
        const f = @field(t, decl.name);
        const info = @typeInfo(@TypeOf(f));
        if (info != .@"fn") continue;
        if (info.@"fn".params.len != 4) continue;
        if (info.@"fn".return_type == null) continue;
        if (@typeInfo(info.@"fn".return_type.?) != .error_union) continue;
        if (@typeInfo(info.@"fn".return_type.?).error_union.payload != void) continue;
        if (@typeInfo(info.@"fn".return_type.?).error_union.error_set != std.mem.Allocator.Error) continue;

        if (info.@"fn".params[0].type == null) continue;
        const t0 = @typeInfo(info.@"fn".params[0].type.?);
        if (t0 != .pointer) continue;
        const t0i = @typeInfo(t0.pointer.child);
        if (t0i != .@"struct") continue;

        if (info.@"fn".params[1].type == null) continue;
        const t1 = @typeInfo(info.@"fn".params[1].type.?);
        if (t1 != .pointer) continue;
        const t1i = @typeInfo(t1.pointer.child);
        if (t1i != .@"struct") continue;
        if (t1.pointer.child != engine.Display) continue;

        if (info.@"fn".params[2].type == null) continue;
        const t2 = @typeInfo(info.@"fn".params[2].type.?);
        if (t2 != .pointer) continue;
        const t2i = @typeInfo(t2.pointer.child);
        if (t2i != .@"struct") continue;
        if (t2.pointer.child != engine.Entity) continue;

        if (info.@"fn".params[3].type == null) continue;
        const t3 = @typeInfo(info.@"fn".params[3].type.?);
        if (t3 != .pointer) continue;
        const t3i = @typeInfo(t3.pointer.child);
        if (t3i != .@"struct") continue;
        if (t3.pointer.child != engine.Event) continue;

        list[count] = CallbackOption{ .name = decl.name, .f = @ptrCast(&f) };
        count += 1;
        if (count == max_callbacks) break;
    }
    return list[0..count];
}

fn findMatchingCallback(name: []const u8, options: []const CallbackOption) Error!*const fn (*anyopaque, *engine.Display, *Entity, *const engine.Event) error{OutOfMemory}!void {
    for (options) |option| {
        if (std.ascii.eqlIgnoreCase(name, option.name))
            return option.f;
    }
    return Error.UnexpectedToken;
}

/// Describes a function exposed to a UI at runtime
pub const UpdateCallbackOption = struct {
    f: *const fn (*anyopaque, *engine.Display, *Entity) void,
    name: []const u8,
};

/// Return the name and pointer to all functions matching the Callback
/// function definition.
pub fn callbackUpdateFunctionList(t: type, list: []UpdateCallbackOption) []const UpdateCallbackOption {
    var count: usize = 0;
    inline for (@typeInfo(t).@"struct".decls) |decl| {
        const f = @field(t, decl.name);
        const info = @typeInfo(@TypeOf(f));
        if (info != .@"fn") continue;
        if (info.@"fn".params.len != 4) continue;
        if (info.@"fn".return_type == null) continue;
        if (@typeInfo(info.@"fn".return_type.?) != .void) continue;

        if (info.@"fn".params[0].type == null) continue;
        const t0 = @typeInfo(info.@"fn".params[0].type.?);
        if (t0 != .pointer) continue;
        const t0i = @typeInfo(t0.pointer.child);
        if (t0i != .@"struct") continue;

        if (info.@"fn".params[1].type == null) continue;
        const t1 = @typeInfo(info.@"fn".params[1].type.?);
        if (t1 != .pointer) continue;
        const t1i = @typeInfo(t1.pointer.child);
        if (t1i != .@"struct") continue;
        if (t1.pointer.child != engine.Display) continue;

        if (info.@"fn".params[2].type == null) continue;
        const t2 = @typeInfo(info.@"fn".params[2].type.?);
        if (t2 != .pointer) continue;
        const t2i = @typeInfo(t2.pointer.child);
        if (t2i != .@"struct") continue;
        if (t2.pointer.child != engine.Entity) continue;

        list[count] = UpdateCallbackOption{ .name = decl.name, .f = @ptrCast(&f) };
        count += 1;
        if (count == max_callbacks) break;
    }
    return list[0..count];
}

fn findMatchingUpdateCallback(name: []const u8, options: []const UpdateCallbackOption) Error!*const fn (*anyopaque, *engine.Display, *Entity) void {
    for (options) |option| {
        if (std.ascii.eqlIgnoreCase(name, option.name))
            return option.f;
    }
    return Error.UnexpectedToken;
}

/// Describes a function exposed to a UI at runtime
pub const StateCallbackOption = struct {
    f: *const fn (*anyopaque, *engine.Display, *Entity) error{OutOfMemory}!void,
    name: []const u8,
};

/// Return the name and pointer to all functions matching the Callback
/// function definition.
pub fn callbackStateFunctionList(t: type, list: []StateCallbackOption) []const StateCallbackOption {
    var count: usize = 0;
    inline for (@typeInfo(t).@"struct".decls) |decl| {
        const f = @field(t, decl.name);
        const info = @typeInfo(@TypeOf(f));
        if (info != .@"fn") continue;
        if (info.@"fn".params.len != 4) continue;
        if (info.@"fn".return_type == null) continue;
        if (@typeInfo(info.@"fn".return_type.?) != .error_union) continue;
        if (@typeInfo(info.@"fn".return_type.?).error_union.payload != void) continue;
        if (@typeInfo(info.@"fn".return_type.?).error_union.error_set != std.mem.Allocator.Error) continue;

        if (info.@"fn".params[0].type == null) continue;
        const t0 = @typeInfo(info.@"fn".params[0].type.?);
        if (t0 != .pointer) continue;
        const t0i = @typeInfo(t0.pointer.child);
        if (t0i != .@"struct") continue;

        if (info.@"fn".params[1].type == null) continue;
        const t1 = @typeInfo(info.@"fn".params[1].type.?);
        if (t1 != .pointer) continue;
        const t1i = @typeInfo(t1.pointer.child);
        if (t1i != .@"struct") continue;
        if (t1.pointer.child != engine.Display) continue;

        if (info.@"fn".params[2].type == null) continue;
        const t2 = @typeInfo(info.@"fn".params[2].type.?);
        if (t2 != .pointer) continue;
        const t2i = @typeInfo(t2.pointer.child);
        if (t2i != .@"struct") continue;
        if (t2.pointer.child != engine.Entity) continue;

        list[count] = StateCallbackOption{ .name = decl.name, .f = @ptrCast(&f) };
        count += 1;
        if (count == max_callbacks) break;
    }
    return list[0..count];
}

fn findMatchingStateCallback(name: []const u8, options: []const StateCallbackOption) Error!*const fn (*anyopaque, *engine.Display, *Entity) error{OutOfMemory}!void {
    for (options) |option| {
        if (std.ascii.eqlIgnoreCase(name, option.name))
            return option.f;
    }
    return Error.UnexpectedToken;
}

/// Describes a function exposed to a UI at runtime
pub const BoolCallbackOption = struct {
    f: *const fn (*anyopaque, *engine.Display, *Entity) bool,
    name: []const u8,
};

/// Return the name and pointer to all functions matching the Callback
/// function definition.
pub fn callbackBoolFunctionList(t: type, list: []BoolCallbackOption) []const BoolCallbackOption {
    var count: usize = 0;
    inline for (@typeInfo(t).@"struct".decls) |decl| {
        const f = @field(t, decl.name);
        const info = @typeInfo(@TypeOf(f));
        if (info != .@"fn") continue;
        if (info.@"fn".params.len != 4) continue;
        if (info.@"fn".return_type == null) continue;
        if (@typeInfo(info.@"fn".return_type.?) != .error_union) continue;
        if (@typeInfo(info.@"fn".return_type.?).error_union.payload != void) continue;
        if (@typeInfo(info.@"fn".return_type.?).error_union.error_set != std.mem.Allocator.Error) continue;

        if (info.@"fn".params[0].type == null) continue;
        const t0 = @typeInfo(info.@"fn".params[0].type.?);
        if (t0 != .pointer) continue;
        const t0i = @typeInfo(t0.pointer.child);
        if (t0i != .@"struct") continue;

        if (info.@"fn".params[1].type == null) continue;
        const t1 = @typeInfo(info.@"fn".params[1].type.?);
        if (t1 != .pointer) continue;
        const t1i = @typeInfo(t1.pointer.child);
        if (t1i != .@"struct") continue;
        if (t1.pointer.child != engine.Display) continue;

        if (info.@"fn".params[2].type == null) continue;
        const t2 = @typeInfo(info.@"fn".params[2].type.?);
        if (t2 != .pointer) continue;
        const t2i = @typeInfo(t2.pointer.child);
        if (t2i != .@"struct") continue;
        if (t2.pointer.child != engine.Entity) continue;

        list[count] = BoolCallbackOption{ .name = decl.name, .f = @ptrCast(&f) };
        count += 1;
        if (count == max_callbacks) break;
    }
    return list[0..count];
}

fn findMatchingBoolCallback(name: []const u8, options: []const BoolCallbackOption) Error!*const fn (*anyopaque, *engine.Display, *Entity) bool {
    for (options) |option| {
        if (std.ascii.eqlIgnoreCase(name, option.name))
            return option.f;
    }
    return Error.UnexpectedToken;
}

/// Read Entity type and initialise the entity with default values.
pub fn readEntityType(token: *Token) Error!Entity {
    return switch (token.tag) {
        .button => .{ .focus = .can_focus, .type = .{ .button = .{ .text_size = .normal } } },
        .checkbox => .{ .focus = .can_focus, .type = .{ .checkbox = .{ .text_size = .normal } } },
        .expander => .{ .focus = .never_focus, .type = .{ .expander = .{} } },
        .label => .{ .focus = .accessibility_focus, .type = .{ .label = .{ .text_size = .normal } } },
        .panel => .{
            .texture = null,
            .background = .{ .image = null },
            .type = .{ .panel = .{ .children = .empty } },
        },
        .progress_bar => .{ .type = .{ .progress_bar = .{} } },
        .rectangle => .{ .type = .{ .rectangle = .{} } },
        .sprite => .{ .type = .{ .sprite = .{} } },
        .text_input => .{
            .minimum = .{ .height = TextSize.normal.size() },
            .focus = .can_focus,
            .type = .{ .text_input = .{
                .text_size = .normal,
                .text = .empty,
                .runes = .empty,
                .initial_text = null,
                .placeholder_text = null,
            } },
        },
        else => error.UnexpectedToken,
    };
}

pub fn readAttributes(
    token: *Token,
    entity: *Entity,
    HandlerType: type,
    handler: *HandlerType,
    callbacks: []const CallbackOption,
    state_callbacks: []const StateCallbackOption,
    update_callbacks: []const UpdateCallbackOption,
    bool_callbacks: []const BoolCallbackOption,
) Error!void {
    token.* = try token.next();
    while (true) {
        //err("reading attribute {t}", .{token.tag});
        try switch (token.tag) {
            .panel, .button, .sprite, .rectangle, .text_input, .label, .checkbox, .expander, .progress_bar, .open_bracket, .close_bracket => return,
            .name => readNameAttribute(token, entity),
            .text => readTextAttribute(token, entity),
            .image => readStringAttribute(token, &entity.texture_name),
            .aria_label => readStringAttribute(token, &entity.aria_label),
            .@"align" => readAlignAttribute(token, entity),
            .rect => readRectAttribute(token, &entity.rect),
            .size => readEntitySizeAttribute(token, entity),
            .minimum => readSizeAttribute(token, &entity.minimum),
            .maximum => readSizeAttribute(token, &entity.maximum),
            .pad => readClipAttribute(token, &entity.pad),
            .layout => readLayoutAttribute(token, &entity.layout),
            .velocity => readClipAttribute(token, &entity.pad),
            .flip => readClipAttribute(token, &entity.pad),
            .text_size => readTextSizeAttribute(token, entity),
            .line_height => readLineHeightAttribute(token, entity),
            .weight => readWeightAttribute(token, entity),
            .progress => readProgressAttribute(token, entity),
            .visible => entity.visible = .visible,
            .hidden => entity.visible = .hidden,
            .style => readStyleAttribute(token, &entity.style),
            .colour => readClipAttribute(token, &entity.pad),
            .max_length => readMaxLengthAttribute(token, entity),
            .checked => readCheckedAttribute(token, entity),
            .on => readOnAttribute(token, entity),
            .off => readOffAttribute(token, entity),
            .checkbox_size => readCheckboxSizeAttribute(token, entity),
            .icon_size => readIconSizeAttribute(token, entity),
            .placeholder_text => readPlaceholderTextAttribute(token, entity),
            .on_change => readOnChangeAttribute(token, entity, handler, callbacks),
            .on_pressed => readOnPressedAttribute(token, entity, handler, callbacks),
            .on_resized => readOnResizedAttribute(token, entity, handler, bool_callbacks),
            .on_visibility => readOnVisibilityAttribute(token, entity, handler, state_callbacks),
            .on_update => readOnUpdateAttribute(token, entity, handler, update_callbacks),
            .on_submit => readOnSubmitAttribute(token, entity, handler, callbacks),
            .on_ui_event => readOnUiEventAttribute(token, entity, handler, callbacks),
            .vertical => {
                if (entity.type != .panel)
                    return error.UnexpectedToken;
                entity.type.panel.direction = .top_to_bottom;
                token.* = try token.next();
            },
            .horizontal => {
                if (entity.type != .panel)
                    return error.UnexpectedToken;
                entity.type.panel.direction = .left_to_right;
                token.* = try token.next();
            },
            .eof => return,
            else => {
                if (entity.type == .button) {
                    const button = &entity.type.button;
                    try switch (token.tag) {
                        .icon_default => readStringAttribute(token, &button.icon.default_name),
                        .icon_hover => readStringAttribute(token, &button.icon.hover_name),
                        .icon_pressed => readStringAttribute(token, &button.icon.pressed_name),
                        .icon_disabled => readStringAttribute(token, &button.icon.disabled_name),
                        .button_default => readStringAttribute(token, &button.button.default_name),
                        .button_hover => readStringAttribute(token, &button.button.hover_name),
                        .button_pressed => readStringAttribute(token, &button.button.pressed_name),
                        .button_disabled => readStringAttribute(token, &button.button.disabled_name),
                        else => return error.UnexpectedToken,
                    };
                    continue;
                }
                return error.UnexpectedToken;
            },
        };
    }
}

pub fn readNameAttribute(token: *Token, entity: *Entity) Error!void {
    token.* = try token.next();
    //err("reading attribute vaue {t}='{s}'", .{ token.tag, token.slice() });
    switch (token.tag) {
        .string => {
            entity.name = token.data[token.loc.start + 1 .. token.loc.end - 1];
            token.* = try token.next();
            return;
        },
        else => return error.UnexpectedToken,
    }
}

pub fn readPlaceholderTextAttribute(token: *Token, entity: *Entity) Error!void {
    if (entity.type != .text_input) return error.UnexpectedToken;
    token.* = try token.next();
    //err("reading attribute vaue {t}='{s}'", .{ token.tag, token.slice() });
    switch (token.tag) {
        .string => {
            entity.type.text_input.placeholder_text = token.data[token.loc.start + 1 .. token.loc.end - 1];
            token.* = try token.next();
            return;
        },
        else => return error.UnexpectedToken,
    }
}

pub fn readOnResizedAttribute(
    token: *Token,
    entity: *Entity,
    handler: *anyopaque,
    callbacks: []const BoolCallbackOption,
) Error!void {
    token.* = try token.next();
    //err("reading attribute vaue {t}='{s}'", .{ token.tag, token.slice() });
    switch (token.tag) {
        .string => {
            const callback_name = token.data[token.loc.start + 1 .. token.loc.end - 1];
            entity.on_resized.func = try findMatchingBoolCallback(callback_name, callbacks);
            entity.on_resized.ptr = handler;
            token.* = try token.next();
            return;
        },
        else => return error.UnexpectedToken,
    }
}

pub fn readOnVisibilityAttribute(
    token: *Token,
    entity: *Entity,
    handler: *anyopaque,
    callbacks: []const StateCallbackOption,
) Error!void {
    token.* = try token.next();
    //err("reading attribute vaue {t}='{s}'", .{ token.tag, token.slice() });
    switch (token.tag) {
        .string => {
            const callback_name = token.data[token.loc.start + 1 .. token.loc.end - 1];
            entity.on_visibility.func = try findMatchingStateCallback(callback_name, callbacks);
            entity.on_visibility.ptr = handler;
            token.* = try token.next();
            return;
        },
        else => return error.UnexpectedToken,
    }
}

pub fn readOnUpdateAttribute(
    token: *Token,
    entity: *Entity,
    handler: *anyopaque,
    callbacks: []const UpdateCallbackOption,
) Error!void {
    const f: *engine.Entity.UpdateCallback = switch (entity.type) {
        .sprite => &entity.type.sprite.update,
        else => return Error.UnexpectedToken,
    };
    token.* = try token.next();
    err("reading attribute vaue {t}='{s}'", .{ token.tag, token.slice() });
    switch (token.tag) {
        .string => {
            const callback_name = token.data[token.loc.start + 1 .. token.loc.end - 1];
            f.func = try findMatchingUpdateCallback(callback_name, callbacks);
            f.ptr = handler;
            token.* = try token.next();
            return;
        },
        else => return error.UnexpectedToken,
    }
}

pub fn readOnSubmitAttribute(
    token: *Token,
    entity: *Entity,
    handler: *anyopaque,
    callbacks: []const CallbackOption,
) Error!void {
    const f: *Entity.Callback = switch (entity.type) {
        .text_input => &entity.type.text_input.on_submit,
        else => return Error.UnexpectedToken,
    };
    token.* = try token.next();
    //err("reading attribute vaue {t}='{s}'", .{ token.tag, token.slice() });
    switch (token.tag) {
        .string => {
            const callback_name = token.data[token.loc.start + 1 .. token.loc.end - 1];
            f.func = try findMatchingCallback(callback_name, callbacks);
            f.ptr = handler;
            token.* = try token.next();
            return;
        },
        else => return error.UnexpectedToken,
    }
}

pub fn readOnUiEventAttribute(
    token: *Token,
    entity: *Entity,
    handler: *anyopaque,
    callbacks: []const CallbackOption,
) Error!void {
    const f: *Entity.Callback = switch (entity.type) {
        .button => &entity.type.button.on_ui_event,
        .label => &entity.type.label.on_ui_event,
        .panel => &entity.type.panel.on_ui_event,
        .sprite => &entity.type.sprite.on_ui_event,
        else => return Error.UnexpectedToken,
    };
    token.* = try token.next();
    //err("reading attribute vaue {t}='{s}'", .{ token.tag, token.slice() });
    switch (token.tag) {
        .string => {
            const callback_name = token.data[token.loc.start + 1 .. token.loc.end - 1];
            f.func = try findMatchingCallback(callback_name, callbacks);
            f.ptr = handler;
            token.* = try token.next();
            return;
        },
        else => return error.UnexpectedToken,
    }
}

pub fn readOnChangeAttribute(
    token: *Token,
    entity: *Entity,
    handler: *anyopaque,
    callbacks: []const CallbackOption,
) Error!void {
    const f: *Entity.Callback = switch (entity.type) {
        .checkbox => &entity.type.checkbox.on_change,
        else => return Error.UnexpectedToken,
    };
    token.* = try token.next();
    //err("reading attribute vaue {t}='{s}'", .{ token.tag, token.slice() });
    switch (token.tag) {
        .string => {
            const callback_name = token.data[token.loc.start + 1 .. token.loc.end - 1];
            f.func = try findMatchingCallback(callback_name, callbacks);
            f.ptr = handler;
            token.* = try token.next();
            return;
        },
        else => return error.UnexpectedToken,
    }
}

pub fn readOnPressedAttribute(
    token: *Token,
    entity: *Entity,
    handler: *anyopaque,
    callbacks: []const CallbackOption,
) Error!void {
    const f: *Entity.Callback = switch (entity.type) {
        .button => &entity.type.button.on_pressed,
        .label => &entity.type.label.on_pressed,
        .panel => &entity.type.panel.on_pressed,
        .sprite => &entity.type.sprite.on_pressed,
        else => return Error.UnexpectedToken,
    };
    token.* = try token.next();
    //err("reading attribute vaue {t}='{s}'", .{ token.tag, token.slice() });
    switch (token.tag) {
        .string => {
            const callback_name = token.data[token.loc.start + 1 .. token.loc.end - 1];
            f.func = try findMatchingCallback(callback_name, callbacks);
            f.ptr = handler;
            token.* = try token.next();
            return;
        },
        else => return error.UnexpectedToken,
    }
}

pub fn readOnAttribute(token: *Token, entity: *Entity) Error!void {
    if (entity.type != .checkbox) return error.UnexpectedToken;
    token.* = try token.next();
    //err("reading attribute vaue {t}='{s}'", .{ token.tag, token.slice() });
    switch (token.tag) {
        .string => {
            entity.type.checkbox.on = token.data[token.loc.start + 1 .. token.loc.end - 1];
            token.* = try token.next();
            return;
        },
        else => return error.UnexpectedToken,
    }
}

pub fn readOffAttribute(token: *Token, entity: *Entity) Error!void {
    if (entity.type != .checkbox) return error.UnexpectedToken;
    token.* = try token.next();
    //err("reading attribute vaue {t}='{s}'", .{ token.tag, token.slice() });
    switch (token.tag) {
        .string => {
            entity.type.checkbox.off = token.data[token.loc.start + 1 .. token.loc.end - 1];
            token.* = try token.next();
            return;
        },
        else => return error.UnexpectedToken,
    }
}

pub fn readLineHeightAttribute(token: *Token, entity: *Entity) Error!void {
    const line_height = switch (entity.type) {
        .label => &entity.type.label.line_height,
        .checkbox => &entity.type.checkbox.line_height,
        else => return error.UnexpectedToken,
    };
    token.* = try token.next();
    //err("reading attribute vaue {t}='{s}'", .{ token.tag, token.slice() });
    switch (token.tag) {
        .number => {
            line_height.* = std.fmt.parseFloat(f32, token.slice()) catch return error.UnexpectedToken;
            token.* = try token.next();
            return;
        },
        else => return error.UnexpectedToken,
    }
}

pub fn readWeightAttribute(token: *Token, entity: *Entity) Error!void {
    if (entity.type != .expander) return error.UnexpectedToken;
    token.* = try token.next();
    //err("reading attribute vaue {t}='{s}'", .{ token.tag, token.slice() });
    switch (token.tag) {
        .number => {
            entity.type.expander.weight = std.fmt.parseFloat(f32, token.slice()) catch return error.UnexpectedToken;
            token.* = try token.next();
            return;
        },
        else => return error.UnexpectedToken,
    }
}

pub fn readProgressAttribute(token: *Token, entity: *Entity) Error!void {
    if (entity.type != .progress_bar) return error.UnexpectedToken;
    token.* = try token.next();
    //err("reading attribute vaue {t}='{s}'", .{ token.tag, token.slice() });
    switch (token.tag) {
        .number => {
            entity.type.progress_bar.progress = std.fmt.parseFloat(f32, token.slice()) catch return error.UnexpectedToken;
            token.* = try token.next();
            return;
        },
        else => return error.UnexpectedToken,
    }
}

pub fn readMaxLengthAttribute(token: *Token, entity: *Entity) Error!void {
    if (entity.type != .text_input) return error.UnexpectedToken;
    token.* = try token.next();
    //err("reading attribute vaue {t}='{s}'", .{ token.tag, token.slice() });
    switch (token.tag) {
        .number => {
            const f = std.fmt.parseFloat(f32, token.slice()) catch return error.UnexpectedToken;
            if (f != @ceil(f)) return error.UnexpectedToken;
            if (f > engine.Entity.TextInput.default_max_length) return error.UnexpectedToken;
            entity.type.text_input.max_length = @intFromFloat(f);
            token.* = try token.next();
            return;
        },
        else => return error.UnexpectedToken,
    }
}

pub fn readStyleAttribute(token: *Token, style: *engine.Theme.Style) Error!void {
    token.* = try token.next();
    //err("reading attribute vaue {t}='{s}'", .{ token.tag, token.slice() });
    if (token.tag == .equals)
        token.* = try token.next();
    switch (token.tag) {
        .normal => style.* = .normal,
        .faded => style.* = .faded,
        .tinted => style.* = .tinted,
        .emphasised => style.* = .emphasised,
        .success => style.* = .success,
        .failed => style.* = .failed,
        .background => style.* = .background,
        .custom => style.* = .custom,
        else => return error.UnexpectedToken,
    }
    token.* = try token.next();
    return;
}

pub fn readTextAttribute(
    token: *Token,
    entity: *engine.Entity,
) Error!void {
    token.* = try token.next();
    switch (token.tag) {
        .string => {
            const value = token.data[token.loc.start + 1 .. token.loc.end - 1];
            switch (entity.type) {
                .label => entity.type.label.text = value,
                .button => entity.type.button.text = value,
                .text_input => entity.type.text_input.initial_text = if (value.len > 0) value else null,
                else => return error.UnexpectedToken,
            }
            token.* = try token.next();
            return;
        },
        else => return error.UnexpectedToken,
    }
}

pub fn readStringAttribute(token: *Token, string: *?[]const u8) Error!void {
    //err("token={t} {s}", .{ token.tag, token.slice() });
    token.* = try token.next();
    //err("token={t} {s}", .{ token.tag, token.slice() });
    switch (token.tag) {
        .string => {
            string.* = token.data[token.loc.start + 1 .. token.loc.end - 1];
            token.* = try token.next();
            return;
        },
        else => return error.UnexpectedToken,
    }
}

pub fn readFloatValue(token: *Token) Error!f32 {
    //err("token={t} {s}", .{ token.tag, token.slice() });
    token.* = try token.next();
    //err("token={t} {s}", .{ token.tag, token.slice() });
    if (token.tag == .equals)
        token.* = try token.next();
    switch (token.tag) {
        .number => {
            const f = std.fmt.parseFloat(f32, token.slice()) catch return error.UnexpectedToken;
            token.* = try token.next();
            return f;
        },
        else => return error.UnexpectedToken,
    }
}

pub fn readAlignAttribute(token: *Token, entity: *Entity) Error!void {
    token.* = try token.next();
    var value_count: u8 = 0;
    var read_x = false;
    var read_y = false;
    while (true) {
        switch (token.tag) {
            .x => {
                if (read_x == true) return error.UnexpectedToken;
                token.* = try token.next();
                entity.child_align.x = switch (token.tag) {
                    .start => .start,
                    .centre => .centre,
                    .end => .end,
                    else => return error.UnexpectedToken,
                };
                read_x = true;
            },
            .y => {
                if (read_y == true) return error.UnexpectedToken;
                token.* = try token.next();
                entity.child_align.y = switch (token.tag) {
                    .start => .start,
                    .centre => .centre,
                    .end => .end,
                    else => return error.UnexpectedToken,
                };
                read_y = true;
            },
            .start, .end, .centre => {
                if (value_count == 2) return error.UnexpectedToken;
                if (value_count == 0) entity.child_align.x = switch (token.tag) {
                    .start => .start,
                    .centre => .centre,
                    .end => .end,
                    else => return error.UnexpectedToken,
                };
                if (value_count == 1) entity.child_align.y = switch (token.tag) {
                    .start => .start,
                    .centre => .centre,
                    .end => .end,
                    else => return error.UnexpectedToken,
                };
                value_count += 1;
                token.* = try token.next();
            },
            else => {
                if (read_x == true or read_y == true or value_count > 0) return;
                return error.UnexpectedToken;
            },
        }
    }
}

pub fn readCheckedAttribute(token: *Token, entity: *Entity) Error!void {
    token.* = try token.next();
    entity.type.checkbox.checked = true;
}

pub fn readRectAttribute(token: *Token, rect: *engine.Rect) Error!void {
    token.* = try token.next();
    switch (token.tag) {
        .string => {
            rect.x = 0;
            return;
        },
        else => return error.UnexpectedToken,
    }
}

pub fn readSizeAttribute(token: *Token, size: *engine.Size) Error!void {
    token.* = try token.next();
    var value_count: u8 = 0;
    var read_width = false;
    var read_height = false;
    while (true) {
        switch (token.tag) {
            .width => {
                if (read_width == true) return error.UnexpectedToken;
                token.* = try token.next();
                size.width = try readFloatValue(token);
                read_width = true;
            },
            .height => {
                if (read_height == true) return error.UnexpectedToken;
                token.* = try token.next();
                size.height = try readFloatValue(token);
                read_height = true;
            },
            .number => {
                if (value_count == 2) return error.UnexpectedToken;
                if (value_count == 0) size.width = std.fmt.parseFloat(f32, token.slice()) catch unreachable;
                if (value_count == 1) size.height = std.fmt.parseFloat(f32, token.slice()) catch unreachable;
                value_count += 1;
                token.* = try token.next();
            },
            else => {
                if (read_width == true or read_height == true or value_count > 0) return;
                return error.UnexpectedToken;
            },
        }
    }
}

pub fn readLayoutAttribute(token: *Token, layout: *engine.Entity.Layout) Error!void {
    token.* = try token.next();
    var value_count: u8 = 0;
    var read_x = false;
    var read_y = false;
    while (true) {
        switch (token.tag) {
            .x => {
                if (read_x == true) return error.UnexpectedToken;
                token.* = try token.next();
                if (token.tag == .equals) token.* = try token.next();
                layout.x = switch (token.tag) {
                    .shrinks => .shrinks,
                    .grows => .grows,
                    .fixed => .fixed,
                    else => return error.UnexpectedToken,
                };
                token.* = try token.next();
                read_x = true;
            },
            .y => {
                if (read_y == true) return error.UnexpectedToken;
                token.* = try token.next();
                if (token.tag == .equals) token.* = try token.next();
                layout.y = switch (token.tag) {
                    .shrinks => .shrinks,
                    .grows => .grows,
                    .fixed => .fixed,
                    else => return error.UnexpectedToken,
                };
                token.* = try token.next();
                read_y = true;
            },
            .shrinks, .grows, .fixed => {
                if (value_count == 2) return error.UnexpectedToken;
                if (value_count == 0) layout.x = switch (token.tag) {
                    .shrinks => .shrinks,
                    .grows => .grows,
                    .fixed => .fixed,
                    else => return error.UnexpectedToken,
                };
                if (value_count == 1) layout.y = switch (token.tag) {
                    .shrinks => .shrinks,
                    .grows => .grows,
                    .fixed => .fixed,
                    else => return error.UnexpectedToken,
                };
                value_count += 1;
                token.* = try token.next();
            },
            else => {
                if (read_x == true or read_y == true or value_count > 0) return;
                return error.UnexpectedToken;
            },
        }
    }
}

pub fn readEntitySizeAttribute(token: *Token, entity: *engine.Entity) Error!void {
    token.* = try token.next();
    var value_count: u8 = 0;
    var read_width = false;
    var read_height = false;
    while (true) {
        switch (token.tag) {
            .width => {
                if (read_width == true) return error.UnexpectedToken;
                token.* = try token.next();
                entity.rect.width = try readFloatValue(token);
                read_width = true;
            },
            .height => {
                if (read_height == true) return error.UnexpectedToken;
                token.* = try token.next();
                entity.rect.height = try readFloatValue(token);
                read_height = true;
            },
            .number => {
                if (value_count == 2) return error.UnexpectedToken;
                if (value_count == 0) entity.rect.width = std.fmt.parseFloat(f32, token.slice()) catch unreachable;
                if (value_count == 1) entity.rect.height = std.fmt.parseFloat(f32, token.slice()) catch unreachable;
                value_count += 1;
                token.* = try token.next();
            },
            else => {
                if (read_width == true or read_height == true or value_count > 0) return;
                return error.UnexpectedToken;
            },
        }
    }
}

pub fn readCheckboxSizeAttribute(token: *Token, entity: *engine.Entity) Error!void {
    if (entity.type != .checkbox) return error.UnexpectedToken;
    const size = &entity.type.checkbox.checkbox_size;
    token.* = try token.next();
    var value_count: u8 = 0;
    var read_width = false;
    var read_height = false;
    while (true) {
        switch (token.tag) {
            .width => {
                if (read_width == true) return error.UnexpectedToken;
                token.* = try token.next();
                size.width = try readFloatValue(token);
                read_width = true;
            },
            .height => {
                if (read_height == true) return error.UnexpectedToken;
                token.* = try token.next();
                size.height = try readFloatValue(token);
                read_height = true;
            },
            .number => {
                if (value_count == 2) return error.UnexpectedToken;
                if (value_count == 0) size.width = std.fmt.parseFloat(f32, token.slice()) catch unreachable;
                if (value_count == 1) size.height = std.fmt.parseFloat(f32, token.slice()) catch unreachable;
                value_count += 1;
                token.* = try token.next();
            },
            else => {
                if (read_width == true or read_height == true or value_count > 0) return;
                return error.UnexpectedToken;
            },
        }
    }
}

pub fn readIconSizeAttribute(token: *Token, entity: *engine.Entity) Error!void {
    if (entity.type != .button) return error.UnexpectedToken;
    const size = &entity.type.checkbox.checkbox_size;
    token.* = try token.next();
    var value_count: u8 = 0;
    var read_width = false;
    var read_height = false;
    while (true) {
        switch (token.tag) {
            .width => {
                if (read_width == true) return error.UnexpectedToken;
                token.* = try token.next();
                size.width = try readFloatValue(token);
                read_width = true;
            },
            .height => {
                if (read_height == true) return error.UnexpectedToken;
                token.* = try token.next();
                size.height = try readFloatValue(token);
                read_height = true;
            },
            .number => {
                if (value_count == 2) return error.UnexpectedToken;
                if (value_count == 0) size.width = std.fmt.parseFloat(f32, token.slice()) catch unreachable;
                if (value_count == 1) size.height = std.fmt.parseFloat(f32, token.slice()) catch unreachable;
                value_count += 1;
                token.* = try token.next();
            },
            else => {
                if (read_width == true or read_height == true or value_count > 0) return;
                return error.UnexpectedToken;
            },
        }
    }
}

pub fn readTextSizeAttribute(token: *Token, entity: *engine.Entity) Error!void {
    const size = switch (entity.type) {
        .label => &entity.type.label.text_size,
        .checkbox => &entity.type.checkbox.text_size,
        else => return error.UnexpectedToken,
    };
    token.* = try token.next();
    switch (token.tag) {
        .small => size.* = .small,
        .normal => size.* = .normal,
        .subheading => size.* = .subheading,
        .heading => size.* = .heading,
        .footnote => size.* = .footnote,
        else => return error.UnexpectedToken,
    }
    token.* = try token.next();
}

pub fn readClipAttribute(token: *Token, clip: *engine.Clip) Error!void {
    token.* = try token.next();
    var value_count: u8 = 0;
    var read_left = false;
    var read_top = false;
    var read_right = false;
    var read_bottom = false;
    while (true) {
        switch (token.tag) {
            .left => {
                if (read_left == true) return error.UnexpectedToken;
                token.* = try token.next();
                clip.left = try readFloatValue(token);
                read_left = true;
            },
            .top => {
                if (read_top == true) return error.UnexpectedToken;
                token.* = try token.next();
                clip.top = try readFloatValue(token);
                read_top = true;
            },
            .right => {
                if (read_right == true) return error.UnexpectedToken;
                token.* = try token.next();
                clip.right = try readFloatValue(token);
                read_right = true;
            },
            .bottom => {
                if (read_bottom == true) return error.UnexpectedToken;
                token.* = try token.next();
                clip.bottom = try readFloatValue(token);
                read_bottom = true;
            },
            .number => {
                if (value_count == 4) return error.UnexpectedToken;
                if (value_count == 0) clip.left = std.fmt.parseFloat(f32, token.slice()) catch unreachable;
                if (value_count == 1) clip.top = std.fmt.parseFloat(f32, token.slice()) catch unreachable;
                if (value_count == 2) clip.right = std.fmt.parseFloat(f32, token.slice()) catch unreachable;
                if (value_count == 3) clip.bottom = std.fmt.parseFloat(f32, token.slice()) catch unreachable;
                value_count += 1;
                token.* = try token.next();
            },
            else => {
                if (read_left == true or read_right == true or read_top == true or read_bottom == true or value_count > 0) return;
                return error.UnexpectedToken;
            },
        }
    }
}

pub const Error = error{
    MaxLineCountExceeded,
    InvalidUtf8,
    UnexpectedToken,
};

const TestHandler = struct {
    count: u8 = 0,

    pub fn on_jump(_: *TestHandler, two: bool, three: bool, four: bool) void {
        _ = two;
        _ = three;
        _ = four;
        return;
    }

    pub fn on_run(_: *TestHandler, two: *engine.Display, three: *engine.Entity, four: *engine.Colour) void {
        _ = two;
        _ = three;
        _ = four;
        return;
    }

    pub fn on_click(self: *TestHandler, two: *engine.Display, three: *engine.Entity, four: *engine.Event) error{OutOfMemory}!void {
        _ = two;
        _ = three;
        _ = four;
        self.count += 1;
        return;
    }

    pub fn on_move(_: *TestHandler, two: *engine.Display, three: *engine.Entity, four: *engine.Event) void {
        _ = two;
        _ = three;
        _ = four;
        return;
    }

    pub fn on_hide(_: *TestHandler, two: *engine.Display, three: *engine.Entity, four: *engine.Event) std.mem.Allocator.Error!void {
        _ = two;
        _ = three;
        _ = four;
        return;
    }

    pub fn save(_: *TestHandler, name: []const u8) void {
        _ = name;
    }
};

test "layout" {
    var layout: engine.Entity.Layout = .{};
    var token = try Token.init("layout fixed grows");
    try readLayoutAttribute(&token, &layout);
    try expectEqual(.fixed, layout.x);
    try expectEqual(.grows, layout.y);
}

test "layout_equals" {
    var layout: engine.Entity.Layout = .{};
    var token = try Token.init("layout x=fixed y=grows");
    try readLayoutAttribute(&token, &layout);
    try expectEqual(.fixed, layout.x);
    try expectEqual(.grows, layout.y);
}

test "layout_equals2" {
    var layout: engine.Entity.Layout = .{};
    var token = try Token.init("layout y=fixed x=grows");
    try readLayoutAttribute(&token, &layout);
    try expectEqual(.grows, layout.x);
    try expectEqual(.fixed, layout.y);
}

test "panel" {
    var te: TestHandler = .{};
    const entity = try readEntity(std.testing.allocator,
        \\panel name "coffee" image "cat"
        \\minimum width=33 height=120
        \\maximum height=99 width=88
        \\horizontal
        \\style tinted
    , TestHandler, &te) orelse unreachable;

    try expectEqual(33, entity.minimum.width);
    try expectEqual(120, entity.minimum.height);
    try expectEqual(88, entity.maximum.width);
    try expectEqual(99, entity.maximum.height);
    try expectEqualStrings("coffee", entity.name);
    try expectEqualStrings("cat", entity.texture_name.?);
    try expectEqual(.left_to_right, entity.type.panel.direction);
    try expectEqual(.tinted, entity.style);
}

test "panel_children" {
    var te: TestHandler = .{};
    const entity = try readEntity(std.testing.allocator,
        \\panel name "coffee" image "cat"
        \\{
        \\  label text "hello"
        \\  label text "hello2"
        \\  button text "save"
        \\}
    , TestHandler, &te) orelse unreachable;

    try expectEqual(3, entity.type.panel.children.items.len);
    try expect(.label == entity.type.panel.children.items[0].type);
    try expect(.label == entity.type.panel.children.items[1].type);
    try expect(.button == entity.type.panel.children.items[2].type);
}

test "label" {
    var te: TestHandler = .{};
    const entity = try readEntity(std.testing.allocator,
        \\label name "coffee" line_height 1.2
        \\minimum 33 44
        \\style emphasised text_size heading
    , TestHandler, &te) orelse unreachable;
    try expectEqual(33, entity.minimum.width);
    try expectEqual(44, entity.minimum.height);
    try expectEqual(1.2, entity.type.label.line_height);
    try expectEqualStrings("coffee", entity.name);
    try expectEqual(.heading, entity.type.label.text_size);
    try expectEqual(.emphasised, entity.style);
}

test "checkbox" {
    var te: TestHandler = .{};
    var entity = try readEntity(std.testing.allocator,
        \\checkbox name "coffee"
        \\minimum width=12.34 height=120
        \\style tinted text_size heading
        \\line_height 1.2 on "on" off "off"
        \\layout y=shrinks x=fixed
        \\checkbox_size 25 26
        \\on_change "on_click"
    , TestHandler, &te) orelse unreachable;

    try expectEqual(1.2, entity.type.checkbox.line_height);
    try expectEqual(12.34, entity.minimum.width);
    try expectEqual(120, entity.minimum.height);
    try expectEqualStrings("coffee", entity.name);
    try expectEqualStrings("on", entity.type.checkbox.on.?);
    try expectEqualStrings("off", entity.type.checkbox.off.?);
    try expectEqual(.heading, entity.type.checkbox.text_size);
    try expectEqual(.tinted, entity.style);
    try expectEqual(25, entity.type.checkbox.checkbox_size.width);
    try expectEqual(26, entity.type.checkbox.checkbox_size.height);
    try expectEqual(.shrinks, entity.layout.y);
    try expectEqual(.fixed, entity.layout.x);

    const allocator = std.testing.allocator;
    const io = std.testing.io;
    var display = try headless_display(allocator, io, 1000, 1600, 2);
    defer display.destroy();

    try expectEqual(0, te.count);
    try entity.type.checkbox.on_change.call(display, &entity, &.{});
    try expectEqual(1, te.count);
}

test "text_input" {
    var te: TestHandler = .{};
    const entity = try readEntity(std.testing.allocator,
        \\text_input name "coffee"
        \\minimum 100 40
        \\style normal placeholder_text "Enter your food"
        \\layout grows shrinks
        \\max_length 123
    , TestHandler, &te) orelse unreachable;
    try expectEqual(100, entity.minimum.width);
    try expectEqual(40, entity.minimum.height);
    try expectEqualStrings("Enter your food", entity.type.text_input.placeholder_text.?);
    try expectEqual(.normal, entity.style);
    try expectEqual(123, entity.type.text_input.max_length);
    try expectEqual(.grows, entity.layout.x);
    try expectEqual(.shrinks, entity.layout.y);
}

test "expander" {
    var te: TestHandler = .{};
    const entity = try readEntity(std.testing.allocator,
        \\expander name "expander 1" weight 0.4
    , TestHandler, &te) orelse unreachable;
    try expectEqual(0.4, entity.type.expander.weight);
    try expectEqualStrings("expander 1", entity.name);
}

const std = @import("std");
const Allocator = std.mem.Allocator;
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;

const engine = @import("engine.zig");
const err = engine.log.err;

const Token = @import("Token.zig");
const Entity = @import("Entity.zig");
const TextSize = engine.TextSize;

const headless_display = @import("test.zig").headless_display;
