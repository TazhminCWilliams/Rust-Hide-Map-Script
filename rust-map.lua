-- OBS Lua Script for Rust Map Cover Toggle

obs = obslua

-- Global table to store settings and hotkey id
data = {
    image = "",
    scene = "",
    delay = 0.0,
    hotkey_id = obs.OBS_INVALID_HOTKEY_ID
}

-- Script description shown in the OBS Scripts window
function script_description()
    return "Adds a hotkey for your Rust game map cover.\n\n" ..
           "Tutorial:\n" ..
           "- rust_map_source_name: The image source name used to cover the Rust map.\n" ..
           "- rust_scene_name: The scene affected by the hotkey. Leave blank to use the current scene.\n" ..
           "- rust_map_delay: Time before the map cover disappears (seconds).\n\n" ..
           "Setup:\n" ..
           "- Go to OBS Hotkeys and set the 'RustMap Push to Hide' hotkey to match your map key."
end

-- Define properties that are editable from the OBS Scripts window
function script_properties()
    local props = obs.obs_properties_create()
    obs.obs_properties_add_text(props, "rust_map_source_name", "Rust Map Source Name:", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_text(props, "rust_scene_name", "Rust Scene Name:", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_float_slider(props, "rust_map_delay", "Reveal Delay (sec):", 0.0, 5.0, 0.1)
    return props
end

-- Called when settings are changed in the Scripts window
function script_update(settings)
    data.image = obs.obs_data_get_string(settings, "rust_map_source_name")
    data.scene = obs.obs_data_get_string(settings, "rust_scene_name")
    data.delay = obs.obs_data_get_double(settings, "rust_map_delay")
end

-- Called when the script is loaded; registers the hotkey
function script_load(settings)
    data.hotkey_id = obs.obs_hotkey_register_frontend("RustMap_Push_to_Hide", "RustMap Push to Hide", mapkey_callback)
    local hotkey_saved_array = obs.obs_data_get_array(settings, "RustMap_Push_to_Hide")
    obs.obs_hotkey_load(data.hotkey_id, hotkey_saved_array)
    obs.obs_data_array_release(hotkey_saved_array)
end

-- Called when the script is saved; saves the hotkey settings
function script_save(settings)
    local hotkey_save_array = obs.obs_hotkey_save(data.hotkey_id)
    obs.obs_data_set_array(settings, "RustMap_Push_to_Hide", hotkey_save_array)
    obs.obs_data_array_release(hotkey_save_array)
end

-- Toggles the visibility of the specified source in the chosen or current scene
function toggle(state)
    if data.scene ~= "" then
        local scene_source = obs.obs_get_source_by_name(data.scene)
        if scene_source then
            local scene = obs.obs_scene_from_source(scene_source)
            local scene_item = obs.obs_scene_find_source(scene, data.image)
            if scene_item then
                obs.obs_sceneitem_set_visible(scene_item, state)
            else
                obs.script_log(obs.LOG_WARNING, "Scene item not found: " .. data.image)
            end
            obs.obs_source_release(scene_source)
        else
            obs.script_log(obs.LOG_WARNING, "Scene not found: " .. data.scene)
        end
    else
        local current_scene_source = obs.obs_frontend_get_current_scene()
        if not current_scene_source then
            obs.script_log(obs.LOG_WARNING, "No current scene found")
            return
        end
        local current_scene = obs.obs_scene_from_source(current_scene_source)
        local scene_item = obs.obs_scene_find_source(current_scene, data.image)
        obs.obs_source_release(current_scene_source)
        if scene_item then
            obs.obs_sceneitem_set_visible(scene_item, state)
        else
            obs.script_log(obs.LOG_WARNING, "Scene item not found in current scene: " .. data.image)
        end
    end
end

-- Timer callback to perform delayed hiding
function timer_callback()
    toggle(false)
    obs.timer_remove(timer_callback)
end

-- Hotkey callback function: shows the source on press, starts timer to hide on release
function mapkey_callback(pressed)
    if pressed then
        obs.timer_remove(timer_callback)
        toggle(true)
    else
        -- Schedule the hiding after the specified delay (converted to milliseconds)
        obs.timer_add(timer_callback, data.delay * 1000)
    end
end
