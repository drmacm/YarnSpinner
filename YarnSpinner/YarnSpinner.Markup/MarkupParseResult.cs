namespace Yarn.Markup
{
    using System.Collections.Generic;

    /// <summary>
    /// The result of parsing a line of marked-up text.
    /// </summary>
    /// <remarks>
    /// You do not create instances of this struct yourself. It is created
    /// by objects that can parse markup, such as <see cref="Dialogue"/>.
    /// </remarks>
    /// <seealso cref="Dialogue.ParseMarkup(string)"/>
    public struct MarkupParseResult
    {
        /// <summary>
        /// The original text, with all parsed markers removed.
        /// </summary>
        public string Text;

        /// <summary>
        /// The list of <see cref="MarkupAttribute"/>s in this parse
        /// result.
        /// </summary>
        public List<MarkupAttribute> Attributes;

        /// <summary>
        /// Initializes a new instance of the <see cref="MarkupParseResult"/> struct.
        /// </summary>
        /// <param name="text">The plain text.</param>
        /// <param name="attributes">The list of attributes.</param>
        internal MarkupParseResult(string text, List<MarkupAttribute> attributes)
        {
            this.Text = text;
            this.Attributes = attributes;
        }

        /// <summary>
        /// Gets the first attribute with the specified name, if present.
        /// </summary>
        /// <param name="name">The name of the attribute to get.</param>
        /// <param name="attribute">When this method returns, contains the
        /// attribute with the specified name, if the attribute is found;
        /// otherwise, the default <see cref="MarkupAttribute"/>. This
        /// parameter is passed uninitialized.</param>
        /// <returns><see langword="true"/> if the <see
        /// cref="MarkupParseResult"/> contains an attribute with the
        /// specified name; otherwise, <see langword="false"/>.</returns>
        public bool TryGetAttributeWithName(string name, out MarkupAttribute attribute)
        {
            foreach (var a in this.Attributes)
            {
                if (a.Name == name)
                {
                    attribute = a;
                    return true;
                }
            }

            attribute = default;
            return false;
        }

        /// <summary>
        /// Returns the substring of <see cref="Text"/> covered by
        /// <paramref name="attribute"/> Position and Length properties.
        /// </summary>
        /// <remarks>
        /// <para>
        /// If the attribute's <see cref="MarkupAttribute.Length"/>
        /// property is zero, this method returns the empty string.
        /// </para>
        /// <para>
        /// This method does not check to see if <paramref
        /// name="attribute"/> is an attribute belonging to this
        /// MarkupParseResult. As a result, if you pass an attribute that
        /// doesn't belong, it may describe a range of text that does not
        /// appear in <see cref="Text"/>. If this occurs, an <see
        /// cref="System.IndexOutOfRangeException"/> will be thrown.
        /// </para>
        /// </remarks>
        /// <param name="attribute">The attribute to get the text
        /// for.</param>
        /// <returns>The text contained within the attribute.</returns>
        /// <throws cref="System.IndexOutOfRangeException">Thrown when
        /// attribute's <see cref="MarkupAttribute.Position"/> and <see
        /// cref="MarkupAttribute.Length"/> properties describe a range of
        /// text outside the maximum range of <see cref="Text"/>.</throws>
        public string TextForAttribute(MarkupAttribute attribute)
        {
            if (attribute.Length == 0)
            {
                return string.Empty;
            }

            if (this.Text.Length < attribute.Position + attribute.Length)
            {
                throw new System.IndexOutOfRangeException($"Attribute represents a range not representable by this text. Does this {nameof(MarkupAttribute)} belong to this {nameof(MarkupParseResult)}?");
            }

            return this.Text.Substring(attribute.Position, attribute.Length);
        }

        /// <summary>
        /// Deletes an attribute from this markup.
        /// </summary>
        /// <remarks>
        /// This method deletes the range of text covered by <paramref
        /// name="attributeToDelete"/>, and updates the other attributes in this
        /// markup as follows:
        ///
        /// <list type="bullet">
        /// <item>
        /// Attributes that start and end before the deleted attribute are
        /// unmodified.
        /// </item>
        ///
        /// <item>
        /// Attributes that start before the deleted attribute and end inside it
        /// are truncated to remove the part overlapping the deleted attribute.
        /// </item>
        ///
        /// <item>
        /// Attributes that have the same position and length as the deleted
        /// attribute are deleted, if they apply to any text.
        /// </item>
        ///
        /// <item>
        /// Attributes that start and end within the deleted attribute are
        /// deleted.
        /// </item>
        ///
        /// <item>
        /// Attributes that start within the deleted attribute, and end outside
        /// it, have their start truncated to remove the part overlapping the
        /// deleted attribute.
        /// </item>
        ///
        /// <item>
        /// Attributes that start after the deleted attribute have their start
        /// point adjusted to account for the deleted text.
        /// </item>
        /// </list>
        ///
        /// <para>
        /// This method does not modify the current object. A new <see
        /// cref="MarkupParseResult"/> is returned.
        /// </para>
        ///
        /// <para>
        /// If <paramref name="attributeToDelete"/> is not an attribute of this
        /// <see cref="MarkupParseResult"/>, the behaviour is undefined.
        /// </para>
        /// </remarks>
        /// <param name="attributeToDelete">The attribute to remove.</param>
        /// <returns>A new <see cref="MarkupParseResult"/> object, with the
        /// plain text modified and an updated collection of
        /// attributes.</returns>
        public MarkupParseResult DeleteRange(MarkupAttribute attributeToDelete)
        {
            var newAttributes = new List<MarkupAttribute>();

            // Address the trivial case: if the attribute has a zero
            // length, just create a new markup that doesn't include it.
            // The plain text is left unmodified, because this attribute
            // didn't apply to any text.
            if (attributeToDelete.Length == 0)
            {
                foreach (var a in this.Attributes)
                {
                    if (!a.Equals(attributeToDelete))
                    {
                        newAttributes.Add(a);
                    }
                }

                return new MarkupParseResult(this.Text, newAttributes);
            }

            var deletionStart = attributeToDelete.Position;
            var deletionEnd = attributeToDelete.Position + attributeToDelete.Length;

            var editedSubstring = this.Text.Remove(attributeToDelete.Position, attributeToDelete.Length);

            foreach (var existingAttribute in this.Attributes)
            {
                var start = existingAttribute.Position;
                var end = existingAttribute.Position + existingAttribute.Length;

                if (existingAttribute.Equals(attributeToDelete))
                {
                    // This is the attribute we're deleting. Don't include
                    // it.
                    continue;
                }

                var editedAttribute = existingAttribute;

                if (start <= deletionStart)
                {
                    // The attribute starts before start point of the item
                    // we're deleting.
                    if (end <= deletionStart)
                    {
                        // This attribute is entirely before the item we're
                        // deleting, and will be unmodified.
                    }
                    else if (end <= deletionEnd)
                    {
                        // This attribute starts before the item we're
                        // deleting, and ends inside it. The Position
                        // doesn't need to change, but its Length is
                        // trimmed so that it ends where the deleted
                        // attribute begins.
                        editedAttribute.Length = deletionStart - start;

                        if (existingAttribute.Length > 0 && editedAttribute.Length <= 0)
                        {
                            // The attribute's length has been reduced to
                            // zero. All of the contents it previous had
                            // have been removed, so we will remove the
                            // attribute itself.
                            continue;
                        }
                    }
                    else
                    {
                        // This attribute starts before the item we're
                        // deleting, and ends after it. Its length is
                        // edited to remove the length of the item we're
                        // deleting.
                        editedAttribute.Length -= attributeToDelete.Length;
                    }
                }
                else if (start >= deletionEnd)
                {
                    // The item begins after the item we're deleting. Its
                    // length isn't changing. We just need to offset its
                    // start position.
                    editedAttribute.Position = start - attributeToDelete.Length;
                }
                else if (start >= deletionStart && end <= deletionEnd)
                {
                    // The item is entirely within the item we're deleting.
                    // It will be deleted too - we'll skip including it in
                    // the updated attributes list.
                    continue;
                }
                else if (start >= deletionStart && end > deletionEnd)
                {
                    // The item starts within the item we're deleting, and
                    // ends outside it. We'll adjust the start point so
                    // that it begins at the point where this item and the
                    // item we're deleting stop overlapping.
                    var overlapLength = deletionEnd - start;
                    var newStart = deletionStart;
                    var newLength = existingAttribute.Length - overlapLength;

                    editedAttribute.Position = newStart;
                    editedAttribute.Length = newLength;
                }

                newAttributes.Add(editedAttribute);
            }

            return new MarkupParseResult(editedSubstring, newAttributes);
        }
    }
}
