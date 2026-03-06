return {
	{
		"RRethy/base16-nvim",
		priority = 1000,
		config = function()
			require('base16-colorscheme').setup({
				base00 = '#12121c',
				base01 = '#12121c',
				base02 = '#9999a5',
				base03 = '#9999a5',
				base04 = '#efefff',
				base05 = '#f8f8ff',
				base06 = '#f8f8ff',
				base07 = '#f8f8ff',
				base08 = '#ff9fb6',
				base09 = '#ff9fb6',
				base0A = '#c9caff',
				base0B = '#a5ffb5',
				base0C = '#e2e3ff',
				base0D = '#c9caff',
				base0E = '#d2d3ff',
				base0F = '#d2d3ff',
			})

			vim.api.nvim_set_hl(0, 'Visual', {
				bg = '#9999a5',
				fg = '#f8f8ff',
				bold = true
			})
			vim.api.nvim_set_hl(0, 'Statusline', {
				bg = '#c9caff',
				fg = '#12121c',
			})
			vim.api.nvim_set_hl(0, 'LineNr', { fg = '#9999a5' })
			vim.api.nvim_set_hl(0, 'CursorLineNr', { fg = '#e2e3ff', bold = true })

			vim.api.nvim_set_hl(0, 'Statement', {
				fg = '#d2d3ff',
				bold = true
			})
			vim.api.nvim_set_hl(0, 'Keyword', { link = 'Statement' })
			vim.api.nvim_set_hl(0, 'Repeat', { link = 'Statement' })
			vim.api.nvim_set_hl(0, 'Conditional', { link = 'Statement' })

			vim.api.nvim_set_hl(0, 'Function', {
				fg = '#c9caff',
				bold = true
			})
			vim.api.nvim_set_hl(0, 'Macro', {
				fg = '#c9caff',
				italic = true
			})
			vim.api.nvim_set_hl(0, '@function.macro', { link = 'Macro' })

			vim.api.nvim_set_hl(0, 'Type', {
				fg = '#e2e3ff',
				bold = true,
				italic = true
			})
			vim.api.nvim_set_hl(0, 'Structure', { link = 'Type' })

			vim.api.nvim_set_hl(0, 'String', {
				fg = '#a5ffb5',
				italic = true
			})

			vim.api.nvim_set_hl(0, 'Operator', { fg = '#efefff' })
			vim.api.nvim_set_hl(0, 'Delimiter', { fg = '#efefff' })
			vim.api.nvim_set_hl(0, '@punctuation.bracket', { link = 'Delimiter' })
			vim.api.nvim_set_hl(0, '@punctuation.delimiter', { link = 'Delimiter' })

			vim.api.nvim_set_hl(0, 'Comment', {
				fg = '#9999a5',
				italic = true
			})

			local current_file_path = vim.fn.stdpath("config") .. "/lua/plugins/dankcolors.lua"
			if not _G._matugen_theme_watcher then
				local uv = vim.uv or vim.loop
				_G._matugen_theme_watcher = uv.new_fs_event()
				_G._matugen_theme_watcher:start(current_file_path, {}, vim.schedule_wrap(function()
					local new_spec = dofile(current_file_path)
					if new_spec and new_spec[1] and new_spec[1].config then
						new_spec[1].config()
						print("Theme reload")
					end
				end))
			end
		end
	}
}
