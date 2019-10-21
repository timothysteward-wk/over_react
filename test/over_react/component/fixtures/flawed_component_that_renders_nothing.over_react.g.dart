// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flawed_component_that_renders_nothing.dart';

// **************************************************************************
// OverReactBuilder (package:over_react/src/builder.dart)
// **************************************************************************

// React component factory implementation.
//
// Registers component implementation and links type meta to builder factory.
final $FlawedWithNoChildComponentFactory = registerComponent2(
  () => new _$FlawedWithNoChildComponent(),
  builderFactory: FlawedWithNoChild,
  componentClass: FlawedWithNoChildComponent,
  isWrapper: false,
  parentType: null,
  displayName: 'FlawedWithNoChild',
);

abstract class _$FlawedWithNoChildPropsAccessorsMixin
    implements _$FlawedWithNoChildProps {
  @override
  Map get props;

  /* GENERATED CONSTANTS */

  static const List<PropDescriptor> $props = const [];
  static const List<String> $propKeys = const [];
}

const PropsMeta _$metaForFlawedWithNoChildProps = const PropsMeta(
  fields: _$FlawedWithNoChildPropsAccessorsMixin.$props,
  keys: _$FlawedWithNoChildPropsAccessorsMixin.$propKeys,
);

_$$FlawedWithNoChildProps _$FlawedWithNoChild([Map backingProps]) =>
    backingProps == null
        ? new _$$FlawedWithNoChildProps$JsMap(new JsBackedMap())
        : new _$$FlawedWithNoChildProps(backingProps);

// Concrete props implementation.
//
// Implements constructor and backing map, and links up to generated component factory.
abstract class _$$FlawedWithNoChildProps extends _$FlawedWithNoChildProps
    with _$FlawedWithNoChildPropsAccessorsMixin
    implements FlawedWithNoChildProps {
  _$$FlawedWithNoChildProps._();

  factory _$$FlawedWithNoChildProps(Map backingMap) {
    if (backingMap == null || backingMap is JsBackedMap) {
      return new _$$FlawedWithNoChildProps$JsMap(backingMap);
    } else {
      return new _$$FlawedWithNoChildProps$PlainMap(backingMap);
    }
  }

  /// Let [UiProps] internals know that this class has been generated.
  @override
  bool get $isClassGenerated => true;

  /// The [ReactComponentFactory] associated with the component built by this class.
  @override
  ReactComponentFactoryProxy get componentFactory =>
      super.componentFactory ?? $FlawedWithNoChildComponentFactory;

  /// The default namespace for the prop getters/setters generated for this class.
  @override
  String get propKeyNamespace => 'FlawedWithNoChildProps.';
}

// Concrete props implementation that can be backed by any [Map].
class _$$FlawedWithNoChildProps$PlainMap extends _$$FlawedWithNoChildProps {
  // This initializer of `_props` to an empty map, as well as the reassignment
  // of `_props` in the constructor body is necessary to work around a DDC bug: https://github.com/dart-lang/sdk/issues/36217
  _$$FlawedWithNoChildProps$PlainMap(Map backingMap)
      : this._props = {},
        super._() {
    this._props = backingMap ?? {};
  }

  /// The backing props map proxied by this class.
  @override
  Map get props => _props;
  Map _props;
}

// Concrete props implementation that can only be backed by [JsMap],
// allowing dart2js to compile more optimal code for key-value pair reads/writes.
class _$$FlawedWithNoChildProps$JsMap extends _$$FlawedWithNoChildProps {
  // This initializer of `_props` to an empty map, as well as the reassignment
  // of `_props` in the constructor body is necessary to work around a DDC bug: https://github.com/dart-lang/sdk/issues/36217
  _$$FlawedWithNoChildProps$JsMap(JsBackedMap backingMap)
      : this._props = new JsBackedMap(),
        super._() {
    this._props = backingMap ?? new JsBackedMap();
  }

  /// The backing props map proxied by this class.
  @override
  JsBackedMap get props => _props;
  JsBackedMap _props;
}

// Concrete component implementation mixin.
//
// Implements typed props/state factories, defaults `consumedPropKeys` to the keys
// generated for the associated props class.
class _$FlawedWithNoChildComponent extends FlawedWithNoChildComponent {
  _$$FlawedWithNoChildProps$JsMap _cachedTypedProps;

  @override
  _$$FlawedWithNoChildProps$JsMap get props => _cachedTypedProps;

  @override
  set props(Map value) {
    assert(
        getBackingMap(value) is JsBackedMap,
        'Component2.props should never be set directly in '
        'production. If this is required for testing, the '
        'component should be rendered within the test. If '
        'that does not have the necessary result, the last '
        'resort is to use typedPropsFactoryJs.');
    super.props = value;
    _cachedTypedProps = typedPropsFactoryJs(getBackingMap(value));
  }

  @override
  _$$FlawedWithNoChildProps$JsMap typedPropsFactoryJs(JsBackedMap backingMap) =>
      new _$$FlawedWithNoChildProps$JsMap(backingMap);

  @override
  _$$FlawedWithNoChildProps typedPropsFactory(Map backingMap) =>
      new _$$FlawedWithNoChildProps(backingMap);

  /// Let [UiComponent] internals know that this class has been generated.
  @override
  bool get $isClassGenerated => true;

  /// The default consumed props, taken from _$FlawedWithNoChildProps.
  /// Used in [UiProps.consumedProps] if [consumedProps] is not overridden.
  @override
  final List<ConsumedProps> $defaultConsumedProps = const [
    _$metaForFlawedWithNoChildProps
  ];
}
