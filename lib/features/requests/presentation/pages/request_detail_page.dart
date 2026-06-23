import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/widgets/state_views.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/request_status.dart';
import '../../domain/entities/service_request.dart';
import '../cubit/request_detail_cubit.dart';
import '../widgets/status_chip.dart';

class RequestDetailPage extends StatelessWidget {
  const RequestDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes')),
      body: BlocConsumer<RequestDetailCubit, RequestDetailState>(
        listenWhen: (p, c) => c.errorMessage != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        },
        builder: (context, state) {
          if (state.status == DetailStatus.loading) {
            return const LoadingView();
          }
          if (state.request == null) {
            return ErrorView(
              message: state.errorMessage ?? 'Solicitação não encontrada.',
              onRetry: () => context.read<RequestDetailCubit>().reload(),
            );
          }
          return _DetailBody(
            request: state.request!,
            isUpdating: state.status == DetailStatus.updating,
          );
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.request, required this.isUpdating});

  final ServiceRequest request;
  final bool isUpdating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                request.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            StatusChip(status: request.status),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            PriorityChip(priority: request.priority),
            const SizedBox(width: 16),
            Icon(Icons.schedule, size: 14, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              DateFormatter.relative(request.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        if (request.pendingSync) ...[
          const SizedBox(height: 12),
          _PendingNotice(theme: theme),
        ],
        const SizedBox(height: 24),
        _InfoTile(
          icon: Icons.person_outline,
          label: 'Solicitante',
          value: request.requester,
        ),
        if (request.category != null)
          _InfoTile(
            icon: Icons.sell_outlined,
            label: 'Categoria',
            value: request.category!,
          ),
        _InfoTile(
          icon: Icons.update,
          label: 'Última atualização',
          value: DateFormatter.full(request.updatedAt),
        ),
        const SizedBox(height: 16),
        Text('Descrição', style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        Text(
          request.description,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
        const SizedBox(height: 28),
        Text('Alterar status', style: theme.textTheme.titleSmall),
        const SizedBox(height: 12),
        _StatusSelector(
          current: request.status,
          enabled: !isUpdating,
          onSelected: (status) =>
              context.read<RequestDetailCubit>().changeStatus(status),
        ),
        if (isUpdating) ...[
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text('Salvando...'),
            ],
          ),
        ],
      ],
    );
  }
}

class _StatusSelector extends StatelessWidget {
  const _StatusSelector({
    required this.current,
    required this.onSelected,
    required this.enabled,
  });

  final RequestStatus current;
  final ValueChanged<RequestStatus> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final status in RequestStatus.values)
          ChoiceChip(
            label: Text(status.label),
            selected: status == current,
            showCheckmark: false,
            avatar: Icon(
              StatusVisuals.icon(status),
              size: 18,
              color: StatusVisuals.color(status),
            ),
            selectedColor: StatusVisuals.color(status).withValues(alpha: 0.16),
            onSelected: enabled && status != current
                ? (_) => onSelected(status)
                : null,
          ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: theme.textTheme.bodyLarge),
            ],
          ),
        ],
      ),
    );
  }
}

class _PendingNotice extends StatelessWidget {
  const _PendingNotice({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_upload_outlined,
            size: 18,
            color: theme.colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Alterações pendentes de sincronização.',
              style: TextStyle(
                color: theme.colorScheme.onTertiaryContainer,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
