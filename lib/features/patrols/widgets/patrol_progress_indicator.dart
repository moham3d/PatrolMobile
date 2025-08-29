import 'package:flutter/material.dart';

/// Progress indicator widget for patrol completion
class PatrolProgressIndicator extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double height;
  final bool showPercentage;
  final Color? backgroundColor;
  final Color? progressColor;

  const PatrolProgressIndicator({
    super.key,
    required this.progress,
    this.height = 8,
    this.showPercentage = false,
    this.backgroundColor,
    this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackgroundColor = backgroundColor ?? Colors.grey.shade300;
    final effectiveProgressColor = progressColor ?? _getProgressColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  color: effectiveBackgroundColor,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: effectiveProgressColor,
                      borderRadius: BorderRadius.circular(height / 2),
                    ),
                  ),
                ),
              ),
            ),
            if (showPercentage) ...[
              const SizedBox(width: 8),
              Text(
                '${(progress * 100).round()}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: effectiveProgressColor,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Color _getProgressColor() {
    if (progress < 0.3) {
      return Colors.red.shade600;
    } else if (progress < 0.7) {
      return Colors.orange.shade600;
    } else {
      return Colors.green.shade600;
    }
  }
}

/// Circular progress indicator for patrol completion
class CircularPatrolProgressIndicator extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final bool showPercentage;
  final Color? backgroundColor;
  final Color? progressColor;

  const CircularPatrolProgressIndicator({
    super.key,
    required this.progress,
    this.size = 60,
    this.strokeWidth = 6,
    this.showPercentage = true,
    this.backgroundColor,
    this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackgroundColor = backgroundColor ?? Colors.grey.shade300;
    final effectiveProgressColor = progressColor ?? _getProgressColor();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Background circle
          CircularProgressIndicator(
            value: 1.0,
            strokeWidth: strokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(effectiveBackgroundColor),
          ),
          // Progress circle
          CircularProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            strokeWidth: strokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(effectiveProgressColor),
          ),
          // Percentage text
          if (showPercentage)
            Center(
              child: Text(
                '${(progress * 100).round()}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: effectiveProgressColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getProgressColor() {
    if (progress < 0.3) {
      return Colors.red.shade600;
    } else if (progress < 0.7) {
      return Colors.orange.shade600;
    } else {
      return Colors.green.shade600;
    }
  }
}

/// Checkpoint progress indicator showing visited/total checkpoints
class CheckpointProgressIndicator extends StatelessWidget {
  final int visitedCheckpoints;
  final int totalCheckpoints;
  final bool showNumbers;
  final double height;

  const CheckpointProgressIndicator({
    super.key,
    required this.visitedCheckpoints,
    required this.totalCheckpoints,
    this.showNumbers = true,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = totalCheckpoints > 0 ? visitedCheckpoints / totalCheckpoints : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showNumbers) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Checkpoints',
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                '$visitedCheckpoints / $totalCheckpoints',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        PatrolProgressIndicator(
          progress: progress,
          height: height,
        ),
      ],
    );
  }
}

/// Step progress indicator for patrol phases
class StepProgressIndicator extends StatelessWidget {
  final List<String> steps;
  final int currentStep;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? completedColor;

  const StepProgressIndicator({
    super.key,
    required this.steps,
    required this.currentStep,
    this.activeColor,
    this.inactiveColor,
    this.completedColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveActiveColor = activeColor ?? theme.primaryColor;
    final effectiveInactiveColor = inactiveColor ?? Colors.grey.shade300;
    final effectiveCompletedColor = completedColor ?? Colors.green.shade600;

    return Row(
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                // Step circle
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getStepColor(i, effectiveActiveColor, effectiveInactiveColor, effectiveCompletedColor),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getStepBorderColor(i, effectiveActiveColor, effectiveInactiveColor, effectiveCompletedColor),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: _getStepIcon(i),
                  ),
                ),
                const SizedBox(height: 8),
                // Step label
                Text(
                  steps[i],
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _getStepTextColor(i, effectiveActiveColor, effectiveInactiveColor, effectiveCompletedColor),
                    fontWeight: i <= currentStep ? FontWeight.w500 : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Connector line
          if (i < steps.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 40),
                color: i < currentStep ? effectiveCompletedColor : effectiveInactiveColor,
              ),
            ),
        ],
      ],
    );
  }

  Color _getStepColor(int index, Color activeColor, Color inactiveColor, Color completedColor) {
    if (index < currentStep) {
      return completedColor;
    } else if (index == currentStep) {
      return activeColor;
    } else {
      return Colors.white;
    }
  }

  Color _getStepBorderColor(int index, Color activeColor, Color inactiveColor, Color completedColor) {
    if (index < currentStep) {
      return completedColor;
    } else if (index == currentStep) {
      return activeColor;
    } else {
      return inactiveColor;
    }
  }

  Color _getStepTextColor(int index, Color activeColor, Color inactiveColor, Color completedColor) {
    if (index < currentStep) {
      return completedColor;
    } else if (index == currentStep) {
      return activeColor;
    } else {
      return inactiveColor;
    }
  }

  Widget _getStepIcon(int index) {
    if (index < currentStep) {
      return const Icon(
        Icons.check,
        size: 16,
        color: Colors.white,
      );
    } else if (index == currentStep) {
      return const Icon(
        Icons.play_arrow,
        size: 16,
        color: Colors.white,
      );
    } else {
      return Text(
        '${index + 1}',
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
    }
  }
}