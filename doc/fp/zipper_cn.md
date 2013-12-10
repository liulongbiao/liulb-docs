The Zipper
===========

Auther: GERARD HUET (INRIA Rocquencourt, France)

## 简评

几乎所有的程序员都遇到过表示一个具有一个关注点子树的树结构的问题，
其中该关注点可能是在树上做上下左右移动。
The Zipper 是 Huet 对一个能够满足该需求的俏皮的数据结构的俏皮的名称。
我真希望在以前面对该问题时就已经知道了它，因为我所得到的方案没有像 Zipper 这样高效和优雅。

## 简介

纯应用式编程范式的一个主要缺点是很多高效的算法在诸如位向量或字符数组
或其他可变层级分类结构等数据结构上使用了破坏性的操作，
而这些操作无法直接地建模为可应用式数据结构。
一个对该问题的著名的方案称为 **函数式数组(Paulson, 1991)** 。
对于树而言，这意味着，通过拷贝从树的根节点到它的路径来非破坏性地修改某个节点出现。
这在当数据结构仅是某个算法的内部对象的时候是可接受的，
其消耗相对于拷贝整个树的原始方案是对数级别的。
但是，当数据结构表示某些全局上下文时，如文本编辑器的缓冲区
或某个证明系统中原理和前提的数据库时，这种技术是被禁止的。
本文中，我们解释了一个简单的方案，其树编辑完全是本地化的，其在数据上的处理不是
在树的原始根节点上，而是在树的当前位置上。

其基本思想很简单： 树被像一个反转的手套一样内外反转，从根节点到当前位置的指针被
反转在一个路径 (path) 结构中。当前位置 (location) 同时持有下方的当前子树和上方的路径。
所有的导航和修改基本操作都作用在位置 (location) 结构上。在结构中上下移动就类似于
在某片衣服上关闭和开启一个拉链，由此得名。

作者在设计一个结构化编辑器的核心时杜撰了这个数据类型，以用作一个证明助理的结构管理器。
这个简单的想法肯定在很多地方被具有创造力的程序员发明了，这里给出的这个可能为大家所俗知的
介绍理由是它还没有被发布过，或者说不是非常出名。

== The Zipper 数据结构

在基本想法上，存在很多的变体。首先，我们先展示一个适用于具有可变元匿名树节点，且
树的叶节点注入的是一个未指定的 item 类型的值的树。

=== Trees, paths and locations

假设我们想层级地操作一个类型参数为 item 的元素；树结构仅是将树分组为一个 section 的层级列表。
例如，在 UNIX 文件系统中，items 将是文件，而 sections 将是目录；而文本编辑器中 items 将是字符，
而两层的 sections 就是将缓冲表示为行的列表以及将行表示为字符的列表。 泛化到任意层级，
我们可以得到一个层级图灵机的表示法，其中一个 tape 位置可能包含一个标识或这一个从某个更低层级
得到的 tape。

这里提供的所有算法都以 OCaml(Leroy et al. 1996) 语言书写。
但这里的代码可以很容易地转换成任何语言，不管是否是函数式的，也不管是否是惰性的。

	type tree = 
		Item of item
	  | Section of tree list;;

现在考虑树中的某个路径(path)：

	type path =
		Top
	  | Node of tree list * path * tree list;;

一个 path 就像一个拉链，允许我们撕开树结构直到某个特定的位置。
一个 `Node(l,p,r)` 包含了其年长的兄长节点的列表 `l` (从最年长的开始)，其父路径 `p`，
以及其年幼的弟弟节点 (从最年幼的开始)。

> 一个由路径表示的树具有兄弟树、叔伯树、叔祖树等，但其父是一个 `path` ，而不是
想通常的图形编辑器中的树。

一个树中的 `location` 具有一个子树，以及其 `path` 。

	type location = Loc of tree * path;;

