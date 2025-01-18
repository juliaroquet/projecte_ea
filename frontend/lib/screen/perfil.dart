import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/userListController.dart';
import '../controllers/userModelController.dart';
import '../controllers/connectedUsersController.dart';
import '../controllers/asignaturaController.dart';
import '../models/userModel.dart';
import '../l10n.dart';
import '../controllers/localeController.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:html' as html; 
import '../helpers/image_picker_helper.dart';
import '../services/cloudinary_service.dart';
import '../screen/upload_image_screen.dart';

class PerfilPage extends StatefulWidget {
  @override
  _PerfilPageState createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final UserListController userListController = Get.find<UserListController>();
  final UserModelController userModelController = Get.find<UserModelController>();
  final ConnectedUsersController connectedUsersController = Get.find<ConnectedUsersController>();
  final AsignaturaController asignaturaController = Get.find<AsignaturaController>();
  final ImagePickerHelper _imagePicker = ImagePickerHelper();
  final CloudinaryService _cloudinaryService = CloudinaryService();


  String? selectedAsignaturaId;
  String? selectedDia;
  String? selectedTurno;
  UserModel? selectedUser;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadProfileImageUrl();
  }

  Future<void> _loadProfileImageUrl() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profileImageUrl = prefs.getString('profileImageUrl');
    });
  }
    Future<void> _saveProfileImageUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profileImageUrl', url);
  }
  Future<void> _selectAndUploadProfileImage() async {
    final imageBase64 = await _imagePicker.pickImage();
    if (imageBase64 != null) {
      String? imageUrl = await _cloudinaryService.uploadImage(imageBase64);
      if (imageUrl != null) {
        setState(() {
          _profileImageUrl = imageUrl;
        });
        _saveProfileImageUrl(imageUrl);
      } else {
        Get.snackbar('Error', 'No se pudo subir la imagen.');
      }
    }
  }

  Future<void> _initializeData() async {
    await asignaturaController.fetchAllAsignaturas();
    userListController.userList.clear();
    
  }

  void _filterUsers() {
  final role = userModelController.user.value.isProfesor
      ? AppLocalizations.of(context)?.translate('role_student') ?? 'alumno'
      : AppLocalizations.of(context)?.translate('role_teacher') ?? 'profesor';
  
  final List<Map<String, String>> disponibilidad = (selectedDia != null && selectedTurno != null)
      ? [{'dia': selectedDia!, 'turno': selectedTurno!}]
      : [];
  
  userListController.filterUsers(role, selectedAsignaturaId, disponibilidad);
}


 @override
