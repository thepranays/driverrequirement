
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../constants/constants.dart';
import 'package:http/http.dart' as http;

//TODO:make abstract class such that root level required services can also work and code cleans up

 class  PushNotificationService {
  //Android Notification Plugins and channel variables
  static late AndroidNotificationChannel channel;
  static late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  static bool isFlutterLocalNotificationsInitialized = false;
  static const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/caricon');

  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    await Firebase.initializeApp();
    await setupPushNotification();
    showFlutterNotification(message);
    print("Handling background message: ${message.messageId}");
  }

  //Asking notification permission setting up channel for notification using FLN plugin
  static Future<void> setupPushNotification() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');

    if (isFlutterLocalNotificationsInitialized) {
      return;
    }
    //subscribe to a topic to get notification
    messaging.subscribeToTopic("drivereq");
    //create high priority notification channel using flutter local notification plugin
    channel = const AndroidNotificationChannel(
      'high_importance_channel', // id
      'Priority0 Notification', // title
      description: 'Driver Requirement Alert', // description
      importance: Importance.max,
    );

    //initialize flutterlocalnotification plugin and create notification channel
    flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.initialize(initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    isFlutterLocalNotificationsInitialized = true;
  }

//Convert URL image to byte array
  static Future<Uint8List> _getByteArrayFromUrl(String url) async {
    final http.Response response = await http.get(Uri.parse(url));
    return response.bodyBytes;
  }

//Show notification using FLN (Flutter Local Notification Plugin)
  static void showFlutterNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    Map<String, dynamic>? data = message.data;
    AndroidNotification? android = message.notification?.android;

    //select appropriate image based on vehicle type
    final vehicleType = notification?.title
        ?.split(" ")
        .first;
    String vehicleUrl = "";
    switch (vehicleType) {
      case "Bike":
        vehicleUrl = AppConstants.bikeImage;
        break;
      case "Truck":
        vehicleUrl = AppConstants.truckImage;
        break;
      case "Car":
        vehicleUrl = AppConstants.carImage;
        break;
      default:
        vehicleUrl = AppConstants.carImage;
        break;
    }

    //to convert byte array to bitmap
    final ByteArrayAndroidBitmap bigPicture = ByteArrayAndroidBitmap(
        await _getByteArrayFromUrl(vehicleUrl));


    //if notification belongs to android then execute->
    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            enableVibration: true,
            styleInformation: BigTextStyleInformation(
              "Expected at " + data["timedate"],
              contentTitle: notification.body! + "-" + data["dist"],

            ),
            largeIcon: bigPicture,
            playSound: true,

          ),
        ),
      );
    }
  }
}
