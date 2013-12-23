Title: Knockout.js 学习笔记
Author: 刘龙彪
css: http://netdna.bootstrapcdn.com/twitter-bootstrap/2.3.2/css/bootstrap-combined.min.css
css: http://yandex.st/highlightjs/7.5/styles/rainbow.min.css
HTML header: <script src="../../../js/seajs/2.1.1/sea.js"></script>
	<script src="../../../js/config.js"></script>
	<script>seajs.use("init");</script>

## Knockout 简介

Knockout 是一个帮助你以一种清晰的底层数据模型来创建富客户端、响应式显示和编辑器用户接口
的 JavaScript 类库。任何你需要动态地更新 UI 的某些部分(如根据用户操作执行变更或当外部
数据源变更时)，KO 可以帮助你以更简单和可维护的方式实现它。

主要特色：

* **优雅的依赖跟踪** - 当你的数据模型改变时，自动更新 UI 相关的部分
* **声明式绑定** - 一种将 UI 的某些部分和你的数据模型关联到一起的简单和显而易见的方式。
	你可以使用任意内嵌的绑定上下文来很容易地创建一个复杂的动态 UI。
* **易扩展** - 为便于重用而将自定义行为实现为新的声明式绑定只需要几行代码。

额外好处：

* **纯 JavaScript 类库** - 可用于任何服务端或客户端技术
* **可添加在任何已有的 web 应用上面** - 不需要大量的架构变更
* **紧凑** - 压缩后仅 13 kb
* **可运行在任何主流浏览器上** -  (IE 6+, Firefox 2+, Chrome, Safari, 等)
* **完备的规格套件** - (BDD 风格开发)意味着其功能正确性可很容易地在新的浏览器或平台上验证

MVVM 可看做具有声明式语法的实时形式的 MVC

KO 不同 jQuery 或类似的低层次 DOM API 竞争。KO 提供了一个互补的、高层次的方式将
数据模型链接到 UI 上。

## Observables

### 用 Observables 创建视图模型

#### MVVM 和 View Models

Model-View-View Model (MVVM) 是一个用于构建用户接口的设计模式。
它描述了你可以如何通过将一个可能很复杂的 UI 分成以下三个部分来保持其简单性：

* **Model** ：应用的存储数据。该数据表示了你的业务领域中的对象和操作(如，可执行转账的
	银行账号)，且独立于任何 UI。使用 KO 时，你常会使用 Ajax 调用服务端代码
	来读写这些存储的模型数据。
* **View Model** ：UI 上的数据和操作的纯代码表示。例如，如果你在实现一个列表编辑器，
	你的 View Model将是一个持有一个项的列表并暴露方法以添加和删除项的对象。<br/>
	注意，它不是 UI 本身：它没有任何按钮或显示样式的概念。它也不是持久数据模型，
	它持有的是用户正在操作的未保存的数据。在 KO 中，你的 View Model 是不具备任何 HTML
	知识的 JavaScript 对象。将 View Model 保持在这个抽象层度使它保持简单，
	这样你可以管理更复杂的行为而不会迷失。
* **View** ：一个表示了视图模型状态的可视的交互的 UI。它从视图模型显示信息，
	发送命令到视图模型(如，用户点击按钮时)，并在任何视图模型状态变更时做相应更新。<br/>
	在 KO 中，你的视图只是你的带有声明式绑定将其链接到视图模型的 HTML 文档。
	或者，你可以使用模板来用来自你的视图模型的数据生成 HTML。

##### 激活 Knockout

`ko.applyBindings`

参数：

* 第一个参数是你希望激活的声明式绑定所使用的视图模型
* 可选的，你可以传入第二个参数定义文档的哪一部分你希望它搜索 `data-bind` 属性。

#### Observables

KO 的一个重要优势在于能自动在视图模型变更时更新你的 UI。要让 KO 知道你的视图模型何时改变，
你需要将模型属性声明为 Observables，因为它们是特殊的 JavaScript 对象，可以通知订阅者
有关变更的信息，并可以自动侦测依赖。

##### 读写 Observables

不是所有的浏览器都支持 JavaScript getters 和 setters (咳 IE 咳)，因此为了兼容性，
ko.observable 对象实际上是函数。

* **读取** Observable 当前值，只要不带参数调用 Observable 。
* **写入** 新值到 Observable ，调用 Observable 并传入一个新值作为参数。
* 要写入多个值到模型对象上的**多个 Observable 属性**，可以使用链式语法。

