import Foundation
import BackgroundTasks
import Capacitor

class BackgroundTaskHandler {
    static let shared = BackgroundTaskHandler()
    
    private let taskID = "gr.auth.aristomate.notifications.fetch"
    private let defaults = UserDefaults.standard
    
    func scheduleBackgroundFetch() {
        // Only available on iOS 13+
        guard #available(iOS 13.0, *) else {
            print("[BG] Background tasks not available on this iOS version")
            return
        }
        
        // Ensure we're on the main thread - BGTaskScheduler must be called from main thread
        DispatchQueue.main.async {
            let request = BGAppRefreshTaskRequest(identifier: self.taskID)
            request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
            
            do {
                try BGTaskScheduler.shared.submit(request)
                print("[BG] Background fetch scheduled successfully for identifier: \(self.taskID)")
            } catch let error as NSError {
                print("[BG] Failed to schedule background fetch:")
                print("[BG]   Error Domain: \(error.domain)")
                print("[BG]   Error Code: \(error.code)")
                print("[BG]   Error: \(error.localizedDescription)")
                print("[BG]   UserInfo: \(error.userInfo)")
            } catch {
                print("[BG] Failed to schedule background fetch: \(error)")
            }
        }
    }
    
    func registerBackgroundTask() {
        // Only available on iOS 13+
        guard #available(iOS 13.0, *) else {
            print("[BG] Background tasks not available on this iOS version")
            return
        }
        
        // Call directly - already on main thread in didFinishLaunchingWithOptions
        print("[BG] Registering background task with identifier: \(taskID)")
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskID, using: nil) { task in
            print("[BG] Background task fired: \(self.taskID)")
            self.handleBackgroundFetch(task as! BGAppRefreshTask)
        }
    }
    
    private func handleBackgroundFetch(_ task: BGAppRefreshTask) {
        print("[BG] Starting background notification fetch...")
        
        // Schedule the next background fetch
        scheduleBackgroundFetch()
        
        // Fetch all notifications
        let group = DispatchGroup()
        var notificationCount = 0
        
        // Fetch Universis notifications
        group.enter()
        fetchUniversisNotifications { count in
            notificationCount += count
            group.leave()
        }
        
        // Fetch Webmail notifications
        group.enter()
        fetchWebmailNotifications { count in
            notificationCount += count
            group.leave()
        }
        
        group.notify(queue: .main) {
            print("[BG] Background fetch completed - \(notificationCount) notifications displayed")
            task.setTaskCompleted(success: notificationCount >= 0)
        }
        
        // Handle task expiration
        task.expirationHandler = {
            print("[BG] Background task expired")
            task.setTaskCompleted(success: false)
        }
    }
    
    // MARK: - Universis Notifications
    
    private func fetchUniversisNotifications(completion: @escaping (Int) -> Void) {
        guard let accessToken = defaults.string(forKey: "login_access_token") else {
            print("[BG] No Universis access token found")
            completion(0)
            return
        }
        
        let lastTimestamp = defaults.double(forKey: "last_universis_notif_timestamp")
        
        let group = DispatchGroup()
        var displayedCount = 0
        
        // Fetch messages
        group.enter()
        fetchUniversisMessages(token: accessToken, lastTimestamp: Int64(lastTimestamp)) { count in
            displayedCount += count
            group.leave()
        }
        
        // Fetch grades
        group.enter()
        fetchUniversisGrades(token: accessToken, lastTimestamp: Int64(lastTimestamp)) { count in
            displayedCount += count
            group.leave()
        }
        
        group.notify(queue: .main) {
            // Update timestamp
            self.defaults.set(Date().timeIntervalSince1970, forKey: "last_universis_notif_timestamp")
            completion(displayedCount)
        }
    }
    
    private func fetchUniversisMessages(token: String, lastTimestamp: Int64, completion: @escaping (Int) -> Void) {
        let urlString = "https://universis-api.it.auth.gr/api/Students/me/messages?$orderby=dateReceived desc, dateCreated desc&$top=3"
        
        guard let url = URL(string: urlString) else {
            completion(0)
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            var count = 0
            
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let messages = json["value"] as? [[String: Any]] {
                
                let formatter = ISO8601DateFormatter()
                
                for message in messages {
                    if let subject = message["subject"] as? String,
                       let body = message["body"] as? String,
                       let dateStr = message["dateReceived"] as? String ?? message["dateCreated"] as? String,
                       let date = formatter.date(from: dateStr) {
                        
                        let timestamp = Int64(date.timeIntervalSince1970)
                        if timestamp > lastTimestamp {
                            self.displayNotification(
                                title: "Universis",
                                body: subject,
                                summary: body.trimmingCharacters(in: .whitespaces).prefix(100),
                                source: "universis"
                            )
                            count += 1
                        }
                    }
                }
            }
            
            completion(count)
        }.resume()
    }
    
    private func fetchUniversisGrades(token: String, lastTimestamp: Int64, completion: @escaping (Int) -> Void) {
        let formatter = ISO8601DateFormatter()
        let lastModifiedDate = Date(timeIntervalSince1970: TimeInterval(lastTimestamp))
        let formattedDate = formatter.string(from: lastModifiedDate).prefix(19) // yyyy-MM-ddTHH:mm:ss
        
        let urlString = "https://universis-api.it.auth.gr/api/students/me/grades?$expand=course($expand=gradeScale,locale)&$filter=gradeModified gt '\(formattedDate)'&$top=-1&$count=false"
        
        guard let url = URL(string: urlString) else {
            completion(0)
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            var count = 0
            
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let grades = json["value"] as? [[String: Any]] {
                
                let isoFormatter = ISO8601DateFormatter()
                
                for grade in grades {
                    if let course = grade["course"] as? [String: Any],
                       let courseName = course["name"] as? String,
                       let examGrade = grade["examGrade"] as? Double,
                       let gradeScale = course["gradeScale"] as? [String: Any],
                       let scaleFactor = gradeScale["scaleFactor"] as? Double,
                       let dateStr = grade["gradeModified"] as? String,
                       let date = isoFormatter.date(from: dateStr) {
                        
                        let timestamp = Int64(date.timeIntervalSince1970)
                        if timestamp > lastTimestamp {
                            let factor = scaleFactor == 0 ? 1.0 : scaleFactor
                            let finalGrade = String(format: "%.1f", examGrade / factor)
                            let isPassed = grade["isPassed"] as? Int == 1
                            let title = "\(finalGrade)"
                            
                            self.displayNotification(
                                title: title,
                                body: courseName,
                                summary: "Grade",
                                source: "universis"
                            )
                            count += 1
                        }
                    }
                }
            }
            
            completion(count)
        }.resume()
    }
    
    // MARK: - Webmail Notifications
    
    private func fetchWebmailNotifications(completion: @escaping (Int) -> Void) {
        guard let username = defaults.string(forKey: "webmail_username"),
              let password = defaults.string(forKey: "webmail_password") else {
            print("[BG] No stored webmail credentials found")
            completion(0)
            return
        }
        
        let lastTimestamp = defaults.double(forKey: "last_webmail_notif_timestamp")
        
        print("[BG] Retrieved stored webmail credentials")
        
        // Create IMAP session
        let session = MCOIMAPSession()
        session.hostname = "mail.auth.gr"
        session.port = 993
        session.username = username
        session.password = password
        session.connectionType = .TLS
        
        print("[BG] Connecting to IMAP server...")
        
        // Fetch last 7 messages
        let fetchOp = session.fetchMessagesOperation(
            withFolder: "INBOX",
            requestKind: [.headers, .flags, .size],
            uids: MCOIndexSet(range: MCORangeMake(1, UINT64_MAX))
        )
        
        fetchOp?.start { error, messages, _ in
            var count = 0
            
            if let error = error {
                print("[BG] IMAP error: \(error.localizedDescription)")
                completion(0)
                return
            }
            
            guard let allMessages = messages as? [MCOIMAPMessage] else {
                print("[BG] No webmail messages found")
                completion(0)
                return
            }
            
            let recentMessages = Array(allMessages.suffix(7))
            print("[BG] Found \(recentMessages.count) recent webmail messages")
            
            if recentMessages.isEmpty {
                completion(0)
                return
            }
            
            // Fetch full message data and display notifications
            let group = DispatchGroup()
            
            for msg in recentMessages {
                group.enter()
                
                if let fetchDataOp = session.fetchMessageOperation(withFolder: "INBOX", uid: msg.uid) {
                    fetchDataOp.start { fetchErr, data in
                        defer { group.leave() }
                        
                        if let _ = fetchErr {
                            return
                        }
                        
                        // Skip sis notifications
                        if let sender = msg.header?.from?.mailbox, sender.contains("sis-no-reply") {
                            return
                        }
                        
                        let msgDate = msg.header?.date ?? Date()
                        let timestamp = Int64(msgDate.timeIntervalSince1970)
                        
                        if timestamp > Int64(lastTimestamp) {
                            self.displayNotification(
                                title: msg.header?.from?.displayName ?? msg.header?.from?.mailbox ?? "Unknown",
                                body: msg.header?.subject ?? "(no subject)",
                                summary: "Email",
                                source: "webmail"
                            )
                            count += 1
                        }
                    }
                } else {
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                // Update timestamp
                self.defaults.set(Date().timeIntervalSince1970, forKey: "last_webmail_notif_timestamp")
                print("[BG] Displayed \(count) webmail notifications")
                completion(count)
            }
        }
    }
    
    // MARK: - Display Notification
    
    private func displayNotification(title: String, body: String, summary: String, source: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        content.userInfo = ["source": source, "summary": summary]
        
        // Add badge icon per source
        switch source {
        case "universis":
            content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        case "webmail":
            content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        default:
            break
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(source)_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[BG] Failed to schedule notification: \(error)")
            } else {
                print("[BG] Notification scheduled - \(title)")
            }
        }
    }
}

