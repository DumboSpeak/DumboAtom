AtomMarkView = require './atom-mark-view'
{CompositeDisposable} = require 'atom'
InputHandler = require './input'

module.exports = AtomMark =
  atomMarkView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @atomMarkView = new AtomMarkView(state.atomMarkViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @atomMarkView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @inputHandler = null
    @mark = new Mark()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-mark:beginningConditionalSpace': => @beginningConditionalSpace()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-mark:endConditionalSpace': => @endConditionalSpace()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-mark:clearSelect': => @clearSelect()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-mark:up': => @up()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-mark:right': => @right()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-mark:down': => @down()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-mark:left': => @left()

    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-mark:captureInput': => @captureInput()

    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-mark:toggle': => @mark.setPos()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-mark:foo': => @mark.selectFromPos()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @atomMarkView.destroy()

  serialize: ->
    atomMarkViewState: @atomMarkView.serialize()

  beginningConditionalSpace: ->
    editor = atom.workspace.getActiveTextEditor()
    pos = editor.getCursorBufferPosition()
    if pos.column != 0 and editor.getTextInBufferRange([pos, [pos.row, pos.column - 1]]) not in [' ', '\t']
      editor.insertText(' ')
    else
        editor.moveRight()

  endConditionalSpace: ->
    editor = atom.workspace.getActiveTextEditor()
    pos = editor.getCursorBufferPosition()
    checkChar = editor.getTextInBufferRange([pos, [pos.row, pos.column + 1]])
    if checkChar not in [' ', '\t']
      editor.insertText(' ')
    else
        editor.moveRight()

  clearSelect: ->
    editor = atom.workspace.getActiveTextEditor()
    editor.setCursorBufferPosition(editor.getCursorBufferPosition())

  up: ->
    editor = atom.workspace.getActiveTextEditor()
    if editor.getSelectedText().length == 0
      editor.moveUp()
    else
      editor.selectUp()

  right: ->
    editor = atom.workspace.getActiveTextEditor()
    if editor.getSelectedText().length == 0
      editor.moveRight()
    else
      editor.selectRight()

  down: ->
    editor = atom.workspace.getActiveTextEditor()
    if editor.getSelectedText().length == 0
      editor.moveDown()
    else
      editor.selectDown()

  left: ->
    editor = atom.workspace.getActiveTextEditor()
    if editor.getSelectedText().length == 0
      editor.moveLeft()
    else
      editor.selectLeft()

  captureInput: ->
    if @inputHandler == null or @inputHandler.listening == false
      @inputHandler = new InputHandler()
      return
    @inputHandler.listening = false

class Mark
  constructor: () ->
    @pos = null
    @editor = null

  setPos: () ->
    @editor = atom.workspace.getActiveTextEditor()
    @pos = @editor.getCursorBufferPosition()

  selectFromPos: () ->
    @editor.setSelectedBufferRange([@pos, @editor.getCursorBufferPosition()])
    @pos = null







filePathToClipboard: ->
    try
      atom.clipboard.write(atom.workspace.getActiveTextEditor().getPath())
    catch
