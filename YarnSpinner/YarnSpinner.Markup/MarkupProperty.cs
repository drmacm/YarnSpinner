namespace Yarn.Markup
{
    /// <summary>
    /// A property associated with a <see cref="MarkupAttribute"/>.
    /// </summary>
    /// <remarks>
    /// You do not create instances of this struct yourself. It is created
    /// by objects that can parse markup, such as <see cref="Dialogue"/>.
    /// </remarks>
    /// <seealso cref="Dialogue.ParseMarkup(string)"/>
    public struct MarkupProperty
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="MarkupProperty"/>
        /// struct.
        /// </summary>
        /// <param name="name">The name of the property.</param>
        /// <param name="value">The value of the property.</param>
        internal MarkupProperty(string name, MarkupValue value)
        {
            this.Name = name;
            this.Value = value;
        }

        /// <summary>
        /// Gets the name of the property.
        /// </summary>
        public string Name { get; private set; }

        /// <summary>
        /// Gets the value of the property.
        /// </summary>
        public MarkupValue Value { get; private set; }
    }
}
