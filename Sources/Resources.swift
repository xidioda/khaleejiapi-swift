import Foundation

// MARK: - Validation Resource

/// Validation APIs: email, phone, IBAN, VAT/TRN, Emirates ID, Saudi ID
public final class ValidationResource: @unchecked Sendable {
    private let client: KhaleejiAPI

    init(client: KhaleejiAPI) {
        self.client = client
    }

    // MARK: Email

    public struct EmailResult: Decodable {
        public let valid: Bool
        public let email: String
        public let checks: EmailChecks
        public let suggestion: String?
        public let domain: String
        public let deliverabilityScore: Int?
        public let provider: EmailProvider?
        public let spf: Bool?
        public let dmarc: Bool?
        public let normalized: String?
    }

    public struct EmailChecks: Decodable {
        public let format: Bool?
        public let mx: Bool
        public let disposable: Bool
        public let role: Bool
        public let freeProvider: Bool?
    }

    public struct EmailProvider: Decodable {
        public let name: String?
        public let type: String?
    }

    /// Validate an email address
    public func validateEmail(_ email: String) async throws -> EmailResult {
        let response: APIResponse<EmailResult> = try await client.get("/email/validate", params: ["email": email])
        return response.data
    }

    // MARK: Phone

    public struct PhoneResult: Decodable {
        public let valid: Bool
        public let phone: String
        public let formatted: String?
        public let type: String?
        public let country: PhoneCountry?
        public let carrier: PhoneCarrier?
        public let formats: PhoneFormats?
        public let areaCode: String?
        public let areaName: String?
        public let portingNote: String?
        public let nationalNumber: String?
    }

    public struct PhoneCountry: Decodable {
        public let name: String?
        public let code: String?
        public let dialCode: String?
    }

    public struct PhoneCarrier: Decodable {
        public let name: String?
        public let mcc: String?
        public let mnc: String?
    }

    public struct PhoneFormats: Decodable {
        public let e164: String?
        public let international: String?
        public let local: String?
        public let rfc3966: String?
    }

    /// Validate a phone number
    public func validatePhone(_ phone: String, country: String? = nil) async throws -> PhoneResult {
        let response: APIResponse<PhoneResult> = try await client.get("/phone/validate", params: [
            "phone": phone,
            "country": country,
        ])
        return response.data
    }

    // MARK: IBAN

    public struct IBANResult: Decodable {
        public let valid: Bool
        public let iban: String
        public let country: String?
        public let bankName: String?
        public let bankCode: String?
    }

    /// Validate an IBAN
    public func validateIBAN(_ iban: String) async throws -> IBANResult {
        let response: APIResponse<IBANResult> = try await client.get("/iban/validate", params: ["iban": iban])
        return response.data
    }

    // MARK: VAT/TRN

    public struct VATResult: Decodable {
        public let valid: Bool
        public let trn: String?
        public let tin: String?
        public let country: VATCountry?
        public let authority: VATAuthority?
        public let vatRate: Double?
        public let vatRateNote: String?
        public let format: String?
        public let checkDigitValid: Bool?
    }

    public struct VATCountry: Decodable {
        public let code: String?
        public let name: String?
        public let nameAr: String?
    }

    public struct VATAuthority: Decodable {
        public let name: String?
        public let nameAr: String?
        public let website: String?
    }

    /// Validate a VAT/TRN number
    public func validateVAT(_ trn: String, countryCode: String? = nil) async throws -> VATResult {
        let response: APIResponse<VATResult> = try await client.get("/vat/validate", params: ["trn": trn, "country": countryCode])
        return response.data
    }

    // MARK: Emirates ID

    public struct EmiratesIDResult: Decodable {
        public let valid: Bool
        public let id: String?
        public let emiratesId: String?
        public let formatted: String?
        public let components: EmiratesIDComponents?
        public let details: EmiratesIDDetails?
        public let authority: EmiratesIDAuthority?
        public let message: String?
    }

    public struct EmiratesIDComponents: Decodable {
        public let nationalityCode: String?
        public let countryCode: String?
        public let birthYear: Int?
        public let sequenceNumber: String?
        public let checkDigit: Int?
    }

    public struct EmiratesIDDetails: Decodable {
        public let birthYear: Int?
        public let estimatedAge: Int?
        public let ageRange: String?
        public let generation: String?
    }

    public struct EmiratesIDAuthority: Decodable {
        public let name: String?
        public let nameAr: String?
        public let website: String?
    }

    /// Validate a UAE Emirates ID
    public func validateEmiratesID(_ id: String) async throws -> EmiratesIDResult {
        let response: APIResponse<EmiratesIDResult> = try await client.get("/emirates-id/validate", params: ["id": id])
        return response.data
    }

