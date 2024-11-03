local constants = require("constants")

local styles = data.raw["gui-style"].default

local no_background = { base = { size = 1, opacity = 0.0 } }
local colored_background = { base = { size = 1, opacity = 0.5 } }

-- FRAME STYLES

styles.fpal_window_dimmer = {
  type = "frame_style",
  graphical_set = {
    base = {
      filename = "__flib__/graphics/black.png",
      size = 1,
      opacity = 0.3,
    },
  },
}

styles.fpal_window = {
  type = "frame_style",
  graphical_set = {
    base = {
      filename = "__factory-palette__/graphics/box.png",
      size = 20,
      background_blur = true,
      opacity = 0.5,
      corner_size = 20,
      top_width = 20,
      bottom_width = 20,
      left_height = 20,
      right_height = 20,
      center_height = 20,
      center_width = 20,
      position = { 0, 0 },
    },
    shadow = default_outer_shadow,
  },
}

-- TITLEBAR STYLES

styles.fpal_titlebar_frame = {
  type = "frame_style",
  padding = 0,
  top_margin = -13,
  left_margin = -17,
  right_margin = -17,
  graphical_set = {
    base = {
      filename = "__factory-palette__/graphics/textbox.png",
      size = 20,
      opacity = 0.3,
      corner_size = 20,
      top_width = 20,
      bottom_width = 20,
      left_height = 1,
      right_height = 1,
      center_height = 1,
      center_width = 20,
      position = { 0, 0 },
      size = 1,
    },
  },
}

styles.fpal_titlebar_flow = {
  type = "horizontal_flow_style",
  horizontal_spacing = 8,
}

-- LABEL STYLES

styles.fpal_clickable_label = {
  type = "label_style",
  hovered_font_color = constants.colors.hovered,
  disabled_font_color = constants.colors.hovered,
}

styles.fpal_clickable_item_label = {
  type = "label_style",
  parent = "fpal_clickable_label",
  horizontally_stretchable = "on",
}

-- EMPTY WIDGET STYLES

styles.fpal_empty_widget = {
  type = "empty_widget_style",
  horizontally_stretchable = "on",
  graphical_set = no_background,
}

-- SCROLLPANE STYLES

styles.fpal_list_box_scroll_pane = {
  type = "scroll_pane_style",
  never_hide_by_search = true,
  padding = 0,
  extra_padding_when_activated = 0,
  top_margin = -4,
  left_margin = -6,
  graphical_set = no_background,
  background_graphical_set = no_background,
  vertical_flow_style = {
    type = "vertical_flow_style",
    vertical_spacing = 0,
    horizontally_stretchable = "on",
  },
}

-- TABLE STYLES

styles.fpal_list_box_table = {
  type = "table_style",
  horizontal_spacing = 0,
  left_cell_padding = 8,
  top_cell_padding = 2,
  right_cell_padding = 8,
  bottom_cell_padding = 2,
  apply_row_graphical_set_per_column = false,
  default_row_graphical_set = no_background,
  hovered_graphical_set = colored_background,
  selected_graphical_set = colored_background,
  clicked_graphical_set = no_background,
  selected_hovered_graphical_set = no_background,
  selected_clicked_graphical_set = no_background,
  column_alignments = {
    { column = 1, alignment = "left" },
    { column = 2, alignment = "center" },
    { column = 3, alignment = "center" },
  },
}

-- TEXTFIELD STYLES

styles.fpal_disablable_textfield = {
  type = "textbox_style",
  disabled_font_color = { 180, 150, 150 },
  default_font_color = { 255, 250, 250 },
  font_color = { 255, 250, 250 },
  left_margin = -4,
  left_padding = 8,
  minimal_height = 20,
  height = 20,
  active_background = no_background,
  disabled_background = no_background,
  default_background = no_background,
}

-- LINE STYLES

styles.fpal_titlebar_separator_line = {
  type = "line_style",
  top_margin = -6,
  left_margin = -17,
  right_margin = -17,
}
