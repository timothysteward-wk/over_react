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

import 'package:args/command_runner.dart';
import 'package:dart_dev/commands/sequence_command.dart';
import 'package:dart_dev/commands/test_command.dart';
import 'package:dart_dev/configs/workiva.dart' as workiva_ddev_config;

Iterable<Command<int>> get config => [
  ...workiva_ddev_config.build(
    testConfig: TestConfig(
      commandName: 'test_vm',
      description: 'Run VM tests.',
      testArgs: ['-P', 'vm'],
    ),
  ),

  TestCommand(
    TestConfig(
      commandName: 'test_ddc',
      description: 'Run browser tests via DDC.',
      testArgs: ['-P', 'dartdevc'],
    ),
  ),

  TestCommand(
    TestConfig(
      commandName: 'test_dart2js',
      description: 'Run browser tests via dart2js.',
      buildRunnerArgs: ['-r'],
      testArgs: ['-P', 'dart2js']
    ),
  ),

  SequenceCommand(
    SequenceConfig(
      commandName: 'test',
      description: 'Run all tests in this package.',
      primaryCommands: [
        ['test_vm'],
        ['test_ddc'],
        ['test_dart2js'],
      ],
    ),
  ),
];

// library tool.dev;

// import 'package:dart_dev/dart_dev.dart' show dev, config;

// main(List<String> args) async {
//   const directories = const <String>[
//     'lib/',
//     'test/',
//     'tool/',
//   ];

//   config.analyze.entryPoints = directories;
//   config.copyLicense.directories = ['integrate']..addAll(directories);

//   config.test
//     ..platforms = [
//       'vm',
//       'chrome',
//     ]
//     ..unitTests = [
//       'test/vm_tests/',
//       'test/over_react_component_declaration_test.dart',
//       'test/over_react_component_test.dart',
//       'test/over_react_dom_test.dart',
//       'test/over_react_util_test.dart',
//     ];

//   await dev(args);
// }
