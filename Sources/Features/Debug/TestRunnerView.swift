import SwiftUI

struct TestRunnerView: View {
    @State private var testResults: [String: TestResult] = [:]
    @State private var isRunningTests = false
    @State private var selectedTest: TestType?
    
    enum TestType: String, CaseIterable {
        case auth = "Authentication"
        case course = "Course"
        case test = "Psych Test"
        case weeklyColumn = "Weekly Column"
        case character = "Character"
        case chat = "Chat"
        case profile = "Profile"
        case notification = "Notification"
        case all = "All Tests"
    }
    
    struct TestResult: Equatable {
        let success: Bool
        let message: String
        let timestamp: Date
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(TestType.allCases, id: \.self) { testType in
                        Button {
                            selectedTest = testType
                            Task {
                                await runTest(testType)
                            }
                        } label: {
                            HStack {
                                Text(testType.rawValue)
                                Spacer()
                                if let result = testResults[testType.rawValue] {
                                    Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(result.success ? .green : .red)
                                }
                                if selectedTest == testType && isRunningTests {
                                    ProgressView()
                                }
                            }
                        }
                        .disabled(isRunningTests)
                    }
                } header: {
                    Text("Test Flows")
                }
                
                if !testResults.isEmpty {
                    Section {
                        ForEach(testResults.sorted(by: { $0.key < $1.key }), id: \.key) { key, result in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(key)
                                        .font(.headline)
                                    Spacer()
                                    Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(result.success ? .green : .red)
                                }
                                
                                if !result.success {
                                    Text(result.message)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                                
                                Text(result.timestamp.formatted())
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } header: {
                        Text("Results")
                    }
                }
            }
            .navigationTitle("Test Runner")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        testResults.removeAll()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .disabled(testResults.isEmpty || isRunningTests)
                }
            }
        }
    }
    
    private func runTest(_ type: TestType) async {
        isRunningTests = true
        defer { isRunningTests = false }
        
        do {
            switch type {
            case .auth:
                try await TestHelper.shared.testAuthFlow()
                recordSuccess(for: type)
            case .course:
                try await TestHelper.shared.testCourseFlow()
                recordSuccess(for: type)
            case .test:
                try await TestHelper.shared.testPsychTestFlow()
                recordSuccess(for: type)
            case .weeklyColumn:
                try await TestHelper.shared.testWeeklyColumnFlow()
                recordSuccess(for: type)
            case .character:
                try await TestHelper.shared.testCharacterFlow()
                recordSuccess(for: type)
            case .chat:
                try await TestHelper.shared.testChatFlow()
                recordSuccess(for: type)
            case .profile:
                try await TestHelper.shared.testProfileFlow()
                recordSuccess(for: type)
            case .notification:
                try await TestHelper.shared.testNotificationFlow()
                recordSuccess(for: type)
            case .all:
                await runAllTests()
            }
        } catch {
            recordFailure(for: type, error: error)
        }
    }
    
    private func runAllTests() async {
        for type in TestType.allCases where type != .all {
            await runTest(type)
        }
    }
    
    private func recordSuccess(for type: TestType) {
        testResults[type.rawValue] = TestResult(
            success: true,
            message: "Test passed",
            timestamp: Date()
        )
    }
    
    private func recordFailure(for type: TestType, error: Error) {
        testResults[type.rawValue] = TestResult(
            success: false,
            message: error.localizedDescription,
            timestamp: Date()
        )
    }
} 