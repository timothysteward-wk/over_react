@TestOn('browser')
@JS()
library react_material_ui.test.js_component_test;

import 'dart:html';

import 'package:js/js.dart';
import 'package:over_react/over_react.dart';
import 'package:over_react/src/util/js_component.dart';
import 'package:react_testing_library/matchers.dart';
import 'package:react_testing_library/react_testing_library.dart' as rtl;
import 'package:react/react_client.dart';
import 'package:react/react_client/react_interop.dart';
import 'package:test/test.dart';

part 'js_component_test.over_react.g.dart';

main() {
  enableTestMode();

  group('uiJsComponent', () {
    group('with generated props config', () {
      jsComponentTestHelper(Test);
    });

    group('with custom PropsFactory', () {
      jsComponentTestHelper(TestCustom);
    });

    group('with no left hand typing', () {
      jsComponentTestHelper(NoLHSTest);
    });

    group('with private prefix', () {
      jsComponentTestHelper(_Test);
    });

    group('throws an error when', () {
      test('config is null', () {
        expect(
            () => uiJsComponent<TestProps>(
                  ReactJsComponentFactoryProxy(_TestJsComponent),
                  null,
                ),
            throwsArgumentError);
      });

      test('props factory is not provided when using custom props class', () {
        expect(
            () => uiJsComponent<TestProps>(
                  ReactJsComponentFactoryProxy(_TestJsComponent),
                  UiFactoryConfig(displayName: 'Foo'),
                ),
            throwsArgumentError);
      });

      test('config not the correct type', () {
        expect(
            () => uiJsComponent<TestProps>(
                  ReactJsComponentFactoryProxy(_TestJsComponent),
                  'foo',
                ),
            throwsArgumentError);
      });
    });
  });
}

void jsComponentTestHelper(UiFactory<TestProps> factory) {
  test(
      'renders a component from end to end, successfully reading props via typed getters',
      () {
    var view = rtl.render(
      (factory()..addTestId('testId'))(),
    );
    var node = view.getByTestId('testId');

    // Sanity check for values with no props set.
    expect(node, isA<SpanElement>());
    expect(node, hasTextContent(''));

    view.rerender(
      (factory()
        ..addTestId('testId')
        ..component = 'div')('rendered content'),
    );
    node = view.getByTestId('testId');

    // Verify the expected outcome of each prop.
    expect(node, isA<DivElement>());
    expect(node, hasTextContent('rendered content'));
  });

  group('initializes the factory variable with a function', () {
    test('that returns a new props class implementation instance', () {
      final instance = factory();
      expect(instance, isA<TestProps>());
      expect(instance, isA<Map>());
    });

    test(
        'that returns a new props class implementation instance backed by an existing map',
        () {
      Map existingMap = {'stringProp': 'test'};
      final props = factory(existingMap);

      expect(props.stringProp, equals('test'));

      props.stringProp = 'modified';
      expect(props.stringProp, equals('modified'));
      expect(existingMap['stringProp'], equals('modified'));
    });
  });

  test('generates prop getters/setters with no namespace', () {
    expect(factory()..stringProp = 'test', containsPair('stringProp', 'test'));

    expect(factory()..dynamicProp = 2, containsPair('dynamicProp', 2));

    expect(factory()..untypedProp = false, containsPair('untypedProp', false));
  });

  group('can pass along unconsumed props', () {
    const stringProp = 'a string';
    const anotherProp = 'this should be filtered';
    const className = 'aClassName';

    group('using `addUnconsumedProps`', () {
      TestProps initialProps;
      TestProps secondProps;

      setUp(() {
        initialProps = (factory()
          ..stringProp = stringProp
          ..anotherProp = anotherProp);

        secondProps = factory();

        expect(secondProps.stringProp, isNull,
            reason: 'Test setup sanity check');
        expect(secondProps.anotherProp, isNull,
            reason: 'Test setup sanity check');
      });

      test('', () {
        secondProps.addUnconsumedProps(initialProps, []);
        expect(secondProps.anotherProp, anotherProp);
        expect(secondProps.stringProp, stringProp);
      });

      test('and consumed props are correctly filtered', () {
        final consumedProps =
            initialProps.staticMeta.forMixins({TestPropsMixin});
        secondProps.addUnconsumedProps(initialProps, consumedProps);
        expect(secondProps.stringProp, isNull);
        expect(secondProps.anotherProp, anotherProp);
      });
    });

    group('using `addUnconsumedDomProps`', () {
      TestProps initialProps;
      TestProps secondProps;

      setUp(() {
        initialProps = (factory()
          ..stringProp = stringProp
          ..anotherProp = anotherProp
          ..className = className);

        secondProps = factory();

        expect(secondProps.className, isNull,
            reason: 'Test setup sanity check');
      });

      test('', () {
        secondProps.addUnconsumedDomProps(initialProps, []);
        expect(secondProps.stringProp, isNull);
        expect(secondProps.anotherProp, isNull);
        expect(secondProps.className, className);
      });

      test('and consumed props are correctly filtered', () {
        expect(initialProps.className, isNotNull,
            reason: 'Test setup sanity check');
        secondProps.addUnconsumedDomProps(
            initialProps, [PropsMeta.forSimpleKey('className')]);
        expect(secondProps.stringProp, isNull);
        expect(secondProps.anotherProp, isNull);
        expect(secondProps.className, isNull);
      });
    });
  });
}

@JS('TestJsComponent')
external ReactClass get _TestJsComponent;

UiFactory<TestProps> Test = uiJsComponent(
  ReactJsComponentFactoryProxy(_TestJsComponent),
  _$TestConfig, // ignore: undefined_identifier
);

UiFactory<TestProps> TestCustom = uiJsComponent(
  ReactJsComponentFactoryProxy(_TestJsComponent),
  UiFactoryConfig(
    propsFactory: PropsFactory.fromUiFactory(Test),
  ),
);

final NoLHSTest = uiJsComponent<TestProps>(
  ReactJsComponentFactoryProxy(_TestJsComponent),
  _$NoLHSTestConfig, // ignore: undefined_identifier
);

final _Test = uiJsComponent<TestProps>(
  ReactJsComponentFactoryProxy(_TestJsComponent),
  _$_TestConfig, // ignore: undefined_identifier
);

@Props(keyNamespace: '')
mixin TestPropsMixin on UiProps {
  String size;
  dynamic component;

  String stringProp;
  dynamic dynamicProp;
  var untypedProp; // ignore: prefer_typing_uninitialized_variables
}

@Props(keyNamespace: '')
mixin ASecondPropsMixin on UiProps {
  bool disabled;
  String anotherProp;
}

class TestProps = UiProps with TestPropsMixin, ASecondPropsMixin;
