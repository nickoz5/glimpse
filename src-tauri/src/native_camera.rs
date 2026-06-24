#[derive(Debug, Clone)]
pub struct CameraDevice {
    pub id: String,
    pub name: String,
}

#[cfg(target_os = "macos")]
mod platform {
    use super::CameraDevice;
    use std::{
        ffi::{CStr, CString},
        os::raw::{c_char, c_double},
    };

    unsafe extern "C" {
        fn glimpse_native_configure_app();
        fn glimpse_native_camera_count() -> usize;
        fn glimpse_native_camera_info(
            index: usize,
            id_buffer: *mut c_char,
            id_buffer_length: usize,
            name_buffer: *mut c_char,
            name_buffer_length: usize,
        );
        fn glimpse_native_is_visible() -> bool;
        fn glimpse_native_show(
            x: c_double,
            y: c_double,
            width: c_double,
            height: c_double,
            device_id: *const c_char,
        );
        fn glimpse_native_hide();
        fn glimpse_native_reset(
            x: c_double,
            y: c_double,
            width: c_double,
            height: c_double,
            device_id: *const c_char,
        );
        fn glimpse_native_set_camera(device_id: *const c_char);
        fn glimpse_native_restore_frame(
            x: c_double,
            y: c_double,
            width: c_double,
            height: c_double,
        );
    }

    pub fn configure_app() {
        unsafe {
            glimpse_native_configure_app();
        }
    }

    fn optional_cstring(value: Option<&str>) -> CString {
        CString::new(value.unwrap_or_default()).unwrap_or_default()
    }

    pub fn devices() -> Vec<CameraDevice> {
        let count = unsafe { glimpse_native_camera_count() };
        let mut devices = Vec::with_capacity(count);

        for index in 0..count {
            let mut id = vec![0 as c_char; 512];
            let mut name = vec![0 as c_char; 512];

            unsafe {
                glimpse_native_camera_info(
                    index,
                    id.as_mut_ptr(),
                    id.len(),
                    name.as_mut_ptr(),
                    name.len(),
                );
            }

            let id = unsafe { CStr::from_ptr(id.as_ptr()) }
                .to_string_lossy()
                .into_owned();
            let name = unsafe { CStr::from_ptr(name.as_ptr()) }
                .to_string_lossy()
                .into_owned();

            if !id.is_empty() {
                devices.push(CameraDevice { id, name });
            }
        }

        devices
    }

    pub fn is_visible() -> bool {
        unsafe { glimpse_native_is_visible() }
    }

    pub fn show(x: f64, y: f64, width: f64, height: f64, device_id: Option<&str>) {
        let device_id = optional_cstring(device_id);
        unsafe {
            glimpse_native_show(x, y, width, height, device_id.as_ptr());
        }
    }

    pub fn hide() {
        unsafe {
            glimpse_native_hide();
        }
    }

    pub fn reset(x: f64, y: f64, width: f64, height: f64, device_id: Option<&str>) {
        let device_id = optional_cstring(device_id);
        unsafe {
            glimpse_native_reset(x, y, width, height, device_id.as_ptr());
        }
    }

    pub fn set_camera(device_id: Option<&str>) {
        let device_id = optional_cstring(device_id);
        unsafe {
            glimpse_native_set_camera(device_id.as_ptr());
        }
    }

    pub fn restore_frame(x: f64, y: f64, width: f64, height: f64) {
        unsafe {
            glimpse_native_restore_frame(x, y, width, height);
        }
    }
}

#[cfg(not(target_os = "macos"))]
mod platform {
    use super::CameraDevice;

    pub fn devices() -> Vec<CameraDevice> {
        Vec::new()
    }

    pub fn configure_app() {}

    pub fn is_visible() -> bool {
        false
    }

    pub fn show(_x: f64, _y: f64, _width: f64, _height: f64, _device_id: Option<&str>) {}

    pub fn hide() {}

    pub fn reset(_x: f64, _y: f64, _width: f64, _height: f64, _device_id: Option<&str>) {}

    pub fn set_camera(_device_id: Option<&str>) {}

    pub fn restore_frame(_x: f64, _y: f64, _width: f64, _height: f64) {}
}

pub use platform::*;
