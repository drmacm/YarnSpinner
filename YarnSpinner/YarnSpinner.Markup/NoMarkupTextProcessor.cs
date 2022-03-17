namespace Yarn.Markup
{
    /// <summary>A markup text processor that implements the <c>[nomarkup]</c>
    /// attribute's behaviour.</summary>
    internal class NoMarkupTextProcessor : IAttributeMarkerProcessor
    {
        /// <inheritdoc/>
        public string ReplacementTextForMarker(MarkupAttributeMarker marker)
        {
            if (marker.TryGetProperty(LineParser.TextAttributeName, out var prop))
            {
                return prop.StringValue;
            }
            else
            {
                // this is only possible when this marker is self-closing (i.e.
                // it's '[nomarkup/]'), in which case there's no text to
                // provide, so we'll provide the empty string here
                return string.Empty;
            }
        }
    }
}
