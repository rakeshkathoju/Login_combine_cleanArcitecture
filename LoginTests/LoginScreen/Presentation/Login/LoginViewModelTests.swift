import XCTest
import Combine
@testable import Login

final class LoginViewModelTests: XCTestCase {
    func test_login_withEmptyCredentials_setsErrorAndDoesNotCallOnSuccess() {
        let useCase = MockLoginUseCase()
        var onSuccessCalled = false
        let viewModel = LoginViewModel(loginUseCase: useCase) { _ in
            onSuccessCalled = true
        }

        viewModel.username = ""
        viewModel.password = ""

        viewModel.login()

        XCTAssertNotNil(viewModel.error)
        XCTAssertFalse(onSuccessCalled)
    }
}

private final class MockLoginUseCase: LoginUseCase {
    func execute(username: String, password: String) -> AnyPublisher<User, Error> {
        return Empty<User, Error>().eraseToAnyPublisher()
    }
}