一个 `location` 由一个可区别的 `tree` ，当前的关注点及其表示其环绕的上下文的 `path` 组成。
注意，一个 `location` 并不对应于树中的某个存在，如我们所假设的，比如在项重写理论(Huet, 1980) 或
在树编辑器 (Donzeau-Gouge et al., 1984)中。
它仅仅是链接指定子树到环绕的上下文的弧的一个指针。

> 示例：假设考虑带字符串项的数学表达式的解析树。表达式 `a × b + c × d` 解析为：

	Section[Section[Item "a"; Item "*"; Item "b"];
		Item "+";
		Section[Item "c"; Item "*"; Item "d"]];;

树中第二个乘号的 `location` 是：

Loc(Item "*",
    Node([Item "c"],
        Node([Item "+"; Section [Item "a"; Item "*"; Item "b"]],
            Top,
            []),
        [Item "d"]))

### 树中的导航原语

	let go_left (Loc(t,p)) = match p with
		Top -> failwith "left of top"
	  | Node(l::left,up,right) -> Loc(l,Node(left,up,t::right))
	  | Node([],up,right) -> failwith "left of first";;

	let go_right (Loc(t,p)) = match p with
		Top -> failwith "right of top"
	  | Node(left,up,r::right) -> Loc(r,Node(t::left,up,right))
	  | _ -> failwith "right of last";;

	let go_up (Loc(t,p)) = match p with
		Top -> failwith "up of top"
	  | Node(left,up,right) -> Loc(Section((rev left) @ (t::right)),up);;

	let go_down (Loc(t,p)) = match t with
		Item(_) -> failwith "down of item"
	  | Section(t1::trees) -> Loc(t1,Node([],p,trees))
	  | _ -> failwith "down of empty";;

注：所有的导航原语都仅花费常量时间，除了 `go_up`，它正比于当前项的“后辈” `list_length(left)`。

我们可以用这些导航原语来编写访问当前树的 nth 子节点。

let nth loc = nthrec
  where rec nthrec = function
    1 -> go_down(loc)
  | n -> if n>0 then go_right(nthrec (n-1))
                else failwith "nth expects a positive integer";;

### 变更、插入和删除

我们可以在当前问题以本地操作方式修改结构：

	let change (Loc(_,p)) t = Loc(t,p);;

在左侧或右侧插入非常自然和便宜：

	let insert_right (Loc(t,p)) r = match p with
		Top -> failwith "insert of top"
	  | Node(left,up,right) -> Loc(t,Node(left,up,r::right));;
	let insert_left (Loc(t,p)) l = match p with
		Top -> failwith "insert of top"
	  | Node(left,up,right) -> Loc(t,Node(l::left,up,right));;
	let insert_down (Loc(t,p)) t1 = match t with
		Item(_) -> failwith "down of item"
	  | Section(sons) -> Loc(t1,Node([],p,sons));;

我们也可能像实现一个删除原语。我们可以选择右移，如果可能的话，否则左移，再则如果是空列表的
话则上移。

let delete (Loc(_,p)) = match p with
    Top -> failwith "delete of top"
  | Node(left,up,r::right) -> Loc(r,Node(left,up,right))
  | Node(l::left,up,[]) -> Loc(l,Node(left,up,[]))
  | Node([],up,[]) -> Loc(Section[],up);;

注意到， `delete` 并不是很简单的操作。

我们相信上述的数据类型和操作集对以应用式却高效的方式来编写结构化编辑已经足够胜任了。

## 基本思想的变体

### Scars

当一个算法具有频繁的需要上移树并下移到相同位置的操作时，这会很耗时间(以及空间和GC时间等)
以同时关闭 sections 。如果在结构中留下“伤疤”，允许直接访问已记住的已访问节点，可能会很有益。
因此，我们将(非空) sections 替换为记住了一个 tree 和其兄弟的 triples ：

	type memo_tree =
		Item of item
	  | Siblings of memo_tree list * memo_tree * memo_tree list;;
	type memo_path =
		Top
	  | Node of memo_tree list * memo_path * memo_tree list;;
	type memo_location = Loc of memo_tree * memo_path;;

我们展示了在这些新结构上的简化的上移、下移操作：

