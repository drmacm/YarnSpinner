namespace Yarn.Markup
{
    /// <summary>Provides a mechanism for producing replacement text for a
    /// marker.</summary>
    /// <seealso cref="LineParser.RegisterMarkerProcessor"/>
    internal interface IAttributeMarkerProcessor
    {
        /// <summary>
        /// Produces the replacement text that should be inserted into a parse
        /// result for a given attribute.
        /// </summary>
        /// <remarks>
        /// If the marker is an <i>open</i> marker, the text from the marker's
        /// position to its corresponding closing marker is provided as a string
        /// property called <c>contents</c>.
        /// </remarks>
        /// <param name="marker">The marker that should have text
        /// inserted.</param>
        /// <returns>The replacement text to insert.</returns>
        string ReplacementTextForMarker(MarkupAttributeMarker marker);
    }
}
