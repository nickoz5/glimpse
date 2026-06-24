mod native_camera;

use serde::{Deserialize, Serialize};
use std::{
    fs,
    path::{Path, PathBuf},
    sync::{Mutex, OnceLock},
};
use tauri::{
    image::Image,
    menu::{Menu, MenuItem, Submenu},
    tray::{MouseButton, MouseButtonState, TrayIconBuilder, TrayIconEvent},
    App, AppHandle, Manager, PhysicalPosition, State,
};
use tauri_plugin_autostart::{MacosLauncher, ManagerExt};

const DEFAULT_WIDTH: f64 = 360.0;
const DEFAULT_HEIGHT: f64 = 240.0;
static PREFERENCES_PATH: OnceLock<PathBuf> = OnceLock::new();

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WindowFrame {
    pub x: f64,
    pub y: f64,
    pub width: f64,
    pub height: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct Preferences {
    pub selected_camera_id: Option<String>,
    pub launch_at_login: bool,
    pub preview_window_frame: Option<WindowFrame>,
}

#[no_mangle]
pub extern "C" fn glimpse_native_frame_changed(x: f64, y: f64, width: f64, height: f64) {
    let Some(path) = PREFERENCES_PATH.get() else {
        return;
    };

    let mut preferences = load_preferences(path);
    preferences.preview_window_frame = Some(WindowFrame {
        x,
        y,
        width,
        height,
    });

    if let Err(error) = save_preferences(path, &preferences) {
        eprintln!("failed to save preview window frame: {error}");
    }
}

struct AppState {
    preferences_path: PathBuf,
    preferences: Mutex<Preferences>,
}

#[tauri::command]
fn get_preferences(state: State<'_, AppState>) -> Result<Preferences, String> {
    let preferences = state
        .preferences
        .lock()
        .map_err(|_| "Preferences lock was poisoned".to_string())?;

    Ok(preferences.clone())
}

#[tauri::command]
fn set_selected_camera(
    state: State<'_, AppState>,
    device_id: Option<String>,
) -> Result<(), String> {
    let mut preferences = state
        .preferences
        .lock()
        .map_err(|_| "Preferences lock was poisoned".to_string())?;

    preferences.selected_camera_id = device_id.filter(|value| !value.is_empty());
    native_camera::set_camera(preferences.selected_camera_id.as_deref());
    preserve_latest_window_frame(&state.preferences_path, &mut preferences);
    save_preferences(&state.preferences_path, &preferences)
}

#[tauri::command]
fn set_launch_at_login(
    app: AppHandle,
    state: State<'_, AppState>,
    enabled: bool,
) -> Result<(), String> {
    set_autostart(&app, enabled)?;

    let mut preferences = state
        .preferences
        .lock()
        .map_err(|_| "Preferences lock was poisoned".to_string())?;

    preferences.launch_at_login = enabled;
    preserve_latest_window_frame(&state.preferences_path, &mut preferences);
    save_preferences(&state.preferences_path, &preferences)
}

pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_autostart::init(
            MacosLauncher::LaunchAgent,
            None,
        ))
        .setup(setup_app)
        .invoke_handler(tauri::generate_handler![
            get_preferences,
            set_selected_camera,
            set_launch_at_login
        ])
        .on_menu_event(|app, event| match event.id().as_ref() {
            "camera_default" => set_camera(app, None),
            "toggle_startup" => {
                if let Err(error) = toggle_launch_at_login(app) {
                    eprintln!("failed to toggle launch at login: {error}");
                }
            }
            "reset_window" => {
                if let Err(error) = reset_preview_window(app) {
                    eprintln!("failed to reset preview window: {error}");
                }
            }
            "exit" => app.exit(0),
            id if id.starts_with("camera_") => {
                if let Some(index) = id
                    .strip_prefix("camera_")
                    .and_then(|value| value.parse::<usize>().ok())
                {
                    if let Some(device) = native_camera::devices().get(index) {
                        set_camera(app, Some(device.id.clone()));
                    }
                }
            }
            _ => {}
        })
        .run(tauri::generate_context!())
        .expect("error while running Glimpse");
}

fn setup_app(app: &mut App) -> Result<(), Box<dyn std::error::Error>> {
    native_camera::configure_app();

    let app_handle = app.handle().clone();
    let preferences_path = preferences_path(&app_handle)?;
    let preferences = load_preferences(&preferences_path);
    let _ = PREFERENCES_PATH.set(preferences_path.clone());

    if let Some(frame) = preferences.preview_window_frame.as_ref() {
        native_camera::restore_frame(frame.x, frame.y, frame.width, frame.height);
    }

    app.manage(AppState {
        preferences_path,
        preferences: Mutex::new(preferences),
    });

    create_tray(&app_handle)?;

    Ok(())
}

fn create_tray(app: &AppHandle) -> tauri::Result<()> {
    let camera_items = camera_menu_items(app)?;
    let camera_item_refs = camera_items
        .iter()
        .map(|item| item as &dyn tauri::menu::IsMenuItem<_>)
        .collect::<Vec<_>>();
    let camera_menu =
        Submenu::with_id_and_items(app, "camera_menu", "Camera", true, &camera_item_refs)?;
    let toggle_startup = MenuItem::with_id(
        app,
        "toggle_startup",
        "Enable Automatic Startup",
        true,
        None::<&str>,
    )?;
    let reset_window = MenuItem::with_id(
        app,
        "reset_window",
        "Reset Window",
        true,
        None::<&str>,
    )?;
    let exit = MenuItem::with_id(app, "exit", "Exit Glimpse", true, None::<&str>)?;
    let menu = Menu::with_items(app, &[&camera_menu, &toggle_startup, &reset_window, &exit])?;

    TrayIconBuilder::with_id("glimpse-tray")
        .icon(Image::from_bytes(include_bytes!(
            "../icons/icon-large.png"
        ))?)
        .tooltip("Glimpse")
        .menu(&menu)
        .show_menu_on_left_click(false)
        .on_tray_icon_event(|tray, event| {
            if let TrayIconEvent::Click {
                position,
                button: MouseButton::Left,
                button_state: MouseButtonState::Up,
                ..
            } = event
            {
                let app = tray.app_handle();
                if let Err(error) = toggle_preview_window(app, Some(position)) {
                    eprintln!("failed to toggle preview window: {error}");
                }
            }
        })
        .build(app)?;

    Ok(())
}

