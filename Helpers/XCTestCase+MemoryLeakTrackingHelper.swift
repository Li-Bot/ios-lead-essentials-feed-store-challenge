
import XCTest


extension XCTestCase {
    
    func tracksForMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated.", file: file, line: line)
        }
    }
    
}
