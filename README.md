​

# gRpc_go_dart-1.编写第一个服务

# 通俗的讲下grpc

 简化掉所有复杂的实现,它要求服务端和客户端之间按照protobuf的规范进行数据交换,所以服务端和客户端都不用关心彼此的代码实现,只关心按照protobuf的形式提供数据

# 为什么是go和dart

技术栈,已经是google的形状了

 同时,go客户端和Flutter间本身通过http协议不好交接数据,用grpc更快更方便

# Hello,World

这个章节将教会你实现用go编写服务端提供grpc接口,而在flutter中定义一个按钮和输入框输入姓名来请求go服务端并获取信息

# 核心的规范文件-protobuf-及基于go的grpc服务端实现

1. protobuf是grpc中最重要的文件,它规定了服务端与客户端之间通信的规范,同时我们也要求客户端和服务端中的protobuf文件必须完全一致,所以让我们首先来编写这个protobuf文件,让我们思考一下这个pro文件要实现什么功能

2. 它应当有一个服务获取请求的字符后返回Hello world + name 字符串

3. 我们首先编写人类可读的proto文件,这个文件是人类可以阅读的:

4. ```bash
   syntax = "proto3";
   //指定了 Go 语言代码生成后应该放置在名为 "github.com/rn-consider/grpcservice/helloworld" 的包中,
   //会影响生成的 .pb.go 文件的 package 声明
   option go_package = "github.com/rn-consider/grpcservice/helloworld";
   option java_multiple_files = true;
   option java_package = "io.helloworld.examples.helloworld";
   option java_outer_classname = "HelloWorldProto";
   
   package helloworld;
   
   // 此处定义服务,为协议缓冲区中的服务定义
   service Greeter {
     /*
     提供SayHello函数,接受HelloRequest类型的消息,
     返回HelloReply类型的消息在grpc中,函数必须始终具有输入消息并返回输出消息
     */
     // Sends a greeting
     rpc SayHello (HelloRequest) returns (HelloReply) {}
   
     // Sends another greeting
     rpc SayHelloAgain (HelloRequest) returns (HelloReply) {}
   
   }
   
   // 要求传入参数必须要name
   message HelloRequest {
     /*
     字段的设计十分重要,应谨慎分配字段编号,切勿更改,且在设计时考虑未来的修订
     消息中的字段定义必须指定三件事:类型,名称,编号
     字段的类型可以是当前支持的整数类型(int32,int64等),float,double,bool,字符串,字节(用于任何数据)
     要注意的是字段名称必须全部小写,并使用_分隔多个单词.
     如first_name,字段编号表示字段在消息中的位置,如name = 1表示name在返回信息中占第一位
     字段编号可以从1到2^29
     推荐在字段编号内留下间距,例如将第一个字段编号为1,然后将10用于下一个字段
     这意味着可在稍后添加任何其他字段而不需要对字段进行编号
     */
     string name = 1;
   }
   
   // 要求返回参数必须要是message
   message HelloReply {
     string message = 1;
   }
   ```

5. 然后我们使用proto工具将这个人类proto转化为用于客户端和服务端定义的接口文件.我们永远不会手动编辑这些文件:

6. ```bash
   protoc --go_out=. --go_opt=paths=source_relative \
      --go-grpc_out=. --go-grpc_opt=paths=source_relative \
      helloworld/helloworld.proto
   ```

7. windows下执行:

8. ```bash
   protoc --go_out=. --go_opt=paths=source_relative "--go-grpc_out=." "--go-grpc_opt=paths=source_relative" helloworld\helloworld.proto
   ```

9. 获得如下的文件,现在项目结构应该如:

