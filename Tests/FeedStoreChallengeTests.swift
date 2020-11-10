//
//  Copyright © 2019 Essential Developer. All rights reserved.
//

import XCTest
import FeedStoreChallenge
import CoreData


final class ErrorManagedObjectContext: NSManagedObjectContext {
    
    override func fetch(_ request: NSFetchRequest<NSFetchRequestResult>) throws -> [Any] {
        throw anyNSError()
    }
    
    private func anyNSError() -> NSError {
        NSError(domain: "any error", code: NSPersistentStoreOperationError, userInfo: nil)
    }
    
}

struct PersistentStoreDescription {
    
    let storeClass: AnyClass
    let storeType: String
    
}

final class CoreDataStack {
    
    lazy var managedContext: NSManagedObjectContext = {
        if let context = managedObjectContext {
            context.persistentStoreCoordinator = persistentStoreCoordinator
            return context
        }
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        return managedObjectContext
    }()
    
    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        let storeOptions = [NSMigratePersistentStoresAutomaticallyOption : true,
                            NSInferMappingModelAutomaticallyOption : true
        ]

        do {
            try coordinator!.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: storeOptions)
        } catch {
            coordinator = nil
            print("Unresolved error \(error)")
            abort()
        }
        return coordinator
    }()
    
    private lazy var managedObjectModel: NSManagedObjectModel = {
        return NSManagedObjectModel.mergedModel(from: [Bundle(for: CoreDataStack.self)])!
    }()
    
    private let storeURL: URL
    
    private let managedObjectContext: NSManagedObjectContext?
    
    init(storeURL: URL, context: NSManagedObjectContext? = nil) {
        self.storeURL = storeURL
        managedObjectContext = context
    }
    
    func deleteAll(of entityName: String, context: NSManagedObjectContext? = nil) -> Error? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try persistentStoreCoordinator?.execute(deleteRequest, with: context ?? managedContext)
            return nil
        } catch {
            return error
        }
    }
    
    @discardableResult
    func saveContext(context: NSManagedObjectContext) -> Error? {
        if !context.hasChanges {
            return nil
        }
        do {
            try context.save()
            return nil
        } catch {
            return error
        }
    }
    
}


final class FeedMapper {
    
    private let feed: Set<CDFeedImage>
    
    init(feed: Set<CDFeedImage>) {
        self.feed = feed
    }
    
    func map() -> [LocalFeedImage] {
        mapLocalsToModels(sort(feed))
    }
    
    private func sort(_ feed: Set<CDFeedImage>) -> [CDFeedImage] {
        feed.sorted { (firstFeedImage, secondFeedImage) -> Bool in
            firstFeedImage.position < secondFeedImage.position
        }
    }
    
    private func mapLocalsToModels(_ feed: [CDFeedImage]) -> [LocalFeedImage] {
        feed.map { cdFeedImage -> LocalFeedImage in
            LocalFeedImage(id: cdFeedImage.id,
                           description: cdFeedImage.desc,
                           location: cdFeedImage.location,
                           url: cdFeedImage.url
            )
        }
    }
    
}


extension NSManagedObject {
    
    static var entityName: String {
        String(describing: Self.self)
    }
    
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: Self.entity(), insertInto: context)
    }
    
}

final class CoreDataFeedStore: FeedStore {
    
    private var managedContext: NSManagedObjectContext {
        coreDataStack.managedContext
    }
    
    private let coreDataStack: CoreDataStack
    
    init(coreDataStack: CoreDataStack) {
        self.coreDataStack = coreDataStack
    }
    
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        managedContext.perform { [unowned self] in
            let error = deleteCaches()
            completion(error)
        }
    }
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        managedContext.perform { [unowned self] in
            deleteCaches()
            
            let cdCache = CDCache(context: managedContext)
            cdCache.timestamp = timestamp
            
            for (index, feedImage) in feed.enumerated() {
                let cdFeedImage = CDFeedImage(context: managedContext)
                cdFeedImage.id = feedImage.id
                cdFeedImage.desc = feedImage.description
                cdFeedImage.location = feedImage.location
                cdFeedImage.url = feedImage.url
                cdFeedImage.position = Int16(index)
                cdCache.addToFeed(cdFeedImage)
            }
            
            coreDataStack.saveContext(context: managedContext)
            completion(nil)
        }
    }
    
    func retrieve(completion: @escaping RetrievalCompletion) {
        let fetchRequest: NSFetchRequest<CDCache> = CDCache.fetchRequest()
        do {
            let cdCaches = try managedContext.fetch(fetchRequest)
            if let cdCache = cdCaches.first {
                let feed = FeedMapper(feed: cdCache.feed).map()
                completion(.found(feed: feed, timestamp: cdCache.timestamp))
            } else {
                completion(.empty)
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    @discardableResult
    private func deleteCaches() -> Error? {
        coreDataStack.deleteAll(of: CDCache.entityName, context: managedContext)
    }
    
}


class FeedStoreChallengeTests: XCTestCase, FeedStoreSpecs {
	
    //  ***********************
    //
    //  Follow the TDD process:
    //
    //  1. Uncomment and run one test at a time (run tests with CMD+U).
    //  2. Do the minimum to make the test pass and commit.
    //  3. Refactor if needed and commit again.
    //
    //  Repeat this process until all tests are passing.
    //
    //  ***********************
    
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
	
    private func makeSUT(storeURL: URL? = nil, context: NSManagedObjectContext? = nil) -> FeedStore {
        let url = storeURL ?? testSpecificStoreURL()
        let coreDataStack = CoreDataStack(storeURL: url, context: context)
        let sut = CoreDataFeedStore(coreDataStack: coreDataStack)
        
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
	
}

//  ***********************
//
//  Uncomment the following tests if your implementation has failable operations.
//
//  Otherwise, delete the commented out code!
//
//  ***********************

extension FeedStoreChallengeTests: FailableRetrieveFeedStoreSpecs {

	func test_retrieve_deliversFailureOnRetrievalError() {
        let sut = makeSUT(context: anyErrorManagedObjectContext())

		assertThatRetrieveDeliversFailureOnRetrievalError(on: sut)
	}

	func test_retrieve_hasNoSideEffectsOnFailure() {
		let sut = makeSUT(context: anyErrorManagedObjectContext())

		assertThatRetrieveHasNoSideEffectsOnFailure(on: sut)
	}
    
    private func anyErrorManagedObjectContext() -> NSManagedObjectContext {
        ErrorManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    }

}

//extension FeedStoreChallengeTests: FailableInsertFeedStoreSpecs {
//
//	func test_insert_deliversErrorOnInsertionError() {
////		let sut = makeSUT()
////
////		assertThatInsertDeliversErrorOnInsertionError(on: sut)
//	}
//
//	func test_insert_hasNoSideEffectsOnInsertionError() {
////		let sut = makeSUT()
////
////		assertThatInsertHasNoSideEffectsOnInsertionError(on: sut)
//	}
//
//}

//extension FeedStoreChallengeTests: FailableDeleteFeedStoreSpecs {
//
//	func test_delete_deliversErrorOnDeletionError() {
////		let sut = makeSUT()
////
////		assertThatDeleteDeliversErrorOnDeletionError(on: sut)
//	}
//
//	func test_delete_hasNoSideEffectsOnDeletionError() {
////		let sut = makeSUT()
////
////		assertThatDeleteHasNoSideEffectsOnDeletionError(on: sut)
//	}
//
//}
