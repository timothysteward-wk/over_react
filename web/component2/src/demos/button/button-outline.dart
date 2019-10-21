// ignore_for_file: file_names
import 'package:over_react/over_react.dart';

import '../../demo_components.dart';

ReactElement buttonOutlineDemo() =>
  (Dom.div()..className = 'btn-toolbar')(
    (Button()..skin = ButtonSkin.PRIMARY_OUTLINE)('Primary'),
    (Button()..skin = ButtonSkin.SECONDARY_OUTLINE)('Secondary'),
    (Button()..skin = ButtonSkin.SUCCESS_OUTLINE)('Success'),
    (Button()..skin = ButtonSkin.INFO_OUTLINE)('Info'),
    (Button()..skin = ButtonSkin.WARNING_OUTLINE)('Warning'),
    (Button()..skin = ButtonSkin.DANGER_OUTLINE)('Danger')
  );
