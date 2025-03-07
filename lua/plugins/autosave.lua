return {
  "Pocco81/auto-save.nvim",
  config = function()
    require("auto-save").setup({
      -- Your configuration goes here
      enabled = true, -- Enable auto-save
      trigger_events = { "InsertLeave", "TextChanged" }, -- Save on these events
      debounce_delay = 1000, -- Delay after which the file is saved (in milliseconds)
      execution_message = {
        message = function() -- Customize the save message
          return "AutoSave: saved at " .. vim.fn.strftime("%H:%M:%S")
        end,
        dim = 0.18, -- Dim the message text
        cleaning_interval = 1250, -- How long the message stays visible (in milliseconds)
      },
      -- Optional: Callback function to run before saving
      pre_save_hook = function()
        -- Example: Do something before saving
        print("AutoSave: Saving file...")
      end,
    })
  end,
}
