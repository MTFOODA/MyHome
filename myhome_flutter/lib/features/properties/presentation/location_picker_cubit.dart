import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/location_repository.dart';

class LocationPickerState {
  final PropertyLocation? selected;
  final bool busy;
  final String? error;
  const LocationPickerState({this.selected, this.busy = false, this.error});
}

class LocationPickerCubit extends Cubit<LocationPickerState> {
  final LocationRepository repository;
  LocationPickerCubit(this.repository, {PropertyLocation? initial})
    : super(LocationPickerState(selected: initial));
  void choose(PropertyLocation point) {
    emit(
      point.valid
          ? LocationPickerState(selected: point)
          : LocationPickerState(
              selected: state.selected,
              error: 'locationOutside',
            ),
    );
  }

  Future<void> locate() async {
    if (state.busy) return;
    emit(LocationPickerState(selected: state.selected, busy: true));
    try {
      final point = await repository.currentLocation();
      if (!isClosed) choose(point);
    } catch (error) {
      if (!isClosed) {
        emit(
          LocationPickerState(
            selected: state.selected,
            error: error is LocationFailure ? error.code : 'locationFailed',
          ),
        );
      }
    }
  }
}
