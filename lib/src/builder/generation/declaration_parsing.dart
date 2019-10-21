// Copyright 2016 Workiva Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// ignore_for_file: deprecated_member_use_from_same_package
import 'package:analyzer/dart/ast/ast.dart';
import 'package:logging/logging.dart';
import 'package:over_react/src/builder/util.dart';
import 'package:over_react/src/component_declaration/annotations.dart' as annotations;
import 'package:over_react/src/util/string_util.dart';
import 'package:source_span/source_span.dart';
import 'package:transformer_utils/transformer_utils.dart' show getSpan, NodeWithMeta;

/// A set of [NodeWithMeta] component pieces declared using `over_react` builder annotations.
///
/// Can include:
///
/// * A single component declared using a `@Factory()`, `@Component()`, `@Props()`, and optionally a `@State()`
/// * Any number of abstract component pieces: `@AbstractComponent()`, `@AbstractProps()`, `@AbstractState()`
/// * Any number of mixins: `@PropsMixin()`, `@StateMixin()`
class ParsedDeclarations {
  factory ParsedDeclarations(CompilationUnit unit, SourceFile sourceFile, Logger logger) {
    bool hasErrors = false;
    bool hasDeclarations = false;
    bool hasPropsCompanionClass = false;
    bool hasAbstractPropsCompanionClass = false;
    bool hasStateCompanionClass = false;
    bool hasAbstractStateCompanionClass = false;

    void error(String message, [SourceSpan span]) {
      hasErrors = true;
      logger.severe(messageWithSpan(message, span: span));
    }

    /// If a [ClassMember] exists in [node] with the name `meta`, this will
    /// throw an error if the member is not static and a warning if the member
    /// is static.
    void checkForMetaPresence(ClassDeclaration node) {
      final metaField = metaFieldOrNull(node);
      final metaMethod = metaMethodOrNull(node);
      final isNotNull = metaField != null || metaMethod != null;
      final isStatic = (metaField?.isStatic ?? false) || (metaMethod?.isStatic ?? false);
      if (isNotNull) {
        // If a class declares a field or method with the name of `meta` which is
        // not static, then we should error, since the static `meta` const in the
        // generated implementation will have a naming collision.
        if (!isStatic) {
          error('Non-static class member `meta` is declared in ${node.name.name}. '
              '`meta` is a field declared by the over_react builder, and is therefore not '
              'valid for use as a class member in any class annotated with  @Props(), @State(), '
              '@AbstractProps(), @AbstractState(), @PropsMixin(), or @StateMixin()',
              getSpan(sourceFile, metaField ?? metaMethod));
        } else {
          // warn that static `meta` definition will not be accessible by consumers.
          logger.warning(messageWithSpan('Static class member `meta` is declared in ${node.name.name}. '
              '`meta` is a field declared by the over_react builder, and therefore this '
              'class member will be unused and should be removed or renamed.',
              span: getSpan(sourceFile, metaField ?? metaMethod)));
        }
      }
    }

    /// Validates that `meta` field in a companion class or props/state mixin
    /// is formatted as expected.
    ///
    /// Meta fields should have the following format:
    ///   `static const {Props|State}Meta meta = _$metaFor{className};`
    ///
    /// [cd] should be either a [ClassDeclaration] instance for the companion
    /// class of a props/state/abstract props/abstract state class, or the
    /// [ClassDeclaration] for a props or state mixin class.
    void validateMetaField(ClassDeclaration cd, String expectedType) {
      final metaField = getMetaField(cd);
      if (metaField == null) return;

      if (metaField.fields.type?.toSource() != expectedType) {
        error(
          'Static meta field in accessor class must be of type `$expectedType`',
          getSpan(sourceFile, metaField),
        );
      }

      final expectedInitializer = '${privateSourcePrefix}metaFor${cd.name.name}';

      final initializer = metaField.fields.variables.single.initializer
          ?.toSource();
      if (!(expectedInitializer == initializer)) {
        error(
          'Static $expectedType field in accessor class must be initialized to:'
              '`$expectedInitializer`',
          getSpan(sourceFile, metaField),
        );
      }
    }

    // Collect the annotated declarations.

    Map<String, List<CompilationUnitMember>> declarationMap = {
      key_factory:           <CompilationUnitMember>[],
      key_component:         <CompilationUnitMember>[],
      key_component2:        <CompilationUnitMember>[],
      key_props:             <CompilationUnitMember>[],
      key_state:             <CompilationUnitMember>[],
      key_abstractComponent: <CompilationUnitMember>[],
      key_abstractProps:     <CompilationUnitMember>[],
      key_abstractState:     <CompilationUnitMember>[],
      key_propsMixin:        <CompilationUnitMember>[],
      key_stateMixin:        <CompilationUnitMember>[],
    };

    // ignore: avoid_positional_boolean_parameters
    void updateCompanionClass(String annotation, bool value) {
      switch (annotation) {
        case 'Props':
          hasPropsCompanionClass = value;
          break;
        case 'AbstractProps':
          hasAbstractPropsCompanionClass = value;
          break;
        case 'State':
          hasStateCompanionClass = value;
          break;
        case 'AbstractState':
          hasAbstractStateCompanionClass = value;
          break;
      }
    }

    bool isPropsClass(String annotation) {
      return (annotation == 'Props' || annotation == 'AbstractProps');
    }

    bool isStateClass(String annotation) {
      return (annotation == 'State' || annotation == 'AbstractState');
    }

    unit.declarations.forEach((_member) {
      _member.metadata.forEach((_annotation) {
        final annotation = _annotation.name.toString();

        // Add to declarationMap if we have a valid over_react annotation
        if (declarationMap[annotation] != null) {
          hasDeclarations = true;
          declarationMap[annotation].add(_member);
        }

        // Now we need to check for a companion class on Dart 2 backwards compatible boilerplate
        // only check for companion class for @Props(), @State, @AbstractProps(),
        // and @AbstractState() annotated classes
        if (_member is! ClassDeclaration || !(isPropsClass(annotation) || isStateClass(annotation))) {
          return;
        }

        final ClassDeclaration member = _member;

        // Check that class name starts with [privateSourcePrefix]
        if (!member.name.name.startsWith(privateSourcePrefix)) {
          error('The class `${member.name.name}` does not start with `$privateSourcePrefix`. All Props, State, '
              'AbstractProps, and AbstractState classes should begin with `$privateSourcePrefix` on Dart 2',
              getSpan(sourceFile, member));
          return;
        }

        final companionName = member.name.name.substring(privateSourcePrefix.length);
        final companionClass = unit.declarations.firstWhere(
                (innerMember) =>
            innerMember is ClassDeclaration && innerMember.name.name == companionName,
            orElse: () => null);

        final hasCompanionClass = companionClass != null;
        if (hasCompanionClass) {
          // Backwards compatible boilerplate. Verify the companion class' meta field
          updateCompanionClass(annotation, true);
          validateMetaField(companionClass, isPropsClass(annotation) ? 'PropsMeta': 'StateMeta');
        } else {
          // Dart 2 only boilerplate. Check for meta presence
          checkForMetaPresence(member);
          updateCompanionClass(annotation, false);
        }
      });
    });

    // Validate the types of the annotated declarations.

    List<TopLevelVariableDeclaration> topLevelVarsOnly(String annotationName, Iterable<CompilationUnitMember> declarations) {
      final topLevelVarDeclarations = <TopLevelVariableDeclaration>[];

      declarations.forEach((declaration) {
        if (declaration is TopLevelVariableDeclaration) {
          topLevelVarDeclarations.add(declaration);
        } else {
          error(
              '`@$annotationName` can only be used on top-level variable declarations.',
              getSpan(sourceFile, declaration)
          );
        }
      });

      return topLevelVarDeclarations;
    }

    List<ClassDeclaration> classesOnly(String annotationName, Iterable<CompilationUnitMember> declarations) {
      final classDeclarations = <ClassDeclaration>[];

      declarations.forEach((declaration) {
        if (declaration is ClassDeclaration) {
          classDeclarations.add(declaration);
        } else {
          error(
              '`@$annotationName` can only be used on classes.',
              getSpan(sourceFile, declaration)
          );
        }
      });

      return classDeclarations;
    }

    declarationMap[key_factory] = topLevelVarsOnly(key_factory, declarationMap[key_factory]);

    [
      key_component,
      key_component2,
      key_props,
      key_state,
      key_abstractComponent,
      key_abstractComponent2,
      key_abstractProps,
      key_abstractState,
      key_propsMixin,
      key_stateMixin,
    ].forEach((annotationName) {
      declarationMap[annotationName] = classesOnly(annotationName, declarationMap[annotationName] ?? const <CompilationUnitMember>[]);
    });

    // Validate that all the declarations that make up a component are used correctly.

    Iterable<List<CompilationUnitMember>> requiredDecls =
        key_allComponentRequired.map((annotationName) => declarationMap[annotationName]);

    Iterable<List<CompilationUnitMember>> requiredDecls2 =
        key_allComponent2Required.map((annotationName) => declarationMap[annotationName]);

    Iterable<List<CompilationUnitMember>> optionalDecls =
        key_allComponentOptional.map((annotationName) => declarationMap[annotationName]);

    bool oneOfEachRequiredDecl2 = requiredDecls2.every((decls) => decls.length == 1);
    bool oneOfEachRequiredDecl = requiredDecls.every((decls) => decls.length == 1) || oneOfEachRequiredDecl2;
    bool noneOfAnyRequiredDecl2 = requiredDecls2.every((decls) => decls.isEmpty);
    bool noneOfAnyRequiredDecl = requiredDecls.every((decls) => decls.isEmpty) && noneOfAnyRequiredDecl2;

    bool atMostOneOfEachOptionalDecl = optionalDecls.every((decls) => decls.length <= 1);
    bool noneOfAnyOptionalDecl       = optionalDecls.every((decls) => decls.isEmpty);

    bool areDeclarationsValid = (
        (oneOfEachRequiredDecl && atMostOneOfEachOptionalDecl) ||
        (noneOfAnyRequiredDecl && noneOfAnyOptionalDecl)
    );

    // Give the consumer some useful errors if the declarations aren't valid.

    void _emitDuplicateDeclarationError(String annotationName, int instanceNumber) {
      final declarations = declarationMap[annotationName];
      error(
          'To define a component, there must be a single `@$annotationName` per file, '
          'but ${declarations.length} were found. (${instanceNumber + 1} of ${declarations.length})',
          getSpan(sourceFile, declarations[instanceNumber])
      );
    }

    if (declarationMap[key_component].isNotEmpty && declarationMap[key_component2].isNotEmpty) {
      error(
          'To define a component, there must be a single `@$key_component` **OR** `@$key_component2` annotation, '
          'but never both.'
      );
    }

    // Ensure that Component2 declarations do not use legacy lifecycle methods.

    if (declarationMap[key_component2].isNotEmpty) {
      final firstComponent2Member = declarationMap[key_component2].first;
      if (firstComponent2Member is ClassDeclaration) {
        Map<String, String> legacyLifecycleMethodsMap = {
          'componentWillReceiveProps': 'Use getDerivedStateFromProps instead.',
          'componentWillMount': 'Use init instead.',
          'componentWillUpdate': 'Use getSnapshotBeforeUpdate instead.',
        };

        legacyLifecycleMethodsMap.forEach((methodName, helpMessage) {
          final method = firstComponent2Member.getMethod(methodName);

          if (method != null) {
            error(unindent(
                '''
                Error within ${firstComponent2Member.name.name}.
        
                When using Component2, a class cannot use ${method.name} because React 16 has removed ${method.name} 
                and renamed it UNSAFE_${method.name}.
                
                $helpMessage
                
                See https://reactjs.org/docs/react-component.html#legacy-lifecycle-methods for additional information.   
                '''
            ));
          }
        });
      }
    }

    if (!areDeclarationsValid) {
      if (!noneOfAnyRequiredDecl) {
        if (declarationMap[key_component].isEmpty && declarationMap[key_component2].isEmpty) {
          // Can't tell if they were trying to build a version 1 or version 2 component,
          // so we'll tailor the error message accordingly.
          error(
              'To define a component, there must also be a `@$key_component` or `@$key_component2` within the same file, '
              'but none were found.'
          );
        } else if (declarationMap[key_component].length > 1) {
          for (int i = 0; i < declarationMap[key_component].length; i++) {
            _emitDuplicateDeclarationError(key_component, i);
          }
        } else if (declarationMap[key_component2].length > 1) {
          for (int i = 0; i < declarationMap[key_component2].length; i++) {
            _emitDuplicateDeclarationError(key_component2, i);
          }
        }

        key_allComponentVersionsRequired.forEach((annotationName) {
          final declarations = declarationMap[annotationName];
          if (declarations.isEmpty) {
            error(
                'To define a component, there must also be a `@$annotationName` within the same file, '
                'but none were found.'
            );
          } else if (declarations.length > 1) {
            for (int i = 0; i < declarations.length; i++) {
              _emitDuplicateDeclarationError(annotationName, i);
            }
          }
          declarationMap[annotationName] = [];
        });
      }

      key_allComponentOptional.forEach((annotationName) {
        final declarations = declarationMap[annotationName];

        if (declarations.length > 1) {
          for (int i = 0; i < declarations.length; i++) {
            error(
                'To define a component, there must not be more than one `@$annotationName` per file, '
                'but ${declarations.length} were found. (${i + 1} of ${declarations.length})',
                getSpan(sourceFile, declarations[i])
            );
          }
        }

        if (noneOfAnyRequiredDecl && declarations.isNotEmpty) {
          error(
              'To define a component, a `@$annotationName` must be accompanied by '
              'the following annotations within the same file: '
              '(@$key_component || @$key_component2), ${key_allComponentVersionsRequired.map((key) => '@$key').join(', ')}.',
              getSpan(sourceFile, declarations.first)
          );
        }
        declarationMap[annotationName] = [];
      });
    } else {
      void checkMetaForMixin(ClassDeclaration mixin, String metaStructName) {
        final className = mixin.name.name;
        // If the mixin starts with `_$`, then we are on Dart 2 only boilerplate,
        // and the mixin should not have a meta field/method
        if (className.startsWith(privateSourcePrefix)) {
          checkForMetaPresence(mixin);
        } else {
          // If the mixin does start not start with `_$`, then we are on the transitional
          // boilerplate and we need to validate the meta field.
          validateMetaField(mixin, metaStructName);
        }
      }
      for (final propsMixin in declarationMap[key_propsMixin]) {
        checkMetaForMixin(propsMixin, 'PropsMeta');
      }

      for (final stateMixin in declarationMap[key_stateMixin]) {
        checkMetaForMixin(stateMixin, 'StateMeta');
      }
    }

    // validate that the factory is initialized correctly
    final factory = declarationMap[key_factory].length <= 1 ? singleOrNull(declarationMap[key_factory]) : null;
    if (factory != null && factory is TopLevelVariableDeclaration) {
      final String factoryName = factory.variables.variables.first.name.name;

      if (factory.variables.variables.length != 1) {
        error('Factory declarations must be a single variable.',
            getSpan(sourceFile, factory.variables));
      } else {
        final variable = factory.variables.variables.first;
        final expectedInitializer = '$privateSourcePrefix$factoryName';

        if ((variable?.initializer?.toString() ?? '') != expectedInitializer) {
          error(
              'Factory variables are stubs for the generated factories, and should '
                  'be initialized with the valid variable name for builder compatibility. '
                  'Should be: $expectedInitializer',
              getSpan(sourceFile, variable.initializer ?? variable)
          );
        }
      }
    }

    if (hasErrors) {
      for (final key in declarationMap.keys) {
        declarationMap[key] = [];
      }
    }

    return ParsedDeclarations._(
        factory:       singleOrNull(declarationMap[key_factory]),
        component:     singleOrNull(declarationMap[key_component]),
        component2:    singleOrNull(declarationMap[key_component2]),
        props:         singleOrNull(declarationMap[key_props]),
        state:         singleOrNull(declarationMap[key_state]),

        abstractProps: declarationMap[key_abstractProps].isNotEmpty ? declarationMap[key_abstractProps] : <ClassDeclaration>[],
        abstractState: declarationMap[key_abstractState].isNotEmpty ? declarationMap[key_abstractState] : <ClassDeclaration>[],

        propsMixins:   declarationMap[key_propsMixin].isNotEmpty ? declarationMap[key_propsMixin] : <ClassDeclaration>[],
        stateMixins:   declarationMap[key_stateMixin].isNotEmpty ? declarationMap[key_stateMixin] : <ClassDeclaration>[],

        hasErrors: hasErrors,
        hasDeclarations: hasDeclarations,
        hasPropsCompanionClass: hasPropsCompanionClass,
        hasAbstractPropsCompanionClass: hasAbstractPropsCompanionClass,
        hasStateCompanionClass: hasStateCompanionClass,
        hasAbstractStateCompanionClass: hasAbstractStateCompanionClass,
    );
  }

