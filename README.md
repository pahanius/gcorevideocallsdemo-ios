
# Системные требования
* Минимальная версия iOS: 12.1

# Интеграция Video calls SDK

## Импорт Video calls SDK и настройка проекта

1. Создаём новый проект
2. Устанавливаем зависимости Pod

	**Podfile**
	```ruby
	pod "mediasoup_ios_client", '1.5.3'
	```
	
3. Копируем `GCoreVideoCallsSDK.framework` в папку проекта
4. В таргете проекта в разделе **General -> Frameworks, Libraries, and Embedded Content** выставляем значение **Embed** на `Embed & Sign` для `GCoreVideoCallsSDK.framework` 
5. В **Build Settings** таргета устанавливаем `ENABLE_BITCODE = NO`
6. В **Build Settings** таргета устанавливаем `Validate Workspace = Yes`
7. В **Info.plist** добавляем описание для параметров **NSCameraUsageDescription** и **NSMicrophoneUsageDescription**

## Инициализация Video calls SDK

1. Импортируем зависимости

	```swift
	import GCoreVideoCallsSDK
	import WebRTC
	```	
	
3. Активируем логирование

	Вывод запросов на сервер и ответы сервера
	```swift
	GCoreRoomLogger.activateLogger()
	```
	
4. Определяем параметры для коннекта к серверу

	```swift
	let options = RoomOptions(cameraPosition: .front)
	
	let parameters = MeetRoomParametrs(
	    roomId: "serv01234",
	    displayName: "John Snow",
	    peerId: "user09876",
	    clientHostName: "studio.gvideo.co"
	)
	```
