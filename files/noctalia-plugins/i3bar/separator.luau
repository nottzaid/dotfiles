--!nonstrict
-- i3bar-style block separator: a quiet 1px line, inset from the bar edges;
-- the bar's widget spacing supplies the side gaps.
local function render()
  barWidget.render(ui.row({ align = "center" }, {
    ui.box({ width = 1, height = 14, fill = "#45475a" }),
  }))
end

render()

function update()
  noctalia.setUpdateInterval(3600000)
  render()
end
