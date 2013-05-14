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

另一个偏好内嵌的权重考量是在写数据时有 **原子性** 和 **隔离性** 的需求。
MongoDB 被设计为不支持多文档事务。

#### 为灵活性而引用

规范化数据模型为多个集合可以给你在执行查询时更多的灵活性。

通常来讲，如果你的恶应用的查询模式已知且数据仅会以一种方式来访问，
内嵌方式工作良好。而如果你的应用会以多种不同的方式查询数据，
或你无法预期数据可能被查询的模式时，更“规范化”的方式会更好一些。

#### 为潜在的高元数关系而引用

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

而在 MongoDB 中我们可以在同一个集合中存储所有类型的文档，且仅存储 **相关的** 字段。

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

## 模仿事务行为

关系型数据库常依赖于原子性多语句事务的存在来确保数据的一致性：
或者一组语句所有的都成功，或者都失败，将数据库从一个自一致状态转换到另外一个。
然而当需扩展关系型数据库到多台物理服务器时，事务必须使用两相提交协议，它
显著地减慢了跨多服务器的事务。MongoDB 不允许多文档原子事务，有效地规避了该问题，
但随之而来的是如何在事务 **缺失** 的情况下维护数据库 一致性。

本章将探索 MongoDB 的文档模型及其原子更新操作如何使关系型数据库中需使用事务来维护
数据库一致性的方法。我们还会使用被称为 **补偿法** 的方式来模拟事务行为。

### 获取一致性的关系型方式

原子性多语句事务

跨服务器事务使用两相提交协议

### 复合文档

内嵌关联文档，删除时仅需删除复合文档

### 使用复杂的更新

内嵌文档仅解决了部分 **事务性** 问题。
读取全部文档，在内存中处理，然后整体更新回去的方式引入了竞态条件。
我们可以使用 MongoDB 的原子更新操作在单个步骤中执行相同的操作。
我们还有其他操作可能移除了我们将更新的项目的危险，因此我们会检查我们的更新是否成功，
如果失败，可能是因为有人删除了该项目，我们需试图将它以新的数量 push 进数组中。

	def increase_qty(order_id, sku, price, qty):
		total_update = price * qty
		while True:
			result = db.orders.update(
				{ '_id': order_id, 'items.sku': sku },
				{ '$inc': {
					'total': total_update,
					'items.$.qty': qty } })
			if result['updatedExisting']: break
			result = db.orders.update(
				{ '_id': order_id, 'items.sku': { '$ne': sku } },
				{ '$inc': { 'total': 110.22 },
					'$push': { 'items': { 'sku': sku,
										  'qty': qty,
										  'price': price } } })
			if result['updatedExisting']: break
			
### 用补偿法进行乐观更新

有时在 MongoDB 中不可能用单个 `update()` 来完成你的操作。
普通的两相提交可能会发生竞态条件。

该问题更好的方式是在数据模型中模仿事务。此处，我们将创建一个 `transaction`
集合包含了所有未解决的转换的状态的文档。

* 任何 `new` 状态的事务在超时时将回滚
* 任何 `committed` 状态的事务将总是(最终地)被退休
* 任何 `rollback` 状态的事务将总是(最终地)被撤销

我们的 `transaction` 集合包含文档的格式如下：

	{
		_id: ObjectId(...),
		state: 'new',
		ts: ISODateTime(...),
		amt: 55.22,
		src: 1,
		dst: 2
	}
	
我们的 `account` 模式也稍稍改变以存储待解决的事务 ID 。

	{ _id: 1, balance: 100, txns: [] }
	{ _id: 2, balance: 0, txns: [] }
	
顶层的 `transfer` 函数将一定的量从一个账号转换到另一个，但添加了该事务完成
的最大时间。如果事务花费了更长时间，将由一个周期性过程将其回滚。

	def transfer(amt, source, destination, max_txn_time):
		txn = prepare_transfer(amt, source, destination)
		commit_transfer(txn, max_txn_time)

