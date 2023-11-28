local obs = obslua
local os = require("os")

-----------------------------------------------------------------------------------

local KICK          = " %[Client thread/INFO%]: %[CHAT%] A kick occurred in your connection, so you were put in the Bed Wars lobby!"
local LOBBY_BLANK_1 = " %[Client thread/INFO%]: %[CHAT%]                                      "
local LOBBY_BLANK_2 = " %[Client thread/INFO%]: %[CHAT%]                          "
local NEW_GAME_1    = " %[Client thread/INFO%]: %[CHAT%] Sending you to mini"
local NEW_GAME_2    = " %[Client thread/INFO%]: %[CHAT%]        "

local START_MESSAGES = {
    " %[Client thread/INFO%]: %[CHAT%]      Protect your bed and destroy the enemy beds.",
    " %[Client thread/INFO%]: %[CHAT%] Cages opened! FIGHT!",
    " %[Client thread/INFO%]: %[CHAT%] Teaming with the Murderer is not allowed!",
    " %[Client thread/INFO%]: %[CHAT%] The game has started!",
}

local APPDATA = os.getenv('APPDATA')
local USERPROFILE = os.getenv('USERPROFILE')

local CLIENTS = {
    ['Vanilla / Forge'] = APPDATA .. '\\.minecraft\\logs\\latest.log',
    ['Lunar Client'] = USERPROFILE .. '\\.lunarclient\\offline\\multiver\\logs\\latest.log',
    ['Badlion Client'] = APPDATA .. '\\.minecraft\\logs\\blclient\\minecraft\\latest.log',
    ['Feather Client'] = APPDATA .. '\\.minecraft\\logs\\latest.log'
}

FILE = ""

-----------------------------------------------------------------------------------

local clock = os.clock
function sleep(n)  -- seconds
  local t0 = clock()
  while clock() - t0 <= n do end
end

local AQS = {}

function AQS:new()
    local aqs = {
        client = "",
        queuing_scene = "",
        current_scene = nil,
        old_scene = "",
        custom_logs_path = "",
        delay = 3,
        index = 0,
        toggle = false,
        status = "",
        hide_in_lobby = false,
        file_ptr = nil
    }
    setmetatable(aqs, self)
    self.__index = self
    return aqs
end

function AQS:setup()
    self.log_file = self:get_log_file()
    -- self.original_edit = get_file_modified_time(self.log_file)
    if not self.log_file then
        print('Invalid log file path')
        return
    end

    if FILE ~= "" then
        FILE:close()
    end
    FILE = io.open(self.log_file, 'r')
    if not FILE then
        print('Failed to open log file')
        return
    end

    local content = FILE:read("*a")
    print("File Opened")

    local lines = self:split(content, "\n")
    self.index = #lines

    print('Setup completed successfully')
end


