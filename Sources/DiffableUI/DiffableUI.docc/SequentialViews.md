# Table views, stack views and menus

Views that apply changes one call at a time.

## Two kinds of batch API

```
SIMULTANEOUS (UIKit, NSCollectionView)       SEQUENTIAL (NSTableView, NSOutlineView, NSMenu, stack views)
 deletes use OLD indexes                       every call is relative to the state
 inserts use NEW indexes                       left by the previous call
 moves go OLD -> NEW
```

`NSTableView`, `NSOutlineView`, `NSMenu`, `UIStackView` and `NSStackView` are sequential. ``SequentialPlan`` converts a diff into an ordered list of operations they can follow.

## A plan by hand

```swift
let changes = old.listChanges(to: new)
let plan = SequentialPlan(changes: changes, oldCount: old.count, newCount: new.count)

plan.perform(
    remove: { index in /* remove the item at index */ },
    insert: { index in /* insert new[index] at index */ },
    move: { from, to in /* move the item at from so it ends at to */ }
)
```

The plan removes first (highest index first), then walks the NEW indexes in order, inserting or moving so that each position is final:

```
 old: [ a  b  c  d ]      new: [ d  b  x ]      a, c deleted · x inserted · d moved to the front

 1. remove(2)                           [ a  b  d ]
    remove(0)                           [ b  d ]
 2. i=0 wants d, has b   -> move(1 -> 0)  [ d  b ]
    i=1 wants b, has b   -> nothing
    i=2 wants x (new)    -> insert(2)     [ d  b  x ]
```

Content updates are not part of the plan, because they do not change positions.

## NSTableView

```swift
tableView.applyDiff(from: rows, to: newRows) {
    self.rows = newRows
}
```

Inside, it runs `beginUpdates()`, the plan (`removeRows`, `insertRows`, `moveRow`), `endUpdates()`, and then reloads the updated rows in every column.

## UIStackView and NSStackView

The views are kept, created or dropped to follow your models:

```swift
stackView.applyDiff(
    from: oldBadges,
    to: newBadges,
    makeView: { badge in BadgeView(badge: badge) },
    update: { view, badge in view.badge = badge }
)
```

```
 models old: [ a  b  c ]        arrangedSubviews: [ Va Vb Vc ]
 models new: [ c  a  d ]

 remove(1)         [ Va Vc ]          Vb leaves the stack and the hierarchy
 move(1 -> 0)      [ Vc Va ]          Vc is reused, not recreated
 insert(2)         [ Vc Va Vd ]       makeView(d)
 updates           update(Vx, model)  for views whose model changed
```

`UIStackView` also accepts `animated:` and `duration:`.

## NSMenu

```swift
menu.applyDiff(
    from: oldCommands,
    to: newCommands,
    makeItem: { NSMenuItem(title: $0.title, action: #selector(run(_:)), keyEquivalent: "") },
    update: { item, command in item.title = command.title }
)
```

Untouched items keep their identity, so open submenus and key equivalents survive.

## UIMenu

`UIMenu` is immutable, so it can only be rebuilt. `replacingChildren(from:to:make:)` reuses the `UIMenuElement` of every model that did not change and builds only the new or edited ones:

```swift
menu = menu.replacingChildren(from: oldCommands, to: newCommands) { command in
    UIAction(title: command.title) { _ in run(command) }
}
```