Observables 的重点是它们可被观察，即其他代码表示它们想在其改变时被通知。

##### 明确订阅 Observables

_你通常不需要手动设置订阅，所以初学者可以跳过这一节_

如果你需要注册自己的订阅以在 Observables 变更时被通知到，你可以调用 `subscribe` 函数。如：

	myViewModel.personName.subscribe(function(newValue) {
		alert("The person's new name is " + newValue);
	});

`subscribe` 函数接收三个参数： `callback` 是通知发生时调用的函数， `target` (可选) 定义
了回调函数中 `this` 的值，以及 `event` (可选，默认为 `change`) 是所接收通知的事件的名称。

你也可以终止一个订阅：首先将其返回值捕获为一个变量，然后调用其 `dispose` 函数：

	var subscription = myViewModel.personName.subscribe(function(newValue) { /* do stuff */ });
	// ...then later...
	subscription.dispose(); // I no longer want notifications

如果你想在 Observable 改变时被通知其以前的值，你可以订阅 `beforeChange` 事件：

	myViewModel.personName.subscribe(function(oldValue) {
		alert("The person's previous name is " + oldValue);
	}, null, "beforeChange");

##### 强制 Observables 总是通知订阅者

当写入到 Observable 包含一个原生类型(数字、字符串、布尔或 `null`)时，Observable 的
依赖通常仅在其值确实被改变时被通知。然而，可以使用内建的 `notify` 扩展器来确保某个
Observable 的订阅者总是在写入时被通知，即使其值是相同的。如下：

	myViewModel.personName.extend({ notify: 'always' });

### 使用 Computed Observables

#### Computed Observables

Computed Observables 是依赖于一或多个其他 Observables 的函数，且将在任何这些依赖
变更时自动更新。

	function AppViewModel() {
		// ... leave firstName and lastName unchanged ...
	 
		this.fullName = ko.computed(function() {
			return this.firstName() + " " + this.lastName();
		}, this);
	}

##### 管理 `this`

_初学者可能希望跳过本节 - 只要你遵循示例的编码模式，你将不需要知道或关心这个！_

如果你好奇 `ko.computed` 的第二个参数，它定义了在求值 Computed Observable 时 `this` 的值。
如果不传入的话，它将不可能引用到 `this.firstName()` 或 `this.lastName()`。

###### 简化事物的惯例

一个避免到处跟踪 `this` 的惯例是：如果你的视图模型的构造器拷贝了对 `this` 的引用
到某个变量(常叫 `self`)，你可以在视图模型的任何地方使用 `self` 而不需要担心它会被
重定义而引用到其他东西，如：

	function AppViewModel() {
		var self = this;
	 
		self.firstName = ko.observable('Bob');
		self.lastName = ko.observable('Smith');
		self.fullName = ko.computed(function() {
			return self.firstName() + " " + self.lastName();
		});
	}

因为 `self` 被捕获在函数闭包中，它会保持可用性且在任何内嵌函数中一致。
这个约定在遇到事件处理器时会更有用。

##### 恰好可运作的依赖链

##### 强制 Computed Observables 总是通知订阅者

	myViewModel.fullName = ko.computed(function() {
		return myViewModel.firstName() + " " + myViewModel.lastName();
	}).extend({ notify: 'always' });

#### 可写的 Computed Observables

_初学者可能希望跳过本节 - 可写的 Computed Observables 是非常高级的且大多数情况下不是必须的。_

示例1：分解用户输入

	function MyViewModel() {
		this.firstName = ko.observable('Planet');
		this.lastName = ko.observable('Earth');
	 
		this.fullName = ko.computed({
			read: function () {
				return this.firstName() + " " + this.lastName();
			},
			write: function (value) {
				var lastSpacePos = value.lastIndexOf(" ");
				if (lastSpacePos > 0) { // Ignore values with no space character
					this.firstName(value.substring(0, lastSpacePos)); // Update "firstName"
					this.lastName(value.substring(lastSpacePos + 1)); // Update "lastName"
				}
			},
			owner: this
		});
	}
	 
	ko.applyBindings(new MyViewModel());

