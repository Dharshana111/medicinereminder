import 'package:flutter/material.dart';

/// FSM (Finite State Machine) Controller for app navigation and state management.
///
/// Implements an improved FSM pattern where each screen represents a state,
/// and transitions are guarded by conditions (e.g., registration status).
enum AppState {
  splash,
  registration,
  dashboard,
  addMedicine,
  editMedicine,
  history,
  profile,
  notification,
}

/// Events that trigger state transitions
enum AppEvent {
  appStarted,
  splashCompleted,
  registrationCompleted,
  navigateToDashboard,
  navigateToAddMedicine,
  navigateToEditMedicine,
  navigateToHistory,
  navigateToProfile,
  notificationTriggered,
  notificationAcknowledged,
  back,
}

class FSMController extends ChangeNotifier {
  AppState _currentState = AppState.splash;
  final List<AppState> _stateHistory = [];

  AppState get currentState => _currentState;
  List<AppState> get stateHistory => List.unmodifiable(_stateHistory);

  /// Transition to a new state based on an event
  void handleEvent(AppEvent event, {bool isRegistered = false}) {
    final previousState = _currentState;
    AppState? nextState;

    switch (event) {
      case AppEvent.appStarted:
        nextState = AppState.splash;
        break;
      case AppEvent.splashCompleted:
        nextState = isRegistered ? AppState.dashboard : AppState.registration;
        break;
      case AppEvent.registrationCompleted:
        nextState = AppState.dashboard;
        break;
      case AppEvent.navigateToDashboard:
        nextState = AppState.dashboard;
        break;
      case AppEvent.navigateToAddMedicine:
        nextState = AppState.addMedicine;
        break;
      case AppEvent.navigateToEditMedicine:
        nextState = AppState.editMedicine;
        break;
      case AppEvent.navigateToHistory:
        nextState = AppState.history;
        break;
      case AppEvent.navigateToProfile:
        nextState = AppState.profile;
        break;
      case AppEvent.notificationTriggered:
        nextState = AppState.notification;
        break;
      case AppEvent.notificationAcknowledged:
        nextState = AppState.dashboard;
        break;
      case AppEvent.back:
        if (_stateHistory.isNotEmpty) {
          nextState = _stateHistory.removeLast();
        }
        break;
    }

    if (nextState != null && nextState != _currentState) {
      if (event != AppEvent.back) {
        _stateHistory.add(previousState);
      }
      _currentState = nextState;
      notifyListeners();
    }
  }

  /// Check if transition is valid from current state
  bool canTransition(AppEvent event) {
    switch (_currentState) {
      case AppState.splash:
        return event == AppEvent.splashCompleted;
      case AppState.registration:
        return event == AppEvent.registrationCompleted;
      case AppState.dashboard:
        return [
          AppEvent.navigateToAddMedicine,
          AppEvent.navigateToHistory,
          AppEvent.navigateToProfile,
          AppEvent.notificationTriggered,
        ].contains(event);
      case AppState.addMedicine:
      case AppState.editMedicine:
        return event == AppEvent.back || event == AppEvent.navigateToDashboard;
      case AppState.history:
      case AppState.profile:
        return event == AppEvent.back || event == AppEvent.navigateToDashboard;
      case AppState.notification:
        return event == AppEvent.notificationAcknowledged;
    }
  }

  void reset() {
    _currentState = AppState.splash;
    _stateHistory.clear();
    notifyListeners();
  }
}