  ParsedDeclarations._({
      TopLevelVariableDeclaration factory,
      // TODO: Remove when `annotations.Component` is removed in the 4.0.0 release.
      @Deprecated('4.0.0')
      ClassDeclaration component,
      ClassDeclaration component2,
      ClassDeclaration props,
      ClassDeclaration state,

      List<ClassDeclaration> abstractProps,
      List<ClassDeclaration> abstractState,

      List<ClassDeclaration> propsMixins,
      List<ClassDeclaration> stateMixins,

      this.hasErrors,
      this.hasDeclarations,

      bool hasPropsCompanionClass,
      bool hasAbstractPropsCompanionClass,
      bool hasStateCompanionClass,
      bool hasAbstractStateCompanionClass,
  }) :
      this.factory       = (factory   == null)  ? null : FactoryNode(factory),
      this.component     = (component == null)  ? null : ComponentNode(component),
      this.component2    = (component2 == null) ? null : Component2Node(component2),
      this.props         = (props     == null)  ? null : PropsNode(props, hasPropsCompanionClass),
      this.state         = (state     == null)  ? null : StateNode(state, hasStateCompanionClass),

      this.abstractProps = List.unmodifiable(abstractProps.map((props) => AbstractPropsNode(props, hasAbstractPropsCompanionClass))),
      this.abstractState = List.unmodifiable(abstractState.map((state) => AbstractStateNode(state, hasAbstractStateCompanionClass))),

