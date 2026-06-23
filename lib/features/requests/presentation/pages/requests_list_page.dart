import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/widgets/brand_picker.dart';
import '../../../../core/presentation/widgets/state_views.dart';
import '../../../../core/theme/brand_cubit.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/requests_list_cubit.dart';
import '../widgets/request_card.dart';
import '../widgets/status_filter_bar.dart';
import '../widgets/sync_banner.dart';

class RequestsListPage extends StatefulWidget {
  const RequestsListPage({super.key});

  @override
  State<RequestsListPage> createState() => _RequestsListPageState();
}

class _RequestsListPageState extends State<RequestsListPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    // Trigger the next page a bit before the very bottom for a smooth feel.
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 280) {
      context.read<RequestsListCubit>().loadMore();
    }
  }

  Future<void> _openCreate() async {
    await context.push('/requests/new');
    if (mounted) context.read<RequestsListCubit>().load(refresh: true);
  }

  Future<void> _openDetail(String id) async {
    await context.push('/requests/$id');
    if (mounted) context.read<RequestsListCubit>().load(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.watch<BrandCubit>().state;
    final cubit = context.read<RequestsListCubit>();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Text(brand.logoEmoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(brand.name, style: const TextStyle(fontSize: 17)),
                  Text(
                    'Solicitações',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Trocar marca',
            icon: const Icon(Icons.palette_outlined),
            onPressed: () => showBrandPicker(context),
          ),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => context.read<AuthCubit>().logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('Nova'),
      ),
      body: Column(
        children: [
          const SyncBanner(),
          BlocBuilder<RequestsListCubit, RequestsListState>(
            buildWhen: (p, c) => p.filter != c.filter,
            builder: (context, state) => StatusFilterBar(
              selected: state.filter,
              onChanged: cubit.changeFilter,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => cubit.load(refresh: true),
              child: BlocBuilder<RequestsListCubit, RequestsListState>(
                builder: (context, state) => _buildBody(context, state, cubit),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    RequestsListState state,
    RequestsListCubit cubit,
  ) {
    if (state.isInitialLoading) {
      return const LoadingView(message: 'Carregando solicitações...');
    }
    if (state.status == ListStatus.error && state.items.isEmpty) {
      return ListView(
        // ListView so pull-to-refresh still works on the error state.
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: ErrorView(
              message: state.errorMessage ?? 'Não foi possível carregar.',
              onRetry: () => cubit.load(),
            ),
          ),
        ],
      );
    }
    if (state.isEmpty) {
      return ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: EmptyView(
              title: 'Nenhuma solicitação',
              subtitle: state.filter == null
                  ? 'Crie a primeira solicitação no botão "Nova".'
                  : 'Nenhuma solicitação com este status.',
              icon: Icons.assignment_outlined,
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: state.items.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final request = state.items[index];
        return RequestCard(
          request: request,
          onTap: () => _openDetail(request.id),
        );
      },
    );
  }
}
