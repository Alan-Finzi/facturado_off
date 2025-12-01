import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:facturador_offline/bloc/cubit_thema/thema_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../helper/sales_database_helper.dart';
import '../helper/sales_sync_helper.dart';
import '../models/sales/sale.dart';
import '../util/logger.dart';

class PageVentasSincronizacion extends StatefulWidget {
  const PageVentasSincronizacion({Key? key}) : super(key: key);

  @override
  _PageVentasSincronizacionState createState() => _PageVentasSincronizacionState();
}

class _PageVentasSincronizacionState extends State<PageVentasSincronizacion> {
  final SalesDatabaseHelper _salesHelper = SalesDatabaseHelper();
  final SalesSyncHelper _syncHelper = SalesSyncHelper();

  List<Sale> _ventas = [];
  List<Sale> _ventasFiltradas = [];

  bool _isLoading = true;
  bool _isInternetConnected = false;
  ConnectionQuality _connectionQuality = ConnectionQuality.unknown;

  // Controladores para filtros
  final TextEditingController _searchController = TextEditingController();
  String _ordenActual = 'fecha_desc';
  String _filtroEstado = 'todos';

  // Controlador para verificar la conectividad
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  Timer? _internetQualityTimer;

  @override
  void initState() {
    super.initState();
    _cargarVentas();
    _iniciarMonitorDeConexion();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _connectivitySubscription.cancel();
    _internetQualityTimer?.cancel();
    super.dispose();
  }

