import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_earthquake/models/earthquake_model.dart';
import 'package:flutter_earthquake/utils/helper_functions.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart' as gc;

class AppDataProvider with ChangeNotifier {
  final baseUrl = Uri.parse('https://earthquake.usgs.gov/fdsnws/event/1/query');
  Map<String, dynamic> queryParams = {};
  double _maxRadiusKm = 500;
  double _latitude = 0.0;
  double _longitude = 0.0;
  String _startTime = '';
  String _endTime = '';
  String _orderBy = 'time';
  String? _currentCity;
  final double _maxRadiusKmThreshold = 20001.6;
  bool _shouldUseLocation = false;
  EarthquakeModel? earthquakeModel;

  double get maxRadiusKm => _maxRadiusKm;
  double get latitude => _latitude;
  double get longitude => _longitude;
  String get startTime => _startTime;
  String get endTime => _endTime;
  String get orderBy => _orderBy;
  String? get currentCity => _currentCity;
  double get maxRadiusThreshold => _maxRadiusKmThreshold;
  bool get shouldUseLocation => _shouldUseLocation;
  bool get hasDataLoaded => earthquakeModel != null;

  void setOrder(String value) {
    _orderBy = value;
    notifyListeners();
    _setQueryParams();
    getEarthquakeData();
  }

  void _setQueryParams() {
    queryParams['format'] = 'geojson';
    queryParams['starttime'] = _startTime;
    queryParams['endtime'] = _endTime;
    queryParams['minmagnitude'] = '4';
    queryParams['orderby'] = _orderBy;
    queryParams['limit'] = '500';
    queryParams['latitude'] = '$_latitude';
    queryParams['longitude'] = '$_longitude';
    queryParams['maxradiuskm'] = '$_maxRadiusKm';
  }

  void init() {
    _startTime = getFormatterDateTime(
      DateTime.now()
          .subtract(
            const Duration(
              days: 1,
            ),
          )
          .millisecondsSinceEpoch,
    );
    _endTime = getFormatterDateTime(DateTime.now().millisecondsSinceEpoch);
    _maxRadiusKm = maxRadiusThreshold;
    _setQueryParams();
    getEarthquakeData();
  }

  Color getAlertColor(String color) {
    return switch (color) {
      'green' => Colors.green,
      'yellow' => Colors.yellow,
      'orange' => Colors.orange,
      _ => Colors.red,
    };
  }

  Future<void> getEarthquakeData() async {
    final uri = Uri.https(baseUrl.authority, baseUrl.path, queryParams);
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        earthquakeModel = EarthquakeModel.fromJson(json);
        print(earthquakeModel!.features!.length);
        notifyListeners();
      }
    } catch (error) {
      print(error);
    }
  }

  void setStartTime(String date) {
    _startTime = date;
    _setQueryParams();
    notifyListeners();
  }

  void setEndTime(String date) {
    _endTime = date;
    _setQueryParams();
    notifyListeners();
  }

  Future<void> setLocation(bool value) async {
    _shouldUseLocation = value;
    notifyListeners();
    if (value) {
      final position = await _determinePosition();
      _latitude = position.latitude;
      _longitude = position.longitude;
      _maxRadiusKm = 500;
      _setQueryParams();
      getEarthquakeData();
      await _getCurrentCity();
    } else {
      _latitude = 0;
      _longitude = 0;
      _maxRadiusKm = _maxRadiusKmThreshold;
      _currentCity = null;
      _setQueryParams();
      getEarthquakeData();
    }
  }

  Future<void> _getCurrentCity() async {
    try {
      final placemarkList =
          await gc.placemarkFromCoordinates(_latitude, _longitude);
      if (placemarkList.isNotEmpty) {
        final placemark = placemarkList.first;
        _currentCity = placemark.locality;
      }
      notifyListeners();
    } catch (error) {
      print(error);
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }
}
