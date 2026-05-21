import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/weather_alert_model.dart';
import '../services/weather_service.dart';

class AlertState {
  final List<WeatherAlertModel> alerts;
  final bool isLoading;
  final String? errorMessage;

  const AlertState({
    this.alerts = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  factory AlertState.initial() => const AlertState();
  factory AlertState.loading() => const AlertState(isLoading: true);
  factory AlertState.success(List<WeatherAlertModel> alerts) => AlertState(alerts: alerts);
  factory AlertState.error(String message) => AlertState(errorMessage: message);

  bool get hasAlerts => alerts.isNotEmpty;
  bool get hasError => errorMessage != null;
}

class AlertNotifier extends Notifier<AlertState> {
  late final WeatherService _weatherService;

  @override
  AlertState build() {
    _weatherService = WeatherService();
    return AlertState.initial();
  }

  Future<void> checkAlertsForLocation(double lat, double lon) async {
    state = AlertState.loading();
    try {
      final alerts = await _weatherService.getWeatherAlerts(lat, lon);
      state = AlertState.success(alerts);
    } catch (_) {
      // Alerts are supplementary — fail silently, don't interrupt the main flow.
      state = AlertState.success([]);
    }
  }

  void clearAlerts() => state = AlertState.initial();
}

final alertProvider = NotifierProvider<AlertNotifier, AlertState>(AlertNotifier.new);
