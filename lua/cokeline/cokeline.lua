local utils = require('cokeline/utils')

local map = vim.tbl_map
-- local fn = vim.fn

local concat = table.concat
local insert = table.insert
local unpack = unpack or table.unpack

local M = {}

M.Cokeline = {
  main = '',
  width = 0,
  lines = {},
  -- cutoffs = {
  --   right = '',
  --   left = '',
  -- },
  before = '',
  after = '',
}

local conclines = function(lines)
  return concat(map(
      function(line) return line:clickable() end,
      lines
  ))
end

function M.Cokeline:new()
  local cokeline = {}
  setmetatable(cokeline, self)
  self.__index = self
  cokeline.main = ''
  cokeline.width = 0
  cokeline.lines = {}
  -- cokeline.cutoffs = {
  --   right = '',
  --   left = '',
  -- }
  cokeline.before = ''
  cokeline.after = ''
  return cokeline
end

function M.Cokeline:add_line(line)
  self.width = self.width + line.width
  insert(self.lines, line)
end

function M.Cokeline:subline(args)
  local direction, lines
  -- local cutoff_fmt

  if args.upto then
    direction = 'left'
    lines = utils.reverse({unpack(self.lines, 1, args.upto)})
    -- cutoff_fmt = ' %s  '
  elseif args.startfrom then
    direction = 'right'
    lines = {unpack(self.lines, args.startfrom)}
    -- cutoff_fmt = '  %s '
  end

  -- local c = 0
  -- for i, line in ipairs(lines) do
  --   c = c + line.width
  --   if (c > args.available_space - fn.strwidth(cutoff_fmt:format(1))) and (i ~= #lines) then
  --     self.cutoffs[direction] = cutoff_fmt:format(#lines - i)
  --     args.available_space =
  --       args.available_space
  --         - fn.strwidth(self.cutoffs[direction])
  --     break
  --   end
  -- end

  local subline = M.Cokeline:new()

  -- -- Change this into a single while loop. If there are cutoffs update the
  -- -- available space, remove the last added line and diminish i by 1.
  -- for _, line in ipairs(lines) do
  --   if subline.width + line.width < args.available_space then
  --     subline:add_line(line)
  --   else
  --     line:shorten({
  --       direction = direction,
  --       available_space = args.available_space - subline.width
  --     })
  --     subline:add_line(line)
  --     break
  --   end
  -- end

  for _, line in ipairs(lines) do
    if subline.width + line.width < args.available_space then
      subline:add_line(line)
    else
      line:shorten({
        direction = direction,
        available_space = args.available_space - subline.width
      })
      subline:add_line(line)
      break
    end
  end

  if args.upto then
    subline.lines = utils.reverse(subline.lines)
  end

  return conclines(subline.lines)
end

function M.Cokeline:render(focused_line)
  local available_space_tot = vim.o.columns

  local available_space_minus_flwidth =
    available_space_tot - focused_line.width

  local available_space_left_right =
    math.floor((available_space_minus_flwidth)/2)

  local available_space = {
    left = available_space_left_right,
    right = available_space_left_right + available_space_minus_flwidth % 2,
  }

  local width_left_of_focused_line = focused_line.colstart - 1
  local width_right_of_focused_line = self.width - focused_line.colend

  local unused_space = {
    left = available_space.left - width_left_of_focused_line,
    right = available_space.right - width_right_of_focused_line,
  }

  local left, right

  if unused_space.left >= 0 then
    left = conclines({unpack(self.lines, 1, focused_line.index - 1)})
  else
    left = self:subline({
      upto = focused_line.index - 1,
      available_space = available_space.left + math.max(unused_space.right, 0),
    })
  end

  if unused_space.right >= 0 then
    right = conclines({unpack(self.lines, focused_line.index + 1)})
  else
    right = self:subline({
      startfrom = focused_line.index + 1,
      available_space = available_space.right + math.max(unused_space.left, 0),
    })
  end

  self.main = left .. self.lines[focused_line.index]:clickable() .. right

  return
    self.before
    -- .. self.cutoffs.left
    .. self.main
    -- .. self.cutoffs.right
    .. self.after
end

return M