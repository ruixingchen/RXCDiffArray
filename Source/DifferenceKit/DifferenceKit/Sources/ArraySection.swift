/// A differentiable section with model and array of elements.
///
/// Arrays are can not be identify each one and comparing whether has updated from other one.
/// ArraySection is a generic wrapper to hold a model to allow it.
public struct ArraySection<Model: Differentiable, Element: Differentiable>: DifferentiableSection {

    /// The model of section for differentiated with other section.
    public var model: Model
    /// The array of element in the section.
    public var _elements: [Element]
    public var elements: [Differentiable] {
        get {
            return self._elements
        }
        set {
            self._elements = newValue as! [Element]
        }
    }

    /// An identifier value that of model for difference calculation.
    @inlinable
    public var differenceIdentifier: Model.DifferenceIdentifier {
        return model.differenceIdentifier
    }

    /// Creates a section with the model and the elements.
    ///
    /// - Parameters:
    ///   - model: A differentiable model of section.
    ///   - elements: The collection of element in the section.
    @inlinable
    public init<C: Collection>(model: Model, elements: C) where C.Element == Element {
        self.model = model
        self._elements = Array(elements)
    }

    /// Creates a new section reproducing the given source section with replacing the elements.
    ///
    /// - Parameters:
    ///   - source: A source section to reproduce.
    ///   - elements: The collection of elements for the new section.
    @inlinable
    public init<C>(source: DifferentiableSection, elements: C) where C : Collection, C.Element == Differentiable {
        guard let s = source as? ArraySection<Model, Element> else {
            fatalError("invalid source type")
        }
        self.init(model: s.model, elements: elements.map({$0 as! Element}))
    }

    /// Indicate whether the content of `self` is equals to the content of
    /// the given source section.
    ///
    /// - Note: It's compared by the model of `self` and the specified section.
    ///
    /// - Parameters:
    ///   - source: A source section to compare.
    ///
    /// - Returns: A Boolean value indicating whether the content of `self` is equals
    ///            to the content of the given source section.
    @inlinable
    public func isContentEqual(to source: Any) -> Bool {
        if let s = source as? ArraySection {
            return model.isContentEqual(to: s.model)
        }
        return false
    }
}

//extension ArraySection: Equatable where Model: Equatable, Element: Equatable {
//    public static func == (lhs: ArraySection, rhs: ArraySection) -> Bool {
//        return lhs.model == rhs.model && lhs.elements == rhs.elements
//    }
//}

extension ArraySection: CustomDebugStringConvertible {
    public var debugDescription: String {
        return """
        ArraySection(
            model: \(model),
            elements: \(elements)
        )
        """
    }
}
