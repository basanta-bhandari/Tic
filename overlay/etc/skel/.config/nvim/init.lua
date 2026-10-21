vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.termguicolors = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.undofile = true
vim.opt.signcolumn = "yes"
vim.g.mapleader = " "
vim.keymap.set("n", "<leader>w", "<cmd>write<cr>", { desc = "Save" })
vim.keymap.set("n", "<leader>q", "<cmd>quit<cr>", { desc = "Quit" })

vim.api.nvim_set_hl(0, "Normal", { fg = "#ffb000", bg = "#000000" })
vim.api.nvim_set_hl(0, "Comment", { fg = "#6c603f", italic = true })
vim.api.nvim_set_hl(0, "Statement", { fg = "#ffd75f", bold = true })
vim.api.nvim_set_hl(0, "String", { fg = "#ffe29a" })
vim.api.nvim_set_hl(0, "LineNr", { fg = "#6c603f" })
vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#ffd75f", bold = true })
