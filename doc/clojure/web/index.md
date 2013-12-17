Title: 使用 Clojure 进行 WEB 开发
Author: 刘龙彪
css: http://netdna.bootstrapcdn.com/twitter-bootstrap/2.3.2/css/bootstrap-combined.min.css
HTML header: <script src="../../../js/seajs/2.1.1/sea.js"></script>
	<script src="../../../js/config.js"></script>
	<script>seajs.use("init");</script>

## Clojure Web 开发

本文中，将对使用 Clojure 进行 Web 开发作一个简要的概述。

### 开发工具

就像 Maven 之于 Java，sbt 之于 Scala，Clojure 也有一个项目构建工具 -- [Leiningen](leiningen/leiningen.html) 。

Clojure 开发支持较好的 IDE 是 Intellij IDEA ，下载后，在 plugins 中查找并安装
La Clojure 插件和 Leiningen 插件。

### 选型

作为一个 Web 项目，自然要考虑到浏览器支持。Windows 7 自 2009 年发布以来已经经历了五个年头。
台式机的生命周期大约五年，考虑到当下现代浏览器的氛围，放弃掉对 IE 6/7 的支持是可行的。

jQuery 以其 “写更少代码，做更多事情” 的理念，赢得了开发人员的广泛关注。但是随着 Web 应用的日渐复杂，
jQuery 在协调更大型得应用的代码结构方面有些力不从心。要管理前端代码的复杂度，引入一个成熟的应用框架
势在必行。

像 Extjs 、Dojo 、GWT 这样的富客户端略显笨重。Backbone.js 是一款比较成熟的轻量级 MVC 框架。
它本身不关注视图渲染，这部分通常交由模板引擎来完成。由此，它比较类似后端的程序，在渲染完成后，和 DOM 之间
的交互交由其他框架来完成。Knockout.js 是一款 MVVM 框架，ViewModel 充当了程序和视图之间的连接器。
因此，它能够完成双向绑定等功能。AngularJs 是 Google 推出的一款 MVW(Model-View-Whatever) 框架，
它不像很多其他的 js 框架一样仅完成单独的某部分功能，它是一个完整的应用框架，包含了具有双向绑定的声明式模板、
MVC、依赖注入等等功能。