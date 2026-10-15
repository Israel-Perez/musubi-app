import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/features/status/domain/api_status.dart';
import 'package:musubi_app/features/status/presentation/status_providers.dart';

/// Pantalla inicial "Musubi": muestra el estado de la conexion con la API y
/// no se rompe si la API no responde (01-03).
class HomeScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final status = ref.watch(apiStatusProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Musubi', style: textTheme.displayMedium),
                const SizedBox(height: 8),
                Text(
                  'Compra y vende entre estudiantes de la UTTT',
                  style: textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                switch (status) {
                  AsyncData(:final value) => _StatusCard(status: value),
                  AsyncError() => const _StatusCard(
                    status: ApiOffline(
                      message: 'No se pudo consultar el servidor.',
                    ),
                  ),
                  _ => const _Checking(),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Checking extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      CircularProgressIndicator(),
      SizedBox(height: 12),
      Text('Conectando con el servidor…'),
    ],
  );
}

class _StatusCard extends ConsumerWidget {
  const new({required this.status});

  final ApiStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    return switch (status) {
      ApiOnline(:final version) => ListTile(
        key: const Key('status-online'),
        leading: Icon(Icons.cloud_done, color: colors.primary),
        title: const Text('Servidor conectado'),
        subtitle: Text('API $version'),
      ),
      ApiOffline(:final message) => Column(
        key: const Key('status-offline'),
        children: [
          ListTile(
            leading: Icon(Icons.cloud_off, color: colors.error),
            title: const Text('Sin conexión con el servidor'),
            subtitle: Text(message),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => ref.invalidate(apiStatusProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    };
  }
}
