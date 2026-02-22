# KhaleejiAPI Swift SDK

Official Swift SDK for [KhaleejiAPI](https://khaleejiapi.dev) — the MENA region's developer API platform.

## Requirements

- iOS 15.0+ / macOS 12.0+ / watchOS 8.0+ / tvOS 15.0+
- Swift 5.9+
- Xcode 15.0+

## Installation

### Swift Package Manager

Add KhaleejiAPI to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/xidioda/khaleejiapi-swift.git", from: "1.0.0")
]
```

Or in Xcode: **File → Add Package Dependencies** → paste the repository URL.

## Quick Start

```swift
import KhaleejiAPI

let api = KhaleejiAPI(apiKey: "kapi_live_your_key_here")

// Validate an email
let email = try await api.validation.validateEmail("user@example.com")
print(email.valid) // true

// Get prayer times
let prayers = try await api.islamic.getPrayerTimes(city: "Dubai")
print(prayers.prayers.fajr) // "05:12"

// Exchange rates
let rates = try await api.finance.getExchangeRates(base: "AED", symbols: ["USD", "EUR", "SAR"])
print(rates.rates) // ["USD": 0.2723, "EUR": 0.2512, "SAR": 1.0205]
```

## API Reference

### Validation

```swift
// Email validation
let result = try await api.validation.validateEmail("user@example.com")

// Phone validation
let phone = try await api.validation.validatePhone("+971501234567", country: "AE")

// IBAN validation
let iban = try await api.validation.validateIBAN("AE070331234567890123456")

// VAT/TRN validation
let vat = try await api.validation.validateVAT("100123456700003")

// Emirates ID validation
let eid = try await api.validation.validateEmiratesID("784-1990-1234567-1")

// Saudi ID validation
let sid = try await api.validation.validateSaudiID("1012345678")

// Saudi ID batch validation (max 100)
let batch = try await api.validation.validateSaudiIDBatch(["1012345678", "2098765432"])
```

### Geolocation

```swift
// IP geolocation
let ip = try await api.geo.ipLookup("8.8.8.8")

// Timezone lookup
let tz = try await api.geo.getTimezone(location: "Dubai")

// Geocoding
let geo = try await api.geo.geocode(address: "Burj Khalifa, Dubai")
```

### Finance

```swift
// Exchange rates
let rates = try await api.finance.getExchangeRates(base: "AED", symbols: ["USD", "EUR"])

// VAT calculation
let vat = try await api.finance.calculateVAT(amount: 100.0, country: "AE")

// Public holidays
let holidays = try await api.finance.getHolidays(country: "AE", year: 2026)

// Business days
let days = try await api.finance.getBusinessDays(country: "AE", from: "2026-01-01", to: "2026-01-31")
```

### Communication

```swift
// AI Translation (powered by Google Gemini)
let translation = try await api.communication.translate(
    text: "Hello, world!",
    target: "ar",
    dialect: "gulf"
)
```

### Islamic

```swift
// Hijri calendar conversion
let hijri = try await api.islamic.convertHijri(today: true)

// Prayer times
let prayers = try await api.islamic.getPrayerTimes(city: "Mecca", method: "umm_al_qura")

// Arabic text processing
let arabic = try await api.islamic.processArabic(
    text: "بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ",
    operation: "removeDiacritics"
)
```

### Utility

```swift
// Weather
let weather = try await api.utility.getWeather(city: "Dubai")

// Fraud check
let fraud = try await api.utility.fraudCheck(email: "test@example.com", ip: "1.2.3.4")

// URL shortener
let short = try await api.utility.shortenURL("https://example.com/very-long-url")
```

## Configuration

```swift
// Simple initialization
let api = KhaleejiAPI(apiKey: "kapi_live_your_key")

// Full configuration
let config = KhaleejiAPIConfig(
    apiKey: "kapi_live_your_key",
    baseURL: "https://khaleejiapi.dev/api/v1",
    timeout: 30,
    maxRetries: 2
)
let api = KhaleejiAPI(config: config)
```

## Error Handling

```swift
do {
    let result = try await api.validation.validateEmail("test@example.com")
} catch let error as KhaleejiAPIError {
    switch error {
    case .unauthorized:
        print("Check your API key")
    case .rateLimited(let retryAfter):
        print("Rate limited. Retry after \(retryAfter ?? 60)s")
    case .badRequest(let message):
        print("Invalid request: \(message)")
    default:
        print(error.localizedDescription)
    }
}
```

## Rate Limiting

After each request, rate limit info is available:

```swift
let result = try await api.validation.validateEmail("test@example.com")
// Rate limit info is included in response headers
// The SDK automatically retries on 429 with exponential backoff
```

## License

MIT — See [LICENSE](LICENSE) for details.

## Links

- [Documentation](https://khaleejiapi.dev/docs)
- [API Reference](https://khaleejiapi.dev/docs/v1)
- [Dashboard](https://khaleejiapi.dev/dashboard)
- [Status](https://khaleejiapi.dev/status)
