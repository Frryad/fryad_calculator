import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/profile.dart';
import 'profile_detail_page.dart';

class ProfilesListPage extends StatefulWidget {
  const ProfilesListPage({super.key});
  @override
  State<ProfilesListPage> createState() => _ProfilesListPageState();
}

class _ProfilesListPageState extends State<ProfilesListPage> {
  late Future<List<Profile>> _profilesFuture;
  final dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _refreshProfiles();
  }

  void _refreshProfiles() {
    setState(() {
      _profilesFuture = dbHelper.getProfiles();
    });
  }

  void _showProfileDialog({Profile? profile}) {
    final nameController = TextEditingController(text: profile?.name);
    final descController = TextEditingController(text: profile?.description);
    final usdController = TextEditingController(text: profile?.dollarBalance.toString() ?? '0');
    final iqdController = TextEditingController(text: profile?.dinarBalance.toString() ?? '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(profile == null ? "New Profile" : "Edit Profile"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name")),
              TextField(controller: descController, decoration: const InputDecoration(labelText: "Description")),
              TextField(controller: usdController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "USD Balance")),
              TextField(controller: iqdController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "IQD Balance")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final newProfile = Profile(
                id: profile?.id,
                name: nameController.text,
                description: descController.text,
                dollarBalance: double.tryParse(usdController.text) ?? 0,
                dinarBalance: double.tryParse(iqdController.text) ?? 0,
              );
              if (profile == null) {
                await dbHelper.insertProfile(newProfile);
              } else {
                await dbHelper.updateProfile(newProfile);
              }
              _refreshProfiles();
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profiles")),
      body: FutureBuilder<List<Profile>>(
        future: _profilesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No profiles yet. Add one!"));
          }
          final profiles = snapshot.data!;
          return ListView.builder(
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profile = profiles[index];
              return ListTile(
                leading: CircleAvatar(child: Text(profile.name.substring(0,1))),
                title: Text(profile.name),
                subtitle: Text(profile.description),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileDetailPage(profileId: profile.id!)),
                  );
                  _refreshProfiles(); // Refresh list after returning from detail page
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showProfileDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}