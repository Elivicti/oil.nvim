local test_util = require("tests.test_util")
local config = require("oil.config")
local files = require("oil.adapters.files")
local view = require("oil.view")

describe("hidden highlight groups", function()
  before_each(function()
    test_util.reset_editor()
  end)

  after_each(function()
    test_util.reset_editor()
  end)

  ---@param entry oil.InternalEntry
  ---@param is_hidden boolean
  ---@return string[]
  local function highlight_groups(entry, is_hidden)
    local chunks = view.format_entry_cols(entry, {}, {}, files, is_hidden, 0)
    local ret = {}
    for _, chunk in ipairs(chunks) do
      if type(chunk) == "table" then
        table.insert(ret, chunk[2])
      end
    end
    return ret
  end

  local function file_entry(name)
    return { 1, name, "file", {} }
  end

  local function dir_entry(name)
    return { 1, name, "directory", {} }
  end

  local function link_entry(meta)
    return { 1, "link", "link", meta }
  end

  it("uses the default Oil*Hidden groups", function()
    assert.are.same({ "OilFileHidden" }, highlight_groups(file_entry(".file"), true))
    assert.are.same({ "OilDirHidden" }, highlight_groups(dir_entry(".dir"), true))
    assert.are.same({ "OilSocketHidden" }, highlight_groups({ 1, ".sock", "socket", {} }, true))

    assert.are.same(
      { "OilOrphanLinkHidden", "OilOrphanLinkTargetHidden" },
      highlight_groups(link_entry({ link = "target" }), true)
    )
    assert.are.same(
      { "OilLinkHidden", "OilLinkTargetHidden" },
      highlight_groups(link_entry({ link = "target", link_stat = { type = "file" } }), true)
    )
  end)

  it("keeps the normal groups for visible entries", function()
    assert.are.same({ "OilFile" }, highlight_groups(file_entry("file"), false))
    assert.are.same({ "OilDir" }, highlight_groups(dir_entry("dir"), false))
    assert.are.same(
      { "OilOrphanLink", "OilOrphanLinkTarget" },
      highlight_groups(link_entry({ link = "target" }), false)
    )
  end)

  it("accepts a single group for all hidden entries", function()
    config.view_options.hidden_highlight = "Comment"

    assert.are.same({ "Comment" }, highlight_groups(file_entry(".file"), true))
    assert.are.same({ "Comment" }, highlight_groups(dir_entry(".dir"), true))
    assert.are.same(
      { "Comment", "Comment" },
      highlight_groups(link_entry({ link = "target" }), true)
    )
    -- Non-hidden entries are unaffected
    assert.are.same({ "OilFile" }, highlight_groups(file_entry("file"), false))
  end)

  it("supports per-entry-type overrides", function()
    config.view_options.hidden_highlight = {
      file = "MyFileHidden",
      -- false falls back to the normal group
      directory = false,
      link_target = "MyLinkTargetHidden",
    }

    assert.are.same({ "MyFileHidden" }, highlight_groups(file_entry(".file"), true))
    assert.are.same({ "OilDir" }, highlight_groups(dir_entry(".dir"), true))
    assert.are.same(
      { "OilLinkHidden", "MyLinkTargetHidden" },
      highlight_groups(link_entry({ link = "target", link_stat = { type = "file" } }), true)
    )
    -- Unset keys keep their defaults
    assert.are.same(
      { "OilOrphanLinkHidden", "OilOrphanLinkTargetHidden" },
      highlight_groups(link_entry({ link = "target" }), true)
    )
  end)

  it("can be disabled entirely", function()
    config.view_options.hidden_highlight = false

    assert.are.same({ "OilFile" }, highlight_groups(file_entry(".file"), true))
    assert.are.same({ "OilDir" }, highlight_groups(dir_entry(".dir"), true))
    assert.are.same(
      { "OilLink", "OilLinkTarget" },
      highlight_groups(link_entry({ link = "target", link_stat = { type = "file" } }), true)
    )
  end)
end)
