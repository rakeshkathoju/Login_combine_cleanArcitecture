import XCTest
@testable import Login

final class AppCoordinatorTests: XCTestCase {
    func test_init_withNoCurrentUser_setsRouteToLogin() {
        let coordinator = AppCoordinator()
        XCTAssertEqual(coordinator.route, .login)
    }
}
