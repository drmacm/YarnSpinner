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

import 'package:yarn_spinner.framework/src/yarn_spinner.markup/markup_value_type.dart';
import 'package:yarn_spinner.framework/src/yarn_spinner.markup/tag_type.dart';


class MarkupParseResult {
  String Text;

  List<MarkupAttribute> Attributes;

  MarkupParseResult(String text, List<MarkupAttribute> attributes) {
    this.text = text;
    this.attributes = attributes;
  }

  bool tryGetAttributeWithName(String name, RefParam<MarkupAttribute> attribute) {
    for (var a in attributes) {
      if (a.name == name) {
        attribute.value = a;
        return true;
      }

    }

    attribute.value = default;
    return false;
  }

  String textForAttribute(MarkupAttribute attribute) {
    if (attribute.length == 0) {
      return String.empty;
    }


    if (text.length < attribute.position + attribute.length) {
      throw IndexOutOfRangeException("Attribute represents a range not representable by this text. Does this ${nameof(MarkupAttribute)} belong to this ${nameof(MarkupParseResult)}?");
    }


    return text.substring(attribute.position, attribute.length);
  }

  MarkupParseResult deleteRange(MarkupAttribute attributeToDelete) {
    var newAttributes = List<MarkupAttribute>();

    // Address the trivial case: if the attribute has a zero
    // length, just create a new markup that doesn't include it.
    // The plain text is left unmodified, because this attribute
    // didn't apply to any text.
    if (attributeToDelete.length == 0) {
      for (var a in attributes) {
        if (!a.equals(attributeToDelete)) {
          newAttributes.add(a);
        }

      }

      return MarkupParseResult(text, newAttributes);
    }


    var deletionStart = attributeToDelete.position;
    var deletionEnd = attributeToDelete.position + attributeToDelete.length;

    var editedSubstring = text.remove(attributeToDelete.position, attributeToDelete.length);

    for (var existingAttribute in attributes) {
      var start = existingAttribute.position;
      var end = existingAttribute.position + existingAttribute.length;

      if (existingAttribute.equals(attributeToDelete)) {
        // This is the attribute we're deleting. Don't include
        // it.
        continue
      }


      var editedAttribute = existingAttribute;

      if (start <= deletionStart) {
        // The attribute starts before start point of the item
        // we're deleting.
        if (end <= deletionStart) {
        }
        else if (end <= deletionEnd) {
          // This attribute starts before the item we're
          // deleting, and ends inside it. The Position
          // doesn't need to change, but its Length is
          // trimmed so that it ends where the deleted
          // attribute begins.
          editedAttribute.length = deletionStart - start;

          if (existingAttribute.length > 0 && editedAttribute.length <= 0) {
            // The attribute's length has been reduced to
            // zero. All of the contents it previous had
            // have been removed, so we will remove the
            // attribute itself.
            continue
          }

        }
        else {
          // This attribute starts before the item we're
          // deleting, and ends after it. Its length is
          // edited to remove the length of the item we're
          // deleting.
          editedAttribute.length -= attributeToDelete.length;
        }
      }
      else if (start >= deletionEnd) {
        // The item begins after the item we're deleting. Its
        // length isn't changing. We just need to offset its
        // start position.
        editedAttribute.position = start - attributeToDelete.length;
      }
      else if (start >= deletionStart && end <= deletionEnd) {
        // The item is entirely within the item we're deleting.
        // It will be deleted too - we'll skip including it in
        // the updated attributes list.
        continue
      }
      else if (start >= deletionStart && end > deletionEnd) {
        // The item starts within the item we're deleting, and
        // ends outside it. We'll adjust the start point so
        // that it begins at the point where this item and the
        // item we're deleting stop overlapping.
        var overlapLength = deletionEnd - start;
        var newStart = deletionStart;
        var newLength = existingAttribute.length - overlapLength;

        editedAttribute.position = newStart;
        editedAttribute.length = newLength;
      }


      newAttributes.add(editedAttribute);
    }

    return MarkupParseResult(editedSubstring, newAttributes);
  }
}

class MarkupAttribute {
  MarkupAttribute(int position, int sourcePosition, int length, String name, Iterable<MarkupProperty> properties) {
    this.position = position;
    this.sourcePosition = sourcePosition;
    this.length = length;
    this.name = name;

    var props = Map<String, MarkupValue>();

    for (var prop in properties) {
      props.add(prop.name, prop.value);
    }

    this.properties = props;
  }

  MarkupAttribute(MarkupAttributeMarker openingMarker, int length) {
  }

  int position = 0;

  int length = 0;

  String name = null;

  Map<String, MarkupValue> properties;

  int sourcePosition = 0;

  /// <inheritdoc
  String toString() {
    var sb = StringBuilder();
    sb.append("[${name}] - ${position}-${position + length} (${length}");

    if (properties?.count > 0) {
      sb.append(", ${properties.count} properties)");
    }


    sb.append(")");

    return sb.toString();
  }
}

class MarkupProperty {
  MarkupProperty(String name, MarkupValue value) {
    this.name = name;
    this.value = value;
  }

  String name = null;

  MarkupValue value = new MarkupValue();
}

class MarkupValue {
  /// Gets the integer value of this property.
  int integerValue = 0;

  /// Gets the float value of this property.
  double floatValue = 0.0;

  /// Gets the string value of this property.
  String stringValue = null;

  // Disable style warning "Summary should begin "Gets a value
  // indicating..." for this property, because that's not what this
  // bool property represents
  /// Gets the bool value of this property.
  bool boolValue = false;

  MarkupValueType type = MarkupValueType.Bool;

  /// <inheritdoc
  String toString() {
    switch (this.Type) {
      case MarkupValueType.integer: {
        return integerValue.toString();
      }
      case MarkupValueType.float: {
        return floatValue.toString();
      }
      case MarkupValueType.String: {
        return stringValue;
      }
      case MarkupValueType.bool: {
        return boolValue.toString();
      }
      default: {
        throw InvalidOperationException("Invalid markup value type ${type}");
      }
    }
  }
}

class MarkupAttributeMarker {
  MarkupAttributeMarker(String name, int position, int sourcePosition, List<MarkupProperty> properties, TagType type) {
    this.name = name;
    this.position = position;
    this.sourcePosition = sourcePosition;
    this.properties = properties;
    this.type = type;
  }

  String name = null;

  int position = 0;

  List<MarkupProperty> properties;

  TagType type = TagType.SelfClosing;

  int sourcePosition = 0;

  bool tryGetProperty(String name, RefParam<MarkupValue> result) {
    for (var prop in properties) {
      if (prop.name.equals(name)) {
        result.value = prop.value;
        return true;
      }

    }

    result.value = default;
    return false;
  }
}
