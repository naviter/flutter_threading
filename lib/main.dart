import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'ffi.dart'; // Your FFI file that exposes getThreadId()

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();
  runApp(const MyApp());
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

class MyTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final threadId = FfiUtilsInterface().utils.getThreadId();
    FlutterForegroundTask.updateService(
      notificationTitle: 'Foreground Service',
      notificationText: 'Thread ID: $threadId',
    );
    FlutterForegroundTask.sendDataToMain({'service': threadId});
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onReceiveData(Object data) {}
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: ThreadIdDemo());
  }
}

class ThreadIdDemo extends StatefulWidget {
  const ThreadIdDemo({super.key});

  @override
  State<ThreadIdDemo> createState() => _ThreadIdDemoState();
}

class _ThreadIdDemoState extends State<ThreadIdDemo> {
  String uiThreadId = '';
  String serviceThreadId = '';
  List<String> isolateThreadIds = [];

  @override
  void initState() {
    super.initState();
    FlutterForegroundTask.addTaskDataCallback(_handleServiceData);
    _initService();
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_handleServiceData);
    super.dispose();
  }

  void _handleServiceData(Object data) {
    if (data is Map && data['service'] != null) {
      setState(() {
        serviceThreadId = data['service'].toString();
      });
    }
  }

  Future<void> _initService() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'foreground_service',
        channelName: 'Foreground Service Notification',
        channelDescription:
            'This notification appears when the foreground service is running.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        // autoRunOnBoot: true,
        // autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<void> _runAll() async {
    final ffi = FfiUtilsInterface();

    setState(() {
      uiThreadId = ffi.utils.getThreadId().toString();
      serviceThreadId = '';
      isolateThreadIds = [];
    });

    // Start foreground service
    await FlutterForegroundTask.startService(
      notificationTitle: 'Running...',
      notificationText: 'Gathering thread IDs',
      callback: startCallback,
    );

    // Spawn 5 isolates
    final results = <String>[];
    await Future.wait(List.generate(5, (_) async {
      final receivePort = ReceivePort();
      await Isolate.spawn(_isolateEntry, receivePort.sendPort);
      return await receivePort.first as String;
    }).map((f) async {
      results.add(await f);
    }));

    setState(() {
      isolateThreadIds = results;
    });
  }

  static void _isolateEntry(SendPort sendPort) {
    final id = FfiUtilsInterface().utils.getThreadId();
    sendPort.send(id.toString());
  }

  @override
  Widget build(BuildContext context) {
    return WithForegroundTask(
      child: Scaffold(
        appBar: AppBar(title: const Text('Thread ID Demo')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton(
                onPressed: _runAll,
                child: const Text('Get Thread IDs'),
              ),
              const SizedBox(height: 16),
              Text('UI Thread ID: $uiThreadId'),
              Text('Service Thread ID: $serviceThreadId'),
              const SizedBox(height: 8),
              const Text('Isolate Thread IDs:'),
              for (final id in isolateThreadIds)
                Text('- $id', style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
