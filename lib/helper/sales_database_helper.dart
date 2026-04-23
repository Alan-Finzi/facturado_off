import '../models/sales/sale.dart';
import '../services/firestore_service.dart';

class SalesDatabaseHelper {
  SalesDatabaseHelper({dynamic databaseHelper});

  final _fs = FirestoreService.instance;

  Future<int> saveSale(Sale sale) async {
    return await _fs.saveSale(sale);
  }

  Future<int> updateSale(Sale sale) async {
    await _fs.updateSale(sale);
    return sale.id ?? 0;
  }

  Future<Sale?> getSaleById(int id) async {
    return await _fs.getSaleById(id);
  }

  Future<List<Sale>> getAllSales() async {
    return await _fs.getAllSales();
  }

  Future<List<Sale>> getSalesByClientId(int clienteId) async {
    return await _fs.getSalesByClientId(clienteId);
  }

  Future<List<Sale>> getSalesByPeriod(DateTime inicio, DateTime fin) async {
    return await _fs.getSalesByPeriod(inicio, fin);
  }

  Future<void> softDeleteSale(int ventaId) async {
    await _fs.softDeleteSale(ventaId);
  }

  Future<void> hardDeleteSale(int ventaId) async {
    await _fs.softDeleteSale(ventaId);
  }

  Future<void> markSaleAsSynchronized(int ventaId) async {
    await _fs.markSaleAsSynchronized(ventaId);
  }

  Future<List<Sale>> getUnsynchronizedSales() async {
    return await _fs.getUnsynchronizedSales();
  }

  Future<double> getTotalSalesByPeriod(DateTime inicio, DateTime fin) async {
    return await _fs.getTotalSalesByPeriod(inicio, fin);
  }
}
