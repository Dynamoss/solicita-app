import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/sync_cubit.dart';

/// Thin status strip shown under the app bar. It surfaces the two offline
/// conditions the challenge cares about: being offline, and having queued
/// actions waiting to sync. Hidden entirely when online with an empty queue.
class SyncBanner extends StatelessWidget {
  const SyncBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncCubit, SyncState>(
      builder: (context, state) {
        if (state.isOnline && !state.hasPending) {
          return const SizedBox.shrink();
        }

        final scheme = Theme.of(context).colorScheme;
        final offline = !state.isOnline;
        final bg = offline
            ? scheme.errorContainer
            : scheme.tertiaryContainer;
        final fg = offline
            ? scheme.onErrorContainer
            : scheme.onTertiaryContainer;

        return Material(
          color: bg,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(
                  offline ? Icons.wifi_off_rounded : Icons.cloud_sync_rounded,
                  size: 18,
                  color: fg,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _message(state),
                    style: TextStyle(color: fg, fontSize: 13),
                  ),
                ),
                if (state.isSyncing)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                  )
                else if (state.hasPending && state.isOnline)
                  TextButton(
                    onPressed: () => context.read<SyncCubit>().sync(),
                    style: TextButton.styleFrom(
                      foregroundColor: fg,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Sincronizar'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _message(SyncState state) {
    final pending = state.pendingCount;
    if (!state.isOnline) {
      return pending > 0
          ? 'Offline • $pending ${_actions(pending)} na fila'
          : 'Você está offline. As alterações serão sincronizadas depois.';
    }
    if (state.isSyncing) return 'Sincronizando...';
    return '$pending ${_actions(pending)} aguardando sincronização';
  }

  String _actions(int count) => count == 1 ? 'ação pendente' : 'ações pendentes';
}
