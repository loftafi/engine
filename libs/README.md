# Libraries

## SDL Instructions

SDL Libraries are available here:

 - https://github.com/libsdl-org/SDL/releases/tag/release-3.2.16
 - https://github.com/libsdl-org/SDL_ttf/releases

## SDL Mac

Download the mac dmg files and locate the following folders which
contain object files for all architectures/platforms:

 - SDL3_ttf.xcframework
 - SDL3.xcframework

Please the above files inside the `lib/` folder. Zig appears not able to
link to `xcframework` files. The `build.zig` file detects the platform and
points to the correct `framework` files inside the bundles.

## SDL Mac Notes

Nomrally mac static libraries are `.a` files and dynamic libraries are
`.dylib` files. Inside `xcframework` packages this does not apply.

On mac, arm64 and x86_64 libraries can be bundled into a single "fat" file,
and it does not have a file extension. You can use `lipo -info` to confirm
if the library file a fat file:

    lipo -info SDL3.xcframework/macos-arm64_x86_64/SDL3.framework/SDL3
    Architectures in the fat file: SDL3 are: x86_64 arm64

If you needed to link with individual "thin" files, Extract the individual
libraries from the "fat" file into the `libs` folder like this.

    lipo -extract_family arm64 SDL3.xcframework/macos-arm64_x86_64/SDL3.framework/SDL3 -output libsdl3-macos-arm64.a
    lipo -extract_family arm64 SDL3_ttf.xcframework/macos-arm64_x86_64/SDL3_ttf.framework/SDL3_ttf -output libsdl3_ttf-macos-arm64.a
    lipo -extract_family arm64 SDL3.xcframework/ios-arm64/SDL3.framework/SDL3 -output libsdl3-ios-arm64.a
    lipo -extract_family x86_64 SDL3.xcframework/ios-arm64/SDL3.framework/SDL3 -output libsdl3-ios-x86_64.a
    lipo -extract_family arm64 SDL3_ttf.xcframework/ios-arm64/SDL3_ttf.framework/SDL3 -output libsdl3_ttf-ios-arm64.a
    lipo -extract_family x86_64 SDL3_ttf.xcframework/ios-arm64/SDL3_ttf.framework/SDL3 -output libsdl3_ttf-ios-x86_64.a
