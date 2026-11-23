# SPEC — Orders screen

**File:** `lib/presentation/orders_screen.dart`
**Widget:** `OrdersScreen`, with a required named parameter `orderRepository` of type `OrderRepository` (`lib/domain/order_repository.dart`).

Shows the titles returned by `OrderRepository.orderTitles()`, one per row.

## States

| State | When | Shows |
|-------|------|-------|
| Loading | the future has not completed | a `CircularProgressIndicator` |
| Empty | the list is empty | the text `No orders yet` |
| Error | the future throws | the text `Couldn't load orders` and a `Retry` button that calls `orderTitles()` again |
| Data | the list has items | one row per title |
