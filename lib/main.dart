import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driverrequirements/screens/FormScreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'constants/constants.dart';



@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await setupPushNotification();
  print("Handling background message: ${message.messageId}");
}

//Android Notification Plugins and channel variables
late AndroidNotificationChannel channel;
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
bool isFlutterLocalNotificationsInitialized=false;
const AndroidInitializationSettings initializationSettingsAndroid =
AndroidInitializationSettings('@mipmap/caricon');

//Keys
GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  //To ensure native firebase is initialized before running the flutter app
  WidgetsFlutterBinding.ensureInitialized();
  //Firebase initialization
  await Firebase.initializeApp();
  //To Receive Notification when app is running in background
  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  //Setting up push notification
  await setupPushNotification();
  //On push notification is received show local flutter notification
  FirebaseMessaging.onMessage.listen(showFlutterNotification);


  runApp(const MyApp());



}

//Asking notification permission setting up channel for notification using FLN plugin
Future<void> setupPushNotification() async{
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
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.initialize(initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  isFlutterLocalNotificationsInitialized = true;
}

//Show notification using FLN (Flutter Local Notification Plugin)
void showFlutterNotification(RemoteMessage message) {
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;
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
          icon:"@mipmap/caricon",
          enableVibration: true,
          playSound: true,

        ),
      ),
    );
  }
}
//Navigator.of(navigatorKey.currentState!.context).pushReplacement(MaterialPageRoute(builder: (BuildContext context)=>MyApp()));



class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey:navigatorKey ,
      title: 'InternApp',
      theme: ThemeData(


        primarySwatch: Colors.red,
      ),
      home: const MyHomePage(title: AppConstants.appTitle),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);



  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Padding(padding: const EdgeInsets.only(right:20.0),
          child: IconButton(icon:const Icon(Icons.add),onPressed: (){
              Navigator.of(context).push(MaterialPageRoute(builder: (context)=>const FormScreen()));
          },),)
        ],
      ),
      body:
        SafeArea(
          child:StreamBuilder<QuerySnapshot>(
            stream: db.collection(AppConstants.driverRequestCollec).snapshots(),
                builder: (context, snapshot) {
                if (!snapshot.hasData) {
                    return const Center(
                    child: CircularProgressIndicator(),
                    );
                } else {
                  return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final icon;
                    switch(snapshot.data!.docs[index]["vehicle"]){
                      case "Bike":
                        icon = const Icon(Icons.electric_bike_outlined);
                        break;
                      case "Truck":
                        icon = const Icon(Icons.fire_truck);
                        break;
                      case "Car":
                        icon = const Icon(Icons.drive_eta);
                        break;
                      default:
                        icon=const Icon(Icons.car_rental);
                        break;
                    }
                  return Card(
                    elevation: 15,
                    child: ListTile(
                      leading: icon,
                      title: Row(
                        children: [
                          Text(snapshot.data!.docs[index]["from"].toString().toUpperCase(),style:const TextStyle(color:Colors.black,fontWeight:FontWeight.bold),),
                          const Icon(Icons.arrow_forward_outlined),
                          Text(snapshot.data!.docs[index]["to"].toString().toUpperCase(),style:const TextStyle(color:Colors.black,fontWeight:FontWeight.bold),),
                        ],
                      ),trailing: Text(snapshot.data!.docs[index]["vehicle"]),
                    ),
                  );
                  });

                }
        },
        ),
        )

    );

  }

}
