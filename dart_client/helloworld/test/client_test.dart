import 'package:test/test.dart';
import 'package:helloworld/bin/client.dart'; // 根据实际路径进行调整

void main() {
  group('GreeterService', () {
    late GreeterService greeterService;

    setUp(() {
      greeterService = GreeterService('8.130.86.137',50051);
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
