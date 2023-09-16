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
