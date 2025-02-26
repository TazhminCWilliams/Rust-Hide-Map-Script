import obspython as obs
import time

class Hotkey:
    def __init__(self, callback, obs_settings, hotkey_id):
        self.obs_settings = obs_settings
        self.hotkey_id = obs.OBS_INVALID_HOTKEY_ID
        self.hotkey_saved_key = None
        self.callback = callback
        self.hotkey_id_str = hotkey_id
        self.load()

    def load(self):
        self.hotkey_saved_key = obs.obs_data_get_array(self.obs_settings, self.hotkey_id_str)
        obs.obs_data_array_release(self.hotkey_saved_key)
        self.hotkey_id = obs.obs_hotkey_register_frontend(self.hotkey_id_str, self.hotkey_id_str, self.callback)
        obs.obs_hotkey_load(self.hotkey_id, self.hotkey_saved_key)

    def save(self):
        self.hotkey_saved_key = obs.obs_hotkey_save(self.hotkey_id)
        obs.obs_data_set_array(self.obs_settings, self.hotkey_id_str, self.hotkey_saved_key)
        obs.obs_data_array_release(self.hotkey_saved_key)

def mapkey_callback(pressed):
    if pressed:
        toggle(True)
    else:  
        time.sleep(data.delay)
        toggle(False)

def toggle(state):
    current_scene_source = obs.obs_frontend_get_current_scene()
    if not current_scene_source:
        return

    current_scene = obs.obs_scene_from_source(current_scene_source)
    obs.obs_source_release(current_scene_source)

    if not current_scene:
        return

    scene_item = obs.obs_scene_find_source(current_scene, data.image)
    if scene_item:
        obs.obs_sceneitem_set_visible(scene_item, state)

def script_description():
    return (
        "Adds a hotkey for your Rust game map cover.\n\n"
        "Tutorial:\n"
        "- rust_map_source_name: The image source name used to cover the Rust map.\n"
        "- rust_scene_name: The scene affected by the hotkey. Leave blank if irrelevant.\n"
        "- reveal delay: Time before the map cover disappears (seconds).\n\n"
        "Setup:\n"
        "- Go to OBS Hotkeys and set the 'RustMap Push to Hide' hotkey to match your map key."
    )

def script_properties():
    properties = obs.obs_properties_create()
    obs.obs_properties_add_text(properties, "rust_map_source_name", "Rust Map Source Name:", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_text(properties, "rust_scene_name", "Rust Scene Name:", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_float_slider(properties, "rust_map_delay", "Reveal Delay (sec):", 0.0, 5.0, 0.1)
    return properties

def script_update(settings):
    data.image = obs.obs_data_get_string(settings, "rust_map_source_name")
    data.scene = obs.obs_data_get_string(settings, "rust_scene_name")
    data.delay = obs.obs_data_get_double(settings, "rust_map_delay")

def script_load(settings):
    data.hotkey = Hotkey(mapkey_callback, settings, "RustMap_Push_to_Hide")
    script_update(settings)

def script_save(settings):
    data.hotkey.save()

class Data:
    image = ""
    scene = ""
    delay = 0.0
    hotkey = None

data = Data()
