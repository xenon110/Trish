import 'package:flutter/material.dart';
import 'package:trish_app/widgets/skeleton_loader.dart';

class SkeletonFactory {
  static Widget skeletonListTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          const SkeletonLoader(width: 56, height: 56, borderRadius: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLoader(width: 120, height: 16),
                const SizedBox(height: 8),
                const SkeletonLoader(width: double.infinity, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget skeletonCard({double height = 200}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(width: double.infinity, height: height, borderRadius: 24),
          const SizedBox(height: 16),
          const SkeletonLoader(width: 150, height: 20),
          const SizedBox(height: 8),
          const SkeletonLoader(width: 100, height: 14),
        ],
      ),
    );
  }
}