| Параметр| Тип | Описание| 
|--|--|--|
| roomId | String | Room ID to connect to<br>*Example:* `roomId: "serv01234"` |
|displayName | String | Set display name of participant<br>[Link for extra details in knowledge base](https://gcorelabs.com/support/articles/4404682043665/#h_01FBPQAEZZ1GR7SF7G7TBAYJWZ)<br>*Example:* `displayName: "John Snow"`|
| peerId | String? (optional) | ID of a participant from your internal system. Please specify userID if you have your own. Or just leave this field blank, then the value will be generated automatically.<br>[Link for extra details in knowledge base](https://gcorelabs.com/support/articles/4404682043665/#h_01FBPQC18B1E3K58C05A8E81Y7)<br>*Example:* `peerId: "user0000000001"`|
| clientHostName | String? (optional) | В данном параметре клиент передает то доменное имя, которое он использует для эксплуатации веб версии мита. Значение: только домен без указания протокола.<br>*Example:* `clientHostName: "meet.gcore.lu"`|
	
5. Создаём экземпляр объекта клиента и конектимся

	```swift
	var client: GCoreRoomClient?
	
	client = GCoreRoomClient(roomOptions: options, requestParameters: parameters, roomListener: self)

	try? client?.open()
	```
	
6. Активируем аудиосессию

	По умолчанию аудиосессией ([AVAudioSession](https://developer.apple.com/documentation/avfaudio/avaudiosession)) SDK управлять не умеет, чтобы включить базовый функционал, нужно вызвать метод активации аудиосессии. Будет активирована громкая связь при разговоре и переключение на наушники при их подключении. Если аудиосессию не активировать, источники звука и микрофона будут выбраны системой по умолчанию (скорее всего это будет разговорный динамик, который нужно прикладывать к уху и внешний микрофон)
	
	```swift
	client?.audioSessionActivate()
	```
	
7. Подписываемся на методы делегата `RoomListener`

	```swift
	///  Получена ошибка
	func  roomClientHandle(error: RoomError)

	///  Успешное соединение с серверу
	func  roomClientDidConnected()

	///  Переподключение к серверу
	func  roomClientReconnecting()

	///  Неудачное переподключение к серверу
	func  roomClientReconnectingFailed()

	///  Соединение с сервером разорвано
	func  roomClientSocketDidDisconnected(roomClient: GCoreRoomClient)
    
    /// Возвращает пиры, находящиеся в комнате в момент входа
    func roomClient(roomClient: GCoreRoomClient, joinWithPeersInRoom peers: [PeerObject])
    
    /// Пир вошёл в комнату
    func roomClient(roomClient: GCoreRoomClient, handlePeer: PeerObject)
    
    /// Пир вышел из комнаты
    func roomClient(roomClient: GCoreRoomClient, peerClosed: String)
    
    // Локальный пир
    /// Локальный видеопоток получен
    func roomClient(roomClient: GCoreRoomClient, produceLocalVideoTrack videoTrack: RTCVideoTrack)
    
    /// Локальный аудиопоток получен
    func roomClient(roomClient: GCoreRoomClient, produceLocalAudioTrack audioTrack: RTCAudioTrack)
    
    /// Был закрыт локальный видеопоток
    func roomClient(roomClient: GCoreRoomClient, didCloseLocalVideoTrack videoTrack: RTCVideoTrack?)
    
    /// Был закрыт локальный аудиопоток
    func roomClient(roomClient: GCoreRoomClient, didCloseLocalAudioTrack audioTrack: RTCAudioTrack?)

    // Внешние пиры
    /// Получен внешний видеопоток
    func roomClient(roomClient: GCoreRoomClient, handledRemoteVideo videoObject: VideoObject)
    
    /**
     Внешний ведопоток был закрыт
     - parameter byModerator Если пир вышел не сам, а его закрыл модератор
     */
    func roomClient(roomClient: GCoreRoomClient, didCloseRemoteVideoByModerator byModerator: Bool, videoObject: VideoObject)
    
    /// Получен внешний аудиопоток
    func roomClient(roomClient: GCoreRoomClient, produceRemoteAudio audioObject: AudioObject)
    
    /**
     Внешний аудиопоток был закрыт
     - parameter byModerator Если пир вышел не сам, а его закрыл модератор
     */
    func roomClient(roomClient: GCoreRoomClient, didCloseRemoteAudioByModerator byModerator: Bool, audioObject: AudioObject)
    
    /**
     В массиве приходит пир с активным микрофоном. Микрофон пира считается активным до тех пор
     пока не будет вызван этот же метод, в массиве которого не будет соответствующего пира
     - parameter peers массив Id у которых активен микрофон
     */
    func roomClient(roomClient: GCoreRoomClient, activeSpeakerPeers peers: [String])
    ```
    
8. Рекомендуемые надстройки после успешного подключения

	Метод `roomClientDidConnected` вызывается после успешного подключения к серверу. То есть мы зашли в комнату. Для последующего подключения видео и аудио, вызываем у клиента методы `toggleAudio(isOn: Bool)` и `toggleVideo(isOn: Bool)` соответственно
	
	```swift
   func roomClientDidConnected() {
		DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
			self.client?.toggleVideo(isOn: true)
			self.client?.toggleAudio(isOn: true)
		}
   }
	```
    
## Взаимодействие с клиентским приложением

### Пиры (участники)

1. При успешном коннекте, вызывается метод, который возвращает всех участников, находящихся в комнате, сохраняем их, рисуем элементы для отображения участников

	```swift
	func joinWithPeersInRoom(_ peers: [PeerObject]) {
		// Как пример, создание объекта пира и добавление нового вью в сетку ScrollView
		peers.forEach { peer in
			let remoteItem = GCLRemoteItem(peerObject: peer)
			remoteItems.insert(remoteItem)
			mainScrollView.addSubview(remoteItem.view)
		}
	}
	```

2. При входе в комнату нового участника,  так же добавляем его в массив подключённых участников и на сетку ScrollView соответственно

	```swift
	func handledPeer(_ peer: PeerObject) {
		let remoteItem = GCLRemoteItem(peerObject: peer)
		remoteItems.insert(remoteItem)
		mainScrollView.addSubview(remoteItem.view)
	}
	```
	
3. При отключении участника, удаляем его из массива

	```swift
	func peerClosed(_ peer: String) {
		if let remoteItem = remoteItems.first(where: { $0.peerId == peer }) {
			remoteItem.view.removeFromSuperview()
			remoteItems.remove(remoteItem)
		}
	}
	```

### Видеопотоки

1. Создаём RTCEAGLVideoView для отображения видеопотоков

	Создаём RTCEAGLVideoView для локального потока и массив вьюх для удалённого потока

	```swift
	private let localVideoView = RTCEAGLVideoView()
	
	struct RemoteVideoItem {
		let peerId: String
		let videoView: RTCEAGLVideoView
	}
	private var remoteItems = [RemoteVideoItem]()
	```
	
	Получаем локальный поток в методе делегата и передаём ему View для отображения видео

	```swift
	func roomClient(roomClient: GCoreRoomClient, produceLocalVideoTrack videoTrack: RTCVideoTrack) {
		videoTrack.add(localVideoView)
	}
	```
	
	Видеопотоки других участников приходят в виде объекта `VideoObject`, у которого есть идентификатор пира `peerId` и видеопоток `rtcVideoTrack`
	
	```swift
	func roomClient(roomClient: GCoreRoomClient, handledRemoteVideo videoObject: VideoObject) {
		// Создаём объект пира с вьюхой, которая будет отображать поток
		let remoteItem = RemoteVideoItem(
			peerId: videoObject.peerid
			videoView: RTCEAGLVideoView()
		)
		remoteItems.add(remoteItem)
		
		// Добавляем потоку вьюху
		videoObject.rtcVideoTrack.add(remoteItem.videoView)
	}
	```
	
	Так как у нас есть массив Пиров с вьюхами, мы можем ими управлять, если приходит событие на удаление видео потока для конкретного пира.
	
### Аудиопотоки

1. При изменении аудиопотока кого-то из участников (вкл/выкл микрофона), вызывается метод, в котором мы можем проверить состояние потока и отрисовать соответствующую иконку.

	```swift
	func audioDidChanged(_ audioObject: AudioObject) {
		if let remoteItem = remoteItems.first(where: { $0.peerId == audioObject.peerId }) {
			remoteItem.isEnableAudio(audioObject.rtcAudioTrack.isEnabled)
		}
	}
	```

### Прочие события

1. Разговаривающие в данный момент участники
	
	Метод **activeSpeakerPeers(_ peers: [String])** возвращает идентификаторы активно говорящих пиров, таким образом мы можем отрисовать для конкретного участника соответствующую иконку

	```swift
	func activeSpeakerPeers(_ peers: [String]) {
		remoteItems.forEach { item in
			item.isSpeekingActive(peers.contains(item.peerId))
		}
	}
	```

## Классы

***`PeerObject`***

peer - новый юзер в комнате

| Параметр| Тип | Описание|
|--|--|--|
| id | String | идентификатор юзера |
|displayName | String? | имя юзера 

---

***`VideoObject`***

| Параметр| Тип | Описание|
|--|--|--|
| peerId | String | идентификатор юзера |
|rtcVideoTrack | RTCVideoTrack | видеопоток 

---

***`AudioObject`***

| Параметр| Тип | Описание|
|--|--|--|
| peerId | String | идентификатор юзера |
|rtcAudioTrack | RTCAudioTrack | видеопоток 

## Типы ошибок

***`RoomError`***

Возвращается в методе 

```swift
func  roomClientHandle(error: GCoreVideoCallsSDK.RoomError)
```

|Тип  | Описание |
|--|--|
| invalidSocketURL | не верный URL для подключению к серверу |
| fatalError(Error) | в объекте `Error` приходит ошибка с сервера, можно посмотреть её description и определить в чём проблема


## Работа в фоновом режиме

На данный момент работа в фоне или бэкграунде не поддерживается, подключение будет активно только на включённом экране телефона. При прерывании конференции, если по каким либо причинам приложение было свёрнуто, нужно заново инициировать подключение к серверу (вход в комнату)
<!--stackedit_data:
eyJoaXN0b3J5IjpbLTE5ODA1NjM3NDQsMTE4MjgzMzc0MiwtMj
E3NjUwNjU1LC0xNDI3NjQzNDA3LC0xODg5MTg3ODg3LDUzMTQx
NzgxMCw4OTI2NTU0OTcsNTMwMDAwMzQzLC0xNjk5OTA3NjQzLC
0xOTQ5ODczNiwtMTE5MTc1NDk0NCw5Mjg4NjQ5NzYsMTc1MjA4
NDA5NSwtNjU1Njc4MDgsNjkwNzk5MzUyLC0xMzExODgxOTkyXX
0=
-->