let go_up_memo (Loc(t,p)) = match p with
    Top -> failwith "up of top"
  | Node(left,p',right) -> Loc(Siblings(left,t,right),p');;
let go_down_memo (Loc(t,p)) = match t with
    Item(_) -> failwith "down of item"
  | Siblings(left,t',right) -> Loc(t',Node(left,p,right));;

改编其他原语留给读者自行完成。

### 一阶项

到此为止，我们的结构都完全是无类型的 - - 我们的树节点甚至没有标签。
我们有一种结构化的编辑器，即 LISP， 但更倾向于 `splicing` 操作而不是常见的 `rplaca`
和 `rplacd` 原语。

如果我们想实现一个针对抽象语法树的树操作编辑器，我们需要用操作名给我们的树节点打标签。
如果我们为这个目的使用项，则它建议常见的 LISP 一阶项的编码: `F(T1; ...;Tn)` 
被编码为树 `Section[Item(F); T1; ... Tn]` 。一个推荐的对偶的方案来自组合逻辑，
其中使用了梳状的结构表示应用排序: `[Tn; ... T1; Item(F)]` 。然而，这些方案都不涉及元数。

我们不应再跟进如此泛化的变体的细节了，转而应当考虑如何调整思想到某个特定的由其元数
给出操作签名的场景，这种方式下树的编辑根据元数来维护树的完整性。

基本地，对每个带 `n` 元数的签名的构造器 `F`，我们给每个元数 `n`，其中 `1 ≤ i ≤ n`，
都关联一个路径操作符 `Node(F, i)`，用于下移至某个 `F-term` 的第 i 个子树。
更确切的说，`Node(F, i)` 有一个 `path` 参数和 `n-1` 个树参数来持有当前的兄弟树。

作为示例，我们这里展示了二叉树所对应的结构：

type binary_tree =
Nil
| Cons of binary_tree * binary_tree;;
type binary_path =
Top
| Left of binary_path * binary_tree
| Right of binary_tree * binary_path;;
type binary_location = Loc of binary_tree * binary_path;;
let change (Loc(_,p)) t = Loc(t,p);;
let go_left (Loc(t,p)) = match p with
Top -> failwith "left of top"
| Left(father,right) -> failwith "left of Left"
| Right(left,father) -> Loc(left,Left(father,t));;
let go_right (Loc(t,p)) = match p with
Top -> failwith "right of top"
| Left(father,right) -> Loc(right,Right(t,father))
| Right(left,father) -> failwith "right of Right";;
let go_up (Loc(t,p)) = match p with
Top -> failwith "up of top"
| Left(father,right) -> Loc(Cons(t,right),father)
| Right(left,father) -> Loc(Cons(left,t),father);;
let go_first (Loc(t,p)) = match t with
Nil -> failwith "first of Nil"
| Cons(left,right) -> Loc(left,Left(p,right));;
let go_second (Loc(t,p)) = match t with
Nil -> failwith "second of Nil"
| Cons(left,right) -> Loc(right,Right(left,p));;

高效的二叉树上的破坏性算法可以很容易地完全用这些应用性方法编写，其中全部都花费常量时间，
因为它们都归纳为本地指针操作。

## 参考

* Donzeau-Gouge, V., Huet, G., Kahn, G. and Lang, B. (1984) <br/>
Programming environments based on structured editors: the MENTOR experience. 
In: Barstow, D., Shrobe, H. and Sandewall, E., editors, Interactive Programming Environments. 128{140. McGraw Hill.
* Huet, G. (1980) <br/>
Confluent reductions: abstract properties and applications to term rewriting
systems. J. ACM, 27(4), 797{821.
* Leroy, X., Remy, D. and Vouillon, J. (1996) <br/>
The Objective Caml system, documentation
and user's manual { release 1.02. INRIA, France. (Available at
ftp.inria.fr:INRIA/Projects/cristal)
* Paulson, L. C. (1991) <br/>
ML for the Working Programmer. Cambridge University Press.
