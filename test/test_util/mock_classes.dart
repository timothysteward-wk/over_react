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
library mock_classes;

import 'dart:async';
import 'dart:html';

import 'package:mockito/mockito.dart';
import 'package:react/react.dart' as react;

class MockTimer extends Mock implements Timer {
  bool _isInstantiated = false;
  void Function() _callback;
  Duration _duration;

  /// Whether the timer has been initialized via [getTimerFactory].
  bool get isInstantiated => _isInstantiated;

  /// The callback the timer was initialized with.
  void Function() get callback => _callback;

  /// The duration the timer was initialized with.
  Duration get duration => _duration;

  /// Returns a function that initializes [mock] with the given duration and callback.
  ///
  /// This function will raise an [AssertionError] if called more than once.
  static Function getTimerFactory(MockTimer mock) {
    Timer timerFactory(Duration duration, void Function() callback) {
      assert(!mock._isInstantiated);

      mock._isInstantiated = true;
      mock._callback = callback;
      mock._duration = duration;

      return mock;
    }

    return timerFactory;
  }
}

// ignore: avoid_implementing_value_types
class MockFileList extends Mock implements FileList {}

// ignore: avoid_implementing_value_types
class MockFile extends Mock implements File {}

class MockFileUploadInputElement extends Mock implements FileUploadInputElement {}

class MockSyntheticEvent extends Mock implements react.SyntheticEvent {}

class MockSyntheticMouseEvent extends Mock implements react.SyntheticMouseEvent {}

// ignore: avoid_implementing_value_types
class MockMouseEvent extends Mock implements MouseEvent {}
