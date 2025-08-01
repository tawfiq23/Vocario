import 'package:flutter/material.dart';
import 'package:vocario/core/l10n/app_localizations.dart';
import 'package:vocario/features/audio_recorder/domain/entities/audio_recording.dart';

class AnalysisError extends StatelessWidget {
  final String? errorMessage;
  final AudioRecording recording;

  const AnalysisError({
    super.key,
    required this.errorMessage,
    required this.recording,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return Row(
      children: [
        Icon(
          Icons.error_outline,
          size: 36,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            errorMessage ?? localizations.analysisFailed,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      ],
    );
  }
}