--[[
Telescope

Usage: tsc [options] [files]

Description:
  Telescope is a test framework for Lua that allows you to write tests
  and specs in a TDD or BDD style.

Options:

  -f,     --full            Show full report
  -q,     --quiet           Show don't show any stack traces
  -s      --silent          Don't show any output
  -h,-?   --help            Show this text
  -v      --version         Show version
  -c      --luacov          Output a coverage file using Luacov (http://luacov.luaforge.net/)
          --load=<file>     Load a Lua file before executing command
          --name=<pattern>  Only run tests whose name matches a Lua string pattern
          --shake           Use shake as the front-end for tests

  Callback options:
    --after=<function>        Run function given after each test
    --before=<function>       Run function before each test
    --err=<function>          Run function after each test that produces an error
    --fail<function>          Run function after each failing test
    --pass=<function>         Run function after each passing test
    --pending=<function>      Run function after each pending test
    --unassertive=<function>  Run function after each unassertive test

  An example callback:

    tsc --after="function(t) print(t.status_label, t.name, t.context) end" example.lua

An example test:

context("A context", function()
  before(function() end)
  after(function() end)
  context("A nested context", function()
    test("A test", function()
      assert_not_equal("ham", "cheese")
    end)
    context("Another nested context", function()
      test("Another test", function()
        assert_greater_than(2, 1)
      end)
    end)
  end)
  test("A test in the top-level context", function()
    assert_equal(1, 1)
  end)
end)

Project home:
  http://telescope.luaforge.net/

License:
  MIT/X11 (Same as Lua)

Author:
  Norman Clarke <norman@njclarke.com>. Please feel free to email bug
  reports, feedback and feature requests.
]]

local telescope = require 'telescope.telescope'

require "lfs"

function findFiles(path,list,pattern)
  pattern = pattern or ""
  local sep = "/"
  for file in lfs.dir(path) do
    if file ~= "." and file ~= ".." then
      local f = path..sep..file
      -- log:debug("Found test file: '",f,"'")
      local attr = lfs.attributes (f)
      assert(type(attr) == "table")
      if attr.mode == "directory" then
        findFiles(f,list,pattern)
      else
        -- add the file to the list:
        table.insert(list,f)
      end
    end
  end
end

return function(options)
  options = options or {
    files = {
      -- "tests/sanity_spec.lua",
      -- "tests/dis_spec.lua",
    },
    folders = {root_path.. "/modules/tests"},
    pattern = "",
    silent = false,
    quiet = false,
    full = true,
    err = function(t)
      log:error("In test '",t.name,"' in context '", t.context,"'")
    end,
    pass = function(t)
      log:notice("Test '",t.name,"' passed.")
    end,
    unassertive = function(t)
      log:warn("No assertion in test '",t.name,"'")
    end,
    before = function(t)
      log:debug("Entering test '",t.name,"' from '", t.context,"'")
    end,
    after = function(t)
      log:debug("Leaving test '",t.name,"'")
      coroutine.yield()
    end,
  }

  local callbacks = {}

  local function progress_meter(t)
    log:debug(t.status_label)
  end

  local function add_callback(callback, func)
    if callbacks[callback] then
      if type(callbacks[callback]) ~= "table" then
        callbacks[callback] = {callbacks[callback]}
      end
      table.insert(callbacks[callback], func)
    else
      callbacks[callback] = func
    end
  end

  -- method used to sleep for a given duration:
  local socket = require "socket"
  _G.sleep = function(secs)
    -- log:debug("Should sleep for ",secs," seconds here.") 
    local tick = socket.gettime()
    local curtick=tick
    while (curtick-tick)<secs do
      -- log:debug("Waiting a bit...") 
      coroutine.yield()
      curtick=socket.gettime()
    end
    -- log:debug("Done waiting!")
  end

  -- log:debug("Telescope version: ",telescope.version)

  -- load a file with custom functionality if desired
  -- if opts["load"] then dofile(opts["load"]) end

  local test_pattern = nil
  if options.pattern then
    test_pattern = function(t) return t.name:match(options.pattern) end 
  end

  -- set callbacks passed on command line
  local callback_args = { "after", "before", "err", "fail", "pass", "pending", "unassertive" }
  for _, callback in ipairs(callback_args) do
    if options[callback] then
      add_callback(callback, options[callback])
    end
  end

  local contexts = {}
  local files = options.files or {}

  -- insert the files found in the folders:
  local folders = options.folders or {}
  local fpat = options.file_pattern or ""
  
  for _,folder in ipairs(folders) do
    findFiles(folder,files,fpat)
  end

  for _, file in ipairs(files) do telescope.load_contexts(file, contexts) end

  local buffer = {}
  -- log:debug("Running tests...")
  local results = telescope.run(contexts, callbacks, test_pattern)
  local summary, data = telescope.summary_report(contexts, results)

  -- log:debug("Writing test reports...")

  if options.full then
    table.insert(buffer, telescope.test_report(contexts, results))
  end

  if not options.silent then
    table.insert(buffer, summary)
    if not options.quiet then
      local report = telescope.error_report(contexts, results)
      if report then
        table.insert(buffer, "")
        table.insert(buffer, report)
      end
    end
  end

  if #buffer > 0 then log:info('Unit Test results:\n'.. table.concat(buffer, "\n")) end
end

