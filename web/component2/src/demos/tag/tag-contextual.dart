// ignore_for_file: file_names
import 'package:over_react/over_react.dart';

import '../../demo_components.dart';

ReactElement tagContextualDemo() => Dom.div()(
  (Tag()..skin = TagSkin.DEFAULT)('Default'),
  (Tag()..skin = TagSkin.PRIMARY)('Primary'),
  (Tag()..skin = TagSkin.SUCCESS)('Success'),
  (Tag()..skin = TagSkin.INFO)('Info'),
  (Tag()..skin = TagSkin.WARNING)('Warning'),
  (Tag()..skin = TagSkin.DANGER)('Danger')
);
