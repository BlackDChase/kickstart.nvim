return {
	'mbbill/undotree',
	-- Define keymaps using the 'keys' field for lazy/packer.
	keys = {
		-- The mapping uses the <cmd> notation for efficiency and clarity.
		{"<leader>u", "<cmd>UndotreeToggle<CR>", mode = "n", desc = "Toggle [U]ndotree"},
	},
}
