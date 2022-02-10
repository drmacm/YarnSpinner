namespace Yarn.Markup
{
    /// <summary>
    /// A value associated with a <see cref="MarkupProperty"/>.
    /// </summary>
    /// <remarks>
    /// You do not create instances of this struct yourself. It is created
    /// by objects that can parse markup, such as <see cref="Dialogue"/>.
    /// </remarks>
    /// <seealso cref="Dialogue.ParseMarkup(string)"/>
    public struct MarkupValue
    {
        /// <summary>Gets the integer value of this property.</summary>
        /// <remarks>
        /// This property is only defined when the property's <see
        /// cref="Type"/> is <see cref="MarkupValueType.Integer"/>.
        /// </remarks>
        public int IntegerValue { get; internal set; }

        /// <summary>Gets the float value of this property.</summary>
        /// /// <remarks>
        /// This property is only defined when the property's <see
        /// cref="Type"/> is <see cref="MarkupValueType.Float"/>.
        /// </remarks>
        public float FloatValue { get; internal set; }

        /// <summary>Gets the string value of this property.</summary>
        /// <remarks>
        /// This property is only defined when the property's <see
        /// cref="Type"/> is <see cref="MarkupValueType.String"/>.
        /// </remarks>
        public string StringValue { get; internal set; }

        // Disable style warning "Summary should begin "Gets a value
        // indicating..." for this property, because that's not what this
        // bool property represents
#pragma warning disable SA1623
        /// <summary>Gets the bool value of this property.</summary>
        /// <remarks>
        /// This property is only defined when the property's <see
        /// cref="Type"/> is <see cref="MarkupValueType.Bool"/>.
        /// </remarks>
        public bool BoolValue { get; internal set; }
#pragma warning restore SA1623

        /// <summary>
        /// Gets the value's type.
        /// </summary>
        public MarkupValueType Type { get; internal set; }

        /// <inheritdoc/>
        public override string ToString()
        {
            switch (this.Type)
            {
                case MarkupValueType.Integer:
                    return this.IntegerValue.ToString();
                case MarkupValueType.Float:
                    return this.FloatValue.ToString();
                case MarkupValueType.String:
                    return this.StringValue;
                case MarkupValueType.Bool:
                    return this.BoolValue.ToString();
                default:
                    throw new System.InvalidOperationException($"Invalid markup value type {this.Type}");
            }
        }
    }
}
