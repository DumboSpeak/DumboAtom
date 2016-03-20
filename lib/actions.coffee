utils = require './utils'
{Disposable, CompositeDisposable, Point, Range} = require 'atom'

disposables = new CompositeDisposable()

searchAhead = (searchPattern, num, back) ->
  count = 0
  editor = atom.workspace.getActiveTextEditor()
  start = editor.getCursorBufferPosition()
  end = start
  lastPos = utils.getLastPos(editor).toArray()
  while count < num
    result = scanThroughRegex([end, lastPos], searchPattern, 'ahead')
    if result == null
      break
    end = result.range.end
    lastLength = result.matchText.length
    count++
  if end == start
    return null
  if back is true
    end = utils.moveBackwards(end, lastLength)
  return new Range(start, end)

searchBehind = (searchPattern, num, back) ->
  editor = atom.workspace.getActiveTextEditor()
  start = editor.getCursorBufferPosition()
  foo = start
  lastPos = [0, 0]
  count = 0
  end = null
  while count < num
    result = scanThroughRegex([start, lastPos], searchPattern, 'behind')
    if result == null
      break
    end = result.range.start
    lastLength = result.matchText.length
    start = end
    count++
  if end == null
    return null
  if back is true
    end = utils.moveForwards(end, lastLength)
  return new Range(foo, end)

scanThroughRegex = (searchRange, regex, direction) ->
  result = null
  editor = atom.workspace.getActiveTextEditor()
  # this is stupid. can functions be initialized as variables?
  if direction == 'ahead'
    editor.scanInBufferRange regex, searchRange, (hit) =>
      hit.stop()
      if hit.matchText != ''
        result = hit
  else if direction == 'behind'
    editor.backwardsScanInBufferRange regex, searchRange, (hit) =>
      hit.stop()
      if hit.matchText != ''
        result = hit
  console.log(result)
  return result

scanBackwardsThroughRegex = (searchRange, regex) ->
  result = null
  editor = atom.workspace.getActiveTextEditor()
  editor.backwardsScanInBufferRange regex, searchRange, (hit) =>
    hit.stop()
    if hit.matchText != ''
      result = hit
  return result

doAction = (actionChar, range, reversed=false) ->
  editor = atom.workspace.getActiveTextEditor()
  console.log(range)
  if actionChar == 'm'
    dest = if reversed then range.start else range.end
    editor.setCursorBufferPosition(dest)
  else if actionChar in ['y', 'c']
    atom.clipboard.write(range.toString())
  else if actionChar in ['d', 'c']
    editor.setTextInBufferRange(range, '')
  else if actionChar == 's'
    editor.setSelectedBufferRange(range, options={reversed: reversed})
  else if actionChar == 'p'
    editor.setTextInBufferRange(range, atom.clipboard.read())