    // MARK: Saudi ID

    public struct SaudiIDResult: Decodable {
        public let id: String
        public let valid: Bool
        public let type: String?
        public let typeAr: String?
        public let nationality: String?
        public let nationalityAr: String?
        public let description: String?
        public let descriptionAr: String?
        public let details: SaudiIDDetails?
        public let authority: SaudiIDAuthority?
        public let errors: [String]?
    }

    public struct SaudiIDDetails: Decodable {
        public let estimatedBirthYearHijri: Int?
        public let estimatedBirthYearGregorian: Int?
        public let estimatedAge: Int?
        public let ageRange: String?
        public let generation: String?
        public let checkDigit: Int?
    }

    public struct SaudiIDAuthority: Decodable {
        public let name: String?
        public let nameAr: String?
        public let website: String?
    }

    public struct SaudiIDBatchResult: Decodable {
        public let results: [SaudiIDResult]
        public let summary: BatchSummary
    }

    public struct BatchSummary: Decodable {
        public let total: Int
        public let valid: Int
        public let invalid: Int
    }

    /// Validate a Saudi National ID or Iqama
    public func validateSaudiID(_ id: String) async throws -> SaudiIDResult {
        let response: APIResponse<SaudiIDResult> = try await client.get("/saudi-id/validate", params: ["id": id])
        return response.data
    }

    /// Batch validate Saudi IDs (max 100)
    public func validateSaudiIDBatch(_ ids: [String]) async throws -> SaudiIDBatchResult {
        struct Body: Encodable { let ids: [String] }
        let response: APIResponse<SaudiIDBatchResult> = try await client.post("/saudi-id/validate", body: Body(ids: ids))
        return response.data
    }
}

// MARK: - Geo Resource

/// Geolocation APIs: IP lookup, timezone, geocoding
public final class GeoResource: @unchecked Sendable {
    private let client: KhaleejiAPI

    init(client: KhaleejiAPI) {
        self.client = client
    }

    public struct IPResult: Decodable {
        public let ip: String
        public let country: String?
        public let countryName: String?
        public let city: String?
        public let latitude: Double?
        public let longitude: Double?
        public let isp: String?
    }

    /// Look up IP geolocation data
    public func ipLookup(_ ip: String? = nil) async throws -> IPResult {
        let response: APIResponse<IPResult> = try await client.get("/ip/lookup", params: ["ip": ip])
        return response.data
    }

    public struct TimezoneResult: Decodable {
        public let location: String
        public let timezone: String
        public let utcOffset: String?
        public let dstActive: Bool?
        public let currentTime: String?
    }

    /// Get timezone data for a location
    public func getTimezone(location: String) async throws -> TimezoneResult {
        let response: APIResponse<TimezoneResult> = try await client.get("/timezone", params: ["location": location])
        return response.data
    }

    public struct GeocodeResult: Decodable {
        public let results: [GeocodeItem]
        public let attribution: String?
    }

    public struct GeocodeItem: Decodable {
        public let name: String?
        public let nameAr: String?
        public let lat: Double
        public let lng: Double
        public let country: String?
        public let countryAr: String?
        public let countryCode: String?
        public let type: String?
        public let address: GeocodeAddress?
        public let osmId: Int?
        public let importance: Double?
        public let boundingBox: GeocodeBoundingBox?
    }

    public struct GeocodeAddress: Decodable {
        public let road: String?
        public let neighbourhood: String?
        public let city: String?
        public let state: String?
        public let postcode: String?
        public let full: String?
    }

    public struct GeocodeBoundingBox: Decodable {
        public let south: Double
        public let north: Double
        public let west: Double
        public let east: Double
    }

    /// Geocode an address or coordinates
    public func geocode(q: String, country: String? = nil, lang: String? = nil) async throws -> GeocodeResult {
        let response: APIResponse<GeocodeResult> = try await client.get("/geocode", params: [
            "q": q,
            "country": country,
            "lang": lang,
        ])
        return response.data
    }
}

// MARK: - Finance Resource

/// Finance APIs: exchange rates, VAT calculation, holidays, business days
public final class FinanceResource: @unchecked Sendable {
    private let client: KhaleejiAPI

    init(client: KhaleejiAPI) {
        self.client = client
    }

    public struct ExchangeRatesResult: Decodable {
        public let base: String
        public let rates: [String: Double]
        public let source: String?
    }

