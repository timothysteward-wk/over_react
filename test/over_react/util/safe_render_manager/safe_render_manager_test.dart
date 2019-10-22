@TestOn('browser')
library top_level_render_manager_test;

import 'dart:async';
import 'dart:html';

import 'package:meta/meta.dart';
import 'package:react/react.dart' as react;
import 'package:over_react/over_react.dart';
import 'package:over_react/src/util/safe_render_manager/safe_render_manager.dart';
import 'package:over_react_test/over_react_test.dart';
import 'package:test/test.dart';

/// Main entry point for TopLevelRenderManager testing
main() {
  setClientConfiguration();
  enableTestMode();

  group('SafeRenderManager', () {
    Element mountNode;
    SafeRenderManager renderManager;

    setUp(() {
      mountNode = new DivElement();
      renderManager = new SafeRenderManager(mountNode);
    });

    tearDown(() async {
      await renderManager?.dispose();
      mountNode.remove();
    });

    group('render()', () {
      test('renders a component into the specified `mountNode`', () {
        renderManager.render(Dom.div()('foo'));
        expect(mountNode.text, 'foo');
      });

      test('rerenders a component into the specified `mountNode`', () {
        renderManager.render(Dom.div()('foo'));
        renderManager.render(Dom.div()('bar'));

        expect(mountNode.text, 'bar');
      });

      group('renders a component and exposes a ref to it via `contentRef`', () {
        test('when there is no existing ref', () {
          renderManager.render(Wrapper()());

          expect(renderManager.contentRef, isNotNull);
          expect(renderManager.contentRef, const isInstanceOf<WrapperComponent>());
        });

        test('by chaining any existing callback ref', () {
          WrapperComponent existingWrapperRef;

          renderManager.render((Wrapper()..ref = ((ref) => existingWrapperRef = ref))());

          expect(renderManager.contentRef, isNotNull);
          expect(existingWrapperRef, same(renderManager.contentRef));
        });

        test('by chaining any existing callback ref and the specified callbackRef argument', () {
          WrapperComponent existingWrapperRef;
          dynamic callbackRef;

          renderManager = new SafeRenderManager(mountNode, callbackRef: ((ref) => callbackRef = ref));
          renderManager.render((Wrapper()..ref = ((ref) => existingWrapperRef = ref))());

          expect(renderManager.contentRef, isNotNull);
          expect(existingWrapperRef, same(renderManager.contentRef));
          expect(callbackRef, same(renderManager.contentRef));
        });
      });
    });

    group('tryUnmountContent()', () {
      test('safely unmounts the rendered component and calls the provided callback when complete', () async {
        renderManager.render(Wrapper()());

        expect(mountNode.children, isNotEmpty);

        final onUnmountCompleter = new Completer();

        storeZone();
        renderManager.tryUnmountContent(onMaybeUnmounted: (isUnmounted) {
          zonedExpect(mountNode.children, isEmpty);
          zonedExpect(isUnmounted, isTrue);

          onUnmountCompleter.complete();
        });

        await onUnmountCompleter.future;
      });

      test('invokes the provided callback immediately when nothing has been rendered', () async {
        expect(mountNode.children, isEmpty, reason: 'test setup sanity check');

        bool onUnmountCalledSynchronously = false;

        storeZone();
        renderManager.tryUnmountContent(onMaybeUnmounted: (isUnmounted) {
          zonedExpect(isUnmounted, isTrue);
          onUnmountCalledSynchronously = true;
        });

        expect(onUnmountCalledSynchronously, isTrue);
      });
    });

    group('dispose', () {
      test('safely unmounts the rendered component and waits until unmounting is complete', () async {
        renderManager.render(Wrapper()());
        expect(mountNode.children, isNotEmpty);

        await renderManager.dispose();
        expect(mountNode.children, isEmpty);
      });
    });

    group('edge-cases', () {
      group('rerenders content when initial and rerender calls happen synchronously from a React', () {
        test('lifecycle method', () {
          final jacket = mount(Test({}));
          jacket.rerender(Test({
            'onComponentDidUpdate': expectAsyncBound(() {
              renderManager.render(Wrapper()('1'));
              renderManager.render(Wrapper()('2'));
              expect(mountNode.children, isEmpty, reason: 'should be rendering async due to React 16 behavior');
            }),
          }));

          expect(mountNode.text, '2', reason: 'should have rendered the content from the last render call');
        });

        test('event callback', () {
          final jacket = mount((Wrapper()
            ..onClick = expectAsyncBound1((_) {
              renderManager.render(Wrapper()('1'));
              renderManager.render(Wrapper()('2'));
              expect(mountNode.children, isEmpty, reason: 'should be rendering async due to React 16 behavior');
            })
          )(), attachedToDocument: true);

          // Use a real click since simulated clicks don't trigger this async behavior
          jacket.getNode().click();

          expect(mountNode.text, '2', reason: 'should have rendered the content from the last render call');
        });
      });

      group('unmounts content safely when unmount calls come from', () {
        bool onMaybeUnmountedCalled;

        setUp(() {
          onMaybeUnmountedCalled = false;
        });

        Future<Null> sharedTest({@required void Function() setUpAndReturnUnmounter(void callUnmount()),
          @required bool verifyImmediateUnmount,
          @required bool verifyDeferredUnmount,
          @required bool verifyAsyncUnmount,
        }) async {
          if (verifyImmediateUnmount && verifyDeferredUnmount) {
            throw new ArgumentError('verifyImmediateUnmount and verifyDeferredUnmount '
                'are mutually exclusive and cannot both be set to true');
          }

          void _callUnmount() {
            renderManager.tryUnmountContent(onMaybeUnmounted: expectAsyncBound1((isUnmounted) {
              onMaybeUnmountedCalled = true;
              expect(isUnmounted, isTrue, reason: 'should have unmounted');
            }));

            if (verifyDeferredUnmount) {
              expect(onMaybeUnmountedCalled, isFalse, reason: 'should not have unmounted yet');
              expect(mountNode.text, '1', reason: 'should not have unmounted yet');
            }
            if (verifyImmediateUnmount) {
              expect(onMaybeUnmountedCalled, isTrue, reason: 'should have unmounted by now');
              expect(mountNode.text, '', reason: 'should have unmounted by now');
            }
          }

          final triggerUnmount = setUpAndReturnUnmounter(expectAsyncBound(_callUnmount));

          await pumpEventQueue();
          // todo also add componentWillUnmount callback
          expect(onMaybeUnmountedCalled, isFalse,
              reason: 'test setup: content should still be mounted before callUnmount is called');
          expect(mountNode.text, '1',
              reason: 'test setup: content should still be mounted before callUnmount is called');

          triggerUnmount();

          if (verifyAsyncUnmount) {
            expect(onMaybeUnmountedCalled, isFalse,
                reason: 'should not have unmounted yet');
            expect(
                mountNode.text, '1', reason: 'should not have unmounted yet');
            await new Future(() {});
          }
          expect(onMaybeUnmountedCalled, isTrue,
              reason: 'should have unmounted by now');
          expect(mountNode.text, '', reason: 'should have unmounted by now');
        }

        group('the same React tree, from a', () {
          test('event handler', () async {
            await sharedTest(
              verifyImmediateUnmount: false,
              verifyDeferredUnmount: true,
              verifyAsyncUnmount: false,
              setUpAndReturnUnmounter: (callUnmount) {
                document.body.append(renderManager.mountNode);
                renderManager.render((Wrapper()
                  ..onClick = (_) {
                    callUnmount();
                  }
                )('1'));

                // Use a real click since simulated clicks don't trigger this async behavior
                return () => findDomNode(renderManager.contentRef).click();
              },
            );
          });

          test('callback of setState performed within event handler', () async {
            await sharedTest(
              verifyImmediateUnmount: false,
              verifyDeferredUnmount: true,
              verifyAsyncUnmount: false,
              setUpAndReturnUnmounter: (callUnmount) {
                document.body.append(renderManager.mountNode);
                renderManager.render((Wrapper()
                  ..onClick = (_) {
                    (renderManager.contentRef as react.Component).setState({}, callUnmount);
                  }
                )('1'));

                // Use a real click since simulated clicks don't trigger this async behavior
                return () => findDomNode(renderManager.contentRef).click();
              },
            );
          });

          test('lifecycle method (pre-commit phase)', () async {
            await sharedTest(
              verifyImmediateUnmount: false,
              verifyDeferredUnmount: true,
              verifyAsyncUnmount: false,
              setUpAndReturnUnmounter: (callUnmount) {
                renderManager.render(Test({
                  'onComponentWillUpdate': callUnmount,
                }, '1'));

                return () => (renderManager.contentRef as react.Component).redraw();
              },
            );
          });

          test('lifecycle method (post-commit phase)', () async {
            await sharedTest(
              verifyImmediateUnmount: false,
              verifyDeferredUnmount: true,
              verifyAsyncUnmount: false,
              setUpAndReturnUnmounter: (callUnmount) {
                renderManager.render(Test({
                  'onComponentDidUpdate': callUnmount,
                }, '1'));

                return () => (renderManager.contentRef as react.Component).redraw();
              },
            );
          });
        });

        group('another React tree, from a', () {
          setUp(() {
            renderManager.render(Wrapper()('1'));
            expect(mountNode.text, '1', reason: 'test setup check');
          });

          test('event handler', () async {
            await sharedTest(
              verifyImmediateUnmount: false,
              verifyDeferredUnmount: true,
              verifyAsyncUnmount: false,
              setUpAndReturnUnmounter: (callUnmount) {
                final jacket = mount((Wrapper()
                  ..onClick = (_) {
                    callUnmount();
                  }
                )(), attachedToDocument: true);

                // Use a real click since simulated clicks don't trigger this async behavior
                return () => jacket.getNode().click();
              },
            );
          });

          test('callback of setState performed within event handler', () async {
            await sharedTest(
              verifyImmediateUnmount: false,
              verifyDeferredUnmount: true,
              verifyAsyncUnmount: false,
              setUpAndReturnUnmounter: (callUnmount) {
                TestJacket jacket;
                jacket = mount((Wrapper()
                  ..onClick = (_) {
                    jacket.getDartInstance().setState({}, callUnmount);
                  }
                )(), attachedToDocument: true);

                // Use a real click since simulated clicks don't trigger this async behavior
                return () => jacket.getNode().click();
              },
            );
          });

          test('lifecycle method (pre-commit phase)', () async {
            await sharedTest(
              verifyImmediateUnmount: false,
              verifyDeferredUnmount: true,
              verifyAsyncUnmount: false,
              setUpAndReturnUnmounter: (callUnmount) {
                final jacket = mount(Test({
                  'onComponentWillUpdate': callUnmount,
                }));

                return () => jacket.getDartInstance().redraw();
              },
            );
          });

          test('lifecycle method (post-commit phase)', () async {
            await sharedTest(
              verifyImmediateUnmount: false,
              verifyDeferredUnmount: true,
              verifyAsyncUnmount: false,
              setUpAndReturnUnmounter: (callUnmount) {
                final jacket = mount(Test({
                  'onComponentDidUpdate': callUnmount,
                }));

                return () => jacket.getDartInstance().redraw();
              },
            );
          });
        });
      });
    });
  });
}
ZoneCallback<R> expectAsyncBound<R>(ZoneCallback<R> callback,
    {int count = 1, int max = 0, String id, String reason}) =>
    Zone.current.bindCallback(expectAsync0(
      callback,
      count: count,
      max: max,
      id: id,
      reason: reason,
    ));

ZoneUnaryCallback<R, T> expectAsyncBound1<R, T>(ZoneUnaryCallback<R, T> callback,
    {int count = 1, int max = 0, String id, String reason}) =>
    Zone.current.bindUnaryCallback(expectAsync1(
      callback,
      count: count,
      max: max,
      id: id,
      reason: reason,
    ));

final Test = registerComponent(() => new TestComponent());
class TestComponent extends react.Component {
  @override
  componentDidMount() {
    props['onComponentDidMount']?.call();
  }

  @override
  componentDidUpdate(prevProps, prevState) {
    props['onComponentDidUpdate']?.call();
  }
  @override
  componentWillUpdate(nextProps, nextState) {
    nextProps['onComponentWillUpdate']?.call();
  }
  @override
  componentWillReceiveProps(nextProps) {
    nextProps['onComponentWillReceiveProps']?.call();
  }
  @override
  componentWillUnmount() {
    nextProps['onComponentWillUnmount']?.call();
  }

  @override
  render() {
    return (Dom.div()..addProps(props))(props['children']);
  }
}
