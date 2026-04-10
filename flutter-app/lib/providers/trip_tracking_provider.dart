import 'package:flutter/foundation.dart';
import '../models/trip_tracking.dart';
import '../services/database_service.dart';
import '../models/vehicle.dart';

class TripTrackingProvider extends ChangeNotifier {
  List<TripTracking> _trips = [];
  List<TripTracking> _vehicleTrips = [];
  bool _isLoading = false;

  List<TripTracking> get trips => _trips;
  List<TripTracking> get vehicleTrips => _vehicleTrips;
  bool get isLoading => _isLoading;

  Future<void> loadTrips() async {
    _isLoading = true;
    notifyListeners();
    try {
      final trips = await DatabaseService.getAllTrips();
      final vehicles = await DatabaseService.getAllVehicles();
      _trips = trips.map((t) {
        Vehicle? veh;
        for (final v in vehicles) {
          if (v.id == t.vehicleId) { veh = v; break; }
        }
        return t.copyWith(vehicle: veh);
      }).toList();
    } catch (e) {
      debugPrint('Error loading trips: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadTripsByVehicleId(int vehicleId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final trips = await DatabaseService.getTripsByVehicleId(vehicleId);
      final vehicle = await DatabaseService.getVehicleById(vehicleId);
      _vehicleTrips = trips.map((t) => t.copyWith(vehicle: vehicle)).toList();
    } catch (e) {
      debugPrint('Error loading trips for vehicle $vehicleId: $e');
      _vehicleTrips = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<int> saveTrip(TripTracking trip) async {
    try {
      final id = await DatabaseService.insertTrip(trip);
      if (id > 0) {
        // Update local list directly instead of re-fetching
        final newTrip = trip.copyWith(id: id);
        _trips.insert(0, newTrip);
        // Also update _vehicleTrips if matching
        final vehicleId = trip.vehicleId;
        if (_vehicleTrips.isNotEmpty && _vehicleTrips.first.vehicleId == vehicleId) {
          _vehicleTrips.insert(0, newTrip);
        }
        notifyListeners();
      }
      return id;
    } catch (e) {
      debugPrint('Error saving trip: $e');
      return -1;
    }
  }

  Future<bool> cancelTrip(TripTracking trip) async {
    try {
      final cancelledTrip = trip.copyWith(
        status: 'cancelled',
        updatedAt: DateTime.now(),
      );
      final id = await DatabaseService.insertTrip(cancelledTrip);
      if (id > 0) {
        // Update local list directly
        final newTrip = cancelledTrip.copyWith(id: id);
        _trips.insert(0, newTrip);
        // Also update _vehicleTrips if matching
        final vehicleId = trip.vehicleId;
        if (_vehicleTrips.isNotEmpty && _vehicleTrips.first.vehicleId == vehicleId) {
          _vehicleTrips.insert(0, newTrip);
        }
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error cancelling trip: $e');
      return false;
    }
  }
}