    /// Get exchange rates
    public func getExchangeRates(base: String = "AED", symbols: [String]? = nil) async throws -> ExchangeRatesResult {
        let response: APIResponse<ExchangeRatesResult> = try await client.get("/exchange/rates", params: [
            "base": base,
            "symbols": symbols?.joined(separator: ","),
        ])
        return response.data
    }

    public struct VATCalcResult: Decodable {
        public let country: String
        public let vatRate: Double
        public let inputAmount: Double
        public let baseAmount: Double
        public let vatAmount: Double
        public let totalAmount: Double
        public let currency: String
    }

    /// Calculate VAT
    public func calculateVAT(amount: Double, country: String = "AE", inclusive: Bool = false) async throws -> VATCalcResult {
        let response: APIResponse<VATCalcResult> = try await client.get("/vat/calculate", params: [
            "amount": String(amount),
            "country": country,
            "inclusive": String(inclusive),
        ])
        return response.data
    }

    public struct HolidaysResult: Decodable {
        public let country: String
        public let countryName: String?
        public let year: Int
        public let weekends: [String]?
        public let holidays: [Holiday]
        public let totalDays: Int?
        public let availableYears: [Int]?
        public let nextHoliday: NextHoliday?
    }

    public struct Holiday: Decodable {
        public let name: String
        public let nameAr: String?
        public let date: String
        public let endDate: String?
        public let type: String
        public let sector: String?
        public let dayOfWeek: String?
        public let daysUntil: Int?
        public let isPast: Bool?
        public let note: String?
    }

    public struct NextHoliday: Decodable {
        public let name: String?
        public let date: String?
        public let daysUntil: Int?
    }

    /// Get public holidays for a GCC country
    public func getHolidays(
        country: String = "AE",
        year: Int? = nil,
        mode: String? = nil,
        date: String? = nil,
        month: Int? = nil
    ) async throws -> HolidaysResult {
        let response: APIResponse<HolidaysResult> = try await client.get("/holidays", params: [
            "country": country,
            "year": year.map { String($0) },
            "mode": mode,
            "date": date,
            "month": month.map { String($0) },
        ])
        return response.data
    }

    public struct BusinessDaysResult: Decodable {
        public let businessDays: Int?
        public let totalDays: Int?
        public let isBusinessDay: Bool?
        public let from: String?
        public let to: String?
        public let resultDate: String?
    }

    /// Calculate business days
    public func getBusinessDays(
        country: String = "AE",
        date: String? = nil,
        from: String? = nil,
        to: String? = nil,
        add: Int? = nil
    ) async throws -> BusinessDaysResult {
        let response: APIResponse<BusinessDaysResult> = try await client.get("/business-days", params: [
            "country": country,
            "date": date,
            "from": from,
            "to": to,
            "add": add.map { String($0) },
        ])
        return response.data
    }
}

// MARK: - Communication Resource

/// Communication APIs: AI-powered translation
public final class CommunicationResource: @unchecked Sendable {
    private let client: KhaleejiAPI

    init(client: KhaleejiAPI) {
        self.client = client
    }

    public struct TranslationResult: Decodable {
        public let text: String?
        public let translated: String?
        public let from: String?
        public let to: String?
        public let detectedLanguage: String?
    }

    /// Translate text using AI (Google Gemini)
    public func translate(
        text: String,
        target: String,
        source: String? = nil,
        formality: String? = nil,
        dialect: String? = nil
    ) async throws -> TranslationResult {
        struct Body: Encodable {
            let text: String
            let target: String
            let source: String?
            let formality: String?
            let dialect: String?
        }
        let response: APIResponse<TranslationResult> = try await client.post("/translate", body: Body(
            text: text, target: target, source: source, formality: formality, dialect: dialect
        ))
        return response.data
    }
}

// MARK: - Islamic Resource

/// Islamic APIs: Hijri calendar, prayer times, Arabic text processing
public final class IslamicResource: @unchecked Sendable {
    private let client: KhaleejiAPI

    init(client: KhaleejiAPI) {
        self.client = client
    }

    public struct HijriResult: Decodable {
        public let gregorian: HijriDate
        public let hijri: HijriDate
        public let direction: String
    }

    public struct HijriDate: Decodable {
        public let date: String
        public let year: Int
        public let month: Int
        public let day: Int
        public let monthName: String?
        public let monthNameAr: String?
        public let dayOfWeek: String?
        public let dayOfWeekAr: String?
    }

    /// Convert between Gregorian and Hijri calendars
    public func convertHijri(date: String? = nil, hijri: String? = nil, today: Bool = false) async throws -> HijriResult {
        let response: APIResponse<HijriResult> = try await client.get("/hijri/convert", params: [
            "date": date,
            "hijri": hijri,
            "today": today ? "true" : nil,
        ])
        return response.data
    }

