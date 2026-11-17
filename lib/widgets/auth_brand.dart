import 'package:flutter/material.dart';

class AuthBrand extends StatelessWidget {
  const AuthBrand({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(compact ? 14 : 24),
    decoration: BoxDecoration(
      color: const Color(0xFF75354A),
      borderRadius: BorderRadius.circular(compact ? 18 : 26),
    ),
    child: Row(
      children: [
        Container(
          padding: EdgeInsets.all(compact ? 9 : 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFC894A6)),
          ),
          child: Text(
            'KS',
            style: TextStyle(
              color: const Color(0xFFFFFCF8),
              fontWeight: FontWeight.w800,
              fontSize: compact ? 14 : 22,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'KEZEK SENDE',
                style: TextStyle(
                  color: const Color(0xFFFFFCF8),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  fontSize: compact ? 15 : 24,
                ),
              ),
              if (!compact)
                const Text(
                  'by zhanna',
                  style: TextStyle(color: Color(0xFFF1DFE3)),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
