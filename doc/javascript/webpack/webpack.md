Title: Webpack 学习笔记
Author: 刘龙彪
css: http://netdna.bootstrapcdn.com/twitter-bootstrap/2.3.2/css/bootstrap-combined.min.css
css: http://yandex.st/highlightjs/7.5/styles/rainbow.min.css
HTML header: <script src="../../../js/seajs/2.1.1/sea.js"></script>
	<script src="../../../js/config.js"></script>
	<script>seajs.use("init");</script>

Webpack 学习笔记
=================

### 特性

* __插件__<br/> webpack 具有强大的 plugin 接口。大多数特性是使用该接口的内部插件。这使得 webpack 非常灵活。
* __性能__<br/> webpack 使用异步 IO 并具有多级缓存。这使得 webpack 很快且在增量编译上更加快。
* __加载器__<br/> webpack 允许使用 loaders 来预处理文件。这使得你能够打包任何静态资源，不仅仅是 javascript。
* __支持__<br/> webpack 支持 AMD 和 CommonJs 模块风格。它会在代码的 AST 上执行智能分析。
它甚至还有一个求值引擎来求值简单的表达式。这使你能够支持大多数已有的类库。
* __代码切分__<br/> webpack 让你可以将代码库切分为块，每个块可按需加载。这降低了初始加载时间。
* __优化__<br/> webpack 可以完成很多优化来降低输出尺寸。它也能通过使用哈希处理请求缓存。
* __开发工具__<br/> webpack 支持 SourceUrls 和 SourceMaps 。调试很方便。
它可以监视你的文件并有一个开发中间间和开发服务器来自动重加载。
* __多目标__<br/> webpack 的主要目标是 web，但它也支持位 WebWorkers 和 node.js 生成包。

## 动机

### 模块化系统风格

#### `<script>` 标签风格

* 全局对象冲突
* 加载顺序很重要
* 开发人员需要解决模块/类库间的依赖
* 大项目中列表会变得很长且难以管理

#### CommonJs : 同步 `require`

优点：

* 服务端模块可以重用
* 已经存在了大量这种风格的模块(npm)
* 简单易用

缺点：

* 阻塞调用不适用于网络。请求是异步的。
* 不能并行 `require` 多个模块

#### AMD : 异步 `require`

优点：

* 适用于网络中的异步请求风格
* 可并行加载多个模块

缺点：

* 编码开支。更加难以读和写
* 看起来像某种变通方案

#### ES 6 模块

优点：

* 静态分析很容易
* 作为 ES 标准提供

缺点：

* 原生浏览器支持尚待时日
* 很少有这种风格的模块

### 转移

模块应在客户端执行，因此需要从服务端转移到浏览器上。

当前在如何转移模块上有两种极端：

* 每个模块一个请求
* 所有模块整合进一个请求

两者都有使用，但都是次优的：

* 每个模块一个请求
** 优点： 仅有被请求的模块被转移
** 缺点： 多个请求意味着更多的开支
** 缺点： 因为请求延迟导致应用启动缓慢
* 所有模块整合进一个请求
** 优点： 更少的请求开支，更少的延迟
** 缺点： 没有(尚未)请求的模块也被转移了

#### 块转移

在编译所有模块时，将模块集分成多个更小的批次(块)
大代码基础成为可能。

### 为何仅限于 Javascript？

还有很多其他静态资源需要处理：

* stylesheets
* images
* webfonts
* html 模板
* etc.

以及：

* coffeescript -> javascript
* less stylesheet -> css
* jade templates  -> 生成 HTML 的 javascript
* i18n files -> something
* etc.

更多信息查看 [使用 loaders][using-loaders]。

### 静态分析

当编译所有模块时，静态分析试图找到依赖。

传统的方式可以找到不带表达式的简单事物，但像 
`require("./template/" + templateName + ".jade")` 这样是很普遍的结构。

很多类库以不同的风格书写。某些非常奇怪...

策略：

更智能的解析器应能使得大多数已有的代码可运行。如果开发者做了某些奇怪的事情，
尝试找到最兼容的方案。

## 什么是 webpack？

webpack 是一个模块打包器。

webpack 接收带依赖的模块并生成这些模块的静态资源表示。

### Why another module bundler?

已有的模块打包器不是很适合大的项目(大的单页面应用)。开发新的模块打包器的最迫切原因是
代码切分以及静态资源应无缝地契合模块化。

### 目标

* 将依赖树切分为按需加载的块
* 保持初始加载时间很短
* 每个静态资源应该能成为一个模块
* 能够将第三方类库整合为模块
* 能够定制模块打包器中几乎所有的部分
* 适合大型项目

### webpack 如何不同？

#### 代码切分

webpack 的依赖树中有两种类型的依赖：同步和异步。异步依赖可作为一个切分点并形成一个新的块。
块树被优化后，对每个块生成一个文件。

#### Loaders

webpack 不仅能原生地处理 javascript，而且可使用 loaders 将其他资源转换成 javascript。
这样每个资源可生成一个模块。

#### 智能解析

webpack 具有一个智能的解析器能处理几乎所有的第三方类库。
它甚至允许依赖中存在像 `require("./templates/" + name + ".jade")` 这样的表达式。
它能处理最常见的模块风格： CommonJs 和 AMD。

#### 插件系统

webpack 以强大的插件系统为特色。大多数内部特性基于该插件系统。
这使你可以按需定制 webpack 及开源分发常用插件。

## 使用 Loaders [using-loaders]

### 什么事 Loaders

loaders 是应用在你的应用的资源文件上的转换。它们是接收资源文件作为参数并返回新的源码
的函数(运行在 node.js 上)。

### Loader 特性

* Loaders 可以串联。它们可作为管道应用到资源上。最终的 Loader 期望返回 javascript，
其他的可返回任意格式(传递给下一个 Loader)。
* Loaders 可以是同步或者异步的。
* Loaders 运行在 node.js 上且可完成所有可在其上完成的事情。
* Loaders 接收查询参数。这可用于给 Loader 传递参数。
* Loaders 可在配置中限制到扩展/正则表达式。
* Loaders 可通过 `npm` 发布/安装。
* 常规的模块在常规的 `main` 外可在 `package.json` 中暴露一个 `loader`。
* Loaders 可访问配置
* 插件可给予 Loaders 更多特性
* Loaders 可生成额外的任意文件
* etc.

### 解析 Loaders

Loaders 以类似于模块的方式被解析。一个 Loader 模块被期待暴露一个函数且以 node.js 
兼容的 javascript 书写。常规场景中你通过 `npm` 来管理 Loaders，但你也可以在应用中
以文件方式拥有 Loaders。

带 `-loader` 后缀的模板名会被尝试。

### 用法

存在多种方式在应用中使用 Loaders：

* 显式使用 `require` 语句
* 通过 CLI 配置
* 通过配置文件配置

#### Loaders in `require`

可以在 `require` 语句(或 `define`,`require.ensure`,etc.)中指定 Loaders。
只要用 `!` 分离 Loaders 和资源即可。每个部分都相对于当前目录进行解析。

#### CLI

可以通过 CLI 绑定 Loaders 到扩展名上。

#### 配置文件

可以通过配置将 Loaders 绑定到正则表达式上。

### 查询参数

Loaders 可通过查询字符串(像web一样)传递查询参数。查询字符串以前缀 `?` 追加到 Loader 上。

注： 查询字符串格式视加载器而定。

## CommonJs

## AMD

## Usage with grunt

## Usage with gulp