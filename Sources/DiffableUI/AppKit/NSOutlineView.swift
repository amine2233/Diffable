#if canImport(AppKit)
import AppKit
import DiffableTree

extension NSOutlineView {

    public func applay<T: DiffableTree>(_ operations: [DiffableTreeNode<T>], perform: Bool) {
        if perform {
            for operation in operations {

                switch operation.operation {
                    case .unchanged(_):
                        break
                    case .inserted(let parent, let at):
                        insertItems(at: IndexSet(integer: at), inParent: parent, withAnimation: [.effectFade])
                    case .updated(_, _):
                        break
                    case .deleted(let parent, let at):
                        removeItems(at: IndexSet(integer: at), inParent: parent, withAnimation: [.effectFade])
                }

                applay(operation.children, perform: perform)
            }
        } else {
            reloadData()
        }
    }
}

#endif