      this.propsMixins   = List.unmodifiable(propsMixins.map((propsMixin) => PropsMixinNode(propsMixin))),
      this.stateMixins   = List.unmodifiable(stateMixins.map((stateMixin) => StateMixinNode(stateMixin))),

      this.declaresComponent = factory != null
  {
    assert(
        ((this.factory == null && ((this.component ?? this.component2) == null) && this.props == null) ||
         (this.factory != null && ((this.component ?? this.component2) != null) && this.props != null)) &&
        '`factory`, `component` / `component2`, and `props` must be either all null or all non-null. '
        'Any other combination represents an invalid component declaration. ' is String
    );
  }



  static final String key_factory           = getName(annotations.Factory);
  // TODO: Remove when `annotations.Component` is removed in the 4.0.0 release.
  @Deprecated('4.0.0')
  static final String key_component         = getName(annotations.Component);
  static final String key_component2        = getName(annotations.Component2);
  static final String key_props             = getName(annotations.Props);
  static final String key_state             = getName(annotations.State);

  // TODO: Remove when `annotations.AbstractComponent` is removed in the 4.0.0 release.
  @Deprecated('4.0.0')
  static final String key_abstractComponent  = getName(annotations.AbstractComponent);
  static final String key_abstractComponent2 = getName(annotations.AbstractComponent2);
  static final String key_abstractProps      = getName(annotations.AbstractProps);
  static final String key_abstractState      = getName(annotations.AbstractState);

