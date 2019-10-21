// ignore_for_file: deprecated_member_use_from_same_package
part of '../annotation_error_integration_test.dart';

@Factory()
UiFactory<AnnotationErrorStatefulProps> AnnotationErrorStateful =
    _$AnnotationErrorStateful;

@Props()
class _$AnnotationErrorStatefulProps extends UiProps {}

@State()
class _$AnnotationErrorStatefulState extends UiState {}

@Component()
class AnnotationErrorStatefulComponent extends UiStatefulComponent2<
    AnnotationErrorStatefulProps, AnnotationErrorStatefulState> {
  @override
  render() => props.children;
}
