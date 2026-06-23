import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../config/brand.dart';
import '../../theme/brand_cubit.dart';

/// Opens the whitelabel brand selector. Picking a brand re-themes the running
/// app instantly (no restart) — the demo of the whitelabel differential.
Future<void> showBrandPicker(BuildContext context) {
  final cubit = context.read<BrandCubit>();
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return BlocBuilder<BrandCubit, Brand>(
        bloc: cubit,
        builder: (context, current) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Text(
                    'Marca (whitelabel)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                for (final brand in Brands.all)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: brand.seedColor.withValues(alpha: 0.15),
                      child: Text(brand.logoEmoji),
                    ),
                    title: Text(brand.name),
                    subtitle: Text(
                      brand.tagline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: brand.id == current.id
                        ? Icon(Icons.check_circle, color: brand.seedColor)
                        : null,
                    onTap: () {
                      cubit.select(brand);
                      Navigator.of(sheetContext).pop();
                    },
                  ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      );
    },
  );
}
