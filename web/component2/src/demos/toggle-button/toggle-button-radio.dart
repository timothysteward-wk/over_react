// ignore_for_file: file_names
import 'package:over_react/over_react.dart';

import '../../demo_components.dart';

ReactElement radioToggleButtonDemo() =>
  (ToggleButtonGroup()
    ..toggleType = ToggleBehaviorType.RADIO
  )(
    (ToggleButton()
      ..value = '1'
    )('Radio 1'),
    (ToggleButton()
      ..value = '2'
      ..defaultChecked = true
    )('Radio 2'),
    (ToggleButton()
      ..value = '3'
    )('Radio 3')
  );
