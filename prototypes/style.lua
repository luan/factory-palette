local constants = require("constants")

local styles = data.raw["gui-style"].default

-- FRAME STYLES

styles.qis_window_dimmer = {
	type = "frame_style",
	graphical_set = {
		base = {
			filename = "__flib__/graphics/black.png",
			size = 1,
			opacity = 0.3,
		},
	},
}

-- LABEL STYLES

styles.qis_clickable_label = {
	type = "label_style",
	hovered_font_color = constants.colors.hovered,
	disabled_font_color = constants.colors.hovered,
}

styles.qis_clickable_item_label = {
	type = "label_style",
	parent = "qis_clickable_label",
	horizontally_stretchable = "on",
}

-- EMPTY WIDGET STYLES

styles.qis_empty_widget = {
	type = "empty_widget_style",
	horizontally_stretchable = "on",
}

-- SCROLLPANE STYLES

styles.qis_list_box_scroll_pane = {
	type = "scroll_pane_style",
	never_hide_by_search = true,
	padding = 0,
	extra_padding_when_activated = 0,
	top_margin = 2,
	graphical_set = {
		base = {
			position = { 17, 0 },
			corner_size = 8,
			center = { position = { 42, 8 }, size = 1 },
			draw_type = "outer"
		},
		shadow = default_inner_shadow,
	},
	vertical_flow_style = {
		type = "vertical_flow_style",
		vertical_spacing = 0,
		horizontally_stretchable = "on",
	},
}

-- TABLE STYLES

styles.qis_list_box_table = {
	type = "table_style",
	horizontal_spacing = 0,
	left_cell_padding = 8,
	top_cell_padding = 2,
	right_cell_padding = 8,
	bottom_cell_padding = 2,
	apply_row_graphical_set_per_column = true,
	default_row_graphical_set = { position = { 208, 17 }, corner_size = 8 },
	hovered_graphical_set = { position = { 34, 17 }, corner_size = 8 },
	clicked_graphical_set = { position = { 51, 17 }, corner_size = 8 },
	selected_graphical_set = { position = { 51, 17 }, corner_size = 8 },
	selected_hovered_graphical_set = { position = { 369, 17 }, corner_size = 8 },
	selected_clicked_graphical_set = { position = { 352, 17 }, corner_size = 8 },
	column_alignments = {
		{ column = 1, alignment = "left" },
		{ column = 2, alignment = "center" },
		{ column = 3, alignment = "center" },
	},
}

-- TEXTFIELD STYLES

styles.qis_disablable_textfield = {
	type = "textbox_style",
	disabled_background = styles.textbox.default_background,
	disabled_font_color = button_default_font_color,
}
