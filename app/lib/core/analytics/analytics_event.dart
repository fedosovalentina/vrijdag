/// Typed product analytics events. Features must use [Analytics] — never PostHog directly.
///
/// Never include event titles, notes, locations, or email bodies in properties.
sealed class AnalyticsEvent {
  const AnalyticsEvent();
}

/// F-001 smoke event — proves the analytics pipeline works (AC-5).
class AppStarted extends AnalyticsEvent {
  const AppStarted({required this.environment, required this.version});

  final String environment;
  final String version;
}

class AuthMagicLinkSent extends AnalyticsEvent {
  const AuthMagicLinkSent();
}

class AuthSignInSucceeded extends AnalyticsEvent {
  const AuthSignInSucceeded({required this.method});

  /// `magic_link` | `apple`
  final String method;
}

class AuthSignOutSucceeded extends AnalyticsEvent {
  const AuthSignOutSucceeded();
}

class AuthAccountDeleted extends AnalyticsEvent {
  const AuthAccountDeleted();
}

class EventCreated extends AnalyticsEvent {
  const EventCreated({
    required this.source,
    required this.isAllDay,
    required this.hasLocation,
  });

  final String source;
  final bool isAllDay;
  final bool hasLocation;
}

class EventEdited extends AnalyticsEvent {
  const EventEdited({required this.source});

  final String source;
}

class EventDeleted extends AnalyticsEvent {
  const EventDeleted({required this.source});

  final String source;
}

class EventDeleteUndone extends AnalyticsEvent {
  const EventDeleteUndone();
}

class BirthdayCreated extends AnalyticsEvent {
  const BirthdayCreated();
}

class BirthdayDeleted extends AnalyticsEvent {
  const BirthdayDeleted();
}

/// Day home opened (F-007). Counts only — never titles.
/// Feed jumped to a day (F-014). [bucket] is `YYYY-MM`, never a title.
/// A label was saved. [countBucket] is how many labels exist, never a name.
class DayFocusOpened extends AnalyticsEvent {
  const DayFocusOpened({required this.eventCountBucket});

  /// `0` | `1-2` | `3-5` | `6+`
  final String eventCountBucket;
}

class FeedEmptyModeSet extends AnalyticsEvent {
  const FeedEmptyModeSet({required this.mode});

  /// `compact` | `collapsed` | `hidden`
  final String mode;
}

class CategorySaved extends AnalyticsEvent {
  const CategorySaved({required this.countBucket});

  /// `1-2` | `3-5` | `6-8`
  final String countBucket;
}

class FeedJump extends AnalyticsEvent {
  const FeedJump({required this.target, required this.bucket});

  /// `today` | `day` | `month`
  final String target;
  final String bucket;
}

class TodayOpened extends AnalyticsEvent {
  const TodayOpened({required this.hasEvents, required this.eventCountBucket});

  final bool hasEvents;

  /// `0` | `1-2` | `3-5` | `6+`
  final String eventCountBucket;
}
