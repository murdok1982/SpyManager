import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/wear_theme.dart';
import 'screens/watchface_screen.dart';
import 'services/wear_data_service.dart';
import 'core/channel/phone_channel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  final dataService = WearDataService();
  final phoneChannel = PhoneChannel();
  phoneChannel.initialize(dataService);

  runApp(
    IMCWearApp(dataService: dataService, phoneChannel: phoneChannel),
  );
}

class IMCWearApp extends StatelessWidget {
  const IMCWearApp({
    super.key,
    required this.dataService,
    required this.phoneChannel,
  });

  final WearDataService dataService;
  final PhoneChannel phoneChannel;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IMC Wear',
      debugShowCheckedModeBanner: false,
      theme: WearTheme.dark(),
      home: WatchfaceScreen(
        dataService: dataService,
        phoneChannel: phoneChannel,
      ),
    );
  }
}
