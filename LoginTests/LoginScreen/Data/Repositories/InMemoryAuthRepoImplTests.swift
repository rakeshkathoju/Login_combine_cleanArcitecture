import XCTest
import Combine
@testable import Login

final class InMemoryAuthRepositoryTests: XCTestCase {

    private var cancellables = Set<AnyCancellable>()
    private var session: URLSession!
    private var sut: InMemoryAuthRepoImpl! // System Under Test
    private let baseURL = URL(string: "https://example.com")! // test base

    override func setUp() {
        super.setUp()
        cancellables = []
        session = makeMockedSession()
        sut = InMemoryAuthRepoImpl()
        MockURLProtocol.requestHandler = nil
    }

    override func tearDown() {
        sut = nil
        session = nil
        MockURLProtocol.requestHandler = nil
        cancellables = []
        super.tearDown()
    }

    // MARK: - loginPublisherSimulatedDelay

    func test_loginPublisherSimulatedDelay_success_setsCurrentUserAndEmitsUser() {
        let exp = expectation(description: "login succeeds")

        sut.loginPublisherSimulatedDelay(username: "rakesh", password: "secret")
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Expected success, got failure: \(error)")
                }
            }, receiveValue: { user in
                XCTAssertEqual(user.username, "rakesh")
                XCTAssertNotNil(self.sut.currentUser)
                XCTAssertEqual(self.sut.currentUser?.username, "rakesh")
                exp.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [exp], timeout: 1.0)
    }

    func test_loginPublisherSimulatedDelay_invalidCredentials_failsWithInvalidCredentials() {
        let exp = expectation(description: "login fails with invalid credentials")

        sut.loginPublisherSimulatedDelay(username: "", password: "")
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    guard let authError = error as? AuthError else {
                        XCTFail("Unexpected error type: \(error)")
                        return
                    }
                    XCTAssertEqual(authError, AuthError.invalidCredentials)
                    exp.fulfill()
                }
            }, receiveValue: { _ in
                XCTFail("Expected failure, got value")
            })
            .store(in: &cancellables)

        wait(for: [exp], timeout: 1.0)
    }

    // MARK: - logoutPublisher

    func test_logoutPublisher_clearsCurrentUser_andEmitsCompletion() {
        let loginExp = expectation(description: "login completes")
        let logoutExp = expectation(description: "logout completes")

        // First log in
        sut.loginPublisherSimulatedDelay(username: "rakesh", password: "secret")
            .sink(receiveCompletion: { _ in
                loginExp.fulfill()
            }, receiveValue: { _ in })
            .store(in: &cancellables)

        wait(for: [loginExp], timeout: 1.0)
        XCTAssertNotNil(sut.currentUser)

        // Then logout
        sut.logoutPublisher()
            .sink(receiveCompletion: { _ in
                logoutExp.fulfill()
            }, receiveValue: { _ in })
            .store(in: &cancellables)

        wait(for: [logoutExp], timeout: 1.0)
        XCTAssertNil(sut.currentUser)
    }
}

// MARK: - Helpers for URLSession mocking (retained for potential future network tests)

import Foundation

func makeMockedSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: config)
}

final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("MockURLProtocol.requestHandler not set.")
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {
        // No-op
    }
}
