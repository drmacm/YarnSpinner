import 'package:yarn_spinner.compiler.framework/src/upgrader/i_language_upgrader.dart';
import 'package:yarn_spinner.compiler.framework/src/upgrader/language_upgrader.dart';
import 'package:yarn_spinner.compiler.framework/src/upgrader/upgraders/v1to_v2/yarn_spinner_v1_lexer.dart';
import 'package:yarn_spinner.compiler.framework/src/upgrader/upgraders/v1to_v2/yarn_spinner_v1_parser.dart';
import 'package:yarn_spinner.compiler.framework/src/upgrader/upgraders/v1to_v2/yarn_spinner_v1_parser_base_visitor.dart';

class OptionsUpgrader implements ILanguageUpgrader {
  @override
  UpgradeResult upgrade(UpgradeJob upgradeJob) {
    var outputFiles = List<OutputFile>();

    for (var file in upgradeJob.files) {
      var replacements = List<TextReplacement>();

      ICharStream input = CharStreams.fromstring(file.source);
      YarnSpinnerV1Lexer lexer = YarnSpinnerV1Lexer(input);
      CommonTokenStream tokens = CommonTokenStream(lexer);
      YarnSpinnerV1Parser parser = YarnSpinnerV1Parser(tokens);

      var tree = parser.dialogue();

      var formatFunctionVisitor = _OptionsVisitor(replacements);

      formatFunctionVisitor.visit(tree);

      outputFiles.add(OutputFile(file.fileName, replacements, file.source));
    }

    var result = UpgradeResult;
    result.files = outputFiles;
    return result;
  }

}
}
class _OptionsVisitor extends YarnSpinnerV1ParserBaseVisitor<int> {
  ICollection<TextReplacement> _replacements;

  final List<_OptionLink> _currentNodeOptionLinks = List<_OptionLink>();

  _OptionsVisitor(ICollection<TextReplacement> replacements) {
    _replacements = replacements;
  }

  static String getContextTextWithWhitespace(ParserRuleContext context) {
    // Get the original text of expressionContext. We can't
    // use "expressionContext.GetText()" here, because that
    // just concatenates the text of all captured tokens,
    // and doesn't include text on hidden channels (e.g.
    // whitespace and comments).
    if (context == null) {
      return String.empty;
    }


    var interval = Interval(context.Start.StartIndex, context.Stop.StopIndex);
    return context.Start.InputStream.getText(interval);
  }

  int visitNode(NodeContext context) {
    _currentNodeOptionLinks.clear();

    visitChildren(context);

    if (_currentNodeOptionLinks.count == 0) {
      // No options in this node. Early out.
      return 0;
    }


    // CurrentNodeOptionLinks now contains all options
    // that were encountered; create amendments to delete them
    // and add shortcut options
    var newShortcutOptionEntries = List<String>();

    for (var optionLink in _currentNodeOptionLinks) {
      // If this option link has any hashtags, the newline at
      // the end of the line is captured, so we'll need to
      // generate a new one in our replacement text. If not,
      // then the replacement text is empty.
      var needsNewline = optionLink.context.hashtag().length > 0;

      String replacementText = "// Option ""${getContextTextWithWhitespace(optionLink.context.option_formatted_text())}"" moved to the end of this node";
      replacementText += needsNewline ? "\n" : String.empty;

      // Create a replacement to remove it
      var replacement = TextReplacement;
      replacement.start = optionLink.context.Start.StartIndex;
      replacement.startLine = optionLink.context.Start.Line;
      replacement.originalText = getContextTextWithWhitespace(optionLink.context);
      replacement.replacementText = replacementText;
      replacement.comment = "An option using deprecated syntax was moved to the end of the node.";

      _replacements.add(replacement);

      // And create a replacement at the end to add the
      // shortcut replacement
      var optionLine = getContextTextWithWhitespace(optionLink.context.option_formatted_text());
      var optionDestination = optionLink.context.nodeName?.Text ?? "<ERROR: invalid destination>";
      var hashtags = optionLink.context.hashtag().select((hashtag) => getContextTextWithWhitespace(hashtag));

      var conditions = optionLink.conditions.select((c) {
        if (c.requiredTruthValue == true) {
          return "(${getContextTextWithWhitespace(c.expression)})";
        }
        else {
          return "!(${getContextTextWithWhitespace(c.expression)})";
        }
       }).reverse();

      var allConditions = String.join(" && ", conditions);

      var sb = StringBuilder();

      // Create the shortcut option
      sb.append("-> ");
      sb.append(optionLine);

      // If this option had any conditions, emit the computed
      // line condition
      if (allConditions.count() > 0) {
        sb.append(" <<if ${allConditions}>>");
      }


      // Emit all hashtags that the option had
      for (var hashtag in hashtags) {
        sb.append(" ${hashtag}");
      }

      // Now start creating the jump instruction
      sb.appendLine();

      // Indent one level; we know we're at the end of a node
      // so we're at the zero indentation level
      sb.append("    ");

      // Emit the jump instruction itself
      sb.append("<<jump ${optionDestination}>>");
      sb.appendLine();

      // We're done!
      newShortcutOptionEntries.add(sb.toString());
    }

    // Finally, create a replacement that injects the newly created shortcut options
    var endOfNode = context.bODY_END().Symbol;

    var newOptionsReplacement = TextReplacement;
    newOptionsReplacement.start = endOfNode.StartIndex;
    newOptionsReplacement.originalText = String.empty;
    newOptionsReplacement.replacementText = String.join(.empty, newShortcutOptionEntries);
    newOptionsReplacement.startLine = endOfNode.Line;
    newOptionsReplacement.comment = "Options using deprecated syntax were moved to the end of the node.";

    _replacements.add(newOptionsReplacement);

    return 0;
  }