示例2： 值转换

	function MyViewModel() {
		this.price = ko.observable(25.99);
	 
		this.formattedPrice = ko.computed({
			read: function () {
				return '$' + this.price().toFixed(2);
			},
			write: function (value) {
				// Strip out unwanted characters, parse as float, then write the raw data back to the underlying "price" observable
				value = parseFloat(value.replace(/[^\.\d]/g, ""));
				this.price(isNaN(value) ? 0 : value); // Write to underlying storage
			},
			owner: this
		});
	}
	 
	ko.applyBindings(new MyViewModel());

示例3： 过滤和验证用户输入

	function MyViewModel() {
		this.acceptedNumericValue = ko.observable(123);
		this.lastInputWasValid = ko.observable(true);
	 
		this.attemptedValue = ko.computed({
			read: this.acceptedNumericValue,
			write: function (value) {
				if (isNaN(value))
					this.lastInputWasValid(false);
				else {
					this.lastInputWasValid(true);
					this.acceptedNumericValue(value); // Write to underlying storage
				}
			},
			owner: this
		});
	}
	 
	ko.applyBindings(new MyViewModel());

#### 依赖跟踪如何运作

_初学者不需要知道这些，但高级开发者会希望了解为什么我们保持这些关于 KO 自动跟踪依赖
并更新 UI 相关部分的声明..._

它实际上非常简单和可爱。跟踪算法如下：

1. 当声明一个 Computed Observable 时， KO 立即调用其求值函数以获取初始值。
2. 在求值函数运行时，KO 保持一个日志，记录了任何该求值器所读取值的 Observables 
(或 Computed Observables)
3. 当求值器完成时， KO 给每个遇到的 Observables (或 Computed Observables) 设置订阅。
订阅回调被设置为导致你的求值器再次运行，循环整个过程回第一步 (注销任何不再应用的旧的订阅)。
4. KO 通知所有订阅者关于该 Computed Observable 的新值。

所以，KO 不只是在求值器第一次运行时检测依赖 - 它每次都会重检测。
这意味着，你的依赖可以是动态的。

另一个小技巧是，声明式绑定简单地实现为 Computed Observables.这样，如果一个绑定读取了
一个 Observable 的值，该绑定变为依赖于该 Observable ，这样如果该 Observable 改变时，
会导致绑定被重求值。

##### 使用 peek 控制依赖

Knockout 的自动依赖跟踪通常如你所愿地工作。但有时你可能需要控制哪些 Observables 将更新
你的 Computed Observable，特别是当 Computed Observable 需要执行某些类型的动作时，如 Ajax 请求。
`peek` 函数可让你访问一个 Observable 或 Computed Observable 而不创建依赖。

> **注：为何循环依赖是无意义的**<br/>
> 如果依赖图中存在环，它通过以下规则避免无限循环：
> **Knockout 不会重启一个在已经在求值中的 Computed Observable 的求值过程。**

#### 判断某个属性是否是 Computed Observable

某些情况下，编程式的判断某个正在处理的值是否是 Computed Observable 会很有用。
Knockout 提供了一个工具函数,`ko.isComputed` 来帮助这些场景。例如，你可能希望
在需发送回服务器的数据中排除 Computed Observable 。

	for (var prop in myObject) {
	  if (myObject.hasOwnProperty(prop) && !ko.isComputed(myObject[prop])) {
		  result[prop] = myObject[prop];
	  }
	}

另外，Knockout 提供了可操作在 Observables 和可写的 Computed Observables 上的类似函数：

* `ko.isObservable` - 
* `ko.isWriteableObservable` - 

#### Computed Observable 参考

Computed Observable 可使用下列形式中的一种构造：

// TODO

Computed Observable 提供了以下函数：

// TODO

### 使用 Observable 数组

如果你想侦测并响应某个对象上的变更，你可以使用 [Observables]。
如果你想侦测并响应某个事物的集合上的变更，就使用一个 `observableArray`。
这在很多需要显示或编辑多个值且需要 UI 的重复部分在项被添加和移除时出现或消失
的场景下非常有用。

	var myObservableArray = ko.observableArray();    // Initially an empty array
	myObservableArray.push('Some value');            // Adds the value and notifies observers

> 重点： `observableArray` 跟踪的是哪些对象**在**数组中，而不是这些对象的状态 

#### 填充 observableArray

#### 从 observableArray 中读取信息

幕后， `observableArray` 实际上是一个值为数组的 Observable (另外，`observableArray` 
增加了下述的一些特性)。

