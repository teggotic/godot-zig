const Builder = @import("std").build.Builder;
const Version = @import("std").build.Version;

pub fn build(builder: &Builder) void {
    builder.addLibPath("/usr/lib64/");
    builder.addCIncludePath("./godot_headers/");
    var exe = builder.addSharedLibrary("godotzig", "godot/core/index.zig", builder.version(0, 0, 1));
    exe.setBuildMode(builder.standardReleaseOptions());

    // exe.linkSystemLibrary("c");

    builder.default_step.dependOn(&exe.step);
    builder.installArtifact(exe);
}
