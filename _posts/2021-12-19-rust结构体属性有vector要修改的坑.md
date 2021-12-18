---
Title: rust结构体属性与vector要修改时的坑
key: rust_struct_vector
layout: article
date: '2021-12-19 15:50:00'
tags:  rust
typora-root-url: ../../iblog

---

这里结构体Prog有个属性stmts类型是vector类型。我想要在迭代`self.prog.stmts`的过程中，去修改`self.prog.stmts`里面的元素的值。

为了修改，不得不把迭代改成`self.prog.stmts.iter_mut`但是，由于赋值的时候也会修改`self`，所以必须是`&mut self`，

那么就同时有两个可变变量了。

为了解决这一问题，我采用的方案是。对`self.prog.stmts`就行clone然后只读迭代，通过索引找到`self.prog.stmts`的位置，通过索引进行修改，这样就是只改`self`了。

```rust
pub struct Prog {
    pub stmts: Vec<Statement>,
}
impl RefResolver {
    pub fn new(prog: Prog) -> Self {
        Self { prog }
    }
    pub fn vist_prog(&mut self) {
        for stat in self.prog.stmts.iter() {
            match stat {
                Statement::FunctionDecl(f) => self.visit_function_decl(f),
                _ => {}
            }
        }
        // rust不能有两个可变借用，因为要修改self上的值， self必须是可变借用， stmts就不能再可变借用了。
        //也不能对stmts同时进行可读和可写。所以self.prog.stmts进行了clone遍历。通过下表赋值修改原来的stmts
        for (i, stat) in self.prog.stmts.clone().iter().enumerate() {
            match stat {
                Statement::FunctionCall(f) => {
                    if let Some(t) = self.resolve_function_call(f) {
                        self.prog.stmts[i] = Statement::FunctionDecl(t)
                    }
                }
                _ => {}
            }
        }
    }
```

