// ignore_for_file: file_names
import 'package:over_react/over_react.dart';

import '../../demo_components.dart';

ReactElement buttonBlockDemo() => Dom.div()(
  (Button()
    ..isBlock = true
  )('Block level button'),
  (Button()
    ..isBlock = true
    ..skin = ButtonSkin.SECONDARY
  )('Block level button')
);
