import 'package:over_react/over_react.dart';

part 'dom_prop_types.over_react.g.dart';

main() {
  final content = Fragment()(
    (Dom.a()
      // This should have a lint.
      ..size = 1
      // These should have no lint
      ..href = null
      ..hrefLang = null
      ..download = null
      ..rel = null
      ..target = null
    )(),
    (Dom.abbr()
      // This should have a lint.
      ..size = 1
      // These should have no lint
      ..title = 'foo'
    )(),
    (Dom.address()
      // This should have a lint.
      ..size = 1
      // These should have no lint
      ..title = 'foo'
    )(),
    (Dom.area()
      // This should have a lint.
      ..size = 1
      // These should have no lint
      ..coords = 1
      ..download = null
      ..href = null
      ..hrefLang = null
      ..rel = null
      ..shape = null
      ..target = null
    )(),
    (Dom.article()
      // This should have a lint.
      ..size = 1
      // These should have no lint
      ..title = 'foo'
    )(),
    (Dom.aside()
      // This should have a lint.
      ..size = 1
      // These should have no lint
      ..title = 'foo'
    )(),
    (Dom.audio()
      // This should have a lint.
      ..size = 1
      // These should have no lint
      ..autoPlay = true
      ..controls = true
      ..muted = true
    )(),
  );
}
