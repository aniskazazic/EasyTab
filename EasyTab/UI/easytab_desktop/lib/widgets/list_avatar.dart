import 'package:easytab_desktop/providers/user_provider.dart';
import 'package:easytab_desktop/providers/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ListAvatar extends StatelessWidget {
  const ListAvatar({
    super.key,
    this.image,
    required this.placeholder,
    this.circular = false,
  });

  final String? image;
  final IconData placeholder;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    final provider = imageProviderFromString(image);
    final fallback = ColoredBox(
      color: const Color(0xFFEFF6FF),
      child: Icon(placeholder, color: const Color(0xFF1E40AF)),
    );
    return SizedBox.square(
      dimension: 36,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(circular ? 18 : 6),
        child: provider == null
            ? fallback
            : Image(
                image: provider,
                fit: BoxFit.cover,
                errorBuilder: (_, error, stackTrace) => fallback,
              ),
      ),
    );
  }
}

class UserListAvatar extends StatelessWidget {
  const UserListAvatar({super.key, required this.userId});

  final int userId;

  @override
  Widget build(BuildContext context) => ProfileListAvatar(
    loadImage: () async =>
        (await context.read<UserProvider>().getById(userId)).profilePicture,
  );
}

class ProfileListAvatar extends StatefulWidget {
  const ProfileListAvatar({super.key, required this.loadImage});

  final Future<String?> Function() loadImage;

  @override
  State<ProfileListAvatar> createState() => _ProfileListAvatarState();
}

class _ProfileListAvatarState extends State<ProfileListAvatar> {
  late final Future<String?> _image;

  @override
  void initState() {
    super.initState();
    _image = widget.loadImage();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<String?>(
    future: _image,
    builder: (context, snapshot) => ListAvatar(
      image: snapshot.data,
      placeholder: Icons.person,
      circular: true,
    ),
  );
}
