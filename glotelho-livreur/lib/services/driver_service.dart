import 'package:dio/dio.dart';
import 'dart:io';
import 'api_service.dart';
import '../models/driver_model.dart';
import '../models/vehicle_model.dart';
// import '../utils/constants.dart'; // Décommente si nécessaire

class RegisterResult {
  final bool success;
  final String? token;
  final String? errorMessage;

  RegisterResult.success({this.token}) : success = true, errorMessage = null;
  RegisterResult.failure(this.errorMessage) : success = false, token = null;
}

class DriverService {
  /// Récupère le profil complet du livreur connecté
  static Future<DriverModel?> fetchProfile() async {
    try {
      final response = await ApiService.dio.get('/drivers/me');
      if (response.statusCode == 200) {
        return DriverModel.fromJson(response.data['data'] ?? response.data);
      }
      return null;
    } on DioException catch (e) {
      print("Erreur fetchProfile: ${e.response?.data}");
      return null;
    }
  }

  /// Soumet le dossier d'inscription avec les fichiers et les informations
  static Future<RegisterResult> register({
    required String nom,
    required String prenom,
    required DateTime dateNaissance,
    required String telephone,
    required String email,
    required String password,
    required String adresseResidence,
    required String cniNumero,
    required VehicleModel vehicle,
    required List<Availability> disponibilites,
    required String mobileMoneyNumero,
    required String mobileMoneyTitulaire,
    required File photoProfil,
    required File cniRecto,
    required File cniVerso,
    required File permis,
    required File photoVehicule,
  }) async {
    try {
      final formData = FormData.fromMap({
        'nom': nom,
        'prenom': prenom,
        'dateNaissance': dateNaissance.toIso8601String(),
        'telephone': telephone,
        'email': email,
        'password': password,
        'adresseResidence': adresseResidence,
        'cniNumero': cniNumero,
        'vehiculeType': vehicle.type,
        'vehiculeMarque': vehicle.marque,
        'vehiculeModele': vehicle.modele,
        'vehiculeImmatriculation': vehicle.immatriculation,
        'assuranceNumero': vehicle.assuranceNumero,
        'assuranceExpiration': vehicle.assuranceExpiration.toIso8601String(),
        'mobileMoneyNumero': mobileMoneyNumero,
        'mobileMoneyTitulaire': mobileMoneyTitulaire,
        
        // Envoi des disponibilités sous format JSON String pour le backend
        'disponibilites': disponibilites.map((d) => d.toJson()).toList(), 

        // Les fichiers images / documents
        'photoProfil': await MultipartFile.fromFile(photoProfil.path),
        'cniRecto': await MultipartFile.fromFile(cniRecto.path),
        'cniVerso': await MultipartFile.fromFile(cniVerso.path),
        'permis': await MultipartFile.fromFile(permis.path),
        'photoVehicule': await MultipartFile.fromFile(photoVehicule.path),
      });

      // On utilise le Dio centralisé (ApiService.dio)
      final response = await ApiService.dio.post('/drivers/register', data: formData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        return RegisterResult.success(token: data['token'] ?? data['data']?['token']);
      }
      return RegisterResult.failure('Erreur serveur (${response.statusCode})');
      
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response?.data['message'] ?? 'Erreur lors de l\'inscription')
          : 'Erreur réseau, vérifiez votre connexion.';
      return RegisterResult.failure(msg.toString());
    } catch (e) {
      return RegisterResult.failure('Erreur inattendue : $e');
    }
  }
}