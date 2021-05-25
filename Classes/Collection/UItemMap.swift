//
//  Created by Антон Лобанов on 23.05.2021.
//

public protocol AnyItemMap {
    var count: Int { get }
    func allItems() -> [USectionBodyItemable]
    func item(at index: Int) -> USectionBodyItemable?
    func subscribeToChanges(_ handler: @escaping () -> Void)
}

public final class UItemMap<Item: Hashable> {
    public typealias BuildHandler = (Int, Item) -> USectionBodyItemable
    public typealias BuildSimpleHandler = () -> USectionBodyItemable

    let items: State<[Item]>
    let block: BuildHandler

    public init (_ items: [Item], @CollectionBuilder<USectionBodyItemable> block: @escaping BuildHandler) {
        self.items = State(wrappedValue: items)
        self.block = block
    }

    public init (_ items: State<[Item]>, @CollectionBuilder<USectionBodyItemable> block: @escaping BuildHandler) {
        self.items = items
        self.block = block
    }

    // ...

    public init (_ items: [Item], @CollectionBuilder<USectionBodyItemable> block: @escaping BuildSimpleHandler) {
        self.items = State(wrappedValue: items)
        self.block = { _, _ in
            block()
        }
    }

    public init (_ items: State<[Item]>, @CollectionBuilder<USectionBodyItemable> block: @escaping BuildSimpleHandler) {
        self.items = items
        self.block = { _, _ in
            block()
        }
    }

    // ...

    public init<T: Hashable>(
        _ first: State<T>,
        @CollectionBuilder<USectionItemable> block: @escaping (T) -> USectionBodyItemable
    ) where Item == Int {
        let states: [AnyState] = [first]
        self.items = states.map { [0] }
        self.block = { _, _ in
            block(first.wrappedValue)
        }
    }

    public init<T: Hashable, V: Hashable>(
        _ first: State<T>,
        _ second: State<V>,
        @CollectionBuilder<USectionItemable> block: @escaping (T, V) -> USectionBodyItemable
    ) where Item == Int {
        let states: [AnyState] = [first, second]
        self.items = states.map { [0] }
        self.block = { _, _ in
            block(first.wrappedValue, second.wrappedValue)
        }
    }

    public init<T: Hashable, V: Hashable, A: Hashable>(
        _ first: State<T>,
        _ second: State<V>,
        _ third: State<A>,
        @CollectionBuilder<USectionItemable> block: @escaping (T, V, A) -> USectionBodyItemable
    ) where Item == Int {
        let states: [AnyState] = [first, second, third]
        self.items = states.map { [0] }
        self.block = { _, _ in
            block(first.wrappedValue, second.wrappedValue, third.wrappedValue)
        }
    }
}

extension UItemMap: AnyItemMap {
    public var count: Int {
        self.items.wrappedValue.count
    }
    
    public func allItems() -> [USectionBodyItemable] {
        self.items.wrappedValue.enumerated().map {
            self.block($0.offset, $0.element)
        }
    }
    
    public func item(at index: Int) -> USectionBodyItemable? {
        guard index < self.items.wrappedValue.count else { return nil }
        return self.block(index, self.items.wrappedValue[index])
    }
    
    public func subscribeToChanges(_ handler: @escaping () -> Void) {
        self.items.removeAllListeners()
        self.items.listen { $0 != $1 ? handler() : () }
    }
}

extension UItemMap: USectionBodyItemable {
    public var identifier: AnyHashable { self.items.wrappedValue }
    public var sectionBodyItem: USectionBodyItem { .map(self) }
}
