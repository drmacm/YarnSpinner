import 'package:yarn_spinner.framework.tests/src/test_base.dart';
import 'package:yarn_spinner.framework/yarn_spinner.framework.dart';

class MarkupTests extends TestBase {

  void testMarkupParsing() {
    var line = "A [b]B[/b]";
    var markup = dialogue.parseMarkup(line);

    assertEquals("A B", markup.text);
    Assert.single(markup.attributes);
    assertEquals("b", markup.attributes[0].Name);
    assertEquals(2, markup.attributes[0].Position);
    assertEquals(1, markup.attributes[0].Length);
  }

  void testOverlappingAttributes() {
    var line = "[a][b][c]X[/b][/a]X[/c]";

    var markup = dialogue.parseMarkup(line);

    assertEquals(3, markup.attributes.Count);
    assertEquals("a", markup.attributes[0].Name);
    assertEquals("b", markup.attributes[1].Name);
    assertEquals("c", markup.attributes[2].Name);
  }

  void testTextExtraction() {
    var line = "A [b]B [c]C[/c][/b]";

    var markup = dialogue.parseMarkup(line);

    assertEquals("B C", markup.textForAttribute(markup.attributes[0]));
    assertEquals("C", markup.textForAttribute(markup.attributes[1]));
  }

  void testAttributeRemoval() {
    // A test string with the following attributes:
    // a: Covers the entire string
    // b: Starts outside X, ends inside
    // c: Same start and end point as X
    // d: Starts inside X, ends outside
    // e: Starts and ends outside X
    var line = "[a][b]A [c][X]x[/b] [d]x[/X][/c] B[/d] [e]C[/e][/a]";
    var originalMarkup = dialogue.parseMarkup(line);

    // Remove the "X" attribute
    assertEquals("X", originalMarkup.attributes[3].Name);
    var trimmedMarkup = originalMarkup.deleteRange(originalMarkup.attributes[3]);

    assertEquals("A x x B C", originalMarkup.text);
    assertEquals(6, originalMarkup.attributes.Count);

    assertEquals("A  B C", trimmedMarkup.text);
    assertEquals(4, trimmedMarkup.attributes.Count);

    assertEquals("a", trimmedMarkup.attributes[0].Name);
    assertEquals(0, trimmedMarkup.attributes[0].Position);
    assertEquals(6, trimmedMarkup.attributes[0].Length);

    assertEquals("b", trimmedMarkup.attributes[1].Name);
    assertEquals(0, trimmedMarkup.attributes[1].Position);
    assertEquals(2, trimmedMarkup.attributes[1].Length);

    // "c" will have been removed along with "X" because it had a
    // length of >0 before deletion, and was reduced to zero
    // characters

    assertEquals("d", trimmedMarkup.attributes[2].Name);
    assertEquals(2, trimmedMarkup.attributes[2].Position);
    assertEquals(2, trimmedMarkup.attributes[2].Length);

    assertEquals("e", trimmedMarkup.attributes[3].Name);
    assertEquals(5, trimmedMarkup.attributes[3].Position);
    assertEquals(1, trimmedMarkup.attributes[3].Length);
  }

  void testFindingAttributes() {
    var line = "A [b]B[/b] [b]C[/b]";
    var markup = dialogue.parseMarkup(line);

    MarkupAttribute attribute = new MarkupAttribute();
    bool found = false;

    var attributeRef = RefParam(attribute);
    found = markup.tryGetAttributeWithName("b", attributeRef);

    attribute = attributeRef.value;
    assertTrue(found);
    assertEquals(attribute, markup.attributes[0]);
    assertNotEquals(attribute, markup.attributes[1]);

    var _Ref = RefParam(_);
    found = markup.tryGetAttributeWithName("c", _Ref);

    _ = _Ref.value;
    assertFalse(found);
  }

  void testMultibyteCharacterParsing(String input) {
    var markup = dialogue.parseMarkup(input);

    // All versions of this string should have the same position
    // and length of the attribute, despite the presence of
    // multibyte characters
    Assert.single(markup.attributes);
    assertEquals(2, markup.attributes[0].Position);
    assertEquals(1, markup.attributes[0].Length);
  }

  void testUnexpectedCloseMarkerThrows(String input) {
    Assert.Throws<MarkupParseException>( {
      var markup = dialogue.parseMarkup(input);
     });
  }