  static final String key_propsMixin        = getName(annotations.PropsMixin);
  static final String key_stateMixin        = getName(annotations.StateMixin);

  static final List<String> key_allComponentVersionsRequired = List.unmodifiable([
    key_factory,
    key_props,
  ]);

  // TODO: Remove when the `@Component` annotation is removed in the 4.0.0 release.
  @Deprecated('4.0.0')
  static final List<String> key_allComponentRequired = List.unmodifiable(
      List.from(key_allComponentVersionsRequired)..add(key_component));

  static final List<String> key_allComponent2Required = List.unmodifiable(
      List.from(key_allComponentVersionsRequired)..add(key_component2));

  static final List<String> key_allComponentOptional = List.unmodifiable([
    key_state,
  ]);

  static final RegExp key_any_annotation = RegExp(
      r'@(?:' +
      [
        key_factory,
        key_component,
        key_component2,
        key_props,
        key_state,
        key_abstractComponent,
        key_abstractComponent2,
        key_abstractProps,
        key_abstractState,
        key_propsMixin,
        key_stateMixin,
      ].join('|').replaceAll(r'$', r'\$') +
      r')',
      caseSensitive: true
  );

  static bool mightContainDeclarations(String source) {
    return key_any_annotation.hasMatch(source);
  }

  final FactoryNode factory;
  // TODO: Remove when `annotations.Component` is removed in the 4.0.0 release.
  @Deprecated('4.0.0')
  final ComponentNode component;
  final Component2Node component2;
  final PropsNode props;
  final StateNode state;

