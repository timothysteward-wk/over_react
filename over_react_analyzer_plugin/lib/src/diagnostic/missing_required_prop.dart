import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:over_react_analyzer_plugin/src/diagnostic/component_usage.dart';
import 'package:over_react_analyzer_plugin/src/fluent_interface_util.dart';

class MissingRequiredPropDiagnostic extends ComponentUsageDiagnosticContributor {
  static final code = ErrorCode(
      'over_react_required_prop',
      'The prop {0} is required.',
      AnalysisErrorSeverity.WARNING,
      AnalysisErrorType.STATIC_WARNING);

  static final fixKind = FixKind(
      code.name, 200, 'Add required prop \'{0}\'');

  ClassElement _cachedAccessorClass;

  @override
  computeErrorsForUsage(result, collector, usage) async {

    final requiredFields = <FieldElement>[];

    // FIXME this almost definitely needs optimization/caching

    var builderType = usage.builder.staticType;
    // Handle generic factories (todo might not be needed)
    while (builderType is TypeParameterType) {
      builderType = (builderType as TypeParameterType).bound;
    }

    // todo check if factory invocation
    if (builderType != null && builderType.name != 'UiProps' && builderType is InterfaceType) {
      final classAndSuperclasses = [builderType.element]
        ..addAll(builderType.element.allSupertypes.map((t) => t.element));
      final allFields = classAndSuperclasses.expand((c) => c.fields);
      for (var field in allFields) {
        if (requiredFields.any((requiredField) => requiredField.name == field.name)) {
          // Short-circuit if we've already identified this field as required.
          // There might be duplicates if props are overridden, and there will
          // definitely be duplicates in the builder-generated code.
          continue;
        }

        if (field.metadata.any((annotation) {
          // Common case, might be good to short circuit here for perf
          if (annotation.isOverride) return false;

          final value = annotation.computeConstantValue();
          final type = value?.type;
          final typeLibrary = type?.element?.library;
          if (typeLibrary?.name != 'over_react.component_declaration.annotations') {
            return false;
          }

          _cachedAccessorClass ??= typeLibrary.getType('Accessor');
          if (!result.typeSystem.isAssignableTo(type, _cachedAccessorClass.type)) {
            return false;
          }

          // This is null when isRequired does not have a valid value
          // (e.g., as the user is typing it in)
          return value.getField('isRequired').toBoolValue() ?? false;
        })) {
          requiredFields.add(field);
        }
      }
    }

    final missingRequiredFieldNames = requiredFields.map((f) => f.name).toSet();

    forEachCascadedProp(usage, (lhs, rhs) {
      missingRequiredFieldNames.remove(lhs.propertyName.name);
    });

    for (var name in missingRequiredFieldNames) {
      collector.addError(
        code,
        location(result, range: range.node(usage.builder)),
        errorMessageArgs: [name],
        // todo fix to add prop
      );
    }
  }
}