class ActionHandler

  constructor: (@editor, num, action, arg) ->
    @num = parseInt(num)
    @action = action
    @arg = arg
    @start = @editor.getCursorBufferPosition()
    @lastPos = utils.getLastPos(@editor).toArray()

  searchAhead: (back, start=@start, lastPos=@lastPos, num=@num) ->
    count = 0
    end = start
    while count < num
      result = @scanForwardsThroughRegex([end, lastPos], searchPattern)
      if result == null
        break
      end = result.range.end
      lastLength = result.matchText.length
      count++
    if end == start
      return null
    if back is true
      end = utils.moveBackwards(end, lastLength)
    return new Range(start, end)

   searchBehind: (back, start=@start,  lastPos=@lastPos, num=@num) ->
    lastPos = start
    count = 0
    end = null
    while count < num
      result = @scanBackwardsThroughRegex [start, lastPos], @argRegex
      if result == null
        break
      end = result.range.start
      lastLength = result.matchText.length
      start = end
      count++
    if end == null
      return null
    if back is true
      end = utils.moveForwards end, lastLength
    new Range(lastPos, end)

  modifyLine: () ->
    start = @start.toArray()
    start[1] = 0
    count = 0
    endRow = Math.min(start[0] + @num - 1, @lastPos[0])
    endCol = @editor.lineTextForBufferRow(endRow).length
    return new Range(start, [endRow, endCol])

  modifyTextObject: (outer) ->
    start = @start.toArray()
    end = @start.toArray()
    start[1] = 0
    end[1] = @editor.lineTextForBufferRow(end[0]).length
    behind = @scanBackwardsThroughRegex([@start, start], @argRegex)
    ahead = @scanForwardsThroughRegex([@start, end], @argRegex)
    if ahead != null and behind != null
      if outer
        return new Range(behind.range.start, ahead.range.end)
      else
        return new Range(behind.range.end, ahead.range.start)
    else if ahead != null
      range = @searchAhead(!outer, ahead.range.end, end)
      if !outer
        startPoint = utils.moveForwards(range.start, ahead.matchText.length)
        return new Range(startPoint, range.end)
      startPoint = utils.moveBackwards(range.start, ahead.matchText.length)
      return new Range(startPoint, range.end)
    else if behind != null
      if outer
        behind = behind.range.end
      else
        behind = behind.range.start
      return @searchBehind(!outer, behind, end)
    else
      return null

  getSurroundRange: () ->
    console.log(@arg)
    start = @start
    end = @start
    pos1 = null
    pos2 = null
    oppoCharCount = 0
    while pos1 == null
      result = @scanBackwardsThroughRegex [start, [0, 0]], @argRegex
      if result == null
        return null
      start = result.range.start
      if result.matchText == @arg[1]
        oppoCharCount++
      else
        if oppoCharCount > 0
          oppoCharCount--
        else
          pos1 = result.range.start
    oppoCharCount = 0
    while pos2 == null
      result = @scanForwardsThroughRegex [end, @lastPos], @argRegex
      if result == null
        return null
      end = result.range.end
      if result.matchText == @arg[0]
        oppoCharCount++
      else
        if oppoCharCount > 0
          oppoCharCount--
        else
          pos2 = result.range.end
    if null not in [pos1, pos2] and @arg.length == 3
      @arg = @arg[0] + @arg[1]
      return new Range(utils.moveForwards(start, 1), utils.moveBackwards(end, 1))
    return new Range(pos1, pos2)

  scanForwardsThroughRegex: (searchRange, regex) =>
    result = null
    @editor.scanInBufferRange regex, searchRange, (hit) =>
      hit.stop()
      if hit.matchText != ''
        result = hit
    result

  scanBackwardsThroughRegex: (searchRange, regex) ->
    result = null
    @editor.backwardsScanInBufferRange regex, searchRange, (hit) =>
      hit.stop()
      if hit.matchText != ''
        result = hit
    result

FUNCS =
  'f':
    'funcName': 'searchAhead'
    'regexStr': null
    'num': null
    'type': 'motion'
    'args': [false]
  'F':
    'funcName': 'searchBehind'
    'regexStr': null
    'num': null
    'type': 'motion'
    'args': [false]
  't':
    'funcName': 'searchAhead'
    'regexStr': null
    'num': null
    'type': 'motion'
    'args': [true]
  'T':
    'funcName': 'searchBehind'
    'regexStr': null
    'num': null
    'type': 'motion'
    'args': [true]
  'l':
    'funcName': 'modifyLine'
    'regexStr': '\\n'
    'num': null
    'type': 'motion'
    'args': []
  's':
    'funcName': 'getSurroundRange'
    'regexStr': null
    'num': null
    'type': 'surroundObject'
    'args': []
  'i':
    'funcName': 'modifyTextObject'
    'regexStr': null
    'num': null
    'type': 'textObject'
    'args': [false]
  'a':
    'funcName': 'modifyTextObject'
    'regexStr': null
    'num': null
    'type': 'textObject'
    'args': [true]
  '':
    'funcName': 'modifyTextObject'
    'regexStr': null
    'num': null
    'type': 'textObject'
    'args': [true]




module.exports = {
    ActionHandler
    searchAhead
    searchBehind
    doAction
}
