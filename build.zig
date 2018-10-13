const Builder = @import("std").build.Builder;
const Version = @import("std").build.Version;

pub fn build(builder: *Builder) void {
    builder.addLibPath("/usr/lib64/");
    builder.addCIncludePath("./godot_headers/");
    var exe = builder.addSharedLibrary("godotzig", "godot/core/index.zig", builder.version(0, 0, 1));
    exe.setBuildMode(builder.standardReleaseOptions());

    // exe.linkSystemLibrary("c");

    builder.default_step.dependOn(&exe.step);
    builder.installArtifact(exe);

    const test_step = builder.step("test", "Test");
    const build_test = builder.addTest("godot/core/tests.zig");
    build_test.linkSystemLibrary("c");
    test_step.dependOn(&build_test.step);
}
