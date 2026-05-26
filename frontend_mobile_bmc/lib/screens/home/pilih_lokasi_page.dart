import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class PilihLokasiPage extends StatefulWidget {
  const PilihLokasiPage({super.key});

  @override
  State<PilihLokasiPage> createState() => _PilihLokasiPageState();
}

class _PilihLokasiPageState extends State<PilihLokasiPage> {

  LatLng selectedLocation =
      const LatLng(3.5952, 98.6722);

  Future<void> _pilihLokasi(LatLng position) async {

    List<Placemark> placemarks =
        await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    Placemark place = placemarks.first;

    String alamat =
        '${place.street}, '
        '${place.subLocality}, '
        '${place.locality}, '
        '${place.administrativeArea}';

    Navigator.pop(context, {
      'alamat': alamat,
      'latitude': position.latitude,
      'longitude': position.longitude,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pilih Lokasi Rumah"),
      ),

      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: selectedLocation,
          zoom: 14,
        ),

        markers: {
          Marker(
            markerId: const MarkerId("rumah"),
            position: selectedLocation,
          ),
        },

        onTap: (LatLng position) async {

          setState(() {
            selectedLocation = position;
          });

          await _pilihLokasi(position);
        },
      ),
    );
  }
}