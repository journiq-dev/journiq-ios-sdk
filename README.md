# Journiq iOS SDK

Official iOS SDK for [Journiq](https://getjourniq.com) — deep linking, deferred deep links, attribution, and event tracking for iOS apps.

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
3. Select version rule: **Up to Next Major** from `0.1.0`
4. Add `JourniqSDK` to your target

Or in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/journiq-dev/journiq-ios-sdk", from: "0.1.0"),
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

## API Reference

### `Journiq` (Class)

| Method | Description |
|--------|-------------|
| `configure(apiKey:baseUrl:)` | Initialize the SDK |
| `deepLinks` | Deep link module |
| `links` | Link management module |
| `events` | Event tracking module |
| `analytics` | Analytics module |
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