// TODO

## Bindings

### 控制文本和外观
### 控制流
### 使用表单字段
### 渲染模板
### 绑定语法

#### `data-bind` 语法

Knockout 的声明式绑定系统提供了一种简洁强大的方式将数据链接到 UI 上。
绑定到简单的数据属性或者使用单个绑定通常很简单。
对更复杂的绑定，需要更好的理解 Knockout 绑定系统的行为和语法。

##### 绑定语法

一个绑定由绑定名称和值两部分组成，由冒号隔开。简单的单绑定示例如下：

	Today's message is: <span data-bind="text: myMessage"></span>

元素可包含多个绑定(相关或不相关的)，其中每个绑定由逗号隔开。如下：

	<!-- related bindings: valueUpdate is a parameter for value -->
	Your value: <input data-bind="value: someValue, valueUpdate: 'afterkeydown'" />
	 
	<!-- unrelated bindings -->
	Cellphone: <input data-bind="value: cellphoneNumber, enable: hasCellphone" />

绑定名称通常应该匹配一个注册的绑定处理器(内建或自定义的)或者是另一个绑定的参数。
如果名称都不匹配，Knockout 将忽略它(不带任何错误或警告)。
因此如果某个绑定不起作用的话，先检查名称是否正确。

##### 绑定值