  void testMarkupShortcutPropertyParsing() {
    var line = "[a=1]s[/a]";
    var markup = dialogue.parseMarkup(line);

    // Should have a single attribute, "a", at position 0 and
    // length 1
    var attribute = markup.attributes[0];
    assertEquals("a", attribute.Name);
    assertEquals(0, attribute.Position);
    assertEquals(1, attribute.Length);

    // Should have a single property on this attribute, "a". Value
    // should be an integer, 1
    var value = attribute.Properties["a"];

    assertEquals(MarkupValueType.integer, value.Type);
    assertEquals(1, value.IntegerValue);
  }

  void testMarkupMultiplePropertyParsing() {
    var line = "[a p1=1 p2=2]s[/a]";
    var markup = dialogue.parseMarkup(line);

    assertEquals("a", markup.attributes[0].Name);

    assertEquals(2, markup.attributes[0].Properties.Count);

    var p1 = markup.attributes[0].Properties["p1"];
    assertEquals(MarkupValueType.integer, p1.Type);
    assertEquals(1, p1.IntegerValue);

    var p2 = markup.attributes[0].Properties["p2"];
    assertEquals(MarkupValueType.integer, p2.Type);
    assertEquals(2, p2.IntegerValue);
  }

  void testMarkupPropertyParsing(String input, MarkupValueType expectedType, String expectedValueAsString) {

    //Necessary to ensure '.' as decimal symbol when parsing 13.37
    Thread.currentThread.currentCulture = CultureInfo.createSpecificCulture("en-GB");

    var markup = dialogue.parseMarkup(input);

    var attribute = markup.attributes[0];
    var propertyValue = attribute.Properties["p"];

    assertEquals(expectedType, propertyValue.Type);
    assertEquals(expectedValueAsString, propertyValue.toString());
  }

  void testMultipleAttributes(String input) {
    var markup = dialogue.parseMarkup(input);

    assertEquals("A B C D", markup.text);

    assertEquals(2, markup.attributes.Count);

    assertEquals("b", markup.attributes[0].Name);
    assertEquals(2, markup.attributes[0].Position);
    assertEquals(2, markup.attributes[0].SourcePosition);
    assertEquals(3, markup.attributes[0].Length);

    assertEquals("c", markup.attributes[1].Name);
    assertEquals(4, markup.attributes[1].Position);
    assertEquals(7, markup.attributes[1].SourcePosition);
    assertEquals(1, markup.attributes[1].Length);
  }

  void testSelfClosingAttributes() {
    var line = "A [a/] B";
    var markup = dialogue.parseMarkup(line);

    assertEquals("A B", markup.text);

    Assert.single(markup.attributes);

    assertEquals("a", markup.attributes[0].Name);
    assertEquals(0, markup.attributes[0].Properties.Count);
    assertEquals(2, markup.attributes[0].Position);
    assertEquals(0, markup.attributes[0].Length);
  }

  void testAttributesMayTrimTrailingWhitespace(String input, String expectedText) {
    var markup = dialogue.parseMarkup(input);

    assertEquals(expectedText, markup.text);
  }

  void testImplicitCharacterAttributeParsing(String input) {
    var markup = dialogue.parseMarkup(input);

    assertEquals("Mae: Wow!", markup.text);
    Assert.single(markup.attributes);

    assertEquals("character", markup.attributes[0].Name);
    assertEquals(0, markup.attributes[0].Position);
    assertEquals(5, markup.attributes[0].Length);

    assertEquals(1, markup.attributes[0].Properties.Count);
    assertEquals("Mae", markup.attributes[0].Properties["name"].StringValue);
  }

  void testNoMarkupModeParsing() {
    var line = "S [a]S[/a] [nomarkup][a]S;][/a][/nomarkup]";
    var markup = dialogue.parseMarkup(line);

    assertEquals("S S [a]S;][/a]", markup.text);

    assertEquals(2, markup.attributes.Count);

    assertEquals("a", markup.attributes[0].Name);
    assertEquals(2, markup.attributes[0].Position);
    assertEquals(1, markup.attributes[0].Length);

    assertEquals("nomarkup", markup.attributes[1].Name);
    assertEquals(4, markup.attributes[1].Position);
    assertEquals(10, markup.attributes[1].Length);
  }

  void testMarkupEscaping() {
    var line = "[a]hello \[b\]hello\[/b\][/a]";
    var markup = dialogue.parseMarkup(line);

    assertEquals("hello [b]hello[/b]", markup.text);
    Assert.single(markup.attributes);
    assertEquals("a", markup.attributes[0].Name);
    assertEquals(0, markup.attributes[0].Position);
    assertEquals(18, markup.attributes[0].Length);
  }
}