  int visitOptionJump(OptionJumpContext context) {
    var destination = context.nodeName.Text;

    var replacement = TextReplacement;
    replacement.originalText = getContextTextWithWhitespace(context);
    replacement.replacementText = "<<jump ${destination}>>";
    replacement.start = context.Start.StartIndex;
    replacement.startLine = context.Start.Line;
    replacement.comment = "A jump was upgraded to use updated syntax.";

    _replacements.add(replacement);

    return 0;
  }

  int visitOptionLink(OptionLinkContext context) {
    var link = _OptionLink(context);

    // Walk up the tree until we hit a NodeContext, looking for
    // if-clauses, else-if clauses, and end-if clauses.
    var parent = context.Parent;

    while (parent != null && parent is YarnSpinnerV1ParserNodeContext == false) {
      Else_clauseContext elseContext = parent as Else_clauseContext;
      Else_if_clauseContext elseIfContext = parent as Else_if_clauseContext;
      If_clauseContext ifClause = parent as If_clauseContext;
      if (parent is If_clauseContext) {
        // The option is inside an 'if' clause. The
        // expression must evaluate to true in order for
        // this option to run.
        link.conditions.add(Tuple2.fromList([ifClause.expression(), true]));
      }
      else if (parent is Else_if_clauseContext) {
        // The option is inside an 'else if' clause. The
        // expression must evaluate to true, and all of the
        // preceding if and else-if clauses in this if
        // statement must evaluate to false, in order for
        // this option to run.
        link.conditions.add(Tuple2.fromList([elseIfContext.expression(), true]));

        var parentIfClause = elseIfContext.Parent as YarnSpinnerV1ParserIf_statementContext;

        for (var siblingClause in parentIfClause.children) {
          // Stop if we've reached ourself
          if (siblingClause == elseIfContext) {
            break
          }


          switch (siblingClause) {
            case If_clauseContext: {
              val siblingIfClause = tmp
              link.conditions.add(Tuple2.fromList([siblingIfClause.expression(), false]));
            }
            case Else_if_clauseContext: {
              val siblingElseIfClause = tmp
              link.conditions.add(Tuple2.fromList([siblingElseIfClause.expression(), false]));
            }
          }
        }
      }
      else if (parent is Else_clauseContext) {
        // The option is inside an 'else' clause. All of the
        // preceding if and else-if clauses in this if
        // statement must evaluate to false, in order for
        // this option to run.
        var parentIfClause = elseContext.Parent as YarnSpinnerV1ParserIf_statementContext;

        for (var siblingClause in parentIfClause.children) {
          // Stop if we've hit ourself (probably not an
          // issue since an else statement occurs at the
          // end anyway, but good to check imo)
          if (siblingClause == elseContext) {
            break
          }


          switch (siblingClause) {
            case If_clauseContext: {
              val siblingIfClause = tmp
              link.conditions.add(Tuple2.fromList([siblingIfClause.expression(), false]));
            }
            case Else_if_clauseContext: {
              val siblingElseIfClause = tmp
              link.conditions.add(Tuple2.fromList([siblingElseIfClause.expression(), false]));
            }
          }
        }
      }


      // Step up the tree
      parent = parent.Parent;
    }

    _currentNodeOptionLinks.add(link);

    return super.visitOptionLink(context);
  }

class _OptionLink {
  OptionLinkContext Context;

  // The collection of conditions for this option to appear
  List<ValueTuple<ExpressionContext, bool>> Conditions;

  _OptionLink(OptionLinkContext context) {
    this.context = context;
    conditions = List<ValueTuple<ExpressionContext, bool>>();
  }
}
