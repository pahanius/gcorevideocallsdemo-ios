
# Change Log

<!-- ## [2.2] - 2021-12-28 -->

<!-- ## SDK -->
<!-- ### Added -->
<!-- ### Changed -->
<!-- ### Fixed -->

<!-- ## Demo приложение -->
<!-- ### Added -->
<!-- ### Changed -->
<!-- ### Fixed -->

## [2.2] - 2021-12-28

## SDK

---

### Fixed

- Xcode 13 compatible
 
---

## [2.1] - 2021-08-19

## SDK

---
 
### Added

- *RoomListener protocol*

Добавлены 2 новых метода. На них можно вешать индикатор загрузки при переподключении SDK к серверам (Например, при прерывании работы приложения из-за поступившего звонка)

|Метод|Описание|
|-|-|
|roomClientStartToConnectWithServices()|Подключение SDK к сервисам.<br>Можно запустить лоадре загрузки|
|roomClientSuccessfullyConnectWithServices()|SDK успешно подключён к сервисам<br>Можно убрать лоадер загрузки|

- *GCoreRoomLogger*

Добавлено замыкание `log: ((_ message: String) -> Void)?`, которое возвращает логи от SDK

```swift
GCoreRoomLogger.log = { [weak self] message in
    print(message)
}
```
 
### Fixed

- audio stream works when the app did collapsed by the user
- reconnection to the room, if the app interapted by the phone call

## Demo приложение

---

### Added

- Вью для показа логов от SDK
- Работа в фоне + переподключение при звонке