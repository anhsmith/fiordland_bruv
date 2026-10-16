-- Gives every level-1 (section) slide a brand background colour, unless the
-- heading sets its own background-color. Override per deck with the
-- `sts-section-bg` metadata key.
--
-- The title slide gets the same colour when the deck sets no background of
-- its own in `title-slide-attributes`, because title-slide text is white.

local section_bg = "#051838"

local function has_background(attrs)
  for key, _ in pairs(attrs) do
    if tostring(key):match("^data%-background") then
      return true
    end
  end
  return false
end

local function read_meta(meta)
  if meta["sts-section-bg"] then
    section_bg = pandoc.utils.stringify(meta["sts-section-bg"])
  end

  local attrs = meta["title-slide-attributes"]
  if attrs == nil then
    meta["title-slide-attributes"] = pandoc.MetaMap({
      ["data-background-color"] = pandoc.MetaString(section_bg)
    })
    return meta
  end
  if not has_background(attrs) then
    attrs["data-background-color"] = pandoc.MetaString(section_bg)
    meta["title-slide-attributes"] = attrs
    return meta
  end
end

local function set_background(el)
  if el.level == 1 and not el.attributes["background-color"] then
    el.attributes["background-color"] = section_bg
  end
  return el
end

return {
  { Meta = read_meta },
  { Header = set_background }
}
