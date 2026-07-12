import 'package:flutter/material.dart';
import '../models/delivery_request_model.dart';
import '../views/delivery/new_delivery_request_screen.dart';
import 'notification_service.dart';

/// Point d'entrée unique pour toute nouvelle demande de course.
///
/// AUJOURD'HUI : appelé par la simulation locale (bouton de test).
/// DEMAIN (Firebase) : appeler `onNewRequest(...)` depuis le handler FCM.
/// Aucun autre fichier ne changera.
class DeliveryRequestManager {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static void init() {
    NotificationService.onRequestTapped = _openRequestScreen;
  }

  static Future<void> onNewRequest(DeliveryRequestModel request) async {
    await NotificationService.showDeliveryRequest(request);
    _openRequestScreen(request);
  }

  static void _openRequestScreen(DeliveryRequestModel request) {
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    nav.push(MaterialPageRoute(
      builder: (_) => NewDeliveryRequestScreen(request: request),
    ));
  }
}