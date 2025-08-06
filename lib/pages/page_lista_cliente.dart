import 'package:facturador_offline/pages/page_clientes_sincronizacion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/cubit_cliente_mostrador/cliente_mostrador_cubit.dart';
import '../bloc/cubit_lista_precios/lista_precios_cubit.dart';
import '../bloc/cubit_lista_precios/lista_precios_state.dart';
import '../models/clientes_mostrador.dart';
import '../models/lista_precio_model.dart';
import '../models/productos_maestro.dart';
import '../pages/page_mod_baja_cliente.dart';
import '../widget/build_text_field.dart';

class ClientesListPage extends StatefulWidget {
  @override
  _ClientesListPageState createState() => _ClientesListPageState();
}

class _ClientesListPageState extends State<ClientesListPage> {
  final _nameController = TextEditingController();
  final _dniController = TextEditingController();
  Lista? _selectedPriceList;
  String _selectedStatus = 'Activos';

  @override
  void initState() {
    super.initState();
    context.read<ClientesMostradorCubit>().getClientesBD();
    context.read<ListaPreciosCubit>().getListasPreciosBD();
  }

  void _filterClients() {
    final nameQuery = _nameController.text;
    final dniQuery = _dniController.text;
    final priceListQuery = _selectedPriceList?.id ?? 0;
    final isActive = _selectedStatus == 'Activos' ? 1 : 0;

    context.read<ClientesMostradorCubit>().filterClientes(
      nameQuery,
      dniQuery,
      priceListQuery,
      isActive,
    );
  }

  void _resetFilters() {
    setState(() {
      _nameController.clear();
      _dniController.clear();
      _selectedPriceList = null;
      _selectedStatus = 'Activos';
    });

    context.read<ClientesMostradorCubit>().getClientesBD();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Listado de Clientes'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildFilters(),
            const SizedBox(height: 16),
            Expanded(child: _buildClientList()),
          ],
        ),
      ),
    );
  }
  Widget _buildFilters() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final double itemWidth = constraints.maxWidth / (isSmallScreen ? 1.5 : 4);
        final fieldTextStyle = const TextStyle(fontSize: 12);

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: itemWidth,
                child: CustomTextField(
                  controller: _nameController,
                  labelText: 'Nombre',
                  hintText: 'Ej: Juan Perez',
                  onChanged: (_) => _filterClients(),
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: CustomTextField(
                  controller: _dniController,
                  labelText: 'CUIT/DNI',
                  hintText: 'Ej: 12345678901',
                  onChanged: (_) => _filterClients(),
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: BlocBuilder<ListaPreciosCubit, ListaPreciosState>(
                  builder: (context, state) {
                    if (state.currentList.isEmpty) {
                      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                    }
                    return DropdownButtonFormField<Lista>(
                      value: _selectedPriceList,
                      isExpanded: true,
                      style: fieldTextStyle,
                      items: state.currentList.map((lista) {
                        return DropdownMenuItem<Lista>(
                          value: lista,
                          child: Text(
                            lista.nombre ?? 'Sin nombre',
                            overflow: TextOverflow.ellipsis,
                            style: fieldTextStyle,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedPriceList = value);
                        _filterClients();
                      },
                      decoration: const InputDecoration(
                        labelText: 'Lista de Precios',
                        border: OutlineInputBorder(),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  isExpanded: true,
                  style: fieldTextStyle,
                  items: ['Activos', 'Inactivos'].map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status, style: fieldTextStyle),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedStatus = value!);
                    _filterClients();
                  },
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Limpiar', style: TextStyle(fontSize: 12)),
                onPressed: _resetFilters,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.sync_alt, size: 16),
                label: const Text('Sincronizar', style: TextStyle(fontSize: 12)),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ClientesSincronizacionPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }



  Widget _buildClientList() {
    return BlocBuilder<ClientesMostradorCubit, ClientesMostradorState>(
      builder: (context, state) {
        if (state.filteredClientes.isEmpty) {
          return const Center(child: Text('No hay clientes disponibles.'));
        }

        final listaPrecios = context.watch<ListaPreciosCubit>().state.currentList;

        return ListView.builder(
          itemCount: state.filteredClientes.length,
          itemBuilder: (context, index) {
            final cliente = state.filteredClientes[index];
            final listaPrecioNombre = listaPrecios.firstWhere(
                  (lista) => lista.id == cliente.listaPrecio,
              orElse: () => Lista(id: 1, nombre: 'sin lista'),
            ).nombre;

            return ListTile(
              title: Text('Nombre Cliente: ${cliente.nombre}'),
              subtitle: Text(
                'CUIT/DNI: ${cliente.dni ?? ''}\nLista de Precios: $listaPrecioNombre',
              ),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ModBajaCliente(cliente: cliente),
                  ),
                );
                if (result == true) {
                  context.read<ClientesMostradorCubit>().getClientesBD();
                }
              },
            );
          },
        );
      },
    );
  }
}
