namespace Yarn.Markup
{
    using System.Collections.Generic;

    /// <summary>
    /// Represents a range of text in a marked-up string.
    /// </summary>
    /// <remarks>
    /// You do not create instances of this struct yourself. It is created
    /// by objects that can parse markup, such as <see cref="Dialogue"/>.
    /// </remarks>
    /// <seealso cref="Dialogue.ParseMarkup(string)"/>
    public struct MarkupAttribute
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="MarkupAttribute"/>
        /// struct using specified values.
        /// </summary>
        /// <param name="position">The position in the plain text where
        /// this attribute begins.</param>
        /// <param name="sourcePosition">The position in the original
        /// source text where this attribute begins.</param>
        /// <param name="length">The number of text elements in the plain
        /// text that this attribute covers.</param>
        /// <param name="name">The name of the attribute.</param>
        /// <param name="properties">The properties associated with this
        /// attribute.</param>
        internal MarkupAttribute(int position, int sourcePosition, int length, string name, IEnumerable<MarkupProperty> properties)
        {
            this.Position = position;
            this.SourcePosition = sourcePosition;
            this.Length = length;
            this.Name = name;

            var props = new Dictionary<string, MarkupValue>();

            foreach (var prop in properties)
            {
                props.Add(prop.Name, prop.Value);
            }

            this.Properties = props;
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="MarkupAttribute"/>
        /// struct, using information taken from an opening <see
        /// cref="MarkupAttributeMarker"/>.
        /// </summary>
        /// <param name="openingMarker">The marker that represents the
        /// start of this attribute.</param>
        /// <param name="length">The number of text elements in the plain
        /// text that this attribute covers.</param>
        internal MarkupAttribute(MarkupAttributeMarker openingMarker, int length)
        : this(openingMarker.Position, openingMarker.SourcePosition, length, openingMarker.Name, openingMarker.Properties)
        {
        }

        /// <summary>
        /// Gets the position in the plain text where
        /// this attribute begins.
        /// </summary>
        public int Position { get; internal set; }

        /// <summary>
        /// Gets the number of text elements in the plain
        /// text that this attribute covers.
        /// </summary>
        public int Length { get; internal set; }

        /// <summary>
        /// Gets the name of the attribute.
        /// </summary>
        public string Name { get; internal set; }

        /// <summary>
        /// Gets the properties associated with this
        /// attribute.
        /// </summary>
        public IReadOnlyDictionary<string, MarkupValue> Properties { get; internal set; }

        /// <summary>
        /// Gets the position in the original source text where this
        /// attribute begins.
        /// </summary>
        internal int SourcePosition { get; private set; }

        /// <inheritdoc/>
        public override string ToString()
        {
            var sb = new System.Text.StringBuilder();
            sb.Append($"[{this.Name}] - {this.Position}-{this.Position + this.Length} ({this.Length}");

            if (this.Properties?.Count > 0)
            {
                sb.Append($", {this.Properties.Count} properties)");
            }

            sb.Append(")");

            return sb.ToString();
        }
    }
}
