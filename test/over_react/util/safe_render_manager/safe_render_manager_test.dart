@TestOn('browser')
library top_level_render_manager_test;

import 'dart:async';
import 'dart:html';

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
  });
}
