//
//  AppearenceManager.swift
//  WatchBrowser
//
//  Created by memz233 on 10/2/24.
//

import OSLog
import SwiftUI
import WeatherKit

final class AppearenceManager {
    static let shared = AppearenceManager()
    
    var currentAppearence = Appearence.light
    
    @AppStorage("DBAutoAppearenceOptionTrigger") private var autoAppearenceOptionTrigger = "CustomTimeRange"
    @AppStorage("DBAutoAppearenceOptionTimeRangeLight") private var autoAppearenceOptionTimeRangeLight = "7:00"
    @AppStorage("DBAutoAppearenceOptionTimeRangeDark") private var autoAppearenceOptionTimeRangeDark = "22:00"
    @AppStorage("AMSunriseTime") private var sunriseTime = "07:00"
    @AppStorage("AMSunsetTime") private var sunsetTime = "22:00"
    
    init() {
        let autoAppearenceOptionTrigger = UserDefaults.standard.string(forKey: "DBAutoAppearenceOptionTrigger") ?? "CustomTimeRange"
        switch autoAppearenceOptionTrigger {
        case "Sun":
            Task {
                await updateSunEvents()
                updateAppearence()
            }
        case "CustomTimeRange":
            updateAppearence()
        default:
            break
        }
    }
    
    func updateSunEvents() async {
        do {
            let daily = try await WeatherService.shared.weather(for: CachedLocationManager.shared.getCachedLocation(), including: .daily)
            if let sunriseDate = daily.forecast.first?.sun.sunrise, let sunsetDate = daily.forecast.first?.sun.sunset {
                let dateFormatter = DateFormatter()
                dateFormatter.locale = .init(identifier: "en_US_POSIX")
                dateFormatter.dateFormat = "HH:mm"
                sunriseTime = dateFormatter.string(from: sunriseDate)
                sunsetTime = dateFormatter.string(from: sunsetDate)
            }
        } catch {
            os_log(.error, "\(error)")
        }
    }
    func updateAppearence() {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = .init(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "HH:mm"
        let currentTime = dateFormatter.string(from: .now)
        switch autoAppearenceOptionTrigger {
        case "Sun":
            currentAppearence = isTimeString(currentTime, between: sunriseTime, and: sunsetTime) ? .light : .dark
        case "CustomTimeRange":
            currentAppearence = isTimeString(currentTime, between: autoAppearenceOptionTimeRangeLight, and: autoAppearenceOptionTimeRangeDark) ? .light : .dark
        default:
            break
        }
        
        func isTimeString(_ compared: String, between lower: String, and higher: String) -> Bool {
            let (comparingHour, comparingMinute) = splitInts(fromTimeString: compared)
            let (lowerHour, lowerMinute) = splitInts(fromTimeString: lower)
            let (higherHour, higherMinute) = splitInts(fromTimeString: higher)
            return comparingHour >= lowerHour && comparingHour <= higherHour && (comparingHour > lowerHour || comparingMinute >= lowerMinute) && (comparingHour < higherHour || comparingMinute < higherMinute)
            // swiftlint:disable:previous line_length
            
            func splitInts(fromTimeString timeString: String) -> (hour: Int, minute: Int) {
                let splited = timeString.components(separatedBy: ":")
                return (Int(splited[0])!, Int(splited[1])!)
            }
        }
    }
    func updateAll(withCompletion completion: @escaping () -> Void = {}) {
        Task {
            if autoAppearenceOptionTrigger == "Sun" {
                await updateSunEvents()
            }
            updateAppearence()
            completion()
        }
    }
    
    enum Appearence {
        case light
        case dark
    }
}
