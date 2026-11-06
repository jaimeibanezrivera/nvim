return {
  "weirongxu/plantuml-previewer.vim",
  dependencies = {
    "tyru/open-browser.vim",
    "aklt/plantuml-syntax",
  },
  init = function()
    vim.g["plantuml_previewer#file_pattern"] = "*.pu,*.uml,*.plantuml,*.puml,*.iuml"
    vim.g["plantuml_previewer#save_format"] = "svg"
  end,
}