  final List<AbstractPropsNode> abstractProps;
  final List<AbstractStateNode> abstractState;

  final List<PropsMixinNode> propsMixins;
  final List<StateMixinNode> stateMixins;

  final bool hasErrors;
  final bool hasDeclarations;
  final bool declaresComponent;

  /// Helper function that returns the single value of a [list], or null if it is empty.
  static singleOrNull(List list) => list.isNotEmpty ? list.single : null;
}

// Generic type aliases, for readability.

// TODO: Remove when `annotations.Component` is removed in the 4.0.0 release.
@Deprecated('4.0.0')
class ComponentNode<TMeta extends annotations.Component>
    extends NodeWithMeta<ClassDeclaration, TMeta> {
  static const String _subtypeOfParamName = 'subtypeOf';

  /// The value of the `subtypeOf` parameter passed in to this node's annotation.
  Identifier subtypeOfValue;

  ComponentNode(AnnotatedNode unit) : super(unit) {
    // Perform special handling for the `subtypeOf` parameter of this node's annotation.
    //
    // If valid, omit it from `unsupportedArguments` so that the `meta` can be accessed without it
    // (with the value available via `subtypeOfValue`), given that all other arguments are valid.

    NamedExpression subtypeOfParam = this.unsupportedArguments.firstWhere((expression) {
      return expression is NamedExpression && expression.name.label.name == _subtypeOfParamName;
    }, orElse: () => null);

    if (subtypeOfParam != null) {
      if (subtypeOfParam.expression is! Identifier) {
        // ignore: only_throw_errors
        throw '`$_subtypeOfParamName` must be an identifier: $subtypeOfParam';
      }

      this.subtypeOfValue = subtypeOfParam.expression;
      this.unsupportedArguments.remove(subtypeOfParam);
    }
  }
}

