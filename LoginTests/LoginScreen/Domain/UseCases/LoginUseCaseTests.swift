import XCTest
import Combine
@testable import Login


final class MockAuthRepository: AuthRepository {
    // Inputs captured for verification
    private(set) var receivedUsername: String?
    private(set) var receivedPassword: String?
    private(set) var callCount: Int = 0

    // Configurable outputs
    var result: Result<User, Error> = .failure(AuthError.serverError)

    func loginPublisher(username: String, password: String) -> AnyPublisher<User, Error> {
        callCount += 1
        receivedUsername = username
        receivedPassword = password

        return Future<User, Error> { [result] promise in
            switch result {
            case .success(let user):
                promise(.success(user))
            case .failure(let error):
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }

    func logoutPublisher() -> AnyPublisher<Void, Never> {
        Just(()).eraseToAnyPublisher()
    }

    var currentUser: User? { nil }
    var currentUserPublisher: AnyPublisher<User?, Never> {
        Just(nil).eraseToAnyPublisher()
    }
}

// MARK: - Tests

final class DefaultLoginUseCaseTests: XCTestCase {

    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables = []
        super.tearDown()
    }

    func test_execute_returnsUserOnSuccess() {
        // Arrange
        let expectedUser = User(id: UUID(), username: "rakesh")
        let mockRepo = MockAuthRepository()
        mockRepo.result = .success(expectedUser)
        let sut = DefaultLoginUseCase(repository: mockRepo)
        let exp = expectation(description: "execute completes")

        // Act
        sut.execute(username: "rakesh", password: "secret")
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Expected success, got failure: \(error)")
                }
            }, receiveValue: { user in
                // Assert
                XCTAssertEqual(user, expectedUser, "Should return the user from repository")
                XCTAssertEqual(mockRepo.callCount, 1, "Repository should be called exactly once")
                XCTAssertEqual(mockRepo.receivedUsername, "rakesh")
                XCTAssertEqual(mockRepo.receivedPassword, "secret")
                exp.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [exp], timeout: 1.0)
    }

    func test_execute_propagatesInvalidCredentialsError() {
        // Arrange
        let mockRepo = MockAuthRepository()
        mockRepo.result = .failure(AuthError.invalidCredentials)
        let sut = DefaultLoginUseCase(repository: mockRepo)
        let exp = expectation(description: "execute fails with invalid credentials")

        // Act
        sut.execute(username: "", password: "")
            .sink(receiveCompletion: { completion in
                if case .failure(let error as AuthError) = completion {
                    // Assert
                    XCTAssertEqual(error, .invalidCredentials)
                    XCTAssertEqual(mockRepo.callCount, 1)
                    exp.fulfill()
                }
            }, receiveValue: { _ in
                XCTFail("Expected failure, got value")
            })
            .store(in: &cancellables)

        wait(for: [exp], timeout: 1.0)
    }

    func test_execute_propagatesServerError() {
        // Arrange
        let mockRepo = MockAuthRepository()
        mockRepo.result = .failure(AuthError.serverError)
        let sut = DefaultLoginUseCase(repository: mockRepo)
        let exp = expectation(description: "execute fails with server error")

        // Act
        sut.execute(username: "user", password: "pass")
            .sink(receiveCompletion: { completion in
                if case .failure(let error as AuthError) = completion {
                    // Assert
                    XCTAssertEqual(error, .serverError)
                    XCTAssertEqual(mockRepo.callCount, 1)
                    exp.fulfill()
                }
            }, receiveValue: { _ in
                XCTFail("Expected failure, got value")
            })
            .store(in: &cancellables)

        wait(for: [exp], timeout: 1.0)
    }

    func test_execute_forwardsParametersToRepository() {
        // Arrange
        let mockRepo = MockAuthRepository()
        let expectedUser = User(id: UUID(), username: "paramCheck")
        mockRepo.result = .success(expectedUser)
        let sut = DefaultLoginUseCase(repository: mockRepo)
        let exp = expectation(description: "execute completes")

        // Act
        sut.execute(username: "paramCheck", password: "p@ss")
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Expected success, got failure: \(error)")
                }
            }, receiveValue: { _ in
                exp.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [exp], timeout: 1.0)

        // Assert
        XCTAssertEqual(mockRepo.receivedUsername, "paramCheck")
        XCTAssertEqual(mockRepo.receivedPassword, "p@ss")
    }
}
