import 'package:get/get.dart';
import '../models/userModel.dart';
import '../models/asignaturaModel.dart';
import 'package:dio/dio.dart' as dio; // Usar siempre el prefijo dio

class UserModelController extends GetxController {
  final user = UserModel(
    id: '0',
    name: 'Usuario desconocido',
    username: 'Sin username',
    mail: 'No especificado',
    password: 'Sin contraseña',
    fechaNacimiento: 'Sin especificar',
    isProfesor: false,
    isAlumno: false,
    isAdmin: false,
  ).obs;

  // Método para actualizar los datos del usuario
 void setUser({
  required String id,
  required String name,
  required String username,
  required String mail,
  required String password,
  required String fechaNacimiento,
  required bool isProfesor,
  required bool isAlumno,
  required bool isAdmin,
  required bool conectado,
  String? foto,
  String? descripcion,
  List<Map<String, String>>? disponibilidad,
  List<dynamic>? asignaturasImparte,
  Map<String, dynamic>? location,
}) {
  user.update((val) {
    if (val != null) {
      val.id = id;
      val.name = name;
      val.username = username;
      val.mail = mail;
      val.password = password;
      val.fechaNacimiento = fechaNacimiento;
      val.isProfesor = isProfesor;
      val.isAlumno = isAlumno;
      val.isAdmin = isAdmin;
      val.conectado = conectado;
      if (foto != null) val.foto = foto;
      if (descripcion != null) val.descripcion = descripcion;
      if (disponibilidad != null) val.disponibilidad = disponibilidad;

      if (asignaturasImparte != null) {
        val.asignaturasImparte = asignaturasImparte.map((item) {
          if (item is AsignaturaModel) {
            return item;
          } else if (item is Map<String, dynamic>) {
            return AsignaturaModel.fromJson(item);
          } else {
            throw Exception('Tipo inesperado en asignaturasImparte: $item');
          }
        }).toList();
      }

      if (location != null) val.location = location;
    }
  });
  printUserData(); // Para depuración
}

  // Método para depuración
  void printUserData() {
    print('User Data -> ${user.value.toJson()}');
  }
}
