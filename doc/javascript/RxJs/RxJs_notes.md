Title: RxJs 学习笔记
Author: 刘龙彪
css: http://netdna.bootstrapcdn.com/twitter-bootstrap/2.3.2/css/bootstrap-combined.min.css
css: http://yandex.st/highlightjs/7.5/styles/rainbow.min.css
HTML header: <script src="../../../js/seajs/2.1.1/sea.js"></script>
	<script src="../../../js/config.js"></script>
	<script>seajs.use("init");</script>

## RxJs 简介

RxJS 是使用可观察序列和 LINQ 风格查询操作符来编写异步和基于事件程序的类库。
使用 RxJS， 开发者用 Observables 来 **表示** 异步数据流，通过 LINQ 操作符来 **查询**
异步数据量，并使用 Schedules 来参数化异步数据流中的并发。
简单地讲， Rx = Observables + LINQ + Schedulers。

在 RxJS 中，你可以表述多个异步数据流，并且使用 `Observer` 对象订阅事件流。
`Observable` 对象会在事件发生时通知已订阅的 `Observer`。

因为 Observable 序列是数据流，你可以使用由 Observable 扩展方法实现的标准查询操作符
来查询它们。这样你可以通过这些查询操作符很容易地在多个事件上进行过滤、投射、聚合、
组合和执行基于时间的操作。除此之外还有很多其他反应式流特定的操作符使得可以书写强大的查询。
取消、异常和同步都可以通过由 Rx 提供的扩展方法优雅地处理。

由 Rx 实现的 Push 模型表现为 `Observable`/`Observer` 的观察者模式。
`Observable` 会自动在任何状态改变时通知所有的 `Observer`s。
要通过订阅注册一个关注，你要使用 `Observable` 上的 `subscribe` 方法，
它接收一个 `Observer` 并返回一个 `Disposable` 对象。
它让你能够跟踪你的订阅并能够取消该订阅。
本质上你可以将可观察序列看做一个常规的集合。

## 主要概念

### `Observable`/`Observer`

Rx 将异步的基于事件的数据源暴露为 RxJs 核心包中 `Observable` 对象所抽象
的基于推送的可观察序列。它将数据源表示为可被观察的，即它可发送数据给任何感兴趣的人。

推送模型的另一半由 `Observer` 表示，它代表了一个通过订阅注册了关注的观察者。
项从可观察序列顺序地传递给它上面所订阅的观察者。

为从一个可观察集合接收通知，你需要使用 `Observable` 的 `subscribe` 方法，并传递一个
`Observer` 对象。它会返回一个 `Disposable` 对象作为该订阅的句柄。
它让你可以在完成时清除该订阅。调用该对象上的 `dispose` 方法会从源上分离该  Observer,
这样就不会继续投递通知。
可以推断，在RxJS 中你不需要像常见的 JavaScript 事件模型那样显式地取消订阅某个事件。

Observers 支持三个发布事件，由对象的方法反映。`onNext` 可被调用零或多次，
当 Observable 数据源有数据可用时。其他两个方法用于指示完成或错误。

RxJs 也提供了 `subscribe` 能力，这样你可以避免自己实现 `Observer` 对象。
对可观察序列的每个发布事件 (`onNext`、`onError`、`onCompleted`)，
你可以指定一个将被调用的函数。如果没有对某个事件指定动作，则将发生默认行为。

## 创建和查询可观察序列

### 创建和订阅简单的可观察序列

* `Rx.Observable.create`
* `Rx.Observable.range`
* `Rx.Observable.timer`
* `Rx.Observable.fromArray`

#### Cold vs Hot Observables

通过使用 `publish` 操作符将冷的可观察序列源转换为热的源，它返回一个 `ConnectableObservable`
实例。`publish` 操作符提供了一种机制通过广播单个订阅到多个订阅者来共享订阅。
这个热变体表现为一个代理并订阅到源上，当它从源上接收值时，将它们推送到自己的订阅者上。
`ConnectableObservable.prototype.connect()` 用来简历对后端源的订阅并开始接收值。

### 桥接到事件

`fromEvent` 和 `fromEventPattern` 操作符允许将 DOM 或自定义事件引入 RxJS 中作为可观察序列。
每次一个事件发生时，一条 `onNext` 消息将被传递到这个可观察你序列中。
然后你就可以像其它可观察序列一样操作事件数据了。

RxJS 不意于取代已有的诸如 Promise 或 Callback 这样的异步编程模型。
然而当你试图组合事件时，RxJS 工厂方法将提供现有编程模型中所找不到的便利。

`Rx.Observable.fromEvent(DOM | jQuery | EventEmitter, eventType)`

`Rx.Observable.fromEventPattern(addHandler, delHandler)`

### 桥接到 Callback 和 Promises

`Rx.Observable.fromCallback`

`Rx.Observable.fromNodeCallback`

`Rx.Observable.fromPromise`

### 查询可观察序列
### 分类的操作符

## 使用 Subjects

`Subject` 类继承了 `Observable` 和 `Observer`，这种意义上它既是 Observer  也是 Observable。

`ReplaySubject` 存储了所有它已发布的值。这样，当你订阅它时，会自动收到它已发布的所有历史值，
即使你的订阅可能发生在某个特定值推送以后。
`BehaviourSubject` 类似于 `ReplaySubject` , 除了它仅存储它所发布的最后一个值。
`BehaviourSubject` 也需要给初始化提供一个默认值。该值会在其没有接受到任何其他值时发送给观察者。
这意味着所有的订阅者都会在 `subscribe` 时马上接收到一个值，除非该 `Subject` 已经完成了。
`AsyncSubject` 类似于 Replay 和 Behavior Subjects，然而它仅存储最后的值，且仅在序列完成时
发布它。你可以将 `AsyncSubject` 类型用于源 Observable 是热的且可能在任何 Observer 可以
订阅它之前完成的情形。这时， `AsyncSubject` 依旧可以提供最后的值并将其发布给任何未来的订阅者。

## 调度和并发

Scheduler 控制何时订阅启动以及何时通知被发布。它由三个组件组成。
它首先是一个数据结构。当你调度需完成的任务时，它们被放到基于优先级或其他条件的队列中。
它也提供了一个执行上下文，指示任务在何处被执行(如，立即执行、当前线程或在其他诸如`setTimeout`
或 `process.nextTick` 这样的回调机制)。最后它具有一个时钟，给自己提供了事件的表示(通过
访问 Scheduler 的 `now` 方法)。在特定 Scheduler 上调度的任务将仅遵循该时钟的指示。

Schedulers 也引入了虚拟时间的表示(由 `VirtualTimeScheduler` 类型指示)，它不和日常生活
中的实际时间关联。

