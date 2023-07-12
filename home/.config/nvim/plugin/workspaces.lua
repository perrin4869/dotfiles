local project_files = require('project_files')

require("workspaces").setup{
  hooks = {
    open = { "NERDTreeToggle", project_files },
  }
}
