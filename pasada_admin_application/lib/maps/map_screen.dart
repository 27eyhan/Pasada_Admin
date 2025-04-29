import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// We don't need webview or dotenv here anymore for Google Maps
// import 'package:webview_flutter/webview_flutter.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';

class Mapscreen extends StatefulWidget {
  const Mapscreen({super.key});

  @override
  State<Mapscreen> createState() => MapsScreenState();
}

class MapsScreenState extends State<Mapscreen> {
  // We don't need the WebViewController or the apiKey from dotenv here
  // late final WebViewController webViewController;
  // final String apiKey = dotenv.env['WEB_MAPS_API_KEY']!;

  // Add a GoogleMapController
  late GoogleMapController mapController;

  // Define the initial camera position (you can change this)
  final LatLng _center = const LatLng(14.5995, 120.9842); // Example: Manila

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  // @override
  // void initState() {
  //   super.initState();
  //   // Remove WebView initialization
  //   // webViewController = WebViewController()
  //   //   ..setJavaScriptMode(JavaScriptMode.unrestricted)
  //   //   ..loadFlutterAsset('assets/web/map.html');
  // }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: _center,
        zoom: 11.0,
      ),
      // You can add markers, polylines etc. here
      // markers: { ... },
      // polylines: { ... },
    );
    // Remove the Scaffold and WebViewWidget
    // return Scaffold(
    //   body: WebViewWidget(
    //     controller: webViewController,
    //   ),
    // );
  }
}