绑定值可以是单个值、变量或字面量或几乎任何有效的 JavaScript 表达式。示例如下：

	<!-- variable (usually a property of the current view model -->
	<div data-bind="visible: shouldShowMessage">...</div>
	 
	<!-- comparison and conditional -->
	The item is <span data-bind="text: price() > 50 ? 'expensive' : 'cheap'"></span>.
	 
	<!-- function call and comparison -->
	<button data-bind="enable: parseAreaCode(cellphoneNumber()) != '555'">...</button>
	 
	<!-- function expression -->
	<div data-bind="click: function (data) { myFunction('param1', data) }">...</div>
	 
	<!-- object literal (with unquoted and quoted property names) -->
	<div data-bind="with: {emotion: 'happy', 'facial-expression': 'smile'}">...</div>

这些示例显示了值可以是几乎任何 JavaScript 表达式。当被包含在花括号、方括号或括号里面时，
甚至逗号都是有效的。当值是一个对象字面量时，对象的属性名必须是一个有效的 JavaScript 标识符
或被引号括起。
如果绑定值是一个无效表达式或引用是未知变量时，Knockout 将输出一个错误并停止处理绑定。

###### 空白符

绑定可以包含任何数量的空白符(空格、制表符或换行符)，因此你可以随意使用来安排你的绑定。
下述示例是等价的：

	<!-- no spaces -->
	<select data-bind="options:availableCountries,optionsText:'countryName',value:selectedCountry,optionsCaption:'Choose...'"></select>
	 
	<!-- some spaces -->
	<select data-bind="options : availableCountries, optionsText : 'countryName', value : selectedCountry, optionsCaption : 'Choose...'"></select>
	 
	<!-- spaces and newlines -->
	<select data-bind="
		options: availableCountries,
		optionsText: 'countryName',
		value: selectedCountry,
		optionsCaption: 'Choose...'"></select>

###### 跳过绑定值

从 Knockout 3.0 开始，你可以指定不带值得绑定，这将给绑定一个 `undefined` 值。如下：


这一点在使用 [绑定预处理][binding-preprocessing] 时非常有用，
它可以给一个绑定赋予一个默认值。

#### 绑定上下文 [binding-context]

_绑定上下文_ 是一个持有你可以在绑定中所引用的数据的对象。
在应用绑定时，Knockout 会自动创建并管理绑定上下文的层级关系。
该层级的根指向你所提供给 `ko.applyBindings(viewModel)` 的 `viewModel` 参数。
然后，每当你使用某个控制流绑定如 `with` 或 `foreach` 时，它都会创建一个子绑定上下文
以指向内嵌的视图模型数据。

绑定上下文提供了以下特殊属性，你可以在任何绑定中引用它们：

* `$parent`

这是当前上下文外的直接父上下文中的视图模型对象。根上下文中，它是 `undefined`。

* `$parents`

表示所有父视图模型的数组；`$parents[0]` 是父上下文的视图模型，等等。

* `$root`

根上下文中的主数据模型对象。它通常是传递给 `ko.applyBindings(viewModel)` 的对象。
它等价于 `$parents[$parents.length - 1]`。

* `$data`

当前上下文中的视图模型对象。根上下文中，`$data` 和 `$root` 是等价的。
在内嵌的绑定上下文中，该参数将被设为当前的数据项。`$data` 在你想引用视图模型本身，
而不是视图模型的抖个属性时非常有用。

* `$index` (仅在 `foreach` 绑定中可用)

`foreach` 绑定所渲染的当前数组实体的基于 0 的索引。不像其他绑定上下文属性，
`$index` 是一个 Observable 且在项的索引改变时随之更新(如项被从数组上添加或移除)。

* `$parentContext`

它指向父级的绑定上下文对象。它和指向父级的数据(不是绑定上下文)的 `$parent` 不同。
它在，例如你需要从内部上下文中访问外部 `foreach` 项的索引(`$parentContext.$index`)很有用。
在根上下文中，它是 `undefiend`。

* `$rawData`

这是当前上下文中的原始的视图模型值。
通常它和 `$data` 是相同的，但如果提供给 Knockout 的视图模型被封装为一个 Observable ，
`$data` 将是未封装的视图模型，而 `$rawData` 将是 Observable 本身。

以下特殊变量在绑定中也可用，但不属于绑定上下文对象：

* `$context`

它指向当前绑定上下文对象。这在你希望访问上下文的属性而它们也存在于视图对象时，
或你希望将上下文对象传递给视图模型的某个帮助方法时会很有用。

* `$element`

这是当前绑定的 DOM 元素对象 (对虚拟元素，它是注释 DOM 对象)。
这在绑定需要访问当前元素的某个属性时很有用。如：

	<div id="item1" data-bind="text: $element.id"></div>

##### 在自定义绑定中控制或修改绑定上下文

和内建的 `with` 和 `foreach` 一样，自定义绑定可以改变其后代元素的上下文或
通过扩展绑定上下文对象来提供特殊属性。
这在 [创建控制后代绑定的自定义绑定][custom-bindings-controlling-descendant-bindings]
中有细节描述。

### 创建自定义绑定

## 其他技术

### 加载和保存 JSON 数据

### 扩展 Observables

Knockout Observables 提供了基本的必要特性来支持读/写值并在值变更时通知订阅者。
然而，有时候你可能希望给 Observable 添加额外的功能。
它可能包含给 Observable 添加额外的属性或者通过在 Observable 前放置一个 Computed Observable
来拦截写入。Knockout 扩展器提供了一种简单灵活的方式来做对 Observable 的这种类型的增强。

#### 如何创建扩展器

创建扩展器涉及给 `ko.extenders` 对象添加一个函数。
该函数接收 Observable 本身作为其第一个参数以及任何选项作为第二个参数。
它可以返回该 Observable 或者返回诸如一个以某种方式使用原始 Observable 的
新的 Computed Observable 这样的东西。

下面这个简单的 `logChange` 扩展器订阅了 Observable 并向控制台写入任何带有配置消息的变更。

	ko.extenders.logChange = function(target, option) {
		target.subscribe(function(newValue) {
		   console.log(option + ": " + newValue);
		});
		return target;
	};

你将通过调用 Observable 上的 `extend` 函数并传入一个包含 `logChange` 属性的对象
来使用这个扩展器。

	this.firstName = ko.observable("Bob").extend({logChange: "first name"});

#### 示例1： 强制输入框为数字

视图源码：

	<p><input data-bind="value: myNumberOne" /> (round to whole number)</p>
	<p><input data-bind="value: myNumberTwo" /> (round to two decimals)</p>

视图模型源码：

	ko.extenders.numeric = function(target, precision) {
		//create a writeable computed observable to intercept writes to our observable
		var result = ko.computed({
			read: target,  //always return the original observables value
			write: function(newValue) {
				var current = target(),
					roundingMultiplier = Math.pow(10, precision),
					newValueAsNum = isNaN(newValue) ? 0 : parseFloat(+newValue),
					valueToWrite = Math.round(newValueAsNum * roundingMultiplier) / roundingMultiplier;
	 
				//only write if it changed
				if (valueToWrite !== current) {
					target(valueToWrite);
				} else {
					//if the rounded value is the same, but a different value was written, force a notification for the current field
					if (newValue !== current) {
						target.notifySubscribers(valueToWrite);
					}
				}
			}
		}).extend({ notify: 'always' });
	 
		//initialize with current value to make sure it is rounded appropriately
		result(target());
	 
		//return the new computed observable
		return result;
	};
	 
	function AppViewModel(one, two) {
		this.myNumberOne = ko.observable(one).extend({ numeric: 0 });
		this.myNumberTwo = ko.observable(two).extend({ numeric: 2 });
	}
	 
	ko.applyBindings(new AppViewModel(221.2234, 123.4525));

注意，这里要从 UI 上自动清除错误值，在 Computed Observable 上
使用 `.extend({ notify: 'always' })` 是必要的。
没有这个的话，用户可能输入一个无效的 `newValue` 但舍入时给出了一个没变的 `valueToWrite`。
然后，鉴于模型的值将不会改变，UI 上的文本框也就没有通知其更新了。
使用 `{ notify: 'always' }` 致使文本框进行更新(清除错误值)，即使计算的属性的值没有变。

#### 示例2：给 Observable 添加验证

本例创建了一个扩展器使得一个 Observable 可标记为 required。
取代返回一个新的对象，这里简单地直接在已有的 Observable 上添加额外的子 Observables。
因为 Observables 是函数，它们可以有自己的属性。然而，当视图模型被转换为 JSON 时，
子 Observables 将被丢弃，而我们将简单的只得到实际 Observable 的值。
这种是非常适合于添加仅和 UI 相关而不需要发送回服务器的额外功能的方式。

视图源码：

	<p data-bind="css: { error: firstName.hasError }">
		<input data-bind='value: firstName, valueUpdate: "afterkeydown"' />
		<span data-bind='visible: firstName.hasError, text: firstName.validationMessage'> </span>
	</p>
	<p data-bind="css: { error: lastName.hasError }">
		<input data-bind='value: lastName, valueUpdate: "afterkeydown"' />
		<span data-bind='visible: lastName.hasError, text: lastName.validationMessage'> </span>
	</p>

视图模型源码：

	ko.extenders.required = function(target, overrideMessage) {
		//add some sub-observables to our observable
		target.hasError = ko.observable();
		target.validationMessage = ko.observable();
	 
		//define a function to do validation
		function validate(newValue) {
		   target.hasError(newValue ? false : true);
		   target.validationMessage(newValue ? "" : overrideMessage || "This field is required");
		}
	 
		//initial validation
		validate(target());
	 
		//validate whenever the value changes
		target.subscribe(validate);
	 
		//return the original observable
		return target;
	};
	 
	function AppViewModel(first, last) {
		this.firstName = ko.observable(first).extend({ required: "Please enter a first name" });
		this.lastName = ko.observable(last).extend({ required: "" });
	}
	 
	ko.applyBindings(new AppViewModel("Bob","Smith"));

#### 应用多个扩展器

可以在调用 Observable 的 `.extend` 方法时一次应用多个扩展器：

	this.firstName = ko.observable(first).extend({ required: "Please enter a first name", logChange: "first name" });

### `throttle` 扩展器

通常，Computed Observables 会在任何依赖改变时被同步地重求值。
而 `throttle` 扩展器会致使 Computed Observable 延迟其重求值直到其依赖在某个指定
时间段内没有改变。被节流的 Computed Observable 因此是异步更新的。

节流的主要的使用场景：

* 让事物在某个延迟后响应
* 将多个变更整合到单个重求值中(所谓 "原子更新")

### 不唐突的事件处理

大多数时候， `data-bind` 属性提供了一种清晰简洁的方式来绑定视图模型。
然而，事件处理是可能导致啰嗦的 `data-bind` 属性的地方，因为通常匿名函数是传参的
推荐方式。

作为替代，Knockout 提供了两个帮助函数允许你标识 DOM 元素上关联的数据：

* `ko.dataFor(element)` 返回在元素上绑定的可用的数据
* `ko.contextFor(element)` 返回在元素上可用的整个绑定上下文

这些帮助函数可用在像 jQuery 的 `bind` 或 `click` 这样非唐突地附着的事件处理器中。

### 使用 `fn` 来添加自定义函数

### 扩展 Knockout 的绑定语法

## 插件

### `mapping` 插件

## 其他信息

### 浏览器支持

### 获取帮助

### 教程 & 示例链接

### 使用 RequireJs 的 AMD 用例