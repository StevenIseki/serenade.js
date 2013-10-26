IDENTIFIER = /^[a-zA-Z][a-zA-Z0-9\-_]*/

LITERAL = /^[\[\]=\:\-!#\.@]/

STRING = /^"((?:\\.|[^"])*)"/

MULTI_DENT = /^(?:\r?\n[^\r\n\S]*)+/

WHITESPACE = /^[^\r\n\S]+/

COMMENT = /^\s*\/\/[^\n]*/

KEYWORDS = ["IF", "ELSE", "COLLECTION", "IN", "VIEW", "UNLESS"]

class Lexer

  tokenize: (code, opts = {}) ->
    @code    = code.replace(/^\s*/, '').replace(/\s*$/, '') # The remainder of the source code.
    @line    = opts.line or 0 # The current line.
    @indent  = 0              # The current indentation level.
    @indents = []             # The stack of all current indentation levels.
    @ends    = []             # The stack for pairing up tokens.
    @tokens  = []             # Stream of parsed tokens in the form `['TYPE', value, line]`.

    @i = 0
    while @chunk = @code.slice @i
      @i += @identifierToken() or
           @commentToken()    or
           @whitespaceToken() or
           @lineToken()       or
           @stringToken()     or
           @literalToken()

    while tag = @ends.pop()
      if tag is 'OUTDENT'
        @token 'OUTDENT'
      else
        @error "missing #{tag}"
    @tokens.shift() until @tokens[0][0] isnt "TERMINATOR"
    @tokens.pop() until @tokens[@tokens.length - 1][0] isnt "TERMINATOR"
    @tokens

  commentToken: ->
    if match = COMMENT.exec @chunk
      match[0].length
    else
      0

  whitespaceToken: ->
    if match = WHITESPACE.exec @chunk
      @token 'WHITESPACE', match[0].length
      match[0].length
    else
      0

  token: (tag, value) ->
    @tokens.push [tag, value, @line]

  identifierToken: ->
    if match = IDENTIFIER.exec @chunk
      name = match[0].toUpperCase()

      # This is like a pseudo rewriter, we remove the previous terminator
      # in case this is an else expression, so that we can parse it as
      # part of the if expression
      if name is "ELSE" and @last(@tokens, 2)[0] is "TERMINATOR"
        @tokens.splice(@tokens.length-3, 1)

      if name in KEYWORDS
        @token name, match[0]
      else
        @token 'IDENTIFIER', match[0]
      match[0].length
    else
      0

  stringToken: ->
    if match = STRING.exec @chunk
      @token 'STRING_LITERAL', match[1].replace(/\\(.)/g, "$1")
      match[0].length
    else
      0

  lineToken: ->
    return 0 unless match = MULTI_DENT.exec @chunk


    indent = match[0]
    @line += @count indent, '\n'
    prev = @last @tokens, 1
    size = indent.length - 1 - indent.lastIndexOf '\n'
    diff = size - @indent

    if size is @indent
      @newlineToken()
    else if size > @indent
      @token 'INDENT'
      @indents.push diff
      @ends.push 'OUTDENT'
    else
      while diff < 0
        @ends.pop()
        diff += @indents.pop()
        @token 'OUTDENT'
      @token 'TERMINATOR', '\n'
    @indent = size
    indent.length


  literalToken: ->
    if match = LITERAL.exec @chunk
      @token match[0]
      1
    else
      @error("Unexpected token '#{@chunk.charAt(0)}'")

  newlineToken: ->
    @token 'TERMINATOR', '\n' unless @tag() is 'TERMINATOR'

  tag: (index, tag) ->
    (tok = @last @tokens, index) and if tag then tok[0] = tag else tok[0]

  value: (index, val) ->
    (tok = @last @tokens, index) and if val then tok[1] = val else tok[1]

  error: (message) ->
    chunk = @code.slice(Math.max(0, @i-10),Math.min(@code.length, @i+10))
    throw SyntaxError "#{message} on line #{ @line + 1} near #{JSON.stringify(chunk)}"

  count: (string, substr) ->
    num = pos = 0
    return 1/0 unless substr.length
    num++ while pos = 1 + string.indexOf substr, pos
    num

  last: (array, back) -> array[array.length - (back or 0) - 1]
