// ignore_for_file: file_names
import 'package:over_react/over_react.dart';

import '../../demo_components.dart';

ReactElement tagBasicDemo() => Fragment()(
  Dom.h1()('Example heading ', Tag()('New')),
  Dom.h2()('Example heading ', Tag()('New')),
  Dom.h3()('Example heading ', Tag()('New')),
  Dom.h4()('Example heading ', Tag()('New')),
  Dom.h5()('Example heading ', Tag()('New')),
  Dom.h6()('Example heading ', Tag()('New'))
);
