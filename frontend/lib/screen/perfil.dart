import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/userListController.dart';
import '../controllers/userModelController.dart';
import '../controllers/connectedUsersController.dart';
import '../controllers/asignaturaController.dart';
import '../models/userModel.dart'; // De tu rama versiofinal
import '../l10n.dart'; // De tu rama versiofinal
import '../controllers/localeController.dart'; // De tu rama versiofinal
import 'package:shared_preferences/shared_preferences.dart'; // De tu rama versiofinal
import '../controllers/userController.dart'; // De la rama main
import '../models/asignaturaModel.dart'; // De la rama main


class PerfilPage extends StatefulWidget {
  @override
  _PerfilPageState createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final UserListController userListController = Get.find<UserListController>();
  final UserModelController userModelController = Get.find<UserModelController>();
  final ConnectedUsersController connectedUsersController = Get.find<ConnectedUsersController>();
  final AsignaturaController asignaturaController = Get.find<AsignaturaController>();
  
  final LocaleController localeController = Get.find<LocaleController>(); // De versiofinal
  final UserController userController = Get.find<UserController>(); // De main
}


String? selectedAsignaturaId;
String? selectedDia;
String? selectedTurno;
RxMap<String, dynamic> selectedUser = <String, dynamic>{}.obs; // Mantén esta de main

  @override
  void initState() {
    super.initState();
    _initializeData();
    
  }

  

  Future<void> _initializeData() async {
    await asignaturaController.fetchAllAsignaturas();
    userListController.userList.clear();
  }

  void _filterUsers() {
    final role = userModelController.user.value.isProfesor
        ? AppLocalizations.of(context)?.translate('role_student') ?? 'alumno'
        : AppLocalizations.of(context)?.translate('role_teacher') ?? 'profesor';

    final List<Map<String, String>> disponibilidad =
        (selectedDia != null && selectedTurno != null)
            ? [
                {'dia': selectedDia!, 'turno': selectedTurno!}
              ]
            : [];

    userListController.filterUsers(role, selectedAsignaturaId, disponibilidad);
  }

  void _startChat(String? userId) {
    if (userId != null && userId.isNotEmpty) {
      final loggedUserId = userModelController.user.value.id;
      final chatRoomId = [loggedUserId, userId].join('-');
      Get.toNamed(
        '/chat',
        arguments: {
          'chatRoomId': chatRoomId,
          'receiverId': userId,
          'receiverName': selectedUser['name'] ?? 'Usuario',
        },
      );
    } else {
      Get.snackbar('Error', 'No se puede iniciar el chat. Usuario inválido.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(

        title: selectedUser.isEmpty ? const Text('Buscar Usuarios') : const Text('Perfil'),
        leading: selectedUser.isEmpty
            ? null
            : IconButton(

                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    selectedUser.clear();
                  });
                },
              ),
        actions: selectedUser.isEmpty
            ? [
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _filterUsers,
                ),
                IconButton(
                  icon: Icon(Icons.language,
                      color: theme.textTheme.bodyLarge?.color),
                  onPressed: () {
                    if (localeController.currentLocale.value.languageCode ==
                        'es') {
                      localeController.changeLanguage('en');
                    } else {
                      localeController.changeLanguage('es');
                    }
                  },
                )
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.chat),
                  onPressed: () => _startChat(selectedUser['id']),
                ),
              ],
      ),

      body: Obx(() {
        return selectedUser.isEmpty ? _buildUserList(theme) : _buildUserProfile(theme);
      }),

    );
  }

  Widget _buildUserList(ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Obx(() {
                if (asignaturaController.isLoading.value) {
                  return const CircularProgressIndicator();
                }
                return DropdownButtonFormField<String>(
                  value: selectedAsignaturaId,
                  items: asignaturaController.asignaturas
                      .map((asignatura) => DropdownMenuItem(
                            value: asignatura.id,
                            child: Text(
                                '${asignatura.nombre} - ${AppLocalizations.of(context)?.translate('level') ?? 'Nivel'}: ${asignatura.nivel}'),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() {
                    selectedAsignaturaId = value;
                  }),
                  decoration: InputDecoration(
                      labelText:
                          AppLocalizations.of(context)?.translate('subject') ??
                              'Asignatura'),
                );
              }),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedDia,
                      items: [
                        AppLocalizations.of(context)?.translate('monday') ??
                            'Lunes',
                        AppLocalizations.of(context)?.translate('tuesday') ??
                            'Martes',
                        AppLocalizations.of(context)?.translate('wednesday') ??
                            'Miércoles',
                        AppLocalizations.of(context)?.translate('thursday') ??
                            'Jueves',
                        AppLocalizations.of(context)?.translate('friday') ??
                            'Viernes',
                      ]
                          .map((dia) => DropdownMenuItem(
                                value: dia,
                                child: Text(dia),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() {
                        selectedDia = value;
                      }),
                      decoration: const InputDecoration(labelText: 'Día'),
                    ),
                  ),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedTurno,
                      items: [
                        AppLocalizations.of(context)?.translate('morning') ??
                            'Mañana',
                        AppLocalizations.of(context)?.translate('afternoon') ??
                            'Tarde',
                      ]
                          .map((turno) => DropdownMenuItem(
                                value: turno,
                                child: Text(turno),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() {
                        selectedTurno = value;
                      }),
                      decoration: InputDecoration(
                        labelText:
                            AppLocalizations.of(context)?.translate('shift') ??
                                'Turno',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            if (userListController.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            if (userListController.userList.isEmpty) {
              return Center(
                child: Text(
                  AppLocalizations.of(context)?.translate('no_users_found') ??
                      'No se encontraron usuarios.',
                ),
              );
            }

            return ListView.builder(
              itemCount: userListController.userList.length,
              itemBuilder: (context, index) {
                final user = userListController.userList[index];
                final isConnected =
                    connectedUsersController.connectedUsers.contains(user.id);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isConnected ? Colors.green : Colors.grey,
                    child: const Icon(Icons.person),
                  ),
                  title: Text(user.name),
                  subtitle: Text(user.mail),
                  onTap: () async {
                    await userController.fetchUserById(user.id);

                    setState(() {
                      selectedUser.assignAll(userModelController.user.value.toJson());
                      selectedUser['id'] = userModelController.user.value.id ?? '';
                      selectedUser['name'] = userModelController.user.value.name ?? 'Sin nombre';
                      selectedUser['mail'] = userModelController.user.value.mail ?? 'Sin email';
                      selectedUser['descripcion'] =
                          userModelController.user.value.descripcion ?? 'Sin descripción';
                    });

                    if (userModelController.user.value.isProfesor) {
                      await userModelController.fetchReviews(user.id);
                      setState(() {
                        selectedUser['reviews'] = userModelController.user.value.reviews ?? [];
                        selectedUser['mediaValoraciones'] =
                            userModelController.user.value.mediaValoraciones ?? 0.0;

                        selectedUser['alumnosUnicos'] = selectedUser['reviews']
                                ?.where((review) => review?.nombreAlumno != null)
                                .map((review) => review.nombreAlumno)
                                .toSet()
                                .length ??
                            0;

                        selectedUser['asignaturasImparte'] =
                            userModelController.user.value.asignaturasImparte ?? [];
                      });
                    }
                  },
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildUserProfile(ThemeData theme) {

    final user = selectedUser;
    final isProfesor = userModelController.user.value.isProfesor;


    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(theme, user),
          if (isProfesor) _buildStatisticsSection(theme, user),
          _buildSectionContainer(
  theme,
  'Asignaturas',
  user['asignaturasImparte'] != null && user['asignaturasImparte'].isNotEmpty
      ? Column(
          children: user['asignaturasImparte']
              .map<Widget>((asignatura) {
                if (asignatura is Map<String, dynamic>) {
                  return ListTile(
                    title: Text(asignatura['nombre'] ?? 'Sin nombre'),
                    subtitle: Text('Nivel: ${asignatura['nivel'] ?? 'Sin nivel'}'),
                  );
                } else if (asignatura is AsignaturaModel) {
                  return ListTile(
                    title: Text(asignatura.nombre ?? 'Sin nombre'),
                    subtitle: Text('Nivel: ${asignatura.nivel ?? 'Sin nivel'}'),
                  );
                }
                return ListTile(
                  title: const Text('Asignatura no válida'),
                );
              })
              .toList(),
        )
      : Text(
          userModelController.user.value.isProfesor
              ? 'No tiene asignaturas asignadas.'
              : 'No se muestran asignaturas para este alumno.',
          style: theme.textTheme.bodyMedium,
        ),
),
          _buildSectionContainer(
            theme,
            'Disponibilidad',
            user['disponibilidad'] != null && user['disponibilidad'].isNotEmpty
                ? Column(
                    children: user['disponibilidad']
                        .map<Widget>((dispo) => ListTile(
                              title: Text('${dispo['dia']} - ${dispo['turno']}'),
                            ))
                        .toList(),
                  )
                : Text('No ha configurado su disponibilidad.', style: theme.textTheme.bodyMedium),
          ),
          if (isProfesor)
            _buildSectionContainer(
              theme,
              'Reviews Recibidas',
              user['reviews'] != null && user['reviews'].isNotEmpty
                  ? Column(
                      children: user['reviews']
                          .map<Widget>((review) => ListTile(
                                title: Text('Alumno: ${review.nombreAlumno ?? 'Desconocido'}'),
                                subtitle: Text('Comentario: ${review.comentario ?? ''}'),
                                trailing: Text('Puntuación: ${review.puntuacion ?? ''}'),
                              ))
                          .toList(),
                    )
                  : Text('No tiene reviews registradas.', style: theme.textTheme.bodyMedium),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, Map<String, dynamic> user) {
    return Stack(
      children: [
        Container(
          height: 220,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primaryColor.withOpacity(0.8),
                theme.primaryColorDark,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned.fill(
          child: Align(
            alignment: Alignment.center,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey,
                  backgroundImage: user['foto'] != null && user['foto'].isNotEmpty
                      ? NetworkImage(user['foto'])
                      : null,
                  child: user['foto'] == null || user['foto'].isEmpty
                      ? Icon(Icons.person, size: 50, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 10),
                Text(
                  user['name'] ?? 'Sin nombre',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user['mail'] ?? 'Sin email',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                if (user['descripcion'] != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      user['descripcion'],
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsSection(ThemeData theme, Map<String, dynamic> user) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatisticCard(
            theme,
            Icons.star,
            'Media Valoraciones',
            user['mediaValoraciones']?.toStringAsFixed(1) ?? '0.0',
          ),
          _buildStatisticCard(
            theme,
            Icons.group,
            'Alumnos Ayudados',
            '${user['alumnosUnicos'] ?? 0}',
          ),
          _buildStatisticCard(
            theme,
            Icons.book,
            'Asignaturas',
            '${user['asignaturasImparte']?.length ?? 0}',
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticCard(ThemeData theme, IconData icon, String label, String value) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 120,
        child: Column(
          children: [
            Icon(icon, size: 32, color: theme.primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSectionContainer(ThemeData theme, String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              content,
            ],
          ),
        ),
      ),

    );
  }
}