--!nonstrict
-- i3bar block separator: a 1px #666666 line inset from the bar edges
-- (i3bar's sep_voff_px); the bar's widget spacing supplies the side gaps.
local function render()
  barWidget.render(ui.row({ align = "center" }, {
    ui.box({ width = 1, height = 12, fill = "#666666" }),
  }))
end

render()

function update()
  noctalia.setUpdateInterval(3600000)
  render()
end
