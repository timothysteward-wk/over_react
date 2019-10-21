import 'dart:async';

import 'package:analyzer/analyzer.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:over_react/src/builder/generation/declaration_parsing.dart';
import 'package:over_react/src/builder/generation/impl_generation.dart';
import 'package:path/path.dart' as p;
import 'package:source_span/source_span.dart';

import './util.dart';

Builder overReactBuilder(BuilderOptions options) => OverReactBuilder();

class OverReactBuilder extends Builder {
  @override
  Map<String, List<String>> get buildExtensions => {
    '.dart': [outputExtension],
  };

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final source = await buildStep.readAsString(buildStep.inputId);
    final libraryUnit = _tryParseCompilationUnit(source, buildStep.inputId);
    if (libraryUnit == null) {
      return;
    }
    if (isPart(libraryUnit)) {
      return;
    }

    final outputs = <String>[];
    void generateForFile(String source, AssetId id, CompilationUnit unit) {
      if (!ParsedDeclarations.mightContainDeclarations(source)) {
        return;
      }
      final sourceFile = SourceFile.fromString(
        source, url: idToPackageUri(id));
      final declarations = ParsedDeclarations(unit, sourceFile, log);
      if (declarations.hasErrors) {
        log.severe('There was an error parsing the file declarations for file: $id');
        return;
      }
      final generator = ImplGenerator(log, sourceFile)
        ..generate(declarations);
      final generatedOutput = generator.outputContentsBuffer.toString().trim();
      if (generatedOutput.isNotEmpty) {
        outputs.add(generatedOutput);
      }
    }

    // Collect all of the part files for this library.
    final parts = libraryUnit.directives
      .whereType<PartDirective>()
      // Ignore all generated `.g.dart` parts.
      .where((part) => !part.uri.stringValue.endsWith('.g.dart'));

    // Generate over_react code for the input library.
    generateForFile(source, buildStep.inputId, libraryUnit);


    final outputId = buildStep.inputId.changeExtension(outputExtension);
    final expectedPart = p.basename(outputId.path);

    bool hasOutputPartDirective() {
      final partUris = libraryUnit.directives
        .whereType<PartDirective>()
        .map((p) => p.uri.stringValue);
      return partUris.contains(expectedPart);
    }

    // Generate over_react code for each part file of the input library.
    for (final part in parts) {
      final partId = AssetId.resolve(
        part.uri.stringValue,
        from: buildStep.inputId);
      if (!await buildStep.canRead(partId)) {
        continue;
      }
      final partSource = await buildStep.readAsString(partId);
      final partUnit = _tryParseCompilationUnit(partSource, partId);
      if (partUnit == null) {
        continue;
      }
      generateForFile(partSource, partId, partUnit);
    }

    if (outputs.isNotEmpty) {
      // Verify that the library file has an `.over_react.g.dart` part.
      if (!hasOutputPartDirective()) {
        log.severe('Missing "part \'$expectedPart\';".');
      }

      await _writePart(buildStep, outputId, outputs);
    } else {
      if (hasOutputPartDirective()) {
        log.warning('An over_react part directive was found in ${buildStep.inputId.path}, '
            'but no code was generated. The part directive may be unnecessary if the file '
            'does not contain any concrete components or abstract state/props classes.');
      }
    }
  }

  static final _headerLine = '// '.padRight(77, '*');

  static final _formatter = DartFormatter();

  static final RegExp _overReactPartDirective = RegExp(
    r'''['"].*\.over_react\.g\.dart['"]''',
  );

  // ignore: unused_element
  static bool _mightContainDeclarations(String source) {
    return ParsedDeclarations.mightContainDeclarations(source) ||
      _overReactPartDirective.hasMatch(source);
  }

  static CompilationUnit _tryParseCompilationUnit(String source, AssetId id) {
    try {
      return parseCompilationUnit(
        source,
        name: id.path,
        suppressErrors: false,
        parseFunctionBodies: true);
    } catch (error, stackTrace) {
      log
        ..fine('There was an error parsing the compilation unit for file: $id')
        ..fine(error)
        ..fine(stackTrace);
      return null;
    }
  }

  static FutureOr<void> _writePart(BuildStep buildStep, AssetId outputId, Iterable<String> outputs) async {
    final partOf = "'${p.basename(buildStep.inputId.uri.toString())}'";

    final buffer = StringBuffer()
      ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
      ..writeln()
      ..writeln('part of $partOf;')
      ..writeln()
      ..writeln(_headerLine)
      ..writeln('// OverReactBuilder (package:over_react/src/builder.dart)')
      ..writeln(_headerLine);

    for (final item in outputs) {
      buffer
        ..writeln()
        ..writeln(item);
    }

    final output = _formatter.format(buffer.toString());
    await buildStep.writeAsString(outputId, output);
  }
}
