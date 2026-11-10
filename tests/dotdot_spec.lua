require("plenary.async").tests.add_to_env()
local TmpDir = require("tests.tmpdir")
local test_util = require("tests.test_util")
local oil = require("oil")

a.describe("dotdot entries", function()
  local tmpdir
  a.before_each(function()
    tmpdir = TmpDir.new()
  end)
  a.after_each(function()
    if tmpdir then
      tmpdir:dispose()
      tmpdir = nil
    end
    test_util.reset_editor()
  end)

  local function setup(opts)
    oil.setup(vim.tbl_deep_extend("force", {
      view_options = { show_dotdot = true },
    }, opts or {}))
  end

  a.it("shows . and .. first and starts on the first real entry", function()
    tmpdir:create({ "a.txt", "sub/" })
    setup()
    test_util.actions.open({ tmpdir.path })
    assert.are.same({ "./", "../", "sub/", "a.txt" }, test_util.parse_entries(0))
    for _ = 1, 20 do
      if vim.fn.line(".") == 3 then
        break
      end
      a.util.sleep(10)
    end
    assert.equals(3, vim.fn.line("."))
  end)

  a.it("is disabled by default", function()
    tmpdir:create({ "a.txt" })
    oil.setup()
    test_util.actions.open({ tmpdir.path })
    assert.are.same({ "a.txt" }, test_util.parse_entries(0))
  end)

  a.it("moves to the end when sorting by name descending", function()
    tmpdir:create({ "a.txt", "b.txt" })
    setup({ view_options = { show_dotdot = true, sort = { { "name", "desc" } } } })
    test_util.actions.open({ tmpdir.path })
    assert.are.same({ "b.txt", "a.txt", "./", "../" }, test_util.parse_entries(0))
  end)

  a.it("does not produce mutation diffs", function()
    tmpdir:create({ "a.txt" })
    setup()
    test_util.actions.open({ tmpdir.path })
    local parser = require("oil.mutator.parser")
    local diffs, errors = parser.parse(0)
    assert.equals(0, #diffs)
    assert.equals(0, #errors)

    -- Removing the synthetic ".." line must not create a delete action
    vim.api.nvim_buf_set_lines(0, 1, 2, true, {})
    diffs, errors = parser.parse(0)
    assert.equals(0, #diffs)
    assert.equals(0, #errors)
  end)
end)
