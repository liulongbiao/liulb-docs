Title: Leiningen
Author: 刘龙彪
css: http://netdna.bootstrapcdn.com/twitter-bootstrap/2.3.2/css/bootstrap-combined.min.css
css: http://yandex.st/highlightjs/7.5/styles/rainbow.min.css
HTML header: <script src="../../../../js/seajs/2.1.1/sea.js"></script>
	<script src="../../../../js/config.js"></script>
	<script>seajs.use("init");</script>

##  Leiningen

Leiningen 是开始使用 Clojure 的最简单的方式，它关注项目的自动化及声明式的配置，让你可以专注于你的代码。

    (defproject leiningen.org "1.0.0"
      :description "Generate static HTML for http://leiningen.org"
      :dependencies [[enlive "1.0.1"]
                     [cheshire "4.0.0"]
                     [org.markdownj/markdownj "0.3.0-1.0.2b4"]]
      :main leiningen.web)

#### 安装

1. 下载 [lein 脚本](https://raw.github.com/technomancy/leiningen/stable/bin/lein)，
    Windows 上对应为 [lein.bat](https://raw.github.com/technomancy/leiningen/stable/bin/lein.bat)。
2. 将其放置到系统路径中
3. 添加可执行权限

#### 文档

这个 [教程](https://github.com/technomancy/leiningen/blob/stable/doc/TUTORIAL.md) 是最好的起步文档。
如果你已经安装了 Leiningen， 可以运行 `lein help tutorial`。