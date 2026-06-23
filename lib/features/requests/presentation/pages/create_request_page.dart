import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/new_request_draft.dart';
import '../../domain/entities/request_status.dart';
import '../cubit/create_request_cubit.dart';

class CreateRequestPage extends StatefulWidget {
  const CreateRequestPage({super.key});

  @override
  State<CreateRequestPage> createState() => _CreateRequestPageState();
}

class _CreateRequestPageState extends State<CreateRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _requester = TextEditingController();
  final _category = TextEditingController();
  RequestPriority _priority = RequestPriority.medium;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _requester.dispose();
    _category.dispose();
    super.dispose();
  }

  void _suggest() {
    FocusScope.of(context).unfocus();
    if (_description.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Descreva melhor a solicitação para usar a IA.'),
        ),
      );
      return;
    }
    context.read<CreateRequestCubit>().suggestMeta(_description.text);
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<CreateRequestCubit>().submit(
          NewRequestDraft(
            title: _title.text.trim(),
            description: _description.text.trim(),
            priority: _priority,
            requester: _requester.text.trim(),
            category: _category.text.trim().isEmpty
                ? null
                : _category.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova solicitação')),
      body: BlocConsumer<CreateRequestCubit, CreateRequestState>(
        listener: (context, state) {
          if (state.status == CreateStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Solicitação criada!')),
            );
            context.pop();
          } else if (state.status == CreateStatus.error &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          } else if (state.suggestion != null &&
              _category.text != state.suggestion!.category) {
            // Auto-apply the suggested category for convenience.
            _category.text = state.suggestion!.category;
          }
        },
        builder: (context, state) {
          return AbsorbPointer(
            absorbing: state.isSubmitting,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  TextFormField(
                    controller: _title,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Título *',
                      hintText: 'Ex.: Não consigo acessar o sistema',
                    ),
                    validator: (v) => (v ?? '').trim().length < 4
                        ? 'Mínimo de 4 caracteres.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _description,
                    minLines: 4,
                    maxLines: 8,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Descrição *',
                      alignLabelWithHint: true,
                      hintText: 'Detalhe o que está acontecendo...',
                    ),
                    validator: (v) => (v ?? '').trim().length < 10
                        ? 'Descreva com ao menos 10 caracteres.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _AiSuggestionSection(
                    state: state,
                    onSuggest: _suggest,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _requester,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Solicitante *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) => (v ?? '').trim().isEmpty
                        ? 'Informe o solicitante.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _category,
                    decoration: const InputDecoration(
                      labelText: 'Categoria',
                      prefixIcon: Icon(Icons.sell_outlined),
                      hintText: 'Opcional (ou sugira com a IA)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<RequestPriority>(
                    initialValue: _priority,
                    decoration: const InputDecoration(
                      labelText: 'Prioridade',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                    items: [
                      for (final p in RequestPriority.values)
                        DropdownMenuItem(value: p, child: Text(p.label)),
                    ],
                    onChanged: (p) =>
                        setState(() => _priority = p ?? RequestPriority.medium),
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: state.isSubmitting ? null : _submit,
                    icon: state.isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: Text(
                      state.isSubmitting ? 'Salvando...' : 'Criar solicitação',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AiSuggestionSection extends StatelessWidget {
  const _AiSuggestionSection({required this.state, required this.onSuggest});

  final CreateRequestState state;
  final VoidCallback onSuggest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestion = state.suggestion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: state.isSuggesting ? null : onSuggest,
          icon: state.isSuggesting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome, size: 18),
          label: Text(
            state.isSuggesting
                ? 'Analisando...'
                : 'Sugerir categoria/resumo com IA',
          ),
        ),
        if (suggestion != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome,
                        size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Sugestão da IA',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    if (suggestion.fromFallback)
                      Text(
                        'modo offline',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Categoria: ${suggestion.category}',
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text('Resumo: ${suggestion.summary}',
                    style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
