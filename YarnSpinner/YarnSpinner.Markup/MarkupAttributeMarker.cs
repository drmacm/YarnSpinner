namespace Yarn.Markup
{
    using System.Collections.Generic;

    /// <summary>
    /// Represents a marker (e.g. <c>[a]</c>) in line of marked up text.
    /// </summary>
    /// <remarks>
    /// You do not create instances of this struct yourself. It is created
    /// by objects that can parse markup, such as <see cref="Dialogue"/>.
    /// </remarks>
    /// <seealso cref="Dialogue.ParseMarkup(string)"/>
    internal struct MarkupAttributeMarker
    {
        /// <summary>
        /// Initializes a new instance of the <see
        /// cref="MarkupAttributeMarker"/> struct.
        /// </summary>
        /// <param name="name">The name of the marker.</param>
        /// <param name="position">The position of the marker.</param>
        /// <param name="sourcePosition">The position of the marker in the original text.</param>
        /// <param name="properties">The properties of the marker.</param>
        /// <param name="type">The type of the marker.</param>
        internal MarkupAttributeMarker(string name, int position, int sourcePosition, List<MarkupProperty> properties, TagType type)
        {
            this.Name = name;
            this.Position = position;
            this.SourcePosition = sourcePosition;
            this.Properties = properties;
            this.Type = type;
        }

        /// <summary>
        /// Gets the name of the marker.
        /// </summary>
        /// <remarks>
        /// For example, the marker <c>[wave]</c> has the name <c>wave</c>.
        /// </remarks>
        public string Name { get; private set; }

        /// <summary>
        /// Gets the position of the marker in the plain text.
        /// </summary>
        public int Position { get; private set; }

        /// <summary>
        /// Gets the list of properties associated with this marker.
        /// </summary>
        public List<MarkupProperty> Properties { get; private set; }

        /// <summary>
        /// Gets the type of marker that this is.
        /// </summary>
        public TagType Type { get; private set; }

        /// <summary>
        /// Gets or sets the position of this marker in the original source
        /// text.
        /// </summary>
        internal int SourcePosition { get; set; }

        /// <summary>
        /// Gets the property associated with the specified key, if
        /// present.
        /// </summary>
        /// <param name="name">The name of the property to get.</param>
        /// <param name="result">When this method returns, contains the
        /// value associated with the specified key, if the key is found;
        /// otherwise, the default <see cref="MarkupValue"/>. This
        /// parameter is passed uninitialized.</param>
        /// <returns><see langword="true"/> if the <see
        /// cref="MarkupAttributeMarker"/> contains an element with the
        /// specified key; otherwise, <see langword="false"/>.</returns>
        public bool TryGetProperty(string name, out MarkupValue result)
        {
            foreach (var prop in this.Properties)
            {
                if (prop.Name.Equals(name))
                {
                    result = prop.Value;
                    return true;
                }
            }

            result = default;
            return false;
        }
    }
}
