import Foundation
import CoreData

// Core Data stack for persisting workout sessions and repetition logs
class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        let model = Self.managedObjectModel()
        container = NSPersistentContainer(name: "WorkoutModel", managedObjectModel: model)
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unresolved error \(error)")
            }
        }
    }

    static func managedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // WorkoutSession entity
        let sessionEntity = NSEntityDescription()
        sessionEntity.name = "WorkoutSession"
        sessionEntity.managedObjectClassName = String(describing: WorkoutSession.self)

        let sId = NSAttributeDescription()
        sId.name = "id"
        sId.attributeType = .UUIDAttributeType
        sId.isOptional = false

        let sStart = NSAttributeDescription()
        sStart.name = "startTime"
        sStart.attributeType = .dateAttributeType
        sStart.isOptional = false

        let sEnd = NSAttributeDescription()
        sEnd.name = "endTime"
        sEnd.attributeType = .dateAttributeType
        sEnd.isOptional = true

        let sExercise = NSAttributeDescription()
        sExercise.name = "exerciseType"
        sExercise.attributeType = .stringAttributeType
        sExercise.isOptional = false

        let repsRelation = NSRelationshipDescription()
        repsRelation.name = "repetitions"
        repsRelation.deleteRule = .cascadeDeleteRule
        repsRelation.minCount = 0
        repsRelation.maxCount = 0

        sessionEntity.properties = [sId, sStart, sEnd, sExercise, repsRelation]

        // RepetitionLog entity
        let repEntity = NSEntityDescription()
        repEntity.name = "RepetitionLog"
        repEntity.managedObjectClassName = String(describing: RepetitionLog.self)

        let rId = NSAttributeDescription()
        rId.name = "id"
        rId.attributeType = .UUIDAttributeType
        rId.isOptional = false

        let rStart = NSAttributeDescription()
        rStart.name = "startTime"
        rStart.attributeType = .doubleAttributeType
        rStart.isOptional = false

        let rEnd = NSAttributeDescription()
        rEnd.name = "endTime"
        rEnd.attributeType = .doubleAttributeType
        rEnd.isOptional = false

        let rConfidence = NSAttributeDescription()
        rConfidence.name = "confidence"
        rConfidence.attributeType = .floatAttributeType
        rConfidence.isOptional = false

        let sessionRelation = NSRelationshipDescription()
        sessionRelation.name = "session"
        sessionRelation.destinationEntity = sessionEntity
        sessionRelation.minCount = 1
        sessionRelation.maxCount = 1
        sessionRelation.deleteRule = .nullifyDeleteRule
        sessionRelation.inverseRelationship = repsRelation

        repsRelation.destinationEntity = repEntity
        repsRelation.inverseRelationship = sessionRelation

        repEntity.properties = [rId, rStart, rEnd, rConfidence, sessionRelation]

        model.entities = [sessionEntity, repEntity]
        return model
    }

    var context: NSManagedObjectContext {
        container.viewContext
    }

    func save() {
        if context.hasChanges {
            try? context.save()
        }
    }
}

@objc(WorkoutSession)
public class WorkoutSession: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var startTime: Date
    @NSManaged public var endTime: Date?
    @NSManaged public var exerciseType: String
    @NSManaged public var repetitions: Set<RepetitionLog>?
}

@objc(RepetitionLog)
public class RepetitionLog: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var startTime: Double
    @NSManaged public var endTime: Double
    @NSManaged public var confidence: Float
    @NSManaged public var session: WorkoutSession
}

class SessionManager {
    enum State { case idle, running, paused, ended }
    private(set) var state: State = .idle
    private let persistence: PersistenceController
    private var session: WorkoutSession?
    private var pauseStart: Date?

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }

    func startSession(exerciseType: String) {
        guard state == .idle else { return }
        let ctx = persistence.context
        let newSession = WorkoutSession(context: ctx)
        newSession.id = UUID()
        newSession.startTime = Date()
        newSession.exerciseType = exerciseType
        session = newSession
        persistence.save()
        state = .running
    }

    func pauseSession() {
        guard state == .running else { return }
        pauseStart = Date()
        state = .paused
    }

    func resumeSession() {
        guard state == .paused else { return }
        pauseStart = nil
        state = .running
    }

    func endSession() {
        guard state == .running || state == .paused else { return }
        session?.endTime = Date()
        persistence.save()
        session = nil
        state = .ended
    }

    func logRepetition(startOffset: TimeInterval, endOffset: TimeInterval, confidence: Float) {
        guard let session = session, state == .running else { return }
        let ctx = persistence.context
        let log = RepetitionLog(context: ctx)
        log.id = UUID()
        log.startTime = startOffset
        log.endTime = endOffset
        log.confidence = confidence
        log.session = session
        session.mutableSetValue(forKey: "repetitions").add(log)
        persistence.save()
    }
}
