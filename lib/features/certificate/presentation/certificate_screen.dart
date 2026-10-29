import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sikarir/core/constants/app_theme.dart';
import 'package:sikarir/core/widgets/blk_header.dart';
import 'package:sikarir/features/auth/presentation/providers/auth_provider.dart';
import 'package:sikarir/features/certificate/presentation/providers/certificate_provider.dart';

class CertificateScreen extends StatefulWidget {
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;

  const CertificateScreen({
    super.key,
    this.onNotificationTap,
    this.onProfileTap,
  });

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token;
      context.read<CertificateProvider>().fetchCertificates(token);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            BlkHeader(
              sectionTitle: 'Sertifikat',
              onNotificationTap: widget.onNotificationTap,
              onProfileTap: widget.onProfileTap,
            ),
            Expanded(
              child: Consumer<CertificateProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.certificates.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final certificates = provider.certificates;

                  return RefreshIndicator(
                    onRefresh: () async {
                      final token = context.read<AuthProvider>().token;
                      await provider.fetchCertificates(token);
                    },
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        const Text(
                          'Sertifikasi & Lisensi Resmi',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Daftar sertifikat kompetensi BNSP dan kelulusan pelatihan BLK Anda.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        if (certificates.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: const Center(
                              child: Text(
                                'Belum ada sertifikat terdaftar.',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ),
                          )
                        else
                          ...certificates.map((cert) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.mintBg,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.verified_rounded,
                                          color: AppColors.mintDark,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              cert.title,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            Text(
                                              cert.issuer,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'NOMOR REGISTRASI',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            Text(
                                              cert.certificateNumber,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.mint,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            cert.status == 'aktif' ? 'Terverifikasi' : cert.status.toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.mintDark,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Berlaku s/d: ${cert.validUntil}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          final url = cert.fileUrl;
                                          if (url.isNotEmpty) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Mengunduh e-Sertifikat dari: $url')),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('File e-Sertifikat belum tersedia atau sedang diproses.')),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.download_rounded, size: 14),
                                        label: const Text('Unduh PDF', style: TextStyle(fontSize: 11)),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.primary,
                                          side: const BorderSide(color: AppColors.primary),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
