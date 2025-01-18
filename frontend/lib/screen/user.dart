import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/userModelController.dart';
import '../controllers/theme_controller.dart';
import '../controllers/userController.dart';
import '../controllers/authController.dart';

class UserPage extends StatelessWidget {
  final UserModelController userModelController = Get.find<UserModelController>();
  final ThemeController themeController = Get.find<ThemeController>();
  final UserController userController = Get.put(UserController());

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Llama a fetchUserById para actualizar los datos del usuario al abrir la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authController = Get.find<AuthController>();
      final userId = authController.getUserId;
      if (userId.isNotEmpty) {
        userController.fetchUserById(userId);
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Perfil de Usuario'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        actions: [
          IconButton(
            icon: Icon(
              themeController.themeMode.value == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
              color: theme.iconTheme.color,
            ),
            onPressed: themeController.toggleTheme,
          ),
        ],
      ),
      body: Obx(() {
        final user = userModelController.user.value;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto, nombre y correo
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: user.foto != null && user.foto!.isNotEmpty
                          ? NetworkImage(user.foto!)
                          : null,
                      child: user.foto == null || user.foto!.isEmpty
                          ? Icon(Icons.person, size: 50, color: theme.iconTheme.color)
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Text(user.name, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(user.mail, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (user.isProfesor) ...[
                // Estadísticas para profesores
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatisticItem(theme, Icons.star, 'Valoraciones', '-'),
                    _buildStatisticItem(theme, Icons.book, 'Asignaturas',
                        '${user.asignaturasImparte?.length ?? 0}'),
                    _buildStatisticItem(theme, Icons.person, 'Alumnos', '-'),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // Descripción
              _buildSectionTitle('Descripción', theme),
              Text(user.descripcion ?? 'Sin descripción',
                  style: theme.textTheme.bodyMedium),

              const SizedBox(height: 20),

              // Asignaturas
              _buildSectionTitle('Asignaturas', theme),
              if (user.asignaturasImparte != null && user.asignaturasImparte!.isNotEmpty)
                Column(
                  children: user.asignaturasImparte!
                      .map((asignatura) => ListTile(
                            title: Text(asignatura.nombre),
                            subtitle: Text(asignatura.nivel.isNotEmpty
                                ? asignatura.nivel
                                : 'Sin nivel especificado'),
                          ))
                      .toList(),
                )
              else
                Text('No tienes asignaturas asignadas',
                    style: theme.textTheme.bodyMedium),

              const SizedBox(height: 20),

              // Disponibilidad
              _buildSectionTitle('Disponibilidad', theme),
              if (user.disponibilidad != null && user.disponibilidad!.isNotEmpty)
                Column(
                  children: user.disponibilidad!
                      .map((d) => ListTile(
                            title: Text('${d['dia']} - ${d['turno']}'),
                          ))
                      .toList(),
                )
              else
                Text('No has configurado tu disponibilidad',
                    style: theme.textTheme.bodyMedium),

              if (!user.isProfesor) ...[
                const SizedBox(height: 30),
                // Historial de clases para alumnos
                _buildSectionTitle('Historial de Clases', theme),
                Text('Aquí se mostrará el historial de clases del alumno.',
                    style: theme.textTheme.bodyMedium),
              ],

              const SizedBox(height: 30),

              // Botones de configuración
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Get.toNamed('/settings_general')!.then((_) {
                          // Actualiza los datos del usuario al volver
                          final authController = Get.find<AuthController>();
                          final userId = authController.getUserId;
                          if (userId.isNotEmpty) {
                            userController.fetchUserById(userId);
                          }
                        });
                      },
                      icon: const Icon(Icons.settings),
                      label: const Text('Configuración'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        Get.toNamed('/settings_asignaturas')!.then((_) {
                          // Actualiza los datos del usuario al volver
                          final authController = Get.find<AuthController>();
                          final userId = authController.getUserId;
                          if (userId.isNotEmpty) {
                            userController.fetchUserById(userId);
                          }
                        });
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Actualizar Datos'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildStatisticItem(ThemeData theme, IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 32, color: theme.iconTheme.color),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.bodyMedium),
        Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