10. ![Image1](https://img-blog.csdnimg.cn/img_convert/57155da27b46733a97f42735c7b45707.png)

11. 接下来我们在main函数中导入,并实现在pb中定义的函数

12. ```Go
    // Package main implements a server for Greeter service.
    package main
    
    import (
        "context"
        "log"
        "net"
    
        pb "github.com/rn-consider/grpcservice/helloworld"
        "google.golang.org/grpc"
    )
    
    // server 用来实现pb中的helloworld.GreeterServer.
    type server struct {
        pb.UnimplementedGreeterServer
    }
    
    // SayHello 实现helloworld.GreeterServer
    func (s *server) SayHello(ctx context.Context, in *pb.HelloRequest) (*pb.HelloReply, error) {
        log.Printf("Received: %v", in.GetName())
        return &pb.HelloReply{Message: "Hello " + in.GetName()}, nil
    }
    
    func (s *server) SayHelloAgain(ctx context.Context, in *pb.HelloRequest) (*pb.HelloReply, error) {
        return &pb.HelloReply{Message: "Hello again " + in.GetName()}, nil
    }
    
    func main() {
        // grpc服务默认应该运行在50051端口
        lis, err := net.Listen("tcp", ":50051")
        if err != nil {
            log.Fatalf("报错: %v", err)
        }
        s := grpc.NewServer()
    
        // 注册服务
        pb.RegisterGreeterServer(s, &server{})
        log.Printf("server listening at %v", lis.Addr())
        if err := s.Serve(lis); err != nil {
            log.Fatalf("failed to serve: %v", err)
        }
    }
    ```
    
    当看到输出时,说明gRpc的服务端已经运行成功

![](https://img-blog.csdnimg.cn/img_convert/5a536c0ee43d95007ae4c69f783b411d.png)

# 基于go服务端中的protobuf文件实现dart客户端

**注意:环境要求安装dart-sdk或者flutter**

当我们想要使用dart快速创建一个项目,因为我们要创建供flutter使用的客户端,使用

dart项目命名规范要求全部小写,用_来分隔单词,建议直接全小写了,dart是很严格的语言

```
dart create -t package helloworld
```

删掉不必要的文件并增加存放protos和其编译后文件的项目结构应该如

![](https://img-blog.csdnimg.cn/img_convert/2e3eb9fd706819cd9c798d8240bc0a0a.png)

- 编辑我们把go服务端写好的proto文件复制到protos目录下,往

- `pubspec.yaml`里添加依赖,:后不加版本号默认获取最新：

- ```
  dependencies:
    # path: ^1.8.0
    async: ^2.2.0
    grpc: ^3.2.4
    protobuf: ^3.0.0
  
  dev_dependencies:
    lints: ^2.0.0
    test: ^1.21.0
  ```

- 然后运行:

- protoc --dart_out=grpc:lib/src/generated -Iprotos protos/helloworld.proto

- 接下来我们在bin中增加client.dart文件,我们将在其中实现grpc客户端,删除不必要的文件后项目结构应该如:

- ![](https://img-blog.csdnimg.cn/img_convert/cc6224f2055298c904c373d3d9e5428d.png)

- 接下来我们在dart.client里添加代码

- ```
  import 'package:grpc/grpc.dart';
  import 'package:helloworld/src/generated/helloworld.pbgrpc.dart';
  
  class GreeterService {
    late ClientChannel _channel;
    late GreeterClient _stub;
  
    GreeterService(String host, int port) {
      _channel = ClientChannel(
        host,
        port: port,
        options: ChannelOptions(
          credentials: ChannelCredentials.insecure(),
        ),
      );
      _stub = GreeterClient(_channel);
    }
  
    Future<String> callSayHello(String name) async {
      try {
        final response = await _stub.sayHello(
          HelloRequest()..name = name,
        );
        return response.message;
      } catch (e) {
        print('Caught error: $e');
        return 'Error occurred';
      } finally {
        await _channel.shutdown();
      }
    }
  }
  ```

运行了go service后我们可以新建测试目录测试dart clilent

并在test/client_test.dart中加入以下代码:

```
import 'package:test/test.dart';
import 'package:helloworld/bin/client.dart'; // 根据实际路径进行调整

void main() {
  group('GreeterService', () {
    late GreeterService greeterService;

    setUp(() {
      greeterService = GreeterService('localhost',50051);
    });

    test('callSayHello returns correct message', () async {
      final name = 'John';
      final result = await greeterService.callSayHello(name);
      expect(result, 'Hello $name');
    });

    test('callSayHello handles error', () async {
      final name = 'Error';
      final result = await greeterService.callSayHello(name);
      expect(result, 'Hello Error');
    });
  });
}
```

可看见测试通过:

![](https://img-blog.csdnimg.cn/img_convert/de1f9559dbeac89e88eec16669a3a859.png)

# 将上一步的dart客户端整合为Packages

因为我们一开始就是基于Package创建的项目所以现在只需要在lib目录下创建与项目同名的dart文件,在这里我们导出bin/client中的GreeterService:

![Image2](https://img-blog.csdnimg.cn/img_convert/f5338f40d77dd3b54ac5b811d27116c7.png)

然后新建flutter项目并且按照顺序

更改pubspec.yaml中的依赖项我们让它能索引到本地包

![](https://img-blog.csdnimg.cn/img_convert/c86d076601775bede683397a8c3a60cb.png)

在lib/main.dart中添加以下代码

# flutter调用dart客户端

- - 首先新建一flutter项目,初始的flutter项目结构如:
  
  - ![](https://img-blog.csdnimg.cn/img_convert/a3c0f5ed2fabca42a3381aec5bda18cf.png)
  
  - 我们的源代码应该放在lib目录中:
  
  - ![](https://img-blog.csdnimg.cn/img_convert/809ceef6e3a4507ba719cf2b7796d499.png)
  
  - 让我们在main.dart中调用它:
  
  - ```
    import 'package:flutter/material.dart';
    import 'package:helloworld/helloworld.dart'; // 根据实际路径进行调整
    
    void main() {
      runApp(MyApp());
    }
    
    class MyApp extends StatelessWidget {
      @override
      Widget build(BuildContext context) {
        final greeterService = GreeterService('localhost',50051);
    
        return MaterialApp(
          title: 'Flutter gRPC Example',
          home: MyHomePage(greeterService: greeterService),
        );
      }
    }
    
    class MyHomePage extends StatefulWidget {
      final GreeterService greeterService;
    
      MyHomePage({required this.greeterService});
    
      @override
      _MyHomePageState createState() => _MyHomePageState();
    }
    
    class _MyHomePageState extends State<MyHomePage> {
      final TextEditingController _nameController = TextEditingController();
      String _message = '';
    
      @override
      Widget build(BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Flutter gRPC Example'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Enter your name'),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = _nameController.text;
                    final response = await widget.greeterService.callSayHello(name);
                    setState(() {
                      _message = response;
                    });
                  },
                  child: Text('Call gRPC Service'),
                ),
                SizedBox(height: 20.0),
                Text(
                  'Response: $_message',
                  style: TextStyle(fontSize: 18.0),
                ),
              ],
            ),
          ),
        );
      }
    
      @override
      void dispose() {
        _nameController.dispose();
        super.dispose();
      }
    }
    ```
    
    编译后你便能看到运行的结果,我们的windows桌面应用已经可以获取grpc响应,假如说我们想在移动端使用呢?这需要一台有公网ip的服务器,并在实例化GreeterService时传入服务器的主机名:
    
    ![](https://img-blog.csdnimg.cn/img_convert/63782976dcd34bd2355fde7df6eaf433.png)

## 在安卓中使用

1. 先编译go service为linux可执行文件,我使用的linux架构为amd64,

2. 注意修改main.go中的监听地址,还有注意在服务器运营商的安全组开放50051端口,还有注意关闭服务器的防火墙

3. ![](https://img-blog.csdnimg.cn/img_convert/dbb87fcd4b7ba42696cd6ab5e5fa2d6a.png)

4. 结果如

5. ![](https://img-blog.csdnimg.cn/img_convert/a873e88ba4af226f143412084eccdf05.png)

6. 上传服务器并运行,用nohup使其后台运行

7. ![](https://img-blog.csdnimg.cn/img_convert/91f96b64f22a3eddeea1fe9fb81fc4b4.png)

8. 更改flutter的实例化

9. ![Image3](https://img-blog.csdnimg.cn/img_convert/8c8152ce36db3c3833f72358e7632978.png)

成功

![](https://img-blog.csdnimg.cn/img_convert/0053e9bf67c0400943c4e10825323a36.png)

# 额外讲点:生成的pb文件的作用

1. **helloworld.pb.go**：
   
   - 这个文件包含了与消息定义相关的代码。每个在 `helloworld.proto` 中定义的消息类型（如 `HelloRequest` 和 `HelloResponse`）都会对应生成 Go 结构体，并且这些结构体实现了 Protocol Buffers 的序列化和反序列化方法，以便在网络上传输或进行持久化时使用。
   - 此文件还包含了一些辅助方法，用于创建、解析和操作消息对象。这些方法让你能够更轻松地使用消息类型。

2. **helloworld_grpc.pb.go**：
   
   - 这个文件包含了与 gRPC 服务定义相关的代码。在 `helloworld.proto` 中定义的 gRPC 服务（如 `Greeter`）会被转化为 Go 接口，并且为每个 gRPC 方法生成相应的客户端和服务器端函数。
   - 客户端函数用于向远程 gRPC 服务发起请求，而服务器端函数用于处理客户端请求并返回响应。

# 额外讲点:dart create命令详解

Dart 官方提供了多种不同类型的模板，以满足不同类型的项目需求。一些常见的 Dart 模板包括：

- `console`：用于创建命令行应用程序的模板
- `web`：用于创建 Web 应用程序的模板。
- `package`：用于创建 Dart 软件包库的模板，供其他 Dart 项目使用。
- `server`：用于创建 Dart 服务器应用程序的模板，用于构建服务器端应用程序。

​

# 额外讲点:dart proto生成pb文件命令详解

protoc --dart_out=grpc:lib/src/generated -Iprotos protos/helloworld.proto

- `protoc` 是 Protocol Buffers 编译器。
- `--dart_out=grpc:lib/src` 指定生成的 Dart 代码应放置在 `lib/src/generated` 目录中，并包括 gRPC 支持。
- `-Iprotos` 指定搜索 Proto 文件的路径（`protos` 目录）。
- `protos/helloworld.proto` 是您要生成 Dart 代码的 Proto 文件的路径。
  创建 Dart 软件包库的模板，供其他 Dart 项目使用。
- `server`：用于创建 Dart 服务器应用程序的模板，用于构建服务器端应用程序。

​

# 额外讲点:dart proto生成pb文件命令详解

protoc --dart_out=grpc:lib/src/generated -Iprotos protos/helloworld.proto

- `protoc` 是 Protocol Buffers 编译器。
- `--dart_out=grpc:lib/src` 指定生成的 Dart 代码应放置在 `lib/src/generated` 目录中，并包括 gRPC 支持。
- `-Iprotos` 指定搜索 Proto 文件的路径（`protos` 目录）。
- `protos/helloworld.proto` 是您要生成 Dart 代码的 Proto 文件的路径。
