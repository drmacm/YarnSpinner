namespace Yarn.Markup
{
    /// <summary>
    /// A type of <see cref="MarkupAttributeMarker"/>.
    /// </summary>
    internal enum TagType
    {
        /// <summary>
        /// An open marker. For example, <c>[a]</c>.
        /// </summary>
        Open,

        /// <summary>
        /// A closing marker. For example, <c>[/a]</c>.
        /// </summary>
        Close,

        /// <summary>
        /// A self-closing marker. For example, <c>[a/]</c>.
        /// </summary>
        SelfClosing,

        /// <summary>
        /// The close-all marker, <c>[/]</c>.
        /// </summary>
        CloseAll,
    }
}
