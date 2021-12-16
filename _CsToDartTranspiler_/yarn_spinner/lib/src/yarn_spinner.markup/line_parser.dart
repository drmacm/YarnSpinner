/*

The MIT License (MIT)

Copyright (c) 2015-2017 Secret Lab Pty. Ltd. and Yarn Spinner contributors.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

import 'package:yarn_spinner.framework/src/yarn_spinner.markup/i_attribute_marker_processor.dart';
import 'package:yarn_spinner.framework/src/yarn_spinner.markup/markup_parse_exception.dart';
import 'package:yarn_spinner.framework/src/yarn_spinner.markup/markup_parse_result.dart';
import 'package:yarn_spinner.framework/src/yarn_spinner.markup/markup_value_type.dart';
import 'package:yarn_spinner.framework/src/yarn_spinner.markup/no_markup_text_processor.dart';
import 'package:yarn_spinner.framework/src/yarn_spinner.markup/tag_type.dart';


class LineParser {
  final String ReplacementMarkerContents = "contents";

  final String CharacterAttribute = "character";

  final String CharacterAttributeNameProperty = "name";

  final String TrimWhitespaceProperty = "trimwhitespace";

  static final Regex _EndOfCharacterMarker = Regex(":\s*");

  static final Comparison<MarkupAttribute> _AttributePositionComparison = (x, y) => x.sourcePosition.compareTo(y.sourcePosition);

  final Map<String, IAttributeMarkerProcessor> _markerProcessors = Map<String, IAttributeMarkerProcessor>();

  String _input;

  StringReader _stringReader;

  int _position = 0;

  int _sourcePosition = 0;

  LineParser() {
    registerMarkerProcessor("nomarkup", NoMarkupTextProcessor());
  }

  /// Registers an object as a marker processor for a given
  void registerMarkerProcessor(String attributeName, IAttributeMarkerProcessor markerProcessor) {
    if (_markerProcessors.containsKey(attributeName)) {
      throw InvalidOperationException("A marker processor for ${attributeName} has already been registered.");
    }


    _markerProcessors.add(attributeName, markerProcessor);
  }

  /// Parses a line of text, and produces a
  MarkupParseResult parseMarkup(String input) {
    if (String.isNullOrEmpty(input)) {
      // We got a null input; return an empty markup parse result
      var result = MarkupParseResult;
      result.text = String.empty;
      result.attributes = List<MarkupAttribute>();
      return result;
    }


    _input = input.normalize();

    _stringReader = StringReader(_input);

    var stringBuilder = StringBuilder();

    var markers = List<MarkupAttributeMarker>();

    int nextCharacter = 0;

    String lastCharacter = String.minValue;

    // Read the entirety of the line
    while ((nextCharacter = _stringReader.read()) != -1) {
      String c = nextCharacter as String;

      if (c == '\\') {
        // This may be the start of an escaped bracket ("\[" or
        // "\]"). Peek ahead to see if it is.
        var nextC = _stringReader.peek() as String;

        if (nextC == '[' || nextC == ']') {
          // It is! We'll discard this '\', and read the next
          // character as plain text.
          c = _stringReader.read() as String;
          stringBuilder.append(c);
          _sourcePosition += 1;
          continue
        }
        else {
        }
      }


      if (c == '[') {
        // How long is our current string, in text elements
        // (i.e. visible glyphs)?
        _position = StringInfo(stringBuilder.toString()).lengthInTextElements;

        // The start of a marker!
        MarkupAttributeMarker marker = _parseAttributeMarker();

        markers.add(marker);

        var hadPrecedingWhitespaceOrLineStart = _position == 0 || String.isWhiteSpace(lastCharacter);

        bool wasReplacementMarker = false;

        // Is this a replacement marker?
        if (marker.name != null && _markerProcessors.containsKey(marker.name)) {
          wasReplacementMarker = true;

          // Process it and get the replacement text!
          var replacementText = _processReplacementMarker(marker);

          // Insert it into our final string and update our
          // position accordingly
          stringBuilder.append(replacementText);
        }


        bool trimWhitespaceIfAble = false;

        if (hadPrecedingWhitespaceOrLineStart) {
          // By default, self-closing markers will trim a
          // single trailing whitespace after it if there was
          // preceding whitespace. This doesn't happen if the
          // marker was a replacement marker, or it has a
          // property "trimwhitespace" (which must be
          // boolean) set to false. All markers can opt-in to
          // trailing whitespace trimming by having a
          // 'trimwhitespace' property set to true.
          if (marker.type == TagType.selfClosing) {
            trimWhitespaceIfAble = !wasReplacementMarker;
          }


          var prop = new MarkupValue();
          var propRef = RefParam(prop);
          if (marker.tryGetProperty(trimWhitespaceProperty, propRef)) {
            prop = propRef.value;
            if (prop.type != MarkupValueType.bool) {
              throw MarkupParseException("Error parsing line ${_input}: attribute ${marker.name} at position ${_position} has a ${prop.type.toString().toLower()} property \"${trimWhitespaceProperty}\" - this property is required to be a boolean value.");
            }


            trimWhitespaceIfAble = prop.boolValue;
          }

        }


        if (trimWhitespaceIfAble) {
          // If there's trailing whitespace, and we want to
          // remove it, do so
          if (_peekWhitespace()) {
            // Consume the single trailing whitespace
            // character (and don't update position)
            _stringReader.read();
            _sourcePosition += 1;
          }

        }

      }
      else {
        // plain text! add it to the resulting string and
        // advance the parser's plain-text position
        stringBuilder.append(c);
        _sourcePosition += 1;
      }

      lastCharacter = c;
    }

    var attributes = _buildAttributesFromMarkers(markers);

    var characterAttributeIsPresent = false;
    for (var attribute in attributes) {
      if (attribute.name == characterAttribute) {
        characterAttributeIsPresent = true;
      }

    }

    if (characterAttributeIsPresent == false) {
      // Attempt to generate a character attribute from the start
      // of the string to the first colon
      var match = _endOfCharacterMarker.match(_input);

      if (match.Success) {
        var endRange = match.Index + match.Length;
        var characterName = _input.substring(0, match.Index);

        MarkupValue nameValue = MarkupValue;
        nameValue.type = MarkupValueType.String;
        nameValue.stringValue = characterName;

        MarkupProperty nameProperty = MarkupProperty(characterAttributeNameProperty, nameValue);

        var characterAttribute = MarkupAttribute(0, 0, endRange, characterAttribute, [nameProperty]);

        attributes.add(characterAttribute);
      }

    }


    var result = MarkupParseResult;
    result.text = stringBuilder.toString();
    result.attributes = attributes;
    return result;
  }

  String _processReplacementMarker(MarkupAttributeMarker marker) {
    // If it's not an open or self-closing marker, we have no text
    // to insert, so return the empty string
    if (marker.type != TagType.open && marker.type != TagType.selfClosing) {
      return String.empty;
    }


    // this is an attribute that we want to replace with text!

    // if this is an opening marker, we read up to the closing
    // marker, the close-all marker, or the end of the string; this
    // becomes the value of a property called "contents", and then
    // we perform the replacement
    if (marker.type == TagType.open) {
      // Read everything up to the closing tag
      String markerContents = _parseRawTextUpToAttributeClose(marker.name);

      // Add this as a property
      var markupValue1 = MarkupValue;
      markupValue1.stringValue = markerContents;
      markupValue1.type = MarkupValueType.String;
      marker.properties.add(MarkupProperty(replacementMarkerContents, markupValue1));
    }


    // Fetch the text that should be inserted into the string at
    // this point
    var replacementText = _markerProcessors[marker.name].replacementTextForMarker(marker);

    return replacementText;
  }

  String _parseRawTextUpToAttributeClose(String name) {
    var remainderOfLine = _stringReader.readToEnd();

    // Parse up to either [/name] or [/], allowing whitespace
    // between any elements.
    var match = System.Text.RegularExpressions.Regex.match(remainderOfLine, "\[\s*\/\s*(${name})?\s*\]");

    // If we didn't find it, then there's no closing marker, and
    // that's an error!
    if (match.Success == false) {
      throw MarkupParseException("Unterminated marker ${name} in line ${_input} at position ${_position}");
    }


    // Split the line into the part up to the closing tag, and the
    // part afterwards
    var closeMarkerPosition = match.Index;

    var rawTextSubstring = remainderOfLine.substring(0, closeMarkerPosition);
    var lineAfterRawText = remainderOfLine.substring(closeMarkerPosition);

    // We've consumed all of this text in the string reader, so to
    // make it possible to parse the rest, we need to create a new
    // string reader with the remaining text
    _stringReader = StringReader(lineAfterRawText);

    return rawTextSubstring;
  }

  List<MarkupAttribute> _buildAttributesFromMarkers(List<MarkupAttributeMarker> markers) {
    // Using a linked list here because we want to append to the
    // front and be able to walk through it easily
    var unclosedMarkerList = LinkedList<MarkupAttributeMarker>();

    var attributes = List<MarkupAttribute>(markers.count);

    for (var marker in markers) {
      switch (marker.Type) {
        case TagType.open: {
          // A new marker! Add it to the unclosed list at the
          // start (because there's a high chance that it
          // will be closed soon).
          unclosedMarkerList.addFirst(marker);
        }
        case TagType.close: {
 {
            // A close marker! Walk back through the
            // unclosed stack to find the most recent
            // marker of the same type to find its pair.
            MarkupAttributeMarker matchedOpenMarker = default;
            for (var openMarker in unclosedMarkerList) {
              if (openMarker.Name == marker.name) {
                // Found a corresponding open!
                matchedOpenMarker = openMarker;
                break
              }

            }

            if (matchedOpenMarker.name == null) {
              throw MarkupParseException("Unexpected close marker ${marker.name} at position ${marker.position} in line ${_input}");
            }


            // This attribute is now closed, so we can
            // remove the marker from the unmatched list
            unclosedMarkerList.remove(matchedOpenMarker);

            // We can now construct the attribute!
            var length = marker.position - matchedOpenMarker.position;
            var attribute = MarkupAttribute(matchedOpenMarker, length);

            attributes.add(attribute);
          }

        }
        case TagType.selfClosing: {
 {
            // Self-closing markers create a zero-length
            // attribute where they appear
            var attribute = MarkupAttribute(marker, 0);
            attributes.add(attribute);
          }

        }
        case TagType.closeAll: {
 {
            // Close all currently open markers

            // For each marker that we currently have open,
            // this marker has closed it, so create an
            // attribute for it
            for (var openMarker in unclosedMarkerList) {
              var length = marker.position - openMarker.Position;
              var attribute = MarkupAttribute(openMarker, length);

              attributes.add(attribute);
            }

            // We've now closed all markers, so we can
            // clear the unclosed list now
            unclosedMarkerList.clear();
          }

        }
      }
    }

    attributes.sort(_attributePositionComparison);

    return attributes;
  }

  MarkupAttributeMarker _parseAttributeMarker() {
    var sourcePositionAtMarkerStart = _sourcePosition;

    // We have already consumed the start of the marker '[' before
    // we enter here. Increment the sourcePosition counter to
    // account for it.
    _sourcePosition += 1;

    // Next, start parsing from the characters that can appear
    // inside the marker
    if (_peek('/')) {
      // This is either the start of a closing tag or the start
      // of the 'close-all' tag
      _parseCharacter('/');

      if (_peek(']')) {
        // It's the close-all tag!
        _parseCharacter(']');
        return MarkupAttributeMarker(null, _position, sourcePositionAtMarkerStart, List<MarkupProperty>(), TagType.closeAll);
      }
      else {
        // It's a named closing tag!
        var tagName = _parseID();
        _parseCharacter(']');
        return MarkupAttributeMarker(tagName, _position, sourcePositionAtMarkerStart, List<MarkupProperty>(), TagType.close);
      }
    }


    // If we're here, this is either an opening tag, or a
    // self-closing tag.

    // If the opening ID is not provided, the name of the attribute
    // is taken from the first property.

    // Tags always start with an ID, which is used as the name of
    // the attribute.
    String attributeName = _parseID();

    var properties = List<MarkupProperty>();

    // If the ID was immediately followed by an '=', this was the
    // first property (its value is also used as the attribute
    // name.)
    if (_peek('=')) {
      // This is also the first property!

      // Parse the rest of the property now before we parse any
      // others.
      _parseCharacter('=');
      var value = _parseValue();
      properties.add(MarkupProperty(attributeName, value));
    }


    // parse all remaining properties
    while (true) {
      _consumeWhitespace();
      var next = _stringReader.peek();
      _assertNotEndOfInput(next);

      if (next as String == ']') {
        // End of an Opening tag.
        _parseCharacter(']');
        return MarkupAttributeMarker(attributeName, _position, sourcePositionAtMarkerStart, properties, TagType.open);
      }


      if (next as String == '/') {
        // End of a self-closing tag.
        _parseCharacter('/');
        _parseCharacter(']');
        return MarkupAttributeMarker(attributeName, _position, sourcePositionAtMarkerStart, properties, TagType.selfClosing);
      }


      // Expect another property.
      var propertyName = _parseID();
      _parseCharacter('=');
      var propertyValue = _parseValue();

      properties.add(MarkupProperty(propertyName, propertyValue));
    }
  }

  MarkupValue _parseValue() {
    // parse integers or floats:
    if (_peekNumeric()) {
      // could be an int or a float
      var integer = _parseInteger();

      // if there's a decimal separator, this is a float
      if (_peek('.')) {
        // a float
        _parseCharacter('.');

        // parse the fractional value
        var fraction = _parseInteger();

        // convert it to a float
        var fractionDigits = fraction.toString().length;
        double floatValue = integer + (fraction / Math.pow(10.0, fractionDigits)) as double;

        var result = MarkupValue;
        result.floatValue = floatValue;
        result.type = MarkupValueType.float;
        return result;
      }
      else {
        // an integer
        var result = MarkupValue;
        result.integerValue = integer;
        result.type = MarkupValueType.integer;
        return result;
      }
    }


    if (_peek('"')) {
      // a string
      var stringValue = _parseString();

      var result = MarkupValue;
      result.stringValue = stringValue;
      result.type = MarkupValueType.String;
      return result;
    }


    var word = _parseID();

    // This ID is expected to be 'true', 'false', or something
    // else. if it's 'true' or 'false', interpret it as a bool.
    if (word.equals("true", StringComparison.invariantCultureIgnoreCase)) {
      var result = MarkupValue;
      result.boolValue = true;
      result.type = MarkupValueType.bool;
      return result;
    }
    else if (word.equals("false", StringComparison.invariantCultureIgnoreCase)) {
      var result = MarkupValue;
      result.boolValue = false;
      result.type = MarkupValueType.bool;
      return result;
    }
    else {
      // interpret this as a one-word string
      var result = MarkupValue;
      result.stringValue = word;
      result.type = MarkupValueType.String;
      return result;
    }
  }

  bool _peek(String expectedCharacter) {
    _consumeWhitespace();
    var next = _stringReader.peek();
    if (next == -1) {
      return false;
    }


    return next as String == expectedCharacter;
  }

  bool _peekWhitespace() {
    var next = _stringReader.peek();
    if (next == -1) {
      return false;
    }


    return String.isWhiteSpace(next as String);
  }

  bool _peekNumeric() {
    _consumeWhitespace();
    var next = _stringReader.peek();
    if (next == -1) {
      return false;
    }


    return String.isDigit(next as String);
  }

  int _parseInteger() {
    _consumeWhitespace();

    StringBuilder intBuilder = StringBuilder();

    while (true) {
      var tempNext = _stringReader.peek();
      _assertNotEndOfInput(tempNext);
      var nextChar = tempNext as String;

      if (String.isDigit(nextChar)) {
        _stringReader.read();
        intBuilder.append(nextChar);
        _sourcePosition += 1;
      }
      else {
        // end of the integer! parse and return it
        return int.parse(intBuilder.toString(), System.Globalization.CultureInfo.invariantCulture);
      }
    }
  }

  String _parseID() {
    _consumeWhitespace();
    var idStringBuilder = StringBuilder();

    // Read the first character, which must be a letter
    int tempNext = _stringReader.read();
    _sourcePosition += 1;
    _assertNotEndOfInput(tempNext);
    String nextChar = tempNext as String;

    if (String.isSurrogate(nextChar)) {
      var nextNext = _stringReader.read();
      _sourcePosition += 1;
      _assertNotEndOfInput(nextNext);
      var nextNextChar = nextNext as String;

      // FIXME: This assumes that all surrogate pairs are
      // 'letters', which may not be the case.
      idStringBuilder.append(nextChar);
      idStringBuilder.append(nextNextChar);
    }
    else if (String.isLetter(nextChar) || nextChar == '_') {
      idStringBuilder.append(tempNext as String);
    }
    else {
      throw ArgumentError("Expected an identifier inside markup in line \"${_input}\"");
    }

    // Read zero or more letters, numbers, or underscores
    while (true) {
      tempNext = _stringReader.peek();
      if (tempNext == -1) {
        break
      }


      nextChar = tempNext as String;

      if (String.isSurrogate(nextChar)) {
        _stringReader.read();
        // consume this char
        _sourcePosition += 1;

        // consume the next character, which we expect to be a
        // surrogate pair
        var nextNext = _stringReader.read();
        _sourcePosition += 1;
        _assertNotEndOfInput(nextNext);
        var nextNextChar = nextNext as String;

        // This assumes that all surrogate pairs are 'letters',
        // which may not be the case.
        idStringBuilder.append(nextChar);
        idStringBuilder.append(nextNextChar);
      }
      else if (String.isLetterOrDigit(nextChar) || tempNext as String == '_') {
        idStringBuilder.append(tempNext as String);
        _stringReader.read();
        // consume it
        _sourcePosition += 1;
      }
      else {
        // no more
        break
      }
    }

    return idStringBuilder.toString();
  }

  String _parseString() {
    _consumeWhitespace();

    var stringStringBuilder = StringBuilder();

    int tempNext = _stringReader.read();
    _assertNotEndOfInput(tempNext);
    _sourcePosition += 1;

    String nextChar = tempNext as String;
    if (nextChar != '"') {
      throw ArgumentError("Expected a string inside markup in line ${_input}");
    }


    while (true) {
      tempNext = _stringReader.read();
      _assertNotEndOfInput(tempNext);
      _sourcePosition += 1;
      nextChar = tempNext as String;

      if (nextChar == '"') {
        // end of string - consume it but don't append to the
        // final collection
        break
      }
      else if (nextChar == '\\') {
        // an escaped quote or backslash
        int nextNext = _stringReader.read();
        _assertNotEndOfInput(nextNext);
        _sourcePosition += 1;
        String nextNextChar = nextNext as String;
        if (nextNextChar == '\\' || nextNextChar == '"') {
          stringStringBuilder.append(nextNextChar);
        }

      }
      else {
        stringStringBuilder.append(nextChar);
      }
    }

    return stringStringBuilder.toString();
  }

  void _parseCharacter(String character) {
    _consumeWhitespace();

    int tempNext = _stringReader.read();
    _assertNotEndOfInput(tempNext);
    if (tempNext as String != character) {
      throw MarkupParseException("Expected a ${character} inside markup in line \"${_input}\"");
    }


    _sourcePosition += 1;
  }

  void _assertNotEndOfInput(int value) {
    if (value == -1) {
      throw MarkupParseException("Unexpected end of line inside markup in line \"${_input}");
    }

  }

  void _consumeWhitespace([bool allowEndOfLine = false]) {
    while (true) {
      var tempNext = _stringReader.peek();
      if (tempNext == -1 && allowEndOfLine == false) {
        throw MarkupParseException("Unexpected end of line inside markup in line \"${_input}");
      }


      if (String.isWhiteSpace(tempNext as String) == true) {
        // consume it and continue
        _stringReader.read();
        _sourcePosition += 1;
      }
      else {
        // no more whitespace ahead; don't consume it, but
        // instead stop eating whitespace
        return;
      }
    }
  }
}
