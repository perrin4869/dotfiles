local project_files = require('project_files')

require("workspaces").setup{
  hooks = {
    open = { "NvimTreeOpen", project_files },
  }
}
