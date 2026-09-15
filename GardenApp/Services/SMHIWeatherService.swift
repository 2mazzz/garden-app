import Foundation

/// One day's forecast minimum temperature, in Europe/Stockholm calendar days.
struct SMHIForecastDay: Identifiable {
    var id: Date { date }
    let date: Date
    let minTemperatureCelsius: Double
}

enum SMHIWeatherServiceError: Error {
    case invalidResponse
}

/// Fetches a point forecast from SMHI's free, keyless open data API.
/// See docs/decisions/0015-weather-data-source.md.
enum SMHIWeatherService {
    private struct ForecastResponse: Decodable {
        let timeSeries: [TimeStep]
    }

    private struct TimeStep: Decodable {
        let validTime: Date
        let parameters: [Parameter]
    }

    private struct Parameter: Decodable {
        let name: String
        let values: [Double]
    }

    /// Next few days' minimum temperature, one entry per calendar day
    /// (Europe/Stockholm), soonest first.
    static func fetchDailyMinTemperatures(latitude: Double, longitude: Double) async throws -> [SMHIForecastDay] {
        let url = URL(
            string: "https://opendata-download-metfcst.smhi.se/api/category/pmp3g/version/2/geotype/point/lon/\(longitude)/lat/\(latitude)/data.json"
        )!
        var request = URLRequest(url: url)
        // SMHI's usage policy asks for a descriptive User-Agent rather than an API key.
        request.setValue("GardenApp/1.0 (personal garden tracker, 2 users)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw SMHIWeatherServiceError.invalidResponse
        }
        return try parse(data: data)
    }

    /// Exposed separately from the network call so the parsing/aggregation
    /// logic can be unit-tested against a fixture response.
    static func parse(data: Data) throws -> [SMHIForecastDay] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let forecast = try decoder.decode(ForecastResponse.self, from: data)
        return dailyMinimums(from: forecast.timeSeries)
    }

    private static func dailyMinimums(from timeSteps: [TimeStep]) -> [SMHIForecastDay] {
        var stockholm = Calendar(identifier: .gregorian)
        stockholm.timeZone = TimeZone(identifier: "Europe/Stockholm") ?? .current

        var minByDay: [Date: Double] = [:]
        for step in timeSteps {
            guard let temperature = step.parameters.first(where: { $0.name == "t" })?.values.first else { continue }
            let dayStart = stockholm.startOfDay(for: step.validTime)
            minByDay[dayStart] = min(minByDay[dayStart] ?? .greatestFiniteMagnitude, temperature)
        }

        return minByDay
            .map { SMHIForecastDay(date: $0.key, minTemperatureCelsius: $0.value) }
            .sorted { $0.date < $1.date }
    }
}
