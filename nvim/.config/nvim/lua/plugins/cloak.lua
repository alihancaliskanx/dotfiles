local function toggle_current_var()
  local line = vim.api.nvim_get_current_line()
  local var_name = line:match("^([%w_]+)%s*=")
  if not var_name then
    vim.notify("Cloak: No variable found on current line", vim.log.levels.WARN)
    return
  end

  local cloak = require("cloak")
  local pattern = cloak.opts.patterns and cloak.opts.patterns[1]
  if not pattern or not pattern.cloak_pattern then
    return
  end

  local target_pat = "^(" .. var_name .. "=)(.+)"
  local found_idx = nil
  for idx, p in ipairs(pattern.cloak_pattern) do
    if type(p) == "table" and p[1] == target_pat then
      found_idx = idx
      break
    end
  end

  if found_idx then
    table.remove(pattern.cloak_pattern, found_idx)
    vim.notify("Cloak: Re-masked " .. var_name, vim.log.levels.INFO)
  else
    table.insert(pattern.cloak_pattern, 1, { target_pat, replace = "%1%2" })
    vim.notify("Cloak: Unmasked " .. var_name, vim.log.levels.INFO)
  end

  cloak.recloak_file(vim.api.nvim_buf_get_name(0))
end

return {
  {
    "laytan/cloak.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      enabled = true,
      cloak_character = "*",
      highlight_group = "Comment",
      patterns = {
        {
          file_pattern = {
            ".env*",
            "wrangler.toml",
            ".dev.vars",
          },
          cloak_pattern = "=.+",
        },
      },
    },
    keys = {
      { "<leader>vl", toggle_current_var, desc = "Env Variable: Lock/Unlock (Permanent)" },
      { "<leader>vp", "<cmd>CloakPreviewLine<cr>", desc = "Env Variable: Preview Line" },
      { "<leader>vt", "<cmd>CloakToggle<cr>", desc = "Env Variable: Toggle Buffer" },
    },
  },
}
