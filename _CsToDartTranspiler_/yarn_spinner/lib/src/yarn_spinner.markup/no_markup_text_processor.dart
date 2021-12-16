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
import 'package:yarn_spinner.framework/src/yarn_spinner.markup/line_parser.dart';
import 'package:yarn_spinner.framework/src/yarn_spinner.markup/markup_parse_result.dart';

/// A markup text processor that implements the `[nomarkup]`
class NoMarkupTextProcessor implements IAttributeMarkerProcessor {
  /// <inheritdoc
  @override
  String replacementTextForMarker(MarkupAttributeMarker marker) {
    var prop = new MarkupValue();
    var propRef = RefParam(prop);
    if (marker.tryGetProperty(LineParser.replacementMarkerContents, propRef)) {
      prop = propRef.value;
      return prop.stringValue;
    }
    else {
      // this is only possible when it's a tag like [raw/], in
      // which case there's no text to provide, so we'll provide
      // the empty string here
      return String.empty;
    }
  }
}
