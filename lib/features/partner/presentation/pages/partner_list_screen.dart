import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sikarir/core/constants/app_theme.dart';
import 'package:sikarir/features/auth/presentation/providers/auth_provider.dart';
import 'package:sikarir/features/partner/data/models/partner_model.dart';
import 'package:sikarir/features/partner/presentation/providers/partner_provider.dart';

class PartnerListScreen extends StatefulWidget {
  const PartnerListScreen({super.key});

  @override
  State<PartnerListScreen> createState() => _PartnerListScreenState();
}

class _PartnerListScreenState extends State<PartnerListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().user?.token;
      context.read<PartnerProvider>().fetchPartners(token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PartnerProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Mitra Industri & Perusahaan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final token = context.read<AuthProvider>().user?.token;
          await provider.fetchPartners(token);
        },
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.mintBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.mint),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.handshake_outlined, color: AppColors.mintDark, size: 28),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ekosistem Kemitraan BLK',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.mintDark,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Perusahaan rekanan siap menyerap alumni berprestasi dan memfasilitasi program magang OJT.',
                                style: TextStyle(fontSize: 11.5, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Daftar Mitra Aktif',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  ...provider.partners.map((partner) => _buildPartnerCard(partner)),
                ],
              ),
      ),
    );
  }

  Widget _buildPartnerCard(PartnerModel partner) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                  image: DecorationImage(
                    image: NetworkImage(partner.logo),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partner.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      partner.industry,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.peachBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${partner.activeVacancies} Loker',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.peachText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            partner.description,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                partner.location,
                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.mintBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  partner.partnershipType,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.mintDark,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
