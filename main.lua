local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local logger = require("logger")
local _ = require("gettext")

-- Plugin main class
local ForceRefresh = WidgetContainer:extend {
    name = "forcerefresh",
    is_doc_only = true, -- Only runs when a document is open
}

function ForceRefresh:init()
    logger.info("ForceRefresh plugin initialized.")

    -- Load saved settings or use defaults
    self.enabled = G_reader_settings:readSetting("forcerefresh_enabled", false)
    self.refresh_mode = G_reader_settings:readSetting("forcerefresh_mode", "flashui")
    self.refresh_on_suspend = G_reader_settings:readSetting("forcerefresh_on_suspend", false)

    -- Add to main menu
    self.ui.menu:registerToMainMenu(self)
end

function ForceRefresh:addToMainMenu(menu_items)
    menu_items.force_refresh = {
        text = _("Force refresh"),
        sorting_hint = "tools",
        sub_item_table = {
            {
                text = _("Enable forced refresh"),
                checked_func = function()
                    return self.enabled
                end,
                callback = function()
                    self.enabled = not self.enabled
                    G_reader_settings:saveSetting("forcerefresh_enabled", self.enabled)
                    logger.info("ForceRefresh on page turn:", self.enabled)
                end
            },
            {
                text = _("Refresh on suspend/sleep"),
                checked_func = function()
                    return self.refresh_on_suspend
                end,
                callback = function()
                    self.refresh_on_suspend = not self.refresh_on_suspend
                    G_reader_settings:saveSetting("forcerefresh_on_suspend", self.refresh_on_suspend)
                    logger.info("ForceRefresh on suspend:", self.refresh_on_suspend)
                end,
            },
            {
                text = _("Refresh mode"),
                sub_item_table = {
                    {
                        text = _("Full refresh (slowest, cleanest)"),
                        checked_func = function()
                            return self.refresh_mode == "full"
                        end,
                        callback = function()
                            self.refresh_mode = "full"
                            G_reader_settings:saveSetting("forcerefresh_mode", "full")
                            logger.info("ForceRefresh mode set to: full")
                        end,
                    },
                    {
                        text = _("Partial refresh (faster, some ghosting)"),
                        checked_func = function()
                            return self.refresh_mode == "partial"
                        end,
                        callback = function()
                            self.refresh_mode = "partial"
                            G_reader_settings:saveSetting("forcerefresh_mode", "partial")
                            logger.info("ForceRefresh mode set to: partial")
                        end,
                    },
                    {
                        text = _("Flash UI (balanced)"),
                        checked_func = function()
                            return self.refresh_mode == "flashui"
                        end,
                        callback = function()
                            self.refresh_mode = "flashui"
                            G_reader_settings:saveSetting("forcerefresh_mode", "flashui")
                            logger.info("ForceRefresh mode set to: flashui")
                        end,
                    },
                    {
                        text = _("Flash partial (fast with quick flash)"),
                        checked_func = function()
                            return self.refresh_mode == "flashpartial"
                        end,
                        callback = function()
                            self.refresh_mode = "flashpartial"
                            G_reader_settings:saveSetting("forcerefresh_mode", "flashpartial")
                            logger.info("ForceRefresh mode set to: flashpartial")
                        end,
                    },
                },
            },
        }
    }
end

-- Register plugin to a page turn event
function ForceRefresh:onPageUpdate(page_number)
    if self.enabled then
        logger.dbg("ForceRefresh: page:", page_number, "mode:", self.refresh_mode)

        -- force refresh the page again after some time
        UIManager:scheduleIn(0.1, function()
            UIManager:setDirty(self.ui, self.refresh_mode)
        end
        )

        -- allow other handlers to handle this event
        return false
    end
end

-- Called when a document is opened
function ForceRefresh:onReaderReady()
    -- do something here
end

-- Called when a document is closed
function ForceRefresh:onCloseDocument()
    -- do something here
end

-- Called when device is about to suspend/sleep
function ForceRefresh:onSuspend()
    if self.refresh_on_suspend then
        logger.dbg("ForceRefresh: Refreshing screen before suspend with mode:", self.refresh_mode)

        -- force refresh the screen after some time
        UIManager:scheduleIn(0.1, function()
            UIManager:setDirty(self.ui, self.refresh_mode)
        end
        )

        -- allow other handlers to handle this event
        return false
    end
end

return ForceRefresh
