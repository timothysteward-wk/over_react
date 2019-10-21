// ignore_for_file: file_names
import 'package:over_react/over_react.dart';

import '../../demo_components.dart';

ReactElement listGroupHeaderDemo() =>
  ListGroup()(
    (ListGroupItem()
      ..header = 'List group item heading'
      ..onClick = (_) {}
      ..isActive = true
    )(
      'Donec id elit non mi porta gravida at eget metus. '
      'Maecenas sed diam eget risus varius blandit.'
    ),
    (ListGroupItem()
      ..header = 'List group item heading'
      ..headerSize = ListGroupItemHeaderElementSize.H4
      ..onClick = (_) {}
    )(
      'Donec id elit non mi porta gravida at eget metus. '
      'Maecenas sed diam eget risus varius blandit.'
    ),
    (ListGroupItem()
      ..header = 'List group item heading'
      ..headerSize = ListGroupItemHeaderElementSize.H3
      ..onClick = (_) {}
    )(
      'Donec id elit non mi porta gravida at eget metus. '
      'Maecenas sed diam eget risus varius blandit.'
    )
  );
