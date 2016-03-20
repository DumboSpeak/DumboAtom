utils = require './utils'
actions = require './actions'
{Disposable, CompositeDisposable} = require 'atom'

class InputHandler

  constructor: () ->
    @subscriptions = new CompositeDisposable
    @editor = atom.workspace.getActiveTextEditor()
    @editorView = atom.views.getView @editor
    @listening = true
    @input = ''
    @editorView.addEventListener 'keypress', (event) =>
      @handleInput(event)

  handleInput: (event) ->
    if not @listening
      return
    event.preventDefault()
    char = utils.CHARS[event.which]
    if char != '`' or isNaN(@input[@input.length - 1])
      @input += char
      return
    num = @getNum()
    moveBack = @input[1] == 't' or @input[1] == 'T'
    if utils.REGEX_PATTERNS.ahead.test(@input)
      range = actions.searchAhead(new RegExp(@input[2]), num, moveBack)
      actions.doAction(@input[0], range)
    else if utils.REGEX_PATTERNS.behind.test(@input)
      range = actions.searchBehind(new RegExp(@input[2]), num, moveBack)
      actions.doAction(@input[0], range, true)
    @listening = false

  getNum: () ->
    num = ''
    for i in [@input.length - 1..0] by -1
      if !isNaN(@input[i])
        num = @input[i] + num
    return parseInt(num)

module.exports = InputHandler
