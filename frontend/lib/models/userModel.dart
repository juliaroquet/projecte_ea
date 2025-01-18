import 'package:flutter/material.dart';
import '../models/asignaturaModel.dart';

class UserModel with ChangeNotifier {
  String id;
  String name;
  String username;
  String mail;
  String password;
  String fechaNacimiento;
  bool isProfesor;
  bool isAlumno;
  bool isAdmin;
  bool conectado;
  String? foto;
  String? descripcion;
  List<Map<String, String>>? disponibilidad;
  List<AsignaturaModel>? asignaturasImparte;
  Map<String, dynamic>? location;

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.mail,
    required this.password,
    required this.fechaNacimiento,
    this.isProfesor = false,
    this.isAlumno = false,
    this.isAdmin = true,
    this.conectado = false,
    this.foto,
    this.descripcion,
    this.disponibilidad,
    this.asignaturasImparte,
    this.location,
  });

  // Getters para latitud y longitud
  double get lat => location?['coordinates']?[1] ?? 0.0;
  double get lng => location?['coordinates']?[0] ?? 0.0;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? '',
      name: json['nombre'] ?? 'Sin nombre',
      username: json['username'] ?? 'Sin username',
      mail: json['email'] ?? 'Sin email',
      password: '',
      fechaNacimiento: json['fechaNacimiento'] ?? 'No especificada',
      isProfesor: json['isProfesor'] ?? false,
      isAlumno: json['isAlumno'] ?? false,
      isAdmin: json['isAdmin'] ?? false,
      conectado: json['conectado'] ?? false,
      foto: json['foto'] ?? '',
      descripcion: json['descripcion'] ?? '',
      disponibilidad: (json['disponibilidad'] as List?)
          ?.map((item) => {
                'dia': item['dia'].toString(),
                'turno': item['turno'].toString(),
              })
          .toList(),
      asignaturasImparte: (json['asignaturasImparte'] as List?)?.map((item) {
        if (item is Map<String, dynamic>) {
          return AsignaturaModel.fromJson(item);
        } else {
          return AsignaturaModel(id: item.toString(), nombre: 'Sin nombre', nivel: '');
        }
      }).toList(),
      location: json['location'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nombre': name,
      'username': username,
      'email': mail,
      'password': password,
      'fechaNacimiento': fechaNacimiento,
      'isProfesor': isProfesor,
      'isAlumno': isAlumno,
      'isAdmin': isAdmin,
      'conectado': conectado,
      'foto': foto,
      'descripcion': descripcion,
      'disponibilidad': disponibilidad,
      'asignaturasImparte': asignaturasImparte?.map((e) => e.toJson()).toList(),
      'location': location,
    };
  }

  @override
  String toString() {
    return '''
    UserModel {
      id: $id,
      name: $name,
      username: $username,
      mail: $mail,
      fechaNacimiento: $fechaNacimiento,
      isProfesor: $isProfesor,
      isAlumno: $isAlumno,
      isAdmin: $isAdmin,
      conectado: $conectado,
      foto: $foto,
      descripcion: $descripcion,
      disponibilidad: $disponibilidad,
      asignaturasImparte: ${asignaturasImparte?.map((item) => item.toString()).toList()},
      location: $location
    }
    ''';
  }
}