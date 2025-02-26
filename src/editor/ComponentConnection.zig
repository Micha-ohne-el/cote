const std = @import("std");
const Component = @import("common").Component;

component: Component,
dynlib: std.DynLib,

pub fn close(this: *@This()) void {
    this.dynlib.close();
}
