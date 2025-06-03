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
    final priceListQuery = _selectedPriceList?.id ?? 1;
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
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        SizedBox(
          width: 250,
          child: CustomTextField(
            controller: _nameController,
            labelText: 'Buscar por Nombre',
            hintText: 'Ej: Juan Perez',
            onChanged: (_) => _filterClients(),
          ),
        ),
        SizedBox(
          width: 200,
          child: CustomTextField(
            controller: _dniController,
            labelText: 'Buscar por CUIT/DNI',
            hintText: 'Ej: 12345678901',
            onChanged: (_) => _filterClients(),
          ),
        ),
        SizedBox(
          width: 300,
          child: BlocBuilder<ListaPreciosCubit, ListaPreciosState>(
            builder: (context, state) {
              if (state.currentList.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              return DropdownButtonFormField<Lista>(
                value: _selectedPriceList,
                isExpanded: true, // <-- Esto permite que el menú ocupe todo el ancho
                items: state.currentList.map((lista) {
                  return DropdownMenuItem<Lista>(
                    value: lista,
                    child: Text(
                      lista.nombre ?? 'Sin nombre',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPriceList = value;
                  });
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
          width: 150,
          child: DropdownButtonFormField<String>(
            value: _selectedStatus,
            items: ['Activos', 'Inactivos'].map((status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Text(status),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedStatus = value!;
              });
              _filterClients();
            },
            decoration: const InputDecoration(
              labelText: 'Estado',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _resetFilters,
          icon: const Icon(Icons.refresh),
          label: const Text('Limpiar filtros'),
        ),
      ],
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ModBajaCliente(cliente: cliente),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
