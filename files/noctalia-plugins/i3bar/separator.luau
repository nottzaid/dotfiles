--!nonstrict
-- i3bar-style block separator: a quiet 1px line, inset from the bar edges;
-- the bar's widget spacing supplies the side gaps.
local function render()
  -- The bar centers this column: 4px above the line shifts its ink down 2px,
  -- matching the measured visual center of the status text.
  barWidget.render(ui.column({ align = "center", gap = 0 }, {
    ui.box({ width = 1, height = 4, fill = "#00000000" }),
    ui.box({ width = 1, height = 14, fill = "#45475a" }),
  }))
end

render()

function update()
  noctalia.setUpdateInterval(3600000)
  render()
end