Widget build(BuildContext context) {
  final ThemeData theme = Theme.of(context);

  return Scaffold(
    appBar: AppBar(
      title: selectedUser == null
          ? Text(AppLocalizations.of(context)?.translate('search_users') ?? 'Buscar Usuarios')
          : Text(AppLocalizations.of(context)?.translate('profile') ?? 'Perfil'),
      leading: selectedUser != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  selectedUser = null; // Volver a la lista de usuarios
                });
              },
            )
          : null,
      actions: selectedUser == null
          ? [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _filterUsers,
              ),
            ]
          : null,
    ),
    body: selectedUser == null ? _buildUserList(theme) : _buildUserProfile(theme),
    floatingActionButton: FloatingActionButton(
      onPressed: _selectAndUploadProfileImage,
      child: const Icon(Icons.upload),
      tooltip: 'Subir foto de perfil',
    ),
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
                            child: Text('${asignatura.nombre} - ${AppLocalizations.of(context)?.translate('level') ?? 'Nivel'}: ${asignatura.nivel}'),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() {
                    selectedAsignaturaId = value;
                  }),
                   decoration: InputDecoration(labelText: AppLocalizations.of(context)?.translate('subject') ?? 'Asignatura'),
                );
              }),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedDia,
                      items: [
                        AppLocalizations.of(context)?.translate('monday') ?? 'Lunes',
                        AppLocalizations.of(context)?.translate('tuesday') ?? 'Martes',
                        AppLocalizations.of(context)?.translate('wednesday') ?? 'Miércoles',
                        AppLocalizations.of(context)?.translate('thursday') ?? 'Jueves',
                      AppLocalizations.of(context)?.translate('friday') ?? 'Viernes',]
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
                      items: [ AppLocalizations.of(context)?.translate('morning') ?? 'Mañana', AppLocalizations.of(context)?.translate('afternoon') ?? 'Tarde',]
                          .map((turno) => DropdownMenuItem(
                                value: turno,
                                child: Text(turno),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() {
                        selectedTurno = value;
                      }),
                      decoration: InputDecoration(labelText: AppLocalizations.of(context)?.translate('shift') ?? 'Turno',),
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
              return Center(child: Text(AppLocalizations.of(context)?.translate('no_users_found') ?? 'No se encontraron usuarios.',), 
              );

            }

            return ListView.builder(
              itemCount: userListController.userList.length,
              itemBuilder: (context, index) {
                final user = userListController.userList[index];
                final isConnected = connectedUsersController.connectedUsers.contains(user.id);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isConnected ? Colors.green : Colors.grey,
                    child: const Icon(Icons.person),
                  ),
                  title: Text(user.name),
                  subtitle: Text(user.mail),
                  onTap: () {
                    setState(() {
                      selectedUser = user;
                    });
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
  final user = selectedUser!;
  final isConnected = connectedUsersController.connectedUsers.contains(user.id);

  return SingleChildScrollView(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: isConnected ? Colors.green : Colors.grey,
                backgroundImage: _profileImageUrl != null
                    ? NetworkImage(_profileImageUrl!)
                    : (user.foto != null && user.foto!.isNotEmpty
                        ? NetworkImage(user.foto!)
                        : null),
                child: (_profileImageUrl == null && (user.foto == null || user.foto!.isEmpty))
                    ? Icon(Icons.person, size: 50, color: theme.iconTheme.color)
                    : null,
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _selectAndUploadProfileImage,
                icon: const Icon(Icons.upload),
                label: const Text('Cambiar Foto de Perfil'),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatisticItem(theme, Icons.star,
                  AppLocalizations.of(context)?.translate('valoraciones') ?? 'Valoraciones', '-'),
              _buildStatisticItem(
                  theme,
                  Icons.book,
                  AppLocalizations.of(context)?.translate('asignaturas') ?? 'Asignaturas',
                  '${user.asignaturasImparte?.length ?? 0}'),
              _buildStatisticItem(theme, Icons.person,
                  AppLocalizations.of(context)?.translate('alumnos') ?? 'Alumnos', '-'),
            ],
          ),
          const SizedBox(height: 20),
        ],
        _buildSectionTitle(
            AppLocalizations.of(context)?.translate('descripcion') ?? 'Descripción', theme),
        Text(
            user.descripcion ??
                AppLocalizations.of(context)?.translate('sin_descripcion') ?? 'Sin descripción',
            style: theme.textTheme.bodyMedium),
        const SizedBox(height: 20),
        _buildSectionTitle(
            AppLocalizations.of(context)?.translate('asignaturas') ?? 'Asignaturas', theme),
        if (user.asignaturasImparte != null && user.asignaturasImparte!.isNotEmpty)
          Column(
            children: user.asignaturasImparte!
                .map((asignatura) => ListTile(
                      title: Text(asignatura.nombre),
                      subtitle: Text(asignatura.nivel),
                    ))
                .toList(),
          )
        else
          Text(
              AppLocalizations.of(context)?.translate('sin_asignaturas') ??
                  'No tiene asignaturas asignadas',
              style: theme.textTheme.bodyMedium),
        const SizedBox(height: 20),
        _buildSectionTitle(
            AppLocalizations.of(context)?.translate('disponibilidad') ?? 'Disponibilidad', theme),
        if (user.disponibilidad != null && user.disponibilidad!.isNotEmpty)
          Column(
            children: user.disponibilidad!
                .map((d) => ListTile(
                      title: Text('${d['dia']} - ${d['turno']}'),
                    ))
                .toList(),
          )
        else
          Text(
              AppLocalizations.of(context)?.translate('sin_disponibilidad') ??
                  'No ha configurado su disponibilidad',
              style: theme.textTheme.bodyMedium),
        if (!user.isProfesor) ...[
          const SizedBox(height: 30),
          Text('Aquí se mostrará el historial de clases del alumno.',
              style: theme.textTheme.bodyMedium),
        ],
        const SizedBox(height: 30),
        Center(
          child: ElevatedButton.icon(
            onPressed: () {
              Get.toNamed('/chat', arguments: {
                'receiverId': user.id,
                'receiverName': user.name,
              });
            },
            icon: const Icon(Icons.chat),
            label: const Text('Iniciar Chat'),
          ),
        ),
      ],
    ),
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
