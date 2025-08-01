import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vocario/core/l10n/app_localizations.dart';
import 'package:vocario/core/services/logger_service.dart';
import 'package:vocario/core/services/network_service/gemini_api_service.dart';
import 'package:vocario/core/utils/context_extensions.dart';
import 'package:vocario/features/audio_analyzer/domain/entities/audio_analysis.dart';
import 'package:vocario/features/audio_analyzer/presentation/providers/audio_analyzer_provider.dart';
import 'package:vocario/features/audio_analyzer/presentation/providers/recordings_provider.dart';
import 'package:vocario/features/audio_analyzer/presentation/screens/widgets/action_buttons.dart';
import 'package:vocario/features/audio_analyzer/presentation/screens/widgets/analysis_card.dart';
import 'package:vocario/features/audio_analyzer/presentation/screens/widgets/audio_player_card.dart';
import 'package:vocario/features/audio_analyzer/presentation/screens/widgets/error_widget.dart';
import 'package:vocario/features/audio_analyzer/presentation/screens/widgets/recording_info_card.dart';
import 'package:vocario/features/audio_recorder/domain/entities/audio_recording.dart';

class AnalysisResultScreen extends ConsumerStatefulWidget {
  final String recordingId;

  const AnalysisResultScreen({
    super.key,
    required this.recordingId,
  });

  @override
  ConsumerState<AnalysisResultScreen> createState() => _SummaryDetailsScreenState();
}

class _SummaryDetailsScreenState extends ConsumerState<AnalysisResultScreen> {
  AudioAnalysis? _previousAnalysis;
  final GeminiApiService _geminiApiService = GeminiApiService();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final recordingAsync = ref.watch(recordingByIdProvider(widget.recordingId));
    final analysisAsync = ref.watch(audioAnalysisByRecordingIdProvider(widget.recordingId));
    final analyzerState = ref.watch(audioAnalyzerNotifierProvider);

    ref.listen<AudioAnalyzerState>(audioAnalyzerNotifierProvider, (previous, next) {
      if (next == AudioAnalyzerState.error) {
        context.showSnackBar(
          localizations.analysisFailed,
          isError: true,
          onClick: () => context.hideSnackBar(),
        );
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackNavigation(context, analyzerState);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(localizations.recordingDetails),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _handleBackNavigation(context, analyzerState),
          ),
        ),
      body: recordingAsync.when(
        data: (recording) {
          if (recording == null) {
            return ErrorDisplayWidget(message: localizations.recordingNotFound);
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RecordingInfoCard(recording: recording),
                      const SizedBox(height: 16),
                      AudioPlayerCard(recording: recording),
                      const SizedBox(height: 16),
                      AnalysisCard(
                        analysisAsync: analysisAsync,
                        analyzerState: analyzerState,
                        recording: recording,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                child: SafeArea(
                  child: ActionButtons(
                    recording: recording,
                    analysisAsync: analysisAsync,
                    onReanalyze: () => _reanalyzeRecording(recording),
                    recordingId: widget.recordingId,
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorDisplayWidget(message: localizations.failedToLoadRecording),
      ),
      ),
    );
  }

  Future<void> _reanalyzeRecording(AudioRecording recording) async {
    if (ref.read(reanalysisNotifierProvider)) return;
    
    try {
      ref.read(reanalysisNotifierProvider.notifier).setReanalyzing(true);
      
      // Store previous analysis for potential restoration
      final currentAnalysis = await ref.read(audioAnalysisByRecordingIdProvider(widget.recordingId).future);
      _previousAnalysis = currentAnalysis;
      
      await ref.read(audioAnalyzerNotifierProvider.notifier).analyzeAudio(recording);
      
      // Invalidate providers to refresh the UI after analysis completes
      ref.invalidate(audioAnalysisByRecordingIdProvider(widget.recordingId));
      ref.invalidate(audioAnalysesListProvider);
      
      ref.read(reanalysisNotifierProvider.notifier).setReanalyzing(false);
    } catch (e) {
      LoggerService.error('Failed to reanalyze recording', e);
      
      ref.read(reanalysisNotifierProvider.notifier).setReanalyzing(false);
      
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        context.showSnackBar(
          localizations.reanalysisFailed,
          isError: true,
        );
      }
      
      // Restore previous analysis if available
      if (_previousAnalysis != null) {
        ref.invalidate(audioAnalysisByRecordingIdProvider(widget.recordingId));
      }
    }
  }

  Future<void> _handleBackNavigation(
    BuildContext context,
    AudioAnalyzerState analyzerState,
  ) async {
    final localizations = AppLocalizations.of(context)!;
    
    if (analyzerState == AudioAnalyzerState.analyzing ||
        ref.read(reanalysisNotifierProvider)) {
      
      final shouldLeave = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(localizations.analysisInProgress),
            content: Text(localizations.analysisInProgressMessage),
            actions: [
              TextButton(
                onPressed: () => context.pop(false),
                child: Text(localizations.cancel),
              ),
              TextButton(
                onPressed: () => context.pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: Text(localizations.leaveAnyway),
              ),
            ],
          );
        },
      );
      
      if (shouldLeave == true) {
        _geminiApiService.cancelOperations();
        
        ref.read(audioAnalyzerNotifierProvider.notifier).reset();
        ref.read(reanalysisNotifierProvider.notifier).setReanalyzing(false);
        
        if (context.mounted) {
          context.pop();
        }
      }
    } else {
      if (context.mounted) {
        context.pop();
      }
    }
  }
}