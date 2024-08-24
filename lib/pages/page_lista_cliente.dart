import 'package:facturador_offline/pages/page_mod_baja_cliente.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/cubit_cliente_mostrador/cliente_mostrador_cubit.dart';
import '../bloc/cubit_lista_precios/lista_precios_cubit.dart';
import '../bloc/cubit_lista_precios/lista_precios_state.dart';
import '../models/clientes_mostrador.dart';
import '../models/lista_precio_model.dart';
import '../widget/build_text_field.dart';

class ClientesListPage extends StatefulWidget {
  @override
  _ClientesListPageState createState() => _ClientesListPageState();
}

class _ClientesListPageState extends State<ClientesListPage> {
  final _nameController = TextEditingController();
  final _dniController = TextEditingController();
  ListaPreciosModel? _selectedPriceList;
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

    context.read<ClientesMostradorCubit>().filterClientes(nameQuery, dniQuery, priceListQuery, isActive);
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
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _nameController,
                    labelText: 'Buscar por Nombre',
                    hintText: 'Ej: Juan Perez',
                    onChanged: (value) => _filterClients(),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: CustomTextField(
                    controller: _dniController,
                    labelText: 'Buscar por CUIT/DNI',
                    hintText: 'Ej: 12345678901',
                    onChanged: (value) => _filterClients(),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: BlocBuilder<ListaPreciosCubit, ListaPreciosState>(
                    builder: (context, state) {
                      if (state.currentList.isEmpty) {
                        return CircularProgressIndicator(); // Muestra un indicador de carga mientras se obtienen las listas
                      }
                      return DropdownButtonFormField<ListaPreciosModel>(
                        value: _selectedPriceList,
                        items: state!.currentList.map((lista) {
                          return DropdownMenuItem<ListaPreciosModel>(
                            value: lista,
                            child: Text(lista.nombre!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPriceList = value;
                          });
                          _filterClients();
                        },
                        decoration: const InputDecoration(
                          labelText: 'Buscar por Lista de Precios',
                          border: OutlineInputBorder(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<ClientesMostradorCubit, ClientesMostradorState>(
                builder: (context, state) {
                  if (state.filteredClientes.isEmpty) {
                    return const Center(child: Text('No hay clientes disponibles.'));
                  }
                  return ListView.builder(
                    itemCount: state.filteredClientes.length,
                    itemBuilder: (context, index) {
                      final cliente = state.filteredClientes[index];
                      final listaPrecios = context.read<ListaPreciosCubit>().state.currentList;
                      final listaPrecioNombre = listaPrecios.firstWhere(
                            (lista) => lista.id == cliente.listaPrecio,
                        orElse: () => ListaPreciosModel(id: 0, nombre: 'Desconocido'),
                      ).nombre;

                      return ListTile(
                        title: Text( 'Nombre Cliente :  ${cliente.nombre}'),
                        subtitle: Text('CUIT/DNI: ${cliente.dni ?? ''}\nLista de Precios: $listaPrecioNombre'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ModBajaCliente(cliente: cliente), // Pasar el cliente a la página
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
