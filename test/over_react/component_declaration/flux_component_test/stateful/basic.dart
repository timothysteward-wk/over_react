// ignore_for_file: deprecated_member_use_from_same_package
part of over_react.component_declaration.flux_component_test;

@Factory()
UiFactory<TestStatefulBasicProps> TestStatefulBasic = _$TestStatefulBasic;

@Props()
class _$TestStatefulBasicProps extends FluxUiProps implements TestBasicProps {}

@State()
class _$TestStatefulBasicState extends UiState {}

@Component()
class TestStatefulBasicComponent extends FluxUiStatefulComponent<TestStatefulBasicProps, TestStatefulBasicState> {
  int numberOfRedraws = 0;

  @override
  render() => Dom.div()();

  @override
  void setState(_, [Function() callback]) {
    numberOfRedraws++;
    if (callback != null) callback();
  }
}

