// ignore_for_file: file_names
import 'package:over_react/over_react.dart';

import '../../demo_components.dart';

ReactElement listGroupAnchorsAndButtonsDemo() =>
  ListGroup()(
    (ListGroupItem()
      ..isActive = true
      ..href = '#'
    )('Cras justo odio'),
    (ListGroupItem()
      ..onClick = (_) {}
    )('Dapibus ac facilisis in'),
    (ListGroupItem()
      ..onClick = (_) {}
    )('Morbi leo risus'),
    (ListGroupItem()
      ..onClick = (_) {}
    )('Porta ac consectetur ac'),
    (ListGroupItem()
      ..isDisabled = true
      ..onClick = (_) {}
    )('Vestibulum at eros')
  );
