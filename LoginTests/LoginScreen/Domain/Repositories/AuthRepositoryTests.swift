// AuthRepositoryContractTests.swift (Test target)

import XCTest
import Combine
@testable import Login

final class AuthRepositoryContractTests: XCTestCase {

    // MARK: - Factory to be overridden by subclasses
    func makeSUT() -> AuthRepository {
        fatalError("Subclasses must override makeSUT() to return a concrete AuthRepository")
    }

    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables = []
        super.tearDown()
    }

    // MARK: - Contract Tests

    func test_login_withValidCredentials_returnsUser_and_setsCurrentUser() {
        // Given
        let sut = makeSUT()
        let exp = expectation(description: "login completes")

        // When
        sut.loginPublisher(username: "alice", password: "password123")
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Expected success, got failure: \(error)")
                }
            }, receiveValue: { user in
                // Then
                XCTAssertEqual(user.username, "alice", "Returned user should match the login username.")
                XCTAssertEqual(sut.currentUser?.username, "alice", "currentUser should be set after successful login.")
                exp.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [exp], timeout: 1.0)
    }

    func test_login_withEmptyUsernameOrPassword_fails() {
        let sut = makeSUT()
        let exp1 = expectation(description: "empty username fails")
        let exp2 = expectation(description: "empty password fails")

        sut.loginPublisher(username: "", password: "some")
            .sink(receiveCompletion: { completion in
                if case .failure = completion { exp1.fulfill() }
            }, receiveValue: { _ in
                XCTFail("Expected failure for empty username")
            })
            .store(in: &cancellables)

        sut.loginPublisher(username: "some", password: "")
            .sink(receiveCompletion: { completion in
                if case .failure = completion { exp2.fulfill() }
            }, receiveValue: { _ in
                XCTFail("Expected failure for empty password")
            })
            .store(in: &cancellables)

        wait(for: [exp1, exp2], timeout: 1.0)
    }

    func test_logout_clearsCurrentUser() {
        let sut = makeSUT()
        let loginExp = expectation(description: "login completes")
        let logoutExp = expectation(description: "logout completes")

        sut.loginPublisher(username: "bob", password: "secret")
            .sink(receiveCompletion: { _ in
                loginExp.fulfill()
            }, receiveValue: { _ in })
            .store(in: &cancellables)

        wait(for: [loginExp], timeout: 1.0)
        XCTAssertNotNil(sut.currentUser, "currentUser should be non-nil after login")

        sut.logoutPublisher()
            .sink(receiveCompletion: { _ in
                logoutExp.fulfill()
            }, receiveValue: { _ in })
            .store(in: &cancellables)

        wait(for: [logoutExp], timeout: 1.0)
        XCTAssertNil(sut.currentUser, "currentUser should be nil after logout")
    }

    func test_currentUser_initially_nil() {
        let sut = makeSUT()
        XCTAssertNil(sut.currentUser, "currentUser should be nil before any successful login")
    }
}