fn camera_menu_items(app: &AppHandle) -> tauri::Result<Vec<MenuItem<tauri::Wry>>> {
    let mut items = vec![MenuItem::with_id(
        app,
        "camera_default",
        "Default Camera",
        true,
        None::<&str>,
    )?];

    for (index, device) in native_camera::devices().iter().enumerate() {
        items.push(MenuItem::with_id(
            app,
            format!("camera_{index}"),
            &device.name,
            true,
            None::<&str>,
        )?);
    }

    Ok(items)
}

fn toggle_preview_window(
    app: &AppHandle,
    tray_position: Option<PhysicalPosition<f64>>,
) -> tauri::Result<()> {
    if native_camera::is_visible() {
        native_camera::hide();
        return Ok(());
    }

    show_preview_window(app, tray_position)
}

fn show_preview_window(
    app: &AppHandle,
    tray_position: Option<PhysicalPosition<f64>>,
) -> tauri::Result<()> {
    let (x, y) = tray_position
        .map(window_position_under_tray)
        .unwrap_or((200.0, 64.0));
    let selected_camera = selected_camera_id(app);
    native_camera::show(
        x,
        y,
        DEFAULT_WIDTH,
        DEFAULT_HEIGHT,
        selected_camera.as_deref(),
    );

    Ok(())
}

fn window_position_under_tray(tray_position: PhysicalPosition<f64>) -> (f64, f64) {
    let x = tray_position.x - (DEFAULT_WIDTH / 2.0);
    let y = tray_position.y + 8.0;
    (x, y)
}

fn reset_preview_window(app: &AppHandle) -> Result<(), String> {
    let (x, y) = default_preview_position(app)?;
    let selected_camera = selected_camera_id(app);
    native_camera::reset(
        x,
        y,
        DEFAULT_WIDTH,
        DEFAULT_HEIGHT,
        selected_camera.as_deref(),
    );
    Ok(())
}

fn default_preview_position(app: &AppHandle) -> Result<(f64, f64), String> {
    let monitor = app
        .primary_monitor()
        .map_err(|error| error.to_string())?
        .ok_or_else(|| "No primary monitor found".to_string())?;
    let position = monitor.position();
    let size = monitor.size();
    let x = position.x as f64 + ((size.width as f64 - DEFAULT_WIDTH) / 2.0);
    let y = position.y as f64 + 48.0;
    Ok((x, y))
}

fn selected_camera_id(app: &AppHandle) -> Option<String> {
    let state = app.state::<AppState>();
    state
        .preferences
        .lock()
        .ok()
        .and_then(|preferences| preferences.selected_camera_id.clone())
}

fn set_camera(app: &AppHandle, device_id: Option<String>) {
    let state = app.state::<AppState>();
    let mut preferences = match state.preferences.lock() {
        Ok(preferences) => preferences,
        Err(_) => {
            eprintln!("failed to set camera: preferences lock was poisoned");
            return;
        }
    };

    preferences.selected_camera_id = device_id.filter(|value| !value.is_empty());
    preserve_latest_window_frame(&state.preferences_path, &mut preferences);
    if let Err(error) = save_preferences(&state.preferences_path, &preferences) {
        eprintln!("failed to save selected camera: {error}");
    }

    native_camera::set_camera(preferences.selected_camera_id.as_deref());
}

fn toggle_launch_at_login(app: &AppHandle) -> Result<(), String> {
    let state = app.state::<AppState>();
    let mut preferences = state
        .preferences
        .lock()
        .map_err(|_| "Preferences lock was poisoned".to_string())?;
    let next_value = !preferences.launch_at_login;

    set_autostart(app, next_value)?;
    preferences.launch_at_login = next_value;
    preserve_latest_window_frame(&state.preferences_path, &mut preferences);
    save_preferences(&state.preferences_path, &preferences)
}

fn set_autostart(app: &AppHandle, enabled: bool) -> Result<(), String> {
    let autostart = app.autolaunch();

    if enabled {
        autostart.enable().map_err(|error| error.to_string())
    } else {
        autostart.disable().map_err(|error| error.to_string())
    }
}

fn preferences_path(app: &AppHandle) -> Result<PathBuf, Box<dyn std::error::Error>> {
    let directory = app.path().app_config_dir()?;
    fs::create_dir_all(&directory)?;
    Ok(directory.join("preferences.json"))
}

fn load_preferences(path: &Path) -> Preferences {
    fs::read_to_string(path)
        .ok()
        .and_then(|contents| serde_json::from_str(&contents).ok())
        .unwrap_or_default()
}

fn save_preferences(path: &Path, preferences: &Preferences) -> Result<(), String> {
    let contents = serde_json::to_string_pretty(preferences).map_err(|error| error.to_string())?;
    fs::write(path, contents).map_err(|error| error.to_string())
}

fn preserve_latest_window_frame(path: &Path, preferences: &mut Preferences) {
    if let Some(frame) = load_preferences(path).preview_window_frame {
        preferences.preview_window_frame = Some(frame);
    }
}