    public struct PrayerTimesResult: Decodable {
        public let location: PrayerLocation?
        public let date: String
        public let prayers: Prayers
        public let qibla: Qibla?
        public let method: PrayerMethod?
        public let school: String?
    }

    public struct PrayerLocation: Decodable {
        public let lat: Double
        public let lng: Double
        public let city: String?
        public let country: String?
    }

    public struct Prayers: Decodable {
        public let fajr: String
        public let sunrise: String
        public let dhuhr: String
        public let asr: String
        public let maghrib: String
        public let isha: String
    }

    public struct Qibla: Decodable {
        public let direction: Double
        public let compass: String?
    }

    public struct PrayerMethod: Decodable {
        public let name: String
    }

    /// Get prayer times for a location
    public func getPrayerTimes(
        city: String? = nil,
        lat: Double? = nil,
        lng: Double? = nil,
        date: String? = nil,
        method: String = "mwl",
        school: String = "shafi"
    ) async throws -> PrayerTimesResult {
        let response: APIResponse<PrayerTimesResult> = try await client.get("/prayer-times", params: [
            "city": city,
            "lat": lat.map { String($0) },
            "lng": lng.map { String($0) },
            "date": date,
            "method": method,
            "school": school,
        ])
        return response.data
    }

    public struct ArabicResult: Decodable {
        public let operation: String
        public let original: String?
        public let text: String?
        public let result: String?
        public let removedCount: Int?
        public let count: Int?
        public let words: [String]?
        public let score: Double?
        public let label: String?
        public let script: String?
    }

    /// Process Arabic text
    public func processArabic(
        text: String,
        operation: String,
        direction: String? = nil
    ) async throws -> ArabicResult {
        struct Body: Encodable {
            let text: String
            let operation: String
            let options: Options?

            struct Options: Encodable {
                let direction: String?
            }
        }
        let response: APIResponse<ArabicResult> = try await client.post("/arabic/process", body: Body(
            text: text,
            operation: operation,
            options: direction.map { Body.Options(direction: $0) }
        ))
        return response.data
    }
}

// MARK: - Utility Resource

/// Utility APIs: weather, QR code, URL shortener, fraud check
public final class UtilityResource: @unchecked Sendable {
    private let client: KhaleejiAPI

    init(client: KhaleejiAPI) {
        self.client = client
    }

    public struct WeatherResult: Decodable {
        public let city: String?
        public let temperature: Double?
        public let humidity: Int?
        public let condition: String?
        public let windSpeed: Double?
    }

    /// Get weather for a city
    public func getWeather(city: String) async throws -> WeatherResult {
        let response: APIResponse<WeatherResult> = try await client.get("/weather", params: ["city": city])
        return response.data
    }

    public struct FraudResult: Decodable {
        public let riskScore: Int
        public let riskLevel: String
        public let recommendation: String?
        public let signals: [FraudSignal]?
        public let ipIntelligence: FraudIpIntelligence?
        public let crossFieldAnalysis: [FraudCrossField]?
    }

    public struct FraudSignal: Decodable {
        public let field: String?
        public let risk: String?
        public let score: Int?
        public let reason: String?
    }

    public struct FraudIpIntelligence: Decodable {
        public let country: String?
        public let isTorExitNode: Bool?
        public let isAnonymousVpn: Bool?
        public let isPublicProxy: Bool?
        public let isHostingProvider: Bool?
        public let isResidentialProxy: Bool?
        public let isp: String?
        public let organization: String?
    }

    public struct FraudCrossField: Decodable {
        public let type: String?
        public let risk: String?
        public let detail: String?
    }

    /// Check for fraud
    public func fraudCheck(ip: String? = nil, email: String? = nil, phone: String? = nil, name: String? = nil) async throws -> FraudResult {
        struct Body: Encodable {
            let ip: String?
            let email: String?
            let phone: String?
            let name: String?
        }
        let response: APIResponse<FraudResult> = try await client.post("/fraud/check", body: Body(ip: ip, email: email, phone: phone, name: name))
        return response.data
    }

    public struct ShortenResult: Decodable {
        public let code: String
        public let shortUrl: String
        public let originalUrl: String
    }

    /// Shorten a URL
    public func shortenURL(_ url: String, customCode: String? = nil) async throws -> ShortenResult {
        struct Body: Encodable {
            let url: String
            let customCode: String?
        }
        let response: APIResponse<ShortenResult> = try await client.post("/url/shorten", body: Body(url: url, customCode: customCode))
        return response.data
    }
}
