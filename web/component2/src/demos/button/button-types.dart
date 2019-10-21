// ignore_for_file: file_names
import 'package:over_react/over_react.dart';

import '../../demo_components.dart';

ReactElement buttonTypesDemo() =>
  (Dom.div()..className = 'btn-toolbar')(
    Button()('Button'),
    (Button()..href = '#')('Link'),
    (Button()..type = ButtonType.SUBMIT)('Submit'),
    (Button()..type = ButtonType.RESET)('Reset')
  );
