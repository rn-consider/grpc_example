import 'package:flutter/material.dart';
import 'package:helloworld/helloworld.dart'; // 根据实际路径进行调整

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final greeterService = GreeterService('8.130.86.137',50051);

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