现在我们有了一个两相提交模型，先准备账号，后提交事务。准备代码如下：

	def prepare_transfer(amt, source, destination):
		# Create a transaction object
		now = datetime.utcnow()
		txnid = ObjectId()
		txn = {
			'_id': txnid,
			'state': 'new',
			'ts': datetime.utcnow(),
			'amt': amt,
			'src': source,
			'dst': destination }
		db.transactions.insert(txn)
		# "Prepare" the accounts
		result = db.accounts.update(
			{ '_id': source, 'balance': { '$gte': amt } },
			{ '$inc': { 'balance': -amt },
				'$push': { 'txns': txn['_id'] } })
		if not result['updatedExisting']:
			db.transaction.remove({'_id': txnid})
			raise InsufficientFundsError(source)
		db.accounts.update(
			{ '_id': dest },
			{ '$inc': { 'balance': amt },
				'$push': { 'txns': txn['_id'] } })
		return txn
		
这里要注意两个关键点：

* 源和目标账号存储了待解决的事务的列表。这让我们可以跟踪某个特定事务ID是否是带决定
* 事务本身必须在特定的时间窗内完成。如果没有的话，一个周期性过程将根据其最终状态
回滚所有未解决事务或提交它们。这处理了应用或数据库在事务中间崩溃的情况。

下面是实际提交转换的函数：

	def commit_transfer(txn, max_txn_time):
		# Mark the transaction as committed
		now = datetime.utcnow()
		cutoff = now - max_txn_time
		result = db.transaction.update(
			{ '_id': txnid, 'state': 'new', 'ts': { '$gt': cutoff } },
			{ '$set': { 'state': 'commit' } })
		if not result['updatedExisting']:
			raise TransactionError(txn['_id'])
		else:
			retire_transaction(txn['_id'])

该函数的主要目的是执行事务状态从 `new` 到 `commit` 的原子更新。
如果更新成功，事务将被退休，即使更新后发生了崩溃。
要实际退休该事务，我们使用以下函数：

	def retire_transaction(txn_id):
		db.accounts.update(
			{ '_id': txn['src'], 'txns._id': txn_id },
			{ '$pull': { 'txns': txn_id } })
		db.accounts.update(
			{ '_id': txn['dst'], 'txns._id': txn['_id'] },
			{ '$pull': { 'txns': txn_id } })
		db.transaction.remove({'_id': txn_id})
		
注意 `retire_transaction` 函数式 **幂等的** ：它可以用相同的 `txn_id` 调用
任意多次，得到的效果和调用一次一样。这意味着如果我们在移除事务对象前
的任意时刻崩溃，随后的清楚进程依旧可以通过简单地调用 `retire_transaction` 退休该事务。

现在我们需要在周期性清除任务中处理超时事务或提交或回滚过程中崩溃的事务。

	def cleanup_transactions(txn, max_txn_time):
		# Find & commit partially-committed transactions
		for txn in db.transaction.find({ 'state': 'commit' }, {'_id': 1}):
			retire_transaction(txn['_id'])
		# Move expired transactions to 'rollback' status:
		cutoff = now - max_txn_time
		db.transaction.update(
			{ '_id': txnid, 'state': 'new', 'ts': { '$lt': cutoff } },
			{ '$set': { 'state': 'rollback' } })
		# Actually rollback transactions
		for txn in db.transaction.find({ 'state': 'rollback' }):
			rollback_transfer()
			
最后，如果我们想回滚一个事务，我们需要更新事务对象并 **撤销** 转换的效果：

	def rollback_transfer(txn):
		db.accounts.update(
			{ '_id': txn['src'], 'txns._id': txn['_id'] },
			{ '$inc': { 'balance': txn['amt'] },
				'$pull': { 'txns': { '_id': txn['_id'] } } })
		db.accounts.update(
			{ '_id': txn['dst'], 'txns._id': txn['_id'] },
			{ '$inc': { 'balance': -txn['amt'] },
				'$pull': { 'txns': { '_id': txn['_id'] } } })
		db.transaction.remove({'_id': txn['_id']})

特别注意，前面的代码仅撤销那些事务依旧存储在账号的 `txns` 数组中的账号的事务。
这使得事务的回滚和通过提交退休一样是幂等的。