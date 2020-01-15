

* 疑问: 使用 import_role 语句时的 handler 触发问题
    * 如果现在的 role 中与引用的 role 有相同名称的 handler, 那么触发哪个?
        * 测试结果，即使“被引用 role” 和 "当前 role" 同时存在相同名称的 handler,其触发的仍然是 "被引用 role" 的 handler
        * 但是如果 '被引用的 role'中定义的 handler 只在 '当前 role' 中有，那么就会用‘当前 role’中的handler
        * 如果“被引用的 role” 和 “当前的 role” 中都没有找到相关的 handler, 那么还在其他“被引用的 role”中找寻 “相同名字的 handler”(在一个 role,同时引入多个 role时)，就近原则
    
    * 当role引用role 时，如需要使用 handler, 应该只在基础role中定义 notify 的引用，而在调用 role中进行实际定义
        * 如果某个调用的 role 不能触发 handler, 比如 mysql 即使更改了配置文件，也不期望其触发重启的操作，那么可以在调用的 role 里定义一个并不实际执行的 handler,这样不影响基础 role 的运行。也实现了定制化

    * 如果不在基础 role 中写 handler, 引用 role的 import_role 时如何定义触发 handler ?
    
    * 发现一个 listen 关键字，测试如下
        * 当`notify: test_handler`时，如果没有 handler 使用 listen 关键字，那么就调用`name: test_handler`的任务
        * 如果既有 `name: test_handler` 的任务，也有 `listen: test_handler `的，两个都会执行
        * 如果两个都没有，会报错停止 `ERROR! The requested handler 'test_handler' was not found in either the main handlers list nor in the listening handlers list`