  // Cargar ventas desde la base de datos
  Future<void> _cargarVentas() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final ventas = await _salesHelper.getAllSales();
      setState(() {
        _ventas = ventas;
        _ventasFiltradas = List.from(_ventas);
        _aplicarFiltros();
        _isLoading = false;
      });
    } catch (e) {
      log.e('PageVentasSincronizacion', 'Error al cargar ventas', e);
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar ventas: $e')),
        );
      }
    }
  }

  // Iniciar monitoreo de conexión a internet
  void _iniciarMonitorDeConexion() {
    // Verificar estado inicial
    Connectivity().checkConnectivity().then((result) {
      _actualizarEstadoConexion(result);
    });

    // Escuchar cambios en la conectividad
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      _actualizarEstadoConexion(result);
    });

    // Iniciar timer para verificar calidad de conexión
    _internetQualityTimer = Timer.periodic(Duration(seconds: 10), (_) {
      _verificarCalidadConexion();
    });
  }

  // Actualizar estado de conexión
  void _actualizarEstadoConexion(ConnectivityResult result) {
    setState(() {
      _isInternetConnected = result != ConnectivityResult.none;

      if (!_isInternetConnected) {
        _connectionQuality = ConnectionQuality.none;
      } else {
        _verificarCalidadConexion();
      }
    });
  }

  // Verificar calidad de la conexión
  Future<void> _verificarCalidadConexion() async {
    if (!_isInternetConnected) {
      setState(() {
        _connectionQuality = ConnectionQuality.none;
      });
      return;
    }

    try {
      // Simular verificación de calidad (en un caso real se mediría la velocidad o latencia)
      final start = DateTime.now();

      // Reemplazar con una verificación real de conectividad
      await Future.delayed(Duration(milliseconds: 500));

      final end = DateTime.now();
      final responseTime = end.difference(start).inMilliseconds;

      setState(() {
        if (responseTime < 300) {
          _connectionQuality = ConnectionQuality.good;
        } else if (responseTime < 800) {
          _connectionQuality = ConnectionQuality.medium;
        } else {
          _connectionQuality = ConnectionQuality.poor;
        }
      });
    } catch (e) {
      setState(() {
        _connectionQuality = ConnectionQuality.poor;
      });
    }
  }

  // Aplicar filtros y ordenamientos a la lista de ventas
  void _aplicarFiltros() {
    final busqueda = _searchController.text.toLowerCase();

    setState(() {
      _ventasFiltradas = _ventas.where((venta) {
        // Filtrar por texto de búsqueda
        bool coincideTexto = true;
        if (busqueda.isNotEmpty) {
          final idVenta = venta.id?.toString().toLowerCase() ?? '';
          final nroVenta = venta.nroVenta?.toLowerCase() ?? '';
          final fecha = DateFormat('dd/MM/yyyy').format(venta.fecha).toLowerCase();
          final cliente = venta.clienteId?.toString().toLowerCase() ?? '';

          coincideTexto = idVenta.contains(busqueda) ||
                           nroVenta.contains(busqueda) ||
                           fecha.contains(busqueda) ||
                           cliente.contains(busqueda);
        }

        // Filtrar por estado de sincronización
        bool coincideEstado = true;
        if (_filtroEstado != 'todos') {
          switch (_filtroEstado) {
            case 'sincronizados':
              coincideEstado = venta.sincronizado == 1;
              break;
            case 'pendientes':
              coincideEstado = venta.sincronizado == 0;
              break;
            case 'error':
              coincideEstado = venta.estado == 'error';
              break;
          }
        }

        return coincideTexto && coincideEstado;
      }).toList();

      // Aplicar ordenamiento
      switch (_ordenActual) {
        case 'fecha_asc':
          _ventasFiltradas.sort((a, b) => a.fecha.compareTo(b.fecha));
          break;
        case 'fecha_desc':
          _ventasFiltradas.sort((a, b) => b.fecha.compareTo(a.fecha));
          break;
        case 'estado':
          _ventasFiltradas.sort((a, b) {
            // Prioridad: error, pendiente, sincronizado
            int getPrioridad(Sale venta) {
              if (venta.estado == 'error') return 0;
              if (venta.sincronizado == 0) return 1;
              return 2;
            }
            return getPrioridad(a).compareTo(getPrioridad(b));
          });
          break;
        case 'total_desc':
          _ventasFiltradas.sort((a, b) => b.total.compareTo(a.total));
          break;
      }
    });
  }

  // Sincronizar todas las ventas pendientes
  Future<void> _sincronizarVentas() async {
    if (!_isInternetConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No hay conexión a internet. Intente nuevamente cuando esté conectado.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final resultado = await _syncHelper.syncAllSales();

      // Recargar ventas para mostrar estado actualizado
      await _cargarVentas();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sincronización completada: ${resultado['success'].length} exitosas, ${resultado['failed'].length} fallidas'
          ),
          backgroundColor: resultado['failed'].length > 0 ? Colors.orange : Colors.green,
        ),
      );
    } catch (e) {
      log.e('PageVentasSincronizacion', 'Error al sincronizar ventas', e);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al sincronizar ventas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Obtener color según estado de sincronización
  Color _getColorPorEstado(Sale venta) {
    if (venta.estado == 'error') {
      return Colors.red.shade100;
    } else if (venta.sincronizado == 0) {
      return Colors.grey.shade200;
    } else {
      return Colors.green.shade100;
    }
  }

  // Widget de indicador de conexión a internet
  Widget _buildInternetIndicator() {
    Color color;
    String text;
    IconData icon;

    switch (_connectionQuality) {
      case ConnectionQuality.good:
        color = Colors.green;
        text = "Buena conexión";
        icon = Icons.wifi;
        break;
      case ConnectionQuality.medium:
        color = Colors.orange;
        text = "Conexión regular";
        icon = Icons.wifi_1_bar;
        break;
      case ConnectionQuality.poor:
        color = Colors.orange.shade700;
        text = "Conexión lenta";
        icon = Icons.wifi_2_bar;
        break;
      case ConnectionQuality.none:
        color = Colors.grey;
        text = "Sin conexión";
        icon = Icons.wifi_off;
        break;
      case ConnectionQuality.unknown:
      default:
        color = Colors.grey;
        text = "Verificando...";
        icon = Icons.wifi_find;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          SizedBox(width: 6),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeCubit = context.watch<ThemaCubit>();
    final isDark = themeCubit.state.isDark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sincronización de Ventas',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        actions: [
          _buildInternetIndicator(),
          SizedBox(width: 12),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _sincronizarVentas,
        backgroundColor: _isInternetConnected ? Colors.blue : Colors.grey,
        tooltip: 'Sincronizar ventas',
        child: Icon(_isLoading ? Icons.hourglass_top : Icons.sync),
      ),
      body: Column(
        children: [
          // Filtros y búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Campo de búsqueda
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Buscar por ID, fecha o cliente',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _aplicarFiltros();
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) => _aplicarFiltros(),
                ),

                SizedBox(height: 16),

                // Filtros y ordenamiento
                Row(
                  children: [
                    // Filtro por estado
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Estado',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        value: _filtroEstado,
                        items: [
                          DropdownMenuItem(value: 'todos', child: Text('Todos')),
                          DropdownMenuItem(
                            value: 'sincronizados',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 16),
                                SizedBox(width: 8),
                                Text('Sincronizados'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'pendientes',
                            child: Row(
                              children: [
                                Icon(Icons.schedule, color: Colors.grey, size: 16),
                                SizedBox(width: 8),
                                Text('Pendientes'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'error',
                            child: Row(
                              children: [
                                Icon(Icons.error, color: Colors.red, size: 16),
                                SizedBox(width: 8),
                                Text('Con error'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _filtroEstado = value;
                              _aplicarFiltros();
                            });
                          }
                        },
                      ),
                    ),

                    SizedBox(width: 12),

                    // Ordenamiento
                    Expanded(
                      flex: 4,
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Ordenar por',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        value: _ordenActual,
                        items: [
                          DropdownMenuItem(
                            value: 'fecha_desc',
                            child: Text('Fecha (más reciente)'),
                          ),
                          DropdownMenuItem(
                            value: 'fecha_asc',
                            child: Text('Fecha (más antigua)'),
                          ),
                          DropdownMenuItem(
                            value: 'estado',
                            child: Text('Estado (error, pendiente, ok)'),
                          ),
                          DropdownMenuItem(
                            value: 'total_desc',
                            child: Text('Importe (mayor a menor)'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _ordenActual = value;
                              _aplicarFiltros();
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Información de cantidad de ventas filtradas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mostrando ${_ventasFiltradas.length} de ${_ventas.length} ventas',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                TextButton.icon(
                  icon: Icon(Icons.refresh),
                  label: Text('Actualizar'),
                  onPressed: _isLoading ? null : _cargarVentas,
                ),
              ],
            ),
          ),

          // Tabla de ventas
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _ventasFiltradas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No se encontraron ventas',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _ventasFiltradas.length,
                        itemBuilder: (context, index) {
                          final venta = _ventasFiltradas[index];
                          return _buildVentaItem(context, venta);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // Construir item de venta para la lista
  Widget _buildVentaItem(BuildContext context, Sale venta) {
    final themeCubit = context.watch<ThemaCubit>();
    final isDark = themeCubit.state.isDark;

    final bool estaSincronizada = venta.sincronizado == 1;
    final bool tieneError = venta.estado == 'error';

    // Formato para fecha
    final fechaFormateada = DateFormat('dd/MM/yyyy HH:mm').format(venta.fecha);

    // Determinar icono y color según estado
    IconData iconoEstado;
    Color colorEstado;
    String textoEstado;

    if (tieneError) {
      iconoEstado = Icons.error;
      colorEstado = Colors.red;
      textoEstado = 'Error';
    } else if (estaSincronizada) {
      iconoEstado = Icons.check_circle;
      colorEstado = Colors.green;
      textoEstado = 'Sincronizada';
    } else {
      iconoEstado = Icons.schedule;
      colorEstado = Colors.grey;
      textoEstado = 'Pendiente';
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isDark ? null : _getColorPorEstado(venta),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Venta #${venta.nroVenta ?? venta.id}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorEstado.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorEstado.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(iconoEstado, size: 14, color: colorEstado),
                  SizedBox(width: 4),
                  Text(
                    textoEstado,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorEstado,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(fechaFormateada),
                  ],
                ),
                Text(
                  '\$${venta.total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            if (venta.clienteId != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.person, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text('Cliente #${venta.clienteId}'),
                  ],
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.sync, color: estaSincronizada ? Colors.grey : Colors.blue),
          tooltip: estaSincronizada ? 'Ya sincronizada' : 'Sincronizar',
          onPressed: estaSincronizada
              ? null
              : () => _sincronizarVentaIndividual(venta),
        ),
        onTap: () => _mostrarDetallesVenta(venta),
      ),
    );
  }

  // Sincronizar una venta individual
  Future<void> _sincronizarVentaIndividual(Sale venta) async {
    if (!_isInternetConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No hay conexión a internet. Intente nuevamente cuando esté conectado.')),
      );
      return;
    }

    if (venta.id == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _syncHelper.enqueueSaleForSync(venta.id!);
      await _cargarVentas();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Venta #${venta.nroVenta ?? venta.id} enviada para sincronización'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      log.e('PageVentasSincronizacion', 'Error al sincronizar venta individual', e);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al sincronizar venta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Mostrar diálogo con detalles de una venta
  void _mostrarDetallesVenta(Sale venta) {
    final themeCubit = context.read<ThemaCubit>();
    final isDark = themeCubit.state.isDark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles de Venta #${venta.nroVenta ?? venta.id}'),
        content: Container(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              // Información general
              _buildDetalleItem('Fecha', DateFormat('dd/MM/yyyy HH:mm').format(venta.fecha)),
              _buildDetalleItem('Estado', venta.estado),
              _buildDetalleItem('Sincronizada', venta.sincronizado == 1 ? 'Sí' : 'No'),
              Divider(),

              // Información financiera
              _buildDetalleItem('Subtotal', '\$${venta.subtotal.toStringAsFixed(2)}'),
              _buildDetalleItem('IVA', '\$${venta.iva.toStringAsFixed(2)}'),
              if (venta.descuento > 0)
                _buildDetalleItem('Descuento', '\$${venta.descuento.toStringAsFixed(2)}'),
              if (venta.recargo > 0)
                _buildDetalleItem('Recargo', '\$${venta.recargo.toStringAsFixed(2)}'),
              _buildDetalleItem('Total', '\$${venta.total.toStringAsFixed(2)}', isBold: true),
              Divider(),

              // Método de pago
              _buildDetalleItem('Método de pago', venta.metodoPago),
              if (venta.metodoPagoDetalles != null && venta.metodoPagoDetalles!.isNotEmpty)
                _buildDetalleItem('Detalles de pago', venta.metodoPagoDetalles!),
              Divider(),

              // Información adicional
              if (venta.clienteId != null)
                _buildDetalleItem('Cliente ID', venta.clienteId.toString()),
              if (venta.domicilioEntrega != null && venta.domicilioEntrega!.isNotEmpty)
                _buildDetalleItem('Domicilio de entrega', venta.domicilioEntrega!),
              if (venta.notaInterna != null && venta.notaInterna!.isNotEmpty)
                _buildDetalleItem('Nota interna', venta.notaInterna!),
              if (venta.observaciones != null && venta.observaciones!.isNotEmpty)
                _buildDetalleItem('Observaciones', venta.observaciones!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
          if (venta.sincronizado == 0)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _sincronizarVentaIndividual(venta);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text('Sincronizar'),
            ),
        ],
      ),
    );
  }

  // Construir un item de detalle para el diálogo
  Widget _buildDetalleItem(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Enum para calidad de conexión
enum ConnectionQuality {
  unknown,
  none,
  poor,
  medium,
  good,
}