class Component2Node extends ComponentNode<annotations.Component2> {
  Component2Node(AnnotatedNode unit) : super(unit);
}

class FactoryNode           extends NodeWithMeta<TopLevelVariableDeclaration, annotations.Factory> {FactoryNode(unit)           : super(unit);}

class PropsOrStateNode<T> extends NodeWithMeta<ClassDeclaration, T> {
  final bool hasCompanionClass;
  // ignore: avoid_positional_boolean_parameters
  PropsOrStateNode(unit, this.hasCompanionClass): super(unit);
}
class PropsNode extends PropsOrStateNode<annotations.Props> {
  PropsNode(unit, hasCompanionClass): super(unit, hasCompanionClass);
}
class StateNode extends PropsOrStateNode<annotations.State> {
  StateNode(unit, hasCompanionClass): super(unit, hasCompanionClass);
}

class AbstractPropsNode extends PropsOrStateNode<annotations.AbstractProps> {
  AbstractPropsNode(unit, hasCompanionClass): super(unit, hasCompanionClass);
}
class AbstractStateNode extends PropsOrStateNode<annotations.AbstractState> {
  AbstractStateNode(unit, hasCompanionClass): super(unit, hasCompanionClass);
}

class PropsMixinNode        extends NodeWithMeta<ClassDeclaration, annotations.PropsMixin>         {PropsMixinNode(unit)        : super(unit);}
class StateMixinNode        extends NodeWithMeta<ClassDeclaration, annotations.StateMixin>         {StateMixinNode(unit)        : super(unit);}

