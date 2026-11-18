import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sikarir/core/constants/app_theme.dart';
import 'package:sikarir/features/profile/presentation/providers/peserta_provider.dart';

class ProfileAvatar extends StatelessWidget {
  final double size;
  final double borderWidth;

  const ProfileAvatar({super.key, this.size = 72, this.borderWidth = 3});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PesertaProvider>();
    final baseUrl = provider.profile?.pasFotoUrl;

    final url = (baseUrl == null)
        ? null
        : '$baseUrl${baseUrl.contains('?') ? '&' : '?'}v=${provider.photoVersion}';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.mintBg,
        border: Border.all(color: AppColors.mint, width: borderWidth),
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? _placeholder()
          : Image.network(
              url,
              key: ValueKey(url),
              fit: BoxFit.cover,
              loadingBuilder: (ctx, child, progress) =>
                  progress == null ? child : _placeholder(),
              errorBuilder: (ctx, error, stack) => _placeholder(),
            ),
    );
  }

  Widget _placeholder() => Icon(
        Icons.person_rounded,
        size: size * 0.55,
        color: AppColors.mintDark,
      );
}