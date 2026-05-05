# Journiq iOS SDK

Official iOS SDK for [Journiq](https://getjourniq.com) — deep linking, deferred deep links, attribution, event tracking, in-app notifications, and push for iOS apps.

## Requirements

- iOS 14+
- Swift 5.9+
- Xcode 15+

## Installation

### Swift Package Manager

Add the package in Xcode:

1. **File → Add Package Dependencies...**
2. Enter the repository URL:
   ```
   https://github.com/journiq-dev/journiq-ios-sdk
   ```
3. Select version rule: **Up to Next Major** from `0.2.1`
4. Add `JourniqSDK` to your target

Or in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/journiq-dev/journiq-ios-sdk", from: "0.2.1"),
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "JourniqSDK", package: "journiq-ios-sdk"),
        ]
    ),
]
```

## Quick Start

### 1. Initialize

```swift
// In your AppDelegate or @main App
import JourniqSDK

@main
struct MyApp: App {
    init() {
        Journiq.configure(apiKey: "jq_pub_your_public_key_here")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 2. Check Deferred Deep Links

```swift
// In your root view or app delegate
Task {
    let result = await Journiq.deepLinks.checkDeferredDeepLink()
    if result.matched, let deepLink = result.deepLink {
        // User installed via a Journiq link — navigate to content
        navigateTo(deepLink.deepLinkPath)
    }
}
```

### 3. Handle Universal Links

```swift
// SwiftUI
.onOpenURL { url in
    if let parsed = Journiq.deepLinks.handleURL(url) {
        let path = parsed.path           // e.g. "product/123"
        let params = parsed.parameters    // query parameters
        navigateTo(path, params: params)
    }
}

// UIKit (SceneDelegate)
func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    guard let url = userActivity.webpageURL,
          let parsed = Journiq.deepLinks.handleURL(url) else { return }
    navigateTo(parsed.path)
}
```

### 4. Track Events

```swift
// Track a conversion event
Journiq.events.track(
    eventName: "purchase",
    deepLinkId: linkId,
    metadata: ["amount": "29.99", "currency": "USD"]
)
```

Events are queued locally (file-based JSON in Library/Caches) and flushed in batches:
- Automatically every 60 seconds when online
- Immediately when network connectivity is restored
- When the app returns to the foreground
- Manually: `await Journiq.events.flush()`

### 5. Create Links (Server-side / Secret Key)

```swift
// Requires secret key (jq_app_*)
Journiq.configure(apiKey: "jq_app_your_secret_key_here")

let link = try await Journiq.links.create(
    LinkCreateRequest(
        webUrl: "https://example.com/product/123",
        title: "Amazing Product",
        deepLinkPath: "product/123"
    )
)
print(link.shortUrl) // https://jnq.link/abc123
```

### 6. Get Analytics (Server-side / Secret Key)

```swift
let stats = try await Journiq.analytics.getLinkStats(linkId: linkId)
print("Total clicks: \(stats.totalClicks)")
print("Unique clicks: \(stats.uniqueClicks)")
```

### 7. Push Notifications

Register the device token so the backend can deliver push and in-app notifications:

```swift
import FirebaseMessaging

// Register FCM token
if let token = Messaging.messaging().fcmToken {
    try await Journiq.push.registerFCMToken(token)
}

// Or register raw APNs token
func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Task {
        try await Journiq.push.registerAPNsToken(deviceToken)
    }
}
```

Handle FCM data messages for in-app notification delivery:

```swift
// In your MessagingDelegate
func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
    let handled = Journiq.push.handleDataMessage(remoteMessage.appData)
    if !handled {
        // Your own message handling
    }
}
```

### 8. In-App Notifications

#### Listen for new notifications (AsyncStream)

```swift
Task {
    for await notification in Journiq.notifications.newNotifications {
        print("New notification: \(notification.title)")
    }
}
```

#### Custom Display Delegate (recommended)

Implement `JourniqNotificationDisplayDelegate` to control the UI:

```swift
class NotificationPresenter: JourniqNotificationDisplayDelegate {
    func displayNotification(_ notification: InAppNotification) {
        // Show your custom banner, sheet, or overlay
        DispatchQueue.main.async {
            let banner = MyBannerView(
                title: notification.title,
                body: notification.body,
                imageURL: notification.imageUrl
            )
            banner.onTap = {
                Task { try await Journiq.notifications.markAsRead(notification.id) }
                Journiq.notifications.reportAction(notification, action: .tapped)
            }
            banner.onDismiss = {
                Journiq.notifications.reportAction(notification, action: .dismissed)
            }
            banner.show()
        }
    }
}

// Register (e.g., in your root view controller's viewDidLoad)
Journiq.notifications.displayDelegate = NotificationPresenter()
```

#### Fetch notifications

```swift
let response = try await Journiq.notifications.getAll(page: 1, limit: 20, unreadOnly: false)
for notification in response.notifications {
    print("\(notification.title) - read: \(notification.read)")
}
```

#### Mark as read & unread count

```swift
try await Journiq.notifications.markAsRead(notificationId)
let unread = try await Journiq.notifications.getUnreadCount()
```

## API Reference

### `Journiq` (Class)

| Method | Description |
|--------|-------------|
| `configure(apiKey:baseUrl:)` | Initialize the SDK |
| `deepLinks` | Deep link module |
| `links` | Link management module |
| `events` | Event tracking module |
| `analytics` | Analytics module |
| `notifications` | In-app notifications module |
| `push` | Push notification registration module |
| `onAppForegrounded()` | Call from `applicationDidBecomeActive` |

### `Journiq.deepLinks` (JourniqDeepLinks)

| Method | Description |
|--------|-------------|
| `checkDeferredDeepLink()` | Check for deferred deep link (first launch only) |
| `handleURL(_:)` | Parse a deep link from an incoming URL |

### `Journiq.links` (JourniqLinks)

| Method | Key Required | Description |
|--------|-------------|-------------|
| `create(_:)` | Secret | Create a new short link |
| `list(page:limit:)` | Secret | List links for the app |
| `get(linkId:)` | Secret | Get a link by ID |

### `Journiq.events` (JourniqEvents)

| Method | Description |
|--------|-------------|
| `track(eventName:deepLinkId:metadata:)` | Queue an event for tracking |
| `flush()` | Force flush pending events |

### `Journiq.analytics` (JourniqAnalytics)

| Method | Key Required | Description |
|--------|-------------|-------------|
| `getLinkStats(linkId:)` | Secret | Get click stats for a link |
| `getAppConfig()` | Any | Get app configuration |

### `Journiq.notifications` (JourniqNotifications)

| Method | Description |
|--------|-------------|
| `newNotifications` | AsyncStream emitting new notifications in real-time |
| `getAll(page:limit:unreadOnly:)` | Fetch paginated notifications |
| `markAsRead(_:)` | Mark a notification as read |
| `getUnreadCount()` | Get the current unread count |
| `displayDelegate` | Set to a `JourniqNotificationDisplayDelegate` for custom UI |
| `reportAction(_:action:)` | Report user tap/dismiss action on a notification |

### `Journiq.push` (JourniqPush)

| Method | Description |
|--------|-------------|
| `registerFCMToken(_:)` | Register an FCM token with Journiq |
| `registerAPNsToken(_:)` | Register a raw APNs device token |
| `handleDataMessage(_:)` | Process an FCM data message. Returns `true` if handled. |

## Offline Support

Events are persisted as JSON files in `Library/Caches/journiq_events/`:

- **Max queue**: 1,000 events (FIFO eviction)
- **Max retries**: 3 per event
- **Expiry**: 7 days
- **Auto-flush**: Every 60s, on network restore, on app foreground

## Zero Dependencies

This SDK uses only Apple frameworks:
- `URLSession` for networking
- `NWPathMonitor` for connectivity monitoring
- `JSONEncoder`/`JSONDecoder` for serialization
- `UserDefaults` for state persistence
- File system for event queue

## Dual Key System

| Key Type | Prefix | Use Case |
|----------|--------|----------|
| Public | `jq_pub_` | Safe for client apps (mobile, web) |
| Secret | `jq_app_` | Server-side only (link CRUD, analytics) |

## License

MIT
