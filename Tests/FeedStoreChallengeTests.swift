//
//  Copyright © 2019 Essential Developer. All rights reserved.
//

import XCTest
import FeedStoreChallenge
import CoreData


class FeedStoreChallengeTests: XCTestCase, FeedStoreSpecs {
	
    override func setUp() {
        super.setUp()
        
        setupEmptyStoreState()
    }

	func test_retrieve_deliversEmptyOnEmptyCache() {
		let sut = makeSUT()

		assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
	}

	func test_retrieve_hasNoSideEffectsOnEmptyCache() {
		let sut = makeSUT()

		assertThatRetrieveHasNoSideEffectsOnEmptyCache(on: sut)
	}

	func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
		let sut = makeSUT()

		assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
	}

	func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
		let sut = makeSUT()

		assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on: sut)
	}

	func test_insert_deliversNoErrorOnEmptyCache() {
		let sut = makeSUT()

		assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
	}

	func test_insert_deliversNoErrorOnNonEmptyCache() {
		let sut = makeSUT()

		assertThatInsertDeliversNoErrorOnNonEmptyCache(on: sut)
	}

	func test_insert_overridesPreviouslyInsertedCacheValues() {
		let sut = makeSUT()

		assertThatInsertOverridesPreviouslyInsertedCacheValues(on: sut)
	}

	func test_delete_deliversNoErrorOnEmptyCache() {
		let sut = makeSUT()

		assertThatDeleteDeliversNoErrorOnEmptyCache(on: sut)
	}

	func test_delete_hasNoSideEffectsOnEmptyCache() {
		let sut = makeSUT()

		assertThatDeleteHasNoSideEffectsOnEmptyCache(on: sut)
	}

	func test_delete_deliversNoErrorOnNonEmptyCache() {
		let sut = makeSUT()

		assertThatDeleteDeliversNoErrorOnNonEmptyCache(on: sut)
	}

	func test_delete_emptiesPreviouslyInsertedCache() {
		let sut = makeSUT()

		assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
	}

	func test_storeSideEffects_runSerially() {
		let sut = makeSUT()

		assertThatSideEffectsRunSerially(on: sut)
	}
	
	// - MARK: Helpers
	
    private func makeSUT(storeURL: URL? = nil, coreDataStack: CoreDataStack? = nil, file: StaticString = #file, line: UInt = #line) -> FeedStore {
        let url = storeURL ?? testSpecificStoreURL()
        let coreDataStack = coreDataStack ?? ProductionCoreDataStack(storeURL: url)
        let sut = CoreDataFeedStore(coreDataStack: coreDataStack)
        tracksForMemoryLeaks(sut, file: file, line: line)
        return sut
	}
    
    private func setupEmptyStoreState() {
        deleteStoreFile()
    }
    
    private func deleteStoreFile() {
        _ = try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
    
    private func testSpecificStoreURL() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("FeedStoreModel.store")
    }
    
    private func failableCoreDataStack(allowFetch: Bool = false) -> CoreDataStack {
        FailableCoreDataStack(storeURL: testSpecificStoreURL(), allowFetch: allowFetch)
    }
	
}

extension FeedStoreChallengeTests: FailableRetrieveFeedStoreSpecs {

	func test_retrieve_deliversFailureOnRetrievalError() {
        let sut = makeSUT(coreDataStack: failableCoreDataStack())

		assertThatRetrieveDeliversFailureOnRetrievalError(on: sut)
	}

	func test_retrieve_hasNoSideEffectsOnFailure() {
		let sut = makeSUT(coreDataStack: failableCoreDataStack())

		assertThatRetrieveHasNoSideEffectsOnFailure(on: sut)
	}

}

extension FeedStoreChallengeTests: FailableInsertFeedStoreSpecs {

	func test_insert_deliversErrorOnInsertionError() {
        let sut = makeSUT(coreDataStack: failableCoreDataStack())

		assertThatInsertDeliversErrorOnInsertionError(on: sut)
	}

	func test_insert_hasNoSideEffectsOnInsertionError() {
        let sut = makeSUT(coreDataStack: failableCoreDataStack(allowFetch: true))

		assertThatInsertHasNoSideEffectsOnInsertionError(on: sut)
	}

}

extension FeedStoreChallengeTests: FailableDeleteFeedStoreSpecs {

	func test_delete_deliversErrorOnDeletionError() {
		let sut = makeSUT(coreDataStack: failableCoreDataStack())

		assertThatDeleteDeliversErrorOnDeletionError(on: sut)
	}

	func test_delete_hasNoSideEffectsOnDeletionError() {
		let sut = makeSUT(coreDataStack: failableCoreDataStack(allowFetch: true))

		assertThatDeleteHasNoSideEffectsOnDeletionError(on: sut)
	}

}