function AQS:split(str, separator)
    local result = {}
    local pattern = string.format("([^%s]+)", separator)
    str:gsub(pattern, function(c) result[#result + 1] = c end)
    return result
end

function AQS:get_log_file()
    if self.client == 'Custom' then
        return self.custom_logs_path
    elseif self.client == 'Auto' then
        self.client = self:detect_client()
    end

    return CLIENTS[self.client]
end

function AQS:detect_client()
    -- TODO: Implement client detection logic here
    return nil
end

function AQS:show_screen()
    if self.current_scene then
        obs.obs_frontend_set_current_scene(self.current_scene)
        print('Showing screen: ' .. obs.obs_source_get_name(self.current_scene))
    end
end

function AQS:hide_screen()
    local scenes = obs.obs_frontend_get_scenes()
    local current_scene = obs.obs_frontend_get_current_scene()
    local current_scene_name = obs.obs_source_get_name(current_scene)
    if current_scene_name == self.queuing_scene then
        return
    end

    for _, scene in ipairs(scenes) do
        local name = obs.obs_source_get_name(scene)
        if name == self.queuing_scene then
            if current_scene ~= scene then
                self.current_scene = current_scene
            end
            obs.obs_frontend_set_current_scene(scene)
            print('Hiding screen: ' .. name)
            obs.source_list_release(scenes)
            return
        end
    end

    self.current_scene = current_scene
    local scene = obs.obs_scene_create(self.queuing_scene)
    obs.obs_scene_release(scene)
    obs.source_list_release(scenes)
    print('Hiding screen: ' .. self.queuing_scene)
end

function AQS:process_line(line)
    self.status = self:get_status(line)

    if self.status == 'lobby' or self.status == 'blanklobby1' then
        if not self.hide_in_lobby then
            self:show_screen()
        end
    end

    if self.status == 'game started' then
        self:show_screen()
    elseif self.status == 'game finished' or self.status == 'prelobby' then
        if self.status == 'game finished' then
            sleep(self.delay)
        end
        self:hide_screen()
    end
end

function AQS:get_status(line)


    if line:sub(-#KICK) == KICK then
        return "lobby"

    elseif string.find(line, "has joined %(") or string.find(line, NEW_GAME_1) then
        return "prelobby"
    end

    local found = false

    for _, substring in ipairs(START_MESSAGES) do
        if string.find(line, substring) then
            found = true
            break
        end
    end

    if found then
        return "game started"
    elseif string.find(line, "1st Killer - ") and string.find(line, " %[Client thread/INFO%]: %[CHAT%] ") then
        return "game finished"
    elseif string.find(line, LOBBY_BLANK_1) then
        return "blanklobby1"
    elseif string.find(line, LOBBY_BLANK_2) then
        return "lobby"
    end
end

function AQS:read_latest_lines()

    if self.log_file == "" then
        print('No log file specified')
        return
    end

    -- local modified_time = get_file_modified_time(self.log_file)

    -- if modified_time ~= self.original_edit then
    --     self.original_edit = modified_time
    -- end
    
    if not FILE then
        return
    end

    local lines = {}
    for line in FILE:lines() do
        table.insert(lines, line)
    end

    if #lines < self.index then
        self.index = #lines
    end

    for i = self.index + 1, #lines do
        self:process_line(lines[i])
    end

    self.index = #lines

    -- if os.time() - modified_time > 30 then
    --     print('Something may have gone wrong')
    -- end
end


-- function get_file_modified_time(filepath)
--     local file = io.open(filepath, "r")
--     if file then
--         local modified_time = file:seek("end")
--         file:close()
--         return modified_time
--     end
--     return nil
-- end

local aqs = AQS:new()

function loop()

    if aqs.toggle == false then
        obs.remove_current_callback()
        print('Script is disabled')
        return
    end

    aqs:read_latest_lines()
end

-----------------------------------------------------------------------------------

function script_description()
    return "Switch scene to queuing when queuing a Bedwars game.\n\nBy Oery"
end

function script_defaults(settings)
    obs.obs_data_set_default_string(settings, 'client', 'Auto')
    obs.obs_data_set_default_string(settings, 'queuing_scene', 'Queuing Scene')
    obs.obs_data_set_default_string(settings, 'custom_logs_path', '')
    obs.obs_data_set_default_int(settings, 'delay', 3)
    obs.obs_data_set_default_bool(settings, 'toggle', true)
    obs.obs_data_set_default_bool(settings, 'hide_in_lobby', true)
end

function script_properties()
    local props = obs.obs_properties_create()
    local p

    p = obs.obs_properties_add_bool(props, 'toggle', 'Enable Script')

    p = obs.obs_properties_add_list(props, 'client', 'Minecraft Client', obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
    -- obs.obs_property_list_add_string(p, 'Auto', 'Auto')
    obs.obs_property_list_add_string(p, 'Vanilla / Forge', 'Vanilla / Forge')
    obs.obs_property_list_add_string(p, 'Lunar Client', 'Lunar Client')
    obs.obs_property_list_add_string(p, 'Badlion Client', 'Badlion Client')
    obs.obs_property_list_add_string(p, 'Feather Client', 'Feather Client')
    obs.obs_property_list_add_string(p, 'Custom', 'Custom')

    p = obs.obs_properties_add_text(props, 'custom_logs_path', 'Custom Logs Path', obs.OBS_TEXT_DEFAULT)
    scene_selector = obs.obs_properties_add_list(props, "queuing_scene", "Queuing Scene", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)

    scenes = obs.obs_frontend_get_scenes()
    for _, scene in ipairs(scenes) do
        name = obs.obs_source_get_name(scene)
        obs.obs_property_list_add_string(scene_selector, name, name)
    end

    p = obs.obs_properties_add_int_slider(props, 'delay', 'Delay after win (s)', 0, 10, 1)
    p = obs.obs_properties_add_bool(props, 'hide_in_lobby', 'Hide Screen in lobbies')

    return props
end

function script_update(settings)
    aqs.client = obs.obs_data_get_string(settings, 'client')
    aqs.queuing_scene = obs.obs_data_get_string(settings, 'queuing_scene')
    aqs.custom_logs_path = obs.obs_data_get_string(settings, 'custom_logs_path')
    aqs.delay = obs.obs_data_get_int(settings, 'delay')
    aqs.toggle = obs.obs_data_get_bool(settings, 'toggle')
    aqs.hide_in_lobby = obs.obs_data_get_bool(settings, 'hide_in_lobby')

    aqs.log_file = ""
    obs.timer_remove(loop)

    if aqs.toggle then
        print('Restarting AQS')
        aqs:setup()
        obs.timer_add(loop, 5000)
    end
end

function script_unload()
    obs.timer_remove(loop)
    if FILE ~= "" then
        FILE:close()
    end
end
