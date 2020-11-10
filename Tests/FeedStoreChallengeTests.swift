//
//  Copyright © 2019 Essential Developer. All rights reserved.
//

import XCTest
import FeedStoreChallenge
import CoreData


final class FailableManagedObjectContext: NSManagedObjectContext {
    
    private let allowFetch: Bool
    
    init(concurrencyType ct: NSManagedObjectContextConcurrencyType, allowFetch: Bool) {
        self.allowFetch = allowFetch
        super.init(concurrencyType: ct)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var hasChanges: Bool {
        true
    }
    
    override func fetch(_ request: NSFetchRequest<NSFetchRequestResult>) throws -> [Any] {
        if allowFetch {
            return []
        }
        throw anyNSError()
    }
    
    
    
    override func save() throws {
        throw anyNSError()
    }
    
    private func anyNSError() -> NSError {
        NSError(domain: "any error", code: NSPersistentStoreOperationError, userInfo: nil)
    }
    
}

final class FailablePersistentStoreCoordinator: NSPersistentStoreCoordinator {
    
    override func execute(_ request: NSPersistentStoreRequest, with context: NSManagedObjectContext) throws -> Any {
        throw anyNSError()
    }
    
    private func anyNSError() -> NSError {
        NSError(domain: "any error", code: NSPersistentStoreOperationError, userInfo: nil)
    }
    
}

protocol CoreDataStack {
    
    var managedContext: NSManagedObjectContext { get }
    
    init(storeURL: URL)

    func deleteAll(of entityName: String, context: NSManagedObjectContext) -> Error?
    func saveContext(context: NSManagedObjectContext) -> Error?
    
}

final class ProductionCoreDataStack: CoreDataStack {
    
    lazy var managedContext: NSManagedObjectContext = {
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
        return NSManagedObjectModel.mergedModel(from: [Bundle(for: ProductionCoreDataStack.self)])!
    }()
    
    private let storeURL: URL
    
    init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    func deleteAll(of entityName: String, context: NSManagedObjectContext) -> Error? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try persistentStoreCoordinator?.execute(deleteRequest, with: context)
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


final class FailableCoreDataStack: CoreDataStack {
    
    lazy var managedContext: NSManagedObjectContext = {
        var managedObjectContext = FailableManagedObjectContext(concurrencyType: .privateQueueConcurrencyType, allowFetch: allowFetch)
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        return managedObjectContext
    }()
    
    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        var coordinator: NSPersistentStoreCoordinator? = FailablePersistentStoreCoordinator(managedObjectModel: managedObjectModel)
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
        return NSManagedObjectModel.mergedModel(from: [Bundle(for: ProductionCoreDataStack.self)])!
    }()
    
    private let storeURL: URL
    private let allowFetch: Bool
    
    init(storeURL: URL) {
        self.storeURL = storeURL
        allowFetch = false
    }
    
    init(storeURL: URL, allowFetch: Bool) {
        self.storeURL = storeURL
        self.allowFetch = allowFetch
    }
    
    func deleteAll(of entityName: String, context: NSManagedObjectContext) -> Error? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try persistentStoreCoordinator?.execute(deleteRequest, with: context)
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
            
            let error = coreDataStack.saveContext(context: managedContext)
            completion(error)
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
	
    private func makeSUT(storeURL: URL? = nil, coreDataStack: CoreDataStack? = nil) -> FeedStore {
        let url = storeURL ?? testSpecificStoreURL()
        let coreDataStack = coreDataStack ?? ProductionCoreDataStack(storeURL: url)
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
