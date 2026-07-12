import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/map_domain.dart';
import '../map_models.dart';

class MapScreenController extends StateNotifier<MapScreenState> {
  MapScreenController() : super(const MapScreenState());

  void setFocus(String? profileId) {
    state = profileId == null
        ? state.copyWith(clearFocus: true)
        : state.copyWith(focusProfileId: profileId);
  }

  void selectZone(ActivityZone? zone) {
    state = zone == null
        ? state.copyWith(clearSelectedZone: true)
        : state.copyWith(selectedZone: zone);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setFriendsSearchQuery(String query) {
    state = state.copyWith(friendsSearchQuery: query);
  }

  void setMapReady(bool ready) {
    state = state.copyWith(isMapReady: ready);
  }

  void toggleFollowMe() {
    state = state.copyWith(followMe: !state.followMe);
  }

  void toggleFullscreen() {
    state = state.copyWith(isFullscreen: !state.isFullscreen);
  }

  void flyTo(GeocodeSuggestion suggestion) {
    state = state.copyWith(
      searchQuery: suggestion.label,
      flyToTarget: suggestion.coordinates,
    );
  }

  void clearFlyTo() {
    state = state.copyWith(clearFlyTo: true);
  }
}
