## 0.3.0

* **Universal Link Resolution**: New `resolveUniversalLink(_:source:)` method on `Journiq.deepLinks`
  * Resolves a universal link URL to its deep link path, parameters, and UTM data via the Journiq API
  * Tracks the link open server-side (no separate tracking call needed)
  * Automatically stores attribution for subsequent event tracking
* **New Models**: `ResolvedLink`, `LinkOpenSource` enum (`universalLink`, `appLink`, `scheme`, `deferred`)
* Bumped deployment target to iOS 14.0

## 0.2.1

* **In-App Notifications**: Real-time notification delivery via FCM data-only push
  * `newNotifications` AsyncStream for reactive UI updates
  * `getAll()`, `markAsRead()`, `getUnreadCount()` async API methods
  * `JourniqNotificationDisplayDelegate` protocol for fully custom notification UI
  * `reportAction(_:action:)` for tap/dismiss tracking
* **Push Module**: `JourniqPush` with FCM and APNs token registration
  * `registerFCMToken(_:)` and `registerAPNsToken(_:)` methods
  * `handleDataMessage(_:)` to route silent push to notification delivery
* Zero external dependencies maintained

## 0.2.0

* Deep link handling improvements
* Event tracking with offline queue and automatic batching
* Link management: create, list, get deep links
* Analytics: link stats and app configuration
* User identity management

## 0.1.0

* Initial release
* Deferred deep link matching via device fingerprinting
* Universal Links and custom URL scheme handling
* Event tracking with file-based offline queue
* Link CRUD operations (secret key)
* Analytics retrieval (secret key)
* User identity (setIdentity / logout)
* Swift Package Manager + CocoaPods distribution
* Zero external dependencies — Apple frameworks only
* Minimum iOS 14, Swift 5.9+
