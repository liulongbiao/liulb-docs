Title: MongoDB 应用设计模式阅读笔记
Author: LiuLongbiao
css: http://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/2.3.1/css/bootstrap.min.css
HTML header: <script src="../../js/init.js"></script>

本文用来记录《MongoDB 应用设计模式》的阅读笔记

## 内嵌还是引用

构建新应用的时候，通常第一件想做的事情就是设计数据模型。
在关系型数据库中，这通常由规范化的过程来形式化，关注于从一系列表中移除冗余。
而 MongoDB 将其数据以结构化文档的形式存储。MongoDB 丰富的文档模型给了你更多的选择空间，
本章就探讨其中一个：你应该在对象中内嵌相关对象还是通过 ID 引用它们。

### 关系型数据库的规范化

* 第一范型：每个行的列值仅能包含一个（仅含一个）值
* 第三范型：
* 规范化以去除冗余
* 取数据需昂贵的 JOIN 操作
* 若去规范化，则更新时需确保同步更新多处

### MongoDB：谁还需要规范化？

MongoDB 中，数据以文档形式存储，可以在列中存储值的数组。

因为 MongoDB 原生支持多值属性，去规范化后可获得性能提升，而不会在更新冗余数据时引入很多困难。
然而这也使得我们的模式设计过程更加复杂。

#### MongoDB 文档格式

MongoDB 建模自 JSON 格式，以 BSON 格式存储。简单地讲 MongoDB 文档即一个键值对字典，
其中值可以是以下几种类型的一种：
* 原生 JSON 类型(如，number, string, Boolean)
* 原生 BSON 类型(如， datetime, ObjectId, UUID, regex)
* 值的数组
* 由键值对组合而成的对象
* null

#### 为本地化而内嵌

一个你想将一对多关系内嵌的原因可能是数据本地化。
MongoDB 将文档在硬盘中顺序存储，因此将所有数据放到一个文档意味着你仅需要一个硬盘
寻址操作来获取所有你需要的东西。

MongoDB 也有一个局限性（因数据库分区简单化的需求所驱动），它没有 JOIN 操作可用。
因此你需要在应用层手动完成，如：

	contact_info = db.contacts.find_one({'_id': 3})
	number_info = list(db.numbers.find({'contact_id': 3})
	
这实际上比关系型的 `JOIN` 操作更糟。
因此如果你的应用总是频繁访问带有所有电话号码的联系人信息的话，
你几乎总是希望将电话号码嵌入联系人信息记录中。

#### 为原子性和隔离性而内嵌

另一个偏好内嵌的权重考量是在写数据时有 *原子性* 和 *隔离性* 的需求。
MongoDB 被设计为不支持多文档事务。

#### 为灵活性而引用

规范化数据模型为多个集合可以给你在执行查询时更多的灵活性。

通常来讲，如果你的恶应用的查询模式已知且数据仅会以一种方式来访问，
内嵌方式工作良好。而如果你的应用会以多种不同的方式查询数据，
或你无法预期数据可能被查询的模式时，更“规范化”的方式会更好一些。

#### 为潜在地高元数关系而引用

另一个偏好使用引用的更规范化模型的权重因子是你的一对多关系可能有非常高
或不可预期的元数。在这种情况下，内嵌会有显著的处罚：
* 文档越大，所用的 RAM 越多
* 增长的文档必须最终被拷贝到更大的空间
* MongoDB 文档具有硬性的尺寸限制 16MB

#### 多对多关系

另一个偏向使用文档引用的因子是多对多或 M:N 关系。

* 模仿关系型数据库模式 -- join 过多
* 完全内嵌 -- 查询简单，但更新时不仅需要更新自身集合，还需要更新所有所嵌入的其他文档
* 折中方案 -- 内嵌一系列 `_id` 而不是整个文档

## 多态模式

MongoDB 有时被认为是一个“无模式”数据库，即它不强制集合中文档具备某个特殊结构。
在一个设计良好的应用中，一个集合会包含相同的或非常相关的结构的文档。
如果集合中所有的文档都类似，但结构不是完全相同的，我们称其为多态模式。

### 多态模式以支持面向对象编程

关系型数据库要支持继承关系建模：
* 创建包含所有可能包含字段的联合，但这会浪费大量空间
* 给每个具体子类创建一个表，但这引入了冗余
* 创建通用表作为基本内容，join 具体的表。

而在 MongoDB 中我们可以在同一个集合中存储所有类型的文档，且仅存储 *相关的* 字段。

关系型数据库中查询时涉及三相 join，而 MongoDB 中的查询则简单得多。

### 多态模式使模式进化成为可能

关系型数据库中模式进化需精心设计的迁移脚本。

MongoDB 中可以一次性更新所有文档：

	db.nodes.update(
		{},
		{$set: { short_description: '' } },
		false, // upsert
		true // multi
		);

但这样在数据量很大时也会影响应用性能。

可选择先在应用层手动处理缺失值

	def get_node_by_url(url):
		node = db.nodes.find_one({'url': url})
		node.setdefault('short_description', '')
		return node
		
然后我们可能选择在后台增量迁移集合，如一次 100 个文档：

	def add_short_descriptions():
		node_ids_to_migrate = db.nodes.find(
		{'short_description': {'$exists':False}}).limit(100)
		db.nodes.update(
		{ '_id': {'$in': node_ids_to_migrate } },
		{ '$set': { 'short_description': '' } },
		multi=True)
		
全部迁移完成后我们就可以忽略默认值了：

	def get_node_by_url(url):
		node = db.nodes.find_one({'url': url})
		return node

#### BSON 存储效率(低效性)

关系型数据库中字段名和类型定义在表级别，而 MongoDB 中字段信息必须被保存在文档中。
特别的，当你存储小型的值，但使用长的属性名时，实际存储量比关系型数据库中会大很多。

Object-Document Mappers

### 多态模式支持半结构化领域数据

一种方式是可以使用通用的子文档属性 `properties` 来包含可变的字段。

	{
		_id: ObjectId(...),
		price: 499.99,
		title: 'Big and Fast Disk Drive',
		gb_capacity: 1000,
		properties: {
		'Seek Time': '5ms',
		'Rotational Speed': '15k RPM',
		'Transfer Rate': '...'
		... }
	}
	
存储半结构化数据的缺点是难以执行查询及在你希望你的应用不知道的字段上建索引。

另一种可能使用的方式是包含属性-值对的一个数组：

	{
		_id: ObjectId(...),
		price: 499.99,
		title: 'Big and Fast Disk Drive',
		gb_capacity: 1000,
		properties: [
		['Seek Time', '5ms' ],
		['Rotational Speed', '15k RPM'],
		['Transfer Rate', '...'],
		... ]
	}
	
用这种方式，我们可以用下面命令让 MongoDB 在 `properties` 字段上建索引：

	db.products.ensure_index('properties')
	
有了索引，我们对指定属性值对的查询如下：

	db.products.find({'properties': [ 'Seek Time': '5ms' ]})
	
### 小结

MongoDB 通过不强制集合中所有文档遵循特定模式的灵活性提供了比 RDBMS 一些好处：

* 更好的面向对象继承和多态
* 模式间更简单的迁移，及更少的应用停机时间
* 更好的支持半结构化领域数据