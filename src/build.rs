fn main() {
    #[cfg(target_os = "macos")]
    {
        println!("cargo:rustc-env=MACOSX_DEPLOYMENT_TARGET=26.0");

        cc::Build::new()
            .file("native/NativeCameraPreview.m")
            .flag("-fobjc-arc")
            .flag("-mmacosx-version-min=26.0")
            .compile("glimpse_native_camera");

        println!("cargo:rustc-link-lib=framework=AppKit");
        println!("cargo:rustc-link-lib=framework=AVFoundation");
        println!("cargo:rustc-link-lib=framework=QuartzCore");
    }

    tauri_build::build()
}
