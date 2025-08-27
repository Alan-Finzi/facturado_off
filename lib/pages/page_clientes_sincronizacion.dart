import 'dart:convert';

import 'package:flutter/material.dart';
import '../models/clientes_mostrador.dart';
import '../helper/database_helper.dart';

class ClientesSincronizacionPage extends StatefulWidget {
    const ClientesSincronizacionPage({super.key});

    @override
    State<ClientesSincronizacionPage> createState() => _ClientesSincronizacionPageState();
}

enum SyncStatus { esperando, sincronizando, sincronizado, error }

class _ClientesSincronizacionPageState extends State<ClientesSincronizacionPage> {
    List<ClientesMostrador> clientesModificados = [];
    Map<String, SyncStatus> estadoClientes = {};
    bool mostrandoPopup = false;

    @override
    void initState() {
        super.initState();
        cargarClientesModificados();
    }

    Future<void> cargarClientesModificados() async {
        final clientes = await DatabaseHelper.instance.getClientesModificados();
        setState(() {
            clientesModificados = clientes;
            estadoClientes = {
                for (var c in clientes) c.idCliente ?? '': SyncStatus.esperando
            };
        });
    }

    Future<void> sincronizarClientes() async {
        setState(() => mostrandoPopup = true);

        for (var cliente in clientesModificados) {
            setState(() => estadoClientes[cliente.idCliente ?? ''] = SyncStatus.sincronizando);

            try {
                await Future.delayed(const Duration(seconds: 1)); // Simulamos API call

                // Simular respuesta exitosa
                final fueExitoso = true; // Acá pondrías tu llamada real a la API

                if (fueExitoso) {
                    await DatabaseHelper.instance.marcarClienteSincronizado(cliente.idCliente);
                    setState(() => estadoClientes[cliente.idCliente ?? ''] = SyncStatus.sincronizado);
                } else {
                    setState(() => estadoClientes[cliente.idCliente ?? ''] = SyncStatus.error);
                }
            } catch (_) {
                setState(() => estadoClientes[cliente.idCliente ?? ''] = SyncStatus.error);
            }
        }
    }

    Color obtenerColorEstado(SyncStatus estado) {
        switch (estado) {
            case SyncStatus.sincronizado:
                return Colors.green;
            case SyncStatus.sincronizando:
                return Colors.orange;
            case SyncStatus.error:
                return Colors.red;
            default:
                return Colors.grey;
        }
    }

    Icon obtenerIconoEstado(SyncStatus estado) {
        return Icon(Icons.circle, color: obtenerColorEstado(estado), size: 16);
    }

    void mostrarJson() {
        showDialog(
            context: context,
            builder: (_) => AlertDialog(
                title: const Text('JSON a enviar'),
                content: SizedBox(
                    width: double.maxFinite,
                    child: SingleChildScrollView(
                        child: SelectableText(
                            jsonEncode(clientesModificados.map((e) => e.toJson()).toList()),
                            style: const TextStyle(fontFamily: 'monospace'),
                        ),
                    ),
                ),
                actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cerrar'),
                    )
                ],
            ),
        );
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text('Clientes modificados'),
                actions: [
                    IconButton(
                        icon: const Icon(Icons.code),
                        onPressed: mostrarJson,
                    )
                ],
            ),
            body: clientesModificados.isEmpty
                ? const Center(child: Text('No hay clientes modificados.'))
                : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemBuilder: (_, i) {
                    final cliente = clientesModificados[i];
                    final estado = estadoClientes[cliente.idCliente ?? ''] ?? SyncStatus.esperando;
                    return ListTile(
                        leading: obtenerIconoEstado(estado),
                        title: Text(cliente.nombre ?? 'Sin nombre'),
                        subtitle: Text(cliente.email ?? 'Sin email'),
                    );
                },
                separatorBuilder: (_, __) => const Divider(),
                itemCount: clientesModificados.length,
            ),
            floatingActionButton: FloatingActionButton.extended(
                heroTag: 'clientes_sincronizacion_fab',
                icon: const Icon(Icons.sync),
                label: const Text('Sincronizar'),
                onPressed: sincronizarClientes,
            ),
        );
    }
}


