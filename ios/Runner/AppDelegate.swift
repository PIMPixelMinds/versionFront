import Flutter
import UIKit
import HealthKit
import Firebase
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, MessagingDelegate {
    
    let gcmMessageIDKey = "gcm.message_id"

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        FirebaseApp.configure()

        // Notifications setup
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            print("Notification permission granted: \(granted)")
        }

        application.registerForRemoteNotifications()
        print("📩 Requested remote notifications registration")
        Messaging.messaging().delegate = self

        GeneratedPluginRegistrant.register(with: self)

        // HealthKit channel
        let controller = window?.rootViewController as! FlutterViewController
        let healthChannel = FlutterMethodChannel(name: "com.meriemabid.pim/health", binaryMessenger: controller.binaryMessenger)

        healthChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
            switch call.method {
            case "fetchHealthData":
                self.fetchHealthData(result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // MARK: - Firebase Messaging
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("✅ Firebase registration token: \(fcmToken ?? "")")
        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
    }

    // MARK: - Notifications
    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        print("📬 APNs device token: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
    }
    
    override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    }

    override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        let userInfo = notification.request.content.userInfo
        print("🔔 Foreground Notification: \(userInfo)")
        return [[.alert, .sound]]
    }

    override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        print("📩 User tapped on notification: \(userInfo)")
    }

    override func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        if let messageID = userInfo[gcmMessageIDKey] {
            print("📨 Message ID: \(messageID)")
        }
        print("📩 Remote notification received: \(userInfo)")
        return .newData
    }

    // MARK: - HealthKit
    private func fetchHealthData(result: @escaping FlutterResult) {
        guard HKHealthStore.isHealthDataAvailable() else {
            result(FlutterError(code: "UNAVAILABLE", message: "Health data is not available", details: nil))
            return
        }

        let healthStore = HKHealthStore()
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount),
              let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate),
              let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN),
              let temperatureType = HKObjectType.quantityType(forIdentifier: .bodyTemperature),
              let spo2Type = HKObjectType.quantityType(forIdentifier: .oxygenSaturation),
              let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            result(FlutterError(code: "INVALID_TYPE", message: "Health data type not found", details: nil))
            return
        }

        let typesToRead: Set<HKObjectType> = [stepType, heartRateType, hrvType, temperatureType, spo2Type, sleepType]

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if !success {
                result(FlutterError(code: "PERMISSION_DENIED", message: "Health permissions not granted", details: error?.localizedDescription))
                return
            }

            let now = Date()
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: now)
            let lastHour = calendar.date(byAdding: .hour, value: -1, to: now)!
            let last24Hours = calendar.date(byAdding: .hour, value: -24, to: now)!

            let predicateToday = HKQuery.predicateForSamples(withStart: today, end: now, options: .strictStartDate)
            let predicateLastHour = HKQuery.predicateForSamples(withStart: lastHour, end: now, options: .strictStartDate)
            let predicateLast24Hours = HKQuery.predicateForSamples(withStart: last24Hours, end: now, options: .strictStartDate)

            var healthData: [String: Any] = [
                "steps": 0.0, "heart_rate": 0.0, "hrv": 0.0,
                "temperature": 0.0, "spo2": 0.0, "sleep_score": 0.0
            ]

            
            let dispatchGroup = DispatchGroup()
            
            // Fetch steps (today only)
            dispatchGroup.enter()
            let stepQuery = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicateToday, options: .cumulativeSum) { _, statistics, error in
                if let error = error {
                    print("Error fetching steps: \(error.localizedDescription)")
                    healthData["steps"] = 0.0
                } else {
                    let steps = statistics?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0.0
                    healthData["steps"] = steps
                    print("Fetched steps for today: \(steps)")
                }
                dispatchGroup.leave()
            }
            
            // Fetch heart rate (last 1 hour)
            dispatchGroup.enter()
            let heartRateQuery = HKSampleQuery(sampleType: heartRateType, predicate: predicateLastHour, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, error in
                if let error = error {
                    print("Error fetching heart rate: \(error.localizedDescription)")
                    healthData["heart_rate"] = 0.0
                } else {
                    let heartRate = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: HKUnit(from: "count/min")) ?? 0.0
                    healthData["heart_rate"] = heartRate
                    print("Fetched heart rate (last 1 hour): \(heartRate)")
                }
                dispatchGroup.leave()
            }
            
            // Fetch HRV (last 1 hour)
            dispatchGroup.enter()
            let hrvQuery = HKSampleQuery(sampleType: hrvType, predicate: predicateLastHour, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, error in
                if let error = error {
                    print("Error fetching HRV: \(error.localizedDescription)")
                    healthData["hrv"] = 0.0
                } else {
                    let hrv = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli)) ?? 0.0
                    healthData["hrv"] = hrv
                    print("Fetched HRV (last 1 hour): \(hrv)")
                }
                dispatchGroup.leave()
            }
            
            // Fetch temperature (last 1 hour)
            dispatchGroup.enter()
            let temperatureQuery = HKSampleQuery(sampleType: temperatureType, predicate: predicateLastHour, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, error in
                if let error = error {
                    print("Error fetching temperature: \(error.localizedDescription)")
                    healthData["temperature"] = 0.0
                } else {
                    let temperature = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: HKUnit.degreeCelsius()) ?? 0.0
                    healthData["temperature"] = temperature
                    print("Fetched temperature (last 1 hour): \(temperature)")
                }
                dispatchGroup.leave()
            }
            
            // Fetch SpO2 (last 1 hour)
            dispatchGroup.enter()
            let spo2Query = HKSampleQuery(sampleType: spo2Type, predicate: predicateLastHour, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, error in
                if let error = error {
                    print("Error fetching SpO2: \(error.localizedDescription)")
                    healthData["spo2"] = 0.0
                } else {
                    let spo2 = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: HKUnit.percent()) ?? 0.0
                    healthData["spo2"] = spo2
                    print("Fetched SpO2 (last 1 hour): \(spo2)")
                }
                dispatchGroup.leave()
            }
            
            // Fetch sleep (last 24 hours, duration as a proxy for sleep score)
            dispatchGroup.enter()
            let sleepQuery = HKSampleQuery(sampleType: sleepType, predicate: predicateLast24Hours, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error = error {
                    print("Error fetching sleep: \(error.localizedDescription)")
                    healthData["sleep_score"] = 0.0
                } else {
                    var sleepDuration: Double = 0.0
                    if let sleepSamples = samples as? [HKCategorySample] {
                        for sample in sleepSamples {
                            if sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue {
                                let duration = sample.endDate.timeIntervalSince(sample.startDate)
                                sleepDuration += duration
                            }
                        }
                    }
                    // Convert to hours and estimate a simple sleep score (0-100)
                    let sleepHours = sleepDuration / 3600.0
                    let sleepScore = min(sleepHours * 12.5, 100.0) // Rough score: 8 hours = 100
                    healthData["sleep_score"] = sleepScore
                    print("Fetched sleep duration (last 24 hours): \(sleepHours) hours, Sleep score: \(sleepScore)")
                }
                dispatchGroup.leave()
            }
            
            // Execute all queries
            healthStore.execute(stepQuery)
            healthStore.execute(heartRateQuery)
            healthStore.execute(hrvQuery)
            healthStore.execute(temperatureQuery)
            healthStore.execute(spo2Query)
            healthStore.execute(sleepQuery)
            
            // Wait for all queries to complete before returning the result
            dispatchGroup.notify(queue: .main) {
                print("Returning health data to Flutter: \(healthData)")
                result(healthData)
            }
        }
    }
}



