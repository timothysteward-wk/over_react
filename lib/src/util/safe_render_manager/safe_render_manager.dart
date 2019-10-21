import 'dart:async';
import 'dart:html';

import 'package:meta/meta.dart';
import 'package:over_react/over_react.dart';
import 'package:react/react_dom.dart' as react_dom;
import 'package:w_common/disposable.dart';

import './safe_render_manager_helper.dart';

/// A class that manages the top-level rendering of a [ReactElement] into a given node,
/// with support for safely rendering/updating via [render] and safely unmounting via [tryUnmountContent].
///
/// This is useful in cases where [react_dom.render] or [react_dom.unmountComponentAtNode]
/// may or may not be called from React events or lifecycle methods, which can have
/// undesirable/unintended side effects.
///
/// For instance, calling [react_dom.unmountComponentAtNode] can unmount a component
/// while an event is being propagated through a component, which normally would never happen.
/// This could result in null errors in the component as the event logic continues.
///
/// SafeRenderManager uses a helper  component under the hood to manage the rendering of content
/// via Component state changes, ensuring that the content is mounted/unmounted as it
/// normally would be.
class SafeRenderManager extends Disposable {
  SafeRenderManagerHelperComponent _helper;

  /// The mount node for content rendered by [render].
  final Element mountNode;

  /// A callback ref to be chained for the component rendered by [render].
  final CallbackRef _callbackRef;

  /// The ref to the component rendered by [render].
  ///
  /// Due to react_dom.render calls not being guaranteed to be synchronous.
  /// this may not be populated until later than expected.
  dynamic contentRef;

  _RenderState _state = _RenderState.unmounted;

  List<ReactElement> _renderQueue = [];

  SafeRenderManager(this.mountNode, {CallbackRef callbackRef}) : _callbackRef = callbackRef;

  /// Renders [content]into [mountNode], chaining existing callback refs to
  /// provide access to the rendered component via [contentRef].
  void render(ReactElement content) {
    _checkDisposalState();

    switch (_state) {
      case _RenderState.mounting:
        _renderQueue.add(content);
        break;
      case _RenderState.mounted:
        _helper.renderContent(content);
        break;
      case _RenderState.unmounted:
        try {
          _state = _RenderState.mounting;
          react_dom.render((SafeRenderManagerHelper()
            ..ref = _helperRef
            ..getInitialContent = () {
              final value = content;
              // Clear this closure variable out so it isn't retained.
              content = null;
              return value;
            }
            ..contentRef = _contentCallbackRef
          )(), mountNode);
        } catch (_) {
          _state == _RenderState.unmounted;
          rethrow;
        }
        break;
    }
  }

  /// Attempts to unmount the rendered component, calling [onMaybeUnmounted]
  /// with whether the component was actually unmounted.
  ///
  /// Unmounting could fail if a call to [render] is batched in with this
  /// unmount during the propagation of this event. In that case, something
  /// other call wanted something rendered and trumped the unmount request.
  ///
  /// This behavior allows the same SafeRenderManager instance to be used to
  /// render/unmount a single content area without calls interfering with each
  /// other.
  ///
  /// If nothing is currently rendered, [onMaybeUnmounted] will be called immediately.
  void tryUnmountContent({void onMaybeUnmounted(bool isUnmounted)}) {
    // Check here since we call _tryUnmountContent in this class's disposal logic.
    _checkDisposalState();
    _tryUnmountContent(onMaybeUnmounted: onMaybeUnmounted, force: false);
  }

  void _tryUnmountContent({void onMaybeUnmounted(bool isUnmounted), @required bool force}) {
    void _unmountContent() {
      _state == _RenderState.unmounted;
      _renderQueue = [];
      react_dom.unmountComponentAtNode(mountNode);
      onMaybeUnmounted?.call(true);
    }

    switch (_state) {
      case _RenderState.mounting:
        _unmountContent();
        break;
      case _RenderState.mounted:
        _helper.tryUnmountContent(onMaybeUnmounted: (isUnmounted) {
          if (isUnmounted || force) {
            _unmountContent();
          } else {
            onMaybeUnmounted?.call(false);
          }
        });
        break;
      case _RenderState.unmounted:
        onMaybeUnmounted?.call(true);
        break;
    }
  }

  void _checkDisposalState() {
    if (isOrWillBeDisposed) {
      throw new ObjectDisposedException();
    }
  }

  void _helperRef(ref) {
    _helper = ref;
    if (_helper != null) {
      if (_state == _RenderState.mounting) {
        _state = _RenderState.mounted;
      }
      _state = _RenderState.mounted;
      _renderQueue.forEach(_helper.renderContent);
      _renderQueue = [];
    }
  }

  void _contentCallbackRef(ref) {
    contentRef = ref;
    _callbackRef?.call(ref);
  }

  @override
  Future<Null> onDispose() async {
    var completer = new Completer<Null>();
    final completerFuture = completer.future;

    runZoned(() {
      // Attempt to unmount the content safely
      _tryUnmountContent(force: true, onMaybeUnmounted: (_) {
        completer?.complete();
        // Clear out to not retain it in the onError closure, which has
        // an indefinitely long lifetime.
        completer = null;
      });
    }, onError: (error, stackTrace) {
      completer?.completeError(error, stackTrace);
      // Clear out to not retain it in the onError closure, which has
      // an indefinitely long lifetime.
      completer = null;
    });

    await completerFuture;

    await super.onDispose();
  }
}

enum _RenderState {
  mounting, mounted, unmounted
}
