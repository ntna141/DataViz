@objc(LevelEntity)
public class LevelEntity: NSManagedObject {
    @NSManaged public var uuid: UUID?
    @NSManaged public var number: Int32
    @NSManaged public var topic: String?
    @NSManaged public var desc: String?
    @NSManaged public var requiredStars: Int32
    @NSManaged public var isUnlocked: Bool
    @NSManaged public var questions: NSSet?
    @NSManaged public var attempts: NSSet?
} 