import Foundation

/// Describes set type
#if canImport(ObjectiveC)
@objcMembers
#endif
public final class SetType: NSObject, SourceryModel, Diffable {
    /// Type name used in declaration
    public var name: String

    /// Array element type name
    public var elementTypeName: TypeName

    // sourcery: skipEquality, skipDescription
    /// Array element type, if known
    public var elementType: Type?

    /// :nodoc:
    public init(name: String, elementTypeName: TypeName, elementType: Type? = nil) {
        self.name = name
        self.elementTypeName = elementTypeName
        self.elementType = elementType
    }

    /// Returns array as generic type
    public var asGeneric: GenericType {
        GenericType(name: "Set", typeParameters: [
            .init(typeName: elementTypeName)
        ])
    }

    public var asSource: String {
        "[\(elementTypeName.asSource)]"
    }

    /// :nodoc:
    override public var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "name = \(String(describing: self.name)), "
        string += "elementTypeName = \(String(describing: self.elementTypeName)), "
        string += "asGeneric = \(String(describing: self.asGeneric)), "
        string += "asSource = \(String(describing: self.asSource))"
        return string
    }

    public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? SetType else {
            results.append("Incorrect type <expected: SetType, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "name").trackDifference(actual: self.name, expected: castObject.name))
        results.append(contentsOf: DiffableResult(identifier: "elementTypeName").trackDifference(actual: self.elementTypeName, expected: castObject.elementTypeName))
        return results
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(self.name)
        hasher.combine(self.elementTypeName)
        return hasher.finalize()
    }

    /// :nodoc:
    public override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? SetType else { return false }
        if self.name != rhs.name { return false }
        if self.elementTypeName != rhs.elementTypeName { return false }
        return true
    }

// sourcery:inline:SetType.AutoCoding

        /// :nodoc:
        required public init?(coder aDecoder: NSCoder) {
            guard let name: String = aDecoder.decode(forKey: "name") else {
                withVaList(["name"]) { arguments in
                    NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: arguments)
                }
                fatalError()
             }; self.name = name
            guard let elementTypeName: TypeName = aDecoder.decode(forKey: "elementTypeName") else {
                withVaList(["elementTypeName"]) { arguments in
                    NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: arguments)
                }
                fatalError()
             }; self.elementTypeName = elementTypeName
            self.elementType = aDecoder.decode(forKey: "elementType")
        }

        /// :nodoc:
        public func encode(with aCoder: NSCoder) {
            aCoder.encode(self.name, forKey: "name")
            aCoder.encode(self.elementTypeName, forKey: "elementTypeName")
            aCoder.encode(self.elementType, forKey: "elementType")
        }
// sourcery:end
}
