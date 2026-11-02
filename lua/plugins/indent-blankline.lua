return {
  -- Indent guides, with the current scope highlighted (needs treesitter)
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl",
  event = "BufReadPost",
  opts = {
    indent = { char = "│" },
    scope = { show_start = false, show_end = false },
    exclude = { filetypes = { "alpha", "neo-tree", "oil", "lazy", "mason", "trouble" } },
  },
  config = function(_, opts)
    -- Some colorschemes don't define IblScope, and ibl errors without it.
    -- Link it to a safe group and re-apply after each colorscheme change.
    local function set_scope_hl()
      vim.api.nvim_set_hl(0, "IblScope", { link = "Delimiter" })
    end
    set_scope_hl()
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = vim.api.nvim_create_augroup("ibl-scope-hl", { clear = true }),
      callback = set_scope_hl,
    })
    require("ibl").setup(opts)
  end,
}
