import 'package:yarn_spinner.framework/src/library.dart';
import 'package:yarn_spinner.framework/src/yarn_spinner.dart';

class Program {
  String dumpCode(Library l) {
    var sb = StringBuilder();

    for (var entry in nodes) {
      sb.appendLine("Node " + entry.Key + ":");

      int instructionCount = 0;
      for (var instruction in entry.Value.Instructions) {
        String instructionText;

        instructionText = "    " + instruction.toString(this, l);

        String preface;

        if (instructionCount % 5 == 0 || instructionCount == entry.Value.Instructions.Count - 1) {
          preface = String.format(CultureInfo.invariantCulture, "{0,6}   ", instructionCount);
        }
        else {
          preface = String.format(CultureInfo.invariantCulture, "{0,6}   ", " ");
        }

        sb.appendLine(preface + instructionText);

        instructionCount++;
      }

      sb.appendLine();
    }


    return sb.toString();
  }

  Iterable<String> getTagsForNode(String nodeName) {
    return nodes[nodeName].Tags;
  }

  // TODO: this behaviour belongs in the VM as a "load additional program" feature, not in the Program data object

  static Program combine(List<Program> programs) {
    if (programs.length == 0) {
      throw ArgumentError(nameof(programs), "At least one program must be provided.");
    }


    var output = Program();

    for (var otherProgram in programs) {
      for (var otherNodeName in otherProgram.nodes) {

        if (output.nodes.containsKey(otherNodeName.Key)) {
          throw InvalidOperationException(String.format(CultureInfo.currentCulture, "This program already contains a node named {0}", otherNodeName.Key));
        }


        output.nodes[otherNodeName.Key] = otherNodeName.Value.clone();
      }

      output.initialValues.add(otherProgram.initialValues);
    }
    return output;
  }
}

class Instruction {

  String toString(Program p, Library l) {
    // Generate a comment, if the instruction warrants it
    String comment = "";

    // Stack manipulation comments
    var pops = 0;
    var pushes = 0;

    switch (Opcode) {

      // These operations all push a single value to the stack
      case OpCode.pushBool, OpCode.pushNull, OpCode.pushFloat, OpCode.pushString, OpCode.pushVariable, OpCode.showOptions: {
        pushes = 1;
      }

      // Functions pop 0 or more values, and pop 0 or 1
      case OpCode.callFunc: {
        var function = l.getFunction(operands[0].StringValue);

        pops = function.method.getParameters().length;

        var returnsValue = function.method.returnType != void.runtimeType;

        if (returnsValue) {
          pushes = 1;
        }


      }

      // Pop always pops a single value
      case OpCode.pop: {
        pops = 1;
      }

      // Switching to a different node will always clear the stack
      case OpCode.runNode: {
        comment += "Clears stack";
      }
    }

    // If we had any pushes or pops, report them
    if (pops > 0 && pushes > 0) {
      comment.addListener(this, String.format(CultureInfo.invariantCulture, "Pops {0}, Pushes {1}", pops, pushes));
    }
    else if (pops > 0) {
      comment.addListener(this, String.format(CultureInfo.invariantCulture, "Pops {0}", pops));
    }
    else if (pushes > 0) {
      comment.addListener(this, String.format(CultureInfo.invariantCulture, "Pushes {0}", pushes));
    }


    // String lookup comments
    switch (Opcode) {
      case OpCode.pushString, OpCode.runLine, OpCode.addOption: {

        // Add the string for this option, if it has one
        if (operands[0].StringValue != "") {
          comment += String.format(CultureInfo.invariantCulture, "\"{0}\"", operands[0].StringValue);
        }


      }
    }

    if (comment != "") {
      comment = "; " + comment;
    }


    String opAString = operands.Count > 0 ? operands[0].toString() : "";
    String opBString = operands.Count > 1 ? operands[1].toString() : "";

    return String.format(CultureInfo.invariantCulture, "{0,-15} {1,-10} {2,-10} {3, -10}", opcode.toString(), opAString, opBString, comment);
  }
}


class Node {
}
