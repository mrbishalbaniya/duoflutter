/// Architecture notes: Duo Mobile notification system
///
/// Layers
/// - [NotificationService] — FCM listeners, local display, badge, update alerts
/// - [NotificationRouter] — type → deep link navigation (no wrong pages)
/// - [NotificationReplyHandler] — inline reply via chat REST API
/// - [LocalNotificationService] — channels, actions, RemoteInput, iOS categories
/// - [PushPayloadParser] — FCM data → typed payload
/// - [NotificationTapPayload] — JSON payload for tap/reply context
///
/// App states
/// - Foreground: FCM onMessage → local notification → tap → router
/// - Background: FCM background handler → local notification
/// - Terminated: getInitialMessage / getLaunchDetails / pending Hive payload
///
/// Extending
/// 1. Add enum value in DuoNotificationType
/// 2. Map default path in NotificationRouter.resolveDefaultDeepLink
/// 3. Optionally add a channel/action in LocalNotificationService
library;
