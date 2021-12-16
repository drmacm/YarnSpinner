import 'package:yarn_spinner.compiler.framework/src/yarn_spinner_lexer.dart';

abstract class IndentAwareLexer extends Lexer {
  final Stack<int> _indents = Stack<int>();

  final Queue<IToken> _pendingTokens = Queue<IToken>();

  final List<Warning> _warnings = List<Warning>();

  IndentAwareLexer(ICharStream input, TextWriter output, TextWriter errorOutput) {
  }

  IndentAwareLexer(ICharStream input) {
  }

  Iterable<Warning> get warnings => _warnings;


  /// <inheritdoc
  IToken nextToken() {
    if (HitEOF && _pendingTokens.Count > 0) {
      // We have hit the EOF, but we have tokens still pending.
      // Start returning those tokens.
      return _pendingTokens.dequeue();
    }
    else if (InputStream.Size == 0) {
      // There's no more incoming symbols, and we don't have
      // anything pending, so we've hit the end of the file.
      HitEOF = true;

      // Return the EOF token.
      return CommonToken(Eof, "<EOF>");
    }
    else {
      // Get the next token, which will enqueue one or more new
      // tokens into the pending tokens queue.
      _checkNextToken();

      if (_pendingTokens.Count > 0) {
        // Then, return a single token from the queue.
        return _pendingTokens.dequeue();
      }
      else {
        // Nothing left in the queue. Return null.
        return null;
      }
    }
  }

  void _checkNextToken() {
    var currentToken = super.nextToken();

    switch (currentToken.Type) {
      case YarnSpinnerLexer.nEWLINE: {
        // Insert indents or dedents depending on the next
        // token's indentation, and enqueues the newline at the
        // correct place
        _handleNewLineToken(currentToken);
      }
      case Eof: {
        // Insert dedents before the end of the file, and then
        // enqueues the EOF.
        _handleEndOfFileToken(currentToken);
      }
      default: {
        _pendingTokens.enqueue(currentToken);
      }
    }
  }

  void _handleEndOfFileToken(IToken currentToken) {
    // We're at the end of the file. Emit as many dedents as we
    // currently have on the stack.
    while (_indents.Count > 0) {
      var indent = _indents.pop();
      _insertToken("<dedent: ${indent}>", YarnSpinnerLexer.dEDENT);
    }

    // Finally, enqueue the EOF token.
    _pendingTokens.enqueue(currentToken);
  }

  void _handleNewLineToken(IToken currentToken) {
    // We're about to go to a new line. Look ahead to see how
    // indented it is.

    // insert the current NEWLINE token
    _pendingTokens.enqueue(currentToken);

    int currentIndentationLength = _getLengthOfNewlineToken(currentToken);

    int previousIndent = 0;
    if (_indents.Count > 0) {
      previousIndent = _indents.peek();
    }
    else {
      previousIndent = 0;
    }

    if (currentIndentationLength > previousIndent) {
      // We are more indented on this line than on the previous
      // line. Insert an indentation token, and record the new
      // indent level.
      _indents.push(currentIndentationLength);

      _insertToken("<indent to ${currentIndentationLength}>", YarnSpinnerLexer.iNDENT);
    }
    else if (currentIndentationLength < previousIndent) {
      // We are less indented on this line than on the previous
      // line. For each level of indentation we're now lower
      // than, insert a dedent token and remove that indentation
      // level.
      while (currentIndentationLength < previousIndent) {
        // Remove this indent from the stack and generate a
        // dedent token for it.
        previousIndent = _indents.pop();
        _insertToken("<dedent from ${previousIndent}>", YarnSpinnerLexer.dEDENT);

        // Figure out the level of indentation we're on -
        // either the top of the indent stack (if we have any
        // indentations left), or zero.
        if (_indents.Count > 0) {
          previousIndent = _indents.peek();
        }
        else {
          previousIndent = 0;
        }
      }
    }

  }

  // Given a NEWLINE token, return the length of the indentation
  // following it by counting the spaces and tabs after it.
  int _getLengthOfNewlineToken(IToken currentToken) {
    if (currentToken.Type != YarnSpinnerLexer.nEWLINE) {
      throw ArgumentError("${nameof(_getLengthOfNewlineToken)} expected ${nameof(currentToken)} to be a ${nameof(YarnSpinnerLexer.nEWLINE)} (${YarnSpinnerLexer.nEWLINE}), not ${currentToken.Type}");
    }


    int length = 0;
    bool sawSpaces = false;
    bool sawTabs = false;

    for (String c in currentToken.Text) {
      switch (c) {
        case ' ': {
          length += 1;
          sawSpaces = true;
        }
        case '\t': {
          sawTabs = true;
          length += 8;
        }
      }
    }

    if (sawSpaces && sawTabs) {
      var warning0 = Warning;
      warning0.token = currentToken;
      warning0.message = "Indentation contains tabs and spaces";
      _warnings.add(warning0);
    }


    return length;
  }

  void _insertToken(String text, int type) {
    // ***
    // https://www.antlr.org/api/Java/org/antlr/v4/runtime/Lexer.html#_tokenStartCharIndex
    int startIndex = TokenStartCharIndex + Text.Length;
    _insertToken(startIndex, startIndex - 1, text, type, Line, Column);
  }

  void _insertToken1(int startIndex, int stopIndex, String text, int type, int line, int column) {
    var tokenFactorySourcePair = Tuple0.create<T1>(this as ITokenSource, InputStream as ICharStream);

    CommonToken token = CommonToken(tokenFactorySourcePair, type, YarnSpinnerLexer.DefaultTokenChannel, startIndex, stopIndex);
    token.Text = text;
    token.Line = line;
    token.Column = column;

    _pendingTokens.enqueue(token);
  }

}
class Warning {
  IToken Token;

  String Message;
